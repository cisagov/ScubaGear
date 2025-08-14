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
    $criticalityValues = Get-UniqueCriticalityValues

    Write-DebugOutput -Message "Found criticality values: $($criticalityValues -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"

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

                        if ($searchBox) {
                            $searchBox.Text = "Search policies by name or ID..."
                            $searchBox.Foreground = [System.Windows.Media.Brushes]::Gray
                            $searchBox.FontStyle = [System.Windows.FontStyles]::Italic
                            $searchBox.Tag = "Placeholder"

                            # Reset criticality filter to "All"
                            if ($criticalityComboBox) {
                                $criticalityComboBox.SelectedIndex = 0
                            }

                            # Trigger the search update
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
            $placeholderText = "Search policies by name or ID..."
            $searchTextBox.Text = $placeholderText
            $searchTextBox.Foreground = [System.Windows.Media.Brushes]::Gray
            $searchTextBox.FontStyle = [System.Windows.FontStyles]::Italic
            $searchTextBox.Tag = "Placeholder"

            # Add GotFocus event
            $searchTextBox.Add_GotFocus({
                if ($this.Tag -eq "Placeholder") {
                    $this.Text = ""
                    $this.Foreground = [System.Windows.Media.Brushes]::Black
                    $this.FontStyle = [System.Windows.FontStyles]::Normal
                    $this.Tag = "Active"
                }
            }.GetNewClosure())

            # Add LostFocus event
            $searchTextBox.Add_LostFocus({
                if ([string]::IsNullOrWhiteSpace($this.Text)) {
                    $this.Text = $placeholderText
                    $this.Foreground = [System.Windows.Media.Brushes]::Gray
                    $this.FontStyle = [System.Windows.FontStyles]::Italic
                    $this.Tag = "Placeholder"
                }
            }.GetNewClosure())

            # Add TextChanged event for real-time search
            $searchTextBox.Add_TextChanged({
                # Only trigger search if not in placeholder mode
                if ($this.Tag -ne "Placeholder" -and ![string]::IsNullOrWhiteSpace($this.Text)) {
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
            if ($searchBox) {
                $searchBox.Text = "Search policies by name or ID..."
                $searchBox.Foreground = [System.Windows.Media.Brushes]::Gray
                $searchBox.FontStyle = [System.Windows.FontStyles]::Italic
                $searchBox.Tag = "Placeholder"

                # Reset default selection to "All"
                $criticalityComboBox.SelectedIndex = 0

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
            Set-SearchAndFilter -TabType $tabType -Criticality $this.SelectedItem.Tag
        }.GetNewClosure())

        Write-DebugOutput -Message "Criticality filter initialized for $tabType with $($criticalityValues.Count) values" -Source $MyInvocation.MyCommand -Level "Info"

    }#end foreach

    Write-DebugOutput -Message "Search and filter initialization completed" -Source $MyInvocation.MyCommand -Level "Info"

    # IMPORTANT: Don't apply initial filtering here - let it happen when products are loaded
}

Function Set-SearchAndFilter {
    <#
    .SYNOPSIS
    Applies search and filter criteria to policy cards.
    .DESCRIPTION
    This Function filters the display of policy cards based on search text and criticality selection.
    #>
    param(
        [string]$TabType,
        [string]$Criticality = "ALL_BASELINES"  # Default to showing all baselines
    )

    # Get search criteria
    $searchTextBox = $syncHash."$($TabType)Search_TextBox"
    #$criticalityComboBox = $syncHash."$($TabType)Criticality_ComboBox"
    $resultCountTextBlock = $syncHash."$($TabType)ResultCount_TextBlock"

    $searchText = ""
    # Only use search text if not in placeholder mode
    if ($searchTextBox -and $searchTextBox.Tag -ne "Placeholder" -and ![string]::IsNullOrWhiteSpace($searchTextBox.Text)) {
        $searchText = $searchTextBox.Text.Trim()
    }

    Write-DebugOutput -Message "Applying filter: Search='$searchText', Criticality='$Criticality'" -Source $MyInvocation.MyCommand -Level "Verbose"

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
                $shouldShow = Test-SearchAndFilter -Card $card -SearchText $searchText -Criticality $Criticality

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
    This Function evaluates whether a policy card should be visible based on search text and criticality filter.
    Assumes the card Tag property contains baseline data with id, name, criticality, and rationale properties.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.FrameworkElement]$Card,  # Changed from Border to FrameworkElement to be more flexible
        [string]$SearchText,
        [string]$Criticality
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

        return $true

    } catch {
        # If any error occurs during filtering (e.g., during window close), just show the card
        Write-DebugOutput -Message "Error in Test-SearchAndFilter: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        return $true
    }
}