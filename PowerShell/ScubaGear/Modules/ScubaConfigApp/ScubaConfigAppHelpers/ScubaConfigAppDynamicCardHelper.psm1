Function Test-RequiredField {
    <#
    .SYNOPSIS
    Validates required fields in a policy card details panel.
    .DESCRIPTION
    This Function checks that all required fields in a policy configuration card have valid values before allowing the configuration to be saved.
    #>
    param(
        [System.Windows.Controls.StackPanel]$detailsPanel,
        [array]$validInputFields,
        [string]$policyId,
        [string]$CardName
    )

    $missingRequiredFields = @()

    # Build dynamic placeholders list based on the fields we're actually validating
    $dynamicPlaceholders = @("Enter value", "No date selected")  # Keep basic fallbacks

    foreach ($inputData in $validInputFields) {
        $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
        if (-not $FieldListDef) { continue }

        foreach ($field in $FieldListDef.fields) {
            # Add the specific placeholder for this field's valueType
            if ($syncHash.UIConfigs.valueValidations.($field.valueType)) {
                $fieldPlaceholder = $syncHash.UIConfigs.valueValidations.($field.valueType).sample
                if ($dynamicPlaceholders -notcontains $fieldPlaceholder) {
                    $dynamicPlaceholders += $fieldPlaceholder
                }
            }
        }
    }

    Write-DebugOutput -Message ("Dynamic placeholders for validation: {0}" -f ($dynamicPlaceholders -join ', ')) -Source $MyInvocation.MyCommand -Level "Verbose"

    foreach ($inputData in $validInputFields) {
        $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
        if (-not $FieldListDef) { continue }

        foreach ($field in $FieldListDef.fields) {
            # Skip if field is not required
            if (-not $field.required) { continue }

            $controlFieldName = ($policyId.replace('.', '_') + "_" + $CardName + "_" + $field.value)
            $hasValue = $false

            Write-DebugOutput -Message ("Checking required field: {0}(control: {1})" -f $field.name, $controlFieldName) -Source $MyInvocation.MyCommand -Level "Verbose"

            if ($field.type -eq "array") {
                # For arrays, check if list container has any items
                $listContainerName = ($controlFieldName + "_List")
                $listContainer = Find-UIControlByName -parent $detailsPanel -targetName $listContainerName

                if ($listContainer -and $listContainer.Children.Count -gt 0) {
                    $hasValue = $true
                }

            } elseif ($field.type -eq "boolean") {
                # Boolean fields always have a value (true or false)
                $hasValue = $true

            } elseif ($field.type -eq "dateString" -and $field.valueType -eq "yearmonthday") {
                # Check DatePicker for date fields
                $datePickerName = ($controlFieldName + "_DatePicker")
                $datePicker = Find-UIControlByName -parent $detailsPanel -targetName $datePickerName

                if ($datePicker -and $datePicker.SelectedDate) {
                    $hasValue = $true
                }

            } else {
                # For all other string-based fields, check TextBox
                $stringFieldName = ($controlFieldName + "_TextBox")
                $stringTextBox = Find-UIControlByName -parent $detailsPanel -targetName $stringFieldName

                if ($stringTextBox -and ![string]::IsNullOrWhiteSpace($stringTextBox.Text)) {
                    # Check if it's not a placeholder text using our dynamic list
                    $currentText = $stringTextBox.Text.Trim()
                    if ($dynamicPlaceholders -notcontains $currentText) {
                        $hasValue = $true
                    }
                }
            }

            # If required field doesn't have a value, add to missing list
            if (-not $hasValue) {
                $missingRequiredFields += $field.name
                Write-DebugOutput -Message ("Required field missing: {0}" -f $field.name) -Source $MyInvocation.MyCommand -Level "Error"
            } else {
                Write-DebugOutput -Message ("Required field has value: {0}" -f $field.name) -Source $MyInvocation.MyCommand -Level "Verbose"
            }
        }
    }

    return $missingRequiredFields
}

Function Test-FieldValidation {
    <#
    .SYNOPSIS
    Validates both required fields and regex patterns for all fields in a policy card.
    .DESCRIPTION
    This function performs comprehensive validation including:
    - Required field validation (fields marked as required must have values)
    - Regex pattern validation (any field with a value must match its pattern if defined)
    Returns both missing required fields and format validation errors.
    #>
    param(
        [System.Windows.Controls.StackPanel]$detailsPanel,
        [array]$validInputFields,
        [string]$policyId,
        [string]$CardName
    )

    $validationErrors = @{
        MissingRequired = @()
        FormatErrors = @()
    }

    # Build dynamic placeholders list
    $dynamicPlaceholders = @("Enter value", "No date selected")
    foreach ($inputData in $validInputFields) {
        $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
        if (-not $FieldListDef) { continue }
        foreach ($field in $FieldListDef.fields) {
            if ($syncHash.UIConfigs.valueValidations.($field.valueType)) {
                $fieldPlaceholder = $syncHash.UIConfigs.valueValidations.($field.valueType).sample
                if ($dynamicPlaceholders -notcontains $fieldPlaceholder) {
                    $dynamicPlaceholders += $fieldPlaceholder
                }
            }
        }
    }

    foreach ($inputData in $validInputFields) {
        $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
        if (-not $FieldListDef) { continue }

        foreach ($field in $FieldListDef.fields) {
            $controlFieldName = ($policyId.replace('.', '_') + "_" + $CardName + "_" + $field.value)
            $fieldValue = $null
            $hasValue = $false

            Write-DebugOutput -Message ("Checking field: {0}, Type: {1}, Required: {2}, Control: {3}" -f $field.name, $field.type, $field.required, $controlFieldName) -Source $MyInvocation.MyCommand -Level "Info"

            # Use field type to determine which control to look for
            switch ($field.type) {
                "array" {
                    $arrayContainer = Find-UIControlByName -parent $detailsPanel -targetName ($controlFieldName + "_Container")
                    if ($arrayContainer) {
                        $listItems = $arrayContainer.Children | Where-Object { $_.GetType().Name -eq "Border" }
                        $hasValue = $listItems.Count -gt 0
                        if ($hasValue) {
                            $fieldValue = @()
                            foreach ($item in $listItems) {
                                $textBlock = $item.Child.Children[0]
                                if ($textBlock -and $textBlock.Text) {
                                    $fieldValue += $textBlock.Text
                                }
                            }
                        }
                    }
                }
                "boolean" {
                    $checkboxControl = Find-UICheckBox -parent $detailsPanel -targetName ($controlFieldName + "_CheckBox")
                    if ($checkboxControl) {
                        # Boolean fields always have a value (true/false), but for required validation
                        # we might want to check if it's actually checked
                        $hasValue = if ($field.required) { $checkboxControl.IsChecked -eq $true } else { $true }
                        $fieldValue = $checkboxControl.IsChecked
                    }
                }
                "dateString" {
                    # Look for DatePicker (created for dateString fields)
                    $datePickerControl = Find-UIControlByName -parent $detailsPanel -targetName ($controlFieldName + "_DatePicker")
                    if ($datePickerControl -and $datePickerControl.SelectedDate) {
                        # Get format from valueValidations if available
                        $dateFormat = if ($syncHash.UIConfigs.valueValidations.($field.valueType)) {
                            $syncHash.UIConfigs.valueValidations.($field.valueType).format
                        } else {
                            "yyyy-MM-dd"  # fallback
                        }
                        $hasValue = $true
                        $fieldValue = $datePickerControl.SelectedDate.ToString($dateFormat)
                    }
                }
                default {
                    # All other field types (string, longstring) use TextBox
                    $textBoxControl = Find-UITextBox -parent $detailsPanel -targetName ($controlFieldName + "_TextBox")
                    Write-DebugOutput -Message ("Looking for TextBox: {0}, Found: {1}" -f ($controlFieldName + "_TextBox"), ($null -ne $textBoxControl)) -Source $MyInvocation.MyCommand -Level "Info"

                    if ($textBoxControl -and ![string]::IsNullOrWhiteSpace($textBoxControl.Text)) {
                        # Get placeholder text from valueValidations if available
                        $placeholderText = if ($syncHash.UIConfigs.valueValidations.($field.valueType)) {
                            $syncHash.UIConfigs.valueValidations.($field.valueType).sample
                        } else {
                            "Enter value"  # fallback
                        }

                        Write-DebugOutput -Message ("TextBox text: '{0}', Placeholder: '{1}'" -f $textBoxControl.Text, $placeholderText) -Source $MyInvocation.MyCommand -Level "Info"

                        # Check if text is not just placeholder
                        $currentText = $textBoxControl.Text.Trim()
                        if ($currentText -ne $placeholderText) {
                            $hasValue = $true
                            $fieldValue = $currentText
                        } else {
                            Write-DebugOutput -Message ("Text matches placeholder, treating as empty") -Source $MyInvocation.MyCommand -Level "Info"
                        }
                    } else {
                        if (-not $textBoxControl) {
                            Write-DebugOutput -Message ("TextBox control not found: {0}" -f ($controlFieldName + "_TextBox")) -Source $MyInvocation.MyCommand -Level "Error"
                        } else {
                            Write-DebugOutput -Message ("TextBox is empty or whitespace") -Source $MyInvocation.MyCommand -Level "Info"
                        }
                    }
                }
            }

            Write-DebugOutput -Message ("Field '{0}' hasValue: {1}, Value: {2}" -f $field.name, $hasValue, $fieldValue) -Source $MyInvocation.MyCommand -Level "Info"            # Check required field validation
            if ($field.required -and -not $hasValue) {
                $validationErrors.MissingRequired += $field.name
                Write-DebugOutput -Message ("Required field missing: {0}" -f $field.name) -Source $MyInvocation.MyCommand -Level "Error"
            }

            # Check regex pattern validation for fields with values
            if ($hasValue -and $field.valueType -and $syncHash.UIConfigs.valueValidations.($field.valueType)) {
                $validation = $syncHash.UIConfigs.valueValidations.($field.valueType)
                if ($validation.pattern) {
                    $pattern = $validation.pattern

                    # For array fields, validate each item
                    if ($field.type -eq "array" -and $fieldValue -is [array]) {
                        foreach ($item in $fieldValue) {
                            if (-not [string]::IsNullOrWhiteSpace($item) -and $item -notmatch $pattern) {
                                $validationErrors.FormatErrors += @{
                                    FieldName = $field.name
                                    Value = $item
                                    ExpectedFormat = $validation.format
                                    Error = "Invalid format for '$($field.name)': '$item'. Expected format: $($validation.format)"
                                }
                                Write-DebugOutput -Message ("Format validation failed for field '{0}': '{1}' does not match pattern '{2}'" -f $field.name, $item, $pattern) -Source $MyInvocation.MyCommand -Level "Error"
                            }
                        }
                    } else {
                        # Single value validation
                        if (-not [string]::IsNullOrWhiteSpace($fieldValue) -and $fieldValue -notmatch $pattern) {
                            $validationErrors.FormatErrors += @{
                                FieldName = $field.name
                                Value = $fieldValue
                                ExpectedFormat = $validation.format
                                Error = "Invalid format for '$($field.name)': '$fieldValue'. Expected format: $($validation.format)"
                            }
                            Write-DebugOutput -Message ("Format validation failed for field '{0}': '{1}' does not match pattern '{2}'" -f $field.name, $fieldValue, $pattern) -Source $MyInvocation.MyCommand -Level "Error"
                        }
                    }
                }

                # Additional script-based validation checks
                if ($validation.invalidScriptChecks -and $validation.invalidScriptChecks.Count -gt 0 -and
                    ![string]::IsNullOrWhiteSpace($validation.invalidScriptMessage)) {

                    try {
                        # Execute each script check - if ANY fail, the validation fails
                        $scriptValidationFailed = $false
                        foreach ($scriptCheck in $validation.invalidScriptChecks) {
                            try {
                                # Create a script block that has access to $value variable
                                $scriptWithValue = '$value = {0}; {1}' -f ("'$fieldValue'"), $scriptCheck
                                $scriptResult = [scriptblock]::Create($scriptWithValue).Invoke()

                                # Any script that returns false/null/empty indicates failure
                                if (-not $scriptResult -or $scriptResult -eq $false -or [string]::IsNullOrEmpty($scriptResult)) {
                                    $scriptValidationFailed = $true
                                    Write-DebugOutput -Message ("Script validation failed for check: {0}" -f $scriptCheck) -Source $MyInvocation.MyCommand -Level "Error"
                                    break
                                }
                            }
                            catch {
                                # If any script check fails to execute, consider validation failed
                                $scriptValidationFailed = $true
                                Write-DebugOutput -Message ("Script validation check failed to execute: {0} - {1}" -f $scriptCheck, $_.Exception.Message) -Source $MyInvocation.MyCommand -Level "Error"
                                break
                            }
                        }

                        if ($scriptValidationFailed) {
                            $validationErrors.FormatErrors += @{
                                FieldName = $field.name
                                Value = $fieldValue
                                ExpectedFormat = $validation.format
                                Error = $validation.invalidScriptMessage
                            }
                            Write-DebugOutput -Message ("Script validation failed for field '{0}': {1}" -f $field.name, $validation.invalidScriptMessage) -Source $MyInvocation.MyCommand -Level "Error"
                        }
                    }
                    catch {
                        Write-DebugOutput -Message ("Script validation error for field '{0}': {1}" -f $field.name, $_.Exception.Message) -Source $MyInvocation.MyCommand -Level "Warning"
                    }
                }
            }
        }
    }

    return $validationErrors
}

Function New-FieldListControl {
    <#
    .SYNOPSIS
    Creates a dynamic field list control for policy configurations.
    .DESCRIPTION
    This Function generates interactive UI controls for managing lists of field values in policy configurations.
    #>
    param(
        [string]$ControlName,
        [string]$PolicyId,
        [object]$Field,
        [System.Windows.Controls.StackPanel]$Container
    )

    $fieldPanel = New-Object System.Windows.Controls.StackPanel
    $fieldPanel.Margin = "0,0,0,12"

    # Field label - USE field.name for UI display
    $fieldLabel = New-Object System.Windows.Controls.TextBlock
    $fieldLabel.FontWeight = "SemiBold"
    $fieldLabel.Margin = "0,0,0,4"

    # Create proper formatting for required fields with red asterisk
    if ($Field.required -eq $true) {
        # Create a run with the field name
        $fieldNameRun = New-Object System.Windows.Documents.Run
        $fieldNameRun.Text = $Field.name

        # Create a run with the red asterisk
        $asteriskRun = New-Object System.Windows.Documents.Run
        $asteriskRun.Text = " *"
        $asteriskRun.Foreground = [System.Windows.Media.Brushes]::Red
        $asteriskRun.FontWeight = "Bold"

        # Add both runs to the textblock
        [void]$fieldLabel.Inlines.Add($fieldNameRun)
        [void]$fieldLabel.Inlines.Add($asteriskRun)
    } else {
        # Non-required field - just show the name
        $fieldLabel.Text = $Field.name
    }
    [void]$fieldPanel.Children.Add($fieldLabel)

    # Field description
    $fieldDesc = New-Object System.Windows.Controls.TextBlock
    $fieldDesc.Text = $Field.description
    $fieldDesc.FontSize = 11
    $fieldDesc.Foreground = $syncHash.Window.FindResource("MutedTextBrush")
    $fieldDesc.Margin = "0,0,0,4"
    $fieldDesc.TextWrapping = "Wrap"
    [void]$fieldPanel.Children.Add($fieldDesc)

    # Use field.value for control naming (for data storage)
    $fieldName = ($PolicyId.replace('.', '_') + "_" + $ControlName + "_" + $Field.value)

    if ($Field.type -eq "array") {
        # Create array input with add/remove Functionality
        $arrayContainer = New-Object System.Windows.Controls.StackPanel
        $arrayContainer.Name = $fieldName + "_Container"

        # Input row for new entries
        $inputRow = New-Object System.Windows.Controls.StackPanel
        $inputRow.Orientation = "Horizontal"
        $inputRow.Margin = "0,0,0,8"

        $inputTextBox = New-Object System.Windows.Controls.TextBox
        $inputTextBox.Name = $fieldName + "_TextBox"
        $inputTextBox.Width = 250
        $inputTextBox.Height = 28
        $inputTextBox.VerticalContentAlignment = "Center"
        $inputTextBox.Margin = "0,0,8,0"
        $inputTextBox.Foreground = [System.Windows.Media.Brushes]::Gray
        $inputTextBox.FontStyle = "Italic"

        # Set placeholder text based on field type using valueValidations
        $placeholderText = if ($syncHash.UIConfigs.valueValidations.($Field.valueType)) {
            $syncHash.UIConfigs.valueValidations.($Field.valueType).sample
        } else {
            "Enter value"  # fallback if valueType not found
        }

        $inputTextBox.Text = $placeholderText

        # Add global event handlers to dynamically created inputTextBox
        Add-UIControlEventHandler -Control $inputTextBox

        # placeholder Functionality - capture placeholder in closure properly
        $inputTextBox.Add_GotFocus({
            #param($sender, $e)
            if ($this.Text -eq $placeholderText) {
                $this.Text = ""
                $this.Foreground = [System.Windows.Media.Brushes]::Black
                $this.FontStyle = "Normal"
            }
        }.GetNewClosure())

        $inputTextBox.Add_LostFocus({
            #param($sender, $e)
            if ([string]::IsNullOrWhiteSpace($this.Text)) {
                $this.Text = $placeholderText
                $this.Foreground = [System.Windows.Media.Brushes]::Gray
                $this.FontStyle = "Italic"
            }
        }.GetNewClosure())

        $addButton = New-Object System.Windows.Controls.Button
        $addButton.Content = "Add"
        $addButton.Name = $fieldName + "_Add"
        $addButton.Style = $syncHash.Window.FindResource("PrimaryButton")
        $addButton.Width = 60
        $addButton.Height = 28

        [void]$inputRow.Children.Add($inputTextBox)
        [void]$inputRow.Children.Add($addButton)
        [void]$arrayContainer.Children.Add($inputRow)

        # List container for added items
        $listContainer = New-Object System.Windows.Controls.StackPanel
        $listContainer.Name = $fieldName + "_List"
        [void]$arrayContainer.Children.Add($listContainer)

        Add-UIControlEventHandler -Control $addButton

        # add button Functionality - capture placeholder properly
        $addButton.Add_Click({
            $inputBox = $this.Parent.Children[0]
            $listPanel = $this.Parent.Parent.Children[1]

            if (![string]::IsNullOrWhiteSpace($inputBox.Text) -and $inputBox.Text -ne $placeholderText) {
                # Trim the input value
                $trimmedValue = $inputBox.Text.Trim()

                # Check if value already exists
                if ($listContainer.Children.Children | Where-Object { $_.Text -contains $trimmedValue }) {
                    $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localePopupMessages.DuplicateEntry, $syncHash.UIConfigs.localeTitles.DuplicateEntry, "OK", "Warning")
                    return
                }

                # Validate input based on valueType using valueValidations
                $isValid = $true
                $errorMessage = ""

                if ($syncHash.UIConfigs.valueValidations.($Field.valueType)) {
                    $validation = $syncHash.UIConfigs.valueValidations.($Field.valueType)
                    if ($validation.pattern) {
                        $isValid = $trimmedValue -match $validation.pattern
                        $errorMessage = ("Invalid {0} format. Please use format: {1}" -f $Field.valueType, $validation.sample)
                    }
                } else {
                    # Fallback for unknown types
                    $isValid = $trimmedValue.Length -gt 0
                    $errorMessage = "Value cannot be empty"
                }

                if ($isValid) {
                    # Create item row
                    $itemRow = New-Object System.Windows.Controls.StackPanel
                    $itemRow.Orientation = "Horizontal"
                    $itemRow.Margin = "0,2,0,2"

                    $itemText = New-Object System.Windows.Controls.TextBlock
                    $itemText.Text = $trimmedValue
                    $itemText.VerticalAlignment = "Center"
                    $itemText.Width = 250
                    $itemText.Margin = "0,0,8,0"

                    $removeButton = New-Object System.Windows.Controls.Button
                    $removeButton.Content = "Remove"
                    $removeButton.Width = 60
                    $removeButton.Height = 22
                    $removeButton.Background = [System.Windows.Media.Brushes]::Red
                    $removeButton.Foreground = [System.Windows.Media.Brushes]::White
                    $removeButton.BorderThickness = "0"
                    $removeButton.FontSize = 10

                    $removeButton.Add_Click({
                        $this.Parent.Parent.Children.Remove($this.Parent)
                    }.GetNewClosure())

                    [void]$itemRow.Children.Add($itemText)
                    [void]$itemRow.Children.Add($removeButton)
                    [void]$listPanel.Children.Add($itemRow)

                    # Clear input - use captured placeholder
                    $inputBox.Text = $placeholderText
                    $inputBox.Foreground = [System.Windows.Media.Brushes]::Gray
                    $inputBox.FontStyle = "Italic"
                } else {
                    $syncHash.ShowMessageBox.Invoke($errorMessage, $syncHash.UIConfigs.localeTitles.ValidationError, "OK", "Warning")
                }
            }
        }.GetNewClosure())

        # Add input row and list container to field panel
        [void]$fieldPanel.Children.Add($arrayContainer)

    } elseif ($Field.type -eq "boolean") {
        # Create boolean checkbox control
        $booleanCheckBox = New-Object System.Windows.Controls.CheckBox
        $booleanCheckBox.Name = $fieldName + "_CheckBox"
        $booleanCheckBox.Content = "Enable this setting"
        $booleanCheckBox.Margin = "0,4,0,0"
        $booleanCheckBox.IsChecked = $false

        # Add global event handlers to dynamically created checkbox
        Add-UIControlEventHandler -Control $booleanCheckBox

        [void]$fieldPanel.Children.Add($booleanCheckBox)

    } elseif ($Field.type -match "string") {

        switch($Field.type){
            "string" {
                $stringTextBox = New-Object System.Windows.Controls.TextBox
                $stringTextBox.Name = $fieldName + "_TextBox"
                $stringTextBox.HorizontalAlignment = "Left"
                $stringTextBox.Width = 400
                $stringTextBox.Height = 28
                $stringTextBox.VerticalContentAlignment = "Center"
            }
            "longstring" {
                $stringTextBox = New-Object System.Windows.Controls.TextBox
                $stringTextBox.Name = $fieldName + "_TextBox"
                $stringTextBox.HorizontalAlignment = "Left"
                $stringTextBox.Width = 500
                $stringTextBox.Height = 80
                $stringTextBox.AcceptsReturn = $true
                $stringTextBox.TextWrapping = "Wrap"
                $stringTextBox.VerticalScrollBarVisibility = "Auto"
                $stringTextBox.VerticalContentAlignment = "Top"
                $stringTextBox.Margin = "0,0,0,8"
            }
            "dateString" {
                # Set placeholder text for string fields using valueValidations
                $stringPlaceholder = if ($syncHash.UIConfigs.valueValidations.($Field.valueType)) {
                    $syncHash.UIConfigs.valueValidations.($Field.valueType).sample
                } else {
                    "Enter value"  # fallback
                }

                # Create a horizontal stack panel for date picker and text box
                $datePanel = New-Object System.Windows.Controls.StackPanel
                $datePanel.Orientation = "Horizontal"
                $datePanel.HorizontalAlignment = "Left"

                # Create DatePicker
                $datePicker = New-Object System.Windows.Controls.DatePicker
                $datePicker.Name = $fieldName + "_DatePicker"
                $datePicker.Width = 150
                $datePicker.Height = 28
                $datePicker.Margin = "0,0,8,0"
                $datePicker.SelectedDateFormat = "Short"
                <#
                Look for the following keys in the JSON:
                    "dateDayMin": 0,
                    "dateDayMax": 1825,
                Set the DisplayDateStart and DisplayDateEnd properties of the DatePicker
                #>
                If($Field.dateDayMin) {
                    $datePicker.DisplayDateStart = [DateTime]::Today.AddDays($Field.dateDayMin)
                }
                If($Field.dateDayMax) {
                    $datePicker.DisplayDateEnd = [DateTime]::Today.AddDays($Field.dateDayMax)
                }

                # Add global event handlers to dynamically created DatePicker
                Add-UIControlEventHandler -Control $datePicker

                # Create a "Clear" button next to the DatePicker
                $clearButton = New-Object System.Windows.Controls.Button
                $clearButton.Content = "Clear"
                $clearButton.Name = $fieldName + "_ClearDate"
                $clearButton.Width = 50
                $clearButton.Height = 28
                $clearButton.Margin = "0,0,8,0"

                # Add global event handlers to dynamically created clear button
                Add-UIControlEventHandler -Control $clearButton

                # Clear button Functionality
                $clearButton.Add_Click({
                    # Find the DatePicker (previous sibling)
                    $parentPanel = $this.Parent
                    $datePicker = $parentPanel.Children[0]
                    $datePicker.SelectedDate = $null
                }.GetNewClosure())

                # Optional: Add a readonly TextBox to show the formatted date
                $stringTextBox = New-Object System.Windows.Controls.TextBox
                $stringTextBox.Name = $fieldName + "_TextBox"
                $stringTextBox.Width = 120
                $stringTextBox.Height = 28
                $stringTextBox.IsReadOnly = $true
                $stringTextBox.Text = "No date selected"
                $stringTextBox.Foreground = [System.Windows.Media.Brushes]::Gray
                $stringTextBox.FontStyle = "Italic"

                # Update text box when date picker changes
                $datePicker.Add_SelectedDateChanged({
                    $parentPanel = $this.Parent
                    $textBox = $parentPanel.Children | Where-Object { $_.Name -like "*_TextBox" }
                    if ($this.SelectedDate) {
                        # Format as yyyy-MM-dd for YAML output
                        $formattedDate = $this.SelectedDate.ToString($syncHash.UIConfigs.valueValidations.($Field.valueType).format)
                        $textBox.Text = $formattedDate
                        $textBox.Foreground = [System.Windows.Media.Brushes]::Black
                        $textBox.FontStyle = "Normal"
                    } else {
                        $textBox.Text = "No date selected"
                        $textBox.Foreground = [System.Windows.Media.Brushes]::Gray
                        $textBox.FontStyle = "Italic"
                    }
                }.GetNewClosure())

                # Add controls to the date panel
                [void]$datePanel.Children.Add($datePicker)
                [void]$datePanel.Children.Add($clearButton)
                [void]$datePanel.Children.Add($stringTextBox)

                # Add the date panel to the field panel instead of individual textbox
                [void]$fieldPanel.Children.Add($datePanel)

                # Skip the normal textbox creation for dateString
                continue
            }
        }

        # Only add the regular textbox if we didn't create a date panel
        if ($Field.type -ne "dateString") {
            # placeholder text for string fields using valueValidations
            $stringPlaceholder = if ($syncHash.UIConfigs.valueValidations.($Field.valueType)) {
                $syncHash.UIConfigs.valueValidations.($Field.valueType).sample
            } else {
                "Enter value"  # fallback if valueType not found in config
            }

            $stringTextBox.Text = $stringPlaceholder
            $stringTextBox.Foreground = [System.Windows.Media.Brushes]::Gray
            $stringTextBox.FontStyle = "Italic"

            # string field placeholder Functionality
            $stringTextBox.Add_GotFocus({
                #param($sender, $e)
                if ($this.Text -eq $stringPlaceholder) {
                    $this.Text = ""
                    $this.Foreground = [System.Windows.Media.Brushes]::Black
                    $this.FontStyle = "Normal"
                }
            }.GetNewClosure())

            $stringTextBox.Add_LostFocus({
                #param($sender, $e)
                if ([string]::IsNullOrWhiteSpace($this.Text)) {
                    $this.Text = $stringPlaceholder
                    $this.Foreground = [System.Windows.Media.Brushes]::Gray
                    $this.FontStyle = "Italic"
                }
            }.GetNewClosure())

            # Add global event handlers to dynamically created stringTextBox
            Add-UIControlEventHandler -Control $stringTextBox
            [void]$fieldPanel.Children.Add($stringTextBox)
        }
    }

    # Add Graph connectivity buttons for those that match the field value
    if ($syncHash.GraphConnected -and ($Field.value -in $syncHash.UIConfigs.graphQueries.Psobject.properties.name) ) {
        $GraphQueryData = ($syncHash.UIConfigs.graphQueries.PSObject.Properties | Where-Object { $_.Name -eq $Field.value }).Value

        $graphGetButton = New-Object System.Windows.Controls.Button
        $graphGetButton.Content = "Get $($GraphQueryData.Name)"
        $graphGetButton.Width = 100
        $graphGetButton.Height = 28
        $graphGetButton.Margin = "8,0,0,0"

        # Add global event handlers to dynamically created graphGetButton
        Add-UIControlEventHandler -Control $graphGetButton

        $graphGetButton.Add_Click({
        try {
            # Get search term from input box
            $searchTerm = if ($inputTextBox.Text -ne $placeholderText -and ![string]::IsNullOrWhiteSpace($inputTextBox.Text)) { $inputTextBox.Text } else { "" }

            $selectedItems = Show-GraphSelector -GraphEntityType $GraphQueryData.Name -SearchTerm $searchTerm

            # More robust check for valid results
            if ($null -ne $selectedItems) {
                # Add selected users to the list
                foreach ($item in $selectedItems) {
                    # Skip if item is null or empty
                    if (-not $item -or [string]::IsNullOrWhiteSpace($item.($GraphQueryData.outProperty))) {
                        continue
                    }

                    # Check if user already exists in the list
                    if ($listContainer.Children.Children | Where-Object { $_.Text -contains $item.Id }) {
                        continue
                    }

                    # Create item panel
                    $itemPanel = New-Object System.Windows.Controls.StackPanel
                    $itemPanel.Orientation = "Horizontal"
                    $itemPanel.Margin = "0,2,0,2"

                    # Create item text block
                    $itemText = New-Object System.Windows.Controls.TextBlock
                    $itemText.Text = "$($item.($GraphQueryData.outProperty))"
                    $itemText.Width = 250
                    $itemText.VerticalAlignment = "Center"
                    $itemText.ToolTip = "$($item.($GraphQueryData.tipProperty))"

                    # Create remove button
                    $removeUserButton = New-Object System.Windows.Controls.Button
                    $removeUserButton.Content = "Remove"
                    $removeUserButton.Width = 60
                    $removeUserButton.Height = 20
                    $removeUserButton.Margin = "8,0,0,0"
                    $removeUserButton.FontSize = 10
                    $removeUserButton.Background = [System.Windows.Media.Brushes]::Red
                    $removeUserButton.Foreground = [System.Windows.Media.Brushes]::White
                    $removeUserButton.BorderThickness = "0"

                    $removeUserButton.Add_Click({
                        $parentItem = $this.Parent
                        $parentContainer = $parentItem.Parent
                        $parentContainer.Children.Remove($parentItem)
                    }.GetNewClosure())

                    [void]$itemPanel.Children.Add($itemText)
                    [void]$itemPanel.Children.Add($removeUserButton)
                    [void]$listContainer.Children.Add($itemPanel)
                }

                # Clear the input box
                $inputTextBox.Text = $placeholderText
                $inputTextBox.Foreground = [System.Windows.Media.Brushes]::Gray
                $inputTextBox.FontStyle = "Italic"
            } else {
                Write-DebugOutput -Message "No items selected or found from Graph query for $($GraphQueryData.Name)" -Source $MyInvocation.MyCommand -Level "Info"
            }
        }
        catch {
            Write-DebugOutput -Message "Error in Graph button click: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.localePopupMessages.GraphError -f $_.Exception.Message), $syncHash.UIConfigs.localeTitles.GraphError, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }.GetNewClosure())

        [void]$inputRow.Children.Add($graphGetButton)
    }
    [void]$Container.Children.Add($fieldPanel)
}


function Add-FieldListControl {
    <#
    .SYNOPSIS
    Adds a list control for managing fields within a policy card.

    .DESCRIPTION
    This function creates a UI control for displaying and managing a list of fields within a policy card.
    #>
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.StackPanel]$FieldPanel,
        [Parameter(Mandatory)]
        $ExistingValues
    )
    foreach ($value in $ExistingValues)
    {
        # Create a horizontal panel for each entry
        $entryPanel = New-Object System.Windows.Controls.StackPanel
        $entryPanel.Orientation = "Horizontal"
        $entryPanel.Margin = "0,2,0,2"

        # Value display
        $entryText = New-Object System.Windows.Controls.TextBlock
        $entryText.Text = $value
        $entryText.Width = 250
        $entryText.VerticalAlignment = "Center"

        # Remove button
        $removeButton = New-Object System.Windows.Controls.Button
        $removeButton.Content = "Remove"
        $removeButton.Width = 60
        $removeButton.Height = 20
        $removeButton.Margin = "8,0,0,0"
        $removeButton.FontSize = 10
        $removeButton.Background = [System.Windows.Media.Brushes]::Red
        $removeButton.Foreground = [System.Windows.Media.Brushes]::White
        $removeButton.BorderThickness = "0"
        $removeButton.Add_Click({
            $FieldPanel.Children.Remove($entryPanel)
        }.GetNewClosure())

        [void]$entryPanel.Children.Add($entryText)
        [void]$entryPanel.Children.Add($removeButton)
        [void]$FieldPanel.Children.Add($entryPanel)
    }
}

# Updated Function to create a field card UI element that handles multiple fields
Function New-FieldListCard {
    <#
    .SYNOPSIS
    Creates a comprehensive field card UI element for policy configuration.
    .DESCRIPTION
    This Function generates a complete card interface with checkboxes, input fields, tabs, and buttons for configuring multiple field types within policy settings including baselineControl tabs.
    When using -OutPolicyOnly, specify -SettingsTypeName to indicate which settings type to save for AutoSave functionality.
    #>
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "ProductName")]
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "OutputData")]
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "FlipFieldValueAndPolicyId")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "SettingsTypeName")]
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "OutPolicyOnly")]
    param(
        [string]$CardName,
        [string]$PolicyId,
        [string]$ProductName,
        [string]$PolicyName,
        [string]$PolicyDescription,
        [string]$Criticality,
        [string[]]$FieldList,  # Can be string or array
        $OutputData,
        [string]$SettingsTypeName,  # Name of the settings type for AutoSave (used with -OutPolicyOnly)
        [switch]$ShowFieldType,
        [switch]$ShowDescription,
        [switch]$FlipFieldValueAndPolicyId,
        [switch]$OutPolicyOnly
    )

    # Store baseline data in card Tag for filtering
    $baselineData = @{
        id = $PolicyId
        name = $PolicyName
        criticality = $Criticality
        rationale = $PolicyDescription
    }

    # Handle both string and array inputs for FieldLists
    $inputFields = @()
    if ($FieldList -is [array]) {
        $inputFields = $FieldList
    } else {
        $inputFields = @($FieldList)
    }

    # Skip if inputField is "none" or empty
    if ($inputFields -contains "none" -or $inputFields.Count -eq 0) {
        return $null
    }

    # Validate all inputFields exist
    $validInputFields = @()
    foreach ($inputData in $inputFields) {
        $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
        if ($FieldListDef) {
            $validInputFields += $inputData
        } else {
            Write-DebugOutput -Message ("Input data [{0}] not found in configuration" -f $inputData) -Source $MyInvocation.MyCommand -Level "Error"
        }
    }

    # Return null if no valid inputFields found
    if ($validInputFields.Count -eq 0) {
        return $null
    }

    # Create the main card border
    $card = New-Object System.Windows.Controls.Border
    $card.Style = $syncHash.Window.FindResource("Card")
    $card.Margin = "0,0,0,12"

    # Create main grid for the card
    $cardGrid = New-Object System.Windows.Controls.Grid
    [void]$cardGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))
    [void]$cardGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))

    # Create header with checkbox and policy info
    $headerGrid = New-Object System.Windows.Controls.Grid
    [void]$headerGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" }))
    [void]$headerGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))
    [System.Windows.Controls.Grid]::SetRow($headerGrid, 0)

    # Create checkbox
    $checkbox = New-Object System.Windows.Controls.CheckBox
    $checkbox.Name = ($PolicyId.replace('.', '_') + "_" + $CardName + "_FieldListCheckbox")
    $checkbox.VerticalAlignment = "Top"
    $checkbox.Margin = "0,0,12,0"
    $checkbox.FontSize = 14
    $checkbox.FontWeight = "Bold"
    $checkbox.Foreground = $syncHash.Window.FindResource("PrimaryBrush")
    # Apply the custom style instead of removing template
    #$checkbox.Style = $syncHash.Window.FindResource("PolicySavedByTagCheckBox")
    $checkbox.Style = $syncHash.Window.FindResource("PolicyGreenDotCheckBox")
    # Remove the default checkbox appearance
    #$checkbox.Template = $null
    [System.Windows.Controls.Grid]::SetColumn($checkbox, 0)

    # Add global event handlers to dynamically created checkbox
    Add-UIControlEventHandler -Control $checkbox

    # Create policy info stack panel
    $policyInfoStack = New-Object System.Windows.Controls.StackPanel
    [System.Windows.Controls.Grid]::SetColumn($policyInfoStack, 1)

    # Policy ID and name
    $policyHeader = New-Object System.Windows.Controls.TextBlock
    $policyHeader.Text = "$PolicyId`: $PolicyName"
    $policyHeader.FontWeight = "SemiBold"
    $policyHeader.Foreground = $syncHash.Window.FindResource("PrimaryBrush")
    $policyHeader.TextWrapping = "Wrap"
    $policyHeader.Margin = "0,0,0,4"

    [void]$policyInfoStack.Children.Add($policyHeader)

    # Add cursor and click handler to policy header
    $policyHeader.Cursor = [System.Windows.Input.Cursors]::Hand
    $policyHeader.Add_MouseLeftButtonDown({
        # Navigate to checkbox: this -> policyInfoStack -> headerGrid -> checkbox (first child)
        $headerGrid = $this.Parent.Parent
        $checkbox = $headerGrid.Children[0]
        $checkbox.IsChecked = -not $checkbox.IsChecked
    }.GetNewClosure())

    If($ShowDescription){
        # Policy description
        $policyDesc = New-Object System.Windows.Controls.TextBlock
        $policyDesc.Text = $PolicyDescription
        $policyDesc.FontSize = 11
        $policyDesc.Foreground = $syncHash.Window.FindResource("MutedTextBrush")
        $policyDesc.TextWrapping = "Wrap"
        [void]$policyInfoStack.Children.Add($policyDesc)
    }

    If($ShowFieldType){
            # Field types info (show all available fields)
        $FieldLists = @()
        foreach ($inputData in $validInputFields) {
            $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
            if ($FieldListDef) {
                $FieldLists += $FieldListDef.name
            }
        }
        $FieldListHeader = New-Object System.Windows.Controls.TextBlock
        $FieldListHeader.Text = "${CardName}: $($FieldLists -join ', ')"
        $FieldListHeader.FontSize = 12
        $FieldListHeader.Foreground = $syncHash.Window.FindResource("AccentBrush")
        $FieldListHeader.Margin = "0,0,0,4"
        [void]$policyInfoStack.Children.Add($FieldListHeader)
    }

    # Add elements to header grid
    [void]$headerGrid.Children.Add($checkbox)
    [void]$headerGrid.Children.Add($policyInfoStack)

    # Create details panel (initially collapsed)
    $detailsPanel = New-Object System.Windows.Controls.StackPanel
    $detailsPanel.Visibility = "Collapsed"
    $detailsPanel.Margin = "24,12,0,0"
    [System.Windows.Controls.Grid]::SetRow($detailsPanel, 1)

    # Create tab control for multiple inputFields if more than one
    if ($validInputFields.Count -gt 1) {
        $tabControl = New-Object System.Windows.Controls.TabControl
        $tabControl.Margin = "0,0,0,16"

        foreach ($inputData in $validInputFields) {
            $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
            if ($FieldListDef) {
                # Create tab item
                $tabItem = New-Object System.Windows.Controls.TabItem
                $tabItem.Header = $FieldListDef.name

                # Create tab content
                $tabContent = New-Object System.Windows.Controls.StackPanel
                $tabContent.Margin = "8"

                # Add description
                $fieldDesc = New-Object System.Windows.Controls.TextBlock
                $fieldDesc.Text = $FieldListDef.description
                $fieldDesc.FontStyle = "Italic"
                $fieldDesc.Foreground = $syncHash.Window.FindResource("MutedTextBrush")
                $fieldDesc.TextWrapping = "Wrap"
                $fieldDesc.Margin = "0,0,0,16"
                [void]$tabContent.Children.Add($fieldDesc)

                # Generate fields for this field
                foreach ($field in $FieldListDef.fields) {
                    New-FieldListControl -ControlName $CardName -PolicyId $PolicyId -Field $field -Container $tabContent
                }

                $tabItem.Content = $tabContent
                [void]$tabControl.Items.Add($tabItem)
            }
        }
        [void]$detailsPanel.Children.Add($tabControl)
    } else {
        # Single Field - no tabs needed
        $FieldListDef = $syncHash.UIConfigs.inputTypes.$validInputFields[0]

        If($ShowDescription){
            # Card description
            $fieldDesc = New-Object System.Windows.Controls.TextBlock
            $fieldDesc.Text = $FieldListDef.description
            $fieldDesc.FontStyle = "Italic"
            $fieldDesc.Foreground = $syncHash.Window.FindResource("MutedTextBrush")
            $fieldDesc.TextWrapping = "Wrap"
            $fieldDesc.Margin = "0,0,0,16"
            [void]$detailsPanel.Children.Add($fieldDesc)
        }
        # Generate fields based on Field
        foreach ($field in $FieldListDef.fields) {
            New-FieldListControl -ControlName $CardName -PolicyId $PolicyId -Field $field -Container $detailsPanel
        }
    }

    # Button panel
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.Margin = "0,16,0,0"

    # Save button
    $saveButton = New-Object System.Windows.Controls.Button
    $saveButton.Content = "Save $CardName"
    $saveButton.Name = ($PolicyId.replace('.', '_') + "_" + $CardName + "_SaveButton")
    $saveButton.Style = $syncHash.Window.FindResource("PrimaryButton")
    $saveButton.Width = 120
    $saveButton.Height = 28
    $saveButton.Margin = "0,0,10,0"

    # Remove button (initially hidden)
    $removeButton = New-Object System.Windows.Controls.Button
    $removeButton.Content = "Remove $CardName"
    $removeButton.Name = ($PolicyId.replace('.', '_') + "_" + $CardName + "_RemoveButton")
    $removeButton.Style = $syncHash.Window.FindResource("PrimaryButton")
    $removeButton.Width = 120
    $removeButton.Height = 28
    $removeButton.Background = [System.Windows.Media.Brushes]::Red
    $removeButton.Foreground = [System.Windows.Media.Brushes]::White
    $removeButton.BorderThickness = "0"
    $removeButton.FontWeight = "SemiBold"
    $removeButton.Cursor = [System.Windows.Input.Cursors]::Hand
    $removeButton.Visibility = "Collapsed"

    [void]$buttonPanel.Children.Add($saveButton)
    [void]$buttonPanel.Children.Add($removeButton)
    [void]$detailsPanel.Children.Add($buttonPanel)

    # Add elements to main grid
    [void]$cardGrid.Children.Add($headerGrid)
    [void]$cardGrid.Children.Add($detailsPanel)
    $card.Child = $cardGrid

    # PRE-POPULATION LOGIC FOR IMPORT
    if ($OutputData) {
        $hasPrePopulatedData = $false

        foreach ($inputData in $validInputFields) {
            $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
            if (-not $FieldListDef) { continue }

            foreach ($field in $FieldListDef.fields) {
                $fieldName = ($PolicyId.replace('.', '_') + "_" + $CardName + "_" + $field.value)
                $existingData = $null

                # Check for existing data based on field type and structure
                if ($OutPolicyOnly) {
                    # For GlobalSettings: data is directly in OutputData
                    # Handle both hashtables (ContainsKey) and OrderedDictionaries (Contains)
                    $hasKey = if ($OutputData -is [System.Collections.Hashtable]) {
                        $OutputData.ContainsKey($field.value)
                    } else {
                        $OutputData.Contains($field.value)
                    }

                    if ($hasKey -and $OutputData[$field.value]) {
                        $existingData = $OutputData[$field.value]
                        Write-DebugOutput -Message "Found existing data for $($field.value): $existingData (Type: $($existingData.GetType().Name))" -Source $MyInvocation.MyCommand -Level "Info"
                    }
                } elseif ($FlipFieldValueAndPolicyId) {
                    # For annotations/omissions: Product -> FieldType -> PolicyId -> Data
                    $baselineControl = $syncHash.UIConfigs.baselineControls | Where-Object { $_.defaultFields -eq $validInputFields[0] }
                    $FieldTypeKey = if ($baselineControl) { $baselineControl.yamlValue } else { $validInputFields[0] }

                    if ($OutputData[$ProductName] -and $OutputData[$ProductName][$FieldTypeKey] -and
                        $OutputData[$ProductName][$FieldTypeKey][$PolicyId] -and
                        $OutputData[$ProductName][$FieldTypeKey][$PolicyId][$field.value]) {
                        $existingData = $OutputData[$ProductName][$FieldTypeKey][$PolicyId][$field.value]
                    }
                } else {
                    # Normal structure: Product -> PolicyId -> FieldType -> Data
                    if ($OutputData[$ProductName] -and $OutputData[$ProductName][$PolicyId]) {
                        $FieldListValue = $FieldListDef.value

                        if ([string]::IsNullOrWhiteSpace($FieldListValue)) {
                            # Data stored directly under policy
                            if ($OutputData[$ProductName][$PolicyId][$field.value]) {
                                $existingData = $OutputData[$ProductName][$PolicyId][$field.value]
                            }
                        } else {
                            # Data stored under exclusion type
                            if ($OutputData[$ProductName][$PolicyId][$FieldListValue] -and
                                $OutputData[$ProductName][$PolicyId][$FieldListValue][$field.value]) {
                                $existingData = $OutputData[$ProductName][$PolicyId][$FieldListValue][$field.value]
                            }
                        }
                    }
                }

                # Pre-populate the field if data exists
                if ($existingData) {
                    $hasPrePopulatedData = $true

                    if ( $field.type -eq "array" -and ($existingData -is [array] -or $existingData -is [System.Collections.IEnumerable]) ) {
                        # Find the list container for this field
                        $listContainerName = ($fieldName + "_List")
                        $listContainer = $null

                        if ($validInputFields.Count -gt 1) {
                            # Multi-tab scenario - search within tabs
                            $tabControl = $detailsPanel.Children | Where-Object { $_ -is [System.Windows.Controls.TabControl] }
                            foreach ($tabItem in $tabControl.Items) {
                                if ($tabItem.Header -eq $FieldListDef.name) {
                                    $tabContent = $tabItem.Content
                                    $listContainer = Find-UIListContainer -parent $tabContent -targetName $listContainerName
                                    if ($listContainer) { break }
                                }
                            }
                        } else {
                            # Single field scenario
                            $listContainer = Find-UIListContainer -parent $detailsPanel -targetName $listContainerName
                        }

                        if ($listContainer) {
                            Add-FieldListControl -FieldPanel $listContainer -ExistingValues $existingData
                        }
                    }
                    elseif ($field.type -eq "boolean") {
                        # Pre-populate boolean field
                        $booleanFieldName = ($fieldName + "_CheckBox")
                        $booleanCheckBox = $null

                        if ($validInputFields.Count -gt 1) {
                            # Multi-tab scenario
                            $tabControl = $detailsPanel.Children | Where-Object { $_ -is [System.Windows.Controls.TabControl] }
                            foreach ($tabItem in $tabControl.Items) {
                                if ($tabItem.Header -eq $FieldListDef.name) {
                                    $tabContent = $tabItem.Content
                                    $booleanCheckBox = Find-UICheckBox -parent $tabContent -targetName $booleanFieldName
                                    if ($booleanCheckBox) { break }
                                }
                            }
                        } else {
                            # Single field scenario
                            $booleanCheckBox = Find-UICheckBox -parent $detailsPanel -targetName $booleanFieldName
                        }

                        if ($booleanCheckBox) {
                            $booleanCheckBox.IsChecked = [bool]$existingData
                        }
                    }
                    elseif ($field.type -match "string") {
                        # Pre-populate string fields
                        if ($field.type -eq "dateString") {
                            $datePickerName = ($fieldName + "_DatePicker")
                            $datePicker = $null

                            if ($validInputFields.Count -gt 1) {
                                # Multi-tab scenario
                                $tabControl = $detailsPanel.Children | Where-Object { $_ -is [System.Windows.Controls.TabControl] }
                                foreach ($tabItem in $tabControl.Items) {
                                    if ($tabItem.Header -eq $FieldListDef.name) {
                                        $tabContent = $tabItem.Content
                                        $datePicker = Find-UIDatePicker -parent $tabContent -targetName $datePickerName
                                        if ($datePicker) { break }
                                    }
                                }
                            } else {
                                # Single field scenario
                                $datePicker = Find-UIDatePicker -parent $detailsPanel -targetName $datePickerName
                            }

                            if ($datePicker) {
                                try {
                                    $datePicker.SelectedDate = [DateTime]::Parse($existingData)
                                } catch {
                                    Write-DebugOutput -Message "Failed to parse date: $existingData" -Source $MyInvocation.MyCommand -Level "Warning"
                                }
                            }
                        } else {
                            $stringFieldName = ($fieldName + "_TextBox")
                            $stringTextBox = $null

                            if ($validInputFields.Count -gt 1) {
                                # Multi-tab scenario
                                $tabControl = $detailsPanel.Children | Where-Object { $_ -is [System.Windows.Controls.TabControl] }
                                foreach ($tabItem in $tabControl.Items) {
                                    if ($tabItem.Header -eq $FieldListDef.name) {
                                        $tabContent = $tabItem.Content
                                        $stringTextBox = Find-UITextBox -parent $tabContent -targetName $stringFieldName
                                        if ($stringTextBox) { break }
                                    }
                                }
                            } else {
                                # Single field scenario
                                $stringTextBox = Find-UITextBox -parent $detailsPanel -targetName $stringFieldName
                            }

                            if ($stringTextBox) {
                                $stringTextBox.Text = $existingData
                                $stringTextBox.Foreground = [System.Windows.Media.Brushes]::Black
                                $stringTextBox.FontStyle = "Normal"
                            }
                        }
                    }
                }
            }
        }

        # If we pre-populated any data, make the card visually distinct
        if ($hasPrePopulatedData) {
            $policyHeader.FontWeight = "Bold"
            $removeButton.Visibility = "Visible"
            # show the save indicator on checkbox
            $checkbox.Tag = "Saved"
        }
    }

    # Add checkbox event handler
    $checkbox.Add_Checked({
        $detailsPanel = $this.Parent.Parent.Children | Where-Object { $_.GetType().Name -eq "StackPanel" }
        $detailsPanel.Visibility = "Visible"
        #$this.Content = "▼"  # Down-pointing triangle when expanded
    }.GetNewClosure())

    $checkbox.Add_Unchecked({
        $detailsPanel = $this.Parent.Parent.Children | Where-Object { $_.GetType().Name -eq "StackPanel" }
        $detailsPanel.Visibility = "Collapsed"
        #$this.Content = "▶"  # Right-pointing triangle when collapsed
    }.GetNewClosure())

    Add-UIControlEventHandler -Control $saveButton
    Add-UIControlEventHandler -Control $removeButton

    # Create click event for save button
    $saveButton.Add_Click({
        $policyIdWithUnderscores = $this.Name.Replace( ("_" + $CardName + "_SaveButton"), "")
        $policyId = $policyIdWithUnderscores.Replace("_", ".")

        Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.PolicySaving -f $CardName.ToLower(), $policyId) -Source $this.Name -Level "Info"
        
        # Disable preview tab immediately when save is initiated
        $syncHash.PreviewTab.IsEnabled = $false
        Write-DebugOutput -Message "Preview tab disabled due to configuration save" -Source $this.Name -Level "Verbose"


        # Get the details panel (parent of button panel)
        $detailsPanel = $this.Parent.Parent

        # Perform comprehensive validation (required fields + regex patterns)
        $validationResults = Test-FieldValidation -detailsPanel $detailsPanel -validInputFields $validInputFields -policyId $policyId -CardName $CardName

        # Check for validation errors
        $hasValidationErrors = $false
        $errorMessages = @()

        # Handle missing required fields
        if ($validationResults.MissingRequired.Count -gt 0) {
            $hasValidationErrors = $true
            foreach ($fieldName in $validationResults.MissingRequired) {
                $errorMessages += "The '$fieldName' field is required and cannot be empty."
            }
        }

        # Handle format validation errors
        if ($validationResults.FormatErrors.Count -gt 0) {
            $hasValidationErrors = $true
            foreach ($formatError in $validationResults.FormatErrors) {
                $errorMessages += $formatError.Error
            }
        }

        # If there are validation errors, show them and exit
        if ($hasValidationErrors) {
            $combinedErrorMessage = $errorMessages -join "`n`n"
            $title = if ($validationResults.MissingRequired.Count -gt 0) {
                $syncHash.UIConfigs.localeTitles.RequiredFieldsMissing
            } else {
                $syncHash.UIConfigs.localeTitles.ValidationError
            }

            $syncHash.ShowMessageBox.Invoke($combinedErrorMessage, $title, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return # Exit save operation if validation fails
        }        # Initialize output data structure
        If($FlipFieldValueAndPolicyId) {
            # For annotations/omissions: Product -> FieldType -> PolicyId -> Data
            # Get the yamlValue from the baseline control that uses this input type
            $baselineControl = $syncHash.UIConfigs.baselineControls | Where-Object { $_.defaultFields -eq $validInputFields[0] }
            $NestedKey = if ($baselineControl) { $baselineControl.yamlValue } else { $validInputFields[0] }
            $PolicyKey = $policyId            # The actual policy ID becomes nested under FieldType
        } elseif ($OutPolicyOnly) {
            # For OutPolicyOnly (GlobalSettings): flat structure directly in OutputData
            # No nested Product/PolicyId structure needed
            $NestedKey = $null
            $PolicyKey = $null
        } else {
            # Normal structure: Product -> PolicyId -> FieldType -> Data
            $NestedKey = $policyId
            $PolicyKey = $validInputFields[0]  # Use the first valid input field name
        }

        # Initialize structure (skip for OutPolicyOnly since we're writing directly to OutputData)
        if (-not $OutPolicyOnly) {
            if (-not $OutputData[$ProductName]) {
                $OutputData[$ProductName] = [ordered]@{}
            }
            if (-not $OutputData[$ProductName][$NestedKey]) {
                $OutputData[$ProductName][$NestedKey] = [ordered]@{}
            }
        }

        $hasOutputData = $false
        $savedinputTypes = @()


        # Process each Field and MERGE them into a single policy entry
        foreach ($inputData in $validInputFields) {
            $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
            if (-not $FieldListDef) { continue }

            # Get the YAML key name
            $yamlKeyName = $FieldListDef.name

            Write-DebugOutput -Message ("Processing {0} Field: {1}" -f $CardName, $inputData) -Source $this.Name -Level "Verbose"

            # Collect field values for this Field
            $fieldCardData = @{}
            foreach ($field in $FieldListDef.fields) {
                # Use $field.value for control names (matching creation)
                $controlFieldName = ($policyId.replace('.', '_') + "_" + $CardName + "_" + $field.value)

                Write-DebugOutput -Message ("Looking for control: {0} (type: {1})" -f $controlFieldName, $field.type) -Source $this.Name -Level "Verbose"

                if ($field.type -eq "array") {
                    # For arrays, look for the list container
                    $listContainerName = ($controlFieldName + "_List")
                    $listContainer = Find-UIListContainer -parent $detailsPanel -targetName $listContainerName

                    if ($listContainer -and $listContainer.Children.Count -gt 0) {
                        $items = @()
                        foreach ($childPanel in $listContainer.Children) {
                            if ($childPanel -is [System.Windows.Controls.StackPanel]) {
                                foreach ($element in $childPanel.Children) {
                                    if ($element -is [System.Windows.Controls.TextBlock]) {
                                        $text = $element.Text.Trim()
                                        if (-not [string]::IsNullOrWhiteSpace($text)) {
                                            $items += $text
                                        }
                                    }
                                }
                            }
                        }

                        if ($items.Count -gt 0) {
                            # Use $field.value for data storage key (YAML output)
                            $fieldCardData[$field.value] = $items
                            Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.CollectedArrayField -f $inputData, $field.value, ($items -join ', ')) -Source $this.Name -Level "Info"
                        }
                    } else {
                        Write-DebugOutput -Message ("List container not found or empty for: {0}" -f $listContainerName) -Source $this.Name -Level "Error"
                    }

                } elseif ($field.type -eq "boolean") {
                    # For boolean, look for the CheckBox
                    $booleanFieldName = ($controlFieldName + "_CheckBox")
                    $booleanCheckBox = Find-UICheckBox -parent $detailsPanel -targetName $booleanFieldName

                    if ($booleanCheckBox) {
                        $value = [bool]$booleanCheckBox.IsChecked
                        # Use $field.value for data storage key (YAML output)
                        $fieldCardData[$field.value] = $value
                        Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.CollectedBooleanField -f $inputData, $field.value, $value) -Source $this.Name -Level "Info"
                    } else {
                        Write-DebugOutput -Message ("Boolean field not found for: {0}" -f $booleanFieldName) -Source $this.Name -Level "Error"
                    }

                } elseif ($field.type -match "string") {
                    # Check if this is a dateString with yearmonthday - look for DatePicker
                    if ($field.type -eq "dateString") {
                        $datePickerName = ($controlFieldName + "_DatePicker")
                        $datePicker = Find-UIDatePicker -parent $detailsPanel -targetName $datePickerName

                        if ($datePicker -and $datePicker.SelectedDate) {
                            $value = $datePicker.SelectedDate.ToString($syncHash.UIConfigs.valueValidations.($Field.valueType).format)
                            $fieldCardData[$field.value] = $value
                            Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.CollectedStringField -f $inputData, $field.value, $value) -Source $this.Name -Level "Info"
                        }
                    } else {
                        $stringFieldName = ($controlFieldName + "_TextBox")
                        $stringTextBox = Find-UITextBox -parent $detailsPanel -targetName $stringFieldName

                        if ($stringTextBox -and ![string]::IsNullOrWhiteSpace($stringTextBox.Text)) {
                            # Check if it's not just the placeholder text using config-driven approach
                            $placeholderText = if ($syncHash.UIConfigs.valueValidations.($field.valueType)) {
                                $syncHash.UIConfigs.valueValidations.($field.valueType).sample
                            } else {
                                "Enter value"  # fallback
                            }

                            if ($stringTextBox.Text.Trim() -ne $placeholderText) {
                                $value = $stringTextBox.Text.Trim()
                                # Use $field.value for data storage key (YAML output)
                                $fieldCardData[$field.value] = $value
                                Write-DebugOutput -Message ("Collected string field [{0}][{1}]: {2}" -f $inputData, $field.value, $value) -Source $this.Name -Level "Verbose"
                            }
                        } else {
                            Write-DebugOutput -Message ("String textbox not found or empty for: {0}" -f $stringFieldName) -Source $this.Name -Level "Error"
                        }
                    }
                }
            }

            # Store the data with proper nesting for YAML output
            if ($fieldCardData.Count -gt 0) {
                # Save data with the appropriate structure
                if ($OutPolicyOnly) {
                    # For OutPolicyOnly (GlobalSettings): store fields directly in OutputData with no nesting
                    foreach ($fieldKey in $fieldCardData.Keys) {
                        $OutputData[$fieldKey] = $fieldCardData[$fieldKey]
                    }
                    Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.MergedCardField -f $CardName, "Direct", "OutPolicyOnly", $inputData, ($fieldCardData | ConvertTo-Json -Compress)) -Source $this.Name -Level "Info"
                } elseif ($FlipFieldValueAndPolicyId) {
                    # Structure: Product -> FieldType -> PolicyId -> Data
                    # $NestedKey = inputType name, $PolicyKey = PolicyId
                    if (-not $OutputData[$ProductName][$NestedKey][$PolicyKey]) {
                        $OutputData[$ProductName][$NestedKey][$PolicyKey] = [ordered]@{}
                    }

                    # Store field data directly under the policy
                    foreach ($fieldKey in $fieldCardData.Keys) {
                        $OutputData[$ProductName][$NestedKey][$PolicyKey][$fieldKey] = $fieldCardData[$fieldKey]
                    }
                    Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.MergedCardField -f $CardName, $ProductName, $PolicyKey, $NestedKey, ($fieldCardData | ConvertTo-Json -Compress)) -Source $this.Name -Level "Info"
                } else {
                    # Original structure: Product -> PolicyId -> FieldType -> Data
                    # $NestedKey = PolicyId, $PolicyKey = inputType name

                    # Get the YAML section name (exclusion type value like "CapExclusions", "RoleExclusions")
                    $FieldListValue = $FieldListDef.value

                    # Handle empty values - store fields directly under policy if no group value
                    if ([string]::IsNullOrWhiteSpace($FieldListValue)) {
                        # If the inputType has no value, store fields directly under the policy
                        foreach ($fieldKey in $fieldCardData.Keys) {
                            $OutputData[$ProductName][$NestedKey][$fieldKey] = $fieldCardData[$fieldKey]
                        }
                        Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.MergedCardField -f $CardName, $ProductName, $NestedKey, "Direct", ($fieldCardData | ConvertTo-Json -Compress)) -Source $this.Name -Level "Info"
                    } else {
                        # If the inputType has a value, create nested structure
                        # IMPORTANT: Clear and rebuild the exclusion type container to ensure empty fields are removed
                        $OutputData[$ProductName][$NestedKey][$FieldListValue] = @{}

                        # Store field data under the exclusion type
                        foreach ($fieldKey in $fieldCardData.Keys) {
                            $OutputData[$ProductName][$NestedKey][$FieldListValue][$fieldKey] = $fieldCardData[$fieldKey]
                        }
                        Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.MergedCardField -f $CardName, $ProductName, $NestedKey, $FieldListValue, ($fieldCardData | ConvertTo-Json -Compress)) -Source $this.Name -Level "Info"
                    }
                }

                $hasOutputData = $true
                $savedinputTypes += $yamlKeyName
            } else {
                # Handle case where no fields have values - we need to clear existing data
                Write-DebugOutput -Message ("No entries collected for {0} fields: {1} - clearing existing data" -f $CardName.ToLower(), $inputData) -Source $this.Name -Level "Info"

                if ($OutPolicyOnly) {
                    # For OutPolicyOnly: Remove any existing fields for this input type
                    foreach ($field in $FieldListDef.fields) {
                        # Handle both hashtables (ContainsKey) and OrderedDictionaries (Contains)
                        $hasKey = if ($OutputData -is [System.Collections.Hashtable]) {
                            $OutputData.ContainsKey($field.value)
                        } else {
                            $OutputData.Contains($field.value)
                        }

                        if ($hasKey) {
                            $OutputData.Remove($field.value)
                            Write-DebugOutput -Message "Removed empty field from OutputData: $($field.value)" -Source $this.Name -Level "Info"
                        }
                    }
                } elseif ($FlipFieldValueAndPolicyId) {
                    # Structure: Product -> FieldType -> PolicyId -> Data
                    if ($OutputData[$ProductName] -and $OutputData[$ProductName][$NestedKey] -and $OutputData[$ProductName][$NestedKey][$PolicyKey]) {
                        $OutputData[$ProductName][$NestedKey].Remove($PolicyKey)
                        Write-DebugOutput -Message "Removed empty policy from FieldType structure: $PolicyKey" -Source $this.Name -Level "Info"
                    }
                } else {
                    # Original structure: Product -> PolicyId -> FieldType -> Data
                    $FieldListValue = $FieldListDef.value

                    if ([string]::IsNullOrWhiteSpace($FieldListValue)) {
                        # Clear fields directly under policy
                        if ($OutputData[$ProductName] -and $OutputData[$ProductName][$NestedKey]) {
                            foreach ($field in $FieldListDef.fields) {
                                if ($OutputData[$ProductName][$NestedKey].ContainsKey($field.value)) {
                                    $OutputData[$ProductName][$NestedKey].Remove($field.value)
                                    Write-DebugOutput -Message "Removed empty field from policy: $($field.value)" -Source $this.Name -Level "Info"
                                }
                            }
                        }
                    } else {
                        # Clear the entire exclusion type container
                        if ($OutputData[$ProductName] -and $OutputData[$ProductName][$NestedKey] -and $OutputData[$ProductName][$NestedKey].ContainsKey($FieldListValue)) {
                            $OutputData[$ProductName][$NestedKey].Remove($FieldListValue)
                            Write-DebugOutput -Message "Removed empty exclusion type: $FieldListValue" -Source $this.Name -Level "Info"
                        }
                    }
                }
            }
        }

        if ($hasOutputData) {
            # Log the final merged structure and show detailed success message
            $successMessage = if ($savedinputTypes.Count -gt 1) {
                "Successfully saved $CardName configuration for policy '$policyId'. Fields saved: $($savedinputTypes -join ', ')."
            } else {
                "Successfully saved $CardName configuration for policy '$policyId'."
            }
            # Save the policy/settings for resume
            if ($OutPolicyOnly -and $SettingsTypeName) {
                Save-AutoSaveSettings -SettingsType $SettingsTypeName
                Write-DebugOutput -Message "OutPolicyOnly save completed using SettingsType: $SettingsTypeName" -Source $this.Name -Level "Info"
            } else {
                # Regular policies use the policy save mechanism
                Save-AutoSavePolicy -CardName $CardName -PolicyId $policyId -ProductName $ProductName -FlipFieldValueAndPolicyId $false
            }

            # Show success message
            $syncHash.ShowMessageBox.Invoke($successMessage, $syncHash.UIConfigs.localeTitles.Success, "OK", "Information")

            # Update YAML preview to reflect the changes
            #New-YamlPreview

            # Make remove button visible and header bold
            $removeButton.Visibility = "Visible"
            $policyHeader.FontWeight = "Bold"

            # Collapse details panel and uncheck checkbox
            $detailsPanel.Visibility = "Collapsed"
             # Show save indicator (check)
            $headerGrid = $detailsPanel.Parent.Children | Where-Object { $_.GetType().Name -eq "Grid" }
            $checkbox = $headerGrid.Children | Where-Object { $_.GetType().Name -eq "CheckBox" }
            $checkbox.Tag = "Saved"
            $checkbox.IsChecked = $false
        } else {
            # Remove save indicator if no data was saved
            $headerGrid = $detailsPanel.Parent.Children | Where-Object { $_.GetType().Name -eq "Grid" }
            $checkbox = $headerGrid.Children | Where-Object { $_.GetType().Name -eq "CheckBox" }
            $checkbox.Tag = $null
            # More specific error message about why no data was saved
            $errorMessage = "No valid data was found to save for $CardName fields. Please ensure all required fields are completed and all field values follow the correct format."
            Write-DebugOutput -Message ("No entries found for {0} fields: {1}" -f $CardName.ToLower(), $inputData) -Source $this.Name -Level "Error"
            $syncHash.ShowMessageBox.Invoke($errorMessage, $syncHash.UIConfigs.localeTitles.ValidationError, "OK", "Warning")
        }
    }.GetNewClosure())


    # Enhanced remove button click handler for multiple exclusionFields
    $removeButton.Add_Click({
        $policyIdWithUnderscores = $this.Name.Replace(("_" + $CardName + "_RemoveButton"), "")
        $policyId = $policyIdWithUnderscores.Replace("_", ".")

        $result = $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.LocalePopupMessages.RemoveCardPolicyConfirmation -f $CardName.ToLower(), $policyId), $syncHash.UIConfigs.localeTitles.ConfirmRemove, "YesNo", "Question")
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {

            # Disable preview tab immediately when remove is confirmed
            $syncHash.PreviewTab.IsEnabled = $false
            Write-DebugOutput -Message "Preview tab disabled due to configuration removal" -Source $this.Name -Level "Verbose"

            # Handle data structure based on configuration
            if ($OutPolicyOnly) {
                # For OutPolicyOnly (e.g. GlobalSettings): Remove fields directly from OutputData
                Write-DebugOutput -Message "OutPolicyOnly removal - processing $($validInputFields.Count) input fields" -Source $this.Name -Level "Info"
                foreach ($inputData in $validInputFields) {
                    $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
                    if ($FieldListDef) {
                        Write-DebugOutput -Message "Processing field definition for: $inputData" -Source $this.Name -Level "Verbose"
                        foreach ($field in $FieldListDef.fields) {
                            $fieldKey = $field.value
                            Write-DebugOutput -Message "Attempting to remove field key: $fieldKey" -Source $this.Name -Level "Verbose"

                                $OutputData.Remove($fieldKey)
                                Write-DebugOutput -Message "Successfully removed GlobalSettings field: $fieldKey" -Source $this.Name -Level "Info"

                        }
                    } else {
                        Write-DebugOutput -Message "No field definition found for input: $inputData" -Source $this.Name -Level "Warning"
                    }
                }
            } elseif ($FlipFieldValueAndPolicyId) {
                # For annotations/omissions: Product -> FieldType -> PolicyId -> Data
                $baselineControl = $syncHash.UIConfigs.baselineControls | Where-Object { $_.defaultFields -eq $validInputFields[0] }
                $FieldTypeKey = if ($baselineControl) { $baselineControl.yamlValue } else { $validInputFields[0] }

                # Check if the field type exists in the output data
                if ($OutputData[$ProductName] -and $OutputData[$ProductName][$FieldTypeKey] -and $OutputData[$ProductName][$FieldTypeKey][$policyId]) {
                    $OutputData[$ProductName][$FieldTypeKey].Remove($policyId)

                    # If no more policies for this field type, remove the field type
                    if ($OutputData[$ProductName][$FieldTypeKey].Count -eq 0) {
                        $OutputData[$ProductName].Remove($FieldTypeKey)
                    }

                    # If no more field types for this product, remove the product
                    if ($OutputData[$ProductName].Count -eq 0) {
                        $OutputData.Remove($ProductName)
                    }
                }
            } else {
                # Normal structure: Product -> PolicyId -> FieldType -> Data
                if ($OutputData[$ProductName] -and $OutputData[$ProductName][$policyId]) {
                    $OutputData[$ProductName].Remove($policyId)

                    # If no more policies for this product, remove the product
                    if ($OutputData[$ProductName].Count -eq 0) {
                        $OutputData.Remove($ProductName)
                    }
                }
            }

            # Clear all field values for all fields
            foreach ($inputData in $validInputFields) {
                $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
                if ($FieldListDef) {
                    foreach ($field in $FieldListDef.fields)
                    {
                        $fieldName = ($policyId.replace('.', '_') + "_" + $inputData + "_" + $field.name)

                        if ($field.type -eq "array") {
                            # Clear list containers
                            $listContainerName = ($fieldName + "_List")
                            $listContainer = $detailsPanel.Children | ForEach-Object {
                                if ($_ -is [System.Windows.Controls.StackPanel]) {
                                    $arrayContainer = $_.Children | Where-Object { $_.Name -eq ($fieldName + "_" + $CardName + "_Container") }
                                    if ($arrayContainer) {
                                        return $arrayContainer.Children | Where-Object { $_.Name -eq $listContainerName }
                                    }
                                } elseif ($_ -is [System.Windows.Controls.TabControl]) {
                                    # Search within tab control
                                    foreach ($tabItem in $_.Items) {
                                        if ($tabItem.Header -eq $FieldListDef.name) {
                                            $tabContent = $tabItem.Content
                                            $arrayContainer = $tabContent.Children | Where-Object { $_.Name -eq ($fieldName + "_" + $CardName + "_Container") }
                                            if ($arrayContainer) {
                                                return $arrayContainer.Children | Where-Object { $_.Name -eq $listContainerName }
                                            }
                                        }
                                    }
                                }
                            } | Select-Object -First 1

                            if ($listContainer) {
                                $listContainer.Children.Clear()
                            }
                        } elseif ($field.type -eq "boolean") {
                            # Reset checkbox
                            $booleanFieldName = ($fieldName + "_" + $CardName + "_CheckBox")
                            $booleanCheckBox = $detailsPanel.Children | ForEach-Object {
                                if ($_ -is [System.Windows.Controls.StackPanel]) {
                                    return $_.Children | Where-Object { $_.Name -eq $booleanFieldName -and $_ -is [System.Windows.Controls.CheckBox] }
                                } elseif ($_ -is [System.Windows.Controls.TabControl]) {
                                    # Search within tab control
                                    foreach ($tabItem in $_.Items) {
                                        if ($tabItem.Header -eq $FieldListDef.name) {
                                            $tabContent = $tabItem.Content
                                            return $tabContent.Children | Where-Object { $_.Name -eq $booleanFieldName -and $_ -is [System.Windows.Controls.CheckBox] }
                                        }
                                    }
                                }
                            } | Select-Object -First 1

                            if ($booleanCheckBox) {
                                $booleanCheckBox.IsChecked = $false
                            }
                        } elseif ($field.type -eq "string") {
                            # Clear text boxes
                            $stringFieldName = ($fieldName + "_" + $CardName + "_TextBox")
                            $stringTextBox = $detailsPanel.Children | ForEach-Object {
                                if ($_ -is [System.Windows.Controls.StackPanel]) {
                                    return $_.Children | Where-Object { $_.Name -eq $stringFieldName -and $_ -is [System.Windows.Controls.TextBox] }
                                } elseif ($_ -is [System.Windows.Controls.TabControl]) {
                                    # Search within tab control
                                    foreach ($tabItem in $_.Items) {
                                        if ($tabItem.Header -eq $FieldListDef.name) {
                                            $tabContent = $tabItem.Content
                                            return $tabContent.Children | Where-Object { $_.Name -eq $stringFieldName -and $_ -is [System.Windows.Controls.TextBox] }
                                        }
                                    }
                                }
                            } | Select-Object -First 1

                            if ($stringTextBox) {
                                $stringTextBox.Text = ""
                            }
                        }
                    }
                }
            }

            # Handle AutoSave removal based on configuration
            if ($OutPolicyOnly -and $SettingsTypeName) {
                # For OutPolicyOnly: Update the settings file after removal (matching save button logic)
                Save-AutoSaveSettings -SettingsType $SettingsTypeName
                Write-DebugOutput -Message "Updated $SettingsTypeName AutoSave file after removal" -Source $this.Name -Level "Info"
            } else {
                # For regular policies: Remove the specific policy AutoSave file
                Remove-AutoSavePolicy -CardName $CardName -PolicyId $policyId
            }

            # Show success message
            $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.LocalePopupMessages.RemoveCardEntrySuccess -f $CardName, $policyId), $syncHash.UIConfigs.localeTitles.Success, "OK", "Information")

            # Update YAML preview to reflect the removal
            #New-YamlPreview

             # Clear the save indicator and hide remove button
            $headerGrid = $this.Parent.Parent.Parent.Children | Where-Object { $_.GetType().Name -eq "Grid" }
            $checkbox = $headerGrid.Children | Where-Object { $_.GetType().Name -eq "CheckBox" }
            $checkbox.Tag = $null

            # Remove the bold formatting from policy header
            $policyInfoStack = $headerGrid.Children | Where-Object { $_.GetType().Name -eq "StackPanel" }
            $policyHeader = $policyInfoStack.Children[0]
            $policyHeader.FontWeight = "SemiBold"

            $this.Visibility = "Collapsed"
            $checkbox.IsChecked = $false
        }
    }.GetNewClosure())

    # Set the Tag property before returning
    $card.Tag = $baselineData

    return $card
}#end New-FieldListsCard