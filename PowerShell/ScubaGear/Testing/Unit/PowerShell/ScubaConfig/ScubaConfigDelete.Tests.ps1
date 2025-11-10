using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigDelete' {
        context 'Delete configuration' {
            BeforeAll{
                [ScubaConfig]::ResetInstance()

                # Create temporary YAML files for testing
                $script:TempConfigFile1 = [System.IO.Path]::GetTempFileName()
                $script:TempConfigFile1 = [System.IO.Path]::ChangeExtension($script:TempConfigFile1, '.yaml')

                $script:TempConfigFile2 = [System.IO.Path]::GetTempFileName()
                $script:TempConfigFile2 = [System.IO.Path]::ChangeExtension($script:TempConfigFile2, '.yaml')

                # First config with multiple products and an object
                @"
ProductNames:
  - teams
  - exo
  - defender
  - aad
  - powerplatform
  - sharepoint
AnObject:
  name: MyObjectName
"@ | Set-Content -Path $script:TempConfigFile1

                # Second config with single product and different object
                @"
ProductNames:
  - teams
MissingObject:
  name: MyMissingObjectName
"@ | Set-Content -Path $script:TempConfigFile2
            }

            It 'Valid config file loads successfully'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile1)
                $Result | Should -Be $true
            }

            It 'Configuration has 6 product names'{
                [ScubaConfig]::GetInstance().Configuration.ProductNames | Should -HaveCount 6
            }

            It 'Configuration has valid object parameter AnObject'{
                [ScubaConfig]::GetInstance().Configuration.AnObject.name | Should -Be 'MyObjectName'
            }

            It 'Configuration does not have MissingObject'{
                [ScubaConfig]::GetInstance().Configuration.MissingObject | Should -BeNullOrEmpty
            }

            It 'Reset instance clears configuration'{
                [ScubaConfig]::ResetInstance()
                [ScubaConfig]::GetInstance().Configuration | Should -BeNullOrEmpty
            }

            It 'Load second config file successfully'{
                $Result = [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile2)
                $Result | Should -Be $true
            }

            It 'Second configuration has 1 product name'{
                $ProductNames = [ScubaConfig]::GetInstance().Configuration.ProductNames
                $ProductNames.Count | Should -Be 1
                $ProductNames | Should -Contain 'teams'
            }

            It 'Second configuration does not have AnObject'{
                [ScubaConfig]::GetInstance().Configuration.AnObject | Should -BeNullOrEmpty
            }

            It 'Second configuration has MissingObject'{
                [ScubaConfig]::GetInstance().Configuration.MissingObject.name | Should -Be 'MyMissingObjectName'
            }

            AfterAll{
                [ScubaConfig]::ResetInstance()
                if (Test-Path $script:TempConfigFile1) {
                    Remove-Item $script:TempConfigFile1 -Force
                }
                if (Test-Path $script:TempConfigFile2) {
                    Remove-Item $script:TempConfigFile2 -Force
                }
            }
        }
    }
}
