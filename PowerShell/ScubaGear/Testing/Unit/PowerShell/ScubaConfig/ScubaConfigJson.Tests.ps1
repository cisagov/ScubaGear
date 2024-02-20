using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigJson' {
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
            BeforeAll {
                function Get-ScubaDefault {throw 'this will be mocked'}
                Mock -ModuleName ScubaConfig Get-ScubaDefault {"."}
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ScubaConfigTestFile')]
                $ScubaConfigTestFile = Join-Path -Path $PSScriptRoot -ChildPath config_test.json
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Result')]
                $Result = [ScubaConfig]::GetInstance().LoadConfig($ScubaConfigTestFile)
                function Get-ScubaDefault {throw 'this will be mocked'}
                Mock -ModuleName ScubaConfig Get-ScubaDefault {"."}
            }
            It 'Load valid config file'{
                $Result | Should -Be $true
            }
            It 'Valid string parameter'{
                [ScubaConfig]::GetInstance().Configuration.M365Environment | Should -Be 'commercial'
            }
            It 'Valid array parameter'{
                [ScubaConfig]::GetInstance().Configuration.ProductNames | Should -Contain 'entraid'
            }
            It 'Product names sorted'{
                [ScubaConfig]::GetInstance().Configuration.ProductNames[0] | Should -BeExactly 'entraid'
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