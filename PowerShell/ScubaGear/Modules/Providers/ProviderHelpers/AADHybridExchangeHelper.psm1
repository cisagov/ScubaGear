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

        # $ExchangeOnlineResource.Name represents the exchange online appId (00000002-0000-0ff1-ce00-000000000000)
        # $ExchangeOnlineResource.Value represents the display name ("Office 365 Exchange Online")
        $ExchangeOnlineResource = $RiskyPermissionsJson.resources.PSObject.Properties | Where-Object {
            $_.Value -eq "Office 365 Exchange Online"
        } | Select-Object -First 1

        if ($null -eq $ExchangeOnlineResource) {
            throw "Could not find 'Office 365 Exchange Online' in RiskyPermissions.json."
        }

        # $FullAccessAsAppRoleId.Name represents the role ID (dc890d15-9560-4a4c-9b7f-a736ec74ec40)
        # $FullAccessAsAppRoleId.Value represents the role name ("full_access_as_app")
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
    searches for all tenant-owned apps assigned the full_access_as_app role.

    .Functionality
    Internal
    #>
    param (
        [Object[]]
        $AggregateRiskyAppsRaw
    )
    process {
        try {
            $Ids = Get-ExchangeHybridIds

            $DedicatedHybridApps = @($AggregateRiskyAppsRaw) | Where-Object {
                $_.Permissions | Where-Object {
                    $_.RoleId -eq $Ids.FullAccessAsAppRoleId -and $_.IsRisky -eq $true
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