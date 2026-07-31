#Requires -Version 5.1

$script:MsalPackageIds = @(
    'Microsoft.Identity.Client',
    'Microsoft.Identity.Client.Broker'
)

function Get-MsalDependencyPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $moduleRoot = Join-Path $RepoRoot 'PowerShell/ScubaGear'
    @{
        ModuleRoot = $moduleRoot
        PackagesConfig = Join-Path $moduleRoot 'dependencies/packages.config'
        LockFile = Join-Path $moduleRoot 'dependencies/msal-lock.json'
        LibRoot = Join-Path $moduleRoot 'lib/net462'
        RuntimeRoot = Join-Path $moduleRoot 'runtimes'
    }
}

function Get-CurrentMsalVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackagesConfig
    )

    [xml]$config = Get-Content -Path $PackagesConfig -Raw
    $versions = @($config.packages.package |
        Where-Object { $_.id -in $script:MsalPackageIds } |
        ForEach-Object { $_.version } |
        Select-Object -Unique)

    if ($versions.Count -ne 1) {
        throw 'Microsoft.Identity.Client and Microsoft.Identity.Client.Broker must use the same version.'
    }

    $versions[0]
}

function Get-AvailableMsalVersions {
    [CmdletBinding()]
    param()

    $versionSets = foreach ($packageId in $script:MsalPackageIds) {
        $uri = "https://api.nuget.org/v3-flatcontainer/$($packageId.ToLowerInvariant())/index.json"
        $response = Invoke-RestMethod -Method Get -Uri $uri -ErrorAction Stop
        ,@($response.versions | Where-Object { $_ -match '^\d+\.\d+\.\d+$' })
    }

    $sharedVersions = @($versionSets[0] | Where-Object { $_ -in $versionSets[1] })
    $sharedVersions | Sort-Object { [version]$_ }
}

function Confirm-MsalUpdateRequirements {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $paths = Get-MsalDependencyPaths -RepoRoot $RepoRoot
    $currentVersion = Get-CurrentMsalVersion -PackagesConfig $paths.PackagesConfig

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
            Summary = 'No stable version is available for both MSAL packages.'
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

function Update-MsalDependencyVersion {
    [CmdletBinding()]
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
        throw "MSAL $Version is not a stable version shared by both required packages."
    }

    $paths = Get-MsalDependencyPaths -RepoRoot $RepoRoot
    $originalConfig = Get-Content -Path $paths.PackagesConfig -Raw
    $resolveRoot = Join-Path ([System.IO.Path]::GetTempPath()) "scubagear-msal-update-$([guid]::NewGuid().ToString('N'))"

    try {
        New-Item -Path $resolveRoot -ItemType Directory -Force | Out-Null
        & $NuGetPath install Microsoft.Identity.Client.Broker -Version $Version `
            -OutputDirectory $resolveRoot -NonInteractive -DirectDownload
        if ($LASTEXITCODE -ne 0) {
            throw "NuGet dependency resolution failed with exit code $LASTEXITCODE."
        }

        $resolvedPackages = foreach ($nuspec in Get-ChildItem -Path $resolveRoot -Recurse -Filter '*.nuspec' -File) {
            [xml]$metadata = Get-Content -Path $nuspec.FullName -Raw
            [pscustomobject]@{
                Id = [string]$metadata.package.metadata.id
                Version = [string]$metadata.package.metadata.version
            }
        }
        $resolvedPackages = @($resolvedPackages |
            Where-Object { $_.Id -and $_.Version } |
            Sort-Object Id -Unique)
        if (($resolvedPackages | Where-Object Id -eq 'Microsoft.Identity.Client').Version -ne $Version -or
            ($resolvedPackages | Where-Object Id -eq 'Microsoft.Identity.Client.Broker').Version -ne $Version) {
            throw 'NuGet did not resolve aligned Microsoft.Identity.Client and Broker versions.'
        }

        $document = New-Object System.Xml.XmlDocument
        $declaration = $document.CreateXmlDeclaration('1.0', 'utf-8', $null)
        [void]$document.AppendChild($declaration)
        $packagesElement = $document.CreateElement('packages')
        [void]$document.AppendChild($packagesElement)
        foreach ($package in $resolvedPackages) {
            $packageElement = $document.CreateElement('package')
            $packageElement.SetAttribute('id', $package.Id)
            $packageElement.SetAttribute('version', $package.Version)
            $packageElement.SetAttribute('targetFramework', 'net462')
            [void]$packagesElement.AppendChild($packageElement)
        }
        $settings = New-Object System.Xml.XmlWriterSettings
        $settings.Indent = $true
        $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
        $writer = [System.Xml.XmlWriter]::Create($paths.PackagesConfig, $settings)
        try {
            $document.Save($writer)
        }
        finally {
            $writer.Dispose()
        }

        Restore-MsalDependencies -RepoRoot $RepoRoot -NuGetPath $NuGetPath
    }
    catch {
        [System.IO.File]::WriteAllText($paths.PackagesConfig, $originalConfig, (New-Object System.Text.UTF8Encoding($false)))
        throw
    }
    finally {
        Remove-Item -Path $resolveRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Assert-MsalAuthenticodeSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $signature = Get-AuthenticodeSignature -FilePath $File.FullName
    if ($signature.Status -ne 'Valid') {
        throw "Invalid Authenticode signature for $($File.FullName): $($signature.Status)"
    }
    if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Subject -notmatch '(^|,\s*)O=Microsoft Corporation(,|$)') {
        throw "Unexpected Authenticode signer for $($File.FullName)."
    }

    $signature
}

function Restore-MsalDependencies {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [string]$NuGetPath = 'nuget.exe'
    )

    $paths = Get-MsalDependencyPaths -RepoRoot $RepoRoot
    $restoreRoot = Join-Path ([System.IO.Path]::GetTempPath()) "scubagear-msal-$([guid]::NewGuid().ToString('N'))"

    try {
        New-Item -Path $restoreRoot -ItemType Directory -Force | Out-Null
        & $NuGetPath restore $paths.PackagesConfig -PackagesDirectory $restoreRoot -NonInteractive -DirectDownload
        if ($LASTEXITCODE -ne 0) {
            throw "NuGet restore failed with exit code $LASTEXITCODE."
        }

        $packages = @(Get-ChildItem -Path $restoreRoot -Recurse -Filter '*.nupkg' -File)
        foreach ($package in $packages) {
            & $NuGetPath verify -Signatures $package.FullName
            if ($LASTEXITCODE -ne 0) {
                throw "NuGet package signature verification failed for $($package.Name) with exit code $LASTEXITCODE."
            }
        }

        [xml]$packageConfig = Get-Content -Path $paths.PackagesConfig -Raw
        $packageDirectories = @{}
        foreach ($packageEntry in $packageConfig.packages.package) {
            $packageDirectories[$packageEntry.id] = "$($packageEntry.id).$($packageEntry.version)"
        }
        $managedFiles = @(
            @{ PackageId = 'Microsoft.Identity.Client'; Source = 'lib/net462/Microsoft.Identity.Client.dll' },
            @{ PackageId = 'Microsoft.Identity.Client.Broker'; Source = 'lib/net462/Microsoft.Identity.Client.Broker.dll' },
            @{ PackageId = 'Microsoft.Identity.Client.NativeInterop'; Source = 'lib/net461/Microsoft.Identity.Client.NativeInterop.dll' },
            @{ PackageId = 'Microsoft.IdentityModel.Abstractions'; Source = 'lib/net462/Microsoft.IdentityModel.Abstractions.dll' },
            @{ PackageId = 'System.Diagnostics.DiagnosticSource'; Source = 'lib/net461/System.Diagnostics.DiagnosticSource.dll' },
            @{ PackageId = 'System.Runtime.CompilerServices.Unsafe'; Source = 'lib/net461/System.Runtime.CompilerServices.Unsafe.dll' },
            @{ PackageId = 'System.ValueTuple'; Source = 'lib/net47/System.ValueTuple.dll' }
        )
        $nativeFiles = @(
            @{ PackageId = 'Microsoft.Identity.Client.NativeInterop'; Source = 'runtimes/win-x64/native/msalruntime.dll'; Destination = 'win-x64/native/msalruntime.dll' },
            @{ PackageId = 'Microsoft.Identity.Client.NativeInterop'; Source = 'runtimes/win-x86/native/msalruntime_x86.dll'; Destination = 'win-x86/native/msalruntime_x86.dll' },
            @{ PackageId = 'Microsoft.Identity.Client.NativeInterop'; Source = 'runtimes/win-arm64/native/msalruntime_arm64.dll'; Destination = 'win-arm64/native/msalruntime_arm64.dll' }
        )

        if ($PSCmdlet.ShouldProcess($paths.ModuleRoot, 'Replace bundled MSAL dependency files')) {
            Remove-Item -Path $paths.LibRoot, $paths.RuntimeRoot -Recurse -Force -ErrorAction SilentlyContinue
            New-Item -Path $paths.LibRoot -ItemType Directory -Force | Out-Null

            foreach ($entry in $managedFiles) {
                $source = Join-Path (Join-Path $restoreRoot $packageDirectories[$entry.PackageId]) $entry.Source
                if (-not (Test-Path -Path $source -PathType Leaf)) {
                    throw "Expected restored dependency was not found: $source"
                }
                Copy-Item -Path $source -Destination $paths.LibRoot -Force
            }
            foreach ($entry in $nativeFiles) {
                $source = Join-Path (Join-Path $restoreRoot $packageDirectories[$entry.PackageId]) $entry.Source
                $destination = Join-Path $paths.RuntimeRoot $entry.Destination
                New-Item -Path (Split-Path $destination) -ItemType Directory -Force | Out-Null
                Copy-Item -Path $source -Destination $destination -Force
            }
        }

        $binaryFiles = @(
            Get-ChildItem -Path $paths.LibRoot, $paths.RuntimeRoot -Recurse -File |
                Where-Object { $_.Extension -in '.dll', '.exe' }
        )
        $fileRecords = foreach ($file in $binaryFiles) {
            $signature = Assert-MsalAuthenticodeSignature -File $file
            $assemblyVersion = $null
            try {
                $assemblyVersion = [Reflection.AssemblyName]::GetAssemblyName($file.FullName).Version.ToString()
            }
            catch {
                # Native binaries do not have a managed assembly identity.
            }
            [ordered]@{
                path = $file.FullName.Substring($paths.ModuleRoot.Length + 1).Replace('\', '/')
                sha256 = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
                assemblyVersion = $assemblyVersion
                signerSubject = $signature.SignerCertificate.Subject
            }
        }

        $packageRecords = foreach ($package in $packages | Sort-Object Name) {
            [ordered]@{
                file = $package.Name
                sha256 = (Get-FileHash -Path $package.FullName -Algorithm SHA256).Hash
            }
        }
        $lock = [ordered]@{
            msalVersion = Get-CurrentMsalVersion -PackagesConfig $paths.PackagesConfig
            teamsCompatibilityVersion = '7.9.0'
            packages = @($packageRecords)
            files = @($fileRecords | Sort-Object path)
        }
        $lock | ConvertTo-Json -Depth 6 | Set-Content -Path $paths.LockFile -Encoding UTF8
        $lock
    }
    finally {
        Remove-Item -Path $restoreRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Test-MsalDependencyIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $paths = Get-MsalDependencyPaths -RepoRoot $RepoRoot
    if (-not (Test-Path -Path $paths.LockFile -PathType Leaf)) {
        throw "MSAL lock file was not found: $($paths.LockFile)"
    }

    $lock = Get-Content -Path $paths.LockFile -Raw | ConvertFrom-Json
    $expectedPaths = @($lock.files.path | Sort-Object)
    $actualFiles = @(
        Get-ChildItem -Path $paths.LibRoot, $paths.RuntimeRoot -Recurse -File -ErrorAction Stop |
            Where-Object { $_.Extension -in '.dll', '.exe' }
    )
    $actualPaths = @($actualFiles | ForEach-Object {
        $_.FullName.Substring($paths.ModuleRoot.Length + 1).Replace('\', '/')
    } | Sort-Object)

    if (Compare-Object -ReferenceObject $expectedPaths -DifferenceObject $actualPaths) {
        throw 'The bundled MSAL file set does not match msal-lock.json.'
    }

    foreach ($record in $lock.files) {
        $file = Get-Item -Path (Join-Path $paths.ModuleRoot $record.path)
        $actualHash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        if ($actualHash -ne $record.sha256) {
            throw "SHA-256 mismatch for $($record.path)."
        }
        $signature = Assert-MsalAuthenticodeSignature -File $file
        if ($signature.SignerCertificate.Subject -ne $record.signerSubject) {
            throw "Authenticode signer drift detected for $($record.path)."
        }
    }

    $msalVersions = @($lock.files |
        Where-Object { $_.path -match 'Microsoft\.Identity\.Client(\.Broker)?\.dll$' } |
        ForEach-Object { $_.assemblyVersion } |
        Select-Object -Unique)
    if ($msalVersions.Count -ne 1 -or $msalVersions[0] -ne "$($lock.msalVersion).0") {
        throw 'MSAL and Broker assembly versions are not aligned with the package lock.'
    }

    [pscustomobject]@{
        State = 'Valid'
        MsalVersion = $lock.msalVersion
        FileCount = $lock.files.Count
    }
}
