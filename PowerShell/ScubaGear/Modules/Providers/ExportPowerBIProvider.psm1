Import-Module -Name $PSScriptRoot/ProviderHelpers/PowerBIRestHelper.psm1 -Force
Import-Module -Name $PSScriptRoot/../Utility/Utility.psm1 -Function Invoke-ScubaRestMethod

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
        [Parameter(Mandatory = $false)]
        [switch]
        $CertificateBasedAuth = $false,

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

        # $Headers = @{
        #     Authorization  = "Bearer $AccessToken"
        #     "Content-Type" = "application/json"
        # }

        # $Uri = "$BaseUrl/v1/admin/tenantsettings"
        $Endpoint = "/v1/admin/tenantsettings"

        # Call the Power BI Admin REST API to get the tenant settings.
        try {
            # $AdminSettings = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Headers -ErrorAction Stop

            $AdminSettings = Invoke-ScubaRestMethod `
                -BaseUrl $BaseUrl `
                -AccessToken $AccessToken `
                -Endpoint $Endpoint `
                -Method Get `
        }
        catch {
            $ErrorText = $_.Exception.Message

            # Possible conditions that can occur based on hands-on testing:
            ##### Service Principal auth
            #  1 - Nobody has logged into the Power BI portal to configure the security group for the service principal: 403 Forbidden
            #  2 - Someone has signed into the Power BI portal, but the service principal security group is not configured: 401 Unauthorized

            ##### Interactive auth (both conditions below can be true at the same time)
            #  1 - Nobody has logged into the Power BI portal before in the target tenant: 403 Forbidden
            #  2 - Someone has signed into the Power BI portal, but the user running ScubaGear does not have Fabric Administrator role: 403 Forbidden

            # Display a custom fix message to the user when permissions are missing or the user hasn't logged into the Power BI portal at least once.
            if ( ($ErrorText -match "403" -and $ErrorText -match "Forbidden") -or ($ErrorText -match "401" -and $ErrorText -match "Unauthorized") ) {
                # Custom message for service principal auth because for this flow the security groups setting is needed.
                if ($CertificateBasedAuth) {
                    Write-Information "`n********** ATTENTION ScubaGear user ********************" -InformationAction Continue
                    Write-Information "- You must sign into the Power BI portal to configure a security group for the service principal. See link below for details:" -InformationAction Continue
                    Write-Information "  https://github.com/cisagov/ScubaGear/blob/main/docs/prerequisites/noninteractive.md#power-bi-tenant-setting" -InformationAction Continue
                    Write-Information "********************************************************`n" -InformationAction Continue
                }
                # Custom message for interactive auth because for this flow the role is needed plus login to the Power BI portal.
                else {
                    Write-Information "`n********** ATTENTION ScubaGear user ********************" -InformationAction Continue
                    Write-Information "- You must have a minimum of the Fabric Administrator role for ScubaGear to read the Power BI configurations" -InformationAction Continue
                    Write-Information "- You must also sign into the Power BI portal at least once" -InformationAction Continue
                    Write-Information "********************************************************`n" -InformationAction Continue
                }
            }
            throw
        }

        if ($AdminSettings.Count -eq 0) {
            throw "No tenant settings were returned from the Power BI Admin REST API. Report this to the ScubaGear team for troubleshooting."
        }

        $TenantSettings = $AdminSettings[0].tenantSettings
        $TenantSettingsJson = ConvertTo-Json @($TenantSettings) -Depth 10
    }

    $Tracker.AddSuccessfulCommand("Invoke-RestMethod")

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
