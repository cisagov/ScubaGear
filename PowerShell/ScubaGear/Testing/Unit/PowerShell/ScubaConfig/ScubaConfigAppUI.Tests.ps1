using module '..\..\..\..\Modules\ScubaConfig\ScubaConfigAppUI.psm1'

InModuleScope ScubaConfigAppUI {

    Describe -tag "Config" -name 'ScubaConfig JSON Configuration Validation' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'uiConfigPath')]
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'baselineConfigPath')]
            $uiConfigPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfig\ScubaConfigAppUI_Control_en-US.json"
            $baselineConfigPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfig\ScubaBaselines_en-US.json"
        }

        Context 'JSON File Structure Validation' {
            It 'Should have valid UI configuration file' {
                Test-Path $uiConfigPath | Should -BeTrue -Because "UI configuration file should exist at expected location"

                { $script:uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json } | Should -Not -Throw -Because "UI config JSON should be valid and parseable"
                $script:uiConfigContent | Should -Not -BeNullOrEmpty
            }

            It 'Should have valid baseline configuration file' {
                Test-Path $baselineConfigPath | Should -BeTrue -Because "Baseline configuration file should exist at expected location"

                { $script:baselineConfigContent = Get-Content $baselineConfigPath -Raw | ConvertFrom-Json } | Should -Not -Throw -Because "Baseline config JSON should be valid and parseable"
                $script:baselineConfigContent | Should -Not -BeNullOrEmpty
            }

            It 'Should contain all required UI configuration root keys' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json

                # Define expected root keys for UI configuration
                $expectedUIRootKeys = @(
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
                    'inputTypes',
                    'valueValidations',
                    'graphQueries'
                )

                foreach ($key in $expectedUIRootKeys) {
                    $uiConfigContent.PSObject.Properties.Name | Should -Contain $key -Because "UI config root key '$key' should be present in configuration"
                }
            }

            It 'Should contain all required baseline configuration root keys' {
                $baselineConfigContent = Get-Content $baselineConfigPath -Raw | ConvertFrom-Json

                # Define expected root keys for baseline configuration
                $expectedBaselineRootKeys = @(
                    'baselines'
                )

                foreach ($key in $expectedBaselineRootKeys) {
                    $baselineConfigContent.PSObject.Properties.Name | Should -Contain $key -Because "Baseline config root key '$key' should be present in configuration"
                }
            }

            It 'Should have valid version format' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.Version | Should -Match '^\d+\.\d+\.\d+' -Because "Version should start with semantic versioning format (x.y.z)"
            }

            It 'Should have valid DebugMode values' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.DebugMode | Should -BeOfType [System.Boolean] -Because "DebugMode should be a boolean value"
            }

            It 'Should have valid EnableSearchAndFilter values' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.EnableSearchAndFilter | Should -BeOfType [System.Boolean] -Because "EnableSearchAndFilter should be a boolean value"
            }
        }

        Context 'Products Configuration Validation' {
            It 'Should have products array with required properties' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.products | Should -Not -BeNullOrEmpty

                # Ensure products is treated as an array (handle single item case)
                $productsArray = @($uiConfigContent.products)
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
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.M365Environment | Should -Not -BeNullOrEmpty

                # Ensure M365Environment is treated as an array (handle single item case)
                $environmentsArray = @($uiConfigContent.M365Environment)
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
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.baselineControls | Should -Not -BeNullOrEmpty

                # Ensure baselineControls is treated as an array (handle single item case)
                $controlsArray = @($uiConfigContent.baselineControls)
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
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.globalSettings | Should -Not -BeNullOrEmpty

                $uiConfigContent.globalSettings.PSObject.Properties.Name | Should -Contain 'sectionName' -Because "GlobalSettings should have a 'sectionName' property"
                $uiConfigContent.globalSettings.PSObject.Properties.Name | Should -Contain 'fields' -Because "GlobalSettings should have a 'fields' property"

                $uiConfigContent.globalSettings.sectionName | Should -Not -BeNullOrEmpty
                $uiConfigContent.globalSettings.fields | Should -Not -BeNullOrEmpty

                # Ensure fields is treated as an array
                $fieldsArray = @($uiConfigContent.globalSettings.fields)
                $fieldsArray.Count | Should -BeGreaterThan 0 -Because "GlobalSettings should have at least one field"
            }
        }

        Context 'AdvancedSections Configuration Validation' {
            It 'Should have advancedSections with required structure' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.advancedSections | Should -Not -BeNullOrEmpty

                foreach ($section in $uiConfigContent.advancedSections.PSObject.Properties) {
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
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json

                $localeMessageSections = @('localeContext', 'localePlaceholder', 'localeInfoMessages', 'localeErrorMessages', 'localePopupMessages', 'localeTitles')

                foreach ($section in $localeMessageSections) {
                    $uiConfigContent.$section | Should -Not -BeNullOrEmpty -Because "Locale section '$section' should not be empty"
                    $uiConfigContent.$section.PSObject.Properties.Count | Should -BeGreaterThan 0 -Because "Locale section '$section' should contain message definitions"
                }
            }
        }

        Context 'ValueValidations Configuration Validation' {
            It 'Should have valueValidations with format properties' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.valueValidations | Should -Not -BeNullOrEmpty

                foreach ($validation in $uiConfigContent.valueValidations.PSObject.Properties) {
                    $validationObj = $validation.Value
                    $validationObj.PSObject.Properties.Name | Should -Contain 'format' -Because "Validation '$($validation.Name)' should have a 'format' property"
                    $validationObj.format | Should -Not -BeNullOrEmpty
                }
            }
        }

        Context 'GraphQueries Configuration Validation' {
            It 'Should have graphQueries with required properties' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.graphQueries | Should -Not -BeNullOrEmpty

                foreach ($query in $uiConfigContent.graphQueries.PSObject.Properties) {
                    $queryObj = $query.Value
                    $queryObj.PSObject.Properties.Name | Should -Contain 'tipProperty' -Because "Graph query '$($query.Name)' should have a 'tipProperty' property"
                    $queryObj.tipProperty | Should -Not -BeNullOrEmpty
                }
            }
        }

        Context 'Baselines Configuration Validation' {
            It 'Should have baselines for each product' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $baselineConfigContent = Get-Content $baselineConfigPath -Raw | ConvertFrom-Json
                
                $baselineConfigContent.baselines | Should -Not -BeNullOrEmpty

                # Verify baselines exist for each product
                $productsArray = @($uiConfigContent.products)
                foreach ($product in $productsArray) {
                    # Convert product id to lowercase for baseline lookup
                    $baselineKey = $product.id.ToLower()
                    $baselineConfigContent.baselines.PSObject.Properties.Name | Should -Contain $baselineKey -Because "Baselines should exist for product '$($product.id)' as '$baselineKey'"

                    $productBaselines = $baselineConfigContent.baselines.$baselineKey
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