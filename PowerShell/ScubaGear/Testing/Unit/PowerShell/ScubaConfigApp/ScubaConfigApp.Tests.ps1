using module '..\..\..\..\Modules\ScubaConfigApp\ScubaConfigApp.psm1'

InModuleScope ScubaConfigApp {

    Describe -tag "Config" -name 'ScubaConfigApp JSON Configuration Validation' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'uiConfigPath')]
            $uiConfigPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigApp_Control_en-US.json"
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'baselineConfigPath')]
            $baselineConfigPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaBaselines_en-US.json"
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

                # Define expected root keys for UI configuration (based on current structure)
                $expectedUIRootKeys = @(
                    'DebugMode',
                    'AutoSaveProgress',
                    'EnableSearchAndFilter',
                    'EnableScubaRun',
                    'EnableResultReader',
                    'MinimumProductsRequired',
                    'localeContext',
                    'localePlaceholder',
                    'localeInfoMessages',
                    'localeErrorMessages',
                    'localePopupMessages',
                    'localeHelpTips',
                    'localeTitles',
                    'defaultAdvancedSettings',
                    'settingsControl',
                    'ScubaRunConfig',
                    'Reports',
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

            It 'Should have valid DebugMode values' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.DebugMode | Should -BeOfType [System.Boolean] -Because "DebugMode should be a boolean value"
            }

            It 'Should have valid AutoSaveProgress values' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.AutoSaveProgress | Should -BeOfType [System.Boolean] -Because "AutoSaveProgress should be a boolean value"
            }

            It 'Should have valid EnableSearchAndFilter values' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.EnableSearchAndFilter | Should -BeOfType [System.Boolean] -Because "EnableSearchAndFilter should be a boolean value"
            }

            It 'Should have valid EnableScubaRun values' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.EnableScubaRun | Should -BeOfType [System.Boolean] -Because "EnableScubaRun should be a boolean value"
            }

            It 'Should have valid EnableResultReader values' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.EnableResultReader | Should -BeOfType [System.Boolean] -Because "EnableResultReader should be a boolean value"
            }

            It 'Should have valid MinimumProductsRequired values' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                # JSON parsing in PowerShell may return [long] for integer values, so accept both [int] and [long]
                $uiConfigContent.MinimumProductsRequired | Should -BeOfType ([System.ValueType]) -Because "MinimumProductsRequired should be a numeric value"
                $uiConfigContent.MinimumProductsRequired | Should -BeGreaterThan 0 -Because "MinimumProductsRequired should be greater than 0"
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
            It 'Should have GlobalTab under settingsControl with required structure' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.settingsControl.GlobalTab | Should -Not -BeNullOrEmpty

                $globalTab = $uiConfigContent.settingsControl.GlobalTab
                $globalTab.PSObject.Properties.Name | Should -Contain 'name' -Because "GlobalTab should have a 'name' property"
                $globalTab.PSObject.Properties.Name | Should -Contain 'description' -Because "GlobalTab should have a 'description' property"
                $globalTab.PSObject.Properties.Name | Should -Contain 'dataControlOutput' -Because "GlobalTab should have a 'dataControlOutput' property"
                $globalTab.PSObject.Properties.Name | Should -Contain 'validationKeys' -Because "GlobalTab should have a 'validationKeys' property"
                $globalTab.PSObject.Properties.Name | Should -Contain 'sectionControl' -Because "GlobalTab should have a 'sectionControl' property"

                $globalTab.name | Should -Not -BeNullOrEmpty
                $globalTab.dataControlOutput | Should -Be "GlobalSettingsData"
                
                # Check sectionControl structure
                $globalTab.sectionControl.GlobalSettingsContainer | Should -Not -BeNullOrEmpty
                $globalTab.sectionControl.GlobalSettingsContainer.PSObject.Properties.Name | Should -Contain 'sectionName' -Because "GlobalSettingsContainer should have a 'sectionName' property"
                $globalTab.sectionControl.GlobalSettingsContainer.PSObject.Properties.Name | Should -Contain 'fields' -Because "GlobalSettingsContainer should have a 'fields' property"

                # Ensure fields is treated as an array
                $fieldsArray = @($globalTab.sectionControl.GlobalSettingsContainer.fields)
                $fieldsArray.Count | Should -BeGreaterThan 0 -Because "GlobalSettingsContainer should have at least one field"
            }
        }

        Context 'SettingsControl Configuration Validation' {
            It 'Should have settingsControl with MainTab, AdvancedTab, and GlobalTab' {
                $uiConfigContent = Get-Content $uiConfigPath -Raw | ConvertFrom-Json
                $uiConfigContent.settingsControl | Should -Not -BeNullOrEmpty

                # Check required tabs exist
                $uiConfigContent.settingsControl.MainTab | Should -Not -BeNullOrEmpty
                $uiConfigContent.settingsControl.AdvancedTab | Should -Not -BeNullOrEmpty
                $uiConfigContent.settingsControl.GlobalTab | Should -Not -BeNullOrEmpty

                # Validate MainTab structure
                $mainTab = $uiConfigContent.settingsControl.MainTab
                $mainTab.PSObject.Properties.Name | Should -Contain 'name' -Because "MainTab should have a 'name' property"
                $mainTab.PSObject.Properties.Name | Should -Contain 'dataControlOutput' -Because "MainTab should have a 'dataControlOutput' property"
                $mainTab.PSObject.Properties.Name | Should -Contain 'validationKeys' -Because "MainTab should have a 'validationKeys' property"
                $mainTab.dataControlOutput | Should -Be "GeneralSettingsData"

                # Validate AdvancedTab structure
                $advancedTab = $uiConfigContent.settingsControl.AdvancedTab
                $advancedTab.PSObject.Properties.Name | Should -Contain 'name' -Because "AdvancedTab should have a 'name' property"
                $advancedTab.PSObject.Properties.Name | Should -Contain 'dataControlOutput' -Because "AdvancedTab should have a 'dataControlOutput' property"
                $advancedTab.PSObject.Properties.Name | Should -Contain 'validationKeys' -Because "AdvancedTab should have a 'validationKeys' property"
                $advancedTab.dataControlOutput | Should -Be "AdvancedSettingsData"
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

    Describe -tag "UI" -name 'ScubaConfigApp XAML Validation' {
        BeforeAll {
            # Mock the UI launch function to prevent actual UI from showing
            Mock -CommandName Start-ScubaConfigApp { return $true }

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
                $xamlPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigAppResources\ScubaConfigAppUI.xaml"
                Test-Path $xamlPath | Should -BeTrue

                $result = Test-XamlValidity -XamlPath $xamlPath
                $result.IsValid | Should -BeTrue -Because "XAML should be valid: $($result.Error)"
            }

            It 'Should contain required UI elements' {
                $xamlPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigAppResources\ScubaConfigAppUI.xaml"
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
                Start-ScubaConfigApp | Should -BeTrue

                # Verify the mock was called
                Should -Invoke -CommandName Start-ScubaConfigApp -Exactly -Times 1
            }
        }
    }

    Describe -tag "Files" -name 'ScubaConfigApp Additional Files Validation' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'changelogPath')]
            $changelogPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigApp_CHANGELOG.md"
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'xamlResourcesPath')]
            $xamlResourcesPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigAppResources"
        }

        Context 'Changelog File Validation' {
            It 'Should have a changelog file' {
                Test-Path $changelogPath | Should -BeTrue -Because "Changelog file should exist"
            }

            It 'Should have valid changelog format' {
                if (Test-Path $changelogPath) {
                    $changelogContent = Get-Content $changelogPath -Raw
                    $changelogContent | Should -Not -BeNullOrEmpty -Because "Changelog should not be empty"
                    $changelogContent | Should -Match '##\s+\d+\.\d+\.\d+' -Because "Changelog should contain version headers in format '## x.x.x'"
                }
            }
        }

        Context 'XAML Resources Validation' {
            It 'Should have XAML resources directory' {
                Test-Path $xamlResourcesPath | Should -BeTrue -Because "XAML resources directory should exist"
            }

            It 'Should contain main XAML file' {
                $mainXamlPath = Join-Path $xamlResourcesPath "ScubaConfigAppUI.xaml"
                Test-Path $mainXamlPath | Should -BeTrue -Because "Main XAML file should exist in resources directory"
            }
        }
    }

    Describe -tag "Integration" -name 'ScubaConfigApp Integration Tests' {
        BeforeAll {
            # Mock function to prevent actual UI launch
            Mock Start-ScubaConfigApp { return $true }

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
                $xamlPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigAppResources\ScubaConfigAppUI.xaml"
                Test-Path $xamlPath | Should -BeTrue

                $result = Test-XamlValidity -XamlPath $xamlPath
                $result.IsValid | Should -BeTrue -Because "XAML should be valid: $($result.Error)"
            }

            It 'Should contain required UI elements' {
                $xamlPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigAppResources\ScubaConfigAppUI.xaml"
                $result = Test-XamlValidity -XamlPath $xamlPath

                $result.IsValid | Should -BeTrue
                $result.Window | Should -Not -BeNullOrEmpty

                # Test for specific named elements that should exist in the XAML
                $result.Window.FindName("MainTabControl") | Should -Not -BeNullOrEmpty -Because "MainTabControl should exist in XAML"
                $result.Window.FindName("PreviewButton") | Should -Not -BeNullOrEmpty -Because "PreviewButton should exist in XAML"
                $result.Window.FindName("ImportButton") | Should -Not -BeNullOrEmpty -Because "ImportButton should exist in XAML"
                $result.Window.FindName("NewSessionButton") | Should -Not -BeNullOrEmpty -Because "NewSessionButton should exist in XAML"

                # Test for new elements added during restructuring
                $result.Window.FindName("ChangelogButton") | Should -Not -BeNullOrEmpty -Because "ChangelogButton should exist in XAML"
                $result.Window.FindName("Version_TextBlock") | Should -Not -BeNullOrEmpty -Because "Version_TextBlock should exist in XAML"
            }
        }

        Context 'Module Function Availability' {
            It 'Should have Start-ScubaConfigApp function available' {
                Get-Command Start-ScubaConfigApp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "Start-ScubaConfigApp function should be exported from module"
            }

            It 'Should not launch actual UI when mocked' {
                # This should return true without launching UI
                Start-ScubaConfigApp | Should -BeTrue

                # Verify the mock was called
                Should -Invoke -CommandName Start-ScubaConfigApp -Exactly -Times 1
            }
        }
    }
}