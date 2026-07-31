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
        [switch]
        $UseSystemBrowserAuthentication,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $ServicePrincipalParams
    )
    if ($ServicePrincipalParams.CertThumbprintParams) {
        $TokenParameters = @{
            CertificateThumbprint = $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint
            AppID = $ServicePrincipalParams.CertThumbprintParams.AppID
            Tenant = $ServicePrincipalParams.CertThumbprintParams.Organization
            Scope = switch ($M365Environment) {
                { $_ -in @('commercial', 'gcc') } { 'https://graph.microsoft.com/.default' }
                default { 'https://graph.microsoft.us/.default' }
            }
        }
    }
    else {
        $TokenParameters = @{
            Scope = if ($Scopes) { $Scopes } else { @('Organization.Read.All') }
            ClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
            Tenant = 'organizations'
        }
        if ($UseSystemBrowserAuthentication) {
            $TokenParameters.DisableBroker = $true
        }
    }

    $TokenParameters.M365Environment = $M365Environment
    $Script:ScubaGraphSession = @{
        M365Environment = $M365Environment
        GraphEndpoint = switch ($M365Environment) {
            'gcchigh' { 'https://graph.microsoft.us' }
            'dod' { 'https://dod-graph.microsoft.us' }
            default { 'https://graph.microsoft.com' }
        }
        TokenParameters = $TokenParameters
    }
    $null = Get-MsalAccessToken @TokenParameters
}

function Get-ScubaGraphContext {
    [CmdletBinding()]
    param()

    if ($Script:ScubaGraphSession) {
        [pscustomobject]@{
            Environment = $Script:ScubaGraphSession.M365Environment
            GraphEndpoint = $Script:ScubaGraphSession.GraphEndpoint
        }
    }
}

function Disconnect-ScubaGraph {
    [CmdletBinding()]
    param()

    $Script:ScubaGraphSession = $null
    $Script:MsalAppCache = @{}
}

function Invoke-ScubaGraphRequest {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'OutputType', Justification = 'Retained for Invoke-MgGraphRequest call-site compatibility; Invoke-RestMethod already returns PSObject output.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [ValidateSet('GET', 'POST', 'PATCH', 'PUT', 'DELETE')]
        [string]$Method = 'GET',

        [object]$Body,

        [hashtable]$Headers,

        [string]$ContentType = 'application/json',

        [string]$OutputType,

        [ValidateRange(0, 10)]
        [int]$MaxRetries = 3
    )

    if (-not $Script:ScubaGraphSession) {
        throw 'Microsoft Graph is not connected. Call Connect-GraphHelper first.'
    }

    $RequestUri = if ([uri]::IsWellFormedUriString($Uri, [UriKind]::Absolute)) {
        $Uri
    }
    else {
        "$($Script:ScubaGraphSession.GraphEndpoint)/$($Uri.TrimStart('/'))"
    }

    $Attempt = 0
    $RefreshedToken = $false
    while ($Attempt -le $MaxRetries) {
        $Attempt++
        $TokenParameters = $Script:ScubaGraphSession.TokenParameters
        $AccessToken = Get-MsalAccessToken @TokenParameters
        $RequestHeaders = @{
            Authorization = "Bearer $AccessToken"
        }
        if ($Headers) {
            foreach ($Header in $Headers.GetEnumerator()) {
                $RequestHeaders[$Header.Key] = $Header.Value
            }
        }
        $RequestParameters = @{
            Uri = $RequestUri
            Method = $Method
            Headers = $RequestHeaders
            ErrorAction = 'Stop'
        }
        if ($null -ne $Body) {
            $RequestParameters.ContentType = $ContentType
            $RequestParameters.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 20 }
        }

        try {
            $Response = Invoke-RestMethod @RequestParameters
            if ($Method -eq 'GET' -and $Response.PSObject.Properties.Name -contains 'value') {
                $Items = [System.Collections.Generic.List[object]]::new()
                foreach ($Item in @($Response.value)) {
                    $Items.Add($Item)
                }
                $NextLink = $Response.'@odata.nextLink'
                while ($NextLink) {
                    $PageParameters = @{
                        Uri = $NextLink
                        Method = 'GET'
                        Headers = $RequestHeaders
                        ErrorAction = 'Stop'
                    }
                    $Page = Invoke-RestMethod @PageParameters
                    foreach ($Item in @($Page.value)) {
                        $Items.Add($Item)
                    }
                    $NextLink = $Page.'@odata.nextLink'
                }
                $Response.value = $Items.ToArray()
            }
            return $Response
        }
        catch {
            $StatusCode = $null
            if ($_.Exception.Response) {
                $StatusCode = [int]$_.Exception.Response.StatusCode
            }
            if ($StatusCode -eq 401 -and -not $RefreshedToken) {
                $RefreshedToken = $true
                $Script:MsalAppCache = @{}
                continue
            }
            if ($StatusCode -eq 429 -and $Attempt -le $MaxRetries) {
                $RetryAfter = 1
                $RetryAfterHeader = $_.Exception.Response.Headers['Retry-After']
                if ($RetryAfterHeader -as [int]) {
                    $RetryAfter = [int]$RetryAfterHeader
                }
                Start-Sleep -Seconds $RetryAfter
                continue
            }
            throw
        }
    }
}

function Get-TeamsAccessTokens {
    <#
    .SYNOPSIS
        Acquires the delegated Graph and Teams resource tokens required by Connect-MicrosoftTeams.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment,

        [Parameter(Mandatory = $false)]
        [switch]$DisableBroker
    )

    $TeamsClientId = "12128f48-ec9e-42f0-b203-ea49fb6af367"
    $GraphScope = switch ($M365Environment) {
        { $_ -in @("commercial", "gcc") } { "https://graph.microsoft.com/.default" }
        { $_ -in @("gcchigh", "dod") } { "https://graph.microsoft.us/.default" }
    }
    $CommonParameters = @{
        ClientId = $TeamsClientId
        Tenant = "organizations"
        M365Environment = $M365Environment
        DisableBroker = $DisableBroker
    }

    Get-MsalAccessToken -Scope $GraphScope @CommonParameters
    Get-MsalAccessToken -Scope "48ac35b8-9aa8-4d74-927d-1f4a14a0b239/.default" @CommonParameters
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

    $ModuleRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
    $LockPath = Join-Path $ModuleRoot 'dependencies/msal-lock.json'
    $LibPath = Join-Path $ModuleRoot 'lib/net462'

    if (-not (Test-Path -Path $LockPath -PathType Leaf)) {
        throw "MSAL dependency lock was not found: $LockPath"
    }

    $Lock = Get-Content -Path $LockPath -Raw | ConvertFrom-Json
    $ExpectedAssemblyVersion = [version]"$($Lock.msalVersion).0"
    $LoadedMsal = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
        $_.GetName().Name -eq 'Microsoft.Identity.Client'
    } | Select-Object -First 1
    if ($LoadedMsal -and $LoadedMsal.GetName().Version -ne $ExpectedAssemblyVersion) {
        throw "Microsoft.Identity.Client $($LoadedMsal.GetName().Version) is already loaded; ScubaGear requires $ExpectedAssemblyVersion. Start a new PowerShell session."
    }

    if (-not $Script:MsalDependenciesValidated) {
        foreach ($Record in $Lock.files) {
            $FilePath = Join-Path $ModuleRoot $Record.path
            if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
                throw "Bundled MSAL dependency is missing: $($Record.path)"
            }
            $ActualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
            if ($ActualHash -ne $Record.sha256) {
                throw "Bundled MSAL dependency failed SHA-256 validation: $($Record.path)"
            }
            $Signature = Get-AuthenticodeSignature -FilePath $FilePath
            if ($Signature.Status -ne 'Valid' -or
                -not $Signature.SignerCertificate -or
                $Signature.SignerCertificate.Subject -notmatch '(^|,\s*)O=Microsoft Corporation(,|$)') {
                throw "Bundled MSAL dependency failed Authenticode validation: $($Record.path)"
            }
        }
        $Script:MsalDependenciesValidated = $true
    }

    $Architecture = switch ($env:PROCESSOR_ARCHITECTURE) {
        'ARM64' { 'win-arm64' }
        'x86' { 'win-x86' }
        default { 'win-x64' }
    }
    $NativePath = Join-Path $ModuleRoot "runtimes/$Architecture/native"
    if (($env:PATH -split ';') -notcontains $NativePath) {
        $env:PATH = "$NativePath;$env:PATH"
    }

    $LoadOrder = @(
        'System.Runtime.CompilerServices.Unsafe.dll',
        'System.Diagnostics.DiagnosticSource.dll',
        'Microsoft.IdentityModel.Abstractions.dll',
        'Microsoft.Identity.Client.dll',
        'Microsoft.Identity.Client.NativeInterop.dll',
        'Microsoft.Identity.Client.Broker.dll'
    )
    foreach ($AssemblyFile in $LoadOrder) {
        $AssemblyName = [System.IO.Path]::GetFileNameWithoutExtension($AssemblyFile)
        $IsLoaded = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.GetName().Name -eq $AssemblyName
        }
        if (-not $IsLoaded) {
            [void][Reflection.Assembly]::LoadFrom((Join-Path $LibPath $AssemblyFile))
        }
    }
}

function Get-ScubaParentWindowHandle {
    [CmdletBinding()]
    param()

    $Handle = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
    if ($Handle -ne [IntPtr]::Zero) {
        return $Handle
    }

    if (-not $Script:ScubaWindowNativeMethods) {
        $NativeMethods = @'
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern System.IntPtr GetConsoleWindow();

[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern System.IntPtr GetForegroundWindow();
'@
        $Script:ScubaWindowNativeMethods = Add-Type `
            -MemberDefinition $NativeMethods `
            -Name 'WindowNativeMethods' `
            -Namespace 'ScubaGear' `
            -PassThru
    }

    $Handle = $Script:ScubaWindowNativeMethods::GetConsoleWindow()
    if ($Handle -eq [IntPtr]::Zero) {
        $Handle = $Script:ScubaWindowNativeMethods::GetForegroundWindow()
    }
    if ($Handle -eq [IntPtr]::Zero) {
        throw 'Unable to resolve a parent window handle required by WAM.'
    }

    $Handle
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
        [string[]]$Scope,

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
        [string]$M365Environment,

        [Parameter(Mandatory = $false, ParameterSetName = 'Interactive')]
        [switch]$DisableBroker
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
                $CacheKey = "PUB:$ClientId|$Authority|Broker:$(-not $DisableBroker)"
                if (-not $Script:MsalAppCache.ContainsKey($CacheKey)) {
                    $Builder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId).
                        WithAuthority($Authority)
                    if ($DisableBroker) {
                        $Builder = $Builder.WithRedirectUri('http://localhost')
                    }
                    else {
                        $Builder = $Builder.WithDefaultRedirectUri()
                        $Builder = $Builder.WithParentActivityOrWindow([Func[IntPtr]] {
                            Get-ScubaParentWindowHandle
                        })
                        $BrokerOptions = [Microsoft.Identity.Client.BrokerOptions]::new(
                            [Microsoft.Identity.Client.BrokerOptions+OperatingSystems]::Windows
                        )
                        $Builder = [Microsoft.Identity.Client.Broker.BrokerExtension]::WithBroker($Builder, $BrokerOptions)
                    }
                    $Script:MsalAppCache[$CacheKey] = $Builder.Build()
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
                    elseif (-not $DisableBroker) {
                        $TokenResult = $MsalApp.AcquireTokenSilent(
                            [string[]]@($Scope),
                            [Microsoft.Identity.Client.PublicClientApplication]::OperatingSystemAccount
                        ).ExecuteAsync().GetAwaiter().GetResult()
                    }
                }
                catch {
                    # Silent failed (no cached token for this scope) — fall through to interactive
                    $TokenResult = $null
                }

                if (-not $TokenResult) {
                    $InteractiveRequest = $MsalApp.AcquireTokenInteractive([string[]]@($Scope))
                    if ($DisableBroker) {
                        $InteractiveRequest = $InteractiveRequest.WithUseEmbeddedWebView($false)
                    }
                    $TokenResult = $InteractiveRequest.ExecuteAsync().GetAwaiter().GetResult()
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
    'Disconnect-ScubaGraph',
    'Get-ScubaGraphContext',
    'Get-TeamsAccessTokens',
    'Initialize-Msal',
    'Get-MsalAccessToken',
    'Invoke-ScubaGraphRequest'
)
