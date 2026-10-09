Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod, Get-ScubaGearRestEndpoint, Get-ScubaGearServiceEndpoint, Get-ScubaGearOAuthScope, Get-ScubaRestRetryDefaults

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

    return Get-ScubaGearServiceEndpoint -Product powerbi -Environment $M365Environment
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
    return Get-ScubaGearOAuthScope -Product powerbi -Environment $M365Environment
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
    $Retry = Get-ScubaRestRetryDefaults
    Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET" @Retry
}

Export-ModuleMember -Function @(
    'Get-PowerBIBaseUrl',
    'Get-PowerBIScope',
    'Get-PowerBITenantSettingsRest'
)