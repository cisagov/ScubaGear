$PermissionsPath = Join-Path -Path ((Get-Item -Path $PSScriptRoot).Parent.Parent.FullName) -ChildPath "Permissions"
$PermissionsJson = (
    Get-Content -Path ( `
        Join-Path -Path $PermissionsPath -ChildPath "RiskyPermissions.json" `
    ) | ConvertFrom-Json
)

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
        $Resource,

        [ValidateNotNullOrEmpty()]
        [string]
        $Id,

        [ValidateNotNullOrEmpty()]
        [boolean]
        $IsAdminConsented
    )

    $RiskyPermissions = $Json.permissions.$Resource.PSObject.Properties.Name
    $Map = @()
    if ($RiskyPermissions -contains $Id) {
        $Map += [PSCustomObject]@{
            RoleId              = $Id
            RoleDisplayName     = $Json.permissions.$Resource.$Id
            ResourceDisplayName = $Resource
            IsAdminConsented    = $IsAdminConsented
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
                    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "IsFromApplication")]
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

    # Both applications/sp objects have key and federated credentials.
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

                    foreach($Role in $Roles) {
                        $ResourceDisplayName = $PermissionsJson.resources.$ResourceAppId
                        $RoleId = $Role.Id
                        $MappedPermissions += Format-RiskyPermission `
                            -Json $PermissionsJson `
                            -Resource $ResourceDisplayName `
                            -Id $RoleId `
                            -IsAdminConsented $IsAdminConsented
                    }
                }

                $FederatedCredentials = Get-MgBetaApplicationFederatedIdentityCredential -All -ApplicationId $App.Id
                $FederatedCredentialsResults = @()

                if ($null -ne $FederatedCredentials) {
                    foreach ($federatedCredential in $FederatedCredentials) {
                        $FederatedCredentialsResults += [PSCustomObject]@{
                            Id          = $federatedCredential.Id
                            Name        = $federatedCredential.Name
                            Description = $federatedCredential.Description
                            Issuer      = $federatedCredential.Issuer
                            Subject     = $federatedCredential.Subject
                            Audiences   = $federatedCredential.Audiences | Out-String
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
            $ServicePrincipalResults = @()
            $ServicePrincipals = Get-MgBetaServicePrincipal -All
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
                        $MappedPermissions += Format-RiskyPermission `
                            -Json $PermissionsJson `
                            -Resource $ResourceDisplayName `
                            -Id $RoleId `
                            -IsAdminConsented $IsAdminConsented
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

function Get-FirstPartyRiskyApplications {
    <#
    .Description
    Returns an aggregated JSON dataset of application objects, combining data from both applications and
    service principal objects. Key/Password/Federated credentials are combined into a single object, and
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

                    $MergedObject = [PSCustomObject]@{
                        ObjectId                 = $ObjectIds
                        AppId                    = $App.AppId
                        DisplayName              = $App.DisplayName
                        IsMultiTenantEnabled     = $App.IsMultiTenantEnabled
                        KeyCredentials           = Merge-Credentials -ApplicationAccessKeys $App.KeyCredentials `
                                                                     -ServicePrincipalAccessKeys $MatchedServicePrincipal.KeyCredentials
                        PasswordCredentials      = Merge-Credentials -ApplicationAccessKeys $App.PasswordCredentials `
                                                                     -ServicePrincipalAccessKeys $MatchedServicePrincipal.PasswordCredentials
                        FederatedCredentials     = Merge-Credentials -ApplicationAccessKeys $App.FederatedCredentials `
                                                                     -ServicePrincipalAccessKeys $MatchedServicePrincipal.FederatedCredentials
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
            Write-Warning "An error occurred in Get-FirstPartyRiskyApplications: $($_.Exception.Message)"
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
    'Get-ApplicationsWithRiskyPermissions',
    'Get-ServicePrincipalsWithRiskyPermissions',
    'Get-FirstPartyRiskyApplications',
    'Get-ThirdPartyRiskyServicePrincipals'
)