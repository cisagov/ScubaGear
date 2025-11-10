using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigLoadConfig' {
        BeforeAll {
            Mock -CommandName Write-Warning {}
        }

        AfterAll {
            # Reset instance after all tests in this file
            [ScubaConfig]::ResetInstance()
        }

        context 'Handling repeated keys in YAML file' {
            It 'Load config with duplicate keys'{
                # Load the file with duplicate keys and check that it throws an error
                {[ScubaConfig]::GetInstance().LoadConfig((Join-Path -Path $PSScriptRoot -ChildPath "./MockLoadConfig.yaml"))} | Should -Throw
            }
            AfterAll {
                [ScubaConfig]::ResetInstance()
            }
        }

        context 'Handling repeated LoadConfig invocations' {
            BeforeAll {
                # Create two temporary YAML files for testing
                $script:TempConfigFile1 = [System.IO.Path]::GetTempFileName()
                $script:TempConfigFile1 = [System.IO.Path]::ChangeExtension($script:TempConfigFile1, '.yaml')

                $script:TempConfigFile2 = [System.IO.Path]::GetTempFileName()
                $script:TempConfigFile2 = [System.IO.Path]::ChangeExtension($script:TempConfigFile2, '.yaml')

                # First config with teams
                @"
ProductNames:
  - teams
"@ | Set-Content -Path $script:TempConfigFile1

                # Second config with exo
                @"
ProductNames:
  - exo
"@ | Set-Content -Path $script:TempConfigFile2
            }

            It 'Load valid config file followed by another'{
                $cfg = [ScubaConfig]::GetInstance()

                # Load the first file and check the ProductNames value
                [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile1) | Should -BeTrue
                $cfg.Configuration.ProductNames | Should -Contain 'teams'
                $cfg.Configuration.ProductNames.Count | Should -Be 1

                # Load the second file and verify that ProductNames has changed
                [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile2) | Should -BeTrue
                $cfg.Configuration.ProductNames | Should -Contain 'exo'
                $cfg.Configuration.ProductNames | Should -Not -Contain 'teams'
                $cfg.Configuration.ProductNames.Count | Should -Be 1

                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }

            AfterAll {
                [ScubaConfig]::ResetInstance()
                if (Test-Path $script:TempConfigFile1) {
                    Remove-Item $script:TempConfigFile1 -Force
                }
                if (Test-Path $script:TempConfigFile2) {
                    Remove-Item $script:TempConfigFile2 -Force
                }
            }
        }
    }
}
