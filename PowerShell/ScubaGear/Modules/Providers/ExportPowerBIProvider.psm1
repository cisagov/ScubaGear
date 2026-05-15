Import-Module -Name $PSScriptRoot/../Utility/Utility.psm1 -Function ConvertFrom-GraphHashtable, Invoke-GraphDirectly
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
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [string]
        $ClientID,

        [Parameter(Mandatory = $false)]
        [string]
        $CertificateThumbprint
    )

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    $Tracker = Get-CommandTracker

    try {
        # Acquire Power BI access token - service principal or interactive
        $TenantDetails = (Invoke-GraphDirectly -Commandlet "Get-MgBetaOrganization" -M365Environment $M365Environment).Value
        $InitialDomain = ($TenantDetails.VerifiedDomains | Where-Object { $_.IsInitial }).Name

        $EnvironmentUrl = Get-PowerBIBaseUrl -M365Environment $M365Environment
        if ((-not [string]::IsNullOrEmpty($ClientID)) -and (-not [string]::IsNullOrEmpty($CertificateThumbprint))) {
            $PowerBIToken = Get-PowerBIAccessToken `
                -CertificateThumbprint $CertificateThumbprint `
                -AppID $ClientID `
                -Tenant $InitialDomain `
                -M365Environment $M365Environment
        }
        else {
            $PowerBIToken = Get-PowerBIAccessTokenInteractive `
                -Tenant $InitialDomain `
                -M365Environment $M365Environment
        }

        $headers = @{
            Authorization  = "Bearer $PowerBIToken"
            "Content-Type" = "application/json"
        }

        # Get tenant settings - covers all PowerBI baseline controls
        $URI = "$EnvironmentUrl/v1/admin/tenantsettings"
        $AdminSettings = $Tracker.TryCommand("Invoke-RestMethod", @{
            "Uri" = $URI
            "Method" = "Get"
            "Headers" = $headers
        })

        # Extract specific settings for each baseline control

        # MS.POWERBI.1.1v1 - Publish to Web
        $PublishToWebSetting = $AdminSettings.tenantSettings | Where-Object { $_.settingName -eq 'PublishToWeb' }

        # MS.POWERBI.2.1v1 - Guest Access
        $GuestAccessSetting = $AdminSettings.tenantSettings | Where-Object { $_.settingName -eq 'AllowGuestUserToAccessSharedContent' }

        # MS.POWERBI.3.1v1 - External Sharing
        $ExternalSharingSetting = $AdminSettings.tenantSettings | Where-Object { $_.settingName -eq 'ExternalSharingV2' }

        # MS.POWERBI.4.1v1 - Service Principals APIs
        $ServicePrincipalAPISetting = $AdminSettings.tenantSettings | Where-Object { $_.settingName -eq 'ServicePrincipalAccessPermissionAPIs' }

        # MS.POWERBI.4.2v1 - Service Principals Profiles
        $ServicePrincipalProfileSetting = $AdminSettings.tenantSettings | Where-Object { $_.settingName -eq 'AllowServicePrincipalsCreateAndUseProfiles' }

        # MS.POWERBI.5.1v1 - ResourceKey Authentication
        $ResourceKeySetting = $AdminSettings.tenantSettings | Where-Object { $_.settingName -eq 'BlockResourceKeyAuthentication' }

        # MS.POWERBI.6.1v1 - R and Python Visuals
        $RScriptSetting = $AdminSettings.tenantSettings | Where-Object { $_.settingName -eq 'RScriptVisual' }

        # MS.POWERBI.7.1v1 - Sensitivity Labels
        $SensitivityLabelSetting = $AdminSettings.tenantSettings | Where-Object { $_.settingName -eq 'EimInformationProtectionEdit' }

        # Convert individual settings to JSON
        $PublishToWebJson = ConvertTo-Json @($PublishToWebSetting) -Depth 5
        $GuestAccessJson = ConvertTo-Json @($GuestAccessSetting) -Depth 5
        $ExternalSharingJson = ConvertTo-Json @($ExternalSharingSetting) -Depth 5
        $ServicePrincipalAPIJson = ConvertTo-Json @($ServicePrincipalAPISetting) -Depth 5
        $ServicePrincipalProfileJson = ConvertTo-Json @($ServicePrincipalProfileSetting) -Depth 5
        $ResourceKeyJson = ConvertTo-Json @($ResourceKeySetting) -Depth 5
        $RScriptJson = ConvertTo-Json @($RScriptSetting) -Depth 5
        $SensitivityLabelJson = ConvertTo-Json @($SensitivityLabelSetting) -Depth 5

        # Convert full tenant settings to JSON for reference
        $TenantSettingsJson = ConvertTo-Json @($AdminSettings.tenantSettings) -Depth 10

    }
    catch {
        Write-Warning "Error retrieving PowerBI Admin settings: $($_.Exception.Message)"
        $Tracker.AddUnSuccessfulCommand("Invoke-RestMethod")

        # Set empty JSON objects for failed connections
        $PublishToWebJson = ConvertTo-Json @()
        $GuestAccessJson = ConvertTo-Json @()
        $ExternalSharingJson = ConvertTo-Json @()
        $ServicePrincipalAPIJson = ConvertTo-Json @()
        $ServicePrincipalProfileJson = ConvertTo-Json @()
        $ResourceKeyJson = ConvertTo-Json @()
        $RScriptJson = ConvertTo-Json @()
        $SensitivityLabelJson = ConvertTo-Json @()
        $TenantSettingsJson = ConvertTo-Json @()
    }

    $PowerBISuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $PowerBIUnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "publish_to_web_setting": $PublishToWebJson,
    "guest_access_setting": $GuestAccessJson,
    "external_sharing_setting": $ExternalSharingJson,
    "service_principal_api_setting": $ServicePrincipalAPIJson,
    "service_principal_profile_setting": $ServicePrincipalProfileJson,
    "resource_key_setting": $ResourceKeyJson,
    "rscript_setting": $RScriptJson,
    "sensitivity_label_setting": $SensitivityLabelJson,
    "tenant_settings": $TenantSettingsJson,
    "powerbi_successful_commands": $PowerBISuccessfulCommands,
    "powerbi_unsuccessful_commands": $PowerBIUnSuccessfulCommands,
"@

    $json
}
