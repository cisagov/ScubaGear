Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod

function Get-ExchangeOnlineScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Exchange Online based on M365 environment.
    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    $Scope = switch ($M365Environment.ToLower()) {
        "commercial" { "https://outlook.office365.com/.default" }
        "gcc"        { "https://outlook.office365.com/.default" }
        "gcchigh"    { "https://outlook.office365.us/.default" }
        "dod"        { "https://outlook-dod.office365.us/.default" }
    }

    return $Scope
}

function Get-ExchangeOnlineApiEndpoint {
    <#
    .SYNOPSIS
        Dynamically resolves the Exchange Online Admin API endpoint URI.
    .DESCRIPTION
        Calls the Exchange Online front-door endpoint to determine the actual backend
        API endpoint. Some tenants get redirected to a tenant-specific subdomain.
        Returns a URI in the format:
        https://<prefix>.outlook.office365.com/adminapi/beta/<TenantId>/InvokeCommand
    .PARAMETER TenantId
        The Azure AD tenant ID.
    .PARAMETER TenantDomain
        The tenant domain (e.g., contoso.onmicrosoft.com).
    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).
    .PARAMETER AccessToken
        The OAuth2 access token for Exchange Online.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$TenantDomain,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $AdminApiFrontDoorBaseUri = switch ($M365Environment.ToLower()) {
        "commercial" { "https://outlook.office365.com" }
        "gcc"        { "https://outlook.office365.com" }
        "gcchigh"    { "https://outlook.office365.us" }
        "dod"        { "https://outlook-dod.office365.us" }
    }

    $BackendSuffix = switch ($M365Environment.ToLower()) {
        "commercial" { ".outlook.office365.com" }
        "gcc"        { ".outlook.office365.com" }
        "gcchigh"    { ".outlook.office365.us" }
        "dod"        { ".outlook-dod.office365.us" }
    }

    $Headers = @{
        "Authorization"   = "Bearer $AccessToken"
        "X-AnchorMailbox" = "UPN:SystemMailbox{bb558c35-97f1-4cb9-8ff7-d53741dc928c}@$TenantDomain"
    }

    $DefaultInvokeEndpoint = "$AdminApiFrontDoorBaseUri/adminapi/beta/$TenantId/InvokeCommand"

    $Handler = $null
    $HttpClient = $null
    $Request = $null
    $Response = $null

    try {
        $FrontDoorEndpoint = "$AdminApiFrontDoorBaseUri/AdminApi/v1.0/$TenantId/EXOModuleFile"
        $Handler = [System.Net.Http.HttpClientHandler]::new()
        $Handler.AllowAutoRedirect = $false
        $HttpClient = [System.Net.Http.HttpClient]::new($Handler)
        $Request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, $FrontDoorEndpoint)

        foreach ($Header in $Headers.GetEnumerator()) {
            $null = $Request.Headers.TryAddWithoutValidation($Header.Key, $Header.Value)
        }

        $Response = $HttpClient.SendAsync(
            $Request,
            [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead
        ).GetAwaiter().GetResult()

        if ((([int]$Response.StatusCode) -ge 300) -and (([int]$Response.StatusCode) -lt 400) -and $Response.Headers.Location) {
            $RedirectUri = $Response.Headers.Location
            if (-not $RedirectUri.IsAbsoluteUri) {
                $RedirectUri = [Uri]::new([Uri]$AdminApiFrontDoorBaseUri, $RedirectUri)
            }
            $Prefix = $RedirectUri.Host.Split('.')[0]
            return "https://$Prefix$BackendSuffix/adminapi/beta/$TenantId/InvokeCommand"
        }
        else {
            return $DefaultInvokeEndpoint
        }
    }
    catch {
        throw "Failed to resolve Exchange Online API endpoint: $($_.Exception.Message)"
    }
    finally {
        if ($Response) {
            $Response.Dispose()
        }
        if ($Request) {
            $Request.Dispose()
        }
        if ($HttpClient) {
            $HttpClient.Dispose()
        }
        if ($Handler) {
            $Handler.Dispose()
        }
    }
}

function Invoke-EXORestMethod {
    <#
    .SYNOPSIS
        Invokes an Exchange Online cmdlet via the Admin REST API.
    .DESCRIPTION
        Calls the Exchange Online AdminApi InvokeCommand endpoint with the specified
        cmdlet name. The backend API expects the cmdlet name as a parameter in the
        request body and returns the results as JSON.
    .PARAMETER CmdletName
        The Exchange Online cmdlet to invoke (e.g., "Get-RemoteDomain", "Get-OrganizationConfig").
    .PARAMETER ApiEndpoint
        The fully-qualified InvokeCommand endpoint URI.
    .PARAMETER AccessToken
        The OAuth2 access token for Exchange Online.
    .PARAMETER Parameters
        Optional hashtable of parameters to pass to the cmdlet.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CmdletName,

        [Parameter(Mandatory = $true)]
        [string]$ApiEndpoint,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    $Headers = @{
        "Authorization"     = "Bearer $AccessToken"
        "Prefer"            = "odata.maxpagesize=1000"
        "X-ResponseFormat"  = "json"
        "client-request-id" = [guid]::NewGuid().ToString()
        "User-Agent"        = "ScubaGear"
    }

    $Body = @{
        CmdletInput = @{
            CmdletName = $CmdletName
            Parameters = $Parameters
        }
    } | ConvertTo-Json -Depth 5

    try {
        $Response = Invoke-RestMethod -Method POST -Uri $ApiEndpoint -Headers $Headers -Body $Body -ContentType "application/json"
        return $Response.value
    }
    catch {
        throw "Exchange Online API call '$CmdletName' failed: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @(
    'Get-ExchangeOnlineScope',
    'Get-ExchangeOnlineApiEndpoint',
    'Invoke-EXORestMethod'
)
