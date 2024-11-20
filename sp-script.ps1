Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All"

function Initialize-RiskyPermissions {
    param (
        [PSCustomObject]$Json,
        [Object[]]$Map,
        [string]$Resource,
        [string]$Id
    )

    $riskyPermissions = $json.permissions.$resource.PSObject.Properties.Name
    if ($riskyPermissions -contains $id) {
        $map += $json.permissions.$resource.$id
    }

    return $map
}

function Get-ValidCredentials {
    param(
        [Array[]]$Credentials,
        [boolean]$IsFromApplication
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
            $mappedPermissions = Initialize-RiskyPermissions -Json $permissionsJson -Map $mappedPermissions -Resource $resourceDisplayName -Id $roleId
        }
    }

    # Get federated credentials
    $federatedCredentials = Get-MgBetaApplicationFederatedIdentityCredential -All -ApplicationId $app.Id
    $federatedCredentialsResults = @()

    if ($null -ne $federatedCredentials) {
        foreach ($federatedCredential in $federatedCredentials) {
            $federatedCredentialsResults += [PSCustomObject]@{
                'Id' = $federatedCredential.Id
                'Name' = $federatedCredential.Name
                'Description' = $federatedCredential.Description
                'Issuer' = $federatedCredential.Issuer
                'Subject' = $federatedCredential.Subject
                'Audiences' = $federatedCredential.Audiences | Out-String
            }
        }
    }

    # Disregard entries without risky permissions
    if ($mappedPermissions.Count -gt 0) {
        $applicationResults += [PSCustomObject]@{
            'Object ID' = $app.Id
            'App ID' = $app.AppId
            'Display Name' = $app.DisplayName
            'IsMultiTenantEnabled' = $IsMultiTenantEnabled
            'Key Credentials' = Get-ValidCredentials -Credentials $app.KeyCredentials -IsFromApplication $true
            'Password Credentials' = Get-ValidCredentials -Credentials $app.PasswordCredentials -IsFromApplication $true
            'Federated Credentials' = $federatedCredentials
            'Risky Permissions' = $mappedPermissions
        }
    }
}

$applicationResults | ConvertTo-Json -Depth 3 > finalAppResults.json

$servicePrincipalResults = @()
$servicePrincipals = Get-MgBetaServicePrincipal -All
Write-Output $servicePrincipals.Count
foreach ($servicePrincipal in $servicePrincipals) {
    # Exclude Microsoft-published service principals
    #if ($servicePrincipal.AppOwnerOrganizationId -ne "f8cdef31-a31e-4b4a-93e4-5f571e91255a") {}

    # Only retrieves permissions an admin has consented to
    $appRoleAssignments = Get-MgBetaServicePrincipalAppRoleAssignment -All -ServicePrincipalId $servicePrincipal.Id
    $mappedPermissions = @()
    if ($appRoleAssignments.Count -gt 0) {
        foreach ($role in $appRoleAssignments) {
            $resourceDisplayName = $role.ResourceDisplayName
            $roleId = $role.AppRoleId
            $mappedPermissions = Initialize-RiskyPermissions -Json $permissionsJson -Map $mappedPermissions -Resource $resourceDisplayName -Id $roleId
        }
    }

    # Disregard entries without risky permissions
    if ($mappedPermissions.Count -gt 0) {
        $servicePrincipalResults += [PSCustomObject]@{
            'Object ID' = $servicePrincipal.Id
            'App ID' = $servicePrincipal.AppId
            'Display Name' = $servicePrincipal.DisplayName
            'Key Credentials' = Get-ValidCredentials -Credentials $servicePrincipal.KeyCredentials -IsFromApplication $false
            'Password Credentials' = Get-ValidCredentials -Credentials $servicePrincipal.PasswordCredentials -IsFromApplication $false
            'Risky Permissions' = $mappedPermissions
        }
    }
}

#$servicePrincipalResults = $servicePrincipalResults | Where-Object { $_."Risky Permissions".Count -gt 0 }
$servicePrincipalResults | ConvertTo-Json -Depth 3 > finalSPResults.json

$aggregateResults = $applicationResults + $servicePrincipalResults
$groupedAggregateResults = $aggregateResults | Group-Object -Property "App ID"
$groupedAggregateResults | ConvertTo-Json > groupedAggregateResults.json