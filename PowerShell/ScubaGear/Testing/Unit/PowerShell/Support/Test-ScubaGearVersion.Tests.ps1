Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Support')

InModuleScope 'Support' {
    Describe "Test-ScubaGearVersion" {
        BeforeAll {
            # Load the RequiredVersions.ps1 file
            $RequiredVersionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\RequiredVersions.ps1"
            if (Test-Path -Path $RequiredVersionsPath) {
                . $RequiredVersionsPath
                # Load the ScubaGear module list to reference later
                $script:ScubaGearModuleList = $ModuleList
            } else {
                throw "Could not find RequiredVersions.ps1 at expected path: $RequiredVersionsPath"
            }

            # Load the ScubaGear version from the manifest
            $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\ScubaGear.psd1"
            if (Test-Path -Path $ManifestPath) {
                $manifestData = Import-PowerShellDataFile -Path $ManifestPath
                $script:CurrentScubaGearVersion = [version]$manifestData.ModuleVersion
            } else {
                throw "Could not find ScubaGear.psd1 at expected path: $ManifestPath"
            }

            # for GitHub container
            if (-not (Get-Command -Name 'Get-DependencyStatus' -ErrorAction SilentlyContinue)) {
                function script:Get-DependencyStatus { }
            }

            $script:MockDependencyModules = @{}
            foreach ($module in $script:ScubaGearModuleList) {
                # Create a mock version that's within the acceptable range
                $mockVersion = $module.ModuleVersion
                if ($mockVersion -lt $module.MaximumVersion) {
                    # Use a version slightly higher than minimum but within range
                    $mockVersion = [version]"$($module.ModuleVersion.Major).$($module.ModuleVersion.Minor + 1).0"
                }

                $script:MockDependencyModules[$module.ModuleName] = @(
                    @{
                        Name = $module.ModuleName
                        Version = $mockVersion
                        ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\$($module.ModuleName)\$mockVersion"
                    }
                )
            }

            # Create mock ScubaGear module using actual version
            $script:MockScubaGearModule = @{
                Name = 'ScubaGear'
                Version = $script:CurrentScubaGearVersion
                ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\ScubaGear\$($script:CurrentScubaGearVersion)"
            }

            # Simulate a newer version for update testing using ScubaGear's versioning pattern
            # ScubaGear uses versions like 1.4.0, 1.5.0, 1.6.0, so increment minor version
            $script:MockNewerScubaGearVersion = [version]"$($script:CurrentScubaGearVersion.Major).$($script:CurrentScubaGearVersion.Minor + 1).0"

            # Create an older version using ScubaGear's versioning pattern
            # For current version 1.6.0, older would be 1.5.0
            if ($script:CurrentScubaGearVersion.Minor -eq 0) {
                # If we're at X.0.0, go to (X-1).9.0 (though this is unlikely for ScubaGear)
                $script:MockOlderScubaGearVersion = [version]"$($script:CurrentScubaGearVersion.Major - 1).9.0"
            } else {
                # Normal case: 1.6.0 -> 1.5.0
                $script:MockOlderScubaGearVersion = [version]"$($script:CurrentScubaGearVersion.Major).$($script:CurrentScubaGearVersion.Minor - 1).0"
            }

            # Set up default mocks at BeforeAll level to ensure they're available
            Mock Get-DependencyStatus {
                return [PSCustomObject]@{
                    TotalRequired = $script:ScubaGearModuleList.Count
                    Installed = $script:ScubaGearModuleList.Count
                    Missing = @()
                    MultipleVersions = @()
                    ModuleFileLocations = @()
                    AdminRequired = $false
                    Status = "Optimal"
                    Recommendations = @("All dependencies are installed.")
                }
            }

            Mock Write-Information { }
            Mock Invoke-RestMethod { }

            # Mock Find-Module (this will work regardless of whether PowerShellGet is loaded)
            Mock Find-Module {
                param($Name)
                $null = $Name  # Satisfy PSScriptAnalyzer
                if ($Name -eq 'ScubaGear') {
                    return @{ Version = $script:MockNewerScubaGearVersion }
                }
                return $null
            }
        }
        BeforeEach {
            # Mock Find-Module (this will work regardless of whether PowerShellGet is loaded)
            Mock Find-Module {
                param($Name)
                $null = $Name  # Satisfy PSScriptAnalyzer
                if ($Name -eq 'ScubaGear') {
                    return @{ Version = $script:MockNewerScubaGearVersion }
                }
                return $null
            }

            Mock Get-DependencyStatus {
                return [PSCustomObject]@{
                    TotalRequired = $script:ScubaGearModuleList.Count
                    Installed = $script:ScubaGearModuleList.Count
                    Missing = @()
                    MultipleVersions = @()
                    ModuleFileLocations = @()
                    AdminRequired = $false
                    Status = "Optimal"
                    Recommendations = @("All dependencies are installed.")
                }
            }

            Mock Write-Information { }
            Mock Invoke-RestMethod { }
        }

        Context "When ScubaGear is not installed" {
            It "Should report ScubaGear as not installed" {
                Mock Get-Module {
                    param($Name, $ListAvailable)
                    $null = $Name, $ListAvailable  # Satisfy PSScriptAnalyzer
                    return $null
                }

                $result = Test-ScubaGearVersion

                $result[0].Status | Should -Be "Not Installed"
                $result[0].Recommendations | Should -Match "Install-Module ScubaGear"
            }
        }

        Context "When ScubaGear is up to date" {
            It "Should report ScubaGear as up to date using actual current version" {
                Mock Get-Module {
                    param($Name, $ListAvailable)
                    $null = $Name, $ListAvailable  # Satisfy PSScriptAnalyzer
                    if ($Name -eq 'ScubaGear' -and $ListAvailable) {
                        # Return a single module as an array
                        return [PSCustomObject]@{
                            Version = $script:CurrentScubaGearVersion
                            ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\ScubaGear\$($script:CurrentScubaGearVersion)"
                        }
                    }
                    return $null
                }
                Mock Find-Module {
                    param($Name, $Repository)
                    $null = $Name, $Repository  # Satisfy PSScriptAnalyzer
                    if ($Name -eq 'ScubaGear') {
                        return @{ Version = $script:CurrentScubaGearVersion }
                    }
                    return $null
                }

                $result = Test-ScubaGearVersion

                $result[0].Status | Should -Be "Up to Date"
                $result[0].CurrentVersion | Should -Be $script:CurrentScubaGearVersion
                $result[0].LatestVersion | Should -Be $script:CurrentScubaGearVersion
                $result[0].CurrentVersion | Should -Be $script:CurrentScubaGearVersion
                $result[0].LatestVersion | Should -Be $script:CurrentScubaGearVersion
            }
        }

        Context "When ScubaGear needs update" {
            It "Should detect when update is needed using real version numbers" {
                Mock Get-Module {
                    param($Name, $ListAvailable)
                    $null = $Name, $ListAvailable  # Satisfy PSScriptAnalyzer
                    if ($Name -eq 'ScubaGear' -and $ListAvailable) {
                        return @{
                            Version = $script:CurrentScubaGearVersion
                            ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\ScubaGear\$($script:CurrentScubaGearVersion)"
                        }
                    }
                    return $null
                }
                Mock Find-Module {
                    param($Name, $Repository)
                    $null = $Name, $Repository  # Satisfy PSScriptAnalyzer
                    if ($Name -eq 'ScubaGear') {
                        return @{ Version = $script:MockNewerScubaGearVersion }
                    }
                    return $null
                }

                $result = Test-ScubaGearVersion

                $result[0].CurrentVersion | Should -Be $script:CurrentScubaGearVersion
                $result[0].LatestVersion | Should -Be $script:MockNewerScubaGearVersion
                $result[0].Recommendations | Should -Match "Update-ScubaGear"
            }
        }

        Context "When ScubaGear has multiple versions" {
            It "Should detect multiple versions and return highest version as current" {
                # The function sorts by Version -Descending and selects the first (highest) version
                # as the current version, even when multiple versions are installed
                Mock Get-Module {
                    param($Name, $ListAvailable)
                    $null = $Name, $ListAvailable  # Satisfy PSScriptAnalyzer
                    if ($Name -eq 'ScubaGear' -and $ListAvailable) {
                        # Put older version first in array, but function will find highest
                        return @(
                            @{
                                Version = $script:MockOlderScubaGearVersion
                                ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\ScubaGear\$($script:MockOlderScubaGearVersion)"
                            },
                            @{
                                Version = $script:CurrentScubaGearVersion
                                ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\ScubaGear\$($script:CurrentScubaGearVersion)"
                            }
                        )
                    }
                    return $null
                }

                $result = Test-ScubaGearVersion

                $result[0].MultipleVersionsInstalled | Should -Be $true
                # Function returns highest version (1.6.0) as current, not first in array
                $result[0].CurrentVersion | Should -Be $script:CurrentScubaGearVersion
                # Check for the actual recommendation text that mentions versions
                $result[0].Recommendations | Should -Match "versions installed"
            }
        }

        Context "When dependencies have multiple versions" {
            It "Should report multiple versions for real modules" {
                # Use first two modules from actual requirements for testing
                $firstModule = $script:ScubaGearModuleList[0]
                $secondModule = $script:ScubaGearModuleList[1]

                # Add Get-Module mock to return ScubaGear module
                Mock Get-Module {
                    param($Name, $ListAvailable)
                    if ($Name -eq 'ScubaGear' -and $ListAvailable) {
                        return @{
                            Version = $script:CurrentScubaGearVersion
                            ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\ScubaGear\$($script:CurrentScubaGearVersion)"
                        }
                    }
                    return $null
                }

                Mock Get-DependencyStatus {
                    return [PSCustomObject]@{
                        TotalRequired = $script:ScubaGearModuleList.Count
                        Installed = $script:ScubaGearModuleList.Count
                        Missing = @()
                        MultipleVersions = @($firstModule.ModuleName, $secondModule.ModuleName)
                        ModuleFileLocations = @(
                            [PSCustomObject]@{
                                ModuleName = $firstModule.ModuleName
                                VersionCount = 2
                                MinVersion = $firstModule.ModuleVersion.ToString()
                                MaxVersion = $firstModule.MaximumVersion.ToString()
                                Locations = @(
                                    "$($firstModule.ModuleVersion) [OK] (CurrentUser): $env:USERPROFILE\Documents\PowerShell\Modules\$($firstModule.ModuleName)\$($firstModule.ModuleVersion)",
                                    "$($firstModule.ModuleVersion.Major).$($firstModule.ModuleVersion.Minor + 1).0 [OK] (CurrentUser): $env:USERPROFILE\Documents\PowerShell\Modules\$($firstModule.ModuleName)\$($firstModule.ModuleVersion.Major).$($firstModule.ModuleVersion.Minor + 1).0"
                                )
                            },
                            [PSCustomObject]@{
                                ModuleName = $secondModule.ModuleName
                                VersionCount = 2
                                MinVersion = $secondModule.ModuleVersion.ToString()
                                MaxVersion = $secondModule.MaximumVersion.ToString()
                                Locations = @(
                                    "$($secondModule.ModuleVersion) [OK] (AllUsers): $env:ProgramFiles\PowerShell\Modules\$($secondModule.ModuleName)\$($secondModule.ModuleVersion)",
                                    "$($secondModule.ModuleVersion.Major).$($secondModule.ModuleVersion.Minor + 1).0 [OK] (CurrentUser): $env:USERPROFILE\Documents\PowerShell\Modules\$($secondModule.ModuleName)\$($secondModule.ModuleVersion.Major).$($secondModule.ModuleVersion.Minor + 1).0"
                                )
                            }
                        )
                        AdminRequired = $true
                        Status = "Needs Cleanup"
                        Recommendations = @("2 modules have multiple versions installed. Run 'Reset-ScubaGearDependencies' to clean up.")
                    }
                }

                $result = Test-ScubaGearVersion

                # Test against the dependency component (second element in array)
                $result[1].MultipleVersionsInstalled | Should -Be $true
                $result[1].MultipleVersionModules | Should -Contain $firstModule.ModuleName
                $result[1].MultipleVersionModules | Should -Contain $secondModule.ModuleName
                $result[1].ModuleFileLocations.Count | Should -Be 2
            }
        }

        Context "GitHub version check with real version" {
            It "Should attempt GitHub version check and compare with real version" {
                # Use ScubaGear versioning pattern for GitHub mock
                $mockGitHubVersion = [version]"$($script:CurrentScubaGearVersion.Major).$($script:CurrentScubaGearVersion.Minor + 1).0"

                # Override the default mock specifically for this test
                Mock Invoke-RestMethod {
                    return @{ tag_name = "v$mockGitHubVersion" }
                } -ParameterFilter { $Uri -like "*github.com*" }

                # Also mock a successful Get-Module call to ensure ScubaGear is "installed"
                Mock Get-Module {
                    param($Name, $ListAvailable)
                    $null = $Name, $ListAvailable  # Satisfy PSScriptAnalyzer
                    if ($Name -eq 'ScubaGear' -and $ListAvailable) {
                        return @{
                            Version = $script:CurrentScubaGearVersion
                            ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\ScubaGear\$($script:CurrentScubaGearVersion)"
                        }
                    }
                    return $null
                }

                $result = Test-ScubaGearVersion -CheckGitHub

                # Should have attempted to check GitHub
                Assert-MockCalled Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -like "*github.com*" }
                $result[0].CurrentVersion | Should -Be $script:CurrentScubaGearVersion
            }
        }

        Context "Parameter validation" {
            It "Should accept CheckGitHub switch parameter" {
                { Test-ScubaGearVersion -CheckGitHub } | Should -Not -Throw
            }

            It "Should work without parameters" {
                { Test-ScubaGearVersion } | Should -Not -Throw
            }
        }
    }
}