Function Format-YamlMultilineString {
    <#
    .SYNOPSIS
    Formats a string value for YAML output, using pipe syntax for multiline strings.
    .DESCRIPTION
    This function detects multiline strings and formats them using YAML's pipe (|) syntax
    for better readability, while single-line strings are quoted normally.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$FieldValue,
        [Parameter(Mandatory=$false)]
        [int]$IndentLevel = 1
    )

    if ([string]::IsNullOrEmpty($FieldValue)) {
        return "`n$(' ' * ($IndentLevel * 2))$FieldName`: `"`""
    }

    # Check if the string contains newlines (multiline)
    if ($FieldValue -match "`n" -or $FieldValue -match "`r") {
        # Use YAML pipe syntax for multiline strings
        $output = "`n$(' ' * ($IndentLevel * 2))$FieldName`: |"

        # Split the content into lines and indent each line properly
        $lines = $FieldValue -split "`r?`n"
        foreach ($line in $lines) {
            # Add proper indentation (indent level + 1 for content under pipe)
            $output += "`n$(' ' * (($IndentLevel + 1) * 2))$line"
        }
        return $output
    } else {
        # Single line - use quoted format
        $escapedValue = $FieldValue.Replace('"', '""')
        return "`n$(' ' * ($IndentLevel * 2))$FieldName`: $escapedValue"
    }
}

Function New-YamlPreviewConvert {
    <#
    .SYNOPSIS
    Generates YAML configuration preview from current UI settings.
    .DESCRIPTION
    This function creates a YAML preview string by collecting values from all UI data structures and converting them into a formatted YAML string.
    .LINK
    ConvertTo-Yaml
    #>
    $yamlPreview = @()
    $yamlPreview += '# ScubaGear Configuration File'
    $yamlPreview += "`n# Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $yamlPreview += "`r"
    $yamlPreview += "`n# Organization Configuration"
    $yamlPreview += "`r"

    $yamlOptions = @(
        'DefaultToStaticType'
        'DisableAliases'
        'OmitNullValues'
        'WithIndentedSequences'
    )
    #use ConvertTo-Yaml to generate the YAML preview
    #remove productName and M365Environment from GeneralSettingsData for the top porttion
    $OrgnizationConfig = [System.Collections.Specialized.OrderedDictionary]::new()
    $keysToNotAdd = @("ProductNames", "M365Environment")
    Foreach($key in $syncHash.GeneralSettingsData.Keys) {
        if ($key -notin $keysToNotAdd) {
            $OrgnizationConfig.Add($key, $syncHash.GeneralSettingsData[$key])
        }
    }
    $yamlPreview += ConvertTo-Yaml -Data $OrgnizationConfig -Options $yamlOptions

    # Handle ProductNames using the enhanced function
    $yamlPreview += "`r"
    $ProductConfig = [System.Collections.Specialized.OrderedDictionary]::new()
    $keysToAdd= @("ProductNames")
    Foreach($key in $syncHash.GeneralSettingsData.Keys){
        if ($key -in $keysToAdd) {
            $ProductConfig.Add($key, $syncHash.GeneralSettingsData[$key])
        }
    }

    $yamlPreview += ConvertTo-Yaml -Data $ProductConfig -Options $yamlOptions

    $yamlPreview += "`n# Configuration Details"
    $yamlPreview += "`r"
    # Handle M365Environment
    $EnvironmentConfig = [System.Collections.Specialized.OrderedDictionary]::new()
    $keysToAdd= @("M365Environment")
    Foreach($key in $syncHash.GeneralSettingsData.Keys){
        if ($key -in $keysToAdd) {
            $EnvironmentConfig.Add($key, $syncHash.GeneralSettingsData[$key])
        }
    }

    $yamlPreview += ConvertTo-Yaml -Data $EnvironmentConfig -Options $yamlOptions

    if($null -ne $syncHash.AdvancedSettingsData -and $syncHash.AdvancedSettingsData.Count -gt 0){
        $yamlPreview += "`n# Advanced Settings"
        $yamlPreview += ""
        # Process advanced settings from data structure instead of UI controls
        $yamlPreview += ConvertTo-Yaml -Data $syncHash.AdvancedSettingsData -Options $yamlOptions
    }

    # Add exclusions
    If($null -ne $syncHash.ExclusionData -and $syncHash.ExclusionData.Count -gt 0) {
        $yamlPreview += "`n# Exclusions"
        $yamlPreview += "`r"
        # Convert ExclusionData to YAML format
        $yamlPreview += (ConvertTo-Yaml -Data $syncHash.ExclusionData -Options $yamlOptions).Trim()
    }

    $supportsAllProducts = $syncHash.UIConfigs.baselineControls | Where-Object { $_.supportsAllProducts }
    #TEST $PolicyControl = $supportsAllProducts[0]
    Foreach($PolicyControl in $supportsAllProducts)
    {
        # Get the output data structure for this control
        $OutputData = $syncHash.($PolicyControl.dataControlOutput)

        if($null -ne $OutputData -and $OutputData.Count -gt 0) {
            $yamlPreview += "`n# $($PolicyControl.controlType) Section"
            $yamlPreview += "`r"

            $NewDataConfig = [System.Collections.Specialized.OrderedDictionary]::new()
            foreach ($section in $OutputData.Values) {
                foreach ($key in $section.Keys) {
                    $NewDataConfig.Add($key, $section[$key])
                }
            }
            #$yamlPreview += "`n$($PolicyControl.yamlValue)`:"
            $yamlPreview += ConvertTo-Yaml -Data $NewDataConfig -Options $yamlOptions
        }
    }

    If($null -ne $syncHash.GlobalSettingsData -and $syncHash.GlobalSettingsData.Count -gt 0) {
        $yamlPreview += "`n# Global Settings"
        $yamlPreview += "`r"
        # Convert GlobalSettingsData to YAML format
        $yamlPreview += ConvertTo-Yaml -Data $syncHash.GlobalSettingsData -Options $yamlOptions
    }
    #add final newline
    $yamlPreview += "`r"

    # Display in preview tab
    $syncHash.YamlPreview_TextBox.Text = $yamlPreview

    foreach ($tab in $syncHash.MainTabControl.Items) {
        if ($tab -is [System.Windows.Controls.TabItem] -and $tab.Header -eq "Preview") {
            $syncHash.MainTabControl.SelectedItem = $syncHash.PreviewTab
            break
        }
    }
}

Function New-YamlPreview {
    <#
    .SYNOPSIS
    Generates YAML configuration preview from current UI settings.
    .DESCRIPTION
    This Function creates a YAML preview string by collecting values from all UI controls and formatting them according to ScubaGear configuration standards.
    #>
    Param(
        [Parameter(Mandatory=$false)]
        [switch]$NoRedirect
    )

    Write-DebugOutput "Starting YAML preview generation" -Source "New-YamlPreview" -Level "Debug"

    $yamlPreview = @()
    $yamlPreview += '# ScubaGear Configuration File'
    $yamlPreview += "`n# Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $yamlPreview += "`n`n# Organization Configuration"

    # Process main settings from GeneralSettings data structure instead of UI controls
    if ($syncHash.GeneralSettingsData -and $syncHash.GeneralSettingsData.Count -gt 0) {
        Write-DebugOutput "Processing GeneralSettings data with $($syncHash.GeneralSettingsData.Count) items" -Source "New-YamlPreview" -Level "Verbose"
        # Process in order of localePlaceholder keys for consistent output
        if ($syncHash.UIConfigs.localePlaceholder) {
            foreach ($placeholderKey in $syncHash.UIConfigs.localePlaceholder.PSObject.Properties.Name) {
                # Convert control name to setting name (remove _TextBox suffix)
                $settingName = $placeholderKey -replace '_TextBox$', ''

                if ($syncHash.GeneralSettingsData.Contains($settingName)) {
                    $settingValue = $syncHash.GeneralSettingsData[$settingName]

                    if (![string]::IsNullOrWhiteSpace($settingValue)) {
                        # Use the new multiline formatting function
                        $yamlPreview += Format-YamlMultilineString -FieldName $settingName -FieldValue $settingValue -IndentLevel 0
                    }
                }
            }
        }

        # Add any other general settings not in localePlaceholder
        foreach ($settingKey in ($syncHash.GeneralSettingsData.Keys | Sort-Object)) {
            # Skip if already processed above
            $alreadyProcessed = $false
            if ($syncHash.UIConfigs.localePlaceholder) {
                foreach ($placeholderKey in $syncHash.UIConfigs.localePlaceholder.PSObject.Properties.Name) {
                    $placeholderSettingName = $placeholderKey -replace '_TextBox$', ''
                    if ($settingKey -eq $placeholderSettingName) {
                        $alreadyProcessed = $true
                        break
                    }
                }
            }

            #exclude specific keys that are handled separately
            if (-not $alreadyProcessed -and $settingKey -ne "ProductNames" -and $settingKey -ne "M365Environment") {
                $settingValue = $syncHash.GeneralSettingsData[$settingKey]
                if (![string]::IsNullOrWhiteSpace($settingValue)) {
                    if ($settingValue -is [bool]) {
                        $yamlPreview += "`n$settingKey`: $($settingValue.ToString().ToLower())"
                    } else {
                        # Use the new multiline formatting function
                        $yamlPreview += Format-YamlMultilineString -FieldName $settingKey -FieldValue $settingValue -IndentLevel 0
                    }
                }
            }
        }
    }

    $yamlPreview += "`n`n# Configuration Details"

    # Handle ProductNames using the enhanced Function
    $yamlPreview += Get-ProductNamesForYaml

    # Handle M365Environment
    $selectedEnv = $syncHash.UIConfigs.M365Environment | Where-Object { $_.id -eq $syncHash.M365Environment_ComboBox.SelectedItem.Tag } | Select-Object -ExpandProperty name
    $yamlPreview += "`nM365Environment: $selectedEnv"

    # Process advanced settings from data structure instead of UI controls
    if ($syncHash.AdvancedSettingsData -and $syncHash.AdvancedSettingsData.Count -gt 0) {
        $yamlPreview += "`n`n# Advanced Settings"

        # Group advanced settings by section for better organization
        if ($syncHash.UIConfigs.advancedSections) {
            foreach ($toggleName in $syncHash.UIConfigs.advancedSections.PSObject.Properties.Name) {
                $sectionConfig = $syncHash.UIConfigs.advancedSections.$toggleName
                $sectionSettings = @()

                # Check if any settings from this section are present
                foreach ($fieldControlName in $sectionConfig.fields) {
                    $settingName = $fieldControlName -replace '_TextBox$|_CheckBox$', ''
                    if ($syncHash.AdvancedSettingsData.Contains($settingName)) {
                        $settingValue = $syncHash.AdvancedSettingsData[$settingName]

                        # Format the value appropriately
                        if ($settingValue -is [bool]) {
                            $formattedValue = $settingValue.ToString().ToLower()
                            $sectionSettings += "`n$settingName`: $formattedValue"
                        } elseif ($settingValue -match '\\|:') {
                            $formattedValue = "`"$($settingValue.Replace('\', '\\'))`""
                            $sectionSettings += "`n$settingName`: $formattedValue"
                        } else {
                            # Use multiline formatting for text values
                            $sectionSettings += Format-YamlMultilineString -FieldName $settingName -FieldValue $settingValue -IndentLevel 0
                        }
                    }
                }

                # Add section comment and settings if any exist
                if ($sectionSettings.Count -gt 0) {
                    $yamlPreview += "`n# $($sectionConfig.sectionName)"
                    $yamlPreview += $sectionSettings
                }
            }
        } else {
            # Fallback: output all advanced settings without grouping
            foreach ($settingKey in ($syncHash.AdvancedSettingsData.Keys | Sort-Object)) {
                $settingValue = $syncHash.AdvancedSettingsData[$settingKey]

                if ($settingValue -is [bool]) {
                    $formattedValue = $settingValue.ToString().ToLower()
                    $yamlPreview += "`n$settingKey`: $formattedValue"
                } elseif ($settingValue -match '\\|:') {
                    $formattedValue = "`"$($settingValue.Replace('\', '\\'))`""
                    $yamlPreview += "`n$settingKey`: $formattedValue"
                } else {
                    # Use multiline formatting for text values
                    $yamlPreview += Format-YamlMultilineString -FieldName $settingKey -FieldValue $settingValue -IndentLevel 0
                }
            }
        }
    }

    #pull all policies from baselines
    $allPolicies = foreach ($category in ($syncHash.Baselines.PSObject.Properties)) {
        foreach ($policy in $category.Value) {
            [PSCustomObject]@{
                Source = $category.Name
                Id     = $policy.id
                Name   = $policy.name
            }
        }
    }

    # loops through the baselineControls: exclusions,annotations and omissions
    Foreach ($baselineControl in $syncHash.UIConfigs.baselineControls){

        $OutputData = $syncHash.($baselineControl.dataControlOutput)

        If($null -ne $OutputData -and $OutputData.Count -gt 0) {
            $yamlPreview += "`n`n#  Baseline Control: $($baselineControl.controlType)"

            If($baselineControl.supportsAllProducts) {
                # Handle annotations and omissions (supports all products)
                # Structure: Product -> FieldType -> PolicyId -> FieldData (after FlipFieldValueAndPolicyId)
                # Output: yamlValue -> PolicyId -> FieldName: FieldValue

                $yamlPreview += "`n$($baselineControl.yamlValue)`:"

                # Collect all policies from all products
                $allPoliciesForControl = [ordered]@{}

                foreach ($productName in ($OutputData.Keys | Sort-Object)) {
                    # The structure is now Product -> FieldType -> PolicyId -> FieldData
                    foreach ($fieldType in ($OutputData[$productName].Keys | Sort-Object)) {
                        $policiesForFieldType = $OutputData[$productName][$fieldType]

                        # Now iterate through the policies under this field type
                        foreach ($policyId in ($policiesForFieldType.Keys | Sort-Object)) {
                            $fieldData = $policiesForFieldType[$policyId]

                            if ($fieldData -and $fieldData.Count -gt 0) {
                                # If policy doesn't exist yet, create it
                                if (-not $allPoliciesForControl.Contains($policyId)) {
                                    $allPoliciesForControl[$policyId] = [ordered]@{}
                                }

                                # Merge field data
                                foreach ($fieldKey in $fieldData.Keys) {
                                    $allPoliciesForControl[$policyId][$fieldKey] = $fieldData[$fieldKey]
                                }
                            }
                        }
                    }
                }

                # Output the consolidated policies
                foreach ($policyId in ($allPoliciesForControl.Keys | Sort-Object)) {
                    # Get the policy details from allPolicies
                    $PolicyDetails = $allPolicies | Where-Object { $_.Id -eq $policyId } | Select-Object -First 1
                    if ($PolicyDetails) {
                        $yamlPreview += "`n  # $($PolicyDetails.Name)"
                    }
                    $yamlPreview += "`n  $policyId`:"

                    $policyFields = $allPoliciesForControl[$policyId]
                    foreach ($fieldKey in ($policyFields.Keys | Sort-Object)) {
                        $fieldValue = $policyFields[$fieldKey]
                        if ($null -ne $fieldValue -and ![string]::IsNullOrEmpty($fieldValue)) {
                            if ($fieldValue -is [bool]) {
                                $yamlPreview += "`n    $fieldKey`: $($fieldValue.ToString().ToLower())"
                            }

                            # Handle arrays
                            elseif ($fieldValue -is [array]) {
                                $yamlPreview += "`n    $fieldKey`:"
                                foreach ($item in $fieldValue) {
                                    $yamlPreview += "`n      - $item"
                                }
                            }

                            # Handle hashtables
                            else {
                                # Use the new multiline formatting function with proper indentation
                                $yamlPreview += Format-YamlMultilineString -FieldName $fieldKey -FieldValue $fieldValue -IndentLevel 2
                            }
                        }
                    }
                }

            } Else {
                # Handle exclusions (product-specific)
                # Structure: Product -> PolicyId -> FieldData
                # Output: Product -> PolicyId -> FieldName: FieldValue

                foreach ($productName in ($OutputData.Keys | Sort-Object)) {
                    $yamlPreview += "`n$productName`:"

                    foreach ($policyId in ($OutputData[$productName].Keys | Sort-Object)) {
                        $PolicyDetails = $allPolicies | Where-Object { $_.Id -eq $policyId } | Select-Object -First 1
                        if ($PolicyDetails) {
                            $yamlPreview += "`n  # $($PolicyDetails.Name)"
                        }
                        $yamlPreview += "`n  $policyId`:"

                        $policyData = $OutputData[$productName][$policyId]
                        foreach ($fieldKey in ($policyData.Keys | Sort-Object)) {
                            $fieldValue = $policyData[$fieldKey]

                            if ($null -ne $fieldValue -and ($fieldValue -isnot [System.Collections.ICollection] -or $fieldValue.Count -gt 0)) {

                                # Handle different field value types
                                # Boolean
                                if ($fieldValue -is [bool]) {
                                    $yamlPreview += "`n    $fieldKey`: $($fieldValue.ToString().ToLower())"
                                }

                                    # Array
                                elseif ($fieldValue -is [array]) {
                                    $yamlPreview += "`n    $fieldKey`:"
                                    foreach ($item in $fieldValue) {
                                        $yamlPreview += "`n      - $item"
                                    }
                                }

                                # Hashtable
                                elseif ($fieldValue -is [hashtable]) {
                                    $yamlPreview += "`n    $fieldKey`:"
                                    foreach ($subFieldName in $fieldValue.Keys) {
                                        $subFieldValue = $fieldValue[$subFieldName]

                                        if ($null -ne $subFieldValue) {
                                            $yamlPreview += "`n      $subFieldName`:"

                                            if ($subFieldValue -is [array] -or $subFieldValue -is [System.Collections.ICollection] ) {
                                                foreach ($item in $subFieldValue) {
                                                    $yamlPreview += "`n        - $item"
                                                }
                                            } else {
                                                $yamlPreview += "`n        - $subFieldValue"
                                            }
                                        }
                                    }
                                }

                                # String (including multiline)
                                elseif ($fieldValue -is [string]) {
                                    # Use the new multiline formatting function with proper indentation
                                    $yamlPreview += Format-YamlMultilineString -FieldName $fieldKey -FieldValue $fieldValue -IndentLevel 2
                                }
                                else {
                                    $yamlPreview += "`n    $fieldKey`: $fieldValue"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # Add Global Settings to YAML
    if ($syncHash.GlobalSettingsData) {
        # Check if there are any valid values to display
        $hasValidGlobalSettings = $false
        $globalSettingsOutput = @()

        foreach ($key in ($syncHash.GlobalSettingsData.Keys | Sort-Object)) {
            $value = $syncHash.GlobalSettingsData[$key]

            # Skip if value is null, empty, false, or empty array
            if ($null -eq $value) { continue }
            if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) { continue }
            if ($value -is [array] -and $value.Count -eq 0) { continue }
            if ($value -is [bool] -and $value -eq $false) { continue }

            $hasValidGlobalSettings = $true

            if ($value -is [array] -and $value.Count -gt 0) {
                $globalSettingsOutput += "`n$key`:"
                foreach ($item in $value) {
                    $globalSettingsOutput += "`n  - $item"
                }
            }
            elseif ($value -is [bool] -and $value -eq $true) {
                $lowerValue = $value.ToString().ToLower()
                $globalSettingsOutput += "`n$key`: $lowerValue"
            }
            elseif ($value -is [string]) {
                # Use the new multiline formatting function
                $globalSettingsOutput += Format-YamlMultilineString -FieldName $key -FieldValue $value -IndentLevel 0
            }
            elseif ($null -ne $value -and $value -ne "") {
                $globalSettingsOutput += "`n$key`: $value"
            }
        }

        # Only add the section header and content if there are valid settings
        if ($hasValidGlobalSettings) {
            $yamlPreview += "`n`n# Global Settings"
            $yamlPreview += $globalSettingsOutput
        }
    }

    #add final newline
    $yamlPreview += "`n"

    # Display in preview tab
    $syncHash.YamlPreview_TextBox.Text = $yamlPreview

    foreach ($tab in $syncHash.MainTabControl.Items) {
        if ($tab -is [System.Windows.Controls.TabItem] -and $tab.Header -eq "Preview" -and $NoRedirect -eq $false) {
            $syncHash.MainTabControl.SelectedItem = $syncHash.PreviewTab
            break
        }
    }
}#end Function : New-YamlPreview