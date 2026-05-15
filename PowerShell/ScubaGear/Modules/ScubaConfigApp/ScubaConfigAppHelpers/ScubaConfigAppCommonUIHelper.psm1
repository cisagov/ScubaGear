
# Add these Functions after the existing UI helper Function
Function Get-UIConfigCriticalValues {
    <#
    .SYNOPSIS
    Extracts unique criticality values from all baseline policies.
    .DESCRIPTION
    This Function scans all product baselines and returns unique criticality values for filter dropdown population.
    #>
    param()

    $criticalityValues = @()

    foreach ($productBaselines in $syncHash.Baselines.PSObject.Properties)
    {
        Write-DebugOutput -Message "Scanning product baselines for criticality values" -Source $MyInvocation.MyCommand -Level "Debug"
        foreach ($baseline in $productBaselines.Value)
        {
            if ($baseline.criticality -and $baseline.criticality -notin $criticalityValues) {
                Write-DebugOutput -Message "Found unique criticality value: $($baseline.criticality)" -Source $MyInvocation.MyCommand -Level "Debug"
                $criticalityValues += $baseline.criticality
            }
        }
    }

    Write-DebugOutput -Message "Found criticality values: $($criticalityValues -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"
    return $criticalityValues | Sort-Object
}

Function Update-CriticalityDropdowns {
    <#
    .SYNOPSIS
    Updates criticality dropdown options based on currently loaded baseline data.
    .DESCRIPTION
    This function refreshes all criticality filter dropdowns to reflect the criticality values
    present in the currently loaded baseline policies.
    #>
    try {
        # Get current criticality values from loaded baselines
        $criticalityValues = Get-UIConfigCriticalValues

        if ($criticalityValues.Count -eq 0) {
            Write-DebugOutput -Message "No criticality values found in loaded baselines" -Source $MyInvocation.MyCommand -Level "Warning"
            return
        }

        Write-DebugOutput -Message "Updating criticality dropdowns with values: $($criticalityValues -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"

        # Update criticality dropdowns for each tab type
        $tabTypes = $syncHash.UIConfigs.baselineControls.controlType

        foreach ($tabType in $tabTypes) {
            $criticalityComboBox = $syncHash."$($tabType)Criticality_ComboBox"

            if ($criticalityComboBox) {
                # Store current selection
                $currentSelection = $null
                if ($criticalityComboBox.SelectedItem) {
                    $currentSelection = $criticalityComboBox.SelectedItem.Tag
                }

                # Clear existing items
                $criticalityComboBox.Items.Clear()

                # Add "All Baselines" option
                $allItem = New-Object System.Windows.Controls.ComboBoxItem
                $allItem.Content = "All Baselines"
                $allItem.Tag = "ALL_BASELINES"
                [void]$criticalityComboBox.Items.Add($allItem)

                # Add specific criticality values
                foreach ($criticality in $criticalityValues) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = "$criticality only"
                    $item.Tag = $criticality
                    [void]$criticalityComboBox.Items.Add($item)
                }

                # Restore previous selection or default to "All"
                $criticalityComboBox.SelectedIndex = 0  # Default to "All Baselines"

                if ($currentSelection -and $currentSelection -ne "ALL_BASELINES") {
                    # Try to restore previous selection
                    for ($i = 0; $i -lt $criticalityComboBox.Items.Count; $i++) {
                        if ($criticalityComboBox.Items[$i].Tag -eq $currentSelection) {
                            $criticalityComboBox.SelectedIndex = $i
                            break
                        }
                    }
                }

                Write-DebugOutput -Message "Updated criticality dropdown for $tabType with $($criticalityValues.Count) values" -Source $MyInvocation.MyCommand -Level "Verbose"
            }
            else {
                Write-DebugOutput -Message "Criticality dropdown not found for tab type: $tabType" -Source $MyInvocation.MyCommand -Level "Warning"
            }
        }

        Write-DebugOutput -Message "Successfully updated all criticality dropdowns" -Source $MyInvocation.MyCommand -Level "Info"
    }
    catch {
        Write-DebugOutput -Message "Error updating criticality dropdowns: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

# Helper Function to find controls in a container
Function Find-UIControlInContainer {
    <#
    .SYNOPSIS
    Finds all controls of a specific type within a container.
    .DESCRIPTION
    This function searches through the visual tree of a WPF container to find and return all controls of a specified type.
    .PARAMETER Container
    The container to search within, which can be a Window, UserControl, or any other WPF container.
    .PARAMETER ControlType
    The type of control to search for, specified as a string (e.g., "TextBox", "ComboBox", etc.).
    #>
    param(
        $Container,
        [string]$ControlType
    )

    $controls = @()

    if ($Container.GetType().Name -eq $ControlType) {
        $controls += $Container
    }

    if ($Container.Children) {
        foreach ($child in $Container.Children) {
            $controls += Find-UIControlInContainer -Container $child -ControlType $ControlType
        }
    }

    if ($Container.Content) {
        $controls += Find-UIControlInContainer -Container $Container.Content -ControlType $ControlType
    }

    return $controls
}

# Recursively find all controls
Function Find-UIControlElement {
    <#
    .SYNOPSIS
    Recursively searches for all control elements within a WPF container.
    .DESCRIPTION
    This Function traverses the visual tree to find and return all control elements contained within a specified parent container.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.DependencyObject]$Parent
    )

    $results = @()

    for ($i = 0; $i -lt [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent); $i++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $i)
        if ($child -is [System.Windows.Controls.Control]) {
            $results += $child
        }
        $results += Find-UIControlElement -Parent $child
    }

    return $results
}

# Function to add event handlers to a specific control (for dynamically created controls)
Function Add-UIControlEventHandler {
    <#
    .SYNOPSIS
    Adds event handlers to dynamically created WPF controls.
    .DESCRIPTION
    This Function attaches appropriate event handlers to different types of WPF controls (TextBox, ComboBox, Button, etc.) for user interaction tracking.
    #>
    param(
        [System.Windows.Controls.Control]$Control
    )

    Write-DebugOutput -Message ("Adding event handlers for {0}: {1}" -f $Control.GetType().Name, $Control.Name) -Source $MyInvocation.MyCommand -Level "Debug"

    switch($Control.GetType().Name) {
        'TextBox' {
            # Add LostFocus event
            $Control.Add_LostFocus({
                $controlName = if ($this.Name) { $this.Name } else { "Unnamed TextBox" }
                $controlValue = $this.Text
                Write-DebugOutput -Message ("{0} [{1}] changed value to: {2}" -f $Control.GetType().Name, $controlName, $controlValue) -Source $MyInvocation.MyCommand -Level "Info"
            }.GetNewClosure())
            Write-DebugOutput -Message "Added LostFocus event handler to TextBox: $($Control.Name)" -Source $MyInvocation.MyCommand -Level "Debug"
        }
        'ComboBox' {
            # Add SelectionChanged event
            $Control.Add_SelectionChanged({
                $controlName = if ($this.Name) { $this.Name } else { "Unnamed ComboBox" }
                $selectedItem = $this.SelectedItem

                # Get the actual value instead of the ComboBoxItem object
                $actualValue = if ($selectedItem) {
                    if ($selectedItem.Tag) {
                        $selectedItem.Tag
                    } elseif ($selectedItem.Content) {
                        $selectedItem.Content
                    } else {
                        $selectedItem.ToString()
                    }
                } else {
                    "null"
                }

                Write-DebugOutput -Message ("{0} [{1}] changed value to: {2}" -f $this.GetType().Name, $controlName, $actualValue) -Source $MyInvocation.MyCommand -Level "Info"
            }.GetNewClosure())
            Write-DebugOutput -Message "Added SelectionChanged event handler to ComboBox: $($Control.Name)" -Source $MyInvocation.MyCommand -Level "Debug"
        }
        'Button' {
            # Add Click event
            $Control.Add_Click({
                $controlName = if ($this.Name) { $this.Name } else { "Unnamed Button" }
                Write-DebugOutput -Message ("{0} [{1}] was pressed" -f $Control.GetType().Name, $controlName) -Source $MyInvocation.MyCommand -Level "Info"
            }.GetNewClosure())
            Write-DebugOutput -Message "Added Click event handler to Button: $($Control.Name)" -Source $MyInvocation.MyCommand -Level "Debug"
        }
        'CheckBox' {
            # Add Checked event
            $Control.Add_Checked({
                $controlName = if ($this.Name) { $this.Name } else { "Unnamed CheckBox" }
                Write-DebugOutput -Message ("{0} [{1}] was checked" -f $Control.GetType().Name, $controlName) -Source $MyInvocation.MyCommand -Level "Info"
            }.GetNewClosure())

            # Add Unchecked event
            $Control.Add_Unchecked({
                $controlName = if ($this.Name) { $this.Name } else { "Unnamed CheckBox" }
                Write-DebugOutput -Message ("{0} [{1}] was unchecked" -f $Control.GetType().Name, $controlName) -Source $MyInvocation.MyCommand -Level "Info"
            }.GetNewClosure())
            Write-DebugOutput -Message "Added Checked/Unchecked event handlers to CheckBox: $($Control.Name)" -Source $MyInvocation.MyCommand -Level "Debug"
        }
    }
}

# Helper Function to find control by setting name
Function Find-UIFieldBySettingName {
    <#
    .SYNOPSIS
    Searches for WPF controls using various naming conventions.
    .DESCRIPTION
    This Function attempts to locate controls by trying multiple naming patterns and conventions commonly used in the application.
    #>
    param([string]$SettingName)

    Write-DebugOutput "Searching for control by setting name: $SettingName" -Source $MyInvocation.MyCommand -Level "Debug"

    # Define naming patterns to try
    $namingPatterns = @(
        $SettingName,                           # Direct name
        "$SettingName`_TextBox"                # SettingName_TextBox
        "$SettingName`_TextBlock"              # SettingName_TextBlock
        "$SettingName`_CheckBox"               # SettingName_CheckBox
        "$SettingName`_ComboBox"               # SettingName_ComboBox
        "$SettingName`_Label"                  # SettingName_Label
        "$SettingName`TextBox"                 # SettingNameTextBox
        "$SettingName`TextBlock"               # SettingNameTextBlock
        "$SettingName`CheckBox"                # SettingNameCheckBox
        "$SettingName`ComboBox"                # SettingNameComboBox
        "$SettingName`Label"                   # SettingNameLabel
    )

    Write-DebugOutput "Trying $($namingPatterns.Count) naming patterns for '$SettingName'" -Source $MyInvocation.MyCommand -Level "Verbose"

    # Try each pattern
    foreach ($pattern in $namingPatterns) {
        if ($syncHash.$pattern) {
            Write-DebugOutput "Found control '$pattern' for setting '$SettingName'" -Source $MyInvocation.MyCommand -Level "Debug"
            return $syncHash.$pattern
        }
    }

    Write-DebugOutput "No control found for setting '$SettingName' after trying all patterns" -Source $MyInvocation.MyCommand -Level "Error"
    return $null
}

# Function to search recursively for controls
Function Find-UIControlByName {
    <#
    .SYNOPSIS
    Recursively searches for a control by name within a parent container.
    .DESCRIPTION
    This nested Function traverses the visual tree to locate a control with a specific name.
    #>
    param($parent, $targetName)

    if ($parent.Name -eq $targetName) {
        return $parent
    }

    if ($parent.Children) {
        foreach ($child in $parent.Children) {
            $result = Find-UIControlByName -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Content -and $parent.Content.Children) {
        foreach ($child in $parent.Content.Children) {
            $result = Find-UIControlByName -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Items) {
        foreach ($item in $parent.Items) {
            if ($item.Content -and $item.Content.Children) {
                foreach ($child in $item.Content.Children) {
                    $result = Find-UIControlByName -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }
        }
    }

    return $null
}

# Helper Function to update control value based on type
Function Set-UIControlValue {
    <#
    .SYNOPSIS
    Updates control values based on their type and handles focus preservation.
    .DESCRIPTION
    This Function sets values on different types of WPF controls while preserving cursor position and preventing timer interference.
    #>
    param(
        [object]$Control,
        [string[]]$Value,
        [string]$SettingKey
    )

    Write-DebugOutput -Message "Setting control value for $SettingKey on $($Control.GetType().Name)" -Source $MyInvocation.MyCommand -Level "Debug"

    switch ($Control.GetType().Name) {
        'TextBox' {
            # Clear placeholder styling if present
            if ($Control.Tag -eq "Placeholder") {
                $Control.Tag = "HasValue"
                $Control.Foreground = [System.Windows.Media.Brushes]::Black
                $Control.FontStyle = [System.Windows.FontStyles]::Normal
            }

            # Handle different value types appropriately
            if ($Value -is [array]) {
                $Control.Text = $Value -join ", "  # Join arrays with commas
            } else {
                $Control.Text = $Value    # Convert other types to string
            }
            $Control.UpdateLayout()
            Write-DebugOutput -Message "Successfully set TextBox value for $SettingKey to: $Value" -Source $MyInvocation.MyCommand -Level "Verbose"
        }
        'TextBlock' {
            <# Skip updating if user is currently typing in this control
            if ($Control.IsFocused -and $Control.IsKeyboardFocused) {
                return
            }
            #>
            $Control.Text = $Value
            $Control.UpdateLayout()

        }
        'CheckBox' {
            $Control.IsChecked = [bool]$Value
        }
        'ComboBox' {
            Set-UIComboBoxValue -ComboBox $Control -Value $Value -SettingKey $SettingKey
        }
        'Label' {
            $Control.Content = $Value
        }
        'String' {
            # Skip updating if user is currently typing in this control
            if ($Control.IsFocused -and $Control.IsKeyboardFocused) {
                return
            }
            $syncHash.$Control = $Value
        }
        default {
            Write-DebugOutput -Message ("Setting warning for {0}: {1}" -f $SettingKey,$Control.GetType().Name) -Source $MyInvocation.MyCommand -Level "Error"
        }
    }
}

# Function to search recursively for the list container
Function Find-UIListContainer {
    <#
    .SYNOPSIS
    Recursively searches for a list container control by name.
    .DESCRIPTION
    This nested Function traverses the WPF control hierarchy to locate a list container used for array field values.
    #>

    param($parent, $targetName)

    if ($parent.Name -eq $targetName) {
        return $parent
    }

    if ($parent.Children) {
        foreach ($child in $parent.Children) {
            $result = Find-UIListContainer -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Content -and $parent.Content.Children) {
        foreach ($child in $parent.Content.Children) {
            $result = Find-UIListContainer -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Items) {
        foreach ($item in $parent.Items) {
            if ($item.Content -and $item.Content.Children) {
                foreach ($child in $item.Content.Children) {
                    $result = Find-UIListContainer -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }
        }
    }

    return $null
}

# Function to search recursively for the checkbox
Function Find-UICheckBox {
    <#
    .SYNOPSIS
    Recursively searches for a CheckBox control by name.
    .DESCRIPTION
    This nested Function traverses the WPF control hierarchy to locate a specific CheckBox control used for boolean field values.
    #>
    param($parent, $targetName)

    if ($parent.Name -eq $targetName -and $parent -is [System.Windows.Controls.CheckBox]) {
        return $parent
    }

    if ($parent.Children) {
        foreach ($child in $parent.Children) {
            $result = Find-UICheckBox -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Content -and $parent.Content.Children) {
        foreach ($child in $parent.Content.Children) {
            $result = Find-UICheckBox -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Items) {
        foreach ($item in $parent.Items) {
            if ($item.Content -and $item.Content.Children) {
                foreach ($child in $item.Content.Children) {
                    $result = Find-UICheckBox -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }
        }
    }

    return $null
}

# Function to search recursively for the textbox
Function Find-UITextBox {
    <#
    .SYNOPSIS
    Recursively searches for a TextBox control by name.
    .DESCRIPTION
    This nested Function traverses the WPF control hierarchy to locate a specific TextBox control used for string field values.
    #>
    param($parent, $targetName)

    if ($parent.Name -eq $targetName -and $parent -is [System.Windows.Controls.TextBox]) {
        return $parent
    }

    if ($parent.Children) {
        foreach ($child in $parent.Children) {
            $result = Find-UITextBox -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Content -and $parent.Content.Children) {
        foreach ($child in $parent.Content.Children) {
            $result = Find-UITextBox -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Items) {
        foreach ($item in $parent.Items) {
            if ($item.Content -and $item.Content.Children) {
                foreach ($child in $item.Content.Children) {
                    $result = Find-UITextBox -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }
        }
    }

    return $null
}

Function Find-UIDatePicker {
    <#
    .SYNOPSIS
    Recursively searches for a DatePicker control by name.
    .DESCRIPTION
    This nested Function traverses the WPF control hierarchy to locate a specific DatePicker control used for date field values.
    #>
    param($parent, $targetName)

    if ($parent.Name -eq $targetName -and $parent -is [System.Windows.Controls.DatePicker]) {
        return $parent
    }

    if ($parent.Children) {
        foreach ($child in $parent.Children) {
            $result = Find-UIDatePicker -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Content -and $parent.Content.Children) {
        foreach ($child in $parent.Content.Children) {
            $result = Find-UIDatePicker -parent $child -targetName $targetName
            if ($result) { return $result }
        }
    }

    if ($parent.Items) {
        foreach ($item in $parent.Items) {
            if ($item.Content -and $item.Content.Children) {
                foreach ($child in $item.Content.Children) {
                    $result = Find-UIDatePicker -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }
        }
    }

    return $null
}

# Helper Function to update ComboBox values
Function Set-UIComboBoxValue {
    <#
    .SYNOPSIS
    Updates ComboBox control selection to match a specified value.
    .DESCRIPTION
    This Function sets the selected item in a ComboBox control by matching the provided value against available items.
    #>
    param(
        [System.Windows.Controls.ComboBox]$ComboBox,
        [object]$Value,
        [string]$SettingKey
    )

    # Default ComboBox handling for other ComboBoxes
    # Try to find item by Tag first (common for environment selection)
    $selectedItem = $ComboBox.Items | Where-Object { $_.Tag -eq $Value }

    # If not found, try by Content
    if (-not $selectedItem) {
        $selectedItem = $ComboBox.Items | Where-Object { $_.Content -eq $Value }
    }

    # If still not found, try by string representation
    if (-not $selectedItem) {
        $selectedItem = $ComboBox.Items | Where-Object { $_.ToString() -eq $Value }
    }

    if ($selectedItem) {
        $syncHash.Window.Dispatcher.Invoke([Action]{
            $ComboBox.SelectedItem = $selectedItem
            $ComboBox.UpdateLayout()
            $ComboBox.InvalidateVisual()
            Write-DebugOutput -Message ("Setting ComboBox info for {0}: {1}" -f $SettingKey,$Value) -Source $MyInvocation.MyCommand -Level "Verbose"
        })
    } else {
        Write-DebugOutput -Message ("Could not find ComboBox [{0}] with value: {1}" -f $SettingKey,$Value) -Source $MyInvocation.MyCommand -Level "Error"
    }
}

# Function to validate UI field based on regex and required status
Function Confirm-UIRequiredField {
    <#
    .SYNOPSIS
    Confirms that a required field is filled out correctly.
    .DESCRIPTION
    This function checks if a UI element (e.g., TextBox, ComboBox) meets the specified requirements, such as being filled out and matching a regex pattern.
    .PARAMETER UIElement
    The UI element to validate, which can be a TextBox, ComboBox, etc.
    .PARAMETER RegexPattern
    The regex pattern to validate the field content against.
    .PARAMETER ErrorMessage
    The message to display if validation fails.
    .PARAMETER PlaceholderText
    Optional placeholder text to check against empty fields.
    .PARAMETER ShowMessageBox
    If specified, shows a message box with the error message if validation fails.
    .PARAMETER TestPath
    If specified, tests if the path exists for the current value.
    .PARAMETER RequiredFiles
    An array of required files to check for existence within the specified path.
    #>
    param(
        [System.Windows.Controls.Control]$UIElement,
        [string]$RegexPattern,
        [string]$ErrorMessage,
        [string]$PlaceholderText = "",
        [switch]$ShowMessageBox,
        [switch]$TestPath,
        [string[]]$RequiredFiles
    )

    $isValid = $true
    $currentValue = ""

    Write-DebugOutput -Message "Validating field: $($UIElement.Name) with regex: $RegexPattern" -Source $MyInvocation.MyCommand -Level "Debug"

    # Get the current value based on control type
    if ($UIElement -is [System.Windows.Controls.TextBox]) {
        $currentValue = $UIElement.Text
        Write-DebugOutput -Message "TextBox '$($UIElement.Name)' current value: $currentValue" -Source $MyInvocation.MyCommand -Level "Verbose"
    } elseif ($UIElement -is [System.Windows.Controls.ComboBox]) {
        $currentValue = $UIElement.SelectedItem
        Write-DebugOutput -Message "ComboBox '$($UIElement.Name)' current value: $currentValue" -Source $MyInvocation.MyCommand -Level "Verbose"
    }

    # Check if field is required and empty/placeholder
    if (([string]::IsNullOrWhiteSpace($currentValue) -or $currentValue -eq $PlaceholderText)) {
        $isValid = $false
    }
    # Check regex pattern if provided and field has content
    elseif (![string]::IsNullOrWhiteSpace($RegexPattern) -and
            ![string]::IsNullOrWhiteSpace($currentValue) -and
            $currentValue -ne $PlaceholderText -and
            -not ($currentValue -match $RegexPattern)) {
        $isValid = $false
    }
    # Check path existence if TestPath is specified
    elseif ($TestPath -and ![string]::IsNullOrWhiteSpace($currentValue) -and $currentValue -ne $PlaceholderText) {
        if (-not (Test-Path $currentValue)) {
            $isValid = $false
        }
        # Check for required files if specified
        elseif ($null -ne $RequiredFiles) {
            $foundRequiredFile = $false
            foreach ($requiredFile in $RequiredFiles) {
                $fullPath = Join-Path $currentValue $requiredFile
                if (Test-Path $fullPath) {
                    $foundRequiredFile = $true
                    break
                }
            }
            if (-not $foundRequiredFile) {
                $isValid = $false
            }
        }
    }

    # Apply visual feedback
    if ($UIElement -is [System.Windows.Controls.TextBox]) {
        if (-not $isValid) {
            Write-DebugOutput "Validation failed - applying red border to TextBox: $($UIElement.Name)" -Source "Confirm-UIRequiredField" -Level "Debug"
            $UIElement.BorderBrush = [System.Windows.Media.Brushes]::Red
            $UIElement.BorderThickness = "2"
        } else {
            Write-DebugOutput "Validation passed - applying gray border to TextBox: $($UIElement.Name)" -Source "Confirm-UIRequiredField" -Level "Debug"
            $UIElement.BorderBrush = [System.Windows.Media.Brushes]::Gray
            $UIElement.BorderThickness = "1"
        }
    }

    # Show error message if requested
    if (-not $isValid -and $ShowMessageBox -and ![string]::IsNullOrWhiteSpace($ErrorMessage)) {
        Write-DebugOutput "Displaying validation error message: $ErrorMessage" -Source "Confirm-UIRequiredField" -Level "Verbose"
        $syncHash.ShowMessageBox.Invoke($ErrorMessage, $syncHash.UIConfigs.localeTitles.ValidationError, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    }

    Write-DebugOutput "Validation result for $($UIElement.Name): $isValid" -Source "Confirm-UIRequiredField" -Level "Debug"
    return $isValid
}

# Function to initialize placeholder text behavior for TextBox controls
Function Initialize-PlaceholderTextBox {
    <#
    .SYNOPSIS
    Configures placeholder text behavior for TextBox controls.
    .DESCRIPTION
    This Function sets up placeholder text that appears when TextBox controls are empty and manages the visual styling for placeholder display.
    #>
    param(
        [System.Windows.Controls.TextBox]$TextBox,
        [string]$PlaceholderText,
        [string]$InitialValue = $null
    )

    Write-DebugOutput "Initializing placeholder text for TextBox '$($TextBox.Name)' with placeholder '$PlaceholderText'" -Source "Initialize-PlaceholderTextBox" -Level "Debug"

    # Set initial state
    if (![string]::IsNullOrWhiteSpace($InitialValue)) {
        Write-DebugOutput "Setting initial value: '$InitialValue'" -Source "Initialize-PlaceholderTextBox" -Level "Verbose"
        $TextBox.Text = $InitialValue
        $TextBox.Foreground = [System.Windows.Media.Brushes]::Black
        $TextBox.FontStyle = [System.Windows.FontStyles]::Normal
        $TextBox.Tag = "HasValue"
    } else {
        Write-DebugOutput "Setting placeholder text display" -Source "Initialize-PlaceholderTextBox" -Level "Verbose"
        $TextBox.Text = $PlaceholderText
        $TextBox.Foreground = [System.Windows.Media.Brushes]::Gray
        $TextBox.FontStyle = [System.Windows.FontStyles]::Italic
        $TextBox.Tag = "Placeholder"
    }

    Write-DebugOutput "Adding GotFocus and LostFocus event handlers" -Source "Initialize-PlaceholderTextBox" -Level "Verbose"

    # Add GotFocus event handler
    $TextBox.Add_GotFocus({
        # Check by text content, not just Tag
        if ($this.Text -eq $PlaceholderText) {
            $this.Text = ""
            $this.Foreground = [System.Windows.Media.Brushes]::Black
            $this.FontStyle = [System.Windows.FontStyles]::Normal
            $this.Tag = "HasValue"
        }
    }.GetNewClosure())

    # Add LostFocus event handler
    $TextBox.Add_LostFocus({
        # Check if text is empty or whitespace
        if ([string]::IsNullOrWhiteSpace($this.Text)) {
            $this.Text = $PlaceholderText
            $this.Foreground = [System.Windows.Media.Brushes]::Gray
            $this.FontStyle = [System.Windows.FontStyles]::Italic
            $this.Tag = "Placeholder"
        } else {
            $this.Tag = "HasValue"
        }
    }.GetNewClosure())
}


# Create a new validation helper function
Function Invoke-RequiredFieldValidation {
    <#
    .SYNOPSIS
    Performs dynamic validation based on the requiredFields configuration
    .DESCRIPTION
    This function validates required fields based on JSON configuration, handling both always-required fields and conditionally-required fields based on toggle states
    #>

    $validationResults = @{
        IsValid = $true
        Errors = @()
        TabsToNavigate = @()
    }

    try {
        Write-DebugOutput -Message "Starting required field validation" -Source $MyInvocation.MyCommand -Level "Verbose"

        # Get required fields configuration
        $requiredFields = $syncHash.UIConfigs.requiredFields

        foreach ($fieldKey in $requiredFields.PSObject.Properties.Name) {
            $fieldConfig = $requiredFields.$fieldKey
            $shouldValidate = $false

            Write-DebugOutput -Message "Processing required field: $fieldKey" -Source $MyInvocation.MyCommand -Level "Verbose"

            # Determine if this field should be validated based on trigger
            switch ($fieldConfig.toggleTrigger) {
                "OnClick" {
                    # Always validate these fields
                    $shouldValidate = $true
                    Write-DebugOutput -Message "Field $fieldKey is always required (OnClick)" -Source $MyInvocation.MyCommand -Level "Verbose"
                }
                default {
                    # Check if the toggle is checked for conditional validation
                    $toggleControl = $syncHash.($fieldConfig.toggleTrigger)
                    if ($toggleControl -and $toggleControl -is [System.Windows.Controls.CheckBox]) {
                        $shouldValidate = $toggleControl.IsChecked
                        Write-DebugOutput -Message "Field $fieldKey conditional validation - Toggle $($fieldConfig.toggleTrigger) is checked: $shouldValidate" -Source $MyInvocation.MyCommand -Level "Verbose"
                    } else {
                        Write-DebugOutput -Message "Toggle control $($fieldConfig.toggleTrigger) not found for field $fieldKey" -Source $MyInvocation.MyCommand -Level "Warning"
                    }
                }
            }

            if ($shouldValidate) {
                # Get the UI element
                $uiElement = $syncHash.($fieldConfig.fieldName)

                if (-not $uiElement) {
                    Write-DebugOutput -Message "UI element $($fieldConfig.fieldName) not found for field $fieldKey" -Source $MyInvocation.MyCommand -Level "Warning"
                    continue
                }

                # Get validation pattern
                $validationPattern = $null
                $placeholderText = ""

                if ($fieldConfig.validationPatternName -and $syncHash.UIConfigs.valueValidations.($fieldConfig.validationPatternName)) {
                    $validationPattern = $syncHash.UIConfigs.valueValidations.($fieldConfig.validationPatternName).pattern
                }

                if ($syncHash.UIConfigs.localePlaceholder.($fieldConfig.fieldName)) {
                    $placeholderText = $syncHash.UIConfigs.localePlaceholder.($fieldConfig.fieldName)
                }

                # Perform validation based on field type
                $isFieldValid = $false

                if ($fieldKey -eq "OPAPath") {
                    # Special validation for OPA path
                    $isFieldValid = Confirm-UIRequiredField -UIElement $uiElement `
                                                      -PlaceholderText $placeholderText `
                                                      -TestPath `
                                                      -RequiredFiles @("opa_windows_amd64.exe", "opa.exe")
                } else {
                    # Standard validation
                    $isFieldValid = Confirm-UIRequiredField -UIElement $uiElement `
                                                      -RegexPattern $validationPattern `
                                                      -PlaceholderText $placeholderText
                }

                if (-not $isFieldValid) {
                    $validationResults.IsValid = $false

                    # Get error message
                    $errorKey = $fieldKey + "Validation"
                    if ($syncHash.UIConfigs.localeErrorMessages.$errorKey) {
                        $errorMessage = $syncHash.UIConfigs.localeErrorMessages.$errorKey
                    } else {
                        $errorMessage = "Field '$fieldKey' is required and must be valid."
                    }

                    $validationResults.Errors += $errorMessage

                    # Find which tab this field belongs to
                    $tabToNavigate = Find-TabForField -FieldKey $fieldKey
                    if ($tabToNavigate -and $tabToNavigate -notin $validationResults.TabsToNavigate) {
                        $validationResults.TabsToNavigate += $tabToNavigate
                    }

                    Write-DebugOutput -Message "Validation failed for field $fieldKey in tab $tabToNavigate" -Source $MyInvocation.MyCommand -Level "Info"
                }
            }
        }

        # Special validation for ProductNames (not in requiredFields but still required)
        $minimumRequired = if ($syncHash.UIConfigs.MinimumProductsRequired) { $syncHash.UIConfigs.MinimumProductsRequired } else { 1 }
        if (-not $syncHash.GeneralSettingsData.ProductNames -or $syncHash.GeneralSettingsData.ProductNames.Count -lt $minimumRequired) {
            $validationResults.IsValid = $false
            $validationResults.Errors += ($syncHash.UIConfigs.localeErrorMessages.ProductSelection -f $minimumRequired)

            $tabToNavigate = Find-TabForField -FieldKey "ProductNames"
            if ($tabToNavigate -and $tabToNavigate -notin $validationResults.TabsToNavigate) {
                $validationResults.TabsToNavigate += $tabToNavigate
            }
        }

        Write-DebugOutput -Message "Validation completed. Valid: $($validationResults.IsValid), Errors: $($validationResults.Errors.Count)" -Source $MyInvocation.MyCommand -Level "Info"

    } catch {
        Write-DebugOutput -Message "Error in validation: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        $validationResults.IsValid = $false
        $validationResults.Errors += "Validation system error: $($_.Exception.Message)"
    }

    return $validationResults
}

Function Find-TabForField {
    <#
    .SYNOPSIS
    Finds which tab a field belongs to based on settingsControl configuration
    .DESCRIPTION
    Uses the settingsControl mapping to determine which tab contains a specific field
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FieldKey
    )

    try {
        $settingsControls = $syncHash.UIConfigs.settingsControl

        foreach ($tabName in $settingsControls.PSObject.Properties.Name) {
            $tabConfig = $settingsControls.$tabName

            if ($tabConfig.validationKeys -and $tabConfig.validationKeys -contains $FieldKey) {
                # Map tab names to actual tab controls
                switch ($tabName) {
                    "MainTab" { return $syncHash.MainTab }
                    "AdvancedTab" { return $syncHash.AdvancedTab }
                    "GlobalTab" { return $syncHash.GlobalTab }
                    default {
                        # Try to find tab by name
                        $tabControl = $syncHash.$tabName
                        if ($tabControl) {
                            return $tabControl
                        }
                    }
                }
            }
        }

        # Fallback - if not found, return MainTab
        Write-DebugOutput -Message "Tab not found for field $FieldKey, defaulting to MainTab" -Source $MyInvocation.MyCommand -Level "Warning"
        return $syncHash.MainTab

    } catch {
        Write-DebugOutput -Message "Error finding tab for field $FieldKey`: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        return $syncHash.MainTab
    }
}

Function Switch-FirstErrorTab {
    <#
    .SYNOPSIS
    Navigates to the first tab that contains validation errors
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$TabsToNavigate
    )

    if ($TabsToNavigate.Count -gt 0) {
        # Navigate to the first tab with errors
        $firstTab = $TabsToNavigate[0]
        $syncHash.MainTabControl.SelectedItem = $firstTab

        Write-DebugOutput -Message "Navigated to tab with validation errors" -Source $MyInvocation.MyCommand -Level "Info"
    }
}