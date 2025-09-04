Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Support')

InModuleScope 'Support' {
    Describe "Update-ScubaGear" {
        BeforeAll {
            # Load the actual ScubaGear version from the manifest
            $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\ScubaGear.psd1"
            if (Test-Path -Path $ManifestPath) {
                $manifestData = Import-PowerShellDataFile -Path $ManifestPath
                $script:CurrentScubaGearVersion = [version]$manifestData.ModuleVersion
            } else {
                throw "Could not find ScubaGear.psd1 at expected path: $ManifestPath"
            }

            # Create test versions based on actual version
            $script:MockNewerVersion = [version]"$($script:CurrentScubaGearVersion.Major).$($script:CurrentScubaGearVersion.Minor + 1).0"
            $script:MockOlderVersion = [version]"$($script:CurrentScubaGearVersion.Major).$($script:CurrentScubaGearVersion.Minor - 1).0"

            # For GitHub container
            if (-not (Get-Command -Name 'Update-ScubaGearFromPSGallery' -ErrorAction SilentlyContinue)) {
                function script:Update-ScubaGearFromPSGallery { param($Scope) }
            }
            if (-not (Get-Command -Name 'Update-ScubaGearFromGitHub' -ErrorAction SilentlyContinue)) {
                function script:Update-ScubaGearFromGitHub { }
            }

            # Set up default mocks at BeforeAll level to ensure they're available
            Mock Write-Output { }
            Mock Write-Information { }
            Mock Write-Error { }
            Mock Write-Warning { }
            Mock Update-ScubaGearFromPSGallery { }
            Mock Update-ScubaGearFromGitHub { }
        }

        BeforeEach {
            Mock Write-Output { }
            Mock Write-Information { }
            Mock Write-Error { }
            Mock Write-Warning { }
            Mock Update-ScubaGearFromPSGallery { }
            Mock Update-ScubaGearFromGitHub { }
        }

        Context "PSGallery update scenarios" {
            It "Should call PSGallery update function with CurrentUser scope" {
                Update-ScubaGear -Source PSGallery -Scope CurrentUser

                Assert-MockCalled Update-ScubaGearFromPSGallery -Times 1 -ParameterFilter { $Scope -eq 'CurrentUser' }
                Assert-MockCalled Update-ScubaGearFromGitHub -Times 0
            }

            It "Should call PSGallery update function with AllUsers scope" {
                Update-ScubaGear -Source PSGallery -Scope AllUsers

                Assert-MockCalled Update-ScubaGearFromPSGallery -Times 1 -ParameterFilter { $Scope -eq 'AllUsers' }
            }

            It "Should default to PSGallery source when not specified" {
                Update-ScubaGear -Scope CurrentUser

                Assert-MockCalled Update-ScubaGearFromPSGallery -Times 1
                Assert-MockCalled Update-ScubaGearFromGitHub -Times 0
            }

            It "Should default to CurrentUser scope when not specified" {
                Update-ScubaGear -Source PSGallery

                Assert-MockCalled Update-ScubaGearFromPSGallery -Times 1 -ParameterFilter { $Scope -eq 'CurrentUser' }
            }
        }

        Context "GitHub update scenarios" {
            It "Should call GitHub update function" {
                Update-ScubaGear -Source GitHub

                Assert-MockCalled Update-ScubaGearFromGitHub -Times 1
                Assert-MockCalled Update-ScubaGearFromPSGallery -Times 0
            }
        }

        Context "Error handling scenarios" {
            It "Should handle invalid source parameter" {
                { Update-ScubaGear -Source "InvalidSource" } | Should -Throw
            }

            It "Should handle invalid scope parameter" {
                { Update-ScubaGear -Scope "InvalidScope" } | Should -Throw
            }
        }

        Context "Parameter validation" {
            It "Should accept valid Source parameter values" {
                { Update-ScubaGear -Source PSGallery } | Should -Not -Throw
                { Update-ScubaGear -Source GitHub } | Should -Not -Throw
            }

            It "Should accept valid Scope parameter values" {
                { Update-ScubaGear -Scope CurrentUser } | Should -Not -Throw
                { Update-ScubaGear -Scope AllUsers } | Should -Not -Throw
            }

            It "Should work with no parameters (defaults)" {
                { Update-ScubaGear } | Should -Not -Throw

                Assert-MockCalled Update-ScubaGearFromPSGallery -Times 1 -ParameterFilter { $Scope -eq 'CurrentUser' }
            }
        }

        Context "Integration with helper functions" {
            It "Should call appropriate helper function based on source" {
                Update-ScubaGear -Source PSGallery -Scope AllUsers
                Update-ScubaGear -Source GitHub

                Assert-MockCalled Update-ScubaGearFromPSGallery -Times 1
                Assert-MockCalled Update-ScubaGearFromGitHub -Times 1
            }

            It "Should pass through parameters correctly to PSGallery function" {
                Update-ScubaGear -Source PSGallery -Scope AllUsers

                Assert-MockCalled Update-ScubaGearFromPSGallery -Times 1 -ParameterFilter {
                    $Scope -eq 'AllUsers'
                }
            }
        }
    }
}
