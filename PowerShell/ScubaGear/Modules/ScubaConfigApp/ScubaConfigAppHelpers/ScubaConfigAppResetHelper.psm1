Function Clear-FieldValue {
    <#
    .SYNOPSIS
    Clears all field values and resets the UI to default state.
    .DESCRIPTION
    This Function resets all configuration data structures and UI controls to their initial empty state for starting a new session.
    #>

    # Clear core data structures
    $syncHash.ExclusionData = [ordered]@{}
    $syncHash.OmissionData = [ordered]@{}
    $syncHash.AnnotationData = [ordered]@{}
    $syncHash.GeneralSettingsData = [ordered]@{}
    $syncHash.AdvancedSettingsData = [ordered]@{}
    $syncHash.GlobalSettingsData = [ordered]@{}

    # Dynamically reset all controls using configuration
    $syncHash.GetEnumerator() | ForEach-Object {
        $controlName = $_.Key
        $control = $_.Value

        if ($control -is [System.Windows.Controls.TextBox]) {
            # First check if there's a placeholder value
            if ($syncHash.UIConfigs.localePlaceholder.$controlName) {
                # Reset to placeholder value with placeholder styling
                $control.Text = $syncHash.UIConfigs.localePlaceholder.$controlName
                $control.Foreground = [System.Windows.Media.Brushes]::Gray
                $control.FontStyle = [System.Windows.FontStyles]::Italic
                $control.BorderBrush = [System.Windows.Media.Brushes]::Gray
                $control.BorderThickness = "1"
            }
            # Then check if there's a default value in defaultSettings
            elseif ($syncHash.UIConfigs.defaultAdvancedSettings.$controlName) {
                $control.Text = $syncHash.UIConfigs.defaultAdvancedSettings.$controlName
                $control.Foreground = [System.Windows.Media.Brushes]::Black
                $control.FontStyle = [System.Windows.FontStyles]::Normal
                $control.BorderBrush = [System.Windows.Media.Brushes]::Gray
                $control.BorderThickness = "1"
            }
            # Fallback for special cases not in config
            else {
                $control.Text = ""
                $control.Foreground = [System.Windows.Media.Brushes]::Black
                $control.FontStyle = [System.Windows.FontStyles]::Normal
                $control.BorderBrush = [System.Windows.Media.Brushes]::Gray
                $control.BorderThickness = "1"
            }
        }
        elseif ($control -is [System.Windows.Controls.CheckBox]) {
            # Check if there's a default value in defaultSettings
            if ($syncHash.UIConfigs.defaultAdvancedSettings.PSObject.Properties.Name -contains $controlName) {
                $control.IsChecked = $syncHash.UIConfigs.defaultAdvancedSettings.$controlName
            }
            # Fallback for controls not in config
            else {
                # Don't reset product checkboxes here - handle them separately
                if (-not $controlName.EndsWith('ProductCheckBox')) {
                    $control.IsChecked = $false
                }
            }
        }
        Write-DebugOutput -Message "Cleared value for: $controlName" -Source $MyInvocation.MyCommand -Level "Verbose"
    }

    # Reset specific UI elements that need special handling

    # Uncheck all product checkboxes
    $allProductCheckboxes = $syncHash.ProductsGrid.Children | Where-Object {
        $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "*ProductCheckBox"
    }
    foreach ($checkbox in $allProductCheckboxes) {
        $checkbox.IsChecked = $false
    }

    # Reset M365 Environment to default
    $syncHash.M365Environment_ComboBox.SelectedIndex = 0

    # Reset Advanced Tab toggles (these control visibility, not data)
    $toggleControls = $syncHash.GetEnumerator() | Where-Object { $_.Name -like '*_Toggle' }
    foreach ($toggleName in $toggleControls) {
        if ($toggleName.Value -is [System.Windows.Controls.CheckBox]) {
            $syncHash.$toggleName.IsChecked = $false
            $contentName = $toggleName.Replace('_Toggle', '_Content')
            if ($syncHash.$contentName) {
                $syncHash.$contentName.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }
    }

    # Clear global settings UI controls
    if ($syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer -and
        $syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer.fields) {
        $globalFields = $syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer.fields
        foreach ($fieldName in $globalFields) {
            $inputType = $syncHash.UIConfigs.inputTypes.$fieldName
            if ($inputType) {
                foreach ($field in $inputType.fields) {
                    switch ($field.type) {
                        "boolean" {
                            $checkboxName = "$($field.value)_GlobalCheckBox"
                            $checkbox = $syncHash[$checkboxName]
                            if ($checkbox) {
                                $checkbox.IsChecked = $false
                            }
                        }
                        "array" {
                            $listName = "$($field.value)_GlobalList"
                            $listContainer = $syncHash[$listName]
                            if ($listContainer) {
                                $listContainer.Children.Clear()
                            }
                            $textBoxName = "$($field.value)_GlobalTextBox"
                            $textBox = $syncHash[$textBoxName]
                            if ($textBox) {
                                # Reset to placeholder
                                if ($field.valueType -eq "ipAddress") {
                                    $placeholderText = "Enter IP address (e.g., 8.8.8.8)"
                                    $textBox.Text = $placeholderText
                                    $textBox.Foreground = [System.Windows.Media.Brushes]::Gray
                                    $textBox.FontStyle = [System.Windows.FontStyles]::Italic
                                } else {
                                    $textBox.Clear()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}#end Function : Clear-FieldValue