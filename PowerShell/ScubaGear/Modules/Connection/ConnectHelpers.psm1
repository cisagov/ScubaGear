function Connect-GraphHelper {
    <#
    .Description
    This function is used for assisting in connecting to different M365 Environments via the Graph API.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Scopes = $null,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $ServicePrincipalParams
    )
    $GraphParams = @{
        'ErrorAction' = 'Stop';
    }

    if ($ServicePrincipalParams.CertThumbprintParams) {
        $GraphParams += @{
            CertificateThumbprint = $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint;
            ClientID              = $ServicePrincipalParams.CertThumbprintParams.AppID;
            TenantId              = $ServicePrincipalParams.CertThumbprintParams.Organization; # Organization also works here
        }
    }
    else {
        $GraphParams += @{Scopes = $Scopes; }
    }
    switch ($M365Environment) {
        "gcchigh" {
            $GraphParams += @{'Environment' = "USGov"; }
        }
        "dod" {
            $GraphParams += @{'Environment' = "USGovDoD"; }
        }
    }
    Connect-MgGraph @GraphParams | Out-Null
}

function Initialize-Msal {
    <#
    .SYNOPSIS
        Ensures the MSAL assembly is loaded and types are resolvable.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param()

    try {
        $null = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]
        return
    }
    catch {
        Write-Verbose "MSAL types not yet resolvable. Loading Microsoft.Identity.Client.dll explicitly."
    }

    $GraphModule = Get-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
    if (-not $GraphModule) {
        throw "Microsoft.Graph.Authentication module is not loaded. Ensure Connect-MgGraph has been called before acquiring tokens."
    }

    $ModulePath = $GraphModule.Path | Split-Path
    $MsalDll = Get-ChildItem -Path $ModulePath -Recurse -Filter "Microsoft.Identity.Client.dll" -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $MsalDll) {
        throw "Microsoft.Identity.Client.dll not found in the Microsoft.Graph.Authentication module directory."
    }

    $Sig = Get-AuthenticodeSignature -FilePath $MsalDll.FullName
    if ($Sig.Status -ne 'Valid') {
        throw "Microsoft.Identity.Client.dll signature is not valid (status: $($Sig.Status)). Aborting MSAL load."
    }

    Add-Type -Path $MsalDll.FullName
}

function Get-MsalAccessToken {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token via MSAL using certificate or interactive auth.
        Reuses cached MSAL app instances and attempts silent token acquisition before
        prompting interactively, minimizing the number of browser popups per session.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding(DefaultParameterSetName = 'Interactive')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Scope,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [string]$CertificateThumbprint,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal')]
        [string]$AppID,

        [Parameter(Mandatory = $true, ParameterSetName = 'Interactive')]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$Tenant,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    Initialize-Msal

    $Authority = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://login.microsoftonline.com/$Tenant" }
        { $_ -in @("gcchigh", "dod") } { "https://login.microsoftonline.us/$Tenant" }
    }

    if ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal') {
        $Certificate = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
        if (-not $Certificate) {
            $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
        }
        if (-not $Certificate) {
            throw "Certificate with thumbprint '$CertificateThumbprint' not found in CurrentUser or LocalMachine certificate stores."
        }
    }

    # Cache MSAL app instances by key so token cache persists across calls.
    # This enables AcquireTokenSilent to succeed for subsequent scope requests
    # after the first interactive sign-in, reducing browser popups to one.
    if (-not $Script:MsalAppCache) {
        $Script:MsalAppCache = @{}
    }

    $MaxAttempts = 3
    $Attempt = 0
    while ($Attempt -lt $MaxAttempts) {
        $Attempt++
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal') {
                $CacheKey = "SP:$AppID|$Authority"
                if (-not $Script:MsalAppCache.ContainsKey($CacheKey)) {
                    $Script:MsalAppCache[$CacheKey] = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).
                        WithCertificate($Certificate).
                        WithAuthority($Authority).
                        Build()
                }
                $MsalApp = $Script:MsalAppCache[$CacheKey]
                $TokenResult = $MsalApp.AcquireTokenForClient([string[]]@($Scope)).ExecuteAsync().GetAwaiter().GetResult()
            }
            else {
                $RedirectUri = "http://localhost"
                $CacheKey = "PUB:$ClientId|$Authority"
                if (-not $Script:MsalAppCache.ContainsKey($CacheKey)) {
                    $Script:MsalAppCache[$CacheKey] = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId).
                        WithAuthority($Authority).
                        WithRedirectUri($RedirectUri).
                        Build()
                }
                $MsalApp = $Script:MsalAppCache[$CacheKey]

                # Try silent acquisition first using cached accounts
                $TokenResult = $null
                try {
                    $Accounts = $MsalApp.GetAccountsAsync().GetAwaiter().GetResult()
                    if ($Accounts -and $Accounts.Count -gt 0) {
                        $TokenResult = $MsalApp.AcquireTokenSilent([string[]]@($Scope), $Accounts[0]).
                            ExecuteAsync().GetAwaiter().GetResult()
                    }
                }
                catch {
                    # Silent failed (no cached token for this scope) — fall through to interactive
                    $TokenResult = $null
                }

                if (-not $TokenResult) {
                    $TokenResult = $MsalApp.AcquireTokenInteractive([string[]]@($Scope)).
                        WithPrompt([Microsoft.Identity.Client.Prompt]::SelectAccount).
                        WithUseEmbeddedWebView($false).
                        ExecuteAsync().GetAwaiter().GetResult()
                }
            }

            return $TokenResult.AccessToken
        }
        catch {
            if ($Attempt -ge $MaxAttempts) {
                Write-Warning "Failed to acquire access token after $MaxAttempts attempts"
                throw
            }

            Write-Warning "Token acquisition attempt $Attempt failed: $($_.Exception.Message). Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
        }
    }
}

Export-ModuleMember -Function @(
    'Connect-GraphHelper',
    'Initialize-Msal',
    'Get-MsalAccessToken'
)
