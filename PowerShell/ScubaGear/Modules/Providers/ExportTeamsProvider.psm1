function Export-TeamsProvider {
    <#
    .Description
    Gets the Teams settings that are relevant
    to the SCuBA Teams baselines using the Teams PowerShell Module
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]
        $CertificateBasedAuth = $false,

        [Parameter(Mandatory = $false)]
        [switch]
        $UseNewSettings = $false
    )

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    $Tracker = Get-CommandTracker

    $TenantInfo = ConvertTo-Json @($Tracker.TryCommand("Get-CsTenant"))
    $MeetingPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-CsTeamsMeetingPolicy"))
    $FedConfig = ConvertTo-Json @($Tracker.TryCommand("Get-CsTenantFederationConfiguration"))
    $ClientConfig = ConvertTo-Json @($Tracker.TryCommand("Get-CsTeamsClientConfiguration"))
    $AppPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-CsTeamsAppPermissionPolicy"))
    $BroadcastPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-CsTeamsMeetingBroadcastPolicy"))
    
    # Determine which Teams app settings to retrieve based on authentication method and user preference
    # Three scenarios:
    # 1. Certificate-based auth: Always use legacy settings (Get-M365UnifiedTenantSettings unavailable)
    # 2. Interactive auth with -UseNewTeamsAppSettings: Use new org-wide settings by user choice
    # 3. Interactive auth without switch: Use legacy settings (default)
    
    if ($CertificateBasedAuth) {
        # Scenario 1: Certificate-based authentication - legacy only
        Write-Warning @"
Certificate-based authentication detected. 
- Legacy Teams app permission policies will be validated for MS.TEAMS.5.1v1, 5.2v1, and 5.3v1 policies.
- Org-wide app settings cannot be retrieved with certificate authentication (Get-M365UnifiedTenantSettings requires user login).
- If your organization uses the newer Teams Admin Center org-wide app settings, 
  please re-run ScubaGear using interactive user authentication with the -UseNewTeamsAppSettings parameter
  to validate policies MS.TEAMS.5.1v2, 5.2v2, and 5.3v2 against new settings.
"@
        $TenantAppSettings = ConvertTo-Json @()
    }
    elseif ($UseNewSettings) {
        # Scenario 2: Interactive auth with explicit new settings preference
        Write-Warning @"
Interactive authentication with -UseNewTeamsAppSettings parameter detected.
- Org-wide app settings (newer v2 policies) will be validated for MS.TEAMS.5.1v2, 5.2v2, and 5.3v2.
- Legacy Teams app permission policies (MS.TEAMS.5.1v1, 5.2v1, 5.3v1) will NOT be validated.
- To validate legacy Teams app permission policies instead, 
  re-run ScubaGear without the -UseNewTeamsAppSettings parameter.
"@
        # Interactive/user authentication - attempt to get org-wide app settings
        $TenantAppSettings = ConvertTo-Json @($Tracker.TryCommand("Get-M365UnifiedTenantSettings"))
    }
    else {
        # Scenario 3: Interactive auth, default behavior - use legacy settings
        Write-Warning @"
Interactive/user authentication detected (default mode).
- Legacy Teams app permission policies will be validated for MS.TEAMS.5.1v1, 5.2v1, and 5.3v1 policies.
- Org-wide app settings (newer v2 policies) will NOT be retrieved.
- If your organization uses the newer Teams Admin Center org-wide app settings,
  re-run ScubaGear with the -UseNewTeamsAppSettings parameter to validate MS.TEAMS.5.1v2, 5.2v2, and 5.3v2 instead.
"@
        $TenantAppSettings = ConvertTo-Json @()
    }

    $TeamsSuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $TeamsUnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "teams_tenant_info": $TenantInfo,
    "meeting_policies": $MeetingPolicies,
    "federation_configuration": $FedConfig,
    "client_configuration": $ClientConfig,
    "app_policies": $AppPolicies,
    "broadcast_policies": $BroadcastPolicies,
    "tenant_app_settings": $TenantAppSettings,
    "teams_successful_commands": $TeamsSuccessfulCommands,
    "teams_unsuccessful_commands": $TeamsUnSuccessfulCommands,
"@

    $json
}

function Get-TeamsTenantDetail {
    <#
    .Description
    Gets the M365 tenant details using the Teams PowerShell Module
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )
    # Need to explicitly clear or convert these values to strings, otherwise
    # these fields contain values Rego can't parse.
    try {
        $TenantInfo = Get-CsTenant -ErrorAction "Stop"

        $VerifiedDomains = $TenantInfo.VerifiedDomains
        $TenantDomain = "Teams: Domain Unretrievable"
        $TLD = ".com"
        if (($M365Environment -eq "gcchigh") -or ($M365Environment -eq "dod")) {
            $TLD = ".us"
        }
        foreach ($Domain in $VerifiedDomains.GetEnumerator()) {
            $Name = $Domain.Name
            $Status = $Domain.Status
            $DomainChecker = $Name.EndsWith(".onmicrosoft$($TLD)") -and !$Name.EndsWith(".mail.onmicrosoft$($TLD)") -and $Status -eq "Enabled"
            if ($DomainChecker) {
                $TenantDomain = $Name
            }
        }

        $TeamsTenantInfo = @{
            "DisplayName" = $TenantInfo.DisplayName;
            "DomainName" = $TenantDomain;
            "TenantId" = $TenantInfo.TenantId;
            "TeamsAdditionalData" = $TenantInfo;
        }
        $TeamsTenantInfo = ConvertTo-Json @($TeamsTenantInfo) -Depth 4
        $TeamsTenantInfo
    }
    catch {
        Write-Warning "Error retrieving Tenant details in Get-TeamsTenantDetail: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
        $TeamsTenantInfo = @{
            "DisplayName" = "Error retrieving Display name";
            "DomainName" = "Error retrieving Domain name";
            "TenantId" = "Error retrieving Tenant ID";
            "TeamsAdditionalData" = "Error retrieving additional data";
        }
        $TeamsTenantInfo = ConvertTo-Json @($TeamsTenantInfo) -Depth 4
        $TeamsTenantInfo
    }
}
