function Format-RiskyPermissions {
    <#
    .Description
    Returns an array of API permissions from either application/service principal which map
    to the list of permissions declared in the riskyPermissions.json file
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $json,

        [ValidateNotNullOrEmpty()]
        [Object[]]
        $map,

        [ValidateNotNullOrEmpty()]
        [string]
        $resource,

        [ValidateNotNullOrEmpty()]
        [string]
        $id
    )

    $riskyPermissions = $json.permissions.$resource.PSObject.Properties.Name
    if ($riskyPermissions -contains $id) {
        $map += $json.permissions.$resource.$id
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
        [ValidateNotNullOrEmpty()]
        [Array[]]
        $credentials
    )

    $validCredentials = @()
    foreach ($credential in $credentials) {
        if ($credential.EndDateTime -gt (Get-Date)) { $validCredentials += $credential }
    }
    $validCredentials
}

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
        
            # Map permissions assigned to application to risky permissions
            $mappedPermissions = @()
            foreach ($resource in $app.RequiredResourceAccess) {
                # Exclude delegated permissions with property Type="Scope"
                $roles = $resource.ResourceAccess | Where-Object { $_.Type -eq "Role" }
                $resourceAppId = $resource.ResourceAppId
            
                foreach($role in $roles) {
                    $resourceDisplayName = $permissionsJson.resources.$resourceAppId
                    $roleId = $role.Id
                    $mappedPermissions = Format-RiskyPermissions -json $permissionsJson -map $mappedPermissions -resource $resourceDisplayName -id $roleId
                }
            }
        
            # Get federated credentials
            $federatedCredentials = Get-MgBetaApplicationFederatedIdentityCredential -ApplicationId $app.Id -All
            $federatedCredentialsResults = @()
        
            # Reformat only if a credential exists
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
                    'Key Credentials' = Get-ValidCredentials -credentials $app.KeyCredentials
                    'Password Credentials' = Get-ValidCredentials -credentials $app.PasswordCredentials
                    'Federated Credentials' = $federatedCredentials
                    'Risky Permissions' = $mappedPermissions
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

Export-ModuleMember -Function @(
    'Get-ApplicationsWithRiskyPermissions'
)