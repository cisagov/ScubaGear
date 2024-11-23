Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All"

function Format-RiskyPermissions {
    <#
    .Description
    Returns an array of API permissions from either application/service principal which map
    to the list of permissions declared in the riskyPermissions.json file
    .Functionality
    #Internal
    ##>
    param (
        #[ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $Json,

        #[ValidateNotNullOrEmpty()]
        [Object[]]
        $Map,

        #[ValidateNotNullOrEmpty()]
        [string]
        $Resource,

        #[ValidateNotNullOrEmpty()]
        [string]
        $Id,

        #[ValidateNotNullOrEmpty()]
        [boolean]
        $IsAdminConsented
    )

    $RiskyPermissions = $Json.permissions.$Resource.PSObject.Properties.Name
    if ($RiskyPermissions -contains $Id) {
        $Map += [PSCustomObject]@{
            RoleId = $Id
            RoleDisplayName = $Json.permissions.$Resource.$Id
            ResourceDisplayName = $Resource
            IsAdminConsented = $IsAdminConsented
        }
    }
    return $Map
}

function Get-ValidCredentials {
    <#
    .Description
    Returns an array of valid credentials, expired credentials are excluded
    .Functionality
    #Internal
    ##>
    param (
        #[ValidateNotNullOrEmpty()]
        [Array[]]
        $Credentials,

        [boolean]
        $IsFromApplication
    )

    $ValidCredentials = @()
    foreach ($Credential in $Credentials) {
        if ($Credential.EndDateTime -gt (Get-Date)) {
            # $credential is of type PSCredential which is immutable, create a copy
            $CredentialCopy = $Credential | Select-Object *, @{
                Name = "IsFromApplication"; 
                Expression = { $IsFromApplication }
            }
            $ValidCredentials += $CredentialCopy
        }
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
        [Object[]]
        $ApplicationCredentials,

        [Object[]]
        $ServicePrincipalCredentials
    )
    # Both applications/sp objects have key and federated credentials.
    # Conditionally merge the two together, select only application/service principal creds, or none.
    $MergedCredentials = @()
    # Both objects valid
    if ($null -ne $ServicePrincipalCredentials -and $null -ne $ApplicationCredentials) {
        $MergedCredentials = @($ServicePrincipalCredentials) + @($ApplicationCredentials)
    }
    # Only application credentials valid
    elseif ($null -eq $ServicePrincipalCredentials -and $null -ne $ApplicationCredentials) {
        $MergedCredentials = @($ApplicationCredentials)
    }
    # Only service principal credentials valid
    elseif ($null -ne $ServicePrincipalCredentials -and $null -eq $ApplicationCredentials) {
        $MergedCredentials = @($ServicePrincipalCredentials)
    }
    # Neither credentials are valid
    else {
        $MergedCredentials = $null
    }
    return $MergedCredentials
}

$PermissionsJson = (Get-Content -Path "./riskyPermissions.json" | ConvertFrom-Json)

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
                # "AzureADMyOrg" = single tenant
                # "AzureADMultipleOrgs" = multi tenant
                $IsMultiTenantEnabled = $false
                if ($App.signInAudience -eq "AzureADMultipleOrgs") { $IsMultiTenantEnabled = $true }
            
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
                            Id = $federatedCredential.Id
                            Name = $federatedCredential.Name
                            Description = $federatedCredential.Description
                            Issuer = $federatedCredential.Issuer
                            Subject = $federatedCredential.Subject
                            Audiences = $federatedCredential.Audiences | Out-String
                        }
                    }
                }
                else {
                    $FederatedCredentialsResults = $null
                }
            
                # Disregard entries without risky permissions
                if ($MappedPermissions.Count -gt 0) {
                    $ApplicationResults += [PSCustomObject]@{
                        ObjectId = $App.Id
                        AppId = $App.AppId
                        DisplayName = $App.DisplayName
                        IsMultiTenantEnabled = $IsMultiTenantEnabled
                        KeyCredentials = Get-ValidCredentials -Credentials $App.KeyCredentials -IsFromApplication $true
                        PasswordCredentials = Get-ValidCredentials -Credentials $App.PasswordCredentials -IsFromApplication $true
                        FederatedCredentials = $FederatedCredentialsResults
                        RiskyPermissions = $MappedPermissions
                    }
                }
            }
        } catch {
            Write-Warning "An error occurred in Get-ApplicationsWithRiskyPermissions: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        $ApplicationResults | ConvertTo-Json -Depth 3
    }
}

$RiskyApps = Get-ApplicationsWithRiskyPermissions
$RiskyApps > finalAppResults.json

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
                        ObjectId = $ServicePrincipal.Id
                        AppId = $ServicePrincipal.AppId
                        DisplayName = $ServicePrincipal.DisplayName
                        KeyCredentials = Get-ValidCredentials -Credentials $ServicePrincipal.KeyCredentials -IsFromApplication $false
                        PasswordCredentials = Get-ValidCredentials -Credentials $ServicePrincipal.PasswordCredentials -IsFromApplication $false
                        RiskyPermissions = $MappedPermissions
                    }
                }
            }
        } catch {
            Write-Warning "An error occurred in Get-ApplicationsWithRiskyPermissions: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        $ServicePrincipalResults | ConvertTo-Json -Depth 3
    }
}

$RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
$RiskySPs > finalSPResults.json

$RiskyApps = (Get-Content -Path "./finalAppResults.json" | ConvertFrom-Json)
$RiskySPs = (Get-Content -Path "./finalSPResults.json" | ConvertFrom-Json)

function Get-AggregatedRiskyServicePrincipals {
    <#
    .Description
    Returns an aggregated JSON dataset, combining data from both applications and service principal objects.
    Key/Password/Federated credentials are combined into a single object, and admin consent is reflected
    in each object's list of associated risky permissions.
    .Functionality
    #Internal
    ##>
    process {
        try {
            $AggregatedResults = @()
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
                
                    $MergedKeyCredentials = Merge-Credentials `
                        -ApplicationCredentials $App.KeyCredentials `
                        -ServicePrincipalCredentials $MatchedServicePrincipal.KeyCredentials
                    $MergedPasswordCredentials = Merge-Credentials `
                        -ApplicationCredentials $App.PasswordCredentials `
                        -ServicePrincipalCredentials $MatchedServicePrincipal.PasswordCredentials
                
                    $MergedObject = [PSCustomObject]@{
                        ApplicationObjectId = $App.ObjectId
                        ServicePrincipalObjectId = $MatchedServicePrincipal.ObjectId
                        AppId = $App.AppId
                        DisplayName = $App.DisplayName
                        IsMultiTenantEnabled = $App.IsMultiTenantEnabled
                        KeyCredentials = $MergedKeyCredentials
                        PasswordCredentials = $MergedPasswordCredentials
                        FederatedCredentials = $App.FederatedCredentials
                        RiskyPermissions = $App.RiskyPermissions
                    }
                }
                else {
                    $MergedObject = $App
                }
                $AggregatedResults += $MergedObject
            }
        }
        catch {
            Write-Warning "An error occurred in Get-AggregatedRiskyServicePrincipals: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        $AggregatedResults | ConvertTo-Json -Depth 3
    }
}

$AggregatedRiskySPs = Get-AggregatedRiskyServicePrincipals
$AggregatedRiskySPs > aggregatedResults.json