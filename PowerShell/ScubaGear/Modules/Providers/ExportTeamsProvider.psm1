function Export-TeamsProvider {
    <#
    .Description
    Gets the Teams settings that are relevant
    to the SCuBA Teams baselines using the Teams PowerShell module
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]
        $CertificateBasedAuth = $false,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $true)]
        [string]
        $AccessToken,

        [Parameter(Mandatory = $true)]
        [string]
        $BaseUrl,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $UnifiedAccessToken,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $UnifiedBaseUrl
    )

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    $Tracker = Get-CommandTracker

    $MeetingPolicies = $Tracker.TryCommand("Get-TeamsMeetingPolicyRest", @{BaseUrl = $BaseUrl; AccessToken = $AccessToken})
    $MeetingPoliciesJson = ConvertTo-Json -Depth 5 @($MeetingPolicies)

    $FedConfig = $Tracker.TryCommand("Get-TeamsTenantFederationConfigurationRest", @{BaseUrl = $BaseUrl; AccessToken = $AccessToken})
    $FedConfigJson = ConvertTo-Json -Depth 5 @($FedConfig)

    $ClientConfig = $Tracker.TryCommand("Get-TeamsClientConfigurationRest", @{BaseUrl = $BaseUrl; AccessToken = $AccessToken})
    $ClientConfigJson = ConvertTo-Json -Depth 5 @($ClientConfig)

    $AppPolicies = $Tracker.TryCommand("Get-TeamsAppPermissionPolicyRest", @{BaseUrl = $BaseUrl; AccessToken = $AccessToken})
    $AppPoliciesJson = ConvertTo-Json -Depth 5 @($AppPolicies)

    $BroadcastPolicies = $Tracker.TryCommand("Get-TeamsMeetingBroadcastPolicyRest", @{BaseUrl = $BaseUrl; AccessToken = $AccessToken})
    $BroadcastPoliciesJson = ConvertTo-Json -Depth 5 @($BroadcastPolicies)


    # The Teams unified app settings REST API is only available in certain environments and only works with interactive authentication.
    if ($M365Environment -in @('gcchigh', 'dod')) {
        # Scenario 1: GCC HIGH / DOD environments: Use legacy settings only (Teams unified app settings REST API is not available in these environments)
        Write-Warning @"
GCC HIGH or DOD environment detected.
- MS.TEAMS.5.1v2, 5.2v2, and 5.3v2 will be validated against legacy Teams app permission policies.
- Unified app settings cannot be retrieved in these environments (Teams unified app settings REST API is unavailable).
"@
        $TenantAppSettingsJson = ConvertTo-Json @([PSCustomObject]@{ })
        # Manually add the respective API to successful commands since the unified app settings REST API is not available in these environments
        $Tracker.AddSuccessfulCommand("Get-TeamsM365UnifiedTenantSettingsRest")
    }
    elseif ($CertificateBasedAuth) {
        # Scenario 2: Certificate-based auth: Use legacy settings only (Teams unified app settings REST API only works in Delegated (on-behalf-of) flow)
        Write-Warning @"
Certificate-based authentication detected.
- MS.TEAMS.5.1v2, 5.2v2, and 5.3v2 will be validated against legacy Teams app permission policies.
- Unified app settings cannot be retrieved with certificate authentication (Teams unified app settings REST API requires user login).
- If your organization uses the newer Teams Admin Center org-wide app settings,
  please re-run ScubaGear using interactive user authentication to validate against org-wide settings instead of legacy policies.
"@
        # Use a marker to indicate certificate auth was used
        $TenantAppSettingsJson = ConvertTo-Json @([PSCustomObject]@{
            CertificateBasedAuth = $true
        })
        # Manually add the respective API to successful commands since the unified app settings REST API is not available for non-interactive auth
        $Tracker.AddSuccessfulCommand("Get-TeamsM365UnifiedTenantSettingsRest")
    }
    else {
        # Scenario 3: Interactive auth: Commercial and GCC environments: Call Teams unified app settings REST API
        $UnifiedSettings = $Tracker.TryCommand("Get-TeamsM365UnifiedTenantSettingsRest", @{BaseUrl = $UnifiedBaseUrl; AccessToken = $UnifiedAccessToken})
        $TenantAppSettingsJson = ConvertTo-Json -Depth 5 @($UnifiedSettings)
    }

    $TeamsSuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $TeamsUnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "meeting_policies": $MeetingPoliciesJson,
    "federation_configuration": $FedConfigJson,
    "client_configuration": $ClientConfigJson,
    "app_policies": $AppPoliciesJson,
    "broadcast_policies": $BroadcastPoliciesJson,
    "tenant_app_settings": $TenantAppSettingsJson,
    "teams_successful_commands": $TeamsSuccessfulCommands,
    "teams_unsuccessful_commands": $TeamsUnSuccessfulCommands,
"@

    $json
}

