using module "..\..\ScubaConfig\ScubaConfig.psm1"

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

function Format-RiskyPermission {
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

        [ValidateNotNullOrEmpty()]
        [boolean]
        $IsAdminConsented
    )

    $RiskyPermissions = $Json.permissions.$AppDisplayName.PSObject.Properties.Name
    $Map = @()
    if ($RiskyPermissions -contains $Id) {
        $Map += [PSCustomObject]@{
            RoleId                 = $Id
            RoleDisplayName        = $Json.permissions.$AppDisplayName.$Id
            ApplicationDisplayName = $AppDisplayName
            IsAdminConsented       = $IsAdminConsented
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

function Get-ApplicationsWithRiskyPermissions {
    <#
    .Description
    Returns an array of applications where each item contains its Object ID, App ID, Display Name,
    Key/Password/Federated Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>
    process {
        try {
            $RiskyPermissionsJson = Get-RiskyPermissionsJson
            $Applications = Get-MgBetaApplication -All
            $ApplicationResults = @()
            foreach ($App in $Applications) {
                # `AzureADMyOrg` = single tenant; `AzureADMultipleOrgs` = multi tenant
                $IsMultiTenantEnabled = $false
                if ($App.SignInAudience -eq "AzureADMultipleOrgs") { $IsMultiTenantEnabled = $true }

                # Map application permissions against RiskyPermissions.json
                $MappedPermissions = @()
                foreach ($Resource in $App.RequiredResourceAccess) {
                    # Exclude delegated permissions with property Type="Scope"
                    $Roles = $Resource.ResourceAccess | Where-Object { $_.Type -eq "Role" }
                    $ResourceAppId = $Resource.ResourceAppId

                    # Additional processing is required to determine if a permission is admin consented.
                    # Initially assume admin consent is false since we reference the application's manifest,
                    # then update the value later when its compared to service principal permissions.
                    $IsAdminConsented = $false

                    # Only map on resources stored in RiskyPermissions.json file
                    if ($RiskyPermissionsJson.resources.PSObject.Properties.Name -contains $ResourceAppId) {
                        foreach($Role in $Roles) {
                            $ResourceDisplayName = $RiskyPermissionsJson.resources.$ResourceAppId
                            $RoleId = $Role.Id
                            $MappedPermissions += Format-RiskyPermission `
                                -Json $RiskyPermissionsJson `
                                -AppDisplayName $ResourceDisplayName `
                                -Id $RoleId `
                                -IsAdminConsented $IsAdminConsented
                        }
                    }
                }

                $FederatedCredentials = Get-MgBetaApplicationFederatedIdentityCredential -All -ApplicationId $App.Id
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
                        RiskyPermissions     = $MappedPermissions
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
    process {
        try {
            $RiskyPermissionsJson = Get-RiskyPermissionsJson
            $ServicePrincipalResults = @()
            # Get all service principals excluding ones owned by Microsoft
            $ServicePrincipals = Get-MgBetaServicePrincipal -All | Where-Object { $_.AppOwnerOrganizationId -ne "f8cdef31-a31e-4b4a-93e4-5f571e91255a" }
            foreach ($ServicePrincipal in $ServicePrincipals) {
                # Only retrieves admin consented permissions
                $AppRoleAssignments = Get-MgBetaServicePrincipalAppRoleAssignment -All -ServicePrincipalId $ServicePrincipal.Id
                $MappedPermissions = @()
                if ($AppRoleAssignments.Count -gt 0) {
                    foreach ($Role in $AppRoleAssignments) {
                        $ResourceDisplayName = $Role.ResourceDisplayName
                        $RoleId = $Role.AppRoleId

                        # Default to true,
                        # `Get-MgBetaServicePrincipalAppRoleAssignment` only returns admin consented permissions
                        $IsAdminConsented = $true

                        # Only map on resources stored in RiskyPermissions.json file
                        if ($RiskyPermissionsJson.permissions.PSObject.Properties.Name -contains $ResourceDisplayName) {
                            $MappedPermissions += Format-RiskyPermission `
                                -Json $RiskyPermissionsJson `
                                -AppDisplayName $ResourceDisplayName `
                                -Id $RoleId `
                                -IsAdminConsented $IsAdminConsented
                        }
                    }
                }

                # Exclude service principals without risky permissions
                if ($MappedPermissions.Count -gt 0) {
                    $ServicePrincipalResults += [PSCustomObject]@{
                        ObjectId             = $ServicePrincipal.Id
                        AppId                = $ServicePrincipal.AppId
                        DisplayName          = $ServicePrincipal.DisplayName
                        # Credentials from application and service principal objects may get merged in other cmdlets.
                        # Differentiate between the two by setting IsFromApplication=$false
                        KeyCredentials       = Format-Credentials -AccessKeys $ServicePrincipal.KeyCredentials -IsFromApplication $false
                        PasswordCredentials  = Format-Credentials -AccessKeys $ServicePrincipal.PasswordCredentials -IsFromApplication $false
                        FederatedCredentials = $ServicePrincipal.FederatedIdentityCredentials
                        RiskyPermissions     = $MappedPermissions
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
                    foreach ($Permission in $App.RiskyPermissions) {
                        $ServicePrincipalRoleIds = $MatchedServicePrincipal.RiskyPermissions | Select-Object -ExpandProperty RoleId
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
                        RiskyPermissions         = $App.RiskyPermissions
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

function Get-ThirdPartyRiskyServicePrincipals {
    <#
    .Description
    Returns a JSON dataset of service principal objects owned by external organizations.
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
            $ServicePrincipals = @()
            foreach ($ServicePrincipal in $RiskySPs) {
                $MatchedApplication = $RiskyApps | Where-Object { $_.AppId -eq $ServicePrincipal.AppId }

                # If a service principal does not have an associated application registration,
                # then it is owned by an external organization.
                if ($null -eq $MatchedApplication) {
                    $ServicePrincipals += $ServicePrincipal
                }
            }
        }
        catch {
            Write-Warning "An error occurred in Get-ThirdPartyRiskyServicePrincipals: $($_.Exception.Message)"
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
    "Get-ThirdPartyRiskyServicePrincipals"
)