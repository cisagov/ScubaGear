Function Update-AllUIFromData {
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

        # Update all baseline controls (exclusions, annotations, omissions) using consolidated function
        Update-BaselineControlUIFromData

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
            $control = Find-ControlBySettingName -SettingName $settingKey

            if ($control) {
                Set-ControlValue -Control $control -Value $settingValue -SettingKey $settingKey
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

        if ($syncHash.UIConfigs.advancedSections) {
            foreach ($toggleName in $syncHash.UIConfigs.advancedSections.PSObject.Properties.Name) {
                $sectionConfig = $syncHash.UIConfigs.advancedSections.$toggleName

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
            $control = Find-ControlBySettingName -SettingName $settingKey

            if ($control) {
                Set-ControlValue -Control $control -Value $settingValue -SettingKey $settingKey
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
        if ($productsToSelect.Count -gt 0) {
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

Function Update-BaselineControlUIFromData {
<#
    .SYNOPSIS
    Updates baseline control UI elements from data using configuration-driven approach.
    .DESCRIPTION
    This Function populates baseline control elements with values from the BaselineConfig data structure.
    Uses the baselineControls configuration to handle all types (exclusions, annotations, omissions) dynamically.
    When new baseline controls are added to the config, no code changes are needed.
    #>

    $BaselineControls = $syncHash.UIConfigs.baselineControls

    Foreach($baseline in $BaselineControls) {
        $outputData = $syncHash.($baseline.dataControlOutput)

        # Skip if no data exists for this baseline control
        if (-not $outputData) {
            Write-DebugOutput -Message "No data found for baseline control: $($baseline.controlType)" -Source $MyInvocation.MyCommand -Level "Verbose"
            continue
        }

        Write-DebugOutput -Message "Updating UI for baseline control: $($baseline.controlType)" -Source $MyInvocation.MyCommand -Level "Info"

        # Determine how to update the data based on the baseline control type
        If($baseline.supportsAllProducts) {
            # Handle controls that support all products (Annotations, Omissions)
            # Data structure: Product -> yamlValue -> PolicyId -> FieldData
            Update-PolicyCardsFromData -BaselineConfig $baseline -Data $outputData
        } Else {
            # Handle product-specific controls (Exclusions)
            # Data structure: Product -> PolicyId -> ExclusionType -> FieldData
            Update-ProductCardsFromData -BaselineConfig $baseline -Data $outputData
        }
    }
}
Function Update-PolicyCardsFromData {
    <#
    .SYNOPSIS
    Updates UI for baseline controls that support all products (Annotations, Omissions).
    .DESCRIPTION
    Handles data structure: Product -> yamlValue -> PolicyId -> FieldData
    #>
    param(
        [Parameter(Mandatory=$true)]
        $BaselineConfig,
        [Parameter(Mandatory=$true)]
        $Data
    )

    # Iterate through products and policies in hashtable structure
    foreach ($productName in $Data.Keys) {
        foreach ($yamlValue in $Data[$productName].Keys) {
            foreach ($policyId in $Data[$productName][$yamlValue].Keys) {
                $policyData = $Data[$productName][$yamlValue][$policyId]

                try {
                    # Get the checkbox name based on control type
                    $checkboxName = ($policyId.replace('.', '_') + "_$($BaselineConfig.controlType.TrimEnd('s'))Checkbox")
                    $checkbox = $syncHash.$checkboxName

                    if ($checkbox) {
                        # Mark as checked
                        $checkbox.IsChecked = $true

                        # Dynamic field handling for other types (Annotations, etc.)
                        Update-DynamicFields -PolicyId $policyId -FieldData $policyData -BaselineConfig $BaselineConfig

                        # Update visual elements (remove button, header styling)
                        Update-CardVisuals -PolicyId $policyId -BaselineConfig $BaselineConfig
                    }
                }
                catch {
                    Write-DebugOutput -Message "Error updating $($BaselineConfig.controlType) UI for policy $policyId in product $productName`: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                }
            }
        }
    }
}


Function Update-ProductCardsFromData {
    <#
    .SYNOPSIS
    Updates UI for baseline controls that are product-specific (Exclusions).
    .DESCRIPTION
    Handles data structure: Product -> PolicyId -> ExclusionType -> FieldData
    #>
    param(
        [Parameter(Mandatory=$true)]
        $BaselineConfig,
        [Parameter(Mandatory=$true)]
        $Data
    )

    # Iterate through products and policies in hashtable structure
    foreach ($productName in $Data.Keys) {
        foreach ($policyId in $Data[$productName].Keys) {
            try {
                # Find the field configuration from the baseline config
                $baseline = $syncHash.Baselines.$productName | Where-Object { $_.id -eq $policyId }
                if ($baseline -and $baseline.($BaselineConfig.fieldControlName) -ne $BaselineConfig.defaultFields) {

                    # Get the checkbox name based on control type
                    $checkboxName = ($policyId.replace('.', '_') + "_$($BaselineConfig.controlType.TrimEnd('s'))Checkbox")
                    $checkbox = $syncHash.$checkboxName

                    if ($checkbox) {
                        # Mark as checked
                        $checkbox.IsChecked = $true

                        # Handle dynamic field population
                        $policyData = $Data[$productName][$policyId]
                        Update-DynamicFields -PolicyId $policyId -FieldData $policyData -BaselineConfig $BaselineConfig -Baseline $baseline

                        # Update visual elements (remove button, header styling)
                        Update-CardVisuals -PolicyId $policyId -BaselineConfig $BaselineConfig
                    }
                }
            }
            catch {
                Write-DebugOutput -Message "Error updating $($BaselineConfig.controlType) UI for policy $policyId in product $productName`: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }
        }
    }
}

Function Update-DynamicFields {
    <#
    .SYNOPSIS
    Updates fields dynamically based on configuration for any baseline control type.
    #>
    param(
        [string]$PolicyId,
        $FieldData,
        $BaselineConfig,
        $Baseline = $null
    )

    # Determine the field configuration to use
    $fieldConfigName = $BaselineConfig.defaultFields

    # For product-specific controls, get the field configuration from the baseline
    if ($Baseline -and $BaselineConfig.fieldControlName) {
        $fieldConfigName = $Baseline.($BaselineConfig.fieldControlName)
    }

    # Handle legacy annotation format first
    if ($BaselineConfig.controlType -eq "Annotations" -and $FieldData -isnot [hashtable]) {
        $commentTextBoxName = ($PolicyId.replace('.', '_') + "_Comment_TextBox")
        $commentTextBox = $syncHash.$commentTextBoxName
        if ($commentTextBox) {
            $commentTextBox.Text = $FieldData.ToString()
            $commentTextBox.Foreground = [System.Windows.Media.Brushes]::Black
            $commentTextBox.FontStyle = [System.Windows.FontStyles]::Normal
        }
        return
    }

    # Get the field list configuration
    $FieldListConfig = $syncHash.UIConfigs.inputTypes.$fieldConfigName

    if (-not $FieldListConfig) {
        Write-DebugOutput -Message "No field configuration found for: $fieldConfigName" -Source $MyInvocation.MyCommand -Level "Error"
        return
    }

    # Iterate through field data (YAML key names)
    foreach ($yamlKeyName in $FieldData.Keys) {
        $fieldDataValues = $FieldData[$yamlKeyName]

        # Populate the data fields based on field configuration
        foreach ($field in $FieldListConfig.fields) {
            # Determine field name for control naming
            $fieldName = if ($field.value) { $field.value } else { $field.name }

            # Build control name based on control type and field configuration
            $controlPrefix = if ($BaselineConfig.controlType -eq "Exclusions") { $fieldConfigName } else { $BaselineConfig.controlType.TrimEnd('s') }
            $controlName = ($PolicyId.replace('.', '_') + "_" + $controlPrefix + "_" + $fieldName)

            if ($fieldDataValues.Keys -contains $fieldName) {
                $fieldValue = $fieldDataValues[$fieldName]

                if ($field.type -eq "array" -and $fieldValue -is [array]) {
                    # Handle array fields
                    Update-ArrayField -ControlName $controlName -FieldValue $fieldValue
                } else {
                    # Handle single value fields
                    Update-SingleField -ControlName $controlName -FieldValue $fieldValue -Field $field -PolicyId $PolicyId
                }
            }
        }
    }
}

Function Update-ArrayField {
    <#
    .SYNOPSIS
    Updates array field controls (lists).
    #>
    param(
        [string]$ControlName,
        [array]$FieldValue
    )

    $listControl = ($ControlName + "_List")
    $listContainer = $syncHash.$listControl

    if ($listContainer) {
        # Clear existing items
        $listContainer.Children.Clear()

        # Add each array item
        foreach ($item in $FieldValue) {
            $itemPanel = New-Object System.Windows.Controls.StackPanel
            $itemPanel.Orientation = "Horizontal"
            $itemPanel.Margin = "0,2,0,2"

            $itemText = New-Object System.Windows.Controls.TextBlock
            $itemText.Text = $item
            $itemText.VerticalAlignment = "Center"
            $itemText.Margin = "0,0,8,0"

            $removeBtn = New-Object System.Windows.Controls.Button
            $removeBtn.Content = "Remove"
            $removeBtn.Background = [System.Windows.Media.Brushes]::Red
            $removeBtn.Foreground = [System.Windows.Media.Brushes]::White
            $removeBtn.Width = 60
            $removeBtn.Height = 20
            $removeBtn.Add_Click({
                $listContainer.Children.Remove($itemPanel)
                Write-DebugOutput -Message "Item removed: $item" -Source $listContainer -Level "Info"
            }.GetNewClosure())

            [void]$itemPanel.Children.Add($itemText)
            [void]$itemPanel.Children.Add($removeBtn)
            [void]$listContainer.Children.Add($itemPanel)
        }
    }
}

Function Update-SingleField {
    <#
    .SYNOPSIS
    Updates single value field controls (textboxes, datepickers).
    #>
    param(
        [string]$ControlName,
        $FieldValue,
        $Field,
        [string]$PolicyId
    )

    $TextboxControl = ($ControlName + "_TextBox")
    $control = $syncHash.$TextboxControl

    if ($control) {
        $control.Text = $FieldValue
        $control.Foreground = [System.Windows.Media.Brushes]::Black
        $control.FontStyle = [System.Windows.FontStyles]::Normal

        # Also update DatePicker if this is a dateString field
        if ($Field.type -eq "dateString") {
            $DatePickerControl = ($ControlName + "_DatePicker")
            $datePicker = $syncHash.$DatePickerControl
            if ($datePicker) {
                try {
                    $dateValue = [DateTime]::ParseExact($FieldValue, "yyyy-MM-dd", $null)
                    $datePicker.SelectedDate = $dateValue
                } catch {
                    Write-DebugOutput -Message "Error parsing date '$FieldValue' for field '$($Field.name)' in policy '$PolicyId': $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                }
            }
        }
    }
}

Function Update-CardVisuals {
    <#
    .SYNOPSIS
    Updates visual elements of a card (remove button, header styling) based on baseline configuration.
    #>
    param(
        [string]$PolicyId,
        $BaselineConfig
    )

    # Show remove button
    $removeButtonName = ($PolicyId.replace('.', '_') + "_Remove$($BaselineConfig.controlType.TrimEnd('s'))")
    $removeButton = $syncHash.$removeButtonName
    if ($removeButton) {
        $removeButton.Visibility = "Visible"
    }

    # Make policy header bold
    $policyHeaderName = ($PolicyId.replace('.', '_') + "_PolicyHeader")
    if ($syncHash.$policyHeaderName) {
        $syncHash.$policyHeaderName.FontWeight = "Bold"
    }
}
