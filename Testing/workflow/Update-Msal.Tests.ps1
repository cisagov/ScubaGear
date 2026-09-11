BeforeAll {
    . (Join-Path $PSScriptRoot '../../utils/workflow/Update-Msal.ps1')

    function New-TestMsalPackagesConfig {
        param(
            [string]$Root,
            [string]$MsalVersion = '4.82.0',
            [string]$BrokerVersion = '4.82.0'
        )

        $dependencyPath = Join-Path $Root 'PowerShell/ScubaGear/dependencies'
        New-Item -Path $dependencyPath -ItemType Directory -Force | Out-Null
        @"
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Microsoft.Identity.Client" version="$MsalVersion" targetFramework="net462" />
  <package id="Microsoft.Identity.Client.Broker" version="$BrokerVersion" targetFramework="net462" />
</packages>
"@ | Set-Content -Path (Join-Path $dependencyPath 'packages.config')
    }
}

Describe 'MSAL dependency updates' {
    BeforeEach {
        New-TestMsalPackagesConfig -Root $TestDrive
    }

    It 'normalizes relative repository paths' {
        Push-Location $TestDrive
        try {
            $paths = Get-MsalDependencyPaths -RepoRoot '.'

            [IO.Path]::IsPathRooted($paths.ModuleRoot) | Should -BeTrue
            $paths.ModuleRoot | Should -Be (Join-Path $TestDrive 'PowerShell/ScubaGear')
        }
        finally {
            Pop-Location
        }
    }

    It 'returns the aligned current package version' {
        $paths = Get-MsalDependencyPaths -RepoRoot $TestDrive
        Get-CurrentMsalVersion -PackagesConfig $paths.PackagesConfig | Should -Be '4.82.0'
    }

    It 'rejects MSAL and Broker version skew' {
        New-TestMsalPackagesConfig -Root $TestDrive -BrokerVersion '4.81.0'
        $paths = Get-MsalDependencyPaths -RepoRoot $TestDrive
        { Get-CurrentMsalVersion -PackagesConfig $paths.PackagesConfig } | Should -Throw
    }

    It 'returns only stable versions shared by both packages' {
        Mock Invoke-RestMethod {
            if ($Uri -match 'broker') {
                return @{ versions = @('4.82.0', '4.83.0-beta', '4.84.0') }
            }
            return @{ versions = @('4.81.0', '4.82.0', '4.84.0', '4.85.0') }
        }

        @(Get-AvailableMsalVersions) | Should -Be @('4.82.0', '4.84.0')
    }

    It 'reports an available shared update without applying it' {
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
}
