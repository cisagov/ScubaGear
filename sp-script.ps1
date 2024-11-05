Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All"

function Map-RiskyPermissions {
    param (
        [PSCustomObject]$json,
        [Object[]]$map,
        [string]$resource,
        [string]$id
    )

    $riskyPermissions = $json.permissions.$resource.PSObject.Properties.Name
    if ($riskyPermissions -contains $id) {
        $map += $json.permissions.$resource.$id
    }

    return $map
}

$permissionsJson = (Get-Content -Path "./riskyPermissions.json" | ConvertFrom-Json)
$servicePrincipalResults = @()
$servicePrincipals = Get-MgServicePrincipal -All
foreach ($servicePrincipal in $servicePrincipals) {
    # Exclude Microsoft-published service principals 
    if ($servicePrincipal.AppOwnerOrganizationId -ne "f8cdef31-a31e-4b4a-93e4-5f571e91255a") {
        $appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipal.Id
        $mappedPermissions = @()

        foreach ($role in $appRoleAssignments) {
            $resourceDisplayName = $role.ResourceDisplayName
            $roleId = $role.AppRoleId
            $mappedPermissions = Map-RiskyPermissions -json $permissionsJson -map $mappedPermissions -resource $resourceDisplayName -id $roleId
        }

        ## Disregard entries without risky permissions
        #if ($mappedPermissions.Count -gt 0) {
        #    $riskyServicePrincipals += [PSCustomObject]@{
        #        'Object ID' = $servicePrincipal.Id
        #        'App ID' = $servicePrincipal.AppId
        #        'Display Name' = $servicePrincipal.DisplayName
        #        'Key Credentials' = $servicePrincipal.KeyCredentials
        #        'Password Credentials' = $servicePrincipal.PasswordCredentials
        #        'Risky Permissions' = $mappedPermissions
        #    }
        #}
        $servicePrincipalResults += [PSCustomObject]@{
            'Object ID' = $servicePrincipal.Id
            'App ID' = $servicePrincipal.AppId
            'Display Name' = $servicePrincipal.DisplayName
            'Key Credentials' = $servicePrincipal.KeyCredentials
            'Password Credentials' = $servicePrincipal.PasswordCredentials
            'Risky Permissions' = $mappedPermissions
        }
    }
}

$servicePrincipalResults = $servicePrincipalResults | Where-Object { $_."Risky Permissions".Count -gt 0 }
$servicePrincipalResults | Format-List > finalSPResults.txt


$applications = Get-MgApplication -All
$applicationResults = @()
foreach ($app in $applications) {

    # Map permissions assigned to application to risky permissions
    $mappedPermissions = @()
    foreach ($resource in $app.RequiredResourceAccess) {
        # Exclude delegated permissions with property Type="Scope"
        $roles = $resource.ResourceAccess | Where-Object { $_.Type -eq "Role" }
        $resourceAppId = $resource.ResourceAppId

        foreach($role in $roles) {
            $resourceDisplayName = $permissionsJson.resources.$resourceAppId
            $roleId = $role.Id
            $mappedPermissions = Map-RiskyPermissions -json $permissionsJson -map $mappedPermissions -resource $resourceDisplayName -id $roleId
        }
    }

    # Get federated credentials
    $federatedCredentials = Get-MgApplicationFederatedIdentityCredential -ApplicationId $app.Id

    # Reformat only if a credential exists
    if ($federatedCredentials -ne $null) {
        $federatedCredentials = [PSCustomObject]@{
            'Id' = $federatedCredentials.Id
            'Name' = $federatedCredentials.Name
            'Description' = $federatedCredentials.Description
            'Issuer' = $federatedCredentials.Issuer
            'Subject' = $federatedCredentials.Subject
            'Audiences' = $federatedCredentials.Audiences | Out-String
        }
    } else {
        $federatedCredentials = @{}
    }

    $applicationResults += [PSCustomObject]@{
        'Object ID' = $app.Id
        'App ID' = $app.AppId
        'Display Name' = $app.DisplayName
        'Key Credentials' = $app.KeyCredentials
        'Password Credentials' = $app.PasswordCredentials
        'Federated Credentials' = $federatedCredentials
        'Risky Permissions' = $mappedPermissions
    }
}

$applicationResults | Format-List > finalAppResults.txt