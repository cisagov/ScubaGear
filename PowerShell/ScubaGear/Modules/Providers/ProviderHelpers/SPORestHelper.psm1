Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Permissions/PermissionsHelper.psm1") -Function Get-ScubaGearPermissions

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
    $Endpoint = "/_api/SPO.Tenant"

    try {
        $SPOContentType = "application/json;odata=verbose"
        $Response = Invoke-ScubaRestMethod -BaseUrl $AdminUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET" -ContentType $SPOContentType -Accept $SPOContentType

        # Extract the tenant object from response
        if ($Response.d) {
            return $Response.d
        }
        elseif ($Response.value) {
            return $Response.value
        }
        return $Response
    }
    catch {
        throw "Failed to get SPO Tenant settings: $($_.Exception.Message)"
    }
}

function Get-SPOSiteRest {
    <#
    .SYNOPSIS
        Gets SharePoint site properties via REST API.
    .DESCRIPTION
        Replaces Get-PnPTenantSite cmdlet with direct REST API call.
    .PARAMETER AdminUrl
        The SharePoint Admin URL.
    .PARAMETER AccessToken
        The OAuth2 access token.
    .PARAMETER Identity
        The site URL to retrieve.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AdminUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    # Use sites endpoint to get site properties
    Add-Type -AssemblyName System.Web
    $EncodedUrl = [System.Web.HttpUtility]::UrlEncode($Identity)
    $Endpoint = "/_api/SPO.Tenant/sites/GetSiteByUrl?url='$EncodedUrl'"

    try {
        $SPOContentType = "application/json;odata=verbose"
        $Response = Invoke-ScubaRestMethod -BaseUrl $AdminUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "POST" -ContentType $SPOContentType -Accept $SPOContentType

        # Extract site properties from response
        if ($Response.d) {
            return $Response.d
        }
        elseif ($Response.value) {
            return $Response.value
        }
        return $Response
    }
    catch {
        # Site properties are not used by current policies - return empty object on failure
        Write-Verbose "Could not retrieve site properties for '$Identity'. This data is not required for current SharePoint policies."
        return @{}
    }
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
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment,

        [Parameter(Mandatory = $true)]
        [string]$InitialDomainPrefix
    )

    $AdminUrl = Get-ScubaGearPermissions -Product sharepoint -OutAs endpoint -Environment $M365Environment -Domain $InitialDomainPrefix

    return $AdminUrl
}

Export-ModuleMember -Function @(
    'Get-SPOTenantRest',
    'Get-SPOSiteRest',
    'Get-SPOAdminUrl'
)
