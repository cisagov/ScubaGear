Import-Module -Name $PSScriptRoot/ProviderHelpers/PowerBIRestHelper.psm1 -Force

function Export-PowerBIProvider {
    <#
    .Description
    Gets the Power BI settings that are relevant
    to the SCuBA Power BI baselines using the Microsoft.PowerBI.Mgmt
    PowerShell Module
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
    $TenantSettings = $null

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    $Tracker = Get-CommandTracker

    # If there is a license we need to make sure the AccessToken and BaseUrl are not null or empty
    if ($LicenseFound) {
        if ([string]::IsNullOrEmpty($AccessToken) -or [string]::IsNullOrEmpty($BaseUrl)) {
            throw "AccessToken and BaseUrl must be provided when LicenseFound is true."
        }

        $EnvironmentUrl = $BaseUrl

        $headers = @{
            Authorization  = "Bearer $AccessToken"
            "Content-Type" = "application/json"
        }

        # Get tenant settings - covers all PowerBI baseline controls
        $URI = "$EnvironmentUrl/v1/admin/tenantsettings"
        $AdminSettings = $Tracker.TryCommand("Invoke-RestMethod", @{
            "Uri" = $URI
            "Method" = "Get"
            "Headers" = $headers
        })

        # If successfully retrieved the tenant settings
        if ($AdminSettings.count -gt 0) {
            $TenantSettings = $AdminSettings[0].tenantSettings
        }
        # If there was an error retrieving the tenant settings, TryCommand already handles it so we don't need to do anything additional.
    }
    # License not found. We must mark Invoke-RestMethod as successful even if we don't call it.
    # The absence of a license is not an error and the Rego displays a no license message.
    else {
        # $TenantSettingsJson = ConvertTo-Json @()
        $Tracker.AddSuccessfulCommand("Invoke-RestMethod")
    }

    $TenantSettingsJson = ConvertTo-Json @($TenantSettings) -Depth 10
    $LicenseFoundJson = ConvertTo-Json $LicenseFound
    $PowerBISuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $PowerBIUnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # "publish_to_web_setting": $PublishToWebJson,
    # Note the spacing and the last comma in the json is important
    $json = @"
    "powerbi_tenant_settings": $TenantSettingsJson,
    "powerbi_successful_commands": $PowerBISuccessfulCommands,
    "powerbi_unsuccessful_commands": $PowerBIUnSuccessfulCommands,
    "powerbi_license_found": $LicenseFoundJson
"@

    $json
}
