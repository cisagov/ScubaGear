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
        $IsAdminConsented
    )

    $RiskyPermissions = $Json.permissions.$AppDisplayName.PSObject.Properties.Name
    $Map = @()
    $IsRisky = $RiskyPermissions -contains $Id

    $Map += [PSCustomObject]@{
        RoleId                 = $Id
        RoleType               = if ($null -ne $RoleType) { $RoleType } else { $null }
        RoleDisplayName        = if ($null -ne $RoleDisplayName) { $RoleDisplayName } else { $null }
        ApplicationDisplayName = $AppDisplayName
        IsAdminConsented       = $IsAdminConsented
        IsRisky                = $IsRisky
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
        $IsFromApplication
    )

    process {
        $ValidCredentials = @()
        $RequiredKeys = @("KeyId", "DisplayName", "StartDateTime", "EndDateTime")
        foreach ($Credential in $AccessKeys) {
            # Only format credentials with the correct keys
            $MissingKeys = $RequiredKeys | Where-Object { -not ($Credential.PSObject.Properties.Name -contains $_) }
            if ($MissingKeys.Count -eq 0) {
                # $Credential is of type PSCredential which is immutable, create a copy
                $CredentialCopy = $Credential | Select-Object -Property `
                    KeyId, DisplayName, StartDateTime, EndDateTime, `
                    @{ Name = "IsFromApplication"; Expression = { $IsFromApplication }}
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

function Get-ServicePrincipalAll {
    <#
    .Description
    Returns all service principals in the tenant, this is used to determine if they have risky permissions.

    .PARAMETER
    M365Environment

    The M365 environment to use for the Graph API call. This is used to determine the correct endpoint for the API call.

    .EXAMPLE
    Get-ServicePrincipalAll -M365Environment commercial

    Returns all service principals in the tenant for the commercial environment.

    #>
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    # Initialize an empty array to store all service principals
    $allServicePrincipals = @()

    # Get the first page of results
    $result = Invoke-GraphDirectly -commandlet "Get-MgBetaServicePrincipal" -M365Environment $M365Environment

    # Add the current page of service principals to our collection
    if ($result.Value) {
        $allServicePrincipals += $result.Value
    }

    # Continue fetching next pages as long as there's a nextLink
    while ($result.'@odata.nextLink') {

        # Extract the URI from the nextLink
        $nextLink = $result.'@odata.nextLink'

        # Use the URI directly for the next request
        $result = Invoke-MgGraphRequest -Uri $nextLink -Method "GET"

        # Add the new page of results to our collection
        if ($result.Value) {
            $allServicePrincipals += $result.Value
        }
    }

    return $allServicePrincipals
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
                            }
                            else {
                                $ReadableRoleType = "Delegated"
                                $RoleDisplayName = ($ResourceAppPermissions.oauth2PermissionScopes | Where-Object { $_.id -eq $RoleId }).value
                            }

                            $MappedPermissions += Format-Permission `
                                -Json $RiskyPermissionsJson `
                                -AppDisplayName $ResourceDisplayName `
                                -Id $RoleId `
                                -RoleType $ReadableRoleType `
                                -RoleDisplayName $RoleDisplayName `
                                -IsAdminConsented $IsAdminConsented
                        }
                    }
                }

                # Get the application credentials via Invoke-GraphDirectly
                $FederatedCredentials = (Invoke-GraphDirectly -commandlet "Get-MgBetaApplicationFederatedIdentityCredential" -M365Environment $M365Environment -Id $App.Id).Value
                $FederatedCredentialsResults = @()

                if ($null -ne $FederatedCredentials) {
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

                # Exclude applications without risky permissions
                if ($MappedPermissions.Count -gt 0) {
                    $ApplicationResults += [PSCustomObject]@{
                        ObjectId             = $App.Id
                        AppId                = $App.AppId
                        DisplayName          = $App.DisplayName
                        IsMultiTenantEnabled = $IsMultiTenantEnabled
                        # Credentials from application and service principal objects may get merged in other cmdlets.
                        # Differentiate between the two by setting IsFromApplication=$true
                        KeyCredentials       = Format-Credentials -AccessKeys $App.KeyCredentials -IsFromApplication $true
                        PasswordCredentials  = Format-Credentials -AccessKeys $App.PasswordCredentials -IsFromApplication $true
                        FederatedCredentials = $FederatedCredentialsResults
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
            # Get all service principals including ones owned by Microsoft
            $ServicePrincipals = Get-ServicePrincipalAll -M365Environment $M365Environment

            # Prepare service principal IDs for batch processing
            $ServicePrincipalIds = $ServicePrincipals.Id

            # Split the service principal IDs into chunks of 20
            $Chunks = [System.Collections.Generic.List[System.Object]]::new()
            $ChunkSize = 20
            for ($i = 0; $i -lt $ServicePrincipalIds.Count; $i += $ChunkSize) {
                $Chunks.Add($ServicePrincipalIds[$i..([math]::Min($i + $ChunkSize - 1, $ServicePrincipalIds.Count - 1))])
            }

            $endpoint = '/beta/$batch'
            if ($M365Environment -eq "gcchigh") {
                $endpoint = "https://graph.microsoft.us" + $endpoint
            }
            elseif ($M365Environment -eq "dod") {
                $endpoint = "https://dod-graph.microsoft.us" + $endpoint
            }
            else {
                $endpoint = "https://graph.microsoft.com" + $endpoint
            }

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
                                        }
                                        else {
                                            $OauthScope = $ResourceAppPermissions.oauth2PermissionScopes | Where-Object { $_.id -eq $RoleId }
                                            if ($null -ne $OauthScope) {
                                                $ReadableRoleType = "Delegated"
                                                $RoleDisplayName = $OauthScope.value
                                            }
                                        }

                                        $MappedPermissions += Format-Permission `
                                            -Json $RiskyPermissionsJson `
                                            -AppDisplayName $ResourceDisplayName `
                                            -Id $RoleId `
                                            -RoleType $ReadableRoleType `
                                            -RoleDisplayName $RoleDisplayName `
                                            -IsAdminConsented $IsAdminConsented
                                    }
                                }
                            }
                        } else {
                            Write-Warning "Error for service principal $($Result.id): $($Result.status)"
                        }

                        # Exclude service principals without risky permissions
                        if ($MappedPermissions.Count -gt 0) {
                            $ServicePrincipalResults += [PSCustomObject]@{
                                ObjectId                = $ServicePrincipal.Id
                                AppId                   = $ServicePrincipal.AppId
                                DisplayName             = $ServicePrincipal.DisplayName
                                SignInAudience          = $ServicePrincipal.SignInAudience
                                # Credentials from application and service principal objects may get merged in other cmdlets.
                                # Differentiate between the two by setting IsFromApplication=$false
                                KeyCredentials          = Format-Credentials -AccessKeys $ServicePrincipal.KeyCredentials -IsFromApplication $false
                                PasswordCredentials     = Format-Credentials -AccessKeys $ServicePrincipal.PasswordCredentials -IsFromApplication $false
                                FederatedCredentials    = $ServicePrincipal.FederatedIdentityCredentials
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
        $RiskySPs
    )
    process {
        try {
            $ServicePrincipals = @()
            $OrgInfo = Get-MgBetaOrganization -ErrorAction "Stop"

            foreach ($ServicePrincipal in $RiskySPs) {
                if ($null -eq $ServicePrincipal) {
                    continue
                }

                # If the service principal's owner id is not the same as this tenant then it is a 3rd party principal
                if ($ServicePrincipal.AppOwnerOrganizationId -ne $OrgInfo.Id) {
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

Export-ModuleMember -Function @(
    "Get-ApplicationsWithRiskyPermissions",
    "Get-ServicePrincipalsWithRiskyPermissions",
    "Format-RiskyApplications",
    "Format-RiskyThirdPartyServicePrincipals"
)