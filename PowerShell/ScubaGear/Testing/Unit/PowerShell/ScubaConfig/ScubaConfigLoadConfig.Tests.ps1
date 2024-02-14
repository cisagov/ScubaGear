using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigLoadConfig' {
        context 'Handling repeated LoadConfig invocations' {
            BeforeAll {
                function Get-ScubaDefault {throw 'this will be mocked'}
                Mock -ModuleName ScubaConfig Get-ScubaDefault {"."}
            }
            It 'Load valid config file followed by another'{
                $cfg = [ScubaConfig]::GetInstance()
                # Load the first file and check the ProductNames value.
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('teams')
                    }
                }
                [ScubaConfig]::GetInstance().LoadConfig($PSCommandPath) | Should -BeTrue
                $cfg.Configuration.ProductNames | Should -Be 'teams'
                # Load the second file and verify that ProductNames has changed.
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('exo')
                    }
                }
                [ScubaConfig]::GetInstance().LoadConfig($PSCommandPath) | Should -BeTrue
                $cfg.Configuration.ProductNames | Should -Be 'exo'
            }
            AfterAll {
                [ScubaConfig]::ResetInstance()
            }
        }
    }
}
