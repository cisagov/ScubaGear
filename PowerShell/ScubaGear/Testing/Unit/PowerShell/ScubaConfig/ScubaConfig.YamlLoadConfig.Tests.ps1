using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
    Describe -tag "Utils" -name 'ScubaConfigLoadConfig' {
        BeforeAll {
            Mock -CommandName Write-Warning {}
            function Get-ScubaDefault {throw 'this will be mocked'}
            Mock -ModuleName ScubaConfig Get-ScubaDefault {"."}
            Remove-Item function:\ConvertFrom-Yaml -ErrorAction SilentlyContinue
        }

        AfterAll {
            # Reset instance after all tests in this file
            [ScubaConfig]::ResetInstance()
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
            BeforeAll {
                # Create a temporary YAML file for testing
                $script:TempConfigFile = [System.IO.Path]::GetTempFileName()
                $script:TempConfigFile = [System.IO.Path]::ChangeExtension($script:TempConfigFile, '.yaml')
                "ProductNames: ['aad']" | Set-Content -Path $script:TempConfigFile
            }
            It 'Load valid config file followed by another'{
                $cfg = [ScubaConfig]::GetInstance()
                # Load the first file and check the ProductNames value.
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('teams')
                        M365Environment='commercial'
                    }
                }
                [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile, $true) | Should -BeTrue
                $cfg.Configuration.ProductNames | Should -Be 'teams'
                # Load the second file and verify that ProductNames has changed.
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('exo')
                        M365Environment='commercial'
                    }
                }
                [ScubaConfig]::GetInstance().LoadConfig($script:TempConfigFile, $true) | Should -BeTrue
                $cfg.Configuration.ProductNames | Should -Be 'exo'
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }
            AfterAll {
                [ScubaConfig]::ResetInstance()
                if (Test-Path $script:TempConfigFile) {
                    Remove-Item $script:TempConfigFile -Force
                }
            }
        }

        context 'Deferred Validation with SkipValidation Parameter' {
            BeforeAll {
                # Create a temporary YAML file with valid content
                $script:ValidConfigFile = [System.IO.Path]::GetTempFileName()
                $script:ValidConfigFile = [System.IO.Path]::ChangeExtension($script:ValidConfigFile, '.yaml')
                @"
ProductNames:
  - aad
M365Environment: commercial
"@ | Set-Content -Path $script:ValidConfigFile -Encoding UTF8

                # Create a temporary YAML file with invalid content that will be overridden
                $script:InvalidConfigFile = [System.IO.Path]::GetTempFileName()
                $script:InvalidConfigFile = [System.IO.Path]::ChangeExtension($script:InvalidConfigFile, '.yaml')
                @"
ProductNames:
  - invalid-product
M365Environment: invalid-env
"@ | Set-Content -Path $script:InvalidConfigFile -Encoding UTF8
            }

            It 'LoadConfig with SkipValidation=$false should validate immediately'{
                # Create valid config file for this test
                $validFile = [System.IO.Path]::GetTempFileName()
                $validFile = [System.IO.Path]::ChangeExtension($validFile, '.yaml')
                "ProductNames: ['aad']" | Set-Content -Path $validFile

                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('aad')
                        M365Environment='commercial'
                    }
                }

                try {
                    # Should succeed with valid config
                    {[ScubaConfig]::GetInstance().LoadConfig($validFile, $false)} | Should -Not -Throw
                    [ScubaConfig]::ResetInstance()

                    # Create invalid config file with truly invalid product
                    $invalidFile = [System.IO.Path]::GetTempFileName()
                    $invalidFile = [System.IO.Path]::ChangeExtension($invalidFile, '.yaml')
                    "ProductNames: ['invalid']" | Set-Content -Path $invalidFile

                    function global:ConvertFrom-Yaml {
                        @{
                            ProductNames=@('thisproductdoesnotexist')
                        }
                    }

                    # Should fail with invalid config
                    {[ScubaConfig]::GetInstance().LoadConfig($invalidFile, $false)} | Should -Throw
                }
                finally {
                    [ScubaConfig]::ResetInstance()
                    if (Test-Path $validFile) { Remove-Item $validFile -Force }
                    if (Test-Path $invalidFile) { Remove-Item $invalidFile -Force }
                }
            }

            It 'LoadConfig with SkipValidation=$true should skip business rule validation'{
                # Create config with invalid values
                $testFile = [System.IO.Path]::GetTempFileName()
                $testFile = [System.IO.Path]::ChangeExtension($testFile, '.yaml')
                "ProductNames: ['invalid']" | Set-Content -Path $testFile

                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('invalid-product')
                        M365Environment='invalid-env'
                    }
                }

                try {
                    # Should load without error even with invalid values
                    {[ScubaConfig]::GetInstance().LoadConfig($testFile, $true)} | Should -Not -Throw

                    # Configuration should be loaded
                    $cfg = [ScubaConfig]::GetInstance()
                    $cfg.Configuration.ProductNames | Should -Contain 'invalid-product'
                    $cfg.Configuration.M365Environment | Should -Be 'invalid-env'
                }
                finally {
                    [ScubaConfig]::ResetInstance()
                    if (Test-Path $testFile) { Remove-Item $testFile -Force }
                }
            }

            It 'ValidateConfiguration should validate current configuration state'{
                # Create config with invalid values
                $testFile = [System.IO.Path]::GetTempFileName()
                $testFile = [System.IO.Path]::ChangeExtension($testFile, '.yaml')
                "ProductNames: ['invalid']" | Set-Content -Path $testFile

                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('invalid-product')
                    }
                }

                try {
                    # Load with validation skipped
                    [ScubaConfig]::GetInstance().LoadConfig($testFile, $true)

                    # ValidateConfiguration should fail on invalid data
                    $cfg = [ScubaConfig]::GetInstance()
                    {$cfg.ValidateConfiguration()} | Should -Throw
                }
                finally {
                    [ScubaConfig]::ResetInstance()
                    if (Test-Path $testFile) { Remove-Item $testFile -Force }
                }
            }

            It 'Override invalid config value then validate should succeed'{
                # Create config with invalid M365Environment
                $testFile = [System.IO.Path]::GetTempFileName()
                $testFile = [System.IO.Path]::ChangeExtension($testFile, '.yaml')
                "M365Environment: gcch" | Set-Content -Path $testFile

                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('aad')
                        M365Environment='gcch'  # Invalid value
                    }
                }

                try {
                    # Load config without validation
                    [ScubaConfig]::GetInstance().LoadConfig($testFile, $true) | Should -BeTrue

                    # Verify invalid value was loaded
                    $cfg = [ScubaConfig]::GetInstance()
                    $cfg.Configuration.M365Environment | Should -Be 'gcch'

                    # Override with valid value (simulating command-line parameter)
                    $cfg.Configuration.M365Environment = 'gcchigh'

                    # Validation should now succeed
                    {$cfg.ValidateConfiguration()} | Should -Not -Throw

                    # Verify the override persisted
                    $cfg.Configuration.M365Environment | Should -Be 'gcchigh'
                }
                finally {
                    [ScubaConfig]::ResetInstance()
                    if (Test-Path $testFile) { Remove-Item $testFile -Force }
                }
            }

            It 'Default LoadConfig() without parameters should validate immediately'{
                # Create valid config
                $validFile = [System.IO.Path]::GetTempFileName()
                $validFile = [System.IO.Path]::ChangeExtension($validFile, '.yaml')
                "ProductNames: ['aad']" | Set-Content -Path $validFile

                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('aad')
                        M365Environment='commercial'
                    }
                }

                try {
                    # Default behavior should still validate
                    {[ScubaConfig]::GetInstance().LoadConfig($validFile)} | Should -Not -Throw
                    [ScubaConfig]::ResetInstance()

                    # Create invalid config
                    $invalidFile = [System.IO.Path]::GetTempFileName()
                    $invalidFile = [System.IO.Path]::ChangeExtension($invalidFile, '.yaml')
                    "ProductNames: ['invalid']" | Set-Content -Path $invalidFile

                    function global:ConvertFrom-Yaml {
                        @{
                            ProductNames=@('invalid-product')
                        }
                    }

                    {[ScubaConfig]::GetInstance().LoadConfig($invalidFile)} | Should -Throw
                }
                finally {
                    [ScubaConfig]::ResetInstance()
                    if (Test-Path $validFile) { Remove-Item $validFile -Force }
                    if (Test-Path $invalidFile) { Remove-Item $invalidFile -Force }
                }
            }

            AfterAll {
                [ScubaConfig]::ResetInstance()
                if (Test-Path $script:ValidConfigFile) {
                    Remove-Item $script:ValidConfigFile -Force
                }
                if (Test-Path $script:InvalidConfigFile) {
                    Remove-Item $script:InvalidConfigFile -Force
                }
            }
        }

    }
}