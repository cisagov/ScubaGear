
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

    foreach ($productBaselines in $syncHash.Baselines.PSObject.Properties) {
        foreach ($baseline in $productBaselines.Value) {
            if ($baseline.criticality -and $baseline.criticality -notin $criticalityValues) {
                $criticalityValues += $baseline.criticality
            }
        }
    }

    return $criticalityValues | Sort-Object
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