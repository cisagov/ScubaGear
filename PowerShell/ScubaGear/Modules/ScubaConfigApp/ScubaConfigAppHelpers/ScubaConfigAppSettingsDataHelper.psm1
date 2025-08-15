Function Set-SettingsDataForGeneralSection {
    <#
    .SYNOPSIS
    Saves general settings from UI controls to data structures.
    .DESCRIPTION
    This Function collects values from UI controls and stores them in the GeneralSettings data structure for YAML export.
    Only processes fields that are NOT part of advanced settings sections.
    #>

    # Collect ProductNames from checked checkboxes - use helper Function
    #Update-ProductNames

    # Build list of advanced settings field names to exclude
    $advancedSettingsFields = @()
    if ($syncHash.UIConfigs.advancedSections) {
        foreach ($sectionKey in $syncHash.UIConfigs.advancedSections.PSObject.Properties.Name) {
            $sectionConfig = $syncHash.UIConfigs.advancedSections.$sectionKey
            foreach ($fieldControlName in $sectionConfig.fields) {
                $advancedSettingsFields += $fieldControlName
            }
        }
    }

    # Collect from localePlaceholder TextBox controls (EXCLUDING advanced settings)
    if ($syncHash.UIConfigs.localePlaceholder -and $syncHash.UIConfigs.localePlaceholder.PSObject.Properties)
    {
        foreach ($placeholderKey in $syncHash.UIConfigs.localePlaceholder.PSObject.Properties.Name) {
            # Skip if this control belongs to advanced settings
            if ($placeholderKey -in $advancedSettingsFields) {
                Write-DebugOutput -Message "Skipping advanced setting: $placeholderKey" -Source $MyInvocation.MyCommand -Level "Verbose"
                continue
            }

            try {
                $control = $syncHash.$placeholderKey
                if ($control -is [System.Windows.Controls.TextBox]) {
                    $currentValue = $control.Text
                    $placeholderValue = $syncHash.UIConfigs.localePlaceholder.$placeholderKey

                    # Only include if it's not empty and not a placeholder
                    if (![string]::IsNullOrWhiteSpace($currentValue) -and $currentValue -ne $placeholderValue) {
                        # Convert control name to setting name (remove _TextBox suffix)
                        $settingName = $placeholderKey -replace '_TextBox$', ''
                        $syncHash.GeneralSettingsData[$settingName] = $currentValue.Trim()
                        Write-DebugOutput -Message "Collected General setting: $placeholderKey = $($syncHash.GeneralSettingsData[$settingName])" -Source $MyInvocation.MyCommand -Level "Verbose"
                    }
                }
            }
            catch {
                Write-DebugOutput -Message "Error processing placeholder key '$placeholderKey': $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }
        }
    }

    # Collect M365Environment
    if ($syncHash.M365Environment_ComboBox.SelectedItem) {
        try {
            $selectedEnv = $syncHash.UIConfigs.M365Environment | Where-Object { $_.id -eq $syncHash.M365Environment_ComboBox.SelectedItem.Tag } | Select-Object -ExpandProperty name
            if ($selectedEnv) {
                $syncHash.GeneralSettingsData["M365Environment"] = $selectedEnv
            }
            Write-DebugOutput -Message "Collected M365Environment: $selectedEnv" -Source $MyInvocation.MyCommand -Level "Verbose"
        }
        catch {
            Write-DebugOutput -Message "Error processing M365Environment: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        }
    }

} #end Function : Set-SettingsDataForGeneralSection

Function Set-SettingsDataForAdvancedSection {
    <#
    .SYNOPSIS
    Saves advanced settings from UI controls to data structures.
    .DESCRIPTION
    This Function collects values from advanced settings UI controls and stores them in the AdvancedSettings data structure for YAML export.
    Only collects values from sections that are enabled via their toggle checkboxes.
    #>

    # Clear advanced settings first
    $syncHash.AdvancedSettingsData.Clear()

    # Process each advanced section based on toggle state
    if ($syncHash.UIConfigs.advancedSections) {
        foreach ($toggleName in $syncHash.UIConfigs.advancedSections.PSObject.Properties.Name) {
            try {
                $toggleControl = $syncHash.$toggleName
                $sectionConfig = $syncHash.UIConfigs.advancedSections.$toggleName

                # Only process if toggle is checked
                if ($toggleControl -and $toggleControl.IsChecked) {
                    foreach ($fieldControlName in $sectionConfig.fields) {
                        $control = $syncHash.$fieldControlName

                        if ($control -is [System.Windows.Controls.TextBox]) {
                            $currentValue = $control.Text
                            if (![string]::IsNullOrWhiteSpace($currentValue)) {
                                # Convert control name to setting name (remove _TextBox suffix)
                                $settingName = $fieldControlName -replace '_TextBox$', ''
                                $syncHash.AdvancedSettingsData[$settingName] = $currentValue.Trim()
                            }
                        }
                        elseif ($control -is [System.Windows.Controls.CheckBox]) {
                            # Convert control name to setting name (remove _CheckBox suffix)
                            $settingName = $fieldControlName -replace '_CheckBox$', ''
                            $syncHash.AdvancedSettingsData[$settingName] = $control.IsChecked
                        }
                        Write-DebugOutput -Message "Collected Advanced setting: $settingName = $($syncHash.AdvancedSettingsData[$settingName])" -Source $MyInvocation.MyCommand -Level "Verbose"
                    }
                }
            }
            catch {
                Write-DebugOutput -Message "Error processing advanced section '$toggleName': $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }
        }
    }

} #end Function : Set-SettingsDataForAdvancedSection

Function Set-SettingsDataForGlobalSection {
    <#
    .SYNOPSIS
    Saves global settings from UI controls to data structures.
    .DESCRIPTION
    This Function collects values from global settings UI controls and stores them for YAML export.
    #>

    if (-not $syncHash.UIConfigs.globalSettings -or -not $syncHash.UIConfigs.globalSettings.fields) {
        return
    }

    Write-DebugOutput -Message "Saving global settings from UI input" -Source $MyInvocation.MyCommand -Level "Info"

    foreach ($fieldName in $syncHash.UIConfigs.globalSettings.fields) {
        $inputType = $syncHash.UIConfigs.inputTypes.$fieldName

        if (-not $inputType) {
            continue
        }

        foreach ($field in $inputType.fields) {
            switch ($field.type) {
                "boolean" {
                    $checkboxName = "$($field.value)_GlobalCheckBox"
                    $checkbox = $syncHash[$checkboxName]
                    if ($checkbox) {
                        $syncHash.GlobalSettingsData[$field.value] = $checkbox.IsChecked -eq $true
                        Write-DebugOutput -Message "Global setting $($field.value): $($syncHash.GlobalSettingsData[$field.value])" -Source $MyInvocation.MyCommand -Level "Info"
                    }
                }
                "array" {
                    # Array data is already managed in the add/remove event handlers
                    Write-DebugOutput -Message "Global setting $($field.value): $($syncHash.GlobalSettingsData[$field.value] -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"
                }
            }
        }
    }
}