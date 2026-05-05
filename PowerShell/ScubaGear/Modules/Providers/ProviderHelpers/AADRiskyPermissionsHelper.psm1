Import-Module -Name $PSScriptRoot/../../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable

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

function Get-RiskyPermissionsJson {
    process {
        try {
            $PermissionsPath = Join-Path -Path ((Get-Item -Path $PSScriptRoot).Parent.Parent.FullName) -ChildPath "Permissions"
            $PermissionsJson = Get-Content -Path (
                Join-Path -Path (Get-Item -Path $PermissionsPath) -ChildPath "RiskyPermissions.json"
            ) | ConvertFrom-Json
        }
        catch {
            Write-Warning "An error occurred in Get-RiskyPermissionsJson: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $PermissionsJson
    }
}

function Format-Permission {
    <#
    .Description
    Returns an API permission from either application/service principal which maps
    to the list of permissions declared in RiskyPermissions.json
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
        $RiskyPermissions = $Json.permissions.$AppDisplayName.$RoleType.PSObject.Properties.Name
        $IsRisky = $RiskyPermissions -contains $Id
        $RiskLevel = $Json.permissions.$AppDisplayName.$RoleType.$Id.RiskLevel

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
        $ResourcePermissionCache
    )
    process {
        try {
            $RiskyPermissionsJson = Get-RiskyPermissionsJson
            # Get all applications in the tenant
            $Applications = (Invoke-GraphDirectly -commandlet "Get-MgBetaApplication" -M365Environment $M365Environment).Value
            $ApplicationResults = @()
            foreach ($App in $Applications) {
                # `AzureADMyOrg` = single tenant; `AzureADMultipleOrgs` = multi tenant
                $IsMultiTenantEnabled = $false
                if ($App.SignInAudience -eq "AzureADMultipleOrgs") { $IsMultiTenantEnabled = $true }

                # Map application permissions against RiskyPermissions.json
                $MappedPermissions = @()
                foreach ($Resource in $App.RequiredResourceAccess) {
                    # Returns both application and delegated permissions
                    $Roles = $Resource.ResourceAccess
                    $ResourceAppId = $Resource.ResourceAppId

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

                    # Only map on resources stored in RiskyPermissions.json file
                    if ($RiskyPermissionsJson.resources.PSObject.Properties.Name -contains $ResourceAppId) {
                        foreach ($Role in $Roles) {
                            $ResourceDisplayName = $RiskyPermissionsJson.resources.$ResourceAppId
                            $RoleId = $Role.Id

                            if ($Role.Type -eq "Role") {
                                $ReadableRoleType = "Application"
                                $RoleDisplayName = ($ResourceAppPermissions.appRoles | Where-Object { $_.id -eq $RoleId }).value
                                # Application permissions always require admin consent
                                $RequiresAdminConsent = $true
                            }
                            else {
                                $ReadableRoleType = "Delegated"
                                $OauthScope = $ResourceAppPermissions.oauth2PermissionScopes | Where-Object { $_.id -eq $RoleId }
                                $RoleDisplayName = $OauthScope.value
                                # Delegated permissions require admin consent if oauth2PermissionScopes.type equals "Admin"
                                $RequiresAdminConsent = $OauthScope.type -eq "Admin"
                            }

                            $MappedPermissions += Format-Permission `
                                -Json $RiskyPermissionsJson `
                                -AppDisplayName $ResourceDisplayName `
                                -Id $RoleId `
                                -RoleType $ReadableRoleType `
                                -RoleDisplayName $RoleDisplayName `
                                -IsAdminConsented $IsAdminConsented `
                                -RequiresAdminConsent $RequiresAdminConsent
                        }
                    }
                }

                # Get the application credentials via Invoke-GraphDirectly
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

                $RiskyPermissions = @($MappedPermissions | Where-Object { $_.IsRisky -eq $true })

                # Exclude applications without risky permissions
                if ($RiskyPermissions.Count -gt 0) {
                    $ApplicationResults += [PSCustomObject]@{
                        ObjectId             = $App.Id
                        AppId                = $App.AppId
                        DisplayName          = $App.DisplayName
                        IsMultiTenantEnabled = $IsMultiTenantEnabled
                        # Credentials from application and service principal objects may get merged in other cmdlets.
                        # Differentiate between the two by setting IsFromApplication=$true
                        KeyCredentials       = Format-Credentials -AccessKeys $App.KeyCredentials -IsFromApplication $true
                        PasswordCredentials  = Format-Credentials -AccessKeys $App.PasswordCredentials -IsFromApplication $true
                        FederatedCredentials = Format-Credentials -AccessKeys $FederatedCredentialsResults -IsFromApplication $true -IsFederated
                        Permissions          = $MappedPermissions
                    }
                }
            }
        } catch {
            Write-Warning "An error occurred in Get-ApplicationsWithRiskyPermissions: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $ApplicationResults
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
        $ResourcePermissionCache
    )
    process {
        try {
            $RiskyPermissionsJson = Get-RiskyPermissionsJson
            $ServicePrincipalResults = @()
            # Get all service principals
            $ServicePrincipals = (Invoke-GraphDirectly -commandlet "Get-MgBetaServicePrincipal" -M365Environment $M365Environment).Value

            # Prepare service principal IDs for batch processing
            $ServicePrincipalIds = $ServicePrincipals.Id

            # Split the service principal IDs into chunks of 20
            $Chunks = [System.Collections.Generic.List[System.Object]]::new()
            $ChunkSize = 20
            for ($i = 0; $i -lt $ServicePrincipalIds.Count; $i += $ChunkSize) {
                $Chunks.Add($ServicePrincipalIds[$i..([math]::Min($i + $ChunkSize - 1, $ServicePrincipalIds.Count - 1))])
            }

            $endpoint = '/beta/$batch'
            $endpoint = (Get-ScubaGearPermissions -CmdletName Connect-MgGraph -Environment $M365Environment -OutAs endpoint) + $endpoint

            # Process each chunk
            foreach ($Chunk in $Chunks) {
                $BatchBody = @{
                    Requests = @()
                }

                foreach ($ServicePrincipalId in $Chunk) {
                    $BatchBody.Requests += @{
                        id     = $ServicePrincipalId
                        method = "GET"
                        url    = "/servicePrincipals/$ServicePrincipalId/appRoleAssignments"
                    }
                }

                # Send the batch request
                $Response = Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body (
                    $BatchBody | ConvertTo-Json -Depth 5
                )

                # Check the response
                if ($Response.responses) {
                    foreach ($Result in $Response.responses) {
                        $ServicePrincipalId = $Result.id
                        $ServicePrincipal = $ServicePrincipals | Where-Object { $_.Id -eq $ServicePrincipalId }
                        $MappedPermissions = @()

                        if ($Result.status -eq 200) {
                            $AppRoleAssignments = $Result.body.value
                            if ($AppRoleAssignments.Count -gt 0) {
                                foreach ($Role in $AppRoleAssignments) {
                                    $ResourceDisplayName = $Role.ResourceDisplayName
                                    $RoleId = $Role.AppRoleId

                                    # Default to true,
                                    # `Get-MgBetaServicePrincipalAppRoleAssignment` only returns admin consented permissions
                                    $IsAdminConsented = $true

                                    # Only map on resources stored in RiskyPermissions.json file
                                    if ($RiskyPermissionsJson.permissions.PSObject.Properties.Name -contains $ResourceDisplayName) {
                                        $ResourceAppId = $RiskyPermissionsJson.resources.PSObject.Properties | Where-Object {
                                            $_.Value -eq $ResourceDisplayName
                                        } | Select-Object -ExpandProperty Name

                                        $ResourceAppPermissions = Get-ResourcePermissions `
                                            -M365Environment $M365Environment `
                                            -ResourcePermissionCache $ResourcePermissionCache `
                                            -ResourceAppId $ResourceAppId

                                        if ($null -eq $ResourceAppPermissions) {
                                            Write-Warning "No permissions found for resource app ID: $ResourceAppId"
                                            continue
                                        }

                                        $ReadableRoleType = $null
                                        $RoleDisplayName = $null

                                        $AppRole = $ResourceAppPermissions.appRoles | Where-Object { $_.id -eq $RoleId }
                                        if ($null -ne $AppRole) {
                                            $ReadableRoleType = "Application"
                                            $RoleDisplayName = $AppRole.value
                                            # Application permissions always require admin consent
                                            $RequiresAdminConsent = $true
                                        }
                                        else {
                                            $OauthScope = $ResourceAppPermissions.oauth2PermissionScopes | Where-Object { $_.id -eq $RoleId }
                                            if ($null -ne $OauthScope) {
                                                $ReadableRoleType = "Delegated"
                                                $RoleDisplayName = $OauthScope.value
                                                # Delegated permissions require admin consent if oauth2PermissionScopes.type equals "Admin"
                                                $RequiresAdminConsent = $OauthScope.type -eq "Admin"
                                            }
                                            else {
                                                # RoleId not found in either appRoles or oauth2PermissionScopes, skip permission
                                                continue
                                            }
                                        }

                                        $MappedPermissions += Format-Permission `
                                            -Json $RiskyPermissionsJson `
                                            -AppDisplayName $ResourceDisplayName `
                                            -Id $RoleId `
                                            -RoleType $ReadableRoleType `
                                            -RoleDisplayName $RoleDisplayName `
                                            -IsAdminConsented $IsAdminConsented `
                                            -RequiresAdminConsent $RequiresAdminConsent
                                    }
                                }
                            }
                        } else {
                            Write-Warning "Error for service principal $($Result.id): $($Result.status)"
                        }

                        $RiskyPermissions = @($MappedPermissions | Where-Object { $_.IsRisky -eq $true })

                        # Exclude service principals without risky permissions
                        if ($RiskyPermissions.Count -gt 0) {
                            $ServicePrincipalResults += [PSCustomObject]@{
                                ObjectId                = $ServicePrincipal.Id
                                AppId                   = $ServicePrincipal.AppId
                                DisplayName             = $ServicePrincipal.DisplayName
                                SignInAudience          = $ServicePrincipal.SignInAudience
                                # Credentials from application and service principal objects may get merged in other cmdlets.
                                # Differentiate between the two by setting IsFromApplication=$false
                                KeyCredentials          = Format-Credentials -AccessKeys $ServicePrincipal.KeyCredentials -IsFromApplication $false
                                PasswordCredentials     = Format-Credentials -AccessKeys $ServicePrincipal.PasswordCredentials -IsFromApplication $false
                                FederatedCredentials    = Format-Credentials -AccessKeys $ServicePrincipal.FederatedIdentityCredentials -IsFromApplication $false -IsFederated
                                Permissions             = $MappedPermissions
                                AppOwnerOrganizationId  = $ServicePrincipal.AppOwnerOrganizationId
                            }
                        }
                    }
                }
            }
        } catch {
            Write-Warning "An error occurred in Get-ServicePrincipalsWithRiskyPermissions: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $ServicePrincipalResults
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
        $M365Environment
    )
    process {
        try {
            $RiskyPermissionsJson = Get-RiskyPermissionsJson
            $Resources = $RiskyPermissionsJson.resources.PSObject.Properties


            $RiskyDelegatedPermissionClassificationResults = @()
            foreach ($Resource in $Resources) {
                $ResourceId = $Resource.Name
                $ResourceName = $Resource.Value

                $ServicePrincipal = (
                    Invoke-GraphDirectly `
                        -Commandlet "Get-MgServicePrincipal" `
                        -M365Environment $M365Environment `
                        -QueryParams @{
                            '$filter' = "appId eq '$ResourceId'"
                        }
                    ).Value

                $ServicePrincipalId = $ServicePrincipal.id

                $RiskyDelegatedPermissions = $RiskyPermissionsJson.permissions.$ResourceName.Delegated.PSObject.Properties

                $PermClassifications = (Invoke-GraphDirectly -commandlet "Get-MgBetaServicePrincipalDelagatedPermissionClassifications" -M365Environment $M365Environment -ID $ServicePrincipalId).Value

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
                    # Determine if each risky permission was admin consented or not
                    foreach ($Permission in $App.Permissions) {
                        $ServicePrincipalRoleIds = $MatchedServicePrincipal.Permissions | Select-Object -ExpandProperty RoleId
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

        # Context factors (25 points max)
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

        [ValidateNotNullOrEmpty()]
        [int]
        $BasePointsPerCredential,

        [array]
        $LifetimeTiers,

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
    }

    $CredentialPoints += $CurrentCredentialPoints

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
            $Weights.RiskLevelWeights[$_.RiskLevel]
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
            $Weights.RiskLevelWeights[$_.RiskLevel]
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
        foreach ($Permission in $AllRiskyPermissions) {
            switch ($Permission.RiskLevel) {
                "Critical" { $HighestRiskLevel = $Weights.CredentialContextWeights.Critical; break }
                "High" { $HighestRiskLevel = $Weights.CredentialContextWeights.High; break }
                "Medium" { $HighestRiskLevel = $Weights.CredentialContextWeights.Medium; break }
                "Low" { $HighestRiskLevel = $Weights.CredentialContextWeights.Low; break }
                default { $HighestRiskLevel = 0 }
            }
        }
        $CredentialBasePoints = $HighestRiskLevel

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
            SeverityScore = $Score
            ScoreBreakdown = $ScoreBreakdown
        }
    }
    catch {
        Write-Warning "An error occurred in Set-SeverityScore: $($_.Exception.Message)"
        Write-Warning "Stack trace: $($_.ScriptStackTrace)"
        throw $_
    }
}

Export-ModuleMember -Function @(
    "Get-RiskyPermissionsJson",
    "Format-Credentials",
    "Get-ApplicationsWithRiskyPermissions",
    "Get-ServicePrincipalsWithRiskyPermissions",
    "Format-RiskyApplications",
    "Format-RiskyThirdPartyServicePrincipals",
    "Get-ServicePrincipalsWithRiskyDelegatedPermissionClassifications"
)
