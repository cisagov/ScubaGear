using module '..\..\..\..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigDelete' {
        context 'Delete configuration' {
            BeforeEach{
                [ScubaConfig]::ResetInstance()
            }
            It 'Valid config file'{
                $ScubaConfigTestFile = Join-Path -Path $PSScriptRoot -ChildPath config_test.yaml
                $Result = [ScubaConfig]::GetInstance().LoadConfig($ScubaConfigTestFile)
                $Result | Should -Be $true
            }
            It '6 Product names'{
                [ScubaConfig]::GetInstance().Configuration.ProductNames | Should -HaveCount 6 -Because "$([ScubaConfig]::GetInstance().Configuration.ParameterNames)"
            }
            It 'Valid object parameter'{
                [ScubaConfig]::GetInstance().Configuration.AnObject.name | Should -Be 'MyObjectName'
            }
            It 'Valid object parameter'{
                [ScubaConfig]::GetInstance().Configuration.MissingObject.name | Should -BeNullOrEmpty
            }
            It 'A different valid config file'{
                $ScubaConfigTestFile = Join-Path -Path $PSScriptRoot -ChildPath config_test_missing_defaults.json
                $Result = [ScubaConfig]::GetInstance().LoadConfig($ScubaConfigTestFile)
                $Result | Should -Be $true
            }
            It '1 Product names'{
                [ScubaConfig]::GetInstance().Configuration.ProductNames | Should -HaveCount 1
            }
            It 'Valid object parameter'{
                [ScubaConfig]::GetInstance().Configuration.AnObject.name | Should -BeNullOrEmpty
            }
            It 'Valid object parameter'{
                [ScubaConfig]::GetInstance().Configuration.MissingObject.name | Should -Be 'MyMissingObjectName'
            }
        }
    }
}