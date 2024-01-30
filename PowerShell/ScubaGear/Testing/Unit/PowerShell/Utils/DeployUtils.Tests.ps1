Context "UT for Build-ScubaModule" {
    Describe -Name 'Return good build folder' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModulePath')]
            $ModulePath = Join-Path -Path $PSScriptRoot -Child '..'
            . (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..\..\utils\DeployUtils.ps1')
            Mock ConfigureScubaGearModule {$true}
        }
        It 'Verify a valid directory is returned' {
            Mock ConfigureScubaGearModule {$true}
            ($ModuleBuildPath = Build-ScubaModule -ModulePath $ModulePath) | Should -Not -BeNullOrEmpty
            Test-Path -Path $ModuleBuildPath -PathType Container | Should -BeTrue
        }
    }
    Describe -Name 'Publish error' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModulePath')]
            $ModulePath = Join-Path -Path $PSScriptRoot -Child '..'
            . (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..\..\utils\DeployUtils.ps1')
            Mock ConfigureScubaGearModule {$false} -Verifiable
            Mock -CommandName Write-Error {}
        }
        It 'Verify warning for config failed' {
            Build-ScubaModule -ModulePath $ModulePath
            Assert-MockCalled Write-Error -Times 1
        }
    }
}

Context "Unit Test for ConfigureScubaGearModule" {
    Describe -Name 'Update manifest' {
        BeforeAll {
            . (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..\..\utils\DeployUtils.ps1')
            $ModulePath = Join-Path -Path $PSScriptRoot -Child '..\..\..\..\'
            if (Test-Path -Path "$env:TEMP\ScubaGear"){
                Remove-Item -Force -Recurse "$env:TEMP\ScubaGear"
            }
            Copy-Item -Recurse -Path $ModulePath -Destination $env:TEMP -Force
            ConfigureScubaGearModule -ModulePath "$env:TEMP\ScubaGear" | Should -BeTrue
            Import-LocalizedData -BaseDirectory "$env:TEMP\ScubaGear" -FileName ScubaGear.psd1 -BindingVariable UpdatedManifest
        }
        It 'Validate Private Data <Name>' -ForEach @(
            @{Name="ProjectUri";Field="ProjectUri"; Expected="https://github.com/cisagov/ScubaGear"},
            @{Name="LicenseUri";Field="LicenseUri"; Expected="https://github.com/cisagov/ScubaGear/blob/main/LICENSE"}
        ){
            $UpdatedManifest.PrivateData.PSData.$Field | Should -BeExactly $Expected
        }
        It 'Validate Manifest Tags' {
            $UpdatedManifest.PrivateData.PSData.Tags | Should -Contain "CISA"
        }
        It 'Validate Manifest ModuleVersion' {
            $Version = [version]$UpdatedManifest.ModuleVersion
            $Version.Major -Match '[0-9]+' | Should -BeTrue
            $Version.Minor -Match '[0-9]+' | Should -BeTrue
            $Version.Build -Match '[0-9]+' | Should -BeTrue
            $Version.Revision -Match '[0-9]+' | Should -BeTrue
        }
    }
    Describe -Name 'Update manifest with version override' {
        BeforeAll {
            . (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..\..\utils\DeployUtils.ps1')
            $ModulePath = Join-Path -Path $PSScriptRoot -Child '..\..\..\..\'
            if (Test-Path -Path "$env:TEMP\ScubaGear"){
                Remove-Item -Force -Recurse "$env:TEMP\ScubaGear"
            }
            Copy-Item -Recurse -Path $ModulePath -Destination $env:TEMP -Force
            ConfigureScubaGearModule -ModulePath "$env:TEMP\ScubaGear" -OverrideModuleVersion "3.0.1"
            Import-LocalizedData -BaseDirectory "$env:TEMP\ScubaGear" -FileName ScubaGear.psd1 -BindingVariable UpdatedManifest
        }
        It 'Validate Manifest ModuleVersion' {
            $Version = [version]$UpdatedManifest.ModuleVersion
            $Version.Major | Should -BeExactly 3
            $Version.Minor | Should -BeExactly 0
            $Version.Build | Should -BeExactly 1
            $Version.Revision | Should -BeExactly -1
            $Version | Should -BeExactly "3.0.1"
        }
    }

    Describe -Name 'Update manifest with prerelease' {
        BeforeAll {
            . (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..\..\utils\DeployUtils.ps1')
            $ModulePath = Join-Path -Path $PSScriptRoot -Child '..\..\..\..\'
            if (Test-Path -Path "$env:TEMP\ScubaGear"){
                Remove-Item -Force -Recurse "$env:TEMP\ScubaGear"
            }
            Copy-Item -Recurse -Path $ModulePath -Destination $env:TEMP -Force
            ConfigureScubaGearModule -ModulePath "$env:TEMP\ScubaGear" -OverrideModuleVersion "3.0.1" -PrereleaseTag 'Alpha'
            Import-LocalizedData -BaseDirectory "$env:TEMP\ScubaGear" -FileName ScubaGear.psd1 -BindingVariable UpdatedManifest
        }
        It 'Validate Manifest version info with prerelease' {
            $Version = [version]$UpdatedManifest.ModuleVersion
            $Version.Major | Should -BeExactly 3
            $Version.Minor | Should -BeExactly 0
            $Version.Build | Should -BeExactly 1
            $Version.Revision | Should -BeExactly -1
            $Version | Should -BeExactly "3.0.1"
            $UpdatedManifest.PrivateData.PSData.Prerelease | Should -BeExactly 'Alpha'
        }
    }
    Describe -Name 'Update manifest Bad' {
        BeforeAll {
            . (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\..\..\utils\DeployUtils.ps1')
            $ModulePath = Join-Path -Path $PSScriptRoot -Child '..\..\..\..\'
            if (Test-Path -Path "$env:TEMP\ScubaGear"){
                Remove-Item -Force -Recurse "$env:TEMP\ScubaGear"
            }
            Copy-Item -Recurse -Path $ModulePath -Destination $env:TEMP -Force
            $ManifestPath = Join-Path -Path $env:TEMP -ChildPath 'ScubaGear\ScubaGear.psd1' -Resolve
            Get-Content "$ModulePath\ScubaGear.psd1" | ForEach-Object { $_ -replace '5.1', '99.1' } | Set-Content $ManifestPath
            Mock -CommandName Write-Error {}
        }
        It 'Validate ConfigureScubaGearModule fails with bad Manifest' {
            ConfigureScubaGearModule -ModulePath "$env:TEMP\ScubaGear" | Should -BeFalse
            Assert-MockCalled Write-Error -Times 1
        }
    }
}

