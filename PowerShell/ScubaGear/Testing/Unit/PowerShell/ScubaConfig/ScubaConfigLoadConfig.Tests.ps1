using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigLoadConfig' {
        BeforeAll {
            # Initialize the system
            [ScubaConfig]::InitializeValidator()
            Mock -CommandName Write-Warning {}
        }

        AfterAll {
            # Reset instance after all tests in this file
            [ScubaConfig]::ResetInstance()
        }

        context 'Handling repeated keys in YAML file' {
            It 'Load config with duplicate keys throws error'{
                # Load the file with duplicate keys and verify it throws an exception
                {[ScubaConfig]::GetInstance().LoadConfig((Join-Path -Path $PSScriptRoot -ChildPath "./MockLoadConfig.yaml"))} | Should -Throw -ExpectedMessage "*Duplicate key*"
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
                [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile1) | Should -Be $true
                $cfg.Configuration.ProductNames | Should -Contain 'teams'
                
                # Load the second file and verify that ProductNames has changed
                [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile2) | Should -Be $true
                $cfg.Configuration.ProductNames | Should -Contain 'exo'
                $cfg.Configuration.ProductNames | Should -Not -Contain 'teams'
                
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
        
        context "Handling policy omissions" {
            BeforeAll {
                # Create temporary YAML files for policy tests
                $script:TempPolicyFile1 = [System.IO.Path]::GetTempFileName()
                $script:TempPolicyFile1 = [System.IO.Path]::ChangeExtension($script:TempPolicyFile1, '.yaml')
                
                $script:TempPolicyFile2 = [System.IO.Path]::GetTempFileName()
                $script:TempPolicyFile2 = [System.IO.Path]::ChangeExtension($script:TempPolicyFile2, '.yaml')
                
                $script:TempPolicyFile3 = [System.IO.Path]::GetTempFileName()
                $script:TempPolicyFile3 = [System.IO.Path]::ChangeExtension($script:TempPolicyFile3, '.yaml')
                
                # Valid control ID
                @"
ProductNames:
  - exo
OmitPolicy:
  MS.EXO.1.1v2:
    Rationale: Example rationale
"@ | Set-Content -Path $script:TempPolicyFile1
                
                # Malformed control ID
                @"
ProductNames:
  - exo
OmitPolicy:
  MSEXO.1.1v2:
    Rationale: Example rationale
"@ | Set-Content -Path $script:TempPolicyFile2
                
                # Control ID not in ProductNames
                @"
ProductNames:
  - exo
OmitPolicy:
  MS.Gmail.1.1v1:
    Rationale: Example rationale
"@ | Set-Content -Path $script:TempPolicyFile3
            }
            
            It 'Does not throw for proper control IDs' {
                [ScubaConfig]::GetInstance().LoadConfig($script:TempPolicyFile1) | Should -BeTrue
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }

            It 'Throws for malformed control IDs' {
                {[ScubaConfig]::GetInstance().LoadConfig($script:TempPolicyFile2)} | Should -Throw -ExpectedMessage "*does not match expected format*"
            }

            It 'Throws for control IDs not encompassed by ProductNames' {
                {[ScubaConfig]::GetInstance().LoadConfig($script:TempPolicyFile3)} | Should -Throw -ExpectedMessage "*not in the selected ProductNames*"
            }
            
            AfterAll {
                if (Test-Path $script:TempPolicyFile1) {
                    Remove-Item $script:TempPolicyFile1 -Force
                }
                if (Test-Path $script:TempPolicyFile2) {
                    Remove-Item $script:TempPolicyFile2 -Force
                }
                if (Test-Path $script:TempPolicyFile3) {
                    Remove-Item $script:TempPolicyFile3 -Force
                }
            }
        }
    }
}
