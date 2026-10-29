using module '..\ScubaConfig\ScubaConfig.psm1'

# Authentication flow and state diagram: /docs/MSAL-INTEGRATION.md

# Session state stored globally so all module import paths share the same instance
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Cross-module singleton required for MSAL session sharing')]
param()
if (-not $Global:ScubaGearState) {
    $Global:ScubaGearState = @{ Session = $null; MsalAppCache = @{}; MsalValidated = $false; MsalLibraryPath = $null; LastRun = $null; }
}

function Connect-GraphHelper {
    <#
    .Description
    This function is used for assisting in connecting to different M365 Environments via the Graph API.
    .PARAMETER Discovery
    Discovers the user's tenant and cloud, then establishes the tenant-specific Graph
    session using the same MSAL application and its token cache.
    .Functionality
    Internal
    .Notes
    The M365Environment default values are pulled from the ScubaConfig schema.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ExplicitEnvironment')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitEnvironment')]
        [ValidateScript({ $_ -cin [ScubaConfig]::GetSupportedEnvironments() })]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Scopes = $null,

        [Parameter(ParameterSetName = 'ExplicitEnvironment')]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $ServicePrincipalParams,

        [Parameter(ParameterSetName = 'ExplicitEnvironment')]
        [string]$TenantId,

        [Parameter(Mandatory = $true, ParameterSetName = 'Discovery')]
        [switch]$Discovery
    )
    $AuthVerbose = @{}
    if ($VerbosePreference -eq 'Continue') { $AuthVerbose.Verbose = $true }
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
        $ClientIdHash = [ScubaConfig]::ScubaDefault('AuthenticationClientIdHashtable')
        $TokenParameters = @{
            Scope = if ($Scopes) { $Scopes } else { @('Organization.Read.All') }
            ClientId = $ClientIdHash.aad
            Tenant = if ($TenantId) { $TenantId } else { 'organizations' }
        }
        if ($Discovery) {
            # Call Get-MsalAccessToken for initial interactive discovery sign-in, which returns the tenant ID and authority host for the user's account.
            $Result = Get-MsalAccessToken @TokenParameters -M365Environment commercial -ForCloudDiscovery -PassThru @AuthVerbose

            $DiscoveredTenantId = [guid]::Empty
            if (-not [guid]::TryParse([string]$Result.TenantId, [ref]$DiscoveredTenantId) -or $DiscoveredTenantId -eq [guid]::Empty) {
                throw 'Interactive cloud discovery did not return a valid tenant ID.'
            }
            $AuthorityHost = switch ($Result.Account.Environment) {
                { $_ -in @('login.microsoftonline.com', 'login.windows.net', 'sts.windows.net') } { 'login.microsoftonline.com' }
                'login.microsoftonline.us' { 'login.microsoftonline.us' }
                default { throw "Interactive cloud discovery returned an unsupported authority: '$($Result.Account.Environment)'." }
            }
            $M365Environment = Get-M365EnvironmentByDomain -TenantDomain $DiscoveredTenantId.ToString() -AuthorityHost $AuthorityHost
            if (($AuthorityHost -eq 'login.microsoftonline.us') -ne ($M365Environment -in @('gcchigh', 'dod'))) {
                throw "Detected environment '$M365Environment' does not match the sign-in authority '$AuthorityHost'."
            }
            $TokenParameters.Tenant = $DiscoveredTenantId.ToString()
        }
        # Keep using the current tenant when a Graph caller requests additional permission scopes.
        # For example, Compare-ScubaGearPermission in ServicePrincipal.psm1 requests Application.Read.All
        # without TenantId. Use the existing session's tenant when the environment matches;
        # an explicit TenantId is already included in TokenParameters above.
        elseif (-not $TenantId -and $Global:ScubaGearState.Session -and
            $Global:ScubaGearState.Session.M365Environment -eq $M365Environment) {
            $TokenParameters.Tenant = $Global:ScubaGearState.Session.TokenParameters.Tenant
        }
    }

    $TokenParameters.M365Environment = $M365Environment
    # Keep the established session until replacement authentication succeeds.
    $Session = @{
        M365Environment = $M365Environment
        GraphEndpoint = switch ($M365Environment) {
            'gcchigh' { 'https://graph.microsoft.us' }
            'dod' { 'https://dod-graph.microsoft.us' }
            default { 'https://graph.microsoft.com' }
        }
        TokenParameters = $TokenParameters
    }
    $TokenResult = Get-MsalAccessToken @TokenParameters -PassThru @AuthVerbose
    $Session.Account = $TokenResult.Account
    $Global:ScubaGearState.Session = $Session
}

function Get-M365EnvironmentByDomain {
    <#
    .SYNOPSIS
        Determines the M365 environment based on the tenant domain.

    .DESCRIPTION
        Determines the M365 environment based on the tenant domain.

    .PARAMETER TenantDomain
        The domain of the tenant for which to determine the environment.

    .EXAMPLE
        $M365Environment = Get-M365EnvironmentByDomain -TenantDomain "contoso.onmicrosoft.com"

    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding(DefaultParameterSetName = 'Interactive')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantDomain,

        [ValidateSet('login.microsoftonline.com', 'login.microsoftonline.us')]
        [string]$AuthorityHost = 'login.microsoftonline.com'
    )

    $MetadataUri = "https://$AuthorityHost/$TenantDomain/.well-known/openid-configuration"

    $Metadata = Invoke-RestMethod -Uri $MetadataUri -Method Get -ErrorAction Stop

    $TenantRegionSubScope = $Metadata.tenant_region_sub_scope

    $M365Environment = switch ($TenantRegionSubScope) {
        "DODCON" { "gcchigh" }
        "GCC"    { "gcc" }
        "DOD"    { "dod" }
        $null    {
            if ([string]::IsNullOrWhiteSpace($Metadata.tenant_region_scope) -or $Metadata.tenant_region_scope -eq 'USGov') {
                throw 'Tenant metadata does not identify a supported M365 environment.'
            }
            "commercial"
        }
        default  {
            throw "Unknown tenant_region_sub_scope value: '$TenantRegionSubScope'"
        }
    }

    return $M365Environment
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

function Get-ScubaGearRunIdentity {
    <#
    .SYNOPSIS
        Returns who (or what app) the current ScubaGear session is signed in as, without calling Microsoft Graph.
    .DESCRIPTION
        Reads the identity from the session ScubaGear already established. It makes no network calls and
        never prompts for a sign-in, so it is safe to call at the end of a run or while handling an error.
        It holds no tokens. Returns nothing when there is no session.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $Session = $Global:ScubaGearState.Session
    if (-not $Session) {
        return
    }

    $TokenParameters = $Session.TokenParameters
    $IsAppOnly = [bool]$TokenParameters.CertificateThumbprint
    $Account = $null
    if (-not $IsAppOnly -and $Session.Account -and $Session.Account.Username) {
        $Account = [string]$Session.Account.Username
    }

    [pscustomobject]@{
        AuthType    = if ($IsAppOnly) { 'AppOnly' } else { 'Delegated' }
        Account     = $Account
        AppId       = if ($IsAppOnly) { $TokenParameters.AppID } else { $TokenParameters.ClientId }
        Tenant      = $TokenParameters.Tenant
        Environment = $Session.M365Environment
    }
}

function Get-ScubaGearContext {
    <#
    .SYNOPSIS
        Shows who (or what app) ScubaGear is currently authenticated to Microsoft Graph as.
    .DESCRIPTION
        ScubaGear no longer depends on the Microsoft.Graph.Authentication module, so
        Get-MgContext is no longer available to identify the signed-in account. This
        cmdlet is the MSAL-based replacement: it resolves the same information
        (account/app, tenant and initial domain, client ID, scopes) by making live
        Microsoft Graph REST calls with the cached MSAL token. It uses GET /v1.0/me
        for delegated/user sign-ins and looks up the client service principal for
        both authentication types. If that lookup fails for the standard Graph
        client, it uses the client's documented display name.

        ScubaGear disconnects when a run finishes, which discards its tokens, so there is no live
        connection to query afterwards. In that case this cmdlet shows the credentials the most
        recent run used, taken from a record that was saved just before disconnecting (the account or
        app, authentication type, tenant and environment, but no tokens). That output has a Status of
        'Disconnected (last run)'. Tenant name, domain and scopes are only available while connected.
    .EXAMPLE
        Get-ScubaGearContext

        Displays the account or app, tenant, and scopes ScubaGear is currently using
        to call Microsoft Graph. Useful for confirming which tenant/user a session is
        connected to before running Invoke-SCuBA against multiple tenants or accounts.
        After a run has finished and disconnected, it shows the credentials that run used.
    .FUNCTIONALITY
        Public
    #>
    [CmdletBinding()]
    param()

    if (-not $Global:ScubaGearState.Session) {
        $LastRun = $Global:ScubaGearState.LastRun
        if ($LastRun) {
            Write-Information "ScubaGear is disconnected. Showing the credentials used by the most recent run (disconnected $($LastRun.DisconnectedAtZulu))." -InformationAction Continue
            return [pscustomobject]@{
                Status             = 'Disconnected (last run)'
                Account            = if ($LastRun.Account) { $LastRun.Account } else { "$($LastRun.AppId) (service principal)" }
                ClientId           = $LastRun.AppId
                AuthType           = $LastRun.AuthType
                Tenant             = $LastRun.Tenant
                Environment        = $LastRun.Environment
                DisconnectedAtZulu = $LastRun.DisconnectedAtZulu
            }
        }
        Write-Warning "ScubaGear is not currently connected to Microsoft Graph, and no earlier run has been recorded in this PowerShell session. Run Invoke-SCuBA first."
        return
    }

    $Session = $Global:ScubaGearState.Session
    $TokenParameters = $Session.TokenParameters
    $IsAppOnly = [bool]$TokenParameters.CertificateThumbprint
    $ClientId = if ($IsAppOnly) { $TokenParameters.AppID } else { $TokenParameters.ClientId }
    $ClientIdHash = [ScubaConfig]::ScubaDefault('AuthenticationClientIdHashtable')

    $Account = "Unknown"
    # Organization.Read.All alone does not grant permission to read service principals.
    $AppDisplayName = if ($ClientId -eq $ClientIdHash.aad) { 'Microsoft Graph Command Line Tools' } else { $null }
    $TenantId = $null
    $TenantName = $null
    $TenantDomain = $null

    try {
        $OrgInfo = Invoke-ScubaGraphRequest -Uri '/v1.0/organization' -Method GET
        $Org = @($OrgInfo.value)[0]
        if ($Org) {
            $TenantId = $Org.id
            $TenantName = $Org.displayName
            $TenantDomain = ($Org.verifiedDomains | Where-Object { $_.isInitial } | Select-Object -First 1).name
        }
    }
    catch {
        Write-Warning "Get-ScubaGearContext: unable to resolve tenant details via Microsoft Graph: $($_.Exception.Message)"
    }

    try {
        $ServicePrincipal = Invoke-ScubaGraphRequest -Uri "/v1.0/servicePrincipals(appId='$ClientId')" -Method GET
        if ($ServicePrincipal.displayName) {
            $AppDisplayName = $ServicePrincipal.displayName
        }
    }
    catch {
        if ($AppDisplayName) {
            Write-Verbose "Get-ScubaGearContext: using the documented client display name because the service principal lookup failed: $($_.Exception.Message)"
        }
        else {
            Write-Warning "Get-ScubaGearContext: unable to resolve service principal display name via Microsoft Graph: $($_.Exception.Message)"
        }
    }

    if ($IsAppOnly) {
        $Account = "$ClientId (service principal)"
    }
    else {
        try {
            $Me = Invoke-ScubaGraphRequest -Uri '/v1.0/me' -Method GET
            if ($Me.userPrincipalName) {
                $Account = $Me.userPrincipalName
            }
            elseif ($Me.mail) {
                $Account = $Me.mail
            }
        }
        catch {
            Write-Warning "Get-ScubaGearContext: unable to resolve signed-in user via Microsoft Graph /v1.0/me: $($_.Exception.Message)"
        }
    }

    [pscustomobject]@{
        Status         = 'Connected'
        Account        = $Account
        AppDisplayName = $AppDisplayName
        ClientId       = $ClientId
        AuthType       = if ($IsAppOnly) { 'AppOnly' } else { 'Delegated' }
        TenantId       = $TenantId
        TenantName     = $TenantName
        TenantDomain   = $TenantDomain
        Scopes         = @($TokenParameters.Scope)
        Environment    = $Session.M365Environment
        GraphEndpoint  = $Session.GraphEndpoint
    }
}

function Disconnect-ScubaGraph {
    <#
    .SYNOPSIS
        Clears the Graph session and MSAL token cache.
    .DESCRIPTION
        Before clearing, it keeps a record of who the session was signed in as so Get-ScubaGearContext can
        still show the credentials the most recent run used. The record holds the account or app, authentication
        type, tenant and environment only, never tokens. The session and token cache are always cleared.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param()

    $Identity = Get-ScubaGearRunIdentity
    if ($Identity) {
        $Identity | Add-Member -NotePropertyName DisconnectedAtZulu `
            -NotePropertyValue ([DateTime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", [cultureinfo]::InvariantCulture))
        $Global:ScubaGearState.LastRun = $Identity
    }

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
        $TokenParameters = $Global:ScubaGearState.Session.TokenParameters.Clone()
        if ($RefreshedToken) {
            $TokenParameters.ForceRefresh = $true
        }
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

    if ($Global:ScubaGearState.MsalValidated) {
        return
    }

    # Do not mark initialization complete if assembly loading or another setup step fails.
    $ErrorActionPreference = 'Stop'
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

    if (-not (Test-ScubaMsalLibrary -LibraryPath $LibraryPath -Manifest $Manifest)) {
        Write-Information "One-time setup: downloading the Microsoft authentication libraries (MSAL) to $LibraryPath. No sign-in is required for this step..." -InformationAction Continue
        # Installation validates the downloaded libraries before returning.
        $LibraryPath = Install-ScubaMsalDependency -LibraryPath $LibraryPath
        Write-Information "Setup complete: the Microsoft authentication libraries (MSAL) were downloaded and verified." -InformationAction Continue
    }

    # Prune superseded cache versions once the pinned version is confirmed usable.
    if (-not $ExplicitLibraryPath -and -not $env:ScubaGearMsalPath) {
        Remove-ScubaMsalStaleVersion -KeepVersion $Manifest.Version
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
    $Global:ScubaGearState.MsalLibraryPath = $LibraryPath
    $Global:ScubaGearState.MsalValidated = $true
}

function New-ScubaMsalPublicClient {
    <#
    .SYNOPSIS
        Builds a public MSAL client using the system browser and a loopback redirect.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$Authority,

        [switch]$ForCloudDiscovery
    )

    [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId).
        WithAuthority($Authority).
        WithRedirectUri('http://localhost').
        WithMultiCloudSupport($ForCloudDiscovery.IsPresent).
        Build()
}

function New-ScubaMsalBrowserRequest {
    <#
    .SYNOPSIS
        Creates a system-browser request, reusing the selected account for browser SSO.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$MsalApp,

        [Parameter(Mandatory = $true)]
        [string[]]$Scope,

        [Parameter(Mandatory = $true)]
        [string]$Tenant,

        [object]$Account
    )

    # The system browser supports WebAuthn/FIDO2/passkeys. MSAL's default prompt
    # forces account selection; retain that only until an account has been selected.
    $Request = $MsalApp.AcquireTokenInteractive($Scope).WithUseEmbeddedWebView($false)
    if ($Account) {
        $Request = $Request.WithAccount($Account).WithPrompt([Microsoft.Identity.Client.Prompt]::NoPrompt)
    }
    if ($Tenant -notin @('common', 'organizations')) {
        $Request = $Request.WithTenantId($Tenant)
    }
    return $Request
}

function Invoke-ScubaMsalRequest {
    <#
    .SYNOPSIS
        Runs an MSAL request so that Ctrl-C and an optional timeout can cancel it.
    .DESCRIPTION
        GetAwaiter().GetResult() blocks the pipeline thread, so Ctrl-C cannot stop a sign-in
        that is waiting on the browser. This waits in short slices instead, which lets PowerShell
        process a stop request, and cancels the MSAL operation (releasing its loopback listener)
        when the wait ends for any reason.
    .PARAMETER Request
        An MSAL request builder exposing ExecuteAsync(CancellationToken).
    .PARAMETER TimeoutSeconds
        Cancels the request after this many seconds. 0 means no timeout.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Request,

        [ValidateRange(0, 3600)]
        [int]$TimeoutSeconds = 0
    )

    $Cts = [System.Threading.CancellationTokenSource]::new()
    try {
        if ($TimeoutSeconds -gt 0) {
            $Cts.CancelAfter([TimeSpan]::FromSeconds($TimeoutSeconds))
        }
        $Task = $Request.ExecuteAsync($Cts.Token)
        while (-not $Task.IsCompleted) {
            [void]$Task.AsyncWaitHandle.WaitOne(250)
        }
        try {
            return $Task.GetAwaiter().GetResult()
        }
        catch [System.OperationCanceledException] {
            if ($TimeoutSeconds -gt 0 -and $Cts.IsCancellationRequested) {
                throw [System.OperationCanceledException]::new(
                    "Sign-in did not complete within $TimeoutSeconds seconds.", $_.Exception)
            }
            throw
        }
    }
    finally {
        $Cts.Cancel()
        $Cts.Dispose()
    }
}

function Get-ScubaMsalFailureChain {
    <#
    .SYNOPSIS
        Returns an exception and each of its inner exceptions, outermost first.
    .DESCRIPTION
        PowerShell wraps SDK exceptions (for example in MethodInvocationException), so the
        MSAL exception that explains a failure is usually an inner exception.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception
    )

    $Current = $Exception
    while ($Current) {
        $Current
        $Current = $Current.InnerException
    }
}

function Test-ScubaMsalRetryableError {
    <#
    .SYNOPSIS
        Determines whether a failed token acquisition is worth attempting again.
    .DESCRIPTION
        Only transient service and network failures are retried. Anything that needs the user
        to act (cancelled or timed-out sign-in, wrong credentials, admin consent, Conditional
        Access, a missing certificate or an invalid app registration) fails immediately, because
        trying again sends the user straight back to the same prompt.
    .PARAMETER Exception
        The exception thrown while acquiring the token.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception
    )

    $Chain = @(Get-ScubaMsalFailureChain -Exception $Exception)

    foreach ($Failure in $Chain) {
        if ($Failure -is [System.OperationCanceledException] -or
            $Failure -is [System.Management.Automation.PipelineStoppedException] -or
            $Failure.PSTypeNames -contains 'Microsoft.Identity.Client.MsalUiRequiredException') {
            return $false
        }
        if ($Failure.PSObject.Properties['ErrorCode'] -and $Failure.ErrorCode -in @('authentication_canceled', 'access_denied')) {
            return $false
        }
    }

    $TransientCodes = @('request_timeout', 'temporarily_unavailable', 'service_not_available', 'network_not_available')
    $TransientHttpStatuses = @(408, 429, 500, 502, 503, 504)
    $TransientWebStatuses = @(
        [System.Net.WebExceptionStatus]::Timeout,
        [System.Net.WebExceptionStatus]::ConnectFailure,
        [System.Net.WebExceptionStatus]::ConnectionClosed,
        [System.Net.WebExceptionStatus]::KeepAliveFailure,
        [System.Net.WebExceptionStatus]::NameResolutionFailure,
        [System.Net.WebExceptionStatus]::ReceiveFailure,
        [System.Net.WebExceptionStatus]::SendFailure
    )

    foreach ($Failure in $Chain) {
        $IsMsal = $Failure.PSTypeNames -contains 'Microsoft.Identity.Client.MsalException'
        if ($IsMsal -and $Failure.PSObject.Properties['ErrorCode'] -and $Failure.ErrorCode -in $TransientCodes) {
            return $true
        }
        if ($IsMsal -and $Failure.PSObject.Properties['StatusCode'] -and [int]$Failure.StatusCode -in $TransientHttpStatuses) {
            return $true
        }
        if ($Failure -is [System.Net.WebException] -and $Failure.Status -in $TransientWebStatuses) {
            return $true
        }
        if ($Failure -is [System.Net.Sockets.SocketException] -or
            $Failure -is [System.IO.IOException] -or
            $Failure.GetType().FullName -eq 'System.Net.Http.HttpRequestException') {
            return $true
        }
    }

    return $false
}

function Get-ScubaMsalFailureHint {
    <#
    .SYNOPSIS
        Explains, in plain language, why a sign-in failure will not be retried.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception
    )

    $Text = (Get-ScubaMsalFailureChain -Exception $Exception | ForEach-Object {
            $Code = if ($_.PSObject.Properties['ErrorCode']) { $_.ErrorCode } else { '' }
            "$Code $($_.Message)"
        }) -join ' '

    switch -Regex ($Text) {
        'AADSTS(65001|90094|650056|650057)|consent_required|admin_consent' {
            return 'Your account is not permitted to grant the required permissions. Ask a Global Administrator to consent, or to run ScubaGear once for this tenant, then try again.'
        }
        'authentication_canceled|did not complete within|OperationCanceled|access_denied' {
            return 'The sign-in was cancelled or timed out. Run ScubaGear again to sign in.'
        }
        'AADSTS(50126|50053|50057|50055|50034)' {
            return 'The sign-in was rejected because of the account credentials or account status. Check the account and try again.'
        }
        'AADSTS(53003|53000|53001|50105|530032)' {
            return 'The sign-in was blocked by a tenant access policy (such as Conditional Access) or because the account is not assigned to the application.'
        }
    }
    return $null
}

function Get-MsalAccessToken {
    <#
    .SYNOPSIS
        Acquires an OAuth2 access token via MSAL using certificate or interactive auth.
        Reuses cached MSAL app instances and attempts silent token acquisition before
        prompting interactively, minimizing the number of browser popups per session.
    .PARAMETER ForCloudDiscovery
        Enables instance-aware sign-in to discover the tenant's cloud from the public common/organizations authority.
        Only supported for first-party Microsoft clients registered with the same ID across clouds.
    .PARAMETER PassThru
        Returns the MSAL authentication result object, including the selected tenant and account cloud,
        instead of only the access token.
    .PARAMETER ForceRefresh
        Bypasses cached access tokens while retaining refresh credentials for silent acquisition.
    .FUNCTIONALITY
        Internal
    .Notes
        The M365Environment default values are pulled from the ScubaConfig schema.
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
        [ValidateScript({ $_ -in [ScubaConfig]::GetSupportedEnvironments() })]
        [string]$M365Environment,

        [Parameter(ParameterSetName = 'Interactive')]
        [switch]$ForCloudDiscovery,

        [switch]$PassThru,

        [switch]$ForceRefresh
    )

    # We call Initialize-Msal here because this function is called directly from the functional test orchestrator.
    Initialize-Msal

    if ($ForCloudDiscovery -and ($Tenant -notin @('common', 'organizations') -or $M365Environment -ne 'commercial')) {
        throw 'Cloud discovery requires the public common or organizations authority.'
    }

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

    # Reuse MSAL application instances via MsalAppCache so their token caches persist between requests.
    # Each delegated client ID has one application and token cache, including Graph discovery,
    # the tenant connection, and later API requests. Disconnect before switching tenants or credentials.

    $MaxAttempts = 3
    # A person must complete the browser sign-in; give up if it is abandoned (for example the tab was closed).
    $InteractiveTimeoutSeconds = 300
    $Attempt = 0
    while ($Attempt -lt $MaxAttempts) {
        $Attempt++
        try {
            # Non-interactive authentication.
            if ($PSCmdlet.ParameterSetName -eq 'ServicePrincipal') {
                $CacheKey = "SP:$AppID"
                if (-not $Global:ScubaGearState.MsalAppCache.ContainsKey($CacheKey)) {
                    $Global:ScubaGearState.MsalAppCache[$CacheKey] = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($AppID).
                        WithCertificate($Certificate).
                        WithAuthority($Authority).
                        Build()
                }
                $MsalApp = $Global:ScubaGearState.MsalAppCache[$CacheKey]
                $ClientRequest = $MsalApp.AcquireTokenForClient([string[]]@($Scope))
                if ($ForceRefresh) {
                    $ClientRequest = $ClientRequest.WithForceRefresh($true)
                }
                $TokenResult = Invoke-ScubaMsalRequest -Request $ClientRequest
            }
            # Interactive authentication.
            else {
                # Reuse the same cached MSAL application object for the same client ID (e.g. Microsoft Graph Command Line Tools).
                $CacheKey = "PUB:$ClientId"
                if (-not $Global:ScubaGearState.MsalAppCache.ContainsKey($CacheKey)) {
                    $Global:ScubaGearState.MsalAppCache[$CacheKey] = New-ScubaMsalPublicClient `
                        -ClientId $ClientId -Authority $Authority -ForCloudDiscovery:$ForCloudDiscovery
                }
                $MsalApp = $Global:ScubaGearState.MsalAppCache[$CacheKey]
                # An IAccount identifies the user, not a client application. Use the
                # scan's Graph account even when this new client lists no accounts;
                # MSAL checks this application's own cache for usable credentials.
                $TokenResult = $null
                $SignInAccount = $Global:ScubaGearState.Session.Account
                # Only an account chosen earlier in this scan may steer the browser. An account that
                # was merely found in the cache has not been confirmed by the user for this sign-in.
                $AccountChosenInSession = [bool]$SignInAccount
                try {
                    # If the session has no selected account, look for one in this MSAL app's cache.
                    # Reusing the session account avoids this lookup and keeps products using the same user.
                    if (-not $SignInAccount) {
                        $Accounts = @($MsalApp.GetAccountsAsync().GetAwaiter().GetResult())
                        if ($Accounts -and $Accounts.Count -gt 0) {
                            $SignInAccount = $Accounts[0]
                        }
                    }
                    # Use the Account object from the Session or MsalApp cache to acquire a token silently.
                    # MSAL returns the underlying cached access token if it is not expired.
                    # If the existing token is expired, MSAL will use the refresh token to get a fresh access token.
                    if ($SignInAccount) {
                        $SilentRequest = $MsalApp.AcquireTokenSilent([string[]]@($Scope), $SignInAccount)
                        if ($ForceRefresh) {
                            $SilentRequest = $SilentRequest.WithForceRefresh($true)
                        }
                        if ($Tenant -notin @('common', 'organizations')) {
                            # The instance-aware discovery client resolves the cloud from
                            # SignInAccount.Environment while this override selects the tenant.
                            $SilentRequest = $SilentRequest.WithTenantId($Tenant)
                        }
                        $TokenResult = Invoke-ScubaMsalRequest -Request $SilentRequest
                        Write-Verbose "Acquired token silently for client '$ClientId' at '$Authority'."
                    }
                    else {
                        Write-Verbose "No cached MSAL account for client '$ClientId' at '$Authority'; interactive sign-in is required."
                    }
                }
                catch {
                    # PowerShell wraps SDK exceptions. Include the underlying MSAL code
                    # so missing credentials can be distinguished from consent/MFA requirements.
                    $SilentFailure = $_.Exception
                    while ($SilentFailure.InnerException -and -not $SilentFailure.PSObject.Properties['ErrorCode']) {
                        $SilentFailure = $SilentFailure.InnerException
                    }
                    $FailureCode = if ($SilentFailure.PSObject.Properties['ErrorCode']) { " [$($SilentFailure.ErrorCode)]" } else { '' }
                    Write-Verbose "Silent token acquisition failed for client '$ClientId' at '$Authority'$($FailureCode): $($SilentFailure.Message)"
                    # Only UI-required MSAL exceptions justify browser fallback, including no_tokens_found.
                    # PSTypeNames includes base types, so derived UI-required exceptions are also recognized.
                    if ($SilentFailure.PSTypeNames -notcontains 'Microsoft.Identity.Client.MsalUiRequiredException') {
                        throw
                    }
                    $TokenResult = $null
                }

                if (-not $TokenResult) {
                    $WaitingNote = "ScubaGear is now waiting for you to finish signing in. If Entra says 'Need admin approval', " +
                        "ask a Global Administrator to approve the permissions, then run ScubaGear again. " +
                        "Press Ctrl+C to cancel; ScubaGear stops waiting after $([math]::Ceiling($InteractiveTimeoutSeconds / 60)) minutes."
                    if ($AccountChosenInSession) {
                        Write-Information "Opening your default browser to reuse your Microsoft 365 sign-in. Additional interaction may be required by Entra. $WaitingNote" -InformationAction Continue
                    }
                    else {
                        Write-Information "Opening your default browser so you can sign in to Microsoft 365. $WaitingNote" -InformationAction Continue
                    }
                    $BrowserAccount = if ($AccountChosenInSession) { $SignInAccount } else { $null }
                    $InteractiveRequest = New-ScubaMsalBrowserRequest -MsalApp $MsalApp `
                        -Scope $Scope -Tenant $Tenant -Account $BrowserAccount
                    $TokenResult = Invoke-ScubaMsalRequest -Request $InteractiveRequest -TimeoutSeconds $InteractiveTimeoutSeconds
                }
            }

            if ($PassThru) {
                return $TokenResult
            }
            return $TokenResult.AccessToken
        }
        catch {
            # Retry only transient failures. A cancelled or timed-out sign-in, bad credentials, a
            # consent the user cannot grant, or Ctrl-C would just show the same prompt again.
            if (-not (Test-ScubaMsalRetryableError -Exception $_.Exception)) {
                $Hint = Get-ScubaMsalFailureHint -Exception $_.Exception
                if ($Hint) {
                    Write-Warning "Token acquisition failed and will not be retried. $Hint"
                }
                throw
            }

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
    'Get-ScubaGearContext',
    'Get-ScubaGearRunIdentity',
    'Get-M365EnvironmentByDomain',
    'Initialize-Msal',
    'Get-MsalAccessToken',
    'Invoke-ScubaGraphRequest',
    'Get-ScubaMsalManifest',
    'Get-ScubaMsalLibraryPath',
    'Test-ScubaMsalLibrary',
    'Install-ScubaMsalDependency',
    'Remove-ScubaMsalStaleVersion'
)
