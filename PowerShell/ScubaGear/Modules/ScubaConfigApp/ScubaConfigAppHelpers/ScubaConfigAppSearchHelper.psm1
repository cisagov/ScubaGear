Function Show-SearchAndFilterControl{
    <#
    .SYNOPSIS
    Initializes search and filter controls for all tabs.
    .DESCRIPTION
    This Function sets up search boxes, filter dropdowns, and their event handlers for baselineControl tabs.
    #>
    param()

    Write-DebugOutput -Message "Showing search and filter controls" -Source $MyInvocation.MyCommand -Level "Info"
    #Show all search and filter controls
    Foreach($item in $synchash.UIConfigs.baselineControls) {
        $SearchAndFilterBorder = ($item.controlType + "SearchAndFilterBorder")
        $synchash.$SearchAndFilterBorder.Visibility = [System.Windows.Visibility]::Visible
    }

    # Add search and filter capability to each tab
    Add-SearchAndFilterCapability
}

Function Hide-SearchAndFilterControl {
    <#
    .SYNOPSIS
    Hides search and filter controls for all tabs.
    .DESCRIPTION
    This Function hides all search boxes and filter dropdowns for baselineControl tabs.
    #>
    param()

    Write-DebugOutput -Message "Hiding search and filter controls" -Source $MyInvocation.MyCommand -Level "Info"

    # Hide all search and filter controls
    Foreach($item in $synchash.UIConfigs.baselineControls) {
        $SearchAndFilterBorder = ($item.controlType + "SearchAndFilterBorder")
        $synchash.$SearchAndFilterBorder.Visibility = [System.Windows.Visibility]::Collapsed
    }
}



# Find the Add-SearchAndFilterCapability Function and modify it to defer initial filtering:

Function Add-SearchAndFilterCapability {
    <#
    .SYNOPSIS
    Initializes search and filter controls for all tabs.
    .DESCRIPTION
    This Function sets up search boxes, filter dropdowns, and their event handlers for baselineControl tabs.
    #>
    param()


    # Get unique criticality values dynamically from baseline data
    $criticalityValues = Get-UIConfigCriticalValues

    # Initialize for each tab type
    $tabTypes = $synchash.UIConfigs.baselineControls.controlType

    foreach ($tabType in $tabTypes)
    {
        Write-DebugOutput -Message "Initializing search and filter for $tabType tab" -Source $MyInvocation.MyCommand -Level "Verbose"

        #Clear the search and filter controls when product tabs are switched (sub tabs)
        #this fixes the issue where policies are blanked out when switching tabs
        $productTabControl = $syncHash."$($tabType)ProductTabControl"
        if ($productTabControl) {
            $productTabControl.Add_SelectionChanged({

                # Get the tab type from the sender control name
                $tabControlName = $this.Name
                $currentTabType = $tabControlName -replace 'ProductTabControl', ''

                # Get the clear search button for this tab type
                $clearButton = $syncHash."$($currentTabType)ClearSearch_Button"

                if ($clearButton) {
                    try {
                        # Programmatically trigger the clear search button click
                        $clearButton.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
                        Write-DebugOutput -Message "Auto-cleared search for $currentTabType when switching product tabs" -Source $MyInvocation.MyCommand -Level "Debug"
                    } catch {
                        # Fallback: manually clear the search and apply filter
                        $searchBox = $syncHash."$($currentTabType)Search_TextBox"
                        $criticalityComboBox = $syncHash."$($currentTabType)Criticality_ComboBox"
                        $configuredComboBox = $syncHash."$($currentTabType)Configured_ComboBox"

                        if ($searchBox) {
                            $searchBox.Tag = "Clearing" # Prevent TextChanged from triggering search
                            $searchBox.Text = $syncHash.UIConfigs.localePlaceholder.SearchPlaceholder_TextBox
                            $searchBox.Foreground = [System.Windows.Media.Brushes]::Gray
                            $searchBox.FontStyle = [System.Windows.FontStyles]::Italic
                            $searchBox.Tag = "Placeholder"

                            # Trigger the search update (filters persist)
                            Set-SearchAndFilter -TabType $currentTabType
                            Write-DebugOutput -Message "Manually cleared search for $currentTabType when switching product tabs (fallback)" -Source $MyInvocation.MyCommand -Level "Debug"
                        }
                    }
                }
            }.GetNewClosure())

            Write-DebugOutput -Message "Added auto-clear search Functionality for $tabType product tabs" -Source $MyInvocation.MyCommand -Level "Verbose"
        }

        # Initialize search textbox with improved placeholder handling
        $searchTextBox = $syncHash."$($tabType)Search_TextBox"
        if ($searchTextBox) {
            # Clear any existing event handlers to prevent conflicts
            $searchTextBox.Text = ""

            # Set up placeholder behavior
            $placeholderText = $syncHash.UIConfigs.localePlaceholder.SearchPlaceholder_TextBox
            $searchTextBox.Text = $placeholderText
            $searchTextBox.Foreground = [System.Windows.Media.Brushes]::Gray
            $searchTextBox.FontStyle = [System.Windows.FontStyles]::Italic
            $searchTextBox.Tag = "Placeholder"

            # Add GotFocus event
            $searchTextBox.Add_GotFocus({
                if ($this.Tag -eq "Placeholder") {
                    $this.Tag = "Clearing" # Set temporary tag to prevent TextChanged from triggering search
                    $this.Text = ""
                    $this.Foreground = [System.Windows.Media.Brushes]::Black
                    $this.FontStyle = [System.Windows.FontStyles]::Normal
                    $this.Tag = "Active"
                }
            }.GetNewClosure())

            # Add LostFocus event
            $searchTextBox.Add_LostFocus({
                if ([string]::IsNullOrWhiteSpace($this.Text)) {
                    $this.Tag = "Clearing" # Set temporary tag to prevent TextChanged from triggering search
                    $this.Text = $placeholderText
                    $this.Foreground = [System.Windows.Media.Brushes]::Gray
                    $this.FontStyle = [System.Windows.FontStyles]::Italic
                    $this.Tag = "Placeholder"
                }
            }.GetNewClosure())

            # Add TextChanged event for real-time search
            $searchTextBox.Add_TextChanged({
                # Don't trigger search if we're in the middle of clearing/setting placeholder
                if ($this.Tag -eq "Clearing") {
                    return
                }

                # Only trigger search if not in placeholder mode
                if ($this.Tag -ne "Placeholder") {
                    # Trigger search whether text is present or empty (to show all items when cleared)
                    Set-SearchAndFilter -TabType $tabType
                }
            }.GetNewClosure())

            Write-DebugOutput -Message "Search textbox initialized for $tabType" -Source $MyInvocation.MyCommand -Level "Verbose"
        }

        # Initialize clear search button
        $clearButton = $syncHash."$($tabType)ClearSearch_Button"
        # Initialize criticality filter combobox with dynamic values
        $criticalityComboBox = $syncHash."$($tabType)Criticality_ComboBox"


        $clearButton.Add_Click({
            $searchBox = $syncHash."$($tabType)Search_TextBox"
            $criticalityComboBox = $syncHash."$($tabType)Criticality_ComboBox"
            $configuredComboBox = $syncHash."$($tabType)Configured_ComboBox"

            if ($searchBox) {
                $searchBox.Tag = "Clearing" # Prevent TextChanged from triggering search
                $searchBox.Text = $syncHash.UIConfigs.localePlaceholder.SearchPlaceholder_TextBox
                $searchBox.Foreground = [System.Windows.Media.Brushes]::Gray
                $searchBox.FontStyle = [System.Windows.FontStyles]::Italic
                $searchBox.Tag = "Placeholder"

                # Trigger the search with cleared text (filters persist)
                Set-SearchAndFilter -TabType $tabType
            }
        }.GetNewClosure())



        # Clear existing items
        $criticalityComboBox.Items.Clear()

        # Add "All" option
        $allItem = New-Object System.Windows.Controls.ComboBoxItem
        $allItem.Content = "All Baselines"
        $allItem.Tag = "ALL_BASELINES"  # Use all values as tag
        [void]$criticalityComboBox.Items.Add($allItem)

        # Add specific criticality values dynamically
        foreach ($criticality in $criticalityValues) {
            $item = New-Object System.Windows.Controls.ComboBoxItem
            $item.Content = "$criticality only"
            $item.Tag = $criticality
            [void]$criticalityComboBox.Items.Add($item)
            Write-DebugOutput -Message "Added criticality option: $criticality" -Source $MyInvocation.MyCommand -Level "Verbose"
        }

        # Set default selection to "All"
        $criticalityComboBox.SelectedIndex = 0

        # Add filter event handler
        $criticalityComboBox.Add_SelectionChanged({
            # Get current configuration status from the other dropdown
            $configuredComboBox = $syncHash."$($tabType)Configured_ComboBox"
            $configurationStatus = if ($configuredComboBox -and $configuredComboBox.SelectedItem) {
                $configuredComboBox.SelectedItem.Tag
            } else {
                "ALL_CONFIGURATIONS"
            }
            Set-SearchAndFilter -TabType $tabType -Criticality $this.SelectedItem.Tag -ConfigurationStatus $configurationStatus
        }.GetNewClosure())

        Write-DebugOutput -Message "Criticality filter initialized for $tabType with $($criticalityValues.Count) values" -Source $MyInvocation.MyCommand -Level "Info"

        # Initialize configuration status filter combobox
        $configuredComboBox = $syncHash."$($tabType)Configured_ComboBox"
        if ($configuredComboBox) {
            # Clear existing items
            $configuredComboBox.Items.Clear()

            # Add "All" option
            $allConfigItem = New-Object System.Windows.Controls.ComboBoxItem
            $allConfigItem.Content = "All Configurations"
            $allConfigItem.Tag = "ALL_CONFIGURATIONS"
            [void]$configuredComboBox.Items.Add($allConfigItem)

            # Add "Configured" option (cards with "Saved" tag)
            $configuredItem = New-Object System.Windows.Controls.ComboBoxItem
            $configuredItem.Content = "Configured Only"
            $configuredItem.Tag = "CONFIGURED"
            [void]$configuredComboBox.Items.Add($configuredItem)

            # Add "Not Configured" option (cards with null/empty tag)
            $notConfiguredItem = New-Object System.Windows.Controls.ComboBoxItem
            $notConfiguredItem.Content = "Not Configured Only"
            $notConfiguredItem.Tag = "NOT_CONFIGURED"
            [void]$configuredComboBox.Items.Add($notConfiguredItem)

            # Set default selection to "All"
            $configuredComboBox.SelectedIndex = 0

            # Add filter event handler
            $configuredComboBox.Add_SelectionChanged({
                # Get current criticality from the other dropdown
                $criticalityComboBox = $syncHash."$($tabType)Criticality_ComboBox"
                $criticality = if ($criticalityComboBox -and $criticalityComboBox.SelectedItem) {
                    $criticalityComboBox.SelectedItem.Tag
                } else {
                    "ALL_BASELINES"
                }
                Set-SearchAndFilter -TabType $tabType -Criticality $criticality -ConfigurationStatus $this.SelectedItem.Tag
            }.GetNewClosure())

            Write-DebugOutput -Message "Configuration status filter initialized for $tabType" -Source $MyInvocation.MyCommand -Level "Info"
        }

    }#end foreach

    Write-DebugOutput -Message "Search and filter initialization completed" -Source $MyInvocation.MyCommand -Level "Info"

    # IMPORTANT: Don't apply initial filtering here - let it happen when products are loaded
}

Function Set-SearchAndFilter {
    <#
    .SYNOPSIS
    Applies search and filter criteria to policy cards.
    .DESCRIPTION
    This Function filters the display of policy cards based on search text, criticality selection, and configuration status.
    #>
    param(
        [string]$TabType,
        [string]$Criticality = "ALL_BASELINES",  # Default to showing all baselines
        [string]$ConfigurationStatus = "ALL_CONFIGURATIONS"  # Default to showing all configurations
    )

    # Get search criteria
    $searchTextBox = $syncHash."$($TabType)Search_TextBox"
    $criticalityComboBox = $syncHash."$($TabType)Criticality_ComboBox"
    $configuredComboBox = $syncHash."$($TabType)Configured_ComboBox"
    $resultCountTextBlock = $syncHash."$($TabType)ResultCount_TextBlock"

    # Get current filter values if not provided as parameters
    if ($Criticality -eq "ALL_BASELINES" -and $criticalityComboBox -and $criticalityComboBox.SelectedItem) {
        $Criticality = $criticalityComboBox.SelectedItem.Tag
    }
    if ($ConfigurationStatus -eq "ALL_CONFIGURATIONS" -and $configuredComboBox -and $configuredComboBox.SelectedItem) {
        $ConfigurationStatus = $configuredComboBox.SelectedItem.Tag
    }

    $searchText = ""
    # Only use search text if not in placeholder mode
    if ($searchTextBox -and $searchTextBox.Tag -ne "Placeholder" -and ![string]::IsNullOrWhiteSpace($searchTextBox.Text)) {
        $searchText = $searchTextBox.Text.Trim()
    }

    Write-DebugOutput -Message "Applying filter: Search='$searchText', Criticality='$Criticality', ConfigurationStatus='$ConfigurationStatus'" -Source $MyInvocation.MyCommand -Level "Verbose"

    # Apply filter to each product tab
    $productTabControl = $syncHash."$($TabType)ProductTabControl"
    if (-not $productTabControl) {
        Write-DebugOutput -Message "Product tab control not found for $TabType" -Source $MyInvocation.MyCommand -Level "Error"
        return
    }

    # Check if there are any enabled product tabs
    $enabledTabs = $productTabControl.Items | Where-Object { $_.IsEnabled }
    if (-not $enabledTabs -or $enabledTabs.Count -eq 0) {
        Write-DebugOutput -Message "No enabled product tabs found for $TabType - skipping filter" -Source $MyInvocation.MyCommand -Level "Verbose"
        # Update result count to show 0
        if ($resultCountTextBlock) {
            $resultCountTextBlock.Text = "0 policies"
        }
        return
    }

    $totalVisible = 0

    foreach ($productTab in $productTabControl.Items) {
        if (-not $productTab.IsEnabled) { continue }

        # Find the content container for this product
        $contentContainer = $null
        if ($productTab.Content -is [System.Windows.Controls.ScrollViewer]) {
            $contentContainer = $productTab.Content.Content
        } elseif ($productTab.Content -is [System.Windows.Controls.StackPanel]) {
            $contentContainer = $productTab.Content
        } else {
            # Look for ScrollViewer in the content
            foreach ($child in $productTab.Content.Children) {
                if ($child -is [System.Windows.Controls.ScrollViewer]) {
                    $contentContainer = $child.Content
                    break
                }
            }
        }

        if (-not $contentContainer) {
            Write-DebugOutput -Message "Content container not found for product tab: $($productTab.Header)" -Source $MyInvocation.MyCommand -Level "Error"
            continue
        }

        $visibleInThisProduct = 0

        # Filter cards in this product container
        # First, get only the Border controls (actual policy cards)
        $policyCards = $contentContainer.Children | Where-Object { $_ -is [System.Windows.Controls.Border] }
        $otherControls = $contentContainer.Children | Where-Object { $_ -isnot [System.Windows.Controls.Border] }

        # Handle policy cards with filtering
        foreach ($card in $policyCards) {
            # Safety check during card iteration
            if ($syncHash.isClosing -or $syncHash.isClosed) {
                break
            }

            try {
                $shouldShow = Test-SearchAndFilter -Card $card -SearchText $searchText -Criticality $Criticality -ConfigurationStatus $ConfigurationStatus

                if ($shouldShow) {
                    $card.Visibility = [System.Windows.Visibility]::Visible
                    $visibleInThisProduct++
                } else {
                    $card.Visibility = [System.Windows.Visibility]::Collapsed
                }
            } catch {
                # If error filtering individual card, make it visible by default
                Write-DebugOutput -Message "Error filtering card: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                $card.Visibility = [System.Windows.Visibility]::Visible
                $visibleInThisProduct++
            }
        }

        # Handle other controls (like TextBlocks for messages)
        foreach ($control in $otherControls) {
            if ($syncHash.isClosing -or $syncHash.isClosed) {
                break
            }

            # For message controls, show them only when no policy cards are visible
            if ($control -is [System.Windows.Controls.TextBlock] -and
                ($control.Text -like "*No policies*" -or $control.Text -like "*No data*")) {
                # Show "No policies" message only when no cards are visible
                if ($visibleInThisProduct -eq 0) {
                    $control.Visibility = [System.Windows.Visibility]::Visible
                } else {
                    $control.Visibility = [System.Windows.Visibility]::Collapsed
                }
            } else {
                # Keep other controls visible by default
                $control.Visibility = [System.Windows.Visibility]::Visible
            }
        }

        $totalVisible += $visibleInThisProduct
        Write-DebugOutput -Message "Product $($productTab.Header): $visibleInThisProduct visible cards" -Source $MyInvocation.MyCommand -Level "Verbose"
    }

    # Update result count
    if ($resultCountTextBlock) {
        $resultCountTextBlock.Text = "$totalVisible policies"
    }

    Write-DebugOutput -Message "Filter applied: $totalVisible policies visible total" -Source $MyInvocation.MyCommand -Level "Info"
}

Function Test-SearchAndFilter {
    <#
    .SYNOPSIS
    Tests if a policy card matches the current search and filter criteria.
    .DESCRIPTION
    This Function evaluates whether a policy card should be visible based on search text, criticality filter, and configuration status.
    Assumes the card Tag property contains baseline data with id, name, criticality, and rationale properties.
    Card objects themselves may have configuration status information (e.g., "Saved" tag for configured cards).
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.FrameworkElement]$Card,  # Changed from Border to FrameworkElement to be more flexible
        [string]$SearchText,
        [string]$Criticality,
        [string]$ConfigurationStatus = "ALL_CONFIGURATIONS"
    )

    # Safety check - return true if window is closing or card is invalid
    if ($syncHash.isClosing -or $syncHash.isClosed -or !$Card) {
        return $true
    }

    # Only process Border controls - other controls should be handled by the caller
    if ($Card -isnot [System.Windows.Controls.Border]) {
        Write-DebugOutput -Message "Test-SearchAndFilter called with non-Border control: $($Card.GetType().Name)" -Source $MyInvocation.MyCommand -Level "Error"
        return $true
    }

    try {
        # Get card data from Tag property - we now always set this with baseline data
        $cardData = $Card.Tag

        # If no tag data, always show the card
        if (-not $cardData) {
            return $true
        }

        # Apply search filter
        if (![string]::IsNullOrWhiteSpace($SearchText)) {
            $searchMatch = $false

            # Search in policy ID
            if ($cardData.id -and $cardData.id -like "*$SearchText*") {
                $searchMatch = $true
            }

            # Search in policy name
            if ($cardData.name -and $cardData.name -like "*$SearchText*") {
                $searchMatch = $true
            }

            # Search in description/rationale
            if ($cardData.rationale -and $cardData.rationale -like "*$SearchText*") {
                $searchMatch = $true
            }

            if (-not $searchMatch) {
                return $false
            }
        }

        # Apply criticality filter - fixed logic
        if (![string]::IsNullOrWhiteSpace($Criticality) -and $Criticality -ne "ALL_BASELINES") {
            # Show only cards that match the selected criticality
            if ($cardData.criticality -ne $Criticality) {
                return $false
            }
        }

        # Apply configuration status filter
        if (![string]::IsNullOrWhiteSpace($ConfigurationStatus) -and $ConfigurationStatus -ne "ALL_CONFIGURATIONS") {
            # Check if the card object has configuration status information
            $isConfigured = $false

            # Method 1: Check if the card itself has any "Saved" indicators
            # This could be in the card's Tag, Name, or other properties
            if ($Card.Tag -and ($Card.Tag -eq "Saved")) {
                $isConfigured = $true
            }

            # Method 2: Look for CheckBox controls within the card that have "Saved" tag
            # This is the primary way the app marks configured policies
            if (-not $isConfigured) {
                try {
                    # Function to recursively search for CheckBox with "Saved" tag
                    function Find-SavedCheckBox($element) {
                        if (-not $element) {
                            return $false
                        }

                        # Check if this element is a CheckBox with "Saved" tag
                        if ($element -is [System.Windows.Controls.CheckBox]) {
                            if ($element.Tag -eq "Saved") {
                                return $true
                            }
                            # Debug: Log all checkboxes found
                            Write-DebugOutput -Message "Found CheckBox with Tag: '$($element.Tag)'" -Source "Find-SavedCheckBox" -Level "Debug"
                        }

                        # Search in child elements using direct property access
                        # Skip LogicalTreeHelper.GetChildren() as it doesn't work properly in PowerShell

                        # Try visual tree for more complex layouts
                        try {
                            if ($element -is [System.Windows.DependencyObject]) {
                                $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($element)
                                for ($i = 0; $i -lt $childCount; $i++) {
                                    $child = [System.Windows.Media.VisualTreeHelper]::GetChild($element, $i)
                                    if (Find-SavedCheckBox $child) {
                                        return $true
                                    }
                                }
                            }
                        } catch {
                            # Visual tree navigation failed
                            return $false
                        }

                        # For Panel controls, try the Children collection
                        try {
                            if ($element -is [System.Windows.Controls.Panel] -and $element.Children) {
                                foreach ($child in $element.Children) {
                                    if (Find-SavedCheckBox $child) {
                                        return $true
                                    }
                                }
                            }
                        } catch {
                            # Panel children access failed
                            return $false
                        }

                        # For ContentControl (like Border), check Content property
                        try {
                            if ($element -is [System.Windows.Controls.ContentControl] -and $element.Content -and $element.Content -ne $element) {
                                if (Find-SavedCheckBox $element.Content) {
                                    return $true
                                }
                            }
                        } catch {
                            # Content access failed
                            return $false
                        }

                        return $false
                    }

                    $isConfigured = Find-SavedCheckBox $Card

                } catch {
                    # If there's an error searching for saved checkboxes, assume not configured
                    Write-DebugOutput -Message "Error checking configuration status: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Debug"
                    $isConfigured = $false
                }
            }

            <# Method 3: Check if the card has visible configuration data
            # Look for any TextBox, ComboBox, or other input controls with non-default values
            if (-not $isConfigured) {
                try {
                    function Find-ConfiguredInputs($element) {
                        if (-not $element) {
                            return $false
                        }

                        # Check for TextBox with non-empty, non-placeholder text
                        if ($element -is [System.Windows.Controls.TextBox]) {
                            if (-not [string]::IsNullOrWhiteSpace($element.Text) -and
                                $element.Text -notlike "*placeholder*" -and
                                $element.Text -notlike "*Enter*" -and
                                $element.Text -notlike "*Type*") {
                                return $true
                            }
                        }

                        # Check for ComboBox with selected items
                        if ($element -is [System.Windows.Controls.ComboBox]) {
                            if ($element.SelectedIndex -gt 0 -or $element.SelectedItem) {
                                return $true
                            }
                        }

                        # Check for CheckBox that's checked (but not the main policy checkbox)
                        if ($element -is [System.Windows.Controls.CheckBox] -and $element.IsChecked -eq $true) {
                            # Skip the main policy checkbox (usually has different styling)
                            if (-not ($element.Name -like "*Policy*" -or $element.Style -and $element.Style.TargetType -eq [System.Windows.Controls.CheckBox])) {
                                return $true
                            }
                        }

                        # Recursively check children (simplified version)
                        try {
                            if ($element -is [System.Windows.Controls.Panel] -and $element.Children) {
                                foreach ($child in $element.Children) {
                                    if (Find-ConfiguredInputs $child) {
                                        return $true
                                    }
                                }
                            }

                            if ($element -is [System.Windows.Controls.ContentControl] -and $element.Content -and $element.Content -ne $element) {
                                if (Find-ConfiguredInputs $element.Content) {
                                    return $true
                                }
                            }
                        } catch {
                            # Ignore errors in recursion
                            return $false
                        }

                        return $false
                    }

                    $isConfigured = Find-ConfiguredInputs $Card

                } catch {
                    # If there's an error checking for configured inputs, assume not configured
                    Write-DebugOutput -Message "Error checking for configured inputs: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Debug"
                    $isConfigured = $false
                }
            }
            #>

            # Debug logging to understand what's happening
            if ($cardData.id) {
                Write-DebugOutput -Message "Card $($cardData.id): isConfigured = $isConfigured, requested filter = $ConfigurationStatus" -Source $MyInvocation.MyCommand -Level "Debug"
            }

            # Apply the filter
            switch ($ConfigurationStatus) {
                "CONFIGURED" {
                    if (-not $isConfigured) {
                        return $false
                    }
                }
                "NOT_CONFIGURED" {
                    if ($isConfigured) {
                        return $false
                    }
                }
            }
        }

        return $true

    } catch {
        # If any error occurs during filtering (e.g., during window close), just show the card
        Write-DebugOutput -Message "Error in Test-SearchAndFilter: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        return $true
    }
}