$PermissionsPath = Join-Path -Path ((Get-Item -Path $PSScriptRoot).Parent.Parent.FullName) -ChildPath "Permissions"
$PermissionsJson = (
    Get-Content -Path ( `
        Join-Path -Path $PermissionsPath -ChildPath "RiskyPermissions.json" `
    ) | ConvertFrom-Json
)

function Format-RiskyPermissions {
    <#
    .Description
    Returns an array of API permissions from either application/service principal which map
    to the list of permissions declared in the RiskyPermissions.json file
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $Json,

        # Initialized as empty array
        [Object[]]
        $Map,

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
    Returns an array of valid credentials, expired credentials are excluded
    .Functionality
    #Internal
    ##>
    param (
        [Object[]]
        $Credentials,

        [ValidateNotNullOrEmpty()]
        [boolean]
        $IsFromApplication
    )

    $ValidCredentials = @()
    foreach ($Credential in $Credentials) {
        # $Credential is of type PSCredential which is immutable, create a copy
        $CredentialCopy = $Credential | Select-Object -Property `
            KeyId, DisplayName, StartDateTime, EndDateTime, `
            @{ Name = "IsFromApplication"; Expression = { $IsFromApplication }}
        $ValidCredentials += $CredentialCopy
    }

    if ($null -eq $Credentials -or $Credentials.Count -eq 0 -or $ValidCredentials.Count -eq 0) {
        return $null
    }
    return $ValidCredentials
}

function Merge-Credentials {
    <#
    .Description
    Merge credentials from multiple resources into a single resource
    .Functionality
    #Internal
    ##>
    param (
        #[ValidateNotNullOrEmpty()]
        [Object[]]
        $ApplicationCredentials,

        #[ValidateNotNullOrEmpty()]
        [Object[]]
        $ServicePrincipalCredentials
    )

    # Both applications/sp objects have key and federated credentials.
    # Conditionally merge the two together, select only application/service principal creds, or none.
    $MergedCredentials = @()
    if ($null -ne $ServicePrincipalCredentials -and $null -ne $ApplicationCredentials) {
        # Both objects valid
        $MergedCredentials = @($ServicePrincipalCredentials) + @($ApplicationCredentials)
    }
    elseif ($null -eq $ServicePrincipalCredentials -and $null -ne $ApplicationCredentials) {
        # Only application credentials valid
        $MergedCredentials = @($ApplicationCredentials)
    }
    elseif ($null -ne $ServicePrincipalCredentials -and $null -eq $ApplicationCredentials) {
        # Only service principal credentials valid
        $MergedCredentials = @($ServicePrincipalCredentials)
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
            
                # Map permissions assigned to application to risky permissions
                $MappedPermissions = @()
                foreach ($Resource in $App.RequiredResourceAccess) {
                    # Exclude delegated permissions with property Type="Scope"
                    $Roles = $Resource.ResourceAccess | Where-Object { $_.Type -eq "Role" }
                    $ResourceAppId = $Resource.ResourceAppId
                    
                    # Additional processing is required to determine if a permission is admin consented.
                    # Initially assume admin consent is false since we are referencing the application's manifest,
                    # then update the value later when its compared to service principal permissions.
                    $IsAdminConsented = $false
            
                    foreach($Role in $Roles) {
                        $ResourceDisplayName = $PermissionsJson.resources.$ResourceAppId
                        $RoleId = $Role.Id
                        $MappedPermissions = Format-RiskyPermissions `
                            -Json $PermissionsJson `
                            -Map $MappedPermissions `
                            -Resource $ResourceDisplayName `
                            -Id $RoleId `
                            -IsAdminConsented $IsAdminConsented
                    }
                }
            
                # Get federated credentials
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
            
                # Disregard entries without risky permissions
                if ($MappedPermissions.Count -gt 0) {
                    $ApplicationResults += [PSCustomObject]@{
                        ObjectId             = $App.Id
                        AppId                = $App.AppId
                        DisplayName          = $App.DisplayName
                        IsMultiTenantEnabled = $IsMultiTenantEnabled
                        KeyCredentials       = Format-Credentials -Credentials $App.KeyCredentials -IsFromApplication $true
                        PasswordCredentials  = Format-Credentials -Credentials $App.PasswordCredentials -IsFromApplication $true
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
                # Only retrieves permissions an admin has consented to
                $AppRoleAssignments = Get-MgBetaServicePrincipalAppRoleAssignment -All -ServicePrincipalId $ServicePrincipal.Id
                $MappedPermissions = @()
                if ($AppRoleAssignments.Count -gt 0) {
                    foreach ($Role in $AppRoleAssignments) {
                        $ResourceDisplayName = $Role.ResourceDisplayName
                        $RoleId = $Role.AppRoleId

                        # `Get-MgBetaServicePrincipalAppRoleAssignment` only returns permissions that are admin consented
                        $IsAdminConsented = $true
                        $MappedPermissions = Format-RiskyPermissions `
                            -Json $PermissionsJson `
                            -Map $MappedPermissions `
                            -Resource $ResourceDisplayName `
                            -Id $RoleId `
                            -IsAdminConsented $IsAdminConsented
                    }
                }
            
                # Disregard entries without risky permissions
                if ($MappedPermissions.Count -gt 0) {
                    $ServicePrincipalResults += [PSCustomObject]@{
                        ObjectId             = $ServicePrincipal.Id
                        AppId                = $ServicePrincipal.AppId
                        DisplayName          = $ServicePrincipal.DisplayName
                        KeyCredentials       = Format-Credentials -Credentials $ServicePrincipal.KeyCredentials -IsFromApplication $false
                        PasswordCredentials  = Format-Credentials -Credentials $ServicePrincipal.PasswordCredentials -IsFromApplication $false
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
                        KeyCredentials           = Merge-Credentials -ApplicationCredentials $App.KeyCredentials -ServicePrincipalCredentials $MatchedServicePrincipal.KeyCredentials
                        PasswordCredentials      = Merge-Credentials -ApplicationCredentials $App.PasswordCredentials -ServicePrincipalCredentials $MatchedServicePrincipal.PasswordCredentials
                        FederatedCredentials     = Merge-Credentials -ApplicationCredentials $App.FederatedCredentials -ServicePrincipalCredentials $MatchedServicePrincipal.FederatedCredentials
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