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
    $fieldLabel.Text = $Field.name
    $fieldLabel.FontWeight = "SemiBold"
    $fieldLabel.Margin = "0,0,0,4"
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

# Updated Function to create a field card UI element that handles multiple fields
Function New-FieldListCard {
    <#
    .SYNOPSIS
    Creates a comprehensive field card UI element for policy configuration.
    .DESCRIPTION
    This Function generates a complete card interface with checkboxes, input fields, tabs, and buttons for configuring multiple field types within policy settings including baselineControl tabs.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "ProductName")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "OutputData")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "FlipFieldValueAndPolicyId")]
    param(
        [string]$CardName,
        [string]$PolicyId,
        [string]$ProductName,
        [string]$PolicyName,
        [string]$PolicyDescription,
        [string]$Criticality,
        [string[]]$FieldList,  # Can be string or array
        $OutputData,
        [switch]$ShowFieldType,
        [switch]$ShowDescription,
        [switch]$FlipFieldValueAndPolicyId
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
    #$checkbox.Content = "▶"  # Right-pointing triangle when collapsed
    $checkbox.FontSize = 14
    $checkbox.FontWeight = "Bold"
    $checkbox.Foreground = $syncHash.Window.FindResource("PrimaryBrush")
    # Remove the default checkbox appearance
    $checkbox.Template = $null
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

        # Get the details panel (parent of button panel)
        $detailsPanel = $this.Parent.Parent

        # Validate required fields BEFORE processing data
        $missingRequiredFields = Test-RequiredField -detailsPanel $detailsPanel -validInputFields $validInputFields -policyId $policyId -CardName $CardName

            if ($missingRequiredFields.Count -gt 0) {
                $errorMessage = if ($missingRequiredFields.Count -eq 1) {
                    $syncHash.UIConfigs.localeErrorMessages.RequiredFieldValidation -f $missingRequiredFields[0]
                } else {
                    $syncHash.UIConfigs.localeErrorMessages.RequiredFieldsValidation -f ($missingRequiredFields -join ", ")
                }

                $syncHash.ShowMessageBox.Invoke($errorMessage, $syncHash.UIConfigs.localeTitles.RequiredFieldsMissing, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
                return # Exit save operation if validation fails
            }        # Initialize output data structure
        If($FlipFieldValueAndPolicyId) {
            # For annotations/omissions: Product -> FieldType -> PolicyId -> Data
            # Get the yamlValue from the baseline control that uses this input type
            $baselineControl = $syncHash.UIConfigs.baselineControls | Where-Object { $_.defaultFields -eq $validInputFields[0] }
            $NestedKey = if ($baselineControl) { $baselineControl.yamlValue } else { $validInputFields[0] }
            $PolicyKey = $policyId            # The actual policy ID becomes nested under FieldType
        } else {
            # Normal structure: Product -> PolicyId -> FieldType -> Data
            $NestedKey = $policyId
            $PolicyKey = $validInputFields[0]  # Use the first valid input field name
        }

        # Initialize structure
        if (-not $OutputData[$ProductName]) {
            $OutputData[$ProductName] = [ordered]@{}
        }
        if (-not $OutputData[$ProductName][$NestedKey]) {
            $OutputData[$ProductName][$NestedKey] = [ordered]@{}
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
                if ($FlipFieldValueAndPolicyId) {
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
                        # Initialize the exclusion type container if it doesn't exist
                        if (-not $OutputData[$ProductName][$NestedKey][$FieldListValue]) {
                            $OutputData[$ProductName][$NestedKey][$FieldListValue] = @{}
                        }

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
                Write-DebugOutput -Message ("No entries collected for {0} fields: {1}" -f $CardName.ToLower(), $inputData) -Source $this.Name -Level "Info"
            }
        }

        if ($hasOutputData) {
            # Log the final merged structure
            $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.LocalePopupMessages.CardSavedSuccess -f $CardName, $ProductName, $policyId, ($savedinputTypes -join ', ')), $syncHash.UIConfigs.localeTitles.Success, "OK", "Information")

            # Update YAML preview to reflect the changes
            #New-YamlPreview

            # Make remove button visible and header bold
            $removeButton.Visibility = "Visible"
            $policyHeader.FontWeight = "Bold"

            # Collapse details panel and uncheck checkbox
            $detailsPanel.Visibility = "Collapsed"
            $checkbox.IsChecked = $false
        } else {
            Write-DebugOutput -Message ("No entries found for {0} fields: {1}" -f $CardName.ToLower(), $inputData) -Source $this.Name -Level "Error"
            $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.LocalePopupMessages.NoEntriesFound -f $CardName.ToLower()), $syncHash.UIConfigs.localeTitles.ValidationError, "OK", "Warning")
        }
    }.GetNewClosure())


    # Enhanced remove button click handler for multiple exclusionFields
    $removeButton.Add_Click({
        $policyIdWithUnderscores = $this.Name.Replace(("_" + $CardName + "_RemoveButton"), "")
        $policyId = $policyIdWithUnderscores.Replace("_", ".")

        $result = $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.LocalePopupMessages.RemoveCardPolicyConfirmation -f $CardName.ToLower(), $policyId), $syncHash.UIConfigs.localeTitles.ConfirmRemove, "YesNo", "Question")
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {

            # Remove the policy from the nested structure
            if ($OutputData[$ProductName] -and $OutputData[$ProductName][$policyId]) {
                $OutputData[$ProductName].Remove($policyId)

                # If no more policies for this product, remove the product
                if ($OutputData[$ProductName].Count -eq 0) {
                    $OutputData.Remove($ProductName)
                }
            }

            # Clear all field values for all exclusionFields
            foreach ($inputData in $validInputFields) {
                $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
                if ($FieldListDef) {
                    foreach ($field in $FieldListDef.fields) {
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

            $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.LocalePopupMessages.RemoveCardEntrySuccess -f $CardName, $policyId), $syncHash.UIConfigs.localeTitles.Success, "OK", "Information")

            # Update YAML preview to reflect the removal
            New-YamlPreview

            # Hide remove button and unbold header
            $this.Visibility = "Collapsed"
            $policyHeader.FontWeight = "SemiBold"
            $checkbox.IsChecked = $false
        }
    }.GetNewClosure())

    # Set the Tag property before returning
    $card.Tag = $baselineData

    return $card
}#end New-FieldListsCard