using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigJson' {
        context 'JSON Configuration' {
            BeforeEach{
                [ScubaConfig]::ResetInstance()
                $ScubaConfigTestFile = Join-Path -Path $PSScriptRoot -ChildPath config_test_duplicate_provider.json
                $Config = [ScubaConfig]::GetInstance()
		$Config.LoadConfig($ScubaConfigTestFile)
            }
            It 'Should not contain duplicate product names'{
                $Config.Configuration.ProductNames | Should -BeExactly @('aad')
            }
	    AfterAll {
              [ScubaConfig]::ResetInstance()
            }
        }
    }
}

