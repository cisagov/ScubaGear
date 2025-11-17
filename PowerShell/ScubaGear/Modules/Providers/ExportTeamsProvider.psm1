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
        $CertificateBasedAuth = $false
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
    
    # Get-M365UnifiedTenantSettings requires delegated (user) authentication.
    # Skip this cmdlet when using certificate-based auth to avoid unnecessary errors.
    # Policies MS.TEAMS.5.1v2, 5.2v2, and 5.3v2 will validate using legacy app permission policies only.
    if ($CertificateBasedAuth) {
        Write-Warning @"
Certificate-based authentication detected. 
- Legacy Teams app permission policies will be validated for the MS.TEAMS.5.1v1, 5.2v1, and 5.3v1 policies. This is default.
- Org-wide app settings cannot be retrieved with certificate authentication (Get-M365UnifiedTenantSettings requires user login).
- If your organization uses the newer Teams Admin Center org-wide app settings, 
  please re-run ScubaGear using interactive user authentication (Connect-MicrosoftTeams without certificate) 
  to validate policies MS.TEAMS.5.1v2, 5.2v2, and 5.3v2 against new settings.
"@
        $TenantAppSettings = ConvertTo-Json @()
    }
    else {
        Write-Warning @"
- Interactive/user authentication detected. 
- Org-wide app settings (Non-legacy) retrieved. This follows the MS.TEAMS.5.1v2, 5.2v2, and 5.3v2 policies.
- Legacy Teams app permission (MS.TEAMS.5.1v1, 5.2v1, and 5.3v1) policies will be not validated (Get-CsTeamsAppPermissionPolicy). 
- If your organization uses the Legacy Teams Admin Center/Set-CsTeamsAppPermissionPolicy org-wide app settings, please re-run ScubaGear using noninteractive authentication 
  (Connect-MicrosoftTeams with certificate) to validate policies MS.TEAMS.5.1v1, 5.2v1, and 5.3v1 against legacy settings.
"@
        # Interactive/user authentication - attempt to get org-wide app settings
        $TenantAppSettings = ConvertTo-Json @($Tracker.TryCommand("Get-M365UnifiedTenantSettings"))
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
