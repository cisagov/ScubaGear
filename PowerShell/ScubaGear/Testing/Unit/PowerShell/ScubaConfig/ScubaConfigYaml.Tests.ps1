using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigYaml' {
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
        context 'YAML Configuration' {
            It 'Valid config file'{
                mock global:ConvertFrom-Yaml {
                    @{
                        ProductNames="teams", "exo", "defender", "aad", "powerplatform", "sharepoint"
                        AnObject=@{name='MyObjectName'}
                        M365Environment='commercial'
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
            It 'Product names sorted'{
                [ScubaConfig]::GetInstance().Configuration.ProductNames[0] | Should -BeExactly 'aad'
            }
            It 'Valid boolean parameter'{
                [ScubaConfig]::GetInstance().Configuration.DisconnectOnExit | Should -Be $false
            }
            It 'Valid object parameter'{
                [ScubaConfig]::GetInstance().Configuration.AnObject.name | Should -Be 'MyObjectName'
            }
        }
    }
}