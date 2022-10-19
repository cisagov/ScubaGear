function Export-TeamsProvider {
    <#
    .Description
    Gets the Teams settings that are relevant
    to the SCuBA Teams baselines using the Teams PowerShell Module
    .Functionality
    Internal
    #>
    [CmdletBinding()]

    $TenantInfo = ConvertTo-Json @(Get-CsTenant)
    $MeetingPolicies = ConvertTo-Json @(Get-CsTeamsMeetingPolicy)
    $FedConfig = ConvertTo-Json @(Get-CsTenantFederationConfiguration)
    $ClientConfig = ConvertTo-Json @(Get-CsTeamsClientConfiguration)
    $AppPolicies = ConvertTo-Json @(Get-CsTeamsAppPermissionPolicy)
    $BroadcastPolicies = ConvertTo-Json @(Get-CsTeamsMeetingBroadcastPolicy)

    # Note the spacing and the last comma in the json is important
    $json = @"
    "teams_tenant_info": $TenantInfo,
    "meeting_policies": $MeetingPolicies,
    "federation_configuration": $FedConfig,
    "client_configuration": $ClientConfig,
    "app_policies": $AppPolicies,
    "broadcast_policies": $BroadcastPolicies,
"@

    # We need to remove the backslash characters from the
    # json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
    $json
}

function Get-TeamsTenantDetail {
    <#
    .Description
    Gets the M365 tenant details using the Teams PowerShell Module
    .Functionality
    Internal
    #>
    $TenantInfo = Get-CsTenant

    # Need to explicitly clear or convert these values to strings, otherwise
    # these fields contain values Rego can't parse.
    $TenantInfo.AssignedPlan = @()
    $TenantInfo.LastSyncTimeStamp = $TenantInfo.LastSyncTimeStamp.ToString()
    $TenantInfo.WhenChanged = $TenantInfo.WhenChanged.ToString()
    $TenantInfo.WhenCreated = $TenantInfo.WhenCreated.ToString()
    $TenantInfo = ConvertTo-Json @($TenantInfo) -Depth 4
    $TenantInfo
}
