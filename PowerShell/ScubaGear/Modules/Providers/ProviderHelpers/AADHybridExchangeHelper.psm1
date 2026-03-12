Import-Module -Name $PSScriptRoot/../../Utility/Utility.psm1 -Function Invoke-GraphDirectly
Import-Module -Name $PSScriptRoot/AADRiskyPermissionsHelper.psm1 -Function Format-Credentials

# The first-party Microsoft "Office 365 Exchange Online" application.
# This app's service principal is instantiated in every M365 tenant automatically.
# In legacy hybrid configurations, Exchange auth certificates were added as keyCredentials
# to this SP — these credentials were compromised and Microsoft requires customers to
# remove them and migrate to the new dedicated hybrid app.
# See: https://learn.microsoft.com/en-us/Exchange/hybrid-deployment/deploy-dedicated-hybrid-app
$OFFICE365_EXCHANGE_ONLINE_APP_ID = "00000002-0000-0ff1-ce00-000000000000"

# The app role ID for full_access_as_app on Office 365 Exchange Online.
# This is the permission that the dedicated hybrid app must have — it is hardcoded
# in the ConfigureExchangeHybridApplication.ps1 script and cannot be customized.
# This is the reliable identifier we use to find the dedicated hybrid app regardless
# of what display name the customer chose for it.
$FULL_ACCESS_AS_APP_ROLE_ID = "dc890d15-9560-4a4c-9b7f-a736ec74ec40"

# Microsoft's tenant ID used to identify first-party Microsoft-owned service principals.
# Used to filter OUT Microsoft's own apps when searching for the tenant-specific
# dedicated hybrid app via app role assignments.
$MICROSOFT_TENANT_IDS = @{
    "commercial"    = "f8cdef31-a31e-4b4a-93e4-5f571e91255a"
    "gcc"           = "f8cdef31-a31e-4b4a-93e4-5f571e91255a"
    "gcchigh"       = "cab8a31a-1906-4287-a0d8-4eef66b95f6e"
    "dod"           = "cab8a31a-1906-4287-a0d8-4eef66b95f6e"
    "china"         = "a55a4d5b-9241-49b1-b4ff-befa8db00269"
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
            $ServicePrincipal = (Invoke-GraphDirectly `
                -Commandlet "Get-MgBetaServicePrincipal" `
                -M365Environment $M365Environment `
                -QueryParams @{ '$filter' = "appId eq '$OFFICE365_EXCHANGE_ONLINE_APP_ID'" }
            ).Value

            if ($null -eq $ServicePrincipal) {
                Write-Warning "Office 365 Exchange Online service principal not found in tenant."
                return $null
            }

            return [PSCustomObject]@{
                ObjectId                = $ServicePrincipal.Id
                AppId                   = $ServicePrincipal.AppId
                DisplayName             = $ServicePrincipal.DisplayName
                HasKeyCredentials       = @($ServicePrincipal.KeyCredentials).Count -gt 0
                KeyCredentials          = Format-Credentials -AccessKeys $ServicePrincipal.KeyCredentials -IsFromApplication $false
                PasswordCredentials     = Format-Credentials -AccessKeys $ServicePrincipal.PasswordCredentials -IsFromApplication $false
                FederatedCredentials    = $ServicePrincipal.FederatedIdentityCredentials
            }
        }
        catch {
            Write-Warning "An error occurred in Get-LegacyExchangeServicePrincipal: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
    }
}

Export-ModuleMember -Function @(
    "Get-LegacyExchangeServicePrincipal"
)