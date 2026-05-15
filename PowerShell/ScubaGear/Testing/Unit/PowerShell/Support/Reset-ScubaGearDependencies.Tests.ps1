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
        }

        Context "WhatIf mode testing (safe execution)" {
            It "Should analyze missing modules without installing them" {
                Mock Get-Module { return $null }  # No modules installed

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                $result.WhatIfMode | Should -Be $true
                $result.ModulesToInstall.Count | Should -Be $script:RealModuleList.Count
                $result.ActionsCompleted | Should -Be 0  # No actual actions in WhatIf mode
                $result.ActionsNeeded | Should -Be $script:RealModuleList.Count

                # Verify no actual PowerShellGet operations were called
                Assert-MockCalled Install-Module -Times 0
                Assert-MockCalled Uninstall-Module -Times 0
            }

            It "Should handle PowerShell version check correctly" {
                # This test verifies the function loads and checks version properly
                Mock Get-Module { return $null }

                { Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf } | Should -Not -Throw
            }

            It "Should return proper object structure" {
                Mock Get-Module { return $null }

                $result = Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf

                # Verify return object has expected properties
                $result.PSObject.Properties.Name | Should -Contain 'Status'
                $result.PSObject.Properties.Name | Should -Contain 'ModulesToInstall'
                $result.PSObject.Properties.Name | Should -Contain 'ActionsNeeded'
                $result.PSObject.Properties.Name | Should -Contain 'WhatIfMode'
                $result.PSObject.Properties.Name | Should -Contain 'Scope'
            }

            It "Should identify all required modules for installation" {
                Mock Get-Module { return $null }

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

                { Reset-ScubaGearDependencies -Scope CurrentUser -WhatIf } | Should -Not -Throw
                { Reset-ScubaGearDependencies -Scope AllUsers -WhatIf } | Should -Not -Throw
            }

            It "Should work with WhatIf parameter" {
                Mock Get-Module { return $null }

                $result = Reset-ScubaGearDependencies -WhatIf -Scope CurrentUser
                $result.WhatIfMode | Should -Be $true
            }
        }
    }
}
