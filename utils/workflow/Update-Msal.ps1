#Requires -Version 5.1

# Tooling used by CI to validate and bump the pinned MSAL dependency closure that ScubaGear
# downloads at runtime. The pin lives in PowerShell/ScubaGear/RequiredVersions.ps1 ($MsalDependency);
# the assemblies are no longer bundled in the repo.

function Get-MsalManifestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $resolvedRepoRoot = (Resolve-Path -Path $RepoRoot -ErrorAction Stop).Path
    Join-Path $resolvedRepoRoot 'PowerShell/ScubaGear/RequiredVersions.ps1'
}

function Get-MsalManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $ManifestPath = Get-MsalManifestPath -RepoRoot $RepoRoot
    if (-not (Test-Path -Path $ManifestPath -PathType Leaf)) {
        throw "RequiredVersions.ps1 was not found: $ManifestPath"
    }

    $MsalDependency = $null
    . $ManifestPath
    if (-not $MsalDependency) {
        throw 'The MSAL dependency manifest ($MsalDependency) is not defined in RequiredVersions.ps1.'
    }
    $MsalDependency
}

function Get-CurrentMsalVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    (Get-MsalManifest -RepoRoot $RepoRoot).Version
}

function Get-AvailableMsalVersions {
    [CmdletBinding()]
    param()

    $uri = "https://api.nuget.org/v3-flatcontainer/microsoft.identity.client/index.json"
    $response = Invoke-RestMethod -Method Get -Uri $uri -ErrorAction Stop
    $stableVersions = @($response.versions | Where-Object { $_ -match '^\d+\.\d+\.\d+$' })
    $stableVersions | Sort-Object { [version]$_ }
}

function Confirm-MsalUpdateRequirements {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $currentVersion = Get-CurrentMsalVersion -RepoRoot $RepoRoot

    try {
        $availableVersions = @(Get-AvailableMsalVersions)
    }
    catch {
        return @{
            State = 'QueryFailed'
            CurrentVersion = $currentVersion
            LatestVersion = $null
            UpdateRequired = $false
            Summary = $_.Exception.Message
        }
    }

    if ($availableVersions.Count -eq 0) {
        return @{
            State = 'VersionSkew'
            CurrentVersion = $currentVersion
            LatestVersion = $null
            UpdateRequired = $false
            Summary = 'No stable Microsoft.Identity.Client version is available.'
        }
    }

    $latestVersion = $availableVersions[-1]
    $updateRequired = [version]$latestVersion -gt [version]$currentVersion
    @{
        State = if ($updateRequired) { 'UpdateAvailable' } else { 'UpToDate' }
        CurrentVersion = $currentVersion
        LatestVersion = $latestVersion
        UpdateRequired = $updateRequired
        Summary = if ($updateRequired) {
            "MSAL $latestVersion is available. Compatibility approval is required before updating from $currentVersion."
        }
        else {
            "MSAL $currentVersion is up to date."
        }
    }
}

function Assert-MsalAuthenticodeSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$SignerOrganization
    )

    $signature = Get-AuthenticodeSignature -FilePath $FilePath
    if ($signature.Status -ne 'Valid') {
        throw "Invalid Authenticode signature for ${FilePath}: $($signature.Status)"
    }
    if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Subject -notmatch [regex]::Escape($SignerOrganization)) {
        throw "Unexpected Authenticode signer for ${FilePath}."
    }

    $signature
}

function Get-MsalPackagePayload {
    <#
        Downloads a pinned package directly from the NuGet flat container, verifies its SHA-256,
        and extracts the manifest-declared assembly to a destination file. No nuget.exe required.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Package,

        [Parameter(Mandatory = $true)]
        [string]$WorkRoot,

        [Parameter(Mandatory = $true)]
        [string]$DestinationDirectory
    )

    if (-not ('System.IO.Compression.ZipFile' -as [type])) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    catch {
        Write-Verbose "Unable to adjust TLS protocol: $($_.Exception.Message)"
    }

    $idLower = $Package.Id.ToLowerInvariant()
    $uri = "https://api.nuget.org/v3-flatcontainer/$idLower/$($Package.Version)/$idLower.$($Package.Version).nupkg"
    $nupkgPath = Join-Path $WorkRoot "$($Package.Id).$($Package.Version).nupkg"

    $previousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $uri -OutFile $nupkgPath -UseBasicParsing -ErrorAction Stop
    }
    finally {
        $ProgressPreference = $previousProgress
    }

    $nupkgHash = (Get-FileHash -Path $nupkgPath -Algorithm SHA256).Hash
    if ($nupkgHash -ne $Package.Sha256) {
        throw "MSAL package failed SHA-256 validation: $($Package.Id) $($Package.Version)"
    }

    $destination = Join-Path $DestinationDirectory $Package.TargetDll
    $archive = [System.IO.Compression.ZipFile]::OpenRead($nupkgPath)
    try {
        $entry = $archive.Entries | Where-Object { $_.FullName -eq $Package.LibPath } | Select-Object -First 1
        if (-not $entry) {
            throw "Assembly '$($Package.LibPath)' was not found in package $($Package.Id) $($Package.Version)."
        }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
    }
    finally {
        $archive.Dispose()
    }

    [pscustomobject]@{
        NupkgPath = $nupkgPath
        NupkgSha256 = $nupkgHash
        AssemblyPath = $destination
    }
}

function Test-MsalDependencyIntegrity {
    <#
        Validates that the pinned manifest is internally consistent and reproducible: every pinned
        package downloads with the expected SHA-256, extracts to the expected assembly, and that
        assembly matches the expected SHA-256, managed version, and Microsoft Authenticode signer.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $manifest = Get-MsalManifest -RepoRoot $RepoRoot
    $signerOrg = $manifest.SignerOrganization

    $filesByName = @{}
    foreach ($file in $manifest.Files) {
        $filesByName[$file.File] = $file
    }

    $workRoot = Join-Path ([System.IO.Path]::GetTempPath()) "scubagear-msal-verify-$([guid]::NewGuid().ToString('N'))"
    $extractRoot = Join-Path $workRoot 'lib'
    New-Item -Path $extractRoot -ItemType Directory -Force | Out-Null
    try {
        foreach ($package in $manifest.Packages) {
            $payload = Get-MsalPackagePayload -Package $package -WorkRoot $workRoot -DestinationDirectory $extractRoot

            $expected = $filesByName[$package.TargetDll]
            if (-not $expected) {
                throw "Manifest is missing a Files entry for $($package.TargetDll)."
            }

            $actualHash = (Get-FileHash -Path $payload.AssemblyPath -Algorithm SHA256).Hash
            if ($actualHash -ne $expected.Sha256) {
                throw "SHA-256 mismatch for $($package.TargetDll)."
            }

            $actualVersion = [Reflection.AssemblyName]::GetAssemblyName($payload.AssemblyPath).Version.ToString()
            if ($actualVersion -ne $expected.AssemblyVersion) {
                throw "Assembly version mismatch for $($package.TargetDll): expected $($expected.AssemblyVersion), found $actualVersion."
            }

            $null = Assert-MsalAuthenticodeSignature -FilePath $payload.AssemblyPath -SignerOrganization $signerOrg
        }

        $manifestMsal = @($manifest.Files | Where-Object { $_.File -eq 'Microsoft.Identity.Client.dll' } | ForEach-Object { $_.AssemblyVersion })
        if ($manifestMsal.Count -ne 1 -or $manifestMsal[0] -ne "$($manifest.Version).0") {
            throw 'MSAL assembly version is not aligned with the manifest version.'
        }
    }
    finally {
        Remove-Item -Path $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    [pscustomobject]@{
        State = 'Valid'
        MsalVersion = $manifest.Version
        FileCount = $manifest.Files.Count
    }
}

function Format-MsalManifestBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Packages,

        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Files
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# Pinned MSAL (Microsoft.Identity.Client) dependency closure. These signed assemblies are not')
    [void]$sb.AppendLine('# bundled in the repo; they are downloaded on demand from NuGet into')
    [void]$sb.AppendLine('# ~/.scubagear/MSAL/<Version>/net462 and verified against the hashes and signer below.')
    [void]$sb.AppendLine('# The Update-Msal workflow rewrites this block when a new version is approved.')
    [void]$sb.AppendLine("[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MsalDependency')]")
    [void]$sb.AppendLine('$MsalDependency = @{')
    [void]$sb.AppendLine("    Version = '$Version'")
    [void]$sb.AppendLine("    SignerOrganization = 'O=Microsoft Corporation'")
    [void]$sb.AppendLine('    Packages = @(')
    foreach ($p in $Packages) {
        [void]$sb.AppendLine("        @{ Id = '$($p.Id)'; Version = '$($p.Version)'; Sha256 = '$($p.Sha256)'; LibPath = '$($p.LibPath)'; TargetDll = '$($p.TargetDll)' }")
    }
    [void]$sb.AppendLine('    )')
    [void]$sb.AppendLine('    Files = @(')
    foreach ($f in $Files) {
        [void]$sb.AppendLine("        @{ File = '$($f.File)'; Sha256 = '$($f.Sha256)'; AssemblyVersion = '$($f.AssemblyVersion)' }")
    }
    [void]$sb.AppendLine('    )')
    [void]$sb.AppendLine('    LoadOrder = @(')
    [void]$sb.AppendLine("        'System.Runtime.CompilerServices.Unsafe.dll'")
    [void]$sb.AppendLine("        'System.Diagnostics.DiagnosticSource.dll'")
    [void]$sb.AppendLine("        'Microsoft.IdentityModel.Abstractions.dll'")
    [void]$sb.AppendLine("        'Microsoft.Identity.Client.dll'")
    [void]$sb.AppendLine('    )')
    [void]$sb.AppendLine('}')
    $sb.ToString()
}

function Update-MsalDependencyVersion {
    <#
        Resolves the dependency closure for a new MSAL version with nuget.exe, computes the hashes
        and assembly versions, and rewrites the $MsalDependency block in RequiredVersions.ps1.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d+\.\d+\.\d+$')]
        [string]$Version,

        [string]$NuGetPath = 'nuget.exe'
    )

    $availableVersions = @(Get-AvailableMsalVersions)
    if ($Version -notin $availableVersions) {
        throw "MSAL $Version is not a stable published version."
    }

    # Same net-target preference the previous bundling logic used.
    $libPreference = @{
        'Microsoft.Identity.Client'              = @('lib/net462')
        'Microsoft.IdentityModel.Abstractions'   = @('lib/net462', 'lib/netstandard2.0')
        'System.Diagnostics.DiagnosticSource'    = @('lib/net461', 'lib/netstandard2.0')
        'System.Runtime.CompilerServices.Unsafe' = @('lib/net461', 'lib/netstandard2.0')
        'System.ValueTuple'                      = @('lib/net47', 'lib/netstandard2.0')
    }

    $resolveRoot = Join-Path ([System.IO.Path]::GetTempPath()) "scubagear-msal-resolve-$([guid]::NewGuid().ToString('N'))"
    New-Item -Path $resolveRoot -ItemType Directory -Force | Out-Null
    try {
        & $NuGetPath install Microsoft.Identity.Client -Version $Version -OutputDirectory $resolveRoot -NonInteractive -DirectDownload
        if ($LASTEXITCODE -ne 0) {
            throw "NuGet dependency resolution failed with exit code $LASTEXITCODE."
        }

        $packages = @()
        $files = @()
        foreach ($nuspec in Get-ChildItem -Path $resolveRoot -Recurse -Filter '*.nuspec' -File) {
            [xml]$metadata = Get-Content -Path $nuspec.FullName -Raw
            $id = [string]$metadata.package.metadata.id
            $ver = [string]$metadata.package.metadata.version
            if (-not $libPreference.ContainsKey($id)) {
                continue
            }

            $packageDir = $nuspec.Directory.FullName
            $libPath = $null
            $assemblyPath = $null
            foreach ($candidate in $libPreference[$id]) {
                $candidatePath = Join-Path $packageDir "$candidate/$id.dll"
                if (Test-Path -Path $candidatePath -PathType Leaf) {
                    $libPath = "$candidate/$id.dll"
                    $assemblyPath = $candidatePath
                    break
                }
            }
            if (-not $assemblyPath) {
                throw "Could not locate a compatible assembly for $id $ver."
            }

            $nupkgPath = Join-Path $packageDir "$id.$ver.nupkg"
            if (-not (Test-Path -Path $nupkgPath -PathType Leaf)) {
                throw "Downloaded package archive was not found for $id $ver."
            }

            & $NuGetPath verify -Signatures $nupkgPath
            if ($LASTEXITCODE -ne 0) {
                throw "NuGet signature verification failed for $id $ver."
            }
            $null = Assert-MsalAuthenticodeSignature -FilePath $assemblyPath -SignerOrganization 'O=Microsoft Corporation'

            $packages += [ordered]@{
                Id = $id
                Version = $ver
                Sha256 = (Get-FileHash -Path $nupkgPath -Algorithm SHA256).Hash
                LibPath = $libPath
                TargetDll = "$id.dll"
            }
            $files += [ordered]@{
                File = "$id.dll"
                Sha256 = (Get-FileHash -Path $assemblyPath -Algorithm SHA256).Hash
                AssemblyVersion = [Reflection.AssemblyName]::GetAssemblyName($assemblyPath).Version.ToString()
            }
        }

        if (-not ($packages | Where-Object { $_.Id -eq 'Microsoft.Identity.Client' -and $_.Version -eq $Version })) {
            throw 'NuGet did not resolve the requested Microsoft.Identity.Client version.'
        }

        $manifestText = Format-MsalManifestBlock -Version $Version -Packages $packages -Files $files
        $manifestPath = Get-MsalManifestPath -RepoRoot $RepoRoot
        if ($PSCmdlet.ShouldProcess($manifestPath, 'Rewrite $MsalDependency manifest')) {
            $content = Get-Content -Path $manifestPath -Raw
            $pattern = '(?ms)^# Pinned MSAL .*?\r?\n\$MsalDependency = @\{.*?\r?\n\}\r?\n?'
            if ($content -notmatch $pattern) {
                throw 'Could not locate the $MsalDependency block in RequiredVersions.ps1.'
            }
            # Escape $ so the replacement text is treated literally by [regex]::Replace.
            $replacement = $manifestText -replace '\$', '$$$$'
            $updated = [regex]::Replace($content, $pattern, $replacement)
            Set-Content -Path $manifestPath -Value $updated -Encoding UTF8 -NoNewline
        }

        Test-MsalDependencyIntegrity -RepoRoot $RepoRoot
    }
    finally {
        Remove-Item -Path $resolveRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
