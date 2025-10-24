using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigLoadConfig' {
        BeforeAll {
            Mock -CommandName Write-Warning {}
            function Get-ScubaDefault {throw 'this will be mocked'}
            Mock -ModuleName ScubaConfig Get-ScubaDefault {"."}
	    Remove-Item function:\ConvertFrom-Yaml
        }
        context 'Handling repeated keys in YAML file' {
            It 'Load config with dupliacte keys'{
                # Load the first file and check the ProductNames value.

                {[ScubaConfig]::GetInstance().LoadConfig((Join-Path -Path $PSScriptRoot -ChildPath "./MockLoadConfig.yaml"))} | Should -Throw
            }
            AfterAll {
                [ScubaConfig]::ResetInstance()
            }
        }
        context 'Handling repeated LoadConfig invocations' {
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
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }
            AfterAll {
                [ScubaConfig]::ResetInstance()
            }
        }

    }
}
