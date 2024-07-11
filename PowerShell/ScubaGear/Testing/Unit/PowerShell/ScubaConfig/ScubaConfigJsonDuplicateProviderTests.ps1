using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigJson' {
        context 'JSON Configuration' {
            BeforeEach{
                [ScubaConfig]::ResetInstance()
                $Config = [ScubaConfig]::GetInstance()
                $Config.Configuration.ProductNames = @('aad', 'aad')
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

