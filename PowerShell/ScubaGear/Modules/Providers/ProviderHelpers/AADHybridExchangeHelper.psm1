Import-Module -Name $PSScriptRoot/../../Utility/Utility.psm1 -Function Invoke-GraphDirectly
Import-Module -Name $PSScriptRoot/AADRiskyPermissionsHelper.psm1 -Function Format-Credentials, Get-RiskyPermissionsJson

function Get-ExchangeHybridIds {
    <#
    .Description
    Look up the Office 365 Exchange Online app ID and full_access_as_app role ID
    from the RiskyPermissions.json reference.

    .Functionality
    Internal
    #>
    process {
        $RiskyPermissionsJson = Get-RiskyPermissionsJson

        # $ExchangeOnlineResource.Name  = appId (00000002-0000-0ff1-ce00-000000000000)
        # $ExchangeOnlineResource.Value = display name ("Office 365 Exchange Online")
        $ExchangeOnlineResource = $RiskyPermissionsJson.resources.PSObject.Properties | Where-Object {
            $_.Value -eq "Office 365 Exchange Online"
        } | Select-Object -First 1

        if ($null -eq $ExchangeOnlineResource) {
            throw "Could not find 'Office 365 Exchange Online' in RiskyPermissions.json."
        }

        # $FullAccessAsAppRoleId.Name  = role ID (dc890d15-9560-4a4c-9b7f-a736ec74ec40)
        # $FullAccessAsAppRoleId.Value = role name ("full_access_as_app")
        $FullAccessAsAppRoleId = $RiskyPermissionsJson.permissions.($ExchangeOnlineResource.Value).Application.PSObject.Properties | Where-Object {
            $_.Value -eq "full_access_as_app"
        } | Select-Object -First 1

        if ($null -eq $FullAccessAsAppRoleId) {
            throw "Could not find 'full_access_as_app' in RiskyPermissions.json under permissions.'$($ExchangeOnlineResource.Value)'.Application"
        }

        return @{
            ExchangeOnlineAppId = $ExchangeOnlineResource.Name
            FullAccessAsAppRoleId = $FullAccessAsAppRoleId.Name
        }
    }
}

function Get-LegacyExchangeServicePrincipal {
    <#
    .Description
    Queries for the first-party Microsoft "Office 365 Exchange Online" service principal, appId "00000002-0000-0ff1-ce00-000000000000".

    In legacy Exchange hybrid configurations, Exchange server authentication certificates were added directly as keyCredentials
    to this first-party Microsoft service principal. Microsoft has since required customers to remove these certificates and
    migrate to a new dedicated hybrid application.

    See resources below for more information:
    - https://learn.microsoft.com/en-us/Exchange/hybrid-deployment/deploy-dedicated-hybrid-app
    - https://microsoft.github.io/CSS-Exchange/Hybrid/ConfigureExchangeHybridApplication/
    - https://github.com/microsoft/CSS-Exchange/blob/main/Hybrid/ConfigureExchangeHybridApplication/ConfigureExchangeHybridApplication.ps1

    .Functionality
    Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )
    process {
        try {
            $Ids = Get-ExchangeHybridIds

            $ExchangeOnlineSP = (Invoke-GraphDirectly `
                -Commandlet "Get-MgBetaServicePrincipal" `
                -M365Environment $M365Environment `
                -QueryParams @{ '$filter' = "appId eq '$($Ids.ExchangeOnlineAppId)'" }
            ).Value

            if ($null -eq $ExchangeOnlineSP) {
                Write-Warning "Office 365 Exchange Online service principal not found in tenant."
                return $null
            }

            return [PSCustomObject]@{
                ObjectId                = $ExchangeOnlineSP.Id
                AppId                   = $ExchangeOnlineSP.AppId
                DisplayName             = $ExchangeOnlineSP.DisplayName
                SignInAudience          = $ExchangeOnlineSP.SignInAudience
                HasKeyCredentials       = ($null -ne $ExchangeOnlineSP.KeyCredentials) -and @($ExchangeOnlineSP.KeyCredentials).Count -gt 0
                KeyCredentials          = Format-Credentials -AccessKeys $ExchangeOnlineSP.KeyCredentials -IsFromApplication $false
                PasswordCredentials     = Format-Credentials -AccessKeys $ExchangeOnlineSP.PasswordCredentials -IsFromApplication $false
                FederatedCredentials    = $ExchangeOnlineSP.FederatedIdentityCredentials
                AppOwnerOrganizationId  = $ExchangeOnlineSP.AppOwnerOrganizationId
            }
        }
        catch {
            Write-Warning "An error occurred in Get-LegacyExchangeServicePrincipal: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
    }
}

function Get-DedicatedExchangeHybridApplications {
    <#
    .Description
    Queries for the tenant-specific dedicated Exchange hybrid application created by the ConfigureExchangeHybridApplication.ps1 script.

    The script creates a new app registration/service principal in the specified tenant with the display name "ExchangeServerApp-{exchange organization guid}"
    by default, but users can also specify a custom name to the script above. This function doesn't search for a specific display name, but instead
    seaches for all tenant-owned apps assigned the full_access_as_app role.

    .Functionality
    Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )
    process {
        try {
            $Ids = Get-ExchangeHybridIds

            # Exchange Online is the resource that owns the full_access_as_app role.
            # Lookup the Exchange Online service principal first, then use its object ID to query for all app role assignments to the full_access_as_app role below.
            $ExchangeOnlineSP = (Invoke-GraphDirectly `
                -Commandlet "Get-MgBetaServicePrincipal" `
                -M365Environment $M365Environment `
                -QueryParams @{
                    '$filter' = "appId eq '$($Ids.ExchangeOnlineAppId)'"
                    '$select' = "id,appId,displayName"
                }
            ).Value

            if ($null -eq $ExchangeOnlineSP) {
                Write-Warning "Office 365 Exchange Online service principal not found in tenant."
                return [PSCustomObject]@{
                    DedicatedHybridAppConfigured = $false
                    Apps                         = $null
                }
            } 

            $AllAppRoleAssignments = (Invoke-GraphDirectly `
                -Commandlet "Get-MgBetaServicePrincipalAppRoleAssignedTo" `
                -M365Environment $M365Environment `
                -Id $ExchangeOnlineSP.Id `
            ).Value

            $AppRoleAssignments = @($AllAppRoleAssignments) | Where-Object {
                $_.AppRoleId -eq $Ids.FullAccessAsAppRoleId
            }

            if ($null -eq $AppRoleAssignments -or @($AppRoleAssignments).Count -eq 0) {
                return [PSCustomObject]@{
                    DedicatedHybridAppConfigured = $false
                    Apps                         = $null
                }
            }

            # Iterate over all service principals assigned the full_access_as_app permission
            # since a tenant may have more than one exchange hybrid app.
            $DedicatedHybridApps = @()
            foreach ($Assignment in $AppRoleAssignments) {
                $ServicePrincipal = (Invoke-GraphDirectly `
                    -Commandlet "Get-MgBetaServicePrincipal" `
                    -M365Environment $M365Environment `
                    -QueryParams @{
                        '$filter' = "id eq '$($Assignment.PrincipalId)'"
                    }
                ).Value

                if ($null -eq $ServicePrincipal) {
                    continue
                }

                $AppRegistration = (Invoke-GraphDirectly `
                    -Commandlet "Get-MgBetaApplication" `
                    -M365Environment $M365Environment `
                    -QueryParams @{
                        '$filter' = "appId eq '$($ServicePrincipal.AppId)'"
                    }
                ).Value

                $ObjectIds = [PSCustomObject]@{
                    Application      = if ($null -ne $AppRegistration) { $AppRegistration.Id } else { $null }
                    ServicePrincipal = $ServicePrincipal.Id
                }

                # Fetch federated credentials from the app registration.
                $FederatedCredentialsResults = @()
                if ($null -ne $AppRegistration) {
                    $FederatedCredentials = (Invoke-GraphDirectly `
                        -Commandlet "Get-MgBetaApplicationFederatedIdentityCredential" `
                        -M365Environment $M365Environment `
                        -Id $AppRegistration.Id
                    ).Value

                    foreach ($FederatedCredential in $FederatedCredentials) {
                        if ($null -eq $FederatedCredential) { continue }
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

                $DedicatedHybridApps += [PSCustomObject]@{
                    ObjectId                = $ObjectIds
                    AppId                   = $ServicePrincipal.AppId
                    DisplayName             = $ServicePrincipal.DisplayName
                    AppRegistrationExists   = ($null -ne $AppRegistration)
                    FullAccessAsAppRole     = $Assignment
                    HasKeyCredentials       = ($null -ne $AppRegistration) -and ($null -ne $AppRegistration.KeyCredentials) -and @($AppRegistration.KeyCredentials).Count -gt 0
                    KeyCredentials          = if ($null -ne $AppRegistration) { Format-Credentials -AccessKeys $AppRegistration.KeyCredentials -IsFromApplication $true } else { $null }
                    PasswordCredentials     = if ($null -ne $AppRegistration) { Format-Credentials -AccessKeys $AppRegistration.PasswordCredentials -IsFromApplication $true } else { $null }
                    FederatedCredentials    = if (@($FederatedCredentialsResults).Count -gt 0) { @($FederatedCredentialsResults) } else { $null }
                    AppOwnerOrganizationId  = $ServicePrincipal.AppOwnerOrganizationId
                }
            }

            return [PSCustomObject]@{
                DedicatedHybridAppConfigured = (@($DedicatedHybridApps).Count -gt 0)
                Apps = if (@($DedicatedHybridApps).Count -gt 0) { @($DedicatedHybridApps) } else { $null }
            }
        }
        catch {
            Write-Warning "An error occurred in Get-DedicatedExchangeHybridApplications: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
    }
}

Export-ModuleMember -Function @(
    "Get-ExchangeHybridIds",
    "Get-LegacyExchangeServicePrincipal",
    "Get-DedicatedExchangeHybridApplications"
)