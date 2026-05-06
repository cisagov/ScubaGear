Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Support')

InModuleScope 'Support' {
    Describe "Reset-ScubaGearDependencies" {
        BeforeAll {
            # Load the actual RequiredVersions.ps1 data for testing
            $RequiredVersionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\RequiredVersions.ps1"
            if (Test-Path -Path $RequiredVersionsPath) {
                . $RequiredVersionsPath
                $script:RealModuleList = $ModuleList
            } else {
                throw "Could not find RequiredVersions.ps1 at expected path: $RequiredVersionsPath"
            }
        }

        BeforeEach {
            # Mock output functions
            Mock Write-Information { }
            Mock Write-Output { }
            Mock Write-Warning { }
            Mock Write-Error { }

            # Mock PowerShellGet functions to prevent actual installation
            Mock Install-Module { }
            Mock Uninstall-Module { }
            Mock Update-Module { }
            Mock Get-InstalledModule { return $null }

            # Mock OPA functions to prevent actual download/installation
            Mock Install-OPAforSCuBA { }
            Mock Get-ExeHash { return "AABBCCDD" }
        }

        Context "WhatIf mode testing (safe execution)" {
            It "Should analyze missing modules without installing them" {
                Mock Get-Module { return $null }
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $false
                }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                $result.WhatIfMode | Should -Be $true
                $result.ModulesToInstall.Count | Should -Be $script:RealModuleList.Count
                $result.ActionsCompleted | Should -Be 0  # No actual actions in WhatIf mode
                $result.ActionsNeeded | Should -BeGreaterThan 0

                # Verify no actual PowerShellGet operations were called
                Assert-MockCalled Install-Module -Times 0
                Assert-MockCalled Uninstall-Module -Times 0
                Assert-MockCalled Install-OPAforSCuBA -Times 0
            }

            It "Should handle PowerShell version check correctly" {
                # This test verifies the function loads and checks version properly
                Mock Get-Module { return $null }
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $false
                }

                { Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf } | Should -Not -Throw
            }

            It "Should return proper object structure" {
                Mock Get-Module { return $null }
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $false
                }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                # Verify return object has expected module properties
                $result.PSObject.Properties.Name | Should -Contain 'Status'
                $result.PSObject.Properties.Name | Should -Contain 'ModulesToInstall'
                $result.PSObject.Properties.Name | Should -Contain 'ActionsNeeded'
                $result.PSObject.Properties.Name | Should -Contain 'WhatIfMode'
                $result.PSObject.Properties.Name | Should -Contain 'Scope'

                # Verify return object has expected OPA properties
                $result.PSObject.Properties.Name | Should -Contain 'OpaUpToDate'
                $result.PSObject.Properties.Name | Should -Contain 'OpaToInstall'
                $result.PSObject.Properties.Name | Should -Contain 'OpaToUpdate'
            }

            It "Should identify all required modules for installation" {
                Mock Get-Module { return $null }
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $false
                }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                # Check that all expected modules are identified
                foreach ($expectedModule in $script:RealModuleList) {
                    $found = $result.ModulesToInstall | Where-Object { $_.Name -eq $expectedModule.ModuleName }
                    $found | Should -Not -BeNullOrEmpty -Because "Module $($expectedModule.ModuleName) should be in install list"
                }
            }
        }

        Context "Parameter validation" {
            It "Should accept valid Scope values" {
                Mock Get-Module { return $null }
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $false
                }

                { Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf } | Should -Not -Throw
                { Reset-ScubaGearDependencies -Scope AllUsers -WhatIf } | Should -Not -Throw
            }

            It "Should work with WhatIf parameter" {
                Mock Get-Module { return $null }
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $false
                }

                $result = Reset-ScubaGearDependencies -WhatIf -Scope CurrentUser
                $result.WhatIfMode | Should -Be $true
            }
        }

        Context "OPA checks" {
            It "Should identify missing OPA for installation" {
                Mock Get-Module {
                    param($Name, $ListAvailable, $ErrorAction)
                    $module = [PSCustomObject]@{
                        Name        = $Name
                        Version     = [version]'9.9.9'
                        ModuleBase  = "C:\FakeModules\$Name"
                    }
                    return $module
                }
                # OPA executable does not exist
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $false
                }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                $result.OpaToInstall | Should -Not -BeNullOrEmpty
                $result.OpaToInstall.Name | Should -Be "OPA"
                $result.OpaUpToDate | Should -BeNullOrEmpty
                $result.OpaToUpdate | Should -BeNullOrEmpty
            }

            It "Should mark OPA as up to date when executable exists and hash matches" {
                Mock Get-Module {
                    param($Name, $ListAvailable, $ErrorAction)
                    $module = [PSCustomObject]@{
                        Name       = $Name
                        Version    = [version]'9.9.9'
                        ModuleBase = "C:\FakeModules\$Name"
                    }
                    return $module
                }
                # OPA executable exists
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $true
                }
                # Hash matches the expected hash
                Mock Get-ExeHash { return "AABBCCDD" }
                Mock Get-FileHash { return [PSCustomObject]@{ Hash = "AABBCCDD" } }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                $result.OpaUpToDate | Should -Not -BeNullOrEmpty
                $result.OpaUpToDate.Name | Should -Be "OPA"
                $result.OpaToInstall | Should -BeNullOrEmpty
                $result.OpaToUpdate | Should -BeNullOrEmpty
            }

            It "Should mark OPA for update when executable exists but hash does not match" {
                Mock Get-Module {
                    param($Name, $ListAvailable, $ErrorAction)
                    $module = [PSCustomObject]@{
                        Name       = $Name
                        Version    = [version]'9.9.9'
                        ModuleBase = "C:\FakeModules\$Name"
                    }
                    return $module
                }
                # OPA executable exists
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $true
                }
                # Hash does NOT match
                Mock Get-ExeHash { return "AABBCCDD" }
                Mock Get-FileHash { return [PSCustomObject]@{ Hash = "DIFFERENTHASH" } }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                $result.OpaToUpdate | Should -Not -BeNullOrEmpty
                $result.OpaToUpdate.Name | Should -Be "OPA"
                $result.OpaToInstall | Should -BeNullOrEmpty
                $result.OpaUpToDate | Should -BeNullOrEmpty
            }

            It "Should count OPA as an action needed when OPA is missing" {
                Mock Get-Module { return $null }
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $false
                }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                # ActionsNeeded should include OPA install (modules + 1 for OPA)
                $result.ActionsNeeded | Should -Be ($script:RealModuleList.Count + 1)
            }

            It "Should call Install-OPAforSCuBA when OPA is missing and not in WhatIf mode" {
                Mock Get-Module { return $null }
                # All Test-Path calls for OPA exe return false (missing), for RequiredVersions.ps1 return true
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    if ($PathType -eq 'Leaf' -and $Path -like '*opa*') { return $false }
                    return $true
                }

                Reset-ScubaGearDependencies -Scope CurrentUser -Confirm:$false

                Assert-MockCalled Install-OPAforSCuBA -Times 1
            }

            It "Should not call Install-OPAforSCuBA when OPA is up to date" {
                Mock Get-Module {
                    param($Name, $ListAvailable, $ErrorAction)
                    return [PSCustomObject]@{
                        Name       = $Name
                        Version    = [version]'9.9.9'
                        ModuleBase = "C:\FakeModules\$Name"
                    }
                }
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $true
                }
                Mock Get-ExeHash { return "AABBCCDD" }
                Mock Get-FileHash { return [PSCustomObject]@{ Hash = "AABBCCDD" } }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                Assert-MockCalled Install-OPAforSCuBA -Times 0
                $result.OpaUpToDate | Should -Not -BeNullOrEmpty
            }

            It "Should include OPA expected version and executable name in result info" {
                Mock Get-Module { return $null }
                Mock Test-Path {
                    param($Path, $PathType)
                    if ($Path -like '*RequiredVersions.ps1') { return $true }
                    return $false
                }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                $result.OpaToInstall.ExpectedVersion | Should -Not -BeNullOrEmpty
                $result.OpaToInstall.ExecutableName | Should -Not -BeNullOrEmpty
                $result.OpaToInstall.InstallPath | Should -Not -BeNullOrEmpty
            }
        }
    }
}
