Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Permissions/PermissionsHelper.psm1") -Function Get-ScubaGearPermissions

function Get-TeamsScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Teams admin API access.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    switch ($M365Environment) {
        default { return Get-ScubaGearPermissions -Product teams -OutAs oauthScope -Environment $M365Environment }
    }
}

function Get-TeamsBaseUrl {
    <#
    .SYNOPSIS
        Returns the Teams admin API base URL for the given M365 environment. This URL is coupled later with the specific Teams API endpoint to form a complete request URL.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    switch ($M365Environment) {
        default { return Get-ScubaGearPermissions -Product teams -OutAs endpoint -Environment $M365Environment }
    }
}

function Get-TeamsUnifiedScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Teams unified admin settings API access.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    switch ($M365Environment) {
        default { return Get-ScubaGearPermissions -Product teamsunified -OutAs oauthScope -Environment $M365Environment }
    }
}

function Get-TeamsUnifiedBaseUrl {
    <#
    .SYNOPSIS
        Returns the Teams unified admin settings API base URL for the given M365 environment. This URL is coupled later with the specific Teams API endpoint to form a complete request URL.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    switch ($M365Environment) {
        default { return Get-ScubaGearPermissions -Product teamsunified -OutAs endpoint -Environment $M365Environment }
    }
}

function Get-TeamsMeetingPolicyRest {
    <#
    .SYNOPSIS
        Gets Meeting policy settings via REST API.
    .DESCRIPTION
        Replaces Get-CsTeamsMeetingPolicy cmdlet.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/Skype.Policy/configurations/TeamsMeetingPolicy"

    $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
    return $Response
}

function Get-TeamsTenantFederationConfigurationRest {
    <#
    .SYNOPSIS
        Gets Tenant Federation configuration settings via REST API.
    .DESCRIPTION
        Replaces Get-CsTenantFederationConfiguration cmdlet.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/Skype.Policy/configurations/TenantFederationSettings"

    $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
    return $Response
}

function Get-TeamsClientConfigurationRest {
    <#
    .SYNOPSIS
        Gets client configuration configuration settings via REST API.
    .DESCRIPTION
        Replaces Get-CsTeamsClientConfiguration cmdlet.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/Skype.Policy/configurations/TeamsClientConfiguration"

    $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
    return $Response
}

function Get-TeamsAppPermissionPolicyRest {
    <#
    .SYNOPSIS
        Gets app permission policy settings via REST API.
    .DESCRIPTION
        Replaces Get-CsTeamsAppPermissionPolicy cmdlet.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/Skype.Policy/configurations/TeamsAppPermissionPolicy"

    $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
    return $Response
}

function Get-TeamsMeetingBroadcastPolicyRest {
    <#
    .SYNOPSIS
        Gets meeting broadcast policy settings via REST API.
    .DESCRIPTION
        Replaces Get-CsTeamsMeetingBroadcastPolicy cmdlet.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/Skype.Policy/configurations/TeamsMeetingBroadcastPolicy"

    $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
    return $Response
}

function Get-TeamsM365UnifiedTenantSettingsRest {
    <#
    .SYNOPSIS
        Gets M365 Teams Unified app Tenant settings via REST API.
    .DESCRIPTION
        Replaces Get-M365UnifiedTenantSettings cmdlet.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/AdminAppCatalog/ps/v2/admin/unifiedApp/settings"

    $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
    return $Response
}

Export-ModuleMember -Function @(
    'Get-TeamsScope',
    'Get-TeamsBaseUrl',
    'Get-TeamsUnifiedScope',
    'Get-TeamsUnifiedBaseUrl',
    'Get-TeamsMeetingPolicyRest',
    'Get-TeamsTenantFederationConfigurationRest',
    'Get-TeamsClientConfigurationRest',
    'Get-TeamsAppPermissionPolicyRest',
    'Get-TeamsMeetingBroadcastPolicyRest',
    'Get-TeamsM365UnifiedTenantSettingsRest'
)
