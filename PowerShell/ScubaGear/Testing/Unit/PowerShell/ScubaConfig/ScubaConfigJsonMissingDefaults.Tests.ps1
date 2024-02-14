using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigMissingDefaults' {
        BeforeAll {
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
            It 'Load valid config file'{
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('aad')
                        M365Environment='commercial'
                        AnObject=@{name='MyObjectName'}
                        DisconnectOnExit = $false
                    }
                }
                [ScubaConfig]::ResetInstance()
                $Result = [ScubaConfig]::GetInstance().LoadConfig($PSCommandPath)
                $Result | Should -Be $true
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
        }
    }
}