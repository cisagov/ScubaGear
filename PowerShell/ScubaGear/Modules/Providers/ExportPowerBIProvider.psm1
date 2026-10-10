Import-Module -Name $PSScriptRoot/ProviderHelpers/PowerBIRestHelper.psm1 -Force
Import-Module -Name $PSScriptRoot/../Utility/ScubaLogging.psm1 -Function Write-ScubaLog

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
        $LicenseFound,

        # This is ingested by the powerbi rego and displayed to the user in the report output
        [Parameter(Mandatory = $false)]
        [string]
        $LicenseReason = ""
    )

    # Initialize the tenant settings to create an empty JSON if there was an error or no license.
    $TenantSettingsJson = ConvertTo-Json @()

    # Set when the Power BI API returns 401/403; ingested by the powerbi rego and shown in the report
    $AccessDeniedReason = ""

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../Utility/ScubaLogging.psm1") -Function Write-ScubaLog
    $Tracker = Get-CommandTracker

    Write-ScubaLog -Message "Starting Power BI provider export." -Level Info -Source "Export-PowerBIProvider"

    if ($LicenseFound) {
        if ([string]::IsNullOrEmpty($AccessToken) -or [string]::IsNullOrEmpty($BaseUrl)) {
            throw "AccessToken and BaseUrl must be provided when LicenseFound is true."
        }

        # Call the Power BI Admin REST API to get the tenant settings. The helper is called directly
        # (not via Tracker.TryCommand) so the HTTP status code is available to classify 401/403 failures.
        $ApiCallSucceeded = $false
        try {
            $AdminSettings = Get-PowerBITenantSettingsRest -BaseUrl $BaseUrl -AccessToken $AccessToken
            $ApiCallSucceeded = $true
        }
        catch {
            $ErrorText = $_.Exception.Message

            # Record the failure on the tracker so the command's state is accurate for any
            # caller that inspects it, matching what CommandTracker.TryCommand does on failure.
            $Tracker.AddUnSuccessfulCommand("Get-PowerBITenantSettingsRest")

            # Possible conditions that can occur based on hands-on testing:
            ##### Service Principal auth
            #  1 - Nobody has logged into the Power BI portal to configure the security group for the service principal: 403 Forbidden
            #  2 - Someone has signed into the Power BI portal, but the service principal security group is not configured: 401 Unauthorized

            ##### Interactive auth (both conditions below can be true at the same time)
            #  1 - Nobody has logged into the Power BI portal before in the target tenant: 403 Forbidden
            #  2 - Someone has signed into the Power BI portal, but the user running ScubaGear does not have Fabric Administrator role: 403 Forbidden

            # Use the HTTP status code when there's a response, since the message text varies with the OS
            # language and PowerShell version. Otherwise fall back to the (401)/(403) in the message.
            $StatusCode = $null
            if ($null -ne $_.Exception.Response) {
                $StatusCode = [int]$_.Exception.Response.StatusCode
            }
            elseif ($ErrorText -match '\((401|403)\)') {
                $StatusCode = [int]$Matches[1]
            }

            # Display a custom fix message to the user when permissions are missing or the user hasn't logged into the Power BI portal at least once.
            if ($StatusCode -in @(401, 403)) {
                # Build the guidance once so the console output and the debug log cannot drift apart.
                $StatusText = if ($StatusCode -eq 403) { "403 Forbidden" } else { "401 Unauthorized" }

                # Custom message for service principal auth because for this flow the security groups setting is needed.
                if ($CertificateBasedAuth) {
                    $AuthType = "ServicePrincipal"
                    $GuidanceLines = @(
                        "- You must sign into the Power BI portal to configure a security group for the service principal. See link below for details:"
                        "  https://github.com/cisagov/ScubaGear/blob/main/docs/prerequisites/noninteractive.md#power-bi-tenant-setting"
                    )
                    $AccessDeniedReason = "The Power BI Admin API denied access ($StatusText). Sign into the Power BI portal and configure a security group for the service principal, and make sure the app registration is not granted the Power BI Tenant.Read.All permission. See <a href=`"https://github.com/cisagov/ScubaGear/blob/main/docs/prerequisites/noninteractive.md#power-bi-tenant-setting`" target=`"_blank`">Power BI tenant setting</a> for details."
                }
                # Custom message for interactive auth because for this flow the role is needed plus login to the Power BI portal.
                else {
                    $AuthType = "Interactive"
                    $GuidanceLines = @(
                        "- You must have a minimum of the Fabric Administrator role for ScubaGear to read the Power BI configurations"
                        "- You must also sign into the Power BI portal at least once"
                    )
                    $AccessDeniedReason = "The Power BI Admin API denied access ($StatusText). The user running ScubaGear needs a minimum of the Fabric Administrator role and must sign into the Power BI portal at least once."
                }

                Write-Information "`n********** ATTENTION ScubaGear user ********************" -InformationAction Continue
                foreach ($GuidanceLine in $GuidanceLines) {
                    Write-Information $GuidanceLine -InformationAction Continue
                }
                Write-Information "********************************************************`n" -InformationAction Continue

                # Also capture the guidance in the debug log so support bundles contain the remediation
                # steps, not just the raw HTTP error. Level is Info rather than Warning to match the
                # convention in CommandTracker: Warning/Error set the session error flag, and the
                # report already shows the remediation on every Power BI policy.
                Write-ScubaLog -Message "Power BI permissions guidance" -Level "Info" -Source "PowerBIProvider" -Data @{
                    AuthType = $AuthType
                    Guidance = ($GuidanceLines -join " ")
                    Error    = $ErrorText
                }
            }
            else {
                Write-Warning "Error running Get-PowerBITenantSettingsRest against the Power BI Admin REST API: $ErrorText"
                Write-ScubaLog -Message "Error running command" -Level "Info" -Source "PowerBIProvider" -Data @{
                    Command = "Get-PowerBITenantSettingsRest"
                    Error   = $ErrorText
                }
            }
        }

        # Get-PowerBITenantSettingsRest stays unsuccessful on any failure so the report shows these policies as errors
        if ($ApiCallSucceeded) {
            if ($AdminSettings.Count -eq 0) {
                throw "No tenant settings were returned from the Power BI Admin REST API. Report this to the ScubaGear team for troubleshooting."
            }

            $TenantSettings = $AdminSettings[0].tenantSettings
            $TenantSettingsJson = ConvertTo-Json @($TenantSettings) -Depth 10
            $Tracker.AddSuccessfulCommand("Get-PowerBITenantSettingsRest")
        }
    }
    else {
        $Tracker.AddSuccessfulCommand("Get-PowerBITenantSettingsRest")
    }

    $LicenseFoundJson = ConvertTo-Json $LicenseFound
    $LicenseReasonJson = ConvertTo-Json $LicenseReason
    $AccessDeniedReasonJson = ConvertTo-Json $AccessDeniedReason
    $PowerBISuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $PowerBIUnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    Write-ScubaLog -Message "Completed Power BI provider export." -Level Debug -Source "Export-PowerBIProvider" -Data @{
        SuccessfulCommandCount   = @($Tracker.GetSuccessfulCommands()).Count
        UnsuccessfulCommandCount = @($Tracker.GetUnSuccessfulCommands()).Count
        UnsuccessfulCommands     = @($Tracker.GetUnSuccessfulCommands())
    }

    $json = @"
    "powerbi_tenant_settings": $TenantSettingsJson,
    "powerbi_successful_commands": $PowerBISuccessfulCommands,
    "powerbi_unsuccessful_commands": $PowerBIUnSuccessfulCommands,
    "powerbi_license_found": $LicenseFoundJson,
    "powerbi_license_reason": $LicenseReasonJson,
    "powerbi_access_denied_reason": $AccessDeniedReasonJson,
"@

    $json
}
