using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigLoadConfig' {
        BeforeAll {
            Mock -CommandName Write-Warning {}
            function Get-ScubaDefault {throw 'this will be mocked'}
            Mock -ModuleName ScubaConfig Get-ScubaDefault {"."}
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
        context "Handling policy omissions" {
            It 'Does not warn for proper control IDs' {
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('exo');
                        OmitPolicy=@{"MS.EXO.1.1v1"=@{"Rationale"="Example rationale"}}
                    }
                }
                [ScubaConfig]::GetInstance().LoadConfig($PSCommandPath) | Should -BeTrue
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }

            It 'Warns for malformed control IDs' {
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('exo');
                        OmitPolicy=@{"MSEXO.1.1v1"=@{"Rationale"="Example rationale"}}
                    }
                }
                [ScubaConfig]::GetInstance().LoadConfig($PSCommandPath) | Should -BeTrue
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
            }

            It 'Warns for control IDs not encompassed by ProductNames' {
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('exo');
                        OmitPolicy=@{"MS.Gmail.1.1v1"=@{"Rationale"="Example rationale"}}
                    }
                }
                [ScubaConfig]::GetInstance().LoadConfig($PSCommandPath) | Should -BeTrue
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
            }
        }
    }
}
