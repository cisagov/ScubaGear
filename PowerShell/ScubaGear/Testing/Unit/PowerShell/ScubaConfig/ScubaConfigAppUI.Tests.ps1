using module '..\..\..\..\Modules\ScubaConfig\ScubaConfigAppUI.psm1'

InModuleScope ScubaConfigAppUI {

    Describe -tag "Config" -name 'ScubaConfig JSON Configuration Validation' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'configPath')]
            $configPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfig\ScubaConfig_en-US.json"
        }

        Context 'JSON File Structure Validation' {
            It 'Should have a valid JSON configuration file' {
                Test-Path $configPath | Should -BeTrue -Because "Configuration file should exist at expected location"

                { $script:configContent = Get-Content $configPath -Raw | ConvertFrom-Json } | Should -Not -Throw -Because "JSON should be valid and parseable"
                $script:configContent | Should -Not -BeNullOrEmpty
            }

            It 'Should contain all required root keys' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json

                # Define expected root keys based on your current configuration structure
                $expectedRootKeys = @(
                    'Version',
                    'DebugMode',
                    'EnableSearchAndFilter',
                    'localeContext',
                    'localePlaceholder',
                    'localeInfoMessages',
                    'localeErrorMessages',
                    'localePopupMessages',
                    'localeTitles',
                    'defaultAdvancedSettings',
                    'advancedSections',
                    'globalSettings',
                    'products',
                    'M365Environment',
                    'baselineControls',
                    'baselines',
                    'inputTypes',
                    'valueValidations',
                    'graphQueries'
                )

                foreach ($key in $expectedRootKeys) {
                    $configContent.PSObject.Properties.Name | Should -Contain $key -Because "Root key '$key' should be present in configuration"
                }
            }

            It 'Should have valid version format' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.Version | Should -Match '^\d+\.\d+\.\d+' -Because "Version should start with semantic versioning format (x.y.z)"
            }

            It 'Should have valid DebugMode values' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.DebugMode | Should -BeOfType [System.Boolean] -Because "DebugMode should be a boolean value"
            }

            It 'Should have valid EnableSearchAndFilter values' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.EnableSearchAndFilter | Should -BeOfType [System.Boolean] -Because "EnableSearchAndFilter should be a boolean value"
            }
        }

        Context 'Products Configuration Validation' {
            It 'Should have products array with required properties' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.products | Should -Not -BeNullOrEmpty

                # Ensure products is treated as an array (handle single item case)
                $productsArray = @($configContent.products)
                $productsArray.Count | Should -BeGreaterThan 0 -Because "Should have at least one product"

                foreach ($product in $productsArray) {
                    $product.PSObject.Properties.Name | Should -Contain 'id' -Because "Each product should have an 'id' property"
                    $product.PSObject.Properties.Name | Should -Contain 'name' -Because "Each product should have a 'name' property"
                    $product.PSObject.Properties.Name | Should -Contain 'displayName' -Because "Each product should have a 'displayName' property"
                    $product.PSObject.Properties.Name | Should -Contain 'supportsExclusions' -Because "Each product should have a 'supportsExclusions' property"

                    $product.id | Should -Not -BeNullOrEmpty
                    $product.supportsExclusions | Should -BeOfType [System.Boolean]
                }
            }
        }

        Context 'M365Environment Configuration Validation' {
            It 'Should have M365Environment array with required properties' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.M365Environment | Should -Not -BeNullOrEmpty

                # Ensure M365Environment is treated as an array (handle single item case)
                $environmentsArray = @($configContent.M365Environment)
                $environmentsArray.Count | Should -BeGreaterThan 0 -Because "Should have at least one environment"

                foreach ($env in $environmentsArray) {
                    $env.PSObject.Properties.Name | Should -Contain 'id' -Because "Each environment should have an 'id' property"
                    $env.PSObject.Properties.Name | Should -Contain 'name' -Because "Each environment should have a 'name' property"
                    $env.PSObject.Properties.Name | Should -Contain 'displayName' -Because "Each environment should have a 'displayName' property"

                    $env.id | Should -Not -BeNullOrEmpty
                    $env.name | Should -Not -BeNullOrEmpty
                }
            }
        }

        Context 'BaselineControls Configuration Validation' {
            It 'Should have baselineControls array with required properties' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.baselineControls | Should -Not -BeNullOrEmpty

                # Ensure baselineControls is treated as an array (handle single item case)
                $controlsArray = @($configContent.baselineControls)
                $controlsArray.Count | Should -BeGreaterThan 0 -Because "Should have at least one baseline control"

                $requiredProperties = @('tabName', 'yamlValue', 'controlType', 'dataControlOutput', 'fieldControlName', 'defaultFields', 'cardName', 'showFieldType', 'showDescription', 'supportsAllProducts')

                foreach ($control in $controlsArray) {
                    foreach ($property in $requiredProperties) {
                        $control.PSObject.Properties.Name | Should -Contain $property -Because "Each baseline control should have a '$property' property"
                    }
                }
            }
        }

        Context 'GlobalSettings Configuration Validation' {
            It 'Should have globalSettings with sectionName and fields' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.globalSettings | Should -Not -BeNullOrEmpty

                $configContent.globalSettings.PSObject.Properties.Name | Should -Contain 'sectionName' -Because "GlobalSettings should have a 'sectionName' property"
                $configContent.globalSettings.PSObject.Properties.Name | Should -Contain 'fields' -Because "GlobalSettings should have a 'fields' property"

                $configContent.globalSettings.sectionName | Should -Not -BeNullOrEmpty
                $configContent.globalSettings.fields | Should -Not -BeNullOrEmpty

                # Ensure fields is treated as an array
                $fieldsArray = @($configContent.globalSettings.fields)
                $fieldsArray.Count | Should -BeGreaterThan 0 -Because "GlobalSettings should have at least one field"
            }
        }

        Context 'AdvancedSections Configuration Validation' {
            It 'Should have advancedSections with required structure' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.advancedSections | Should -Not -BeNullOrEmpty

                foreach ($section in $configContent.advancedSections.PSObject.Properties) {
                    $sectionObj = $section.Value
                    $sectionObj.PSObject.Properties.Name | Should -Contain 'sectionName' -Because "Advanced section '$($section.Name)' should have a 'sectionName' property"
                    $sectionObj.PSObject.Properties.Name | Should -Contain 'fields' -Because "Advanced section '$($section.Name)' should have a 'fields' property"

                    $sectionObj.sectionName | Should -Not -BeNullOrEmpty
                    # Fields array can be empty, so just check it exists
                    $sectionObj.fields | Should -Not -BeNull
                }
            }
        }

        Context 'Locale Messages Validation' {
            It 'Should have non-empty locale message sections' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json

                $localeMessageSections = @('localeContext', 'localePlaceholder', 'localeInfoMessages', 'localeErrorMessages', 'localePopupMessages', 'localeTitles')

                foreach ($section in $localeMessageSections) {
                    $configContent.$section | Should -Not -BeNullOrEmpty -Because "Locale section '$section' should not be empty"
                    $configContent.$section.PSObject.Properties.Count | Should -BeGreaterThan 0 -Because "Locale section '$section' should contain message definitions"
                }
            }
        }

        Context 'ValueValidations Configuration Validation' {
            It 'Should have valueValidations with format properties' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.valueValidations | Should -Not -BeNullOrEmpty

                foreach ($validation in $configContent.valueValidations.PSObject.Properties) {
                    $validationObj = $validation.Value
                    $validationObj.PSObject.Properties.Name | Should -Contain 'format' -Because "Validation '$($validation.Name)' should have a 'format' property"
                    $validationObj.format | Should -Not -BeNullOrEmpty
                }
            }
        }

        Context 'GraphQueries Configuration Validation' {
            It 'Should have graphQueries with required properties' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.graphQueries | Should -Not -BeNullOrEmpty

                foreach ($query in $configContent.graphQueries.PSObject.Properties) {
                    $queryObj = $query.Value
                    $queryObj.PSObject.Properties.Name | Should -Contain 'tipProperty' -Because "Graph query '$($query.Name)' should have a 'tipProperty' property"
                    $queryObj.tipProperty | Should -Not -BeNullOrEmpty
                }
            }
        }

        Context 'Baselines Configuration Validation' {
            It 'Should have baselines for each product' {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
                $configContent.baselines | Should -Not -BeNullOrEmpty

                # Verify baselines exist for each product
                $productsArray = @($configContent.products)
                foreach ($product in $productsArray) {
                    # Convert product id to lowercase for baseline lookup
                    $baselineKey = $product.id.ToLower()
                    $configContent.baselines.PSObject.Properties.Name | Should -Contain $baselineKey -Because "Baselines should exist for product '$($product.id)' as '$baselineKey'"

                    $productBaselines = $configContent.baselines.$baselineKey
                    $productBaselines | Should -Not -BeNullOrEmpty -Because "Product '$($product.id)' should have baseline policies"

                    # Ensure baselines is treated as an array (handle single item case)
                    $baselinesArray = @($productBaselines)
                    $baselinesArray.Count | Should -BeGreaterThan 0 -Because "Product '$($product.id)' should have at least one baseline policy"
                }
            }
        }
    }

    Describe -tag "UI" -name 'ScubaConfigAppUI XAML Validation' {
        BeforeAll {
            # Mock the UI launch function to prevent actual UI from showing
            Mock -CommandName Start-ScubaConfigAppUI { return $true }

            # Helper function to test XAML parsing without UI launch
            function Test-XamlValidity {
                param([string]$XamlPath)

                try {
                    # Load assemblies needed for XAML parsing
                    [System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | Out-Null
                    [System.Reflection.Assembly]::LoadWithPartialName('PresentationCore') | Out-Null

                    # Read and process XAML the same way as the main function
                    [string]$XAML = (Get-Content $XamlPath -ReadCount 0) -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window' -replace 'Click=".*','/>'
                    [xml]$UIXML = $XAML
                    $reader = New-Object System.Xml.XmlNodeReader ([xml]$UIXML)

                    # Try to load the XAML - this will throw if invalid
                    $window = [Windows.Markup.XamlReader]::Load($reader)

                    return @{
                        IsValid = $true
                        Window = $window
                        Error = $null
                    }
                }
                catch {
                    return @{
                        IsValid = $false
                        Window = $null
                        Error = $_.Exception.Message
                    }
                }
            }
        }

        Context 'XAML File Validation' {
            It 'Should have a valid XAML file' {
                $xamlPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfig\ScubaConfigAppUI.xaml"
                Test-Path $xamlPath | Should -BeTrue

                $result = Test-XamlValidity -XamlPath $xamlPath
                $result.IsValid | Should -BeTrue -Because "XAML should be valid: $($result.Error)"
            }

            It 'Should contain required UI elements' {
                $xamlPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfig\ScubaConfigAppUI.xaml"
                $result = Test-XamlValidity -XamlPath $xamlPath

                $result.IsValid | Should -BeTrue
                $result.Window | Should -Not -BeNullOrEmpty

                # Test for specific named elements that should exist in the XAML
                $result.Window.FindName("MainTabControl") | Should -Not -BeNullOrEmpty -Because "MainTabControl should exist in XAML"
                $result.Window.FindName("PreviewButton") | Should -Not -BeNullOrEmpty -Because "PreviewButton should exist in XAML"
                $result.Window.FindName("ImportButton") | Should -Not -BeNullOrEmpty -Because "ImportButton should exist in XAML"
                $result.Window.FindName("NewSessionButton") | Should -Not -BeNullOrEmpty -Because "NewSessionButton should exist in XAML"
            }
        }

        Context 'Mocked UI Function' {
            It 'Should not launch actual UI when mocked' {
                # This should return true without launching UI
                Start-ScubaConfigAppUI | Should -BeTrue

                # Verify the mock was called
                Should -Invoke -CommandName Start-ScubaConfigAppUI -Exactly -Times 1
            }
        }
    }
}