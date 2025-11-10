using module '..\..\..\..\Modules\ScubaConfig\ScubaConfigValidator.psm1'
using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

InModuleScope ScubaConfig {
Describe "JSON-based Configuration System" {
    BeforeAll {
        # Initialize the system
        [ScubaConfig]::InitializeValidator()
    }

    Context "System Initialization" {
        It "Should initialize the validator successfully" {
            { [ScubaConfig]::InitializeValidator() } | Should -Not -Throw
        }

        It "Should load configuration defaults from JSON" {
            $defaults = [ScubaConfig]::GetConfigDefaults()
            $defaults | Should -Not -BeNullOrEmpty
        }

        It "Should load configuration schema from JSON" {
            $schema = [ScubaConfig]::GetConfigSchema()
            $schema | Should -Not -BeNullOrEmpty
        }
    }

    Context "Default Values from JSON" {
        It "Should read DisconnectOnExit default as false from JSON" {
            $disconnectDefault = [ScubaConfig]::ScubaDefault('DefaultDisconnectOnExit')
            $disconnectDefault | Should -Be $false
        }

        It "Should read LogIn default as true from JSON" {
            $loginDefault = [ScubaConfig]::ScubaDefault('DefaultLogIn')
            $loginDefault | Should -Be $true
        }

        It "Should read OPAVersion default from JSON" {
            $opaVersion = [ScubaConfig]::ScubaDefault('DefaultOPAVersion')
            $opaVersion | Should -Be "1.9.0"
        }

        It "Should read M365Environment default as commercial from JSON" {
            $environment = [ScubaConfig]::ScubaDefault('DefaultM365Environment')
            $environment | Should -Be "commercial"
        }

        It "Should read ProductNames default from JSON" {
            $productNames = [ScubaConfig]::ScubaDefault('DefaultProductNames')
            $productNames | Should -Contain "aad"
            $productNames | Should -Contain "defender"
            $productNames | Should -Contain "exo"
        }

        It "Should read OutFolderName default from JSON" {
            $folderName = [ScubaConfig]::ScubaDefault('DefaultOutFolderName')
            $folderName | Should -Be "M365BaselineConformance"
        }
    }

    Context "JSON Structure Validation" {
        It "Should have products defined in defaults" {
            $defaults = [ScubaConfig]::GetConfigDefaults()
            $defaults.products | Should -Not -Be NullOrEmpty
            $defaults.products.PSObject.Properties.Count | Should -BeGreaterThan 0
        }

        It "Should have environments defined in defaults" {
            $defaults = [ScubaConfig]::GetConfigDefaults()
            $defaults.M365Environment | Should -Not -BeNullOrEmpty
            $defaults.M365Environment.PSObject.Properties.Count | Should -BeGreaterThan 0
        }

        It "Should have validation settings defined" {
            $defaults = [ScubaConfig]::GetConfigDefaults()
            $defaults.validation | Should -Not -BeNullOrEmpty
            $defaults.validation.policyIdPattern | Should -Not -BeNullOrEmpty
        }

        It "Should have privileged roles defined" {
            $defaults = [ScubaConfig]::GetConfigDefaults()
            $defaults.privilegedRoles | Should -Not -BeNullOrEmpty
            $defaults.privilegedRoles.Count | Should -BeGreaterThan 0
        }
    }

    Context "Product Information" {
        It "Should provide product information for supported products" {
            $aadInfo = [ScubaConfig]::GetProductInfo('aad')
            $aadInfo | Should -Not -BeNullOrEmpty
            $aadInfo.name | Should -Be "Microsoft Entra ID"
        }

        It "Should return supported products list" {
            $supportedProducts = [ScubaConfig]::GetSupportedProducts()
            $supportedProducts | Should -Contain "aad"
            $supportedProducts | Should -Contain "defender"
        }

        It "Should return supported environments list" {
            $supportedEnvironments = [ScubaConfig]::GetSupportedEnvironments()
            $supportedEnvironments | Should -Contain "commercial"
            $supportedEnvironments | Should -Contain "gcc"
        }
    }

    Context "No Hardcoded Values" {
        It "Should not use hardcoded DisconnectOnExit value" {
            # This test ensures the value comes from JSON, not hardcoded
            $jsonDefaults = Get-Content "$PSScriptRoot\..\..\..\..\Modules\ScubaConfig\ScubaConfigDefaults.json" | ConvertFrom-Json
            $jsonValue = $jsonDefaults.defaults.DisconnectOnExit
            $configValue = [ScubaConfig]::ScubaDefault('DefaultDisconnectOnExit')
            $configValue | Should -Be $jsonValue
        }

        It "Should read all default values from JSON file" {
            $jsonDefaults = Get-Content "$PSScriptRoot\..\..\..\..\Modules\ScubaConfig\ScubaConfigDefaults.json" | ConvertFrom-Json

            # Test key values match between JSON and ScubaConfig
            [ScubaConfig]::ScubaDefault('DefaultLogIn') | Should -Be $jsonDefaults.defaults.LogIn
            [ScubaConfig]::ScubaDefault('DefaultM365Environment') | Should -Be $jsonDefaults.defaults.M365Environment
            [ScubaConfig]::ScubaDefault('DefaultOPAVersion') | Should -Be $jsonDefaults.defaults.OPAVersion
        }
    }

    AfterAll {
        [ScubaConfig]::ResetInstance()
    }
}
}
