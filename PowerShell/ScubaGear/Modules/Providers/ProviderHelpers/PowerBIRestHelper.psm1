Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Permissions/PermissionsHelper.psm1") -Function Get-ScubaGearRestEndpoint

function Get-PowerBIBaseUrl {
    <#
    .SYNOPSIS
        Returns the Power BI Admin API base URL for the given M365 environment.
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
        "commercial" { return "https://api.powerbi.com" }
        "gcc"        { return "https://api.powerbigov.us" }
        "gcchigh"    { return "https://api.high.powerbigov.us" }
        "dod"        { return "https://app.mil.powerbigov.us" }
    }
}

function Get-PowerBIScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Power BI API access.
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
        "commercial" { return "https://analysis.windows.net/powerbi/api/.default" }
        "gcc"        { return "https://analysis.usgovcloudapi.net/powerbi/api/.default" }
        "gcchigh"    { return "https://high.analysis.usgovcloudapi.net/powerbi/api/.default" }
        "dod"        { return "https://mil.analysis.usgovcloudapi.net/powerbi/api/.default" }
    }
}

function Get-PowerBITenantSettingsRest {
    <#
    .SYNOPSIS
        Gets Power BI tenant settings via the Power BI Admin REST API.
    .DESCRIPTION
        Replaces the Power BI Admin API's tenant settings call previously made inline in
        Export-PowerBIProvider with a dedicated wrapper, matching the pattern used by the
        other Rest helpers (Get-SPOTenantRest, Get-PowerPlatform*Rest, Get-Teams*Rest).
    .PARAMETER BaseUrl
        The Power BI Admin API base URL.
    .PARAMETER AccessToken
        The OAuth2 access token.
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

    $Endpoint = Get-ScubaGearRestEndpoint -FunctionName 'Get-PowerBITenantSettingsRest'
    Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
}

Export-ModuleMember -Function @(
    'Get-PowerBIBaseUrl',
    'Get-PowerBIScope',
    'Get-PowerBITenantSettingsRest'
)