using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigDelete' {
        context 'Delete configuration' {
            BeforeAll{
                [ScubaConfig]::ResetInstance()
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@("teams", "exo", "defender", "aad", "powerplatform", "sharepoint")
                        AnObject=@{name='MyObjectName'}
                    }
                }
                # Create a temporary YAML file for testing
                $script:TempConfigFile = [System.IO.Path]::GetTempFileName()
                $script:TempConfigFile = [System.IO.Path]::ChangeExtension($script:TempConfigFile, '.yaml')
                "ProductNames: ['aad']" | Set-Content -Path $script:TempConfigFile
            }
            It 'Valid config file'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile)
                $Result | Should -Be $true
            }
            It '6 Product names'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile)
                $Result | Should -Be $true
                [ScubaConfig]::GetInstance().Configuration.ProductNames | Should -HaveCount 6 -Because "$([ScubaConfig]::GetInstance().Configuration.ParameterNames)"
            }
            It 'Valid object parameter'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile)
                $Result | Should -Be $true
                [ScubaConfig]::GetInstance().Configuration.AnObject.name | Should -Be 'MyObjectName'
            }
            It 'Valid object parameter'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile)
                $Result | Should -Be $true
                [ScubaConfig]::GetInstance().Configuration.MissingObject.name | Should -BeNullOrEmpty
            }
            It 'Reset Instance'{
                [ScubaConfig]::ResetInstance()
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@("teams")
                        MissingObject=@{name='MyMissingObjectName'}
                    }
                }
            }
            It 'A different valid config file'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile)
                $Result | Should -Be $true
            }
            It '1 Product names'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile)
                $Result | Should -Be $true
                [ScubaConfig]::GetInstance().Configuration.ProductNames | Should -HaveCount 1
            }
            It 'Valid object parameter'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile)
                $Result | Should -Be $true
                [ScubaConfig]::GetInstance().Configuration.AnObject.name | Should -BeNullOrEmpty
            }
            It 'Valid object parameter'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile)
                $Result | Should -Be $true
                [ScubaConfig]::GetInstance().Configuration.MissingObject.name | Should -Be 'MyMissingObjectName'
            }
            AfterAll{
                [ScubaConfig]::ResetInstance()
                if (Test-Path $script:TempConfigFile) {
                    Remove-Item $script:TempConfigFile -Force
                }
            }
        }
    }
}
