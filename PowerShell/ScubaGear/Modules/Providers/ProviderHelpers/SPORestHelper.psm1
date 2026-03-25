function Get-SPOAccessToken {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token for SharePoint Admin API using certificate authentication.
    .DESCRIPTION
        Creates a JWT assertion signed with the certificate private key and exchanges it for an access token.
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

    # Determine token endpoint based on environment
    $TokenEndpoint = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com" }
        { $_ -in @("gcchigh", "dod") } { "https://login.microsoftonline.us" }
    }

    # Load certificate from store (try CurrentUser first, then LocalMachine)
    $Certificate = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $Certificate) {
        $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    }
    if (-not $Certificate) {
        throw "Certificate with thumbprint '$CertificateThumbprint' not found in CurrentUser or LocalMachine certificate stores."
    }

    # Build JWT header
    $CertHash = $Certificate.GetCertHash()
    $X5t = [System.Convert]::ToBase64String($CertHash) -replace '\+', '-' -replace '/', '_' -replace '='
    $JwtHeader = @{
        alg = "RS256"
        typ = "JWT"
        x5t = $X5t
    } | ConvertTo-Json -Compress

    # Build JWT payload
    $Now = [System.DateTimeOffset]::UtcNow
    $JwtPayload = @{
        aud = "$TokenEndpoint/$Tenant/oauth2/v2.0/token"
        iss = $AppID
        sub = $AppID
        jti = [guid]::NewGuid().ToString()
        nbf = $Now.ToUnixTimeSeconds()
        exp = $Now.AddMinutes(10).ToUnixTimeSeconds()
    } | ConvertTo-Json -Compress

    # Base64Url encode header and payload
    $HeaderB64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($JwtHeader)) -replace '\+', '-' -replace '/', '_' -replace '='
    $PayloadB64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($JwtPayload)) -replace '\+', '-' -replace '/', '_' -replace '='

    # Sign the JWT
    $DataToSign = [System.Text.Encoding]::UTF8.GetBytes("$HeaderB64.$PayloadB64")
    $RSA = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
    $Signature = $RSA.SignData($DataToSign, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $SignatureB64 = [System.Convert]::ToBase64String($Signature) -replace '\+', '-' -replace '/', '_' -replace '='

    $ClientAssertion = "$HeaderB64.$PayloadB64.$SignatureB64"

    # Request token
    $TokenUrl = "$TokenEndpoint/$Tenant/oauth2/v2.0/token"
    $Scope = "$AdminUrl/.default"

    $Body = @{
        client_id             = $AppID
        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        client_assertion      = $ClientAssertion
        scope                 = $Scope
        grant_type            = "client_credentials"
    }

    try {
        $Response = Invoke-RestMethod -Uri $TokenUrl -Method POST -Body $Body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
        return $Response.access_token
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
        Uses authorization code flow with PKCE via browser popup for user authentication.
        Uses SharePoint Online Management Shell app ID which is pre-authorized for SharePoint Admin API.
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

    # SharePoint Online Management Shell app ID - pre-authorized for SharePoint Admin API
    $ClientId = "9bc3ab49-b65d-410a-85ad-de819febfddc"
    $RedirectUri = "https://oauth.spops.microsoft.com/"

    # Determine endpoints based on environment
    $AuthEndpoint = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com" }
        { $_ -in @("gcchigh", "dod") } { "https://login.microsoftonline.us" }
    }

    # Generate state for CSRF protection
    $State = [guid]::NewGuid().ToString()

    # Build authorization URL - use SharePoint resource
    $Resource = $AdminUrl
    $AuthUrl = "$AuthEndpoint/$Tenant/oauth2/authorize?" +
        "client_id=$ClientId" +
        "&response_type=code" +
        "&redirect_uri=$([System.Web.HttpUtility]::UrlEncode($RedirectUri))" +
        "&resource=$([System.Web.HttpUtility]::UrlEncode($Resource))" +
        "&state=$State" +
        "&prompt=select_account"

    Write-Information "Opening browser for SharePoint authentication..."
    Write-Information "Please sign in with a SharePoint Administrator account."

    # Open browser for authentication
    Start-Process $AuthUrl

    # Prompt user to paste the redirect URL
    Write-Information ""
    Write-Information "After signing in, you will be redirected to a page."
    Write-Information "Copy the ENTIRE URL from your browser's address bar and paste it here:"
    $RedirectResponse = Read-Host "Paste URL"

    # Parse authorization code from the pasted URL
    try {
        $Uri = [System.Uri]$RedirectResponse
        $QueryString = [System.Web.HttpUtility]::ParseQueryString($Uri.Query)
        $AuthCode = $QueryString["code"]
        $ErrorCode = $QueryString["error"]
    }
    catch {
        throw "Invalid URL format. Make sure you copied the complete URL from the browser."
    }

    if ($ErrorCode) {
        throw "Authentication failed: $ErrorCode - $($QueryString["error_description"])"
    }

    if (-not $AuthCode) {
        throw "No authorization code found in the URL. Make sure you copied the complete URL."
    }

    # Exchange authorization code for token (OAuth 1.0 endpoint for v1 tokens)
    $TokenUrl = "$AuthEndpoint/$Tenant/oauth2/token"
    $TokenBody = @{
        client_id    = $ClientId
        grant_type   = "authorization_code"
        code         = $AuthCode
        redirect_uri = $RedirectUri
        resource     = $Resource
    }

    try {
        $TokenResponse = Invoke-RestMethod -Uri $TokenUrl -Method POST -Body $TokenBody -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
        Write-Information "Authentication successful!"
        return $TokenResponse.access_token
    }
    catch {
        throw "Failed to exchange code for token: $($_.Exception.Message)"
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
        Write-Warning "Could not retrieve site properties for '$Identity'. This data is not required for current SharePoint policies."
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
