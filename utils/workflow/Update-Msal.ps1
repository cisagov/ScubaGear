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
    $endpoints = @(
        "https://api.nuget.org/v3-flatcontainer/$idLower/$($Package.Version)/$idLower.$($Package.Version).nupkg"
        "https://www.nuget.org/api/v2/package/$($Package.Id)/$($Package.Version)"
        "https://globalcdn.nuget.org/packages/$idLower.$($Package.Version).nupkg"
    )
    $nupkgPath = Join-Path $WorkRoot "$($Package.Id).$($Package.Version).nupkg"

    $previousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        $failures = @()
        $downloaded = $false
        foreach ($uri in $endpoints) {
            try {
                Invoke-WebRequest -Uri $uri -OutFile $nupkgPath -UseBasicParsing -ErrorAction Stop
                $downloaded = $true
                break
            }
            catch {
                $failures += "$uri -> $($_.Exception.Message)"
            }
        }
        if (-not $downloaded) {
            throw "Unable to download $($Package.Id) $($Package.Version) from any NuGet endpoint:`n$($failures -join "`n")"
        }
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
        [System.Collections.IEnumerable]$Files,

        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$LoadOrder
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
    foreach ($entry in $LoadOrder) {
        [void]$sb.AppendLine("        '$entry'")
    }
    [void]$sb.AppendLine('    )')
    [void]$sb.AppendLine('}')
    $sb.ToString()
}

function Get-MsalNuGetEndpoints {
    param(
        [Parameter(Mandatory = $true)] [string]$Id,
        [Parameter(Mandatory = $true)] [string]$Version
    )
    $idLower = $Id.ToLowerInvariant()
    @(
        "https://api.nuget.org/v3-flatcontainer/$idLower/$Version/$idLower.$Version.nupkg"
        "https://www.nuget.org/api/v2/package/$Id/$Version"
        "https://globalcdn.nuget.org/packages/$idLower.$Version.nupkg"
    )
}

function Save-MsalNupkg {
    param(
        [Parameter(Mandatory = $true)] [string]$Id,
        [Parameter(Mandatory = $true)] [string]$Version,
        [Parameter(Mandatory = $true)] [string]$OutFile
    )
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    catch { Write-Verbose "Unable to adjust TLS protocol: $($_.Exception.Message)" }

    $previous = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        $failures = @()
        foreach ($uri in (Get-MsalNuGetEndpoints -Id $Id -Version $Version)) {
            try {
                Invoke-WebRequest -Uri $uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
                return
            }
            catch { $failures += "$uri -> $($_.Exception.Message)" }
        }
        throw "Unable to download $Id $Version from any NuGet endpoint:`n$($failures -join "`n")"
    }
    finally { $ProgressPreference = $previous }
}

function ConvertTo-MsalNormalizedTfm {
    param([string]$TargetFramework)
    if (-not $TargetFramework) { return @{ Kind = 'any'; Version = [version]'0.0' } }
    $text = "$TargetFramework"
    $number = [regex]::Match($text, '\d+(?:\.\d+)*').Value
    if (-not $number) { $number = '0' }
    if ($number -notmatch '\.' -and $number.Length -ge 2) {
        $parts = @($number[0], $number[1])
        if ($number.Length -ge 3) { $parts += $number.Substring(2) }
        $number = $parts -join '.'
    }
    $segments = @($number.Split('.'))
    while ($segments.Count -lt 2) { $segments += '0' }
    $version = [version](($segments[0..([Math]::Min(2, $segments.Count - 1))]) -join '.')
    if ($text -match 'Standard') { return @{ Kind = 'std'; Version = $version } }
    if ($text -match 'Framework' -or $text -match 'net\d') { return @{ Kind = 'fx'; Version = $version } }
    return @{ Kind = 'other'; Version = $version }
}

function Get-MsalTfmScore {
    # Scores a candidate dependency-group target framework for a net462 consumer (-1 = incompatible).
    param([hashtable]$Normalized)
    switch ($Normalized.Kind) {
        'fx'  { if ($Normalized.Version -le [version]'4.6.2') { return 2000 + [int]($Normalized.Version.Major * 100 + $Normalized.Version.Minor * 10 + $Normalized.Version.Build) } elseif ($Normalized.Version -le [version]'4.8.1') { return 900 + [int]($Normalized.Version.Minor * 10 + $Normalized.Version.Build) } else { return -1 } }
        'std' { if ($Normalized.Version -le [version]'2.0') { return 500 + [int]($Normalized.Version.Major * 10 + $Normalized.Version.Minor) } else { return -1 } }
        'any' { return 0 }
        default { return 0 }
    }
}

function Resolve-MsalClosure {
    <#
        Resolves the full net462 dependency closure for a Microsoft.Identity.Client version by
        walking each package's .nuspec dependency graph, downloading the signed packages directly
        from NuGet, and selecting the best net462-compatible assembly from each. Returns Packages,
        Files, and a dependency-first LoadOrder ready for the manifest. No nuget.exe required.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d+\.\d+\.\d+$')]
        [string]$Version
    )

    if (-not ('System.IO.Compression.ZipFile' -as [type])) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    }

    $libFrameworkOrder = @('net462', 'net461', 'net46', 'net452', 'net451', 'net45', 'net472', 'net471', 'net47', 'net48', 'netstandard2.0', 'netstandard1.6', 'netstandard1.3', 'netstandard1.0')
    $work = Join-Path ([System.IO.Path]::GetTempPath()) "scubagear-msal-closure-$([guid]::NewGuid().ToString('N'))"
    New-Item -Path $work -ItemType Directory -Force | Out-Null
    try {
        $resolved = @{}          # id -> version
        $dependencies = @{}      # id -> @(child ids)
        $queue = New-Object System.Collections.Queue
        $queue.Enqueue(@{ Id = 'Microsoft.Identity.Client'; Version = $Version })

        while ($queue.Count -gt 0) {
            $item = $queue.Dequeue()
            $id = $item.Id
            $ver = $item.Version
            if ($resolved.ContainsKey($id) -and [version]$resolved[$id] -ge [version]$ver) { continue }
            $resolved[$id] = $ver

            $nupkg = Join-Path $work "$id.$ver.nupkg"
            if (-not (Test-Path -Path $nupkg -PathType Leaf)) {
                Save-MsalNupkg -Id $id -Version $ver -OutFile $nupkg
            }

            $archive = [System.IO.Compression.ZipFile]::OpenRead($nupkg)
            try {
                $nuspecEntry = $archive.Entries | Where-Object { $_.FullName -like '*.nuspec' } | Select-Object -First 1
                $reader = New-Object System.IO.StreamReader($nuspecEntry.Open())
                [xml]$nuspec = $reader.ReadToEnd()
                $reader.Close()
            }
            finally { $archive.Dispose() }

            $groups = @($nuspec.package.metadata.dependencies.group)
            $deps = @()
            if ($groups.Count -gt 0 -and $groups[0]) {
                $best = $null
                $bestScore = -999
                foreach ($group in $groups) {
                    $score = Get-MsalTfmScore -Normalized (ConvertTo-MsalNormalizedTfm -TargetFramework $group.targetFramework)
                    if ($score -ge 0 -and $score -ge $bestScore) { $bestScore = $score; $best = $group }
                }
                if ($best) { $deps = @($best.dependency) }
            }
            elseif ($nuspec.package.metadata.dependencies.dependency) {
                $deps = @($nuspec.package.metadata.dependencies.dependency)
            }

            $dependencies[$id] = @()
            foreach ($dep in $deps) {
                if (-not $dep.id) { continue }
                $depVersion = ($dep.version -replace '[\[\]\(\)]', '').Split(',')[0].Trim()
                if (-not $depVersion) { continue }
                $dependencies[$id] += [string]$dep.id
                $queue.Enqueue(@{ Id = [string]$dep.id; Version = $depVersion })
            }
        }

        # Build a record (hashes + Authenticode) for each package that ships a managed assembly
        # matching its own id; framework-reference-only meta packages are skipped.
        $records = @{}
        foreach ($id in $resolved.Keys) {
            $ver = $resolved[$id]
            $nupkg = Join-Path $work "$id.$ver.nupkg"
            $libPath = $null
            $dllPath = Join-Path $work "$id.dll"
            $archive = [System.IO.Compression.ZipFile]::OpenRead($nupkg)
            try {
                $chosen = $null
                $chosenScore = -999
                foreach ($entry in $archive.Entries) {
                    if ($entry.FullName -notmatch "^lib/[^/]+/$([regex]::Escape($id))\.dll$") { continue }
                    $framework = ($entry.FullName -split '/')[1]
                    $index = [array]::IndexOf($libFrameworkOrder, $framework)
                    $score = if ($index -ge 0) { 100 - $index } else { -50 }
                    if ($score -gt $chosenScore) { $chosenScore = $score; $chosen = $entry }
                }
                if ($chosen) {
                    $libPath = $chosen.FullName
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($chosen, $dllPath, $true)
                }
            }
            finally { $archive.Dispose() }

            if (-not $libPath) { continue }

            $null = Assert-MsalAuthenticodeSignature -FilePath $dllPath -SignerOrganization 'O=Microsoft Corporation'
            $records[$id] = [pscustomobject]@{
                Id = $id
                Version = $ver
                LibPath = $libPath
                TargetDll = "$id.dll"
                NupkgSha256 = (Get-FileHash -Path $nupkg -Algorithm SHA256).Hash
                DllSha256 = (Get-FileHash -Path $dllPath -Algorithm SHA256).Hash
                AssemblyVersion = [Reflection.AssemblyName]::GetAssemblyName($dllPath).Version.ToString()
            }
        }

        if (-not $records.ContainsKey('Microsoft.Identity.Client')) {
            throw 'Could not resolve a managed Microsoft.Identity.Client assembly.'
        }

        # Dependency-first (post-order DFS) load order across the managed packages.
        $order = New-Object System.Collections.Generic.List[string]
        $state = @{}
        foreach ($root in $records.Keys) {
            if ($state[$root]) { continue }
            $stack = New-Object System.Collections.Stack
            $stack.Push($root)
            while ($stack.Count -gt 0) {
                $node = $stack.Peek()
                if (-not $state[$node]) { $state[$node] = 'visiting' }
                $next = $null
                foreach ($child in $dependencies[$node]) {
                    if ($records.ContainsKey($child) -and $state[$child] -ne 'done') { $next = $child; break }
                }
                if ($next -and $state[$next] -ne 'visiting') {
                    $stack.Push($next)
                }
                else {
                    [void]$stack.Pop()
                    if ($state[$node] -ne 'done') { $state[$node] = 'done'; $order.Add($node) }
                }
            }
        }

        $packages = foreach ($id in $order) {
            $record = $records[$id]
            [ordered]@{ Id = $record.Id; Version = $record.Version; Sha256 = $record.NupkgSha256; LibPath = $record.LibPath; TargetDll = $record.TargetDll }
        }
        $files = foreach ($id in $order) {
            $record = $records[$id]
            [ordered]@{ File = $record.TargetDll; Sha256 = $record.DllSha256; AssemblyVersion = $record.AssemblyVersion }
        }
        $loadOrder = foreach ($id in $order) { $records[$id].TargetDll }

        [pscustomobject]@{
            Packages = @($packages)
            Files = @($files)
            LoadOrder = @($loadOrder)
        }
    }
    finally {
        Remove-Item -Path $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Update-MsalDependencyVersion {
    <#
        Resolves the full net462 dependency closure for a new MSAL version, computes hashes and
        assembly versions, and rewrites the $MsalDependency block in RequiredVersions.ps1.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d+\.\d+\.\d+$')]
        [string]$Version
    )

    $availableVersions = @(Get-AvailableMsalVersions)
    if ($Version -notin $availableVersions) {
        throw "MSAL $Version is not a stable published version."
    }

    $closure = Resolve-MsalClosure -Version $Version
    if (-not ($closure.Packages | Where-Object { $_.Id -eq 'Microsoft.Identity.Client' -and $_.Version -eq $Version })) {
        throw 'The resolved closure did not include the requested Microsoft.Identity.Client version.'
    }

    $manifestText = Format-MsalManifestBlock -Version $Version -Packages $closure.Packages -Files $closure.Files -LoadOrder $closure.LoadOrder
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
