Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All"

$permissionsJson = (Get-Content -Path "./riskyPermissions.json" | ConvertFrom-Json).permissions
$results = @()
<#$servicePrincipals = Get-MgServicePrincipal -All
foreach ($servicePrincipal in $servicePrincipals) {
    $appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $servicePrincipal.Id
    $mappedPermissions = @()
    foreach ($role in $appRoleAssignments) {
        $resourceDisplayName = $role.ResourceDisplayName
        $roleId = $role.AppRoleId

        $riskyPermissions = $permissionsJson.$resourceDisplayName.PSObject.Properties.Name
        if ($riskyPermissions -contains $roleId) {
            $mappedPermissions += $permissionsJson.$resourceDisplayName.$roleId
        }
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
    $results += [PSCustomObject]@{
        'Object ID' = $servicePrincipal.Id
        'App ID' = $servicePrincipal.AppId
        'Display Name' = $servicePrincipal.DisplayName
        'Risky Permissions' = $mappedPermissions
    }
}

#$results = $results | Where-Object { $_."Risky Permissions".Count -gt 0 }
$results | Format-List > finalSPResults.txt
#>

$applications = Get-MgApplication -All
foreach ($app in $applications) { 
    $app | Format-List
    #$federatedCredentials = Get-MgApplicationFederatedIdentityCredential -ApplicationId $app.Id
    #$federatedCredentials | Format-List >> appregistrations.txt


}


#
#$results = @()
#foreach ($App in $apps) {
#    Write-Verbose -Message "Application Name : $($app.DisplayName) :: $($App.id)"
#    if ($App.PasswordCredentials.Count -ne 0 -or $App.KeyCredentials.Count -ne 0) {
#        $hit = $false
#        foreach ($permission in $App.RequiredResourceAccess) {
#            Write-Verbose -Message "Permission :: $permission"
#            $resource_id = $permission.ResourceAppId 
#            $requiredRoles = $permission.ResourceAccess.Id
#            foreach ($category in $defs.$resource_id.PSObject.Properties.Name) {
#                Write-Verbose -Message "Category :: $category"
#                $risky = $defs.$resource_id.$category.PSObject.Properties.Name
#                $res = Compare-Object -ReferenceObject $risky -DifferenceObject $requiredRoles -PassThru -IncludeEqual -ExcludeDifferent
#                if ($res -ne $null) {
#                    $Permissions = Get-ApplicationPermissions -App $App -Permissions $defs
#                    
#                    $results += [PSCustomObject]@{
#                        'Object ID'            = $App.ObjectId
#                        'App ID'               = $App.AppId
#                        'Display Name'         = $App.DisplayName
#                        'Key Credentials'      = ($App.KeyCredentials | Out-String)
#                        'Password Credentials' = ($App.PasswordCredentials | Out-String)
#                        'Risky Permissions'    = ($Permissions | Out-String)
#                    }
#                
#                    $hit = $True
#                    break
#                }
#            }
#            if ($hit) {
#                break
#            }
#        }
#    }
#}

<#
$service_principals = Get-AzureADServicePrincipal -All $True

            $results = @()
            $first_party_sps = @()
            foreach ($service_principal in $service_principals) {
                if (($service_principal.PasswordCredentials.Count -ne 0 -or $service_principal.KeyCredentials.Count -ne 0)) {
                    if (($service_principal.AppOwnerTenantId -eq 'f8cdef31-a31e-4b4a-93e4-5f571e91255a')) {
                        $first_party_sps += [PSCustomObject]@{
                            'Object ID'            = $service_principal.ObjectId
                            'App ID'               = $service_principal.AppId
                            'Display Name'         = $service_principal.DisplayName
                            'Key Credentials'      = ($service_principal.KeyCredentials | Out-String)
                            'Password Credentials' = ($service_principal.PasswordCredentials | Out-String)
                        }
                    }
                    else {
                        $app_roles = $service_principal | Get-AzureADServiceAppRoleAssignedTo
                        $hit = $false
                        foreach ($app_role in $app_roles) {
                            $resource_name = $app_role.ResourceDisplayName
                            $perm = $app_role.Id

                            foreach ($category in $defs.$resource_name.PSObject.Properties.Name) {
                                $risky = $defs.$resource_name.$category.PSObject.Properties.Name
                                if ($risky -contains $perm) {
                                    $perms = Get-ServicePrincipalPermissions -Assignments $app_roles -Permissions $defs

                                    $results += [PSCustomObject]@{
                                        'Object ID'            = $service_principal.ObjectId
                                        'App ID'               = $service_principal.AppId
                                        'Display Name'         = $service_principal.DisplayName
                                        'Key Credentials'      = ($service_principal.KeyCredentials | Out-String)
                                        'Password Credentials' = ($service_principal.PasswordCredentials | Out-String)
                                        'Risky Permissions'    = ($perms | Out-String)
                                    }
                                    
                                    $hit = $True
                                    break
                                }
                            }
                            if ($hit) {
                                break
                            }
                        }
                    }
                }
            }

            foreach ($result in $results) {
                Write-Host -Object $result
            }
#>

