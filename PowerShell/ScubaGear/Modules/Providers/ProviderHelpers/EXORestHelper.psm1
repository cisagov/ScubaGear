Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Permissions/PermissionsHelper.psm1") -Function Get-ScubaGearPermissions

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

    return Get-ScubaGearPermissions -Product exo -OutAs oauthScope -Environment $M365Environment
}

function Get-ComplianceScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Security & Compliance based on M365 environment.
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

    return Get-ScubaGearPermissions -Product securitysuite -OutAs oauthScope -Environment $M365Environment
}

function Resolve-ScubaFrontDoorEndpoint {
    <#
    .SYNOPSIS
        Probes an M365 admin API front-door to discover its tenant-specific regional backend host.
    .DESCRIPTION
        Shared by Get-ExchangeOnlineApiEndpoint and Get-ComplianceApiEndpoint. Sends an
        unfollowed GET to the front-door's EXOModuleFile discovery path; the front-door
        responds with a 3xx redirect whose Location header contains the regional prefix
        (e.g., gcc02b, nam13b). Combines that prefix with $BackendSuffix to build the
        final InvokeCommand endpoint.
    .PARAMETER FrontDoorBaseUri
        The product's front-door base URI (e.g., https://outlook.office365.com).
    .PARAMETER BackendSuffix
        The backend host suffix to combine with the discovered prefix (e.g., ".outlook.office365.com").
    .PARAMETER TenantId
        The Azure AD tenant ID.
    .PARAMETER TenantDomain
        The tenant domain (e.g., contoso.onmicrosoft.com).
    .PARAMETER AccessToken
        The OAuth2 access token used for the discovery call.
    .PARAMETER TimeoutSeconds
        Discovery call timeout in seconds (default: 15).
    .PARAMETER ThrowOnFailure
        If set, throws when the discovery call fails. Otherwise falls back to the
        default (non-redirected) endpoint and writes a warning.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FrontDoorBaseUri,

        [Parameter(Mandatory = $true)]
        [string]$BackendSuffix,

        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$TenantDomain,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 15,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    $DefaultEndpoint = "$FrontDoorBaseUri/adminapi/beta/$TenantId/InvokeCommand"
    $DiscoveryUrl = "$FrontDoorBaseUri/AdminApi/v1.0/$TenantId/EXOModuleFile"

    # On PS 5.1 Desktop, System.Net.Http is not loaded into a fresh process by default,
    # so the type literals below fail to resolve unless something else already loaded it.
    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue

    $Headers = @{
        "Authorization"   = "Bearer $AccessToken"
        "X-AnchorMailbox" = "UPN:SystemMailbox{bb558c35-97f1-4cb9-8ff7-d53741dc928c}@$TenantDomain"
    }

    $Handler = $null
    $HttpClient = $null
    $Request = $null
    $Response = $null

    try {
        $Handler = [System.Net.Http.HttpClientHandler]::new()
        $Handler.AllowAutoRedirect = $false
        $HttpClient = [System.Net.Http.HttpClient]::new($Handler)
        $HttpClient.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
        $Request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, $DiscoveryUrl)

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
                $RedirectUri = [Uri]::new([Uri]$FrontDoorBaseUri, $RedirectUri)
            }
            # The redirect points to the admin/protection front-end host, but the REST API
            # is served from the corresponding backend host built from $BackendSuffix.
            $Prefix = $RedirectUri.Host.Split('.')[0]
            $ResolvedEndpoint = "https://$Prefix$BackendSuffix/adminapi/beta/$TenantId/InvokeCommand"
            Write-Verbose "Front-door endpoint resolved: $ResolvedEndpoint"
            return $ResolvedEndpoint
        }

        Write-Verbose "Front-door did not redirect (status $([int]$Response.StatusCode)). Using default endpoint."
        return $DefaultEndpoint
    }
    catch {
        if ($ThrowOnFailure) {
            throw "Failed to resolve API endpoint: $($_.Exception.Message)"
        }
        Write-Warning "Failed to resolve API endpoint: $($_.Exception.Message). Using default."
        return $DefaultEndpoint
    }
    finally {
        if ($Response) { $Response.Dispose() }
        if ($Request) { $Request.Dispose() }
        if ($HttpClient) { $HttpClient.Dispose() }
        if ($Handler) { $Handler.Dispose() }
    }
}

function Get-ComplianceApiEndpoint {
    <#
    .SYNOPSIS
        Dynamically resolves the Security & Compliance Admin API endpoint URI.
    .DESCRIPTION
        Probes the compliance front-door to discover the tenant-specific regional
        backend (e.g., gcc02b, nam13b).  The front-door redirects to the regional
        host on the admin.protection domain; the actual REST API is served from
        the corresponding ps.compliance.protection host on port 443.
        Returns a URI in the format:
        https://<prefix>.ps.compliance.protection.outlook.com/adminapi/beta/<TenantId>/InvokeCommand
    .PARAMETER TenantId
        The Azure AD tenant ID.
    .PARAMETER TenantDomain
        The tenant domain (e.g., contoso.onmicrosoft.com).
    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).
    .PARAMETER AccessToken
        An OAuth2 access token (EXO or compliance-scoped) used for the discovery call.
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

    $FrontDoorBaseUri = Get-ScubaGearPermissions -Product securitysuite -OutAs endpoint -Environment $M365Environment

    # $BackendSuffix will end up looking like this: ".ps.compliance.protection.outlook.com"
    $BackendSuffix = "." + ($FrontDoorBaseUri -replace '^https://', '')

    return Resolve-ScubaFrontDoorEndpoint -FrontDoorBaseUri $FrontDoorBaseUri -BackendSuffix $BackendSuffix `
        -TenantId $TenantId -TenantDomain $TenantDomain -AccessToken $AccessToken
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

    $AdminApiFrontDoorBaseUri = Get-ScubaGearPermissions -Product exo -OutAs endpoint -Environment $M365Environment

    # $BackendSuffix will end up looking like this: ".outlook.office365.com"
    $BackendSuffix = "." + ($AdminApiFrontDoorBaseUri -replace '^https://', '')

    return Resolve-ScubaFrontDoorEndpoint -FrontDoorBaseUri $AdminApiFrontDoorBaseUri -BackendSuffix $BackendSuffix `
        -TenantId $TenantId -TenantDomain $TenantDomain -AccessToken $AccessToken -ThrowOnFailure
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

    $AdditionalHeaders = @{
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

    # Speeds up Invoke-RestMethod, disable progress bar
    $ProgressPreference = 'SilentlyContinue'

    try {
        $Response = Invoke-ScubaRestMethod -BaseUrl $ApiEndpoint -Endpoint "" -AccessToken $AccessToken `
            -Method POST -Body $Body -AdditionalHeaders $AdditionalHeaders -TimeoutSec 30 `
            -MaxRetries 3 -RetryDelaySeconds 5
        return $Response.value
    }
    catch {
        throw "Exchange Online API call '$CmdletName' failed: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @(
    'Get-ExchangeOnlineScope',
    'Get-ExchangeOnlineApiEndpoint',
    'Get-ComplianceScope',
    'Get-ComplianceApiEndpoint',
    'Invoke-EXORestMethod'
)
