Import-Module -Name $PSScriptRoot/ProviderHelpers/PowerBIRestHelper.psm1 -Force

function Export-PowerBIProvider {
    <#
    .Description
    Gets the Power BI settings that are relevant
    to the SCuBA Power BI baselines using the Power BI Admin REST API.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [string]
        $AccessToken,

        [string]
        $BaseUrl,

        [Parameter(Mandatory = $true)]
        [bool]
        $LicenseFound
    )

    # Initialize the tenant settings to create an empty JSON if there was an error or no license.
    $TenantSettingsJson = ConvertTo-Json @()

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    $Tracker = Get-CommandTracker

    if ($LicenseFound) {
        if ([string]::IsNullOrEmpty($AccessToken) -or [string]::IsNullOrEmpty($BaseUrl)) {
            throw "AccessToken and BaseUrl must be provided when LicenseFound is true."
        }

        $Headers = @{
            Authorization  = "Bearer $AccessToken"
            "Content-Type" = "application/json"
        }

        $Uri = "$BaseUrl/v1/admin/tenantsettings"
        $AdminSettings = $Tracker.TryCommand("Invoke-RestMethod", @{
            "Uri" = $Uri
            "Method" = "Get"
            "Headers" = $Headers
        })

        if ($AdminSettings.Count -gt 0) {
            $TenantSettings = $AdminSettings[0].tenantSettings
            $TenantSettingsJson = ConvertTo-Json @($TenantSettings) -Depth 10
        }
    }
    else {
        $Tracker.AddSuccessfulCommand("Invoke-RestMethod")
    }

    $LicenseFoundJson = ConvertTo-Json $LicenseFound
    $PowerBISuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $PowerBIUnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    $json = @"
    "powerbi_tenant_settings": $TenantSettingsJson,
    "powerbi_successful_commands": $PowerBISuccessfulCommands,
    "powerbi_unsuccessful_commands": $PowerBIUnSuccessfulCommands,
    "powerbi_license_found": $LicenseFoundJson,
"@

    $json
}
