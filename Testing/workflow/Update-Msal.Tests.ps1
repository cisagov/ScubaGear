BeforeAll {
    . (Join-Path $PSScriptRoot '../../utils/workflow/Update-Msal.ps1')

    function New-TestRequiredVersions {
        param(
            [string]$Root,
            [string]$MsalVersion = '4.82.0'
        )

        $moduleRoot = Join-Path $Root 'PowerShell/ScubaGear'
        New-Item -Path $moduleRoot -ItemType Directory -Force | Out-Null
        @"
`$ModuleList = @()

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MsalDependency')]
`$MsalDependency = @{
    Version = '$MsalVersion'
    SignerOrganization = 'O=Microsoft Corporation'
    Packages = @(
        @{ Id = 'Microsoft.Identity.Client'; Version = '$MsalVersion'; Sha256 = 'AAAA'; LibPath = 'lib/net462/Microsoft.Identity.Client.dll'; TargetDll = 'Microsoft.Identity.Client.dll' }
    )
    Files = @(
        @{ File = 'Microsoft.Identity.Client.dll'; Sha256 = 'BBBB'; AssemblyVersion = '$MsalVersion.0' }
    )
    LoadOrder = @(
        'Microsoft.Identity.Client.dll'
    )
}
"@ | Set-Content -Path (Join-Path $moduleRoot 'RequiredVersions.ps1')
    }
}

Describe 'MSAL dependency updates' {
    BeforeEach {
        New-TestRequiredVersions -Root $TestDrive
    }

    It 'normalizes relative repository paths' {
        Push-Location $TestDrive
        try {
            $manifestPath = Get-MsalManifestPath -RepoRoot '.'

            [IO.Path]::IsPathRooted($manifestPath) | Should -BeTrue
            $manifestPath | Should -Be (Join-Path $TestDrive 'PowerShell/ScubaGear/RequiredVersions.ps1')
        }
        finally {
            Pop-Location
        }
    }

    It 'reads the pinned manifest from RequiredVersions.ps1' {
        $manifest = Get-MsalManifest -RepoRoot $TestDrive

        $manifest.Version | Should -Be '4.82.0'
        $manifest.Files.Count | Should -Be 1
    }

    It 'returns the pinned current version' {
        Get-CurrentMsalVersion -RepoRoot $TestDrive | Should -Be '4.82.0'
    }

    It 'returns only stable versions' {
        Mock Invoke-RestMethod {
            return @{ versions = @('4.81.0', '4.82.0', '4.83.0-beta', '4.84.0') }
        }

        @(Get-AvailableMsalVersions) | Should -Be @('4.81.0', '4.82.0', '4.84.0')
    }

    It 'reports an available update without applying it' {
        Mock Get-AvailableMsalVersions { @('4.82.0', '4.87.0') }

        $result = Confirm-MsalUpdateRequirements -RepoRoot $TestDrive

        $result.State | Should -Be 'UpdateAvailable'
        $result.CurrentVersion | Should -Be '4.82.0'
        $result.LatestVersion | Should -Be '4.87.0'
        $result.UpdateRequired | Should -BeTrue
    }

    It 'reports upstream query failures without requesting an update' {
        Mock Get-AvailableMsalVersions { throw 'NuGet unavailable' }

        $result = Confirm-MsalUpdateRequirements -RepoRoot $TestDrive

        $result.State | Should -Be 'QueryFailed'
        $result.UpdateRequired | Should -BeFalse
        $result.Summary | Should -Match 'NuGet unavailable'
    }

    It 'round-trips the manifest block through the formatter and regex replacement' {
        $manifest = Get-MsalManifest -RepoRoot $TestDrive
        $block = Format-MsalManifestBlock -Version $manifest.Version -Packages $manifest.Packages -Files $manifest.Files -LoadOrder $manifest.LoadOrder
        $block | Should -Match "Version = '4.82.0'"

        # The formatter output must parse back to an equivalent manifest.
        $tmp = Join-Path $TestDrive 'roundtrip.ps1'
        Set-Content -Path $tmp -Value $block -Encoding UTF8

        $MsalDependency = $null
        . $tmp
        $MsalDependency.Version | Should -Be '4.82.0'
        $MsalDependency.Files.Count | Should -Be 1
    }
}
