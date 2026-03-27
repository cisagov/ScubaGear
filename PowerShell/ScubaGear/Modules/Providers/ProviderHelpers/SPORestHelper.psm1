. (Join-Path -Path $PSScriptRoot -ChildPath "MsalHelper.ps1")

function Get-SPOAccessToken {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token for SharePoint Admin API using certificate authentication.
    .DESCRIPTION
        Uses MSAL (Microsoft.Identity.Client) ConfidentialClientApplication to acquire a token
        scoped to the SharePoint Admin URL. MSAL is loaded as a dependency of Microsoft.Graph.Authentication.
    .PARAMETER CertificateThumbprint
        The thumbprint of the certificate to use for authentication.
    .PARAMETER AppID
        The Azure AD Application (Client) ID.
    .PARAMETER Tenant
        The tenant domain or ID.
    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).
    .PARAMETER AdminUrl
        The SharePoint Admin URL.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CertificateThumbprint,

        [Parameter(Mandatory = $true)]
        [string]$AppID,

        [Parameter(Mandatory = $true)]
        [string]$Tenant,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment,

        [Parameter(Mandatory = $true)]
        [string]$AdminUrl
    )

    Initialize-Msal

    $Authority = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com/$Tenant" }
        { $_ -in @("gcchigh", "dod") } { "https://login.microsoftonline.us/$Tenant" }
    }

    # Load certificate from store (try CurrentUser first, then LocalMachine)
    $Certificate = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $Certificate) {
        $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    }
    if (-not $Certificate) {
        throw "Certificate with thumbprint '$CertificateThumbprint' not found in CurrentUser or LocalMachine certificate stores."
    }

    try {
        $MsalApp = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).
            WithCertificate($Certificate).
            WithAuthority($Authority).
            Build()

        $TokenResult = $MsalApp.AcquireTokenForClient([string[]]@("$AdminUrl/.default")).ExecuteAsync().GetAwaiter().GetResult()
        return $TokenResult.AccessToken
    }
    catch {
        throw "Failed to acquire SharePoint access token: $($_.Exception.Message)"
    }
}

function Get-SPOAccessTokenInteractive {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token for SharePoint Admin API using interactive browser authentication.
    .DESCRIPTION
        Uses MSAL (Microsoft.Identity.Client) PublicClientApplication to acquire a token via
        interactive browser sign-in. MSAL handles the browser popup, redirect, and code exchange.
    .PARAMETER Tenant
        The tenant domain or ID.
    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).
    .PARAMETER AdminUrl
        The SharePoint Admin URL.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Tenant,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment,

        [Parameter(Mandatory = $true)]
        [string]$AdminUrl
    )

    Initialize-Msal

    # SharePoint Online Management Shell app ID - pre-authorized for SharePoint Admin API
    $ClientId = "9bc3ab49-b65d-410a-85ad-de819febfddc"
    $RedirectUri = "http://localhost"

    $Authority = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com/$Tenant" }
        { $_ -in @("gcchigh", "dod") } { "https://login.microsoftonline.us/$Tenant" }
    }

    try {
        $MsalApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId).
            WithAuthority($Authority).
            WithRedirectUri($RedirectUri).
            Build()

        $Scopes = [string[]]@("$AdminUrl/.default")
        $TokenResult = $MsalApp.AcquireTokenInteractive($Scopes).
            WithPrompt([Microsoft.Identity.Client.Prompt]::SelectAccount).
            ExecuteAsync().GetAwaiter().GetResult()

        return $TokenResult.AccessToken
    }
    catch {
        throw "Failed to acquire SharePoint access token interactively: $($_.Exception.Message)"
    }
}

function Invoke-SPORestMethod {
    <#
    .SYNOPSIS
        Invokes a SharePoint Admin REST API method.
    .DESCRIPTION
        Wrapper for making authenticated requests to SharePoint Admin REST API.
    .PARAMETER AdminUrl
        The SharePoint Admin URL.
    .PARAMETER AccessToken
        The OAuth2 access token.
    .PARAMETER Endpoint
        The API endpoint (e.g., "/_api/SPO.Tenant").
    .PARAMETER Method
        HTTP method (default: GET).
    .PARAMETER Body
        Request body (optional).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AdminUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $false)]
        [string]$Method = "GET",

        [Parameter(Mandatory = $false)]
        [string]$Body = $null
    )

    $Uri = "$AdminUrl$Endpoint"
    $Headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Accept"        = "application/json;odata=verbose"
        "Content-Type"  = "application/json;odata=verbose"
    }

    $Params = @{
        Uri         = $Uri
        Method      = $Method
        Headers     = $Headers
        ErrorAction = "Stop"
    }

    if ($Body) {
        $Params.Body = $Body
    }

    try {
        $Response = Invoke-RestMethod @Params
        return $Response
    }
    catch {
        throw "SharePoint REST API call failed: $($_.Exception.Message)"
    }
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
    $Endpoint = "/_api/SPO.Tenant"

    try {
        $Response = Invoke-SPORestMethod -AdminUrl $AdminUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"

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
        $Response = Invoke-SPORestMethod -AdminUrl $AdminUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "POST"

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

    $AdminUrl = switch ($M365Environment) {
        "commercial" { "https://$InitialDomainPrefix-admin.sharepoint.com" }
        "gcc"        { "https://$InitialDomainPrefix-admin.sharepoint.com" }
        "gcchigh"    { "https://$InitialDomainPrefix-admin.sharepoint.us" }
        "dod"        { "https://$InitialDomainPrefix-admin.sharepoint-mil.us" }
    }

    return $AdminUrl
}

Export-ModuleMember -Function @(
    'Get-SPOAccessToken',
    'Get-SPOAccessTokenInteractive',
    'Invoke-SPORestMethod',
    'Get-SPOTenantRest',
    'Get-SPOSiteRest',
    'Get-SPOAdminUrl'
)
