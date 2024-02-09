using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigLoadConfig' {
        context 'Handling repeated LoadConfig invocations' {
            It 'Load valid config file followed by another'{
                $cfg = [ScubaConfig]::GetInstance()
		# Load the first file and check the ProductNames value.
                $file1 = Join-Path -Path $PSScriptRoot -ChildPath config_test_load_config1.json
                $cfg.LoadConfig($file1)
                $cfg.Configuration.ProductNames | Should -Be 'teams'
		# Load the second file and verify that ProductNames has changed.
                $file2 = Join-Path -Path $PSScriptRoot -ChildPath config_test_load_config2.json
                $cfg.LoadConfig($file2)
                $cfg.Configuration.ProductNames | Should -Be 'exo'
            }
            AfterAll {
                [ScubaConfig]::ResetInstance()
            }
        }
    }
}
