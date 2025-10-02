Function New-GlobalSettingsControls {
    <#
    .SYNOPSIS
    Creates UI controls for global settings using New-FieldListCard with direct save to GlobalSettingsData.
    .DESCRIPTION
    This Function creates global settings using New-FieldListCard with the -OutPolicyOnly parameter
    to save data directly to the flat GlobalSettingsData structure without nesting.
    #>

    if (-not $syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer -or
        -not $syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer.fields) {
        Write-DebugOutput -Message "No global settings fields defined in configuration" -Source $MyInvocation.MyCommand -Level "Info"
        return
    }

    # Clear existing controls
    $syncHash.GlobalSettingsContainer.Children.Clear()

    # Store existing data temporarily to avoid double population
    $existingGlobalData = $null
    if ($syncHash.GlobalSettingsData -and $syncHash.GlobalSettingsData.Count -gt 0) {
        $existingGlobalData = $syncHash.GlobalSettingsData.Clone()
        Write-DebugOutput -Message "Stored existing global settings data for re-population: $($existingGlobalData.Keys -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"
    }

    # Initialize fresh global settings data structure
    $syncHash.GlobalSettingsData = @{}

    $globalFields = $syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer.fields
    Write-DebugOutput -Message "Creating global settings controls for $($globalFields.Count) fields" -Source $MyInvocation.MyCommand -Level "Info"

    foreach ($fieldName in $globalFields) {
        $inputType = $syncHash.UIConfigs.inputTypes.$fieldName

        if (-not $inputType) {
            Write-DebugOutput -Message "Input type not found for global settings field: $fieldName" -Source $MyInvocation.MyCommand -Level "Error"
            continue
        }

        Write-DebugOutput -Message "Creating field list card for global settings field: $fieldName" -Source $MyInvocation.MyCommand -Level "Info"

        # DEBUG: Check field types
        foreach ($field in $inputType.fields) {
            Write-DebugOutput -Message "Field $($field.value) is type $($field.type)" -Source $MyInvocation.MyCommand -Level "Info"
        }

        # Use a fake policy ID for global settings
        $globalPolicyId = "GlobalSettings"

        # Create card with empty data initially to avoid pre-population
        $card = New-FieldListCard `
            -CardName "GlobalSettings" `
            -PolicyId $globalPolicyId `
            -ProductName "Global" `
            -PolicyName $inputType.name `
            -PolicyDescription $inputType.description `
            -Criticality "N/A" `
            -FieldList $fieldName `
            -OutputData $syncHash.GlobalSettingsData `
            -SettingsTypeName "GlobalSettingsData" `
            -ShowFieldType:$false `
            -ShowDescription:$true `
            -OutPolicyOnly

        if ($card) {
            $syncHash.GlobalSettingsContainer.Children.Add($card)
            Write-DebugOutput -Message "Successfully created card for global setting: $fieldName" -Source $MyInvocation.MyCommand -Level "Info"
        } else {
            Write-DebugOutput -Message "Failed to create card for global setting: $fieldName" -Source $MyInvocation.MyCommand -Level "Error"
        }
    }

    # Restore the existing data after cards are created
    if ($existingGlobalData) {
        $syncHash.GlobalSettingsData = $existingGlobalData
        Write-DebugOutput -Message "Restored existing global settings data: $($syncHash.GlobalSettingsData.Keys -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"
    }

    # Global settings now use -OutPolicyOnly parameter for direct saving
    # No additional setup needed - integrates directly with the centralized AutoSave system

    Write-DebugOutput -Message "Global settings integrated with centralized AutoSave system using -OutPolicyOnly parameter" -Source $MyInvocation.MyCommand -Level "Info"
}


Function Update-GlobalSettingsCards {
    <#
    .SYNOPSIS
    Updates existing global settings cards with imported data.
    .DESCRIPTION
    This function updates the global settings cards that were already created with any imported data.
    Should be called after YAML import to populate the cards with existing values.
    #>

    if (-not $syncHash.GlobalSettingsData -or $syncHash.GlobalSettingsData.Count -eq 0) {
        Write-DebugOutput -Message "No global settings data to update cards with" -Source $MyInvocation.MyCommand -Level "Info"
        return
    }

    Write-DebugOutput -Message "Updating global settings cards with imported data: $($syncHash.GlobalSettingsData.Keys -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"

    # Get all global settings cards
    $globalCards = $syncHash.GlobalSettingsContainer.Children | Where-Object { $_ -is [System.Windows.Controls.Border] }

    foreach ($card in $globalCards) {
        # Try to find which field this card represents by looking at the policy name
        $cardContent = $card.Child  # This should be the Grid
        $headerGrid = $cardContent.Children[0]  # Header should be first row
        $policyInfoStack = $headerGrid.Children[1]  # Policy info is second column
        $policyHeader = $policyInfoStack.Children[0]  # Policy header is first child
        $detailsPanel = $cardContent.Children[1]  # Details panel is second row

        # Extract the field name from the policy header text
        if ($policyHeader.Text -match "GlobalSettings: (.+)") {
            $fieldDisplayName = $matches[1]

            # Find the corresponding input type
            $globalFields = $syncHash.UIConfigs.settingsControl.GlobalTab.sectionControl.GlobalSettingsContainer.fields
            $matchingField = $null

            foreach ($fieldName in $globalFields) {
                $inputType = $syncHash.UIConfigs.inputTypes.$fieldName
                if ($inputType -and $inputType.name -eq $fieldDisplayName) {
                    $matchingField = $fieldName
                    break
                }
            }

            if ($matchingField) {
                Write-DebugOutput -Message "Found matching field for card: $matchingField" -Source $MyInvocation.MyCommand -Level "Verbose"

                # Get the input type configuration
                $inputType = $syncHash.UIConfigs.inputTypes.$matchingField
                $hasData = $false
                $alreadyPopulated = $false

                # Process each field in the input type
                foreach ($field in $inputType.fields) {
                    $hasKey = if ($syncHash.GlobalSettingsData -is [System.Collections.Hashtable]) {
                        $syncHash.GlobalSettingsData.ContainsKey($field.value)
                    } else {
                        $syncHash.GlobalSettingsData.Contains($field.value)
                    }

                    if ($hasKey -and $syncHash.GlobalSettingsData[$field.value]) {
                        $hasData = $true
                        $existingData = $syncHash.GlobalSettingsData[$field.value]
                        Write-DebugOutput -Message "Found data for field $($field.value): $existingData" -Source $MyInvocation.MyCommand -Level "Info"

                        # Create field name for control lookup
                        $fieldName = ("GlobalSettings_GlobalSettings_" + $field.value)

                        # Check if field is already populated to avoid duplicates
                        if ($field.type -eq "array") {
                            $listContainerName = ($fieldName + "_List")
                            $listContainer = Find-UIListContainer -parent $detailsPanel -targetName $listContainerName

                            if ($listContainer -and $listContainer.Children.Count -gt 0) {
                                $alreadyPopulated = $true
                                Write-DebugOutput -Message "Field $($field.value) already populated, skipping" -Source $MyInvocation.MyCommand -Level "Info"
                                continue
                            }
                        }

                        # Only populate if not already populated
                        if (-not $alreadyPopulated) {
                            # Populate the actual UI controls based on field type
                            if ($field.type -eq "array") {
                                # For array fields, find the list container and populate it
                                $listContainerName = ($fieldName + "_List")
                                $listContainer = Find-UIListContainer -parent $detailsPanel -targetName $listContainerName

                                if ($listContainer) {
                                    # Convert single value to array if needed
                                    $arrayData = if ($existingData -is [array] -or $existingData -is [System.Collections.IEnumerable]) {
                                        $existingData
                                    } else {
                                        @($existingData)
                                    }

                                    Write-DebugOutput -Message "Populating array field $($field.value) with: $($arrayData -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"
                                    Add-FieldListControl -FieldPanel $listContainer -ExistingValues $arrayData
                                } else {
                                    Write-DebugOutput -Message "Could not find list container: $listContainerName" -Source $MyInvocation.MyCommand -Level "Error"
                                }
                            }
                            elseif ($field.type -eq "boolean") {
                                # For boolean fields, find the checkbox and set it
                                $booleanFieldName = ($fieldName + "_CheckBox")
                                $booleanCheckBox = Find-UICheckBox -parent $detailsPanel -targetName $booleanFieldName

                                if ($booleanCheckBox) {
                                    $booleanCheckBox.IsChecked = [bool]$existingData
                                    Write-DebugOutput -Message "Set boolean field $($field.value) to: $existingData" -Source $MyInvocation.MyCommand -Level "Info"
                                } else {
                                    Write-DebugOutput -Message "Could not find boolean checkbox: $booleanFieldName" -Source $MyInvocation.MyCommand -Level "Error"
                                }
                            }
                            elseif ($field.type -match "string") {
                                # For string fields, find the textbox and set it
                                if ($field.type -eq "dateString") {
                                    $datePickerName = ($fieldName + "_DatePicker")
                                    $datePicker = Find-UIDatePicker -parent $detailsPanel -targetName $datePickerName

                                    if ($datePicker) {
                                        try {
                                            $datePicker.SelectedDate = [DateTime]::Parse($existingData)
                                            Write-DebugOutput -Message "Set date field $($field.value) to: $existingData" -Source $MyInvocation.MyCommand -Level "Info"
                                        } catch {
                                            Write-DebugOutput -Message "Failed to parse date: $existingData" -Source $MyInvocation.MyCommand -Level "Warning"
                                        }
                                    }
                                } else {
                                    $stringFieldName = ($fieldName + "_TextBox")
                                    $stringTextBox = Find-UITextBox -parent $detailsPanel -targetName $stringFieldName

                                    if ($stringTextBox) {
                                        $stringTextBox.Text = $existingData
                                        $stringTextBox.Foreground = [System.Windows.Media.Brushes]::Black
                                        $stringTextBox.FontStyle = "Normal"
                                        Write-DebugOutput -Message "Set string field $($field.value) to: $existingData" -Source $MyInvocation.MyCommand -Level "Info"
                                    } else {
                                        Write-DebugOutput -Message "Could not find string textbox: $stringFieldName" -Source $MyInvocation.MyCommand -Level "Error"
                                    }
                                }
                            }
                        }
                    }
                }

                if ($hasData) {
                    # Make the card visually indicate it has data
                    $policyHeader.FontWeight = "Bold"

                    # Show the remove button
                    $buttonPanel = $detailsPanel.Children | Where-Object { $_ -is [System.Windows.Controls.StackPanel] -and $_.Orientation -eq "Horizontal" } | Select-Object -Last 1
                    if ($buttonPanel) {
                        $removeButton = $buttonPanel.Children | Where-Object { $_.Content -like "Remove*" }
                        if ($removeButton) {
                            $removeButton.Visibility = "Visible"
                            Write-DebugOutput -Message "Made remove button visible for global settings card: $matchingField" -Source $MyInvocation.MyCommand -Level "Info"
                        }
                    }

                    Write-DebugOutput -Message "Updated visual state and populated data for global settings card: $matchingField" -Source $MyInvocation.MyCommand -Level "Info"
                }
            }
        }
    }
}