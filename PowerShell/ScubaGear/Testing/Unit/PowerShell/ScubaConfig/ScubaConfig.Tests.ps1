using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe "ScubaConfig Module Unit Tests" {
    BeforeEach {
        # Reset the instance before each test to prevent state bleed
        [ScubaConfig]::ResetInstance()
    }

    AfterEach {
        # Reset the instance after each test to prevent state bleed
        [ScubaConfig]::ResetInstance()
    }

    AfterAll {
        # Clean up after tests
        [ScubaConfig]::ResetInstance()
    }

    Context "Class Structure and Properties" {
        It "Should be a valid PowerShell class" {
            [ScubaConfig] | Should -Not -BeNullOrEmpty
            [ScubaConfig].Name | Should -Be "ScubaConfig"
        }

        It "Should have required static properties" {
            # Check that the class has static members - the private properties aren't directly accessible
            [ScubaConfig] | Get-Member -Static | Should -Not -BeNullOrEmpty
        }

        It "Should have required instance properties" {
            $Instance = [ScubaConfig]::GetInstance()

            # Instance should be created successfully and be usable
            $Instance | Should -Not -BeNullOrEmpty
            $Instance.GetType().Name | Should -Be "ScubaConfig"
        }

        It "Should have required static methods" {
            $StaticMethods = [ScubaConfig] | Get-Member -Static -MemberType Method | Select-Object -ExpandProperty Name

            $StaticMethods | Should -Contain "GetInstance"
            $StaticMethods | Should -Contain "ResetInstance"
            $StaticMethods | Should -Contain "InitializeValidator"
            $StaticMethods | Should -Contain "ScubaDefault"
            $StaticMethods | Should -Contain "GetConfigDefaults"
            $StaticMethods | Should -Contain "ValidateConfigFile"
            $StaticMethods | Should -Contain "GetSupportedProducts"
            $StaticMethods | Should -Contain "GetSupportedEnvironments"
            $StaticMethods | Should -Contain "GetProductInfo"
            $StaticMethods | Should -Contain "GetPrivilegedRoles"
        }

        It "Should have required instance methods" {
            $Instance = [ScubaConfig]::GetInstance()
            $InstanceMethods = $Instance | Get-Member -MemberType Method | Select-Object -ExpandProperty Name

            $InstanceMethods | Should -Contain "LoadConfig"
            $InstanceMethods | Should -Contain "ValidateConfiguration"
        }
    }

    Context "Singleton Pattern Implementation" {
        It "Should return the same instance on multiple calls" {
            $Instance1 = [ScubaConfig]::GetInstance()
            $Instance2 = [ScubaConfig]::GetInstance()

            $Instance1 | Should -Be $Instance2
            $Instance1.GetHashCode() | Should -Be $Instance2.GetHashCode()
        }

        It "Should create new instance after reset" {
            # Load some configuration into the instance to create state
            $Instance1 = [ScubaConfig]::GetInstance()
            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            "ProductNames: [aad]" | Set-Content -Path $TempFile

            try {
                $Instance1.LoadConfig($TempFile)
                $HasConfig1 = $Instance1.Configuration -ne $null

                [ScubaConfig]::ResetInstance()

                $Instance2 = [ScubaConfig]::GetInstance()
                $HasConfig2 = $Instance2.Configuration -ne $null

                # After reset, new instance should not have the old configuration
                $HasConfig1 | Should -Be $true
                $HasConfig2 | Should -Be $false
            }
            finally {
                Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
            }
        }

        It "Should properly initialize on first access" {
            [ScubaConfig]::ResetInstance()

            # Should not throw when getting instance
            { [ScubaConfig]::GetInstance() } | Should -Not -Throw

            # Should have initialized the validator
            [ScubaConfig]::_ValidatorInitialized | Should -Be $true
        }
    }

    Context "Static Method Functionality" {
        It "Should initialize validator without errors" {
            { [ScubaConfig]::InitializeValidator() } | Should -Not -Throw
        }

        It "Should get configuration defaults" {
            $Defaults = [ScubaConfig]::GetConfigDefaults()

            $Defaults | Should -Not -BeNullOrEmpty
            $Defaults | Should -BeOfType [PSCustomObject]
        }

        It "Should get supported products as array" {
            $Products = [ScubaConfig]::GetSupportedProducts()

            $Products | Should -Not -BeNullOrEmpty
            # Ensure it's iterable (could be array or single value)
            $ProductsArray = @($Products)
            $ProductsArray.Count | Should -BeGreaterThan 0
        }

        It "Should get supported environments as array" {
            $Environments = [ScubaConfig]::GetSupportedEnvironments()

            $Environments | Should -Not -BeNullOrEmpty
            # Ensure it's iterable (could be array or single value)
            $EnvironmentsArray = @($Environments)
            $EnvironmentsArray.Count | Should -BeGreaterThan 0
        }

        It "Should get product info for valid products" {
            $Products = [ScubaConfig]::GetSupportedProducts()
            $FirstProduct = $Products[0]

            $ProductInfo = [ScubaConfig]::GetProductInfo($FirstProduct)

            $ProductInfo | Should -Not -BeNullOrEmpty
            $ProductInfo | Should -BeOfType [PSCustomObject]
        }

        It "Should get privileged roles as array" {
            $Roles = [ScubaConfig]::GetPrivilegedRoles()

            $Roles | Should -Not -BeNullOrEmpty
            # Ensure it's iterable (could be array or single value)
            $RolesArray = @($Roles)
            $RolesArray.Count | Should -BeGreaterThan 0
        }

        It "Should provide backward compatibility with ScubaDefault method" {
            { [ScubaConfig]::ScubaDefault('DefaultOPAVersion') } | Should -Not -Throw
            { [ScubaConfig]::ScubaDefault('DefaultProductNames') } | Should -Not -Throw
            { [ScubaConfig]::ScubaDefault('DefaultM365Environment') } | Should -Not -Throw
        }

        It "Should validate configuration files" {
            # Create a minimal test file
            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            "ProductNames: [aad]" | Set-Content -Path $TempFile

            try {
                $Result = [ScubaConfig]::ValidateConfigFile($TempFile)
                $Result | Should -Not -BeNullOrEmpty
                $Result | Should -BeOfType [PSCustomObject]
                $Result.PSObject.Properties.Name | Should -Contain 'IsValid'
            }
            finally {
                Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "Instance Method Functionality" {
        It "Should have empty configuration initially" {
            $Instance = [ScubaConfig]::GetInstance()

            $Instance.Configuration | Should -BeNullOrEmpty
        }

        It "Should load configuration files" {
            $Instance = [ScubaConfig]::GetInstance()

            # Create a minimal test file
            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            "ProductNames: [aad]" | Set-Content -Path $TempFile

            try {
                { $Instance.LoadConfig($TempFile) } | Should -Not -Throw
            }
            finally {
                Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
            }
        }

        It "Should validate current configuration" {
            $Instance = [ScubaConfig]::GetInstance()

            # Load some configuration first
            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            "ProductNames: [aad]" | Set-Content -Path $TempFile

            try {
                $Instance.LoadConfig($TempFile)
                # Method should exist and be callable
                { $Instance.ValidateConfiguration() } | Should -Not -Throw
            }
            finally {
                Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
            }
        }

        It "Should support skip validation parameter in LoadConfig" {
            $Instance = [ScubaConfig]::GetInstance()

            # Create a minimal test file
            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            "ProductNames: [aad]" | Set-Content -Path $TempFile

            try {
                { $Instance.LoadConfig($TempFile, $true) } | Should -Not -Throw
                { $Instance.LoadConfig($TempFile, $false) } | Should -Not -Throw
            }
            finally {
                Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "Error Handling" {
        It "Should handle invalid file paths gracefully" {
            $Instance = [ScubaConfig]::GetInstance()

            { $Instance.LoadConfig("nonexistent-file.yaml") } | Should -Throw
        }

        It "Should handle invalid product names in GetProductInfo" {
            { [ScubaConfig]::GetProductInfo("InvalidProduct") } | Should -Not -Throw
        }

        It "Should handle invalid ScubaDefault keys" {
            # Invalid keys should throw exceptions as designed
            { [ScubaConfig]::ScubaDefault("InvalidKey") } | Should -Throw
        }
    }

    Context "State Management" {
        It "Should maintain configuration state between calls" {
            $Instance = [ScubaConfig]::GetInstance()

            # Create a test file
            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            "ProductNames: [aad]" | Set-Content -Path $TempFile

            try {
                $Instance.LoadConfig($TempFile)
                $Instance.Configuration | Should -Not -BeNullOrEmpty

                # Get same instance and check configuration persists
                $SameInstance = [ScubaConfig]::GetInstance()
                $SameInstance.Configuration | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
            }
        }

        It "Should clear state on reset" {
            $Instance = [ScubaConfig]::GetInstance()

            # Load some configuration
            $TempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.yaml')
            "ProductNames: [aad]" | Set-Content -Path $TempFile

            try {
                $Instance.LoadConfig($TempFile)
                $Instance.Configuration | Should -Not -BeNullOrEmpty

                # Reset and get new instance
                [ScubaConfig]::ResetInstance()
                $NewInstance = [ScubaConfig]::GetInstance()
                $NewInstance.Configuration | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}