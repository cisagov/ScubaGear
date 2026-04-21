Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod

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
        # accept header https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/complete-basic-operations-using-sharepoint-rest-endpoints#properties-used-in-rest-requests
        $SPOContentType = "application/json;odata=verbose"

        # Data is wrapped in a "d" property when using odata=verbose
        $Response = (Invoke-ScubaRestMethod -BaseUrl $AdminUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET" -ContentType $SPOContentType -Accept $SPOContentType).d

        return $Response
    }
    catch {
        throw "Failed to get SPO Tenant settings: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @(
    'Get-SPOTenantRest'
)
