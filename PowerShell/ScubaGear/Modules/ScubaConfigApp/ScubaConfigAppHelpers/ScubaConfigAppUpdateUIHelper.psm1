Function Update-UIFromSettingsData {
    <#
    .SYNOPSIS
    Updates all UI elements from the current data structures.
    .DESCRIPTION
    This Function refreshes all UI components to reflect the current state of the configuration data.
    #>
    try {
        # Update general settings (textboxes, comboboxes)
        Update-GeneralSettingsFromData

        # Update advanced settings
        Update-AdvancedSettingsFromData

        # Update product checkboxes
        Update-ProductNameCheckboxFromData

        # Update global settings cards with imported data
        Update-GlobalSettingsCards

        Write-DebugOutput -Message "All UI elements updated from imported YAML data" -Source $MyInvocation.MyCommand -Level "Info"
    }
    catch {
        Write-DebugOutput -Message "Error updating UI from imported data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

# Function to update general settings UI from data (Dynamic Version)
Function Update-GeneralSettingsFromData {
    <#
    .SYNOPSIS
    Updates general settings UI controls from data.
    .DESCRIPTION
    This Function populates general settings controls with values from the GeneralSettings data structure.
    #>
    if (-not $syncHash.GeneralSettingsData) { return }

    try {
        foreach ($settingKey in $syncHash.GeneralSettingsData.Keys) {
            $settingValue = $syncHash.GeneralSettingsData[$settingKey]

            # Skip if value is null or empty
            if ($null -eq $settingValue) {
                Write-DebugOutput -Message "Skipping null value for setting: $settingKey" -Source $MyInvocation.MyCommand -Level "Verbose"
                continue
            }

            Write-DebugOutput -Message "Processing setting: $settingKey = $settingValue" -Source $MyInvocation.MyCommand -Level "Verbose"

            # Special handling for M365Environment
            if ($settingKey -eq "M365Environment") {
                $m365ComboBox = $syncHash.M365Environment_ComboBox
                if ($m365ComboBox) {
                    Write-DebugOutput -Message "Found M365Environment_ComboBox, setting value to: $settingValue" -Source $MyInvocation.MyCommand -Level "Info"
                    Set-UIComboBoxValue -ComboBox $m365ComboBox -Value $settingValue -SettingKey $settingKey
                    continue
                } else {
                    Write-DebugOutput -Message "M365Environment_ComboBox not found in syncHash!" -Source $MyInvocation.MyCommand -Level "Error"
                }
            }

            # Find the corresponding XAML control using various naming patterns
            $control = Find-UIFieldBySettingName -SettingName $settingKey

            if ($control) {
                Set-UIControlValue -Control $control -Value $settingValue -SettingKey $settingKey
                Write-DebugOutput -Message "Updated control for setting: $settingKey" -Source $MyInvocation.MyCommand -Level "Verbose"
            } else {
                Write-DebugOutput -Message ("No UI control found for setting: {0}" -f $settingKey) -Source $MyInvocation.MyCommand -Level "Error"
            }
        }
    }
    catch {
        Write-DebugOutput -Message ("Error updating general settings UI: {0}" -f $_.Exception.Message) -Source $MyInvocation.MyCommand -Level "Error"
    }
}

# Function to update advanced settings UI from data
Function Update-AdvancedSettingsFromData {
    <#
    .SYNOPSIS
    Updates advanced settings UI controls from data.
    .DESCRIPTION
    This Function populates advanced settings controls with values from the AdvancedSettings data structure and enables appropriate toggle sections.
    #>
    if (-not $syncHash.AdvancedSettingsData) { return }

    try {
        # First, determine which sections need to be enabled based on imported data
        $sectionsToEnable = @()

        if ($syncHash.UIConfigs.settingsControl.AdvancedTab.sectionControl) {
            foreach ($toggleName in $syncHash.UIConfigs.settingsControl.AdvancedTab.sectionControl.PSObject.Properties.Name) {
                $sectionConfig = $syncHash.UIConfigs.settingsControl.AdvancedTab.sectionControl.$toggleName

                # Check if any setting from this section exists in imported data
                $sectionHasData = $false
                foreach ($fieldControlName in $sectionConfig.fields) {
                    $settingName = $fieldControlName -replace '_TextBox$|_CheckBox$', ''
                    if ($syncHash.AdvancedSettingsData.Contains($settingName)) {
                        $sectionHasData = $true
                        break
                    }
                }

                # Enable the toggle if this section has data
                if ($sectionHasData) {
                    $sectionsToEnable += $toggleName
                    $toggleControl = $syncHash.$toggleName
                    if ($toggleControl -and $toggleControl -is [System.Windows.Controls.CheckBox]) {
                        $toggleControl.IsChecked = $true
                        Write-DebugOutput -Message "Enabled advanced section toggle: $toggleName" -Source $MyInvocation.MyCommand -Level "Verbose"
                    }
                }
            }
        }



        # Now update the actual field values
        foreach ($settingKey in $syncHash.AdvancedSettingsData.Keys) {
            $settingValue = $syncHash.AdvancedSettingsData[$settingKey]

            # Skip if value is null or empty
            if ($null -eq $settingValue) { continue }

            # Find the corresponding XAML control using various naming patterns
            $control = Find-UIFieldBySettingName -SettingName $settingKey

            if ($control) {
                Set-UIControlValue -Control $control -Value $settingValue -SettingKey $settingKey
                Write-DebugOutput -Message "Updated advanced setting control: $settingKey = $settingValue" -Source $MyInvocation.MyCommand -Level "Verbose"
            } else {
                Write-DebugOutput -Message "Could not find control for advanced setting: $settingKey" -Source $MyInvocation.MyCommand -Level "Error"
            }
        }
    }
    catch {
        Write-DebugOutput -Message "Error updating advanced settings from data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

Function Update-ProductNameCheckboxFromData{
    <#
    .SYNOPSIS
    Updates product name checkbox controls from data.
    .DESCRIPTION
    This Function sets the checked state of product name checkboxes based on the current configuration data.
    #>
    param([string[]]$ProductNames = $null)

    # Get all product checkboxes
    $allProductCheckboxes = $syncHash.ProductsGrid.Children | Where-Object {
        $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "*ProductCheckBox"
    }

    # Get all available product IDs
    $allProductIds = $syncHash.UIConfigs.products | Select-Object -ExpandProperty id

    # Determine which products to select
    $productsToSelect = @()

    if ($ProductNames) {
        if ($ProductNames -contains '*') {
            $productsToSelect = $allProductIds
            Write-DebugOutput -Message "Selecting all products due to '*' value" -Source $MyInvocation.MyCommand -Level "Verbose"
        } else {
            $productsToSelect = $ProductNames
        }
    } elseif ($syncHash.GeneralSettingsData.ProductNames) {
        $productsToSelect = $syncHash.GeneralSettingsData.ProductNames
    }

    try {

        # Get current state
        $currentlyChecked = @()
        foreach ($checkbox in $allProductCheckboxes) {
            if ($checkbox.IsChecked) {
                $currentlyChecked += $checkbox.Tag
            }
        }

        Write-DebugOutput -Message "Currently checked products: $($currentlyChecked -join ', ')" -Source $MyInvocation.MyCommand -Level "Verbose"
        Write-DebugOutput -Message "Products to select: $($productsToSelect -join ', ')" -Source $MyInvocation.MyCommand -Level "Verbose"

        # First, CHECK the products that should be selected (this ensures we always have at least one checked)
        foreach ($productId in $productsToSelect) {
            $checkbox = $allProductCheckboxes | Where-Object { $_.Tag -eq $productId }
            if ($checkbox -and -not $checkbox.IsChecked) {
                Write-DebugOutput -Message "Checking product: $productId" -Source $MyInvocation.MyCommand -Level "Verbose"
                $checkbox.IsChecked = $true
            }
        }

        # Now, UNCHECK products that should not be selected (avoiding the minimum selection error)
        foreach ($checkbox in $allProductCheckboxes) {
            $productId = $checkbox.Tag
            if ($checkbox.IsChecked -and $productId -notin $productsToSelect) {
                Write-DebugOutput -Message "Unchecking product: $productId" -Source $MyInvocation.MyCommand -Level "Verbose"
                $checkbox.IsChecked = $false
            }
        }

        # Now check selected products and create their content
        foreach ($productId in $productsToSelect) {
            $checkbox = $allProductCheckboxes | Where-Object { $_.Tag -eq $productId }
            if ($checkbox) {
                $checkbox.IsChecked = $true
                #$product = $syncHash.UIConfigs.products | Where-Object { $_.id -eq $productId }

                Foreach($baseline in $syncHash.UIConfigs.baselineControls) {
                    $tabName = "$($productId)$($baseline.controlType)Tab"
                    if ($syncHash.$tabName) {
                        $syncHash.$tabName.IsEnabled = $true
                        $container = $syncHash.("$($productId)$($baseline.controlType)Content")
                        if ($container -and $container.Children.Count -eq 0) {
                            New-ProductPolicyCards -ProductName $productId -Container $container -ControlType $baseline.controlType
                            Write-DebugOutput -Message ("Created content for: {0} ({1})" -f $productId, $baseline.controlType) -Source $MyInvocation.MyCommand -Level "Verbose"
                        }
                    }
                }

                Write-DebugOutput -Message ("Enabled tabs and ensured content for: {0}" -f $productId) -Source $MyInvocation.MyCommand -Level "Verbose"
            }
        }

        # Apply initial filters now that cards are created
        if ($productsToSelect.Count -gt 0 -and $syncHash.UIConfigs.EnableSearchAndFilter) {
            # Update criticality dropdowns now that baselines are loaded
            try {
                Update-CriticalityDropdowns
                Write-DebugOutput -Message "Updated criticality dropdowns after baseline loading" -Source $MyInvocation.MyCommand -Level "Info"
            } catch {
                Write-DebugOutput -Message "Error updating criticality dropdowns: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }

            # Trigger initial filter for all tab types after a brief delay to ensure cards are rendered
            $syncHash.Window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [Action]{
                try {
                    foreach ($tabType in $syncHash.UIConfigs.baselineControls.ControlType) {
                        Set-SearchAndFilter -TabType $tabType
                    }
                    Write-DebugOutput -Message "Initial filters applied after product selection" -Source $MyInvocation.MyCommand -Level "Info"
                } catch {
                    Write-DebugOutput -Message "Error applying initial filters: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                }
            })
        }

        # Update GeneralSettings
        if ($productsToSelect.Count -gt 0) {
            $syncHash.GeneralSettingsData["ProductNames"] = $productsToSelect
        } else {
            $syncHash.GeneralSettingsData.Remove("ProductNames")
        }

    } catch {
        Write-DebugOutput -Message ("Error updating product checkboxes: {0}" -f $_.Exception.Message) -Source $MyInvocation.MyCommand -Level "Error"
    }
    Write-DebugOutput -Message ("Updated checkboxes and tabs for products: {0}" -f ($productsToSelect -join ', ')) -Source $MyInvocation.MyCommand -Level "Verbose"
}