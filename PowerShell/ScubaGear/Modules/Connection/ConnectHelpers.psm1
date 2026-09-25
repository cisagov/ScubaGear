# Session state stored globally so all module import paths share the same instance
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Cross-module singleton required for MSAL session sharing')]
param()
if (-not $Global:ScubaGearState) {
    $Global:ScubaGearState = @{ Session = $null; MsalAppCache = @{}; MsalValidated = $false; MsalLibraryPath = $null; MsalResolverRegistered = $false }
}

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
    }

    $TokenParameters.M365Environment = $M365Environment
    $Global:ScubaGearState.Session = @{
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
    <#
    .SYNOPSIS
        Returns the active Graph session environment and endpoint.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param()

    if ($Global:ScubaGearState.Session) {
        [pscustomobject]@{
            Environment = $Global:ScubaGearState.Session.M365Environment
            GraphEndpoint = $Global:ScubaGearState.Session.GraphEndpoint
        }
    }
}

function Disconnect-ScubaGraph {
    <#
    .SYNOPSIS
        Clears the Graph session and MSAL token cache.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param()

    $Global:ScubaGearState.Session = $null
    $Global:ScubaGearState.MsalAppCache = @{}
}

function Invoke-ScubaGraphRequest {
    <#
    .SYNOPSIS
        Sends an authenticated REST request to the Microsoft Graph API.
    .FUNCTIONALITY
        Internal
    #>
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

    if (-not $Global:ScubaGearState.Session) {
        throw 'Microsoft Graph is not connected. Call Connect-GraphHelper first.'
    }

    $RequestUri = if ([uri]::IsWellFormedUriString($Uri, [UriKind]::Absolute)) {
        $Uri
    }
    else {
        "$($Global:ScubaGearState.Session.GraphEndpoint)/$($Uri.TrimStart('/'))"
    }

    $Attempt = 0
    $RefreshedToken = $false
    while ($Attempt -le $MaxRetries) {
        $Attempt++
        $TokenParameters = $Global:ScubaGearState.Session.TokenParameters
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
                $Global:ScubaGearState.MsalAppCache = @{}
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
            $IsTransientFailure = $null -eq $StatusCode -or $StatusCode -in @(408, 500, 502, 503, 504)
            if ($IsTransientFailure -and $Attempt -le $MaxRetries) {
                Start-Sleep -Seconds ([Math]::Min([Math]::Pow(2, $Attempt - 1), 4))
                continue
            }
            throw
        }
    }
}

function Get-ScubaMsalManifest {
    <#
    .SYNOPSIS
        Returns the pinned MSAL dependency manifest declared in RequiredVersions.ps1.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param()

    $ModuleRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
    $RequiredVersionsPath = Join-Path $ModuleRoot 'RequiredVersions.ps1'
    if (-not (Test-Path -Path $RequiredVersionsPath -PathType Leaf)) {
        throw "RequiredVersions.ps1 was not found: $RequiredVersionsPath"
    }

    # Dot-source in a child scope so only the manifest variable leaks back.
    $MsalDependency = $null
    . $RequiredVersionsPath
    if (-not $MsalDependency) {
        throw 'The MSAL dependency manifest ($MsalDependency) is not defined in RequiredVersions.ps1.'
    }
    return $MsalDependency
}

function Get-ScubaMsalLibraryPath {
    <#
    .SYNOPSIS
        Resolves the cache folder that holds the MSAL assemblies for a given version.
        Honors the $env:ScubaGearMsalPath override so air-gapped hosts can pre-stage the files.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    if ($env:ScubaGearMsalPath) {
        return $env:ScubaGearMsalPath
    }

    $HomeDirectory = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    Join-Path -Path $HomeDirectory -ChildPath ".scubagear/MSAL/$Version/net462"
}

function Test-ScubaMsalLibrary {
    <#
    .SYNOPSIS
        Verifies every MSAL assembly in the cache matches the manifest hash, signer, and version.
        Returns $true/$false, or throws when -ThrowOnFail is set.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Manifest,

        [switch]$ThrowOnFail
    )

    foreach ($Record in $Manifest.Files) {
        $FilePath = Join-Path $LibraryPath $Record.File
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            if ($ThrowOnFail) { throw "MSAL dependency is missing from the cache: $($Record.File)" }
            return $false
        }
        $ActualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
        if ($ActualHash -ne $Record.Sha256) {
            if ($ThrowOnFail) { throw "MSAL dependency failed SHA-256 validation: $($Record.File)" }
            return $false
        }
        $Signature = Get-AuthenticodeSignature -FilePath $FilePath
        if ($Signature.Status -ne 'Valid' -or
            -not $Signature.SignerCertificate -or
            $Signature.SignerCertificate.Subject -notmatch [regex]::Escape($Manifest.SignerOrganization)) {
            if ($ThrowOnFail) { throw "MSAL dependency failed Authenticode validation: $($Record.File)" }
            return $false
        }
    }
    return $true
}

function Save-ScubaNuGetPackage {
    <#
    .SYNOPSIS
        Downloads a NuGet package (.nupkg) to a file, trying multiple NuGet endpoints so a network
        that blocks one host can still reach the authoritative signed package. All endpoints serve
        identical bytes, so the caller's SHA-256 check is unaffected by which one responds.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [string]$OutFile
    )

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    catch {
        Write-Verbose "Unable to adjust TLS protocol: $($_.Exception.Message)"
    }

    $IdLower = $Id.ToLowerInvariant()
    $Endpoints = @(
        "https://api.nuget.org/v3-flatcontainer/$IdLower/$Version/$IdLower.$Version.nupkg"
        "https://www.nuget.org/api/v2/package/$Id/$Version"
        "https://globalcdn.nuget.org/packages/$IdLower.$Version.nupkg"
    )

    $PreviousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        $Failures = @()
        foreach ($Uri in $Endpoints) {
            try {
                Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
                return
            }
            catch {
                $Failures += "$Uri -> $($_.Exception.Message)"
            }
        }
        throw "Unable to download $Id $Version from any NuGet endpoint:`n$($Failures -join "`n")"
    }
    finally {
        $ProgressPreference = $PreviousProgress
    }
}

function Install-ScubaMsalDependency {
    <#
    .SYNOPSIS
        Downloads the pinned MSAL assemblies from NuGet into the ScubaGear cache and verifies them.
        Each package is fetched directly (flat-container .nupkg), hash-checked, and the target
        assembly is extracted into the net462 cache folder. No nuget.exe dependency.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [string]$LibraryPath,

        [switch]$Force
    )

    $Manifest = Get-ScubaMsalManifest
    if (-not $LibraryPath) {
        $LibraryPath = Get-ScubaMsalLibraryPath -Version $Manifest.Version
    }

    if (-not $Force -and (Test-ScubaMsalLibrary -LibraryPath $LibraryPath -Manifest $Manifest)) {
        return $LibraryPath
    }

    if (-not ('System.IO.Compression.ZipFile' -as [type])) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    }

    # PowerShell 5.1 defaults to SSL3/TLS1.0; NuGet requires TLS 1.2+.
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    catch {
        Write-Verbose "Unable to adjust TLS protocol: $($_.Exception.Message)"
    }

    New-Item -ItemType Directory -Path $LibraryPath -Force | Out-Null
    $TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "scubagear-msal-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
    try {
        foreach ($Package in $Manifest.Packages) {
            $NupkgPath = Join-Path $TempRoot "$($Package.Id).$($Package.Version).nupkg"
            Save-ScubaNuGetPackage -Id $Package.Id -Version $Package.Version -OutFile $NupkgPath

            $NupkgHash = (Get-FileHash -Path $NupkgPath -Algorithm SHA256).Hash
            if ($NupkgHash -ne $Package.Sha256) {
                throw "MSAL package failed SHA-256 validation: $($Package.Id) $($Package.Version)"
            }

            $Archive = [System.IO.Compression.ZipFile]::OpenRead($NupkgPath)
            try {
                $Entry = $Archive.Entries | Where-Object { $_.FullName -eq $Package.LibPath } | Select-Object -First 1
                if (-not $Entry) {
                    throw "Assembly '$($Package.LibPath)' was not found in package $($Package.Id) $($Package.Version)."
                }
                $Destination = Join-Path $LibraryPath $Package.TargetDll
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($Entry, $Destination, $true)
            }
            finally {
                $Archive.Dispose()
            }
        }
    }
    finally {
        Remove-Item -Path $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    $null = Test-ScubaMsalLibrary -LibraryPath $LibraryPath -Manifest $Manifest -ThrowOnFail
    return $LibraryPath
}

function Remove-ScubaMsalStaleVersion {
    <#
    .SYNOPSIS
        Removes cached MSAL version folders under ~/.scubagear/MSAL other than the pinned version.
        No-op when the $env:ScubaGearMsalPath override is in use.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeepVersion
    )

    if ($env:ScubaGearMsalPath) {
        return
    }

    $HomeDirectory = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    $MsalRoot = Join-Path -Path $HomeDirectory -ChildPath '.scubagear/MSAL'
    if (-not (Test-Path -Path $MsalRoot -PathType Container)) {
        return
    }

    Get-ChildItem -Path $MsalRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne $KeepVersion } |
        ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove stale MSAL version')) {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
}

function Initialize-Msal {
    <#
    .SYNOPSIS
        Ensures the pinned MSAL assemblies are present in the ScubaGear cache and loaded.
        Downloads and verifies them on first use, then loads them dependency-first.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [string]$LibraryPath
    )

    $ExplicitLibraryPath = $PSBoundParameters.ContainsKey('LibraryPath')
    $Manifest = Get-ScubaMsalManifest
    $ExpectedAssemblyVersion = [version]"$($Manifest.Version).0"
    $LoadedMsal = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
        $_.GetName().Name -eq 'Microsoft.Identity.Client'
    } | Select-Object -First 1
    if ($LoadedMsal -and $LoadedMsal.GetName().Version -ne $ExpectedAssemblyVersion) {
        throw "Microsoft.Identity.Client $($LoadedMsal.GetName().Version) is already loaded; ScubaGear requires $ExpectedAssemblyVersion. Start a new PowerShell session."
    }

    if (-not $LibraryPath) {
        $LibraryPath = if ($Global:ScubaGearState.MsalLibraryPath) {
            $Global:ScubaGearState.MsalLibraryPath
        }
        else {
            Get-ScubaMsalLibraryPath -Version $Manifest.Version
        }
    }

    if (-not $Global:ScubaGearState.MsalValidated) {
        if (-not (Test-ScubaMsalLibrary -LibraryPath $LibraryPath -Manifest $Manifest)) {
            Write-Information "MSAL dependencies not found or invalid; downloading to $LibraryPath ..." -InformationAction Continue
            $LibraryPath = Install-ScubaMsalDependency -LibraryPath $LibraryPath
        }
        $null = Test-ScubaMsalLibrary -LibraryPath $LibraryPath -Manifest $Manifest -ThrowOnFail
        $Global:ScubaGearState.MsalValidated = $true
        $Global:ScubaGearState.MsalLibraryPath = $LibraryPath

        # Prune superseded cache versions once the pinned version is confirmed usable.
        if (-not $ExplicitLibraryPath -and -not $env:ScubaGearMsalPath) {
            Remove-ScubaMsalStaleVersion -KeepVersion $Manifest.Version
        }
    }

    # A compiled AssemblyResolve handler provides runtime binding redirects (MSAL 4.89 requests
    # e.g. System.Memory 4.0.1.1 but the package ships 4.0.1.2). It is compiled rather than a
    # PowerShell scriptblock so executing it cannot itself trigger assembly loads and recurse.
    # Scoped to the known MSAL closure so it never affects unrelated resolution.
    if (-not ('ScubaGear.MsalAssemblyResolver' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Reflection;
namespace ScubaGear {
    public static class MsalAssemblyResolver {
        private static HashSet<string> _known;
        private static bool _registered;
        public static void Register(string[] names) {
            _known = new HashSet<string>(names, StringComparer.OrdinalIgnoreCase);
            if (_registered) { return; }
            _registered = true;
            AppDomain.CurrentDomain.AssemblyResolve += delegate(object sender, ResolveEventArgs e) {
                string simple = new AssemblyName(e.Name).Name;
                if (_known == null || !_known.Contains(simple)) { return null; }
                foreach (Assembly a in AppDomain.CurrentDomain.GetAssemblies()) {
                    if (a.GetName().Name == simple) { return a; }
                }
                return null;
            };
        }
    }
}
'@
    }
    [ScubaGear.MsalAssemblyResolver]::Register([string[]]($Manifest.Files | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.File) }))

    # PowerShell 7 (.NET) already ships the System.*/Bcl closure; loading the net462 copies
    # collides with the runtime, so only load the MSAL assemblies there.
    $LoadMsalOnly = $PSVersionTable.PSEdition -eq 'Core'
    foreach ($AssemblyFile in $Manifest.LoadOrder) {
        $AssemblyName = [System.IO.Path]::GetFileNameWithoutExtension($AssemblyFile)
        if ($LoadMsalOnly -and $AssemblyName -notlike 'Microsoft.Identity*') { continue }
        $IsLoaded = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.GetName().Name -eq $AssemblyName
        }
        if (-not $IsLoaded) {
            [void][Reflection.Assembly]::LoadFrom((Join-Path $LibraryPath $AssemblyFile))
        }
    }
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
    if (-not $Global:ScubaGearState.MsalAppCache) {
        $Global:ScubaGearState.MsalAppCache = @{}
    }

    $MaxAttempts = 3
    $Attempt = 0
    while ($Attempt -lt $MaxAttempts) {
        $Attempt++
        try {
            if ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal') {
                $CacheKey = "SP:$AppID|$Authority"
                if (-not $Global:ScubaGearState.MsalAppCache.ContainsKey($CacheKey)) {
                    $Global:ScubaGearState.MsalAppCache[$CacheKey] = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).
                        WithCertificate($Certificate).
                        WithAuthority($Authority).
                        Build()
                }
                $MsalApp = $Global:ScubaGearState.MsalAppCache[$CacheKey]
                $TokenResult = $MsalApp.AcquireTokenForClient([string[]]@($Scope)).ExecuteAsync().GetAwaiter().GetResult()
            }
            else {
                $CacheKey = "PUB:$ClientId|$Authority"
                if (-not $Global:ScubaGearState.MsalAppCache.ContainsKey($CacheKey)) {
                    # Loopback redirect + system browser (no WAM broker)
                    $Global:ScubaGearState.MsalAppCache[$CacheKey] = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId).
                        WithAuthority($Authority).
                        WithRedirectUri('http://localhost').
                        Build()
                }
                $MsalApp = $Global:ScubaGearState.MsalAppCache[$CacheKey]

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
    'Disconnect-ScubaGraph',
    'Get-ScubaGraphContext',
    'Initialize-Msal',
    'Get-MsalAccessToken',
    'Invoke-ScubaGraphRequest',
    'Get-ScubaMsalManifest',
    'Get-ScubaMsalLibraryPath',
    'Test-ScubaMsalLibrary',
    'Install-ScubaMsalDependency',
    'Remove-ScubaMsalStaleVersion'
)
