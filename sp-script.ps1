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
        $json,

        #[ValidateNotNullOrEmpty()]
        [Object[]]
        $map,

        #[ValidateNotNullOrEmpty()]
        [string]
        $resource,

        #[ValidateNotNullOrEmpty()]
        [string]
        $id
    )

    $riskyPermissions = $json.permissions.$resource.PSObject.Properties.Name
    if ($riskyPermissions -contains $id) {
        $map += [PSCustomObject]@{
            RoleId = $id
            RoleDisplayName = $json.permissions.$resource.$id
            ResourceDisplayName = $resource
        }
    }

    $map
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
        $credentials,

        [boolean]
        $IsFromApplication
    )

    $validCredentials = @()
    foreach ($credential in $credentials) {
        if ($credential.EndDateTime -gt (Get-Date)) {
            # $credential is of type PSCredential which is immutable, so create a copy
            $credentialCopy = $credential | Select-Object *, @{Name = "IsFromApplication"; Expression = { $IsFromApplication }}
            $validCredentials += $credentialCopy
        }
    }
    return $validCredentials
}

$permissionsJson = (Get-Content -Path "./riskyPermissions.json" | ConvertFrom-Json)

function Get-ApplicationsWithRiskyPermissions {
    <#
    .Description
    Returns an array of applications where each item contains its Object ID, App ID, Display Name,
    Key/Password/Federated Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>

    try {
        $applications = Get-MgBetaApplication -All
        $applicationResults = @()
        foreach ($app in $applications) {
            # "AzureADMyOrg" = single tenant
            # "AzureADMultipleOrgs" = multi tenant
            $IsMultiTenantEnabled = $false
            if ($app.signInAudience -eq "AzureADMultipleOrgs") { $IsMultiTenantEnabled = $true }
        
            # Map permissions assigned to application to risky permissions
            $mappedPermissions = @()
            foreach ($resource in $app.RequiredResourceAccess) {
                # Exclude delegated permissions with property Type="Scope"
                $roles = $resource.ResourceAccess | Where-Object { $_.Type -eq "Role" }
                $resourceAppId = $resource.ResourceAppId
        
                foreach($role in $roles) {
                    $resourceDisplayName = $permissionsJson.resources.$resourceAppId
                    $roleId = $role.Id
                    $mappedPermissions = Format-RiskyPermissions `
                        -Json $permissionsJson `
                        -Map $mappedPermissions `
                        -Resource $resourceDisplayName `
                        -Id $roleId
                }
            }
        
            # Get federated credentials
            $federatedCredentials = Get-MgBetaApplicationFederatedIdentityCredential -All -ApplicationId $app.Id
            $federatedCredentialsResults = @()
        
            if ($null -ne $federatedCredentials) {
                foreach ($federatedCredential in $federatedCredentials) {
                    $federatedCredentialsResults += [PSCustomObject]@{
                        Id = $federatedCredential.Id
                        Name = $federatedCredential.Name
                        Description = $federatedCredential.Description
                        Issuer = $federatedCredential.Issuer
                        Subject = $federatedCredential.Subject
                        Audiences = $federatedCredential.Audiences | Out-String
                    }
                }
            }
        
            # Disregard entries without risky permissions
            if ($mappedPermissions.Count -gt 0) {
                $applicationResults += [PSCustomObject]@{
                    ObjectId = $app.Id
                    AppId = $app.AppId
                    DisplayName = $app.DisplayName
                    IsMultiTenantEnabled = $IsMultiTenantEnabled
                    KeyCredentials = Get-ValidCredentials -Credentials $app.KeyCredentials -IsFromApplication $true
                    PasswordCredentials = Get-ValidCredentials -Credentials $app.PasswordCredentials -IsFromApplication $true
                    FederatedCredentials = $federatedCredentials
                    RiskyPermissions = $mappedPermissions
                }
            }
        }
    } catch {
        Write-Warning "An error occurred in Get-ApplicationsWithRiskyPermissions: $($_.Exception.Message)"
        Write-Warning "Stack trace: $($_.ScriptStackTrace)"
        throw $_
    }
    $applicationResults | ConvertTo-Json -Depth 3
}

#$riskyApps = Get-ApplicationsWithRiskyPermissions
#$riskyApps > finalAppResults.json

function Get-ServicePrincipalsWithRiskyPermissions {
    <#
    .Description
    Returns an array of service principals where each item contains its Object ID, App ID, Display Name,
    Key/Password Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>
    try {
        $servicePrincipalResults = @()
        $servicePrincipals = Get-MgBetaServicePrincipal -All
        foreach ($servicePrincipal in $servicePrincipals) {
            # Only retrieves permissions an admin has consented to
            $appRoleAssignments = Get-MgBetaServicePrincipalAppRoleAssignment -All -ServicePrincipalId $servicePrincipal.Id
            $mappedPermissions = @()
            if ($appRoleAssignments.Count -gt 0) {
                foreach ($role in $appRoleAssignments) {
                    $resourceDisplayName = $role.ResourceDisplayName
                    $roleId = $role.AppRoleId
                    $mappedPermissions = Format-RiskyPermissions `
                        -Json $permissionsJson `
                        -Map $mappedPermissions `
                        -Resource $resourceDisplayName `
                        -Id $roleId
                }
            }
        
            # Disregard entries without risky permissions
            if ($mappedPermissions.Count -gt 0) {
                $servicePrincipalResults += [PSCustomObject]@{
                    ObjectId = $servicePrincipal.Id
                    AppId = $servicePrincipal.AppId
                    DisplayName = $servicePrincipal.DisplayName
                    KeyCredentials = Get-ValidCredentials -Credentials $servicePrincipal.KeyCredentials -IsFromApplication $false
                    PasswordCredentials = Get-ValidCredentials -Credentials $servicePrincipal.PasswordCredentials -IsFromApplication $false
                    RiskyPermissions = $mappedPermissions
                }
            }
        }
    } catch {
        Write-Warning "An error occurred in Get-ApplicationsWithRiskyPermissions: $($_.Exception.Message)"
        Write-Warning "Stack trace: $($_.ScriptStackTrace)"
        throw $_
    }
    $servicePrincipalResults | ConvertTo-Json -Depth 3
}

#$servicePrincipalResults = $servicePrincipalResults | Where-Object { $_."Risky Permissions".Count -gt 0 }

#$riskySPs = Get-ServicePrincipalsWithRiskyPermissions
#$riskySPs > finalSPResults.json

$riskyApps = (Get-Content -Path "./finalAppResults.json" | ConvertFrom-Json)
$riskySPs = (Get-Content -Path "./finalSPResults.json" | ConvertFrom-Json)

$aggregatedResults = @()
foreach ($app in $riskyApps) {
    $matchedServicePrincipal = $riskySPs | Where-Object { $_.AppId -eq $app.AppId }

    # Merge objects if an application and service principal exist with the same AppId
    if ($matchedServicePrincipal) {
        # iterate over app permissions
        # if the permissions is contained in sp permission list, then change "IsAdminConsented" from false to true
        # if not, keep set to false

        # Determine if each risky permission was admin consented or not
        foreach ($permission in $app.RiskyPermissions) {
            $permission | Add-Member -MemberType NoteProperty -Name "IsAdminConsented" -Value $false
            $ServicePrincipalRoleIds = $matchedServicePrincipal.RiskyPermissions | Select-Object -ExpandProperty RoleId
            if ($ServicePrincipalRoleIds -contains $permission.RoleId) {
                $permission.IsAdminConsented = $true
            }
        }

        if ($matchedServicePrincipal.KeyCredentials.Count -gt 0) {
            $mergedKeyCredentials = @($app.KeyCredentials) + @($matchedServicePrincipal.KeyCredentials)
        }

        if ($matchedServicePrincipal.PasswordCredentials.Count -gt 0) {
            $mergedKeyCredentials = @($app.PasswordCredentials) + @($matchedServicePrincipal.PasswordCredentials)
        }

        $mergedObject = [PSCustomObject]@{
            #ObjectId = [PSCustomerObject]@{
            #    ApplicationObjectId = $app.ObjectId
            #    ServicePrincipalObjectId = $matchedServicePrincipal.ObjectId
            #}
            AppId = $app.AppId
            DisplayName = $app.DisplayName
            IsMultiTenantEnabled = $app.IsMultiTenantEnabled
            KeyCredentials = $mergedKeyCredentials
            PasswordCredentials = $mergedPasswordCredentials
            FederatedCredentials = $app.FederatedCredentials
            RiskyPermissions = $app.RiskyPermissions
        }
    }
    else {
        $mergedObject = $app
    }

    $aggregatedResults += $mergedObject
}

$aggregatedResults | ConvertTo-Json > aggregatedResults.json
#$groupedAggregateResults = $aggregateResults | Group-Object -Property "App ID"
#$groupedAggregateResults | ConvertTo-Json > groupedAggregateResults.json