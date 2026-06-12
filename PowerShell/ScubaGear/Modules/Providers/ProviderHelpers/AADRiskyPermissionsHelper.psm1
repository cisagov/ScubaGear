Import-Module -Name $PSScriptRoot/../../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable

# Module-scoped cache for RiskyAppPermissions.json - loaded once, reused across all function calls
$script:CachedRiskyAppPermissionsJson = $null
$script:CachedPermissionLookup = $null

function Get-ResourcePermissions {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [hashtable]
        $ResourcePermissionCache,

        [string]
        $ResourceAppId
    )
    try {
        if ($null -eq $ResourcePermissionCache) {
            $ResourcePermissionCache = @{}
        }

        if (-not $ResourcePermissionCache.ContainsKey($ResourceAppId)) {
            # v1.0 Graph endpoint is used here because it contains the oauth2PermissionScopes property
            $result = (
                Invoke-GraphDirectly `
                    -Commandlet "Get-MgServicePrincipal" `
                    -M365Environment $M365Environment `
                    -QueryParams @{
                        '$filter' = "appId eq '$ResourceAppId'"
                        '$select' = "appRoles,oauth2PermissionScopes"
                    }
            ).Value

            $ResourcePermissionCache[$ResourceAppId] = $result
        }
        return $ResourcePermissionCache[$ResourceAppId]
    }
    catch {
        Write-Warning "An error occurred in Get-ResourcePermissions: $($_.Exception.Message)"
        Write-Warning "Stack trace: $($_.ScriptStackTrace)"
        throw $_
    }
}

function Get-RiskyAppPermissionsJson {
    <#
    .Description
    Returns the parsed RiskyAppPermissions.json data. Uses a module-scoped cache to avoid
    redundant file reads and JSON parsing on subsequent calls.
    .Functionality
    Internal
    #>
    process {
        if ($null -eq $script:CachedRiskyAppPermissionsJson) {
            try {
                $SchemasPath = Join-Path -Path ((Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.FullName) -ChildPath "schemas"
                $script:CachedRiskyAppPermissionsJson = Get-Content -Path (
                    Join-Path -Path (Get-Item -Path $SchemasPath) -ChildPath "RiskyAppPermissions.json"
                ) -Raw | ConvertFrom-Json
                # Build the hashtable lookup on first load
                $script:CachedPermissionLookup = New-PermissionLookup -Json $script:CachedRiskyAppPermissionsJson
            }
            catch {
                Write-Warning "An error occurred in Get-RiskyAppPermissionsJson: $($_.Exception.Message)"
                Write-Warning "Stack trace: $($_.ScriptStackTrace)"
                throw $_
            }
        }
        return $script:CachedRiskyAppPermissionsJson
    }
}

function New-PermissionLookup {
    <#
    .Description
    Builds a nested hashtable from the RiskyAppPermissions.json PSObject for O(1) permission lookups.
    Structure: $Lookup[$ResourceDisplayName][$RoleType][$Guid] = @{ Name; RiskLevel }
    .Functionality
    Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $Json
    )

    $Lookup = @{}
    foreach ($Resource in $Json.permissions.PSObject.Properties) {
        $ResourceName = $Resource.Name
        $Lookup[$ResourceName] = @{}
        foreach ($RoleType in $Resource.Value.PSObject.Properties) {
            # Skip internal keys like _excludedDelegated
            if ($RoleType.Name.StartsWith("_")) { continue }
            $RoleTypeName = $RoleType.Name
            $Lookup[$ResourceName][$RoleTypeName] = @{}
            foreach ($Perm in $RoleType.Value.PSObject.Properties) {
                $Lookup[$ResourceName][$RoleTypeName][$Perm.Name] = @{
                    Name = $Perm.Value.Name
                    RiskLevel = $Perm.Value.RiskLevel
                }
            }
        }
    }
    return $Lookup
}

function Get-PermissionLookup {
    <#
    .Description
    Returns the cached hashtable lookup for risky permissions. Builds it if not yet initialized.
    .Functionality
    Internal
    #>
    param (
        [PSCustomObject]
        $RiskyAppPermissionsJson
    )

    if ($null -ne $script:CachedPermissionLookup) {
        return $script:CachedPermissionLookup
    }

    if ($null -eq $RiskyAppPermissionsJson) {
        $RiskyAppPermissionsJson = Get-RiskyAppPermissionsJson
    }

    $script:CachedPermissionLookup = New-PermissionLookup -Json $RiskyAppPermissionsJson
    return $script:CachedPermissionLookup
}

function New-RiskyAppResourceLookup {
    <#
    .Description
    Builds a pair of hashtable lookups for risky resource mappings.
    .Functionality
    Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $RiskyAppPermissionsJson
    )

    $Lookup = @{
        AppIdToName = @{}
        NameToAppId = @{}
    }

    foreach ($Property in $RiskyAppPermissionsJson.resources.PSObject.Properties) {
        $Lookup.AppIdToName[$Property.Name] = $Property.Value
        $Lookup.NameToAppId[$Property.Value] = $Property.Name
    }

    return $Lookup
}

function Get-PermissionTypeDetails {
    <#
    .Description
    Resolves role type, display name, and consent requirements using cached per-resource lookups.
    .Functionality
    Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [object]
        $ResourceAppPermissions,

        [ValidateNotNull()]
        [hashtable]
        $ResourcePermissionTypeCache,

        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceAppId,

        [ValidateNotNullOrEmpty()]
        [string]
        $RoleId,

        [string]
        $DeclaredRoleType
    )

    if (-not $ResourcePermissionTypeCache.ContainsKey($ResourceAppId)) {
        $RoleLookup = @{}
        foreach ($Role in @($ResourceAppPermissions.appRoles)) {
            if ($null -ne $Role -and $null -ne $Role.id) {
                $RoleLookup[[string]$Role.id] = $Role
            }
        }

        $ScopeLookup = @{}
        foreach ($Scope in @($ResourceAppPermissions.oauth2PermissionScopes)) {
            if ($null -ne $Scope -and $null -ne $Scope.id) {
                $ScopeLookup[[string]$Scope.id] = $Scope
            }
        }

        $ResourcePermissionTypeCache[$ResourceAppId] = @{
            AppRoles = $RoleLookup
            Scopes   = $ScopeLookup
        }
    }

    $PermissionTypeLookup = $ResourcePermissionTypeCache[$ResourceAppId]
    $Role = $PermissionTypeLookup.AppRoles[$RoleId]
    if ($null -ne $Role) {
        return @{
            ReadableRoleType     = "Application"
            RoleDisplayName      = $Role.value
            RequiresAdminConsent = $true
        }
    }

    $Scope = $PermissionTypeLookup.Scopes[$RoleId]
    if ($null -ne $Scope) {
        return @{
            ReadableRoleType     = "Delegated"
            RoleDisplayName      = $Scope.value
            RequiresAdminConsent = $Scope.type -eq "Admin"
        }
    }

    # Preserve role type semantics when the caller explicitly declared delegated/role and Graph object is missing.
    if ($DeclaredRoleType -eq "Role") {
        return @{
            ReadableRoleType     = "Application"
            RoleDisplayName      = $null
            RequiresAdminConsent = $true
        }
    }

    return @{
        ReadableRoleType     = "Delegated"
        RoleDisplayName      = $null
        RequiresAdminConsent = $false
    }
}

function Invoke-GraphBatchRequestsWithRetry {
    <#
    .Description
    Executes Graph batch requests with bounded retry/backoff for transient failures (including HTTP 429).
    .Functionality
    Internal
    #>
    param (
        [Parameter(Mandatory = $true)]
        [array]
        $Requests,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $true)]
        [string]
        $M365Environment,

        [ValidateSet("v1.0", "beta", IgnoreCase = $true)]
        [string]
        $ApiVersion = "beta",

        [ValidateRange(0, 10)]
        [int]
        $MaxRetries = 6,

        [ValidateRange(1, 30)]
        [int]
        $BaseDelaySeconds = 1
    )

    if ($null -eq $Requests -or $Requests.Count -eq 0) {
        return @{}
    }

    $GetScubaGearPermissionsCommand = Get-Command -Name Get-ScubaGearPermissions -ErrorAction SilentlyContinue
    $IsFallbackMode = $null -eq $GetScubaGearPermissionsCommand
    if ($IsFallbackMode) {
        # Unit tests can mock Invoke-MgGraphRequest without loading the permissions helper.
        $BatchEndpoint = "/$ApiVersion/`$batch"
        $MaxRetries = 0
    }
    else {
        $EndpointRoot = Get-ScubaGearPermissions -CmdletName Connect-MgGraph -Environment $M365Environment -OutAs endpoint
        $BatchEndpoint = "$EndpointRoot/$ApiVersion/`$batch"
    }

    $Completed = @{}
    $PendingRequests = @($Requests)
    $BatchSize = 20

    for ($Attempt = 0; $Attempt -le $MaxRetries; $Attempt++) {
        $BatchResponses = @{}

        for ($Offset = 0; $Offset -lt $PendingRequests.Count; $Offset += $BatchSize) {
            $RequestChunk = $PendingRequests[$Offset..([Math]::Min($Offset + $BatchSize - 1, $PendingRequests.Count - 1))]
            $BatchBody = @{ requests = @($RequestChunk) }
            $BatchResponse = Invoke-MgGraphRequest -Method POST -Uri $BatchEndpoint -Body ($BatchBody | ConvertTo-Json -Depth 10)

            foreach ($Response in @($BatchResponse.responses)) {
                $BatchResponses[[string]$Response.id] = $Response
            }
        }

        $RetryRequests = [System.Collections.Generic.List[object]]::new()
        $MaxRetryAfterSeconds = 0

        foreach ($Request in $PendingRequests) {
            $Response = $BatchResponses[[string]$Request.id]

            if ($null -eq $Response) {
                [void]$RetryRequests.Add($Request)
                continue
            }

            $StatusCode = 0
            if ($null -ne $Response.status) {
                $StatusCode = [int]$Response.status
            }

            $IsRetriableStatus = $StatusCode -in @(429, 500, 502, 503, 504)

            if ($IsRetriableStatus -and $Attempt -lt $MaxRetries) {
                [void]$RetryRequests.Add($Request)

                if ($null -ne $Response.headers) {
                    $RetryAfterValue = $Response.headers.'Retry-After'
                    if ($null -eq $RetryAfterValue) {
                        $RetryAfterValue = $Response.headers.'retry-after'
                    }

                    $ParsedRetryAfter = 0
                    if ($null -ne $RetryAfterValue -and [int]::TryParse([string]$RetryAfterValue, [ref]$ParsedRetryAfter)) {
                        if ($ParsedRetryAfter -gt $MaxRetryAfterSeconds) {
                            $MaxRetryAfterSeconds = $ParsedRetryAfter
                        }
                    }
                }
            }
            else {
                $Completed[[string]$Request.id] = $Response
            }
        }

        if ($RetryRequests.Count -eq 0) {
            break
        }

        $BackoffSeconds = [Math]::Pow(2, $Attempt) * $BaseDelaySeconds
        $DelaySeconds = [Math]::Max([int][Math]::Ceiling($BackoffSeconds), $MaxRetryAfterSeconds)
        $JitterMs = Get-Random -Minimum 100 -Maximum 900

        Write-Verbose "Retrying $($RetryRequests.Count) Graph batch requests in $DelaySeconds second(s) (attempt $($Attempt + 1) of $MaxRetries)."
        Start-Sleep -Seconds $DelaySeconds
        Start-Sleep -Milliseconds $JitterMs

        $PendingRequests = $RetryRequests.ToArray()
    }

    # Preserve non-transient failed responses so callers can log status.
    foreach ($Request in $PendingRequests) {
        if (-not $Completed.ContainsKey([string]$Request.id)) {
            $Completed[[string]$Request.id] = @{
                id = [string]$Request.id
                status = 599
                body = @{}
            }
        }
    }

    return $Completed
}

function Format-Permission {
    <#
    .Description
    Returns an API permission from either application/service principal which maps
    to the list of permissions declared in RiskyAppPermissions.json
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $Json,

        [ValidateNotNullOrEmpty()]
        [string]
        $AppDisplayName,

        [ValidateNotNullOrEmpty()]
        [string]
        $Id,

        [string]
        $RoleType,

        [string]
        $RoleDisplayName,

        [ValidateNotNullOrEmpty()]
        [boolean]
        $IsAdminConsented,

        [ValidateNotNullOrEmpty()]
        [boolean]
        $RequiresAdminConsent
    )
    $Map = @()
    if ($null -ne $RoleType) {
        $Lookup = Get-PermissionLookup -RiskyAppPermissionsJson $Json
        $IsRisky = $false
        $RiskLevel = $null

        if ($Lookup.ContainsKey($AppDisplayName) -and
            $Lookup[$AppDisplayName].ContainsKey($RoleType) -and
            $Lookup[$AppDisplayName][$RoleType].ContainsKey($Id)) {
            $IsRisky = $true
            $RiskLevel = $Lookup[$AppDisplayName][$RoleType][$Id].RiskLevel
        }

        $Map += [PSCustomObject]@{
            RoleId                 = $Id
            RoleType               = if ($null -ne $RoleType) { $RoleType } else { $null }
            RoleDisplayName        = if ($null -ne $RoleDisplayName) { $RoleDisplayName } else { $null }
            ApplicationDisplayName = $AppDisplayName
            IsAdminConsented       = $IsAdminConsented
            RequiresAdminConsent   = $RequiresAdminConsent
            IsRisky                = $IsRisky
            RiskLevel              = $RiskLevel
        }
    }
    return $Map
}

function Format-Credentials {
    <#
    .Description
    Returns an array of valid/expired credentials
    .Functionality
    #Internal
    ##>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSReviewUnusedParameter", "IsFromApplication", Justification = "False positive due to variable scoping"
    )]
    param (
        [Object[]]
        $AccessKeys,

        [ValidateNotNullOrEmpty()]
        [boolean]
        $IsFromApplication,

        [switch]
        $IsFederated
    )

    process {
        $ValidCredentials = @()

        if ($IsFederated) {
            $RequiredKeys = @("Id", "Name", "Description", "Issuer", "Subject", "Audiences")
        }
        else {
            $RequiredKeys = @("KeyId", "DisplayName", "StartDateTime", "EndDateTime")
        }
        
        foreach ($Credential in $AccessKeys) {
            # Only format credentials with the correct keys
            $MissingKeys = $RequiredKeys | Where-Object { -not ($Credential.PSObject.Properties.Name -contains $_) }
            if ($MissingKeys.Count -eq 0) {
                if ($IsFederated) {
                    # $Credential is of type PSCredential which is immutable, create a copy
                    $CredentialCopy = $Credential | Select-Object -Property `
                        Id, Name, Description, Issuer, Subject, Audiences,`
                        @{ Name = "IsFromApplication"; Expression = { $IsFromApplication }}
                }
                else {
                    $CredentialCopy = $Credential | Select-Object -Property `
                        KeyId, DisplayName, StartDateTime, EndDateTime, `
                        @{ Name = "IsFromApplication"; Expression = { $IsFromApplication }}
                }
                $ValidCredentials += $CredentialCopy
            }
        }

        if ($null -eq $AccessKeys -or $AccessKeys.Count -eq 0 -or $ValidCredentials.Count -eq 0) {
            return $null
        }
        return $ValidCredentials
    }
}

function Merge-Credentials {
    <#
    .Description
    Merge credentials from multiple resources into a single resource
    .Functionality
    #Internal
    ##>
    param (
        [Object[]]
        $ApplicationAccessKeys,

        [Object[]]
        $ServicePrincipalAccessKeys
    )

    # Both application/sp objects have key and federated credentials.
    # Conditionally merge the two together, select only application/service principal creds, or none.
    $MergedCredentials = @()
    if ($null -ne $ServicePrincipalAccessKeys -and $null -ne $ApplicationAccessKeys) {
        # Both objects valid
        $MergedCredentials = @($ServicePrincipalAccessKeys) + @($ApplicationAccessKeys)
    }
    elseif ($null -eq $ServicePrincipalAccessKeys -and $null -ne $ApplicationAccessKeys) {
        # Only application credentials valid
        $MergedCredentials = @($ApplicationAccessKeys)
    }
    elseif ($null -ne $ServicePrincipalAccessKeys -and $null -eq $ApplicationAccessKeys) {
        # Only service principal credentials valid
        $MergedCredentials = @($ServicePrincipalAccessKeys)
    }
    else {
        # Neither credentials are valid
        $MergedCredentials = $null
    }
    return $MergedCredentials
}

function Get-ApplicationsWithRiskyPermissions {
    <#
    .Description
    Returns an array of applications where each item contains its Object ID, App ID, Display Name,
    Key/Password/Federated Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [hashtable]
        $ResourcePermissionCache,

        [PSCustomObject]
        $RiskyAppPermissionsJson
    )
    process {
        try {
            if ($null -eq $RiskyAppPermissionsJson) {
                $RiskyAppPermissionsJson = Get-RiskyAppPermissionsJson
            }
            $ResourceLookup = New-RiskyAppResourceLookup -RiskyAppPermissionsJson $RiskyAppPermissionsJson
            $ResourcePermissionTypeCache = @{}

            # Get all applications in the tenant with only required fields to reduce payload size.
            $Applications = (
                Invoke-GraphDirectly `
                    -commandlet "Get-MgBetaApplication" `
                    -M365Environment $M365Environment `
                    -QueryParams @{
                        '$select' = "id,appId,displayName,signInAudience,requiredResourceAccess,keyCredentials,passwordCredentials"
                    }
            ).Value
            $ApplicationResults = [System.Collections.Generic.List[object]]::new()

            foreach ($App in $Applications) {
                # `AzureADMyOrg` = single tenant; `AzureADMultipleOrgs` = multi tenant
                $IsMultiTenantEnabled = $false
                if ($App.SignInAudience -eq "AzureADMultipleOrgs") { $IsMultiTenantEnabled = $true }

                # Map application permissions against RiskyAppPermissions.json
                $MappedPermissions = [System.Collections.Generic.List[object]]::new()
                foreach ($Resource in $App.RequiredResourceAccess) {
                    # Returns both application and delegated permissions
                    $Roles = $Resource.ResourceAccess
                    $ResourceAppId = $Resource.ResourceAppId

                    if (-not $ResourceLookup.AppIdToName.ContainsKey($ResourceAppId)) {
                        continue
                    }
                    $ResourceDisplayName = $ResourceLookup.AppIdToName[$ResourceAppId]

                    $ResourceAppPermissions = Get-ResourcePermissions `
                        -M365Environment $M365Environment `
                        -ResourcePermissionCache $ResourcePermissionCache `
                        -ResourceAppId $ResourceAppId

                    if ($null -eq $ResourceAppPermissions) {
                        Write-Warning "No permissions found for resource app ID: $ResourceAppId"
                        continue
                    }

                    # Additional processing is required to determine if a permission is admin consented.
                    # Initially assume admin consent is false since we reference the application's manifest,
                    # then update the value later when its compared to service principal permissions.
                    $IsAdminConsented = $false

                    foreach ($Role in $Roles) {
                        $RoleId = [string]$Role.Id
                        $PermissionTypeDetails = Get-PermissionTypeDetails `
                            -ResourceAppPermissions $ResourceAppPermissions `
                            -ResourcePermissionTypeCache $ResourcePermissionTypeCache `
                            -ResourceAppId $ResourceAppId `
                            -RoleId $RoleId `
                            -DeclaredRoleType $Role.Type

                        [void]$MappedPermissions.AddRange(@(
                            Format-Permission `
                                -Json $RiskyAppPermissionsJson `
                                -AppDisplayName $ResourceDisplayName `
                                -Id $RoleId `
                                -RoleType $PermissionTypeDetails.ReadableRoleType `
                                -RoleDisplayName $PermissionTypeDetails.RoleDisplayName `
                                -IsAdminConsented $IsAdminConsented `
                                -RequiresAdminConsent $PermissionTypeDetails.RequiresAdminConsent
                        ))
                    }
                }

                $RiskyPermissions = @($MappedPermissions | Where-Object { $_.IsRisky -eq $true })

                # Exclude applications without risky permissions
                if ($RiskyPermissions.Count -gt 0) {
                    # Fetch federated credentials only for applications that are confirmed risky.
                    $FederatedCredentials = (Invoke-GraphDirectly -commandlet "Get-MgBetaApplicationFederatedIdentityCredential" -M365Environment $M365Environment -Id $App.Id).Value
                    $FederatedCredentialsResults = @()

                    if ($FederatedCredentials -is [System.Collections.IEnumerable] -and $FederatedCredentials.Count -gt 0) {
                        foreach ($FederatedCredential in $FederatedCredentials) {
                            $FederatedCredentialsResults += [PSCustomObject]@{
                                Id          = $FederatedCredential.Id
                                Name        = $FederatedCredential.Name
                                Description = $FederatedCredential.Description
                                Issuer      = $FederatedCredential.Issuer
                                Subject     = $FederatedCredential.Subject
                                Audiences   = $FederatedCredential.Audiences | Out-String
                            }
                        }
                    }
                    else {
                        $FederatedCredentialsResults = $null
                    }

                    [void]$ApplicationResults.Add([PSCustomObject]@{
                        ObjectId             = $App.Id
                        AppId                = $App.AppId
                        DisplayName          = $App.DisplayName
                        IsMultiTenantEnabled = $IsMultiTenantEnabled
                        # Credentials from application and service principal objects may get merged in other cmdlets.
                        # Differentiate between the two by setting IsFromApplication=$true
                        KeyCredentials       = Format-Credentials -AccessKeys $App.KeyCredentials -IsFromApplication $true
                        PasswordCredentials  = Format-Credentials -AccessKeys $App.PasswordCredentials -IsFromApplication $true
                        FederatedCredentials = Format-Credentials -AccessKeys $FederatedCredentialsResults -IsFromApplication $true -IsFederated
                        Permissions          = $MappedPermissions.ToArray()
                    })
                }
            }
        } catch {
            Write-Warning "An error occurred in Get-ApplicationsWithRiskyPermissions: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $ApplicationResults.ToArray()
    }
}

function Get-ServicePrincipalsWithRiskyPermissions {
    <#
    .Description
    Returns an array of service principals where each item contains its Object ID, App ID, Display Name,
    Key/Password Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [hashtable]
        $ResourcePermissionCache,

        [PSCustomObject]
        $RiskyAppPermissionsJson
    )
    process {
        try {
            if ($null -eq $RiskyAppPermissionsJson) {
                $RiskyAppPermissionsJson = Get-RiskyAppPermissionsJson
            }
            $ServicePrincipalResults = [System.Collections.Generic.List[object]]::new()
            $ResourceLookup = New-RiskyAppResourceLookup -RiskyAppPermissionsJson $RiskyAppPermissionsJson
            $ResourcePermissionTypeCache = @{}

            # Get all service principals with only required fields to reduce payload size.
            $ServicePrincipals = (
                Invoke-GraphDirectly `
                    -commandlet "Get-MgBetaServicePrincipal" `
                    -M365Environment $M365Environment `
                    -QueryParams @{
                        '$select' = "id,appId,displayName,signInAudience,keyCredentials,passwordCredentials,federatedIdentityCredentials,appOwnerOrganizationId"
                    }
            ).Value

            $ServicePrincipalById = @{}
            foreach ($ServicePrincipal in @($ServicePrincipals)) {
                $ServicePrincipalById[[string]$ServicePrincipal.Id] = $ServicePrincipal
            }

            $BatchRequests = @(
                foreach ($ServicePrincipalId in @($ServicePrincipals.Id)) {
                    @{
                        id = [string]$ServicePrincipalId
                        method = "GET"
                        url = "/servicePrincipals/$ServicePrincipalId/appRoleAssignments?`$select=appRoleId,resourceDisplayName"
                    }
                }
            )
            $BatchResponses = Invoke-GraphBatchRequestsWithRetry -Requests $BatchRequests -M365Environment $M365Environment -ApiVersion "beta"

            foreach ($ServicePrincipalId in @($ServicePrincipals.Id)) {
                $Result = $BatchResponses[[string]$ServicePrincipalId]
                $ServicePrincipal = $ServicePrincipalById[[string]$ServicePrincipalId]
                if ($null -eq $ServicePrincipal) {
                    continue
                }

                $MappedPermissions = [System.Collections.Generic.List[object]]::new()
                if ($null -ne $Result -and [int]$Result.status -eq 200 -and $null -ne $Result.body) {
                    $AppRoleAssignments = @($Result.body.value)
                    foreach ($Role in $AppRoleAssignments) {
                        $ResourceDisplayName = [string]$Role.ResourceDisplayName
                        $RoleId = [string]$Role.AppRoleId

                        if (-not $ResourceLookup.NameToAppId.ContainsKey($ResourceDisplayName)) {
                            continue
                        }

                        # Default to true,
                        # `Get-MgBetaServicePrincipalAppRoleAssignment` only returns admin consented permissions
                        $IsAdminConsented = $true
                        $ResourceAppId = $ResourceLookup.NameToAppId[$ResourceDisplayName]

                        $ResourceAppPermissions = Get-ResourcePermissions `
                            -M365Environment $M365Environment `
                            -ResourcePermissionCache $ResourcePermissionCache `
                            -ResourceAppId $ResourceAppId

                        if ($null -eq $ResourceAppPermissions) {
                            Write-Warning "No permissions found for resource app ID: $ResourceAppId"
                            continue
                        }

                        $PermissionTypeDetails = Get-PermissionTypeDetails `
                            -ResourceAppPermissions $ResourceAppPermissions `
                            -ResourcePermissionTypeCache $ResourcePermissionTypeCache `
                            -ResourceAppId $ResourceAppId `
                            -RoleId $RoleId

                        [void]$MappedPermissions.AddRange(@(
                            Format-Permission `
                                -Json $RiskyAppPermissionsJson `
                                -AppDisplayName $ResourceDisplayName `
                                -Id $RoleId `
                                -RoleType $PermissionTypeDetails.ReadableRoleType `
                                -RoleDisplayName $PermissionTypeDetails.RoleDisplayName `
                                -IsAdminConsented $IsAdminConsented `
                                -RequiresAdminConsent $PermissionTypeDetails.RequiresAdminConsent
                        ))
                    }
                }
                elseif ($null -ne $Result) {
                    Write-Warning "Error for service principal ${ServicePrincipalId}: $($Result.status)"
                }

                $RiskyPermissions = @($MappedPermissions | Where-Object { $_.IsRisky -eq $true })

                # Exclude service principals without risky permissions
                if ($RiskyPermissions.Count -gt 0) {
                    [void]$ServicePrincipalResults.Add([PSCustomObject]@{
                        ObjectId                = $ServicePrincipal.Id
                        AppId                   = $ServicePrincipal.AppId
                        DisplayName             = $ServicePrincipal.DisplayName
                        SignInAudience          = $ServicePrincipal.SignInAudience
                        # Credentials from application and service principal objects may get merged in other cmdlets.
                        # Differentiate between the two by setting IsFromApplication=$false
                        KeyCredentials          = Format-Credentials -AccessKeys $ServicePrincipal.KeyCredentials -IsFromApplication $false
                        PasswordCredentials     = Format-Credentials -AccessKeys $ServicePrincipal.PasswordCredentials -IsFromApplication $false
                        FederatedCredentials    = Format-Credentials -AccessKeys $ServicePrincipal.FederatedIdentityCredentials -IsFromApplication $false -IsFederated
                        Permissions             = $MappedPermissions.ToArray()
                        AppOwnerOrganizationId  = $ServicePrincipal.AppOwnerOrganizationId
                    })
                }
            }
        } catch {
            Write-Warning "An error occurred in Get-ServicePrincipalsWithRiskyPermissions: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $ServicePrincipalResults.ToArray()
    }
}

function Get-ServicePrincipalsWithRiskyDelegatedPermissionClassifications {
    <#
    .Description
    Returns an array of service principals where each item contains its Object ID, App ID, Display Name,
    Key/Password Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [PSCustomObject]
        $RiskyAppPermissionsJson
    )
    process {
        try {
            if ($null -eq $RiskyAppPermissionsJson) {
                $RiskyAppPermissionsJson = Get-RiskyAppPermissionsJson
            }
            $Resources = $RiskyAppPermissionsJson.resources.PSObject.Properties
            $ResourceIds = @($Resources | ForEach-Object { [string]$_.Name })

            # Resolve all risky resource service principals in one filtered query instead of per-resource lookups.
            $ServicePrincipalByAppId = @{}
            if ($ResourceIds.Count -gt 0) {
                $FilterValues = @($ResourceIds | ForEach-Object { "appId eq '$_'" })
                $FilterClause = $FilterValues -join " or "

                $ResolvedServicePrincipals = (
                    Invoke-GraphDirectly `
                        -Commandlet "Get-MgServicePrincipal" `
                        -M365Environment $M365Environment `
                        -QueryParams @{
                            '$filter' = $FilterClause
                            '$select' = "id,appId,displayName"
                        }
                ).Value

                foreach ($ResolvedServicePrincipal in @($ResolvedServicePrincipals)) {
                    $ServicePrincipalByAppId[[string]$ResolvedServicePrincipal.appId] = $ResolvedServicePrincipal
                }
            }

            $ResourceByServicePrincipalId = @{}
            foreach ($Resource in $Resources) {
                $ResourceId = $Resource.Name
                $ResourceName = $Resource.Value

                $ServicePrincipal = $ServicePrincipalByAppId[$ResourceId]
                if ($null -eq $ServicePrincipal -or $null -eq $ServicePrincipal.id) {
                    continue
                }

                $ResourceByServicePrincipalId[[string]$ServicePrincipal.id] = [PSCustomObject]@{
                    ResourceId = $ResourceId
                    ResourceName = $ResourceName
                    ServicePrincipal = $ServicePrincipal
                }
            }

            $BatchRequests = @(
                foreach ($ServicePrincipalId in @($ResourceByServicePrincipalId.Keys)) {
                    @{
                        id = [string]$ServicePrincipalId
                        method = "GET"
                        url = "/servicePrincipals/$ServicePrincipalId/delegatedPermissionClassifications?`$select=id,permissionId,permissionName,classification"
                    }
                }
            )
            $BatchResponses = Invoke-GraphBatchRequestsWithRetry -Requests $BatchRequests -M365Environment $M365Environment -ApiVersion "beta"


            $RiskyDelegatedPermissionClassificationResults = @()
            foreach ($ServicePrincipalId in @($ResourceByServicePrincipalId.Keys)) {
                $ResourceContext = $ResourceByServicePrincipalId[$ServicePrincipalId]
                $ResourceId = $ResourceContext.ResourceId
                $ResourceName = $ResourceContext.ResourceName
                $ServicePrincipal = $ResourceContext.ServicePrincipal

                $RiskyDelegatedPermissions = $RiskyAppPermissionsJson.permissions.$ResourceName.Delegated.PSObject.Properties
                $Result = $BatchResponses[[string]$ServicePrincipalId]
                if ($null -eq $Result -or [int]$Result.status -ne 200 -or $null -eq $Result.body) {
                    if ($null -ne $Result) {
                        Write-Warning "Error for service principal ${ServicePrincipalId}: $($Result.status)"
                    }
                    continue
                }

                $PermClassifications = @($Result.body.value)

                $RiskyPermClassifications = @()
                foreach ($PermClassification in $PermClassifications) {
                    if ($PermClassification.Classification -eq "low" -and $RiskyDelegatedPermissions.Name -contains $PermClassification.PermissionId) {
                        $RiskyPermClassifications += [PSCustomObject]@{
                            id                = $PermClassification.id
                            permissionId      = $PermClassification.permissionId
                            permissionName    = $PermClassification.permissionName
                            classification    = $PermClassification.classification
                        }
                    }
                }

                if ($RiskyPermClassifications.Count -gt 0) {
                    $RiskyDelegatedPermissionClassificationResults += [PSCustomObject]@{
                        ObjectId                        = $ServicePrincipalId
                        AppId                           = $ResourceId
                        DisplayName                     = $ServicePrincipal.DisplayName
                        RiskyPermClassifications        = $RiskyPermClassifications.permissionName
                    }
                }
            }
            return $RiskyDelegatedPermissionClassificationResults
        } catch {
            Write-Warning "An error occurred in Get-ServicePrincipalsWithRiskyDelegatedPermissionClassifications: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
    }
}

function Format-RiskyApplications {
    <#
    .Description
    Returns an aggregated JSON dataset of application objects, combining data from both applications and
    service principal objects. Key/Password/Federated credentials are combined into a single array, and
    admin consent is reflected in each object's list of associated risky permissions.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $RiskyApps,

        [ValidateNotNullOrEmpty()]
        [Object[]]
        $RiskySPs
    )
    process {
        try {
            $Applications = @()
            foreach ($App in $RiskyApps) {
                $MatchedServicePrincipal = $RiskySPs | Where-Object { $_.AppId -eq $App.AppId }

                # Merge objects if an application and service principal exist with the same AppId
                $MergedObject = @{}
                if ($MatchedServicePrincipal) {
                    $ServicePrincipalRoleIds = @($MatchedServicePrincipal.Permissions | Select-Object -ExpandProperty RoleId)

                    # Determine if each risky permission was admin consented or not
                    foreach ($Permission in $App.Permissions) {
                        if ($ServicePrincipalRoleIds -contains $Permission.RoleId) {
                            $Permission.IsAdminConsented = $true
                        }
                    }

                    $ObjectIds = [PSCustomObject]@{
                        Application      = $App.ObjectId
                        ServicePrincipal = $MatchedServicePrincipal.ObjectId
                    }

                    $MergedKeyCredentials = Merge-Credentials `
                        -ApplicationAccessKeys $App.KeyCredentials `
                        -ServicePrincipalAccessKeys $MatchedServicePrincipal.KeyCredentials

                    $MergedPasswordCredentials = Merge-Credentials `
                        -ApplicationAccessKeys $App.PasswordCredentials `
                        -ServicePrincipalAccessKeys $MatchedServicePrincipal.PasswordCredentials

                    $MergedFederatedCredentials = Merge-Credentials `
                        -ApplicationAccessKeys $App.FederatedCredentials `
                        -ServicePrincipalAccessKeys $MatchedServicePrincipal.FederatedCredentials

                    $MergedObject = [PSCustomObject]@{
                        ObjectId                 = $ObjectIds
                        AppId                    = $App.AppId
                        DisplayName              = $App.DisplayName
                        IsMultiTenantEnabled     = $App.IsMultiTenantEnabled
                        KeyCredentials           = $MergedKeyCredentials
                        PasswordCredentials      = $MergedPasswordCredentials
                        FederatedCredentials     = $MergedFederatedCredentials
                        Permissions              = $App.Permissions
                    }
                }
                else {
                    $MergedObject = $App
                }

                # Calculate severity score after admin consent for permissions has been determined
                $SeverityInfo = Set-SeverityScore -Object $MergedObject

                # Add severity info to the merged object
                $MergedObject | Add-Member -MemberType NoteProperty -Name "SeverityScore" -Value $SeverityInfo.SeverityScore
                $MergedObject | Add-Member -MemberType NoteProperty -Name "ScoreBreakdown" -Value $SeverityInfo.ScoreBreakdown

                $Applications += $MergedObject
            }
        }
        catch {
            Write-Warning "An error occurred in Format-RiskyApplications: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $Applications
    }
}

function Format-RiskyThirdPartyServicePrincipals {
    <#
    .Description
    Returns a JSON dataset of service principal objects owned by external organizations.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $RiskySPs,

        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        # Raw hashtable containing privileged service principals which is keyed by ServicePrincipalId (object id)
        [hashtable]
        $PrivilegedServicePrincipals = @{}
    )
    process {
        try {
            $ServicePrincipals = @()
            $OrgInfo = (Invoke-GraphDirectly -Commandlet "Get-MgBetaOrganization" -M365Environment $M365Environment).Value

            foreach ($ServicePrincipal in $RiskySPs) {
                if ($null -eq $ServicePrincipal) {
                    continue
                }

                # A null value indicates the owner organization is unknown (e.g., agent service principal)
                # and should not be treated as a third-party service principal.
                if ($null -eq $ServicePrincipal.AppOwnerOrganizationId) {
                    Write-Warning "Service principal $($ServicePrincipal.DisplayName) with AppId $($ServicePrincipal.AppId) does not have an AppOwnerOrganizationId. Skipping."
                    continue
                }

                # If the service principal's owner id is not the same as this tenant then it is a 3rd party principal
                if ($ServicePrincipal.AppOwnerOrganizationId -ne $OrgInfo.Id) {
                    $PrivilegedRoles = @()
                    if ($PrivilegedServicePrincipals.ContainsKey($ServicePrincipal.ObjectId)) {
                        $PrivilegedRoles = $PrivilegedServicePrincipals[$ServicePrincipal.ObjectId].roles
                    }

                    # Calculate severity score after admin consent for permissions has been determined
                    $SeverityInfo = Set-SeverityScore `
                        -Object $ServicePrincipal `
                        -IsThirdPartyServicePrincipal `
                        -PrivilegedRoles $PrivilegedRoles

                    # Add severity info to the merged object
                    $ServicePrincipal | Add-Member -MemberType NoteProperty -Name "SeverityScore" -Value $SeverityInfo.SeverityScore
                    $ServicePrincipal | Add-Member -MemberType NoteProperty -Name "ScoreBreakdown" -Value $SeverityInfo.ScoreBreakdown
                    $ServicePrincipal | Add-Member -MemberType NoteProperty -Name "PrivilegedRoles" -Value $PrivilegedRoles

                    $ServicePrincipals += $ServicePrincipal
                }
            }
        }
        catch {
            Write-Warning "An error occurred in Format-RiskyThirdPartyServicePrincipals: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }

        return $ServicePrincipals
    }
}

function Get-SeverityScoreWeights {
    <#
    .Description
    Returns the weight factors used in severity score calculation.
    The priority score is determined by the sum of all weight factors. A higher value indicates higher risk.

    Weight Factor                   Notes
    -------------------------------------------------------------------------------------------------------------------------------------------
    Permission risk level weights | Each risky permission adds its RiskLevel weight: critical = 50, high = 15, medium = 5, low = 2
    -------------------------------------------------------------------------------------------------------------------------------------------
    Permission volume             | +1 per 10 total permissions (both risky and non-risky)
    -------------------------------------------------------------------------------------------------------------------------------------------
    Multi-tenant                  | +10 for applications with multi-tenant enabled
    -------------------------------------------------------------------------------------------------------------------------------------------
    Third-party service principal | +20 for externally-owned service principals
    -------------------------------------------------------------------------------------------------------------------------------------------
    Privileged roles              | +8 per privileged role assigned to a service principal
    -------------------------------------------------------------------------------------------------------------------------------------------
    Credential context weights    | Base points are added to a credential based on the highest level permission assigned to the application. 
                                  | +50/cred for critical, +35/cred for high, +15/cred for medium, +5/cred for low
    -------------------------------------------------------------------------------------------------------------------------------------------
    Credential type discounts     | Key credentials are discounted by 50% and federated credentials are discounted by 75%
    -------------------------------------------------------------------------------------------------------------------------------------------
    Credential lifetime tiers     | Bonus points for credentials with long lifetimes (excludes federated credentials):
                                  | +5 points for password creds valid for 2+ years, +3 points for 1-2 years, +2 points for 6 months - 1 year
                                  | +5 points for key creds valid for 3+ years, +3 points for 2-3 years, +2 points for 1-2 years
    -------------------------------------------------------------------------------------------------------------------------------------------
    .Functionality
    #Internal
    #>
    return [PSCustomObject]@{
        PermissionRiskLevelWeights = @{
            Critical = 50
            High = 15
            Medium = 5
            Low = 2
            Description = "Risk level weights are assigned based on the level of access granted by each permission."
        }

        PermissionVolume = @{
            PointsPer10Permissions = 1
            Description = "Over-permissioned applications/service principals represent an increased attack surface regardless of individual permission risk level."
        }

        MultiTenant = @{
            Points = 10
            Description = "Multi-tenant applications can be used across multiple organizations, increasing their attack surface."
        }

        ThirdPartyServicePrincipal = @{
            Points = 20
            Description = "Third-party service principals are owned by external organizations and do not fall under the same security policies as internal service principals."
        }

        PrivilegedRoles = @{
            PointsPerRole = 8
            Description = "Service principals with privileged roles (e.g., Global Administrator) have elevated permissions and pose a higher risk."
        }

        CredentialContextWeights = @{
            Critical = 50
            High = 35
            Medium = 15
            Low = 5
            Description = "Credential base points dynamically scale by the highest risk level permission on the app/SP."
        }

        # Discount applied to credential base points.
        # Key and federated credentials are discounted since key (certificate) credentials are more difficult to steal, and federated credentials contain no shared secret.
        CredentialTypeDiscounts = @{
            Password = 1.0
            Key = 0.5
            Federated = 0.25
            Description = "Multiplier applied to credential and base points by credential type. Passwords hold the highest risk, then certificates, and federated creds with the least."
        }

        PasswordCredentialLifetimeTiers = @(
            @{ MinDays = 730; Points = 5 }  # 2+ years
            @{ MinDays = 365; Points = 3 }  # 1 - 2 years
            @{ MinDays = 180; Points = 2 }  # 6 months - 1 year
                                            # <= 180 days is valid, no bonus points
        )

        KeyCredentialLifetimeTiers = @(
            @{ MinDays = 1095; Points = 5 } # 3+ years
            @{ MinDays = 730;  Points = 3 } # 2 - 3 years
            @{ MinDays = 365;  Points = 2 } # 1 - 2 years
                                            # <= 365 days is valid, no bonus points
        )

        CredentialVolume = @{
            PointsPerCredentialAfterFirst = 5
            Description = "Multiple active credentials increase the authentication attack surface. Each active credential beyond the first adds bonus points."
        }

        # Used in Entra ID HTML report to generate risk indicators.
        CredentialRiskIndicatorTiers = @{
            Critical = 0.75
            High = 0.50
            Medium = 0.25
            # Below 0.25 is considered low risk
        }
    }
}

function ConvertFrom-DotNetDate {
    param(
        [string]
        $DateString
    )

    if ([string]::IsNullOrEmpty($DateString)) {
        return $null
    }

    # Dates are returned from Graph as .NET JSON dates: /Date(1675800895000)/
    if ($DateString -match '\\?/Date\((\d+)\)\\?/') {
        $EpochMs = $Matches[1]
        return [System.DateTimeOffset]::FromUnixTimeMilliseconds($EpochMs).UtcDateTime
    }

    return [Datetime]::Parse($DateString)
}

function Set-CredentialScore {
    <#
    .Description
    Calculates the severity score for credentials; handles password, key, and federated credentials.
    .Functionality
    #Internal
    #>
    param (
        [Object[]]
        $AccessKeys,

        # Base points per credential are derived by:
        # - multiplying the credential context weight (determined by the app/SP's highest risk level permission)
        # - credential type discount (password credentials have no discount, key credentials have a 50% discount,
        #   and federated credentials have a 75% discount)
        [ValidateNotNullOrEmpty()]
        [int]
        $BasePointsPerCredential,

        # Bonus poinst are added to a credential's score if the credential's duration exceeds a certain time-bound threshold.
        [array]
        $LifetimeTiers,

        # Only check lifetime for password/key credentials, not required for federated credentials.
        [switch]
        $CheckLifetime
    )

    $CredentialPoints = 0
    $CredentialCount = 0
    $LongLivedCredentialCount = 0

    if ($null -eq $AccessKeys -or @($AccessKeys).Count -eq 0) {
        return @{
            CredentialCount = $CredentialCount
            LongLivedCredentialCount = $LongLivedCredentialCount
            TotalPoints = $CredentialPoints
        }
    }

    foreach ($Credential in $AccessKeys) {
        $CurrentCredentialPoints = 0

        # Skip expired credentials since they can't be used for authentication
        if ($CheckLifetime -and $null -ne $Credential.EndDateTime) {
            $End = ConvertFrom-DotNetDate -DateString $Credential.EndDateTime
            if ($null -ne $End -and $End -lt (Get-Date)) {
                continue
            }
        }

        $CredentialCount++

        # Base points are determined by the app/SP's highest permission risk level
        $CurrentCredentialPoints += $BasePointsPerCredential

        # Add additional points for long-lived credentials (excludes federated)
        if ($CheckLifetime -and $null -ne $Credential.StartDateTime -and $null -ne $Credential.EndDateTime) {
            $Start = ConvertFrom-DotNetDate -DateString $Credential.StartDateTime
            $End = ConvertFrom-DotNetDate -DateString $Credential.EndDateTime
            $Duration = (New-TimeSpan -Start $Start -End $End).Days

            if ($LifetimeTiers) {
                foreach ($Tier in $LifetimeTiers) {
                    if ($Duration -gt $Tier.MinDays) {
                        $CurrentCredentialPoints += $Tier.Points
                        $LongLivedCredentialCount++
                        break
                    }
                }
            }
        }

        $CredentialPoints += $CurrentCredentialPoints
    }

    return @{
        CredentialCount = $CredentialCount
        LongLivedCredentialCount = $LongLivedCredentialCount
        TotalPoints = $CredentialPoints
    }
}

function Set-SeverityScore {
    <#
    .Description
    Calculates a severity score for each risky application/service principal based on multiple risk factors:
    - Number of admin consented risky permissions
    - Number of non-admin consented risky permissions
    - Multi-tenant enabled/disabled
    - Third-party service principal (owned externally)
    - Privileged roles assigned to risky service principals
    - Existence of password/key/federated credentials (considers Long-lived credentials)
    
    The total severity score is normalized to 100 to factor in different weight distributions for each of the above risk factors.
    .Functionality
    #Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $Object,

        [switch]
        $IsThirdPartyServicePrincipal,

        [string[]]
        $PrivilegedRoles = @()
    )
    try {
        $Weights = Get-SeverityScoreWeights

        $Score = 0
        $ScoreBreakdown = @{}

        # 1. Determine admin consented risky permission weight factor
        $AdminConsentedRiskyPermissions = @($Object.Permissions | Where-Object {
            $_.IsRisky -eq $true -and $_.IsAdminConsented -eq $true
        })
        $AdminConsentedPoints = ($AdminConsentedRiskyPermissions | ForEach-Object {
            $Weights.PermissionRiskLevelWeights[$_.RiskLevel]
        } | Measure-Object -Sum).Sum

        $Score += $AdminConsentedPoints
        $ScoreBreakdown.AdminConsentedRiskyPermissions = [PSCustomObject]@{
            PermissionCount = $AdminConsentedRiskyPermissions.Count
            TotalPoints = $AdminConsentedPoints
        }

        # 2. Determine non-admin consented risky permission weight factor
        $NonAdminConsentedRiskyPermissions = @($Object.Permissions | Where-Object {
            $_.IsRisky -eq $true -and $_.IsAdminConsented -eq $false
        })
        $NonAdminConsentedPoints = ($NonAdminConsentedRiskyPermissions | ForEach-Object {
            $Weights.PermissionRiskLevelWeights[$_.RiskLevel]
        } | Measure-Object -Sum).Sum

        $Score += $NonAdminConsentedPoints
        $ScoreBreakdown.NonAdminConsentedRiskyPermissions = [PSCustomObject]@{
            PermissionCount = $NonAdminConsentedRiskyPermissions.Count
            TotalPoints = $NonAdminConsentedPoints
        }

        # 3. Determine privileged roles weight factor (used only for service principals)
        $PrivilegedRolesPoints = 0
        if ($PrivilegedRoles.Count -gt 0) {
            $PrivilegedRolesPoints = $PrivilegedRoles.Count * $Weights.PrivilegedRoles.PointsPerRole
            $Score += $PrivilegedRolesPoints

            $ScoreBreakdown.PrivilegedRoles = [PSCustomObject]@{
                RoleCount = $PrivilegedRoles.Count
                TotalPoints = $PrivilegedRolesPoints
                Roles = $PrivilegedRoles
            }
        }

        # 4. Determine multi-tenant weight factor (used only for applications)
        $MultiTenantPoints = 0
        if ($Object.IsMultiTenantEnabled -eq $true) {
            $MultiTenantPoints = $Weights.MultiTenant.Points
            $Score += $MultiTenantPoints

            $ScoreBreakdown.MultiTenant = [PSCustomObject]@{
                IsMultiTenantEnabled = $Object.IsMultiTenantEnabled
                TotalPoints = $MultiTenantPoints
            }
        }

        # 5. Determine third-party service principal weight factor (used only for service principals)
        $ThirdPartyServicePrincipalPoints = 0
        if ($IsThirdPartyServicePrincipal -eq $true) {
            $ThirdPartyServicePrincipalPoints = $Weights.ThirdPartyServicePrincipal.Points
            $Score += $ThirdPartyServicePrincipalPoints

            $ScoreBreakdown.ThirdPartyServicePrincipal = [PSCustomObject]@{
                IsThirdPartyServicePrincipal = $true
                TotalPoints = $ThirdPartyServicePrincipalPoints
            }
        }

        # 6. Determine the credential base points by the highest risk level permission on the app/SP
        $AllRiskyPermissions = @($Object.Permissions | Where-Object { $_.IsRisky -eq $true })
        $RiskLevelPriority = @{ Critical = 4; High = 3; Medium = 2; Low = 1 }
        $HighestRiskLevel = "None"
        $HighestPriority = 0

        foreach ($Permission in $AllRiskyPermissions) {
            $Priority = $RiskLevelPriority[$Permission.RiskLevel]
            if ($null -ne $Priority -and $Priority -gt $HighestPriority) {
                $HighestPriority = $Priority
                $HighestRiskLevel = $Permission.RiskLevel
            }
        }

        $CredentialBasePoints = if ($HighestRiskLevel -ne "None") { $Weights.CredentialContextWeights[$HighestRiskLevel] } else { 0 }
        $ScoreBreakdown.HighestRiskLevel = $HighestRiskLevel

        # 7. Calculate password credential weight factor
        $PasswordBasePoints = [Math]::Ceiling($CredentialBasePoints * $Weights.CredentialTypeDiscounts.Password)
        $AllPasswordCredentials = @($Object.PasswordCredentials | Where-Object { $null -ne $_ })
        $PasswordScore = Set-CredentialScore `
            -AccessKeys $AllPasswordCredentials `
            -BasePointsPerCredential $PasswordBasePoints `
            -LifetimeTiers $Weights.PasswordCredentialLifetimeTiers `
            -CheckLifetime

        $Score += $PasswordScore.TotalPoints
        $ScoreBreakdown.PasswordCredentials = [PSCustomObject]@{
            CredentialCount = $PasswordScore.CredentialCount
            LongLivedCredentialCount = $PasswordScore.LongLivedCredentialCount
            TotalPoints = $PasswordScore.TotalPoints
        }

        # 8. Calculate key credential weight factor
        $KeyBasePoints = [Math]::Ceiling($CredentialBasePoints * $Weights.CredentialTypeDiscounts.Key)
        $AllKeyCredentials = @($Object.KeyCredentials | Where-Object { $null -ne $_})
        $KeyScore = Set-CredentialScore `
            -AccessKeys $AllKeyCredentials `
            -BasePointsPerCredential $KeyBasePoints `
            -LifetimeTiers $Weights.KeyCredentialLifetimeTiers `
            -CheckLifetime

        $Score += $KeyScore.TotalPoints
        $ScoreBreakdown.KeyCredentials = [PSCustomObject]@{
            CredentialCount = $KeyScore.CredentialCount
            LongLivedCredentialCount = $KeyScore.LongLivedCredentialCount
            TotalPoints = $KeyScore.TotalPoints
        }

        # 9. Calculate federated credential weight factor
        $FederatedBasePoints = [Math]::Ceiling($CredentialBasePoints * $Weights.CredentialTypeDiscounts.Federated)
        $AllFederatedCredentials = @($Object.FederatedCredentials | Where-Object { $null -ne $_})
        $FederatedScore = Set-CredentialScore `
            -AccessKeys $AllFederatedCredentials `
            -BasePointsPerCredential $FederatedBasePoints `

        $Score += $FederatedScore.TotalPoints
        $ScoreBreakdown.FederatedCredentials = [PSCustomObject]@{
            CredentialCount = $FederatedScore.CredentialCount
            TotalPoints = $FederatedScore.TotalPoints
        }

        # 10. Credential volume factor
        $TotalActiveCredentials = $PasswordScore.CredentialCount + $KeyScore.CredentialCount + $FederatedScore.CredentialCount
        $CredentialVolumePoints = 0

        if ($TotalActiveCredentials -gt 1) {
            # Subtract 1 because we're already taking into account the first credential.
            $CredentialVolumePoints = ($TotalActiveCredentials - 1) * $Weights.CredentialVolume.PointsPerCredentialAfterFirst
            $Score += $CredentialVolumePoints
        }

        $ScoreBreakdown.CredentialVolume = [PSCustomObject]@{
            TotalActiveCredentials = $TotalActiveCredentials
            TotalPoints = $CredentialVolumePoints
        }

        # 11. Permission volume factor
        $TotalPermissionCount = @($Object.Permissions).Count
        # Use Math.floor() so the integer division truncates rounds down.
        # For example:
        # - 5 permissions / 10 = 0.5 x 1 (0 points)
        # - 15 permissions / 10 = 1.5 x 1 (1 point)
        $PermissionVolumePoints = [Math]::Floor($TotalPermissionCount / 10) * $Weights.PermissionVolume.PointsPer10Permissions
        $Score += $PermissionVolumePoints
        $ScoreBreakdown.PermissionVolume = [PSCustomObject]@{
            TotalPermissions = $TotalPermissionCount
            TotalPoints = $PermissionVolumePoints
        }

        return [PSCustomObject]@{
            SeverityScore  = $Score
            ScoreBreakdown = $ScoreBreakdown
        }
    }
    catch {
        Write-Warning "An error occurred in Set-SeverityScore: $($_.Exception.Message)"
        Write-Warning "Stack trace: $($_.ScriptStackTrace)"
        throw $_
    }
}

# Keep Get-RiskyAppPermissionsJson exported for cross-module usage in AADHybridExchangeHelper.
Export-ModuleMember -Function @(
    "Get-RiskyAppPermissionsJson",
    "Format-Credentials",
    "Get-ApplicationsWithRiskyPermissions",
    "Get-ServicePrincipalsWithRiskyPermissions",
    "Format-RiskyApplications",
    "Format-RiskyThirdPartyServicePrincipals",
    "Get-SeverityScoreWeights",
    "Get-ServicePrincipalsWithRiskyDelegatedPermissionClassifications"
)
