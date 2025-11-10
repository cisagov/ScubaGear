using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigMissingDefaults' {
        BeforeAll {
            [ScubaConfig]::ResetInstance()
        }

        AfterAll {
            [ScubaConfig]::ResetInstance()
        }

        Context 'General case'{
            It 'Get Instance without loading'{
               $Config1 = [ScubaConfig]::GetInstance()
               $Config1 | Should -Not -BeNull
               $Config2 =  [ScubaConfig]::GetInstance()

               $Config1 -eq $Config2 | Should -Be $true
            }
            It 'Load invalid path'{
                {[ScubaConfig]::GetInstance().LoadConfig('Bad path name')}| Should -Throw -ExceptionType([System.IO.FileNotFoundException])
            }
        }

        context 'JSON Configuration' {
            BeforeAll {
                # Create a temporary YAML file for testing
                $script:TempConfigFile = [System.IO.Path]::GetTempFileName()
                $script:TempConfigFile = [System.IO.Path]::ChangeExtension($script:TempConfigFile, '.yaml')

                # Create a valid YAML config with specific values
                @"
ProductNames:
  - aad
M365Environment: commercial
DisconnectOnExit: false
"@ | Set-Content -Path $script:TempConfigFile
                
                # Load the config once for all tests in this context
                [ScubaConfig]::ResetInstance()
                [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile)
            }

            It 'Configuration loaded successfully'{
                [ScubaConfig]::GetInstance().Configuration | Should -Not -BeNullOrEmpty
            }

            It 'Valid string parameter'{
                [ScubaConfig]::GetInstance().Configuration.M365Environment | Should -Be 'commercial'
            }

            It 'Valid array parameter'{
                [ScubaConfig]::GetInstance().Configuration.ProductNames | Should -Contain 'aad'
            }

            It 'Valid boolean parameter'{
                [ScubaConfig]::GetInstance().Configuration.DisconnectOnExit | Should -Be $false
            }

            AfterAll {
                if (Test-Path $script:TempConfigFile) {
                    Remove-Item $script:TempConfigFile -Force
                }
            }
        }
    }
}