using module '..\..\ScubaConfig\ScubaConfig.psm1'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod, Get-ScubaGearRestEndpoint, Get-ScubaRestRetryDefaults, Get-ScubaGearServiceEndpoint, Get-ScubaGearOAuthScope

function Get-SPOScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for SharePoint Admin API access.
    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).
    .PARAMETER InitialDomainPrefix
        The initial domain prefix (e.g., "contoso" from contoso.onmicrosoft.com).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -in [ScubaConfig]::GetSupportedEnvironments() })]
        [string]$M365Environment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InitialDomainPrefix
    )

    return Get-ScubaGearOAuthScope -Product sharepoint -Environment $M365Environment -Domain $InitialDomainPrefix
}

function Get-SPOAdminUrl {
    <#
    .SYNOPSIS
        Gets the SharePoint Admin URL based on environment and domain prefix.
    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).
    .PARAMETER InitialDomainPrefix
        The initial domain prefix (e.g., "contoso" from contoso.onmicrosoft.com).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -in [ScubaConfig]::GetSupportedEnvironments() })]
        [string]$M365Environment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InitialDomainPrefix
    )

    return Get-ScubaGearServiceEndpoint -Product sharepoint -Environment $M365Environment -Domain $InitialDomainPrefix
}

function Get-SPOTenantRest {
    <#
    .SYNOPSIS
        Gets SharePoint tenant settings via REST API.
    .DESCRIPTION
        Replaces Get-PnPTenant cmdlet with direct REST API call.
    .PARAMETER AdminUrl
        The SharePoint Admin URL.
    .PARAMETER AccessToken
        The OAuth2 access token.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AdminUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    # SharePoint CSOM-style REST endpoint for tenant properties
    $Endpoint = Get-ScubaGearRestEndpoint -FunctionName 'Get-SPOTenantRest'
    $Retry = Get-ScubaRestRetryDefaults

    # accept header https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/complete-basic-operations-using-sharepoint-rest-endpoints#properties-used-in-rest-requests
    $SPOContentType = "application/json;odata=verbose"

    # The SharePoint REST API wraps tenant properties in a "d" envelope when using
    # odata=verbose content type (e.g., { "d": { "SharingCapability": 0, ... } }).
    # Without odata=verbose the response would be a flat JSON object ($Response directly),
    # or a collection under $Response.value. We use odata=verbose here to get the
    # strongly-typed tenant object.
    $Response = (Invoke-ScubaRestMethod -BaseUrl $AdminUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET" -ContentType $SPOContentType -Accept $SPOContentType @Retry).d

    return $Response
}

Export-ModuleMember -Function @(
    'Get-SPOTenantRest',
    'Get-SPOAdminUrl',
    'Get-SPOScope'
)
