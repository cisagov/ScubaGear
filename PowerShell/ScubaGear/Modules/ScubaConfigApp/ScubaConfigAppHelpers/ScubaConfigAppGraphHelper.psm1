Function Update-GraphStatusIndicator {
    <#
    .SYNOPSIS
    Updates the Graph connection status indicator in the UI.
    .DESCRIPTION
    Updates the visual indicator to show whether Microsoft Graph is connected or disconnected.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "IsConnected")]
    param(
        [bool]$IsConnected = $syncHash.GraphConnected
    )

    try {
        $syncHash.Window.Dispatcher.Invoke([Action]{
            if ($IsConnected) {
                # Connected state - Green indicator
                $syncHash.GraphStatusIndicator.Fill = [System.Windows.Media.Brushes]::Green
                $syncHash.GraphStatusText.Text = "Graph Connected"
                $syncHash.GraphStatusText.Foreground = [System.Windows.Media.Brushes]::DarkGreen
                $syncHash.GraphStatusBorder.Background = [System.Windows.Media.Brushes]::LightGreen
                $syncHash.GraphStatusBorder.ToolTip = "Microsoft Graph is connected and ready for data queries"

                Write-DebugOutput -Message "Graph status indicator updated: Connected" -Source $MyInvocation.MyCommand -Level "Info"
            } else {
                # Disconnected state - Red indicator
                $syncHash.GraphStatusIndicator.Fill = [System.Windows.Media.Brushes]::Red
                $syncHash.GraphStatusText.Text = "Graph Disconnected"
                $syncHash.GraphStatusText.Foreground = [System.Windows.Media.Brushes]::DarkRed
                $syncHash.GraphStatusBorder.Background = [System.Windows.Media.Brushes]::LightPink
                $syncHash.GraphStatusBorder.ToolTip = "Microsoft Graph is not connected - some features may be limited"

                Write-DebugOutput -Message "Graph status indicator updated: Disconnected" -Source $MyInvocation.MyCommand -Level "Info"
            }
        })
    } catch {
        Write-DebugOutput -Message "Error updating Graph status indicator: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

Function Initialize-GraphStatusIndicator {
    <#
    .SYNOPSIS
    Initializes the Graph status indicator with click functionality.
    .DESCRIPTION
    Sets up the Graph status indicator and adds click event for connection management.
    #>

    # Add click event to the status border for connection management
    $syncHash.GraphStatusBorder.Add_MouseLeftButtonUp({
        if ($syncHash.GraphConnected) {
            # Show disconnect option
            $result = $syncHash.ShowMessageBox.Invoke(
                "Do you want to disconnect from Microsoft Graph?`n`nThis will disable dynamic data queries but won't affect your current configuration.",
                "Disconnect Graph",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )

            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                try {
                    Disconnect-MgGraph -ErrorAction Stop
                    $syncHash.GraphConnected = $false
                    Update-GraphStatusIndicator -IsConnected $false

                    # Remove dynamic Graph buttons
                    # You might want to add a function to clean up dynamic buttons

                    $syncHash.ShowMessageBox.Invoke(
                        "Successfully disconnected from Microsoft Graph.",
                        "Graph Disconnected",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Information
                    )
                } catch {
                    Write-DebugOutput -Message "Error disconnecting from Graph: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                    $syncHash.ShowMessageBox.Invoke(
                        "Error disconnecting from Graph: $($_.Exception.Message)",
                        "Disconnect Error",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Error
                    )
                }
            }
        } else {
            # Show connect information
            $syncHash.ShowMessageBox.Invoke(
                $syncHash.UIConfigs.LocalePopupMessages.GraphNotConnected,
                "Graph Connection",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
        }
    })

    # Set initial status
    Update-GraphStatusIndicator -IsConnected $syncHash.GraphConnected

    Write-DebugOutput -Message "Graph status indicator initialized" -Source $MyInvocation.MyCommand -Level "Info"
}

# Enhanced Graph Query Function with Filter Support
Function Invoke-GraphQueryWithFilter {
    <#
    .SYNOPSIS
    Executes Microsoft Graph API queries with filtering support in a background thread.
    .DESCRIPTION
    This Function performs asynchronous Microsoft Graph API queries with optional filtering, returning data for users, groups, or other Graph entities.
    #>
    param(
        [string]$QueryType,
        $GraphConfig,
        [string]$FilterString,
        [int]$Top = 999
    )

    Write-DebugOutput "Starting Graph query - Type: $QueryType, Filter: $FilterString, Top: $Top" -Source "Invoke-GraphQueryWithFilter" -Level "Debug"

    # Create runspace
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()

    Write-DebugOutput "Created new runspace for Graph query" -Source "Invoke-GraphQueryWithFilter" -Level "Verbose"

    # Create PowerShell instance
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace

    # Add script block
    $scriptBlock = {
        param($QueryType, $GraphConfig, $FilterString, $Top)

        try {
            # Get query configuration
            $queryConfig = $GraphConfig.$QueryType
            if (-not $queryConfig) {
                #Write-DebugOutput -Message "Query configuration not found for: $QueryType" -Source $MyInvocation.MyCommand -Level "Error"
            }

            # Build query parameters
            $queryParams = @{
                Uri = $queryConfig.endpoint
                Method = "Get"
            }

            # Build query string
            $queryStringParts = @()

            # Add existing query parameters from config
            if ($queryConfig.queryParameters) {
                foreach ($param in $queryConfig.queryParameters.psobject.properties.name) {
                    $queryStringParts += "$param=$($queryConfig.queryParameters.$param)"
                }
            }

            # Add filter if provided
            if (![string]::IsNullOrWhiteSpace($FilterString)) {
                $queryStringParts += "`$filter=$FilterString"
            }

            # Add top parameter
            $queryStringParts += "`$top=$Top"

            # Combine query string
            if ($queryStringParts.Count -gt 0) {
                $queryParams.Uri += $syncHash.GraphEndpoint + "?" + ($queryStringParts -join "&")
            }

            #Write-DebugOutput -Message "Graph Query URI: $($queryParams.Uri)" -Source $MyInvocation.MyCommand -Level "Information"

            # Execute the Graph request
            $result = Invoke-MgGraphRequest @queryParams -OutputType PSObject

            # Return the result
            return @{
                Success = $true
                Data = $result
                QueryConfig = $queryConfig
                Message = "Successfully retrieved $($result.value.Count) items"
                FilterApplied = ![string]::IsNullOrWhiteSpace($FilterString)
            }
        }
        catch {
            #Write-DebugOutput -Message "Error executing Graph query: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            return @{
                Success = $false
                Error = $_.Exception.Message
                Message = "Failed to retrieve data from uri [{0}]: {1}" -f $queryParams.Uri, $($_.Exception.Message)
                FilterApplied = ![string]::IsNullOrWhiteSpace($FilterString)
            }
        }
    }

    # Add parameters and start execution
    $powershell.AddScript($scriptBlock).AddParameter("QueryType", $QueryType).AddParameter("GraphConfig", $GraphConfig).AddParameter("FilterString", $FilterString).AddParameter("Top", $Top)
    $asyncResult = $powershell.BeginInvoke()

    return @{
        PowerShell = $powershell
        AsyncResult = $asyncResult
        Runspace = $runspace
    }
}

Function Get-GraphEntityConfig {
    <#
    .SYNOPSIS
    Dynamically builds entity configurations from the JSON graphQueries configuration.
    .DESCRIPTION
    This function reads the graphQueries section from the UI configuration and creates
    the entity configurations needed for the Graph selector dialogs.
    #>
    param(
        [string]$entityType
    )

    # Check if the specific entity type exists in the configuration
    $queryProperty = $syncHash.UIConfigs.graphQueries.PSObject.Properties | Where-Object { $_.Name -eq $entityType }

    if (-not $queryProperty) {
        Write-DebugOutput -Message "Entity type '$entityType' not found in graphQueries configuration" -Source $MyInvocation.MyCommand -Level "Error"
        return $null
    }

    $queryConfig = $queryProperty.Value

    # Build the configuration for the specific entity type
    $config = @{
        Title = "Select $($queryConfig.name)"
        SearchPlaceholder = "Search by $($queryConfig.searchProperty.ToLower())..."
        LoadingMessage = "Loading $($queryConfig.name.ToLower())..."
        NoResultsMessage = "No $($queryConfig.name.ToLower()) found matching the search criteria."
        NoResultsTitle = "No $($queryConfig.name) Found"
        FilterProperty = $queryConfig.queryfilterProperty
        SearchProperty = $queryConfig.searchProperty
        QueryType = $entityType
        AllowMultiple = $queryConfig.allowMultipleSelection
    }

    # Build column configuration from displayColumnOrder
    $columnConfig = [ordered]@{}
    foreach ($column in $queryConfig.displayColumnOrder) {
        $columnConfig[$column.value] = @{
            Header = $column.name
            Width = 200  # Default width, you could make this configurable too
        }
    }
    $config.ColumnConfig = $columnConfig

    # Create data transform script block with columns captured in closure
    $columns = $queryConfig.displayColumnOrder
    $config.DataTransform = {
        param($item)
        $result = [PSCustomObject]@{ OriginalObject = $item }

        foreach ($column in $columns) {
            $propName = $column.value
            # Handle special cases for group types
            if ($propName -eq "groupTypes" -and $item.GroupTypes) {
                $groupType = "Distribution"
                if ($item.SecurityEnabled) { $groupType = "Security" }
                if ($item.GroupTypes -contains "Unified") { $groupType = "Microsoft 365" }
                $result | Add-Member -MemberType NoteProperty -Name "GroupType" -Value $groupType
            } else {
                $result | Add-Member -MemberType NoteProperty -Name $propName -Value $item.$propName
            }
        }
        return $result
    }.GetNewClosure()

    return $config
}

Function Show-GraphProgressWindow {
    <#
    .SYNOPSIS
    Displays a progress window while executing Graph queries and shows results in a selection interface.
    .DESCRIPTION
    This Function shows a progress dialog during Graph API operations and presents the results in a searchable, selectable data grid for users and groups.
    #>
    param(
        [string]$GraphEntityType,
        [string]$SearchTerm = "",
        [int]$Top = 100
    )

    try {
        # Get configuration for the specified entity type
        $config = Get-GraphEntityConfig -entityType $GraphEntityType
        if ($config) {
            Write-DebugOutput -Message "Using configuration for graph entity type: $GraphEntityType" -Source $MyInvocation.MyCommand -Level "Verbose"
        }else{
            Write-DebugOutput -Message "Unsupported graph entity type: $GraphEntityType" -Source $MyInvocation.MyCommand -Level "Error"
        }

        # Build filter string
        $filterString = $null
        if (![string]::IsNullOrWhiteSpace($SearchTerm)) {
            $filterString = "startswith($($config.FilterProperty),'$SearchTerm')"
        }

        # Show progress window
        $progressWindow = New-Object System.Windows.Window
        $progressWindow.Title = $config.Title
        $progressWindow.Width = 300
        $progressWindow.Height = 120
        $progressWindow.WindowStartupLocation = "CenterOwner"
        $progressWindow.Owner = $syncHash.Window
        $progressWindow.Background = [System.Windows.Media.Brushes]::White

        $progressPanel = New-Object System.Windows.Controls.StackPanel
        $progressPanel.Margin = "20"
        $progressPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $progressPanel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

        $progressLabel = New-Object System.Windows.Controls.Label
        $progressLabel.Content = $config.LoadingMessage
        $progressLabel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

        $progressBar = New-Object System.Windows.Controls.ProgressBar
        $progressBar.Width = 200
        $progressBar.Height = 20
        $progressBar.IsIndeterminate = $true

        [void]$progressPanel.Children.Add($progressLabel)
        [void]$progressPanel.Children.Add($progressBar)
        $progressWindow.Content = $progressPanel

        # Start async operation
        Write-DebugOutput -Message "Starting async operation for graph query type: $($config.QueryType) with filter: $filterString" -Source $MyInvocation.MyCommand -Level "Verbose"
        $asyncOp = Invoke-GraphQueryWithFilter `
                        -QueryType $config.QueryType `
                        -GraphConfig $syncHash.UIConfigs.graphQueries `
                        -FilterString $filterString -Top $Top

        # Show progress window
        $progressWindow.Show()

        # Wait for completion
        while (-not $asyncOp.AsyncResult.IsCompleted) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }

        # Close progress window
        $progressWindow.Close()

        # Get results
        $result = $asyncOp.PowerShell.EndInvoke($asyncOp.AsyncResult)
        $asyncOp.PowerShell.Dispose()
        $asyncOp.Runspace.Close()
        $asyncOp.Runspace.Dispose()

        if ($result.Success) {
            Write-DebugOutput -Message "Graph query successful for entity type: $GraphEntityType, items found: $($result.Data.value.Count)" -Source $MyInvocation.MyCommand -Level "Verbose"
            $items = $result.Data.value
            if (-not $items -or $items.Count -eq 0) {
                $syncHash.ShowMessageBox.Invoke($config.NoResultsMessage, $config.NoResultsTitle,
                                                [System.Windows.MessageBoxButton]::OK,
                                                [System.Windows.MessageBoxImage]::Information)
                return $null
            }

            # Transform data using entity-specific transformer
            $displayItems = $items | ForEach-Object {
                & $config.DataTransform $_
            } | Sort-Object DisplayName

            # Show selector using the universal selection window
            $selectedItems = Show-UISelectionWindow `
                                -Title $config.Title `
                                -SearchPlaceholder $config.SearchPlaceholder `
                                -Items $displayItems `
                                -ColumnConfig $config.ColumnConfig `
                                -SearchProperty $config.SearchProperty `
                                -DisplayOrder $config.ColumnConfig.Keys `
                                -AllowMultiple:$config.AllowMultiple

            return $selectedItems
        }
        else {
            Write-DebugOutput -Message "Graph query failed for entity type: $GraphEntityType, error: $($result.Error)" -Source $MyInvocation.MyCommand -Level "Error"
            $syncHash.ShowMessageBox.Invoke($result.Message, $syncHash.UIConfigs.localeTitles.Error,
                                            [System.Windows.MessageBoxButton]::OK,
                                            [System.Windows.MessageBoxImage]::Error)
            return $null
        }
    }
    catch {
        $syncHash.ShowMessageBox.Invoke(("{0} {1}: {2}" -f $syncHash.UIConfigs.localeErrorMessages.WindowError,$GraphEntityType, $_.Exception.Message),
                                        $syncHash.UIConfigs.localeTitles.Error,
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Error)
        return $null
    }
}

Function Show-GraphSelector {
    <#
    .SYNOPSIS
    Shows a Graph entity selector with optional search Functionality.
    .DESCRIPTION
    This Function displays a selector interface for Microsoft Graph entities (users, groups) with optional search term filtering and result limiting.
    #>
    param(
        [string]$GraphEntityType,
        [string]$SearchTerm = "",
        [int]$Top = 100
    )
    If([string]::IsNullOrWhiteSpace($SearchTerm)) {
        Write-DebugOutput -Message "Showing $($GraphEntityType.ToLower()) selector with top: $Top" -Source $MyInvocation.MyCommand -Level "Info"
    }Else {
        Write-DebugOutput -Message "Showing $($GraphEntityType.ToLower()) selector with search term: $SearchTerm, top: $Top" -Source $MyInvocation.MyCommand -Level "Info"
    }
    return Show-GraphProgressWindow -GraphEntityType $GraphEntityType -SearchTerm $SearchTerm -Top $Top
}

#build UI selection window
Function Show-UISelectionWindow {
    <#
    .SYNOPSIS
    Creates a universal selection window with search and filtering capabilities.
    .DESCRIPTION
    This Function generates a reusable selection dialog with a searchable data grid, supporting single or multiple selection modes for various data types.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "SearchProperty")]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$SearchPlaceholder,

        [Parameter(Mandatory)]
        [array]$Items,

        [Parameter(Mandatory)]
        [hashtable]$ColumnConfig,

        [Parameter()]
        [string[]]$DisplayOrder,

        [Parameter()]
        [string]$SearchProperty = "DisplayName",

        [Parameter()]
        [int]$WindowWidth = 1000,

        [Parameter()]
        [string]$ReturnProperty,

        [Parameter()]
        [switch]$AllowMultiple
    )

    #[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | out-null
    #[System.Reflection.Assembly]::LoadWithPartialName('System.Security') | out-null

    try {
        # Create selection window
        $selectionWindow = New-Object System.Windows.Window
        $selectionWindow.Title = $Title
        $selectionWindow.Width = $WindowWidth
        $selectionWindow.Height = 500
        $selectionWindow.WindowStartupLocation = "CenterOwner"
        $selectionWindow.Owner = $syncHash.Window
        $selectionWindow.Background = [System.Windows.Media.Brushes]::White

        # Create main grid
        $mainGrid = New-Object System.Windows.Controls.Grid
        $rowDef1 = New-Object System.Windows.Controls.RowDefinition
        $rowDef1.Height = [System.Windows.GridLength]::Auto
        $rowDef2 = New-Object System.Windows.Controls.RowDefinition
        $rowDef2.Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $rowDef3 = New-Object System.Windows.Controls.RowDefinition
        $rowDef3.Height = [System.Windows.GridLength]::Auto
        [void]$mainGrid.RowDefinitions.Add($rowDef1)
        [void]$mainGrid.RowDefinitions.Add($rowDef2)
        [void]$mainGrid.RowDefinitions.Add($rowDef3)

        # Search panel
        $searchPanel = New-Object System.Windows.Controls.StackPanel
        $searchPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $searchPanel.Margin = "10"

        $searchLabel = New-Object System.Windows.Controls.Label
        $searchLabel.Content = "Search:"
        $searchLabel.Width = 60
        $searchLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

        $searchBox = New-Object System.Windows.Controls.TextBox
        $searchBox.Width = 300
        $searchBox.Height = 25
        $searchBox.Text = $SearchPlaceholder
        $searchBox.Foreground = [System.Windows.Media.Brushes]::Gray
        $searchBox.FontStyle = [System.Windows.FontStyles]::Italic
        $searchBox.Margin = "5,0"

        # Search box placeholder Functionality
        $searchBox.Add_GotFocus({
            if ($searchBox.Text -eq $SearchPlaceholder) {
                $searchBox.Text = ""
                $searchBox.Foreground = [System.Windows.Media.Brushes]::Black
                $searchBox.FontStyle = [System.Windows.FontStyles]::Normal
            }
        })

        $searchBox.Add_LostFocus({
            if ([string]::IsNullOrWhiteSpace($searchBox.Text)) {
                $searchBox.Text = $SearchPlaceholder
                $searchBox.Foreground = [System.Windows.Media.Brushes]::Gray
                $searchBox.FontStyle = [System.Windows.FontStyles]::Italic
            }
        })

        [void]$searchPanel.Children.Add($searchLabel)
        [void]$searchPanel.Children.Add($searchBox)

        [System.Windows.Controls.Grid]::SetRow($searchPanel, 0)
        [void]$mainGrid.Children.Add($searchPanel)

        # Create DataGrid
        $dataGrid = New-Object System.Windows.Controls.DataGrid
        $dataGrid.AutoGenerateColumns = $false
        $dataGrid.CanUserAddRows = $false
        $dataGrid.CanUserDeleteRows = $false
        $dataGrid.IsReadOnly = $true
        $dataGrid.SelectionMode = if ($AllowMultiple) { [System.Windows.Controls.DataGridSelectionMode]::Extended } else { [System.Windows.Controls.DataGridSelectionMode]::Single }
        $dataGrid.GridLinesVisibility = [System.Windows.Controls.DataGridGridLinesVisibility]::Horizontal
        $dataGrid.HeadersVisibility = [System.Windows.Controls.DataGridHeadersVisibility]::Column
        $dataGrid.Margin = "10"

        # Display order handling if specified
        if ($DisplayOrder -and $DisplayOrder.Count -gt 0) {
            $keyOrder = $DisplayOrder
        } else {
            # Use keys from ColumnConfig if no display order specified
            $keyOrder = $ColumnConfig.Keys | Sort-Object
        }

        # Create columns based on ColumnConfig
        foreach ($columnKey in $keyOrder) {
            if ($ColumnConfig.Contains($columnKey)) {
                $column = New-Object System.Windows.Controls.DataGridTextColumn
                $column.Header = $ColumnConfig[$columnKey].Header
                $column.Binding = New-Object System.Windows.Data.Binding($columnKey)
                $column.Width = $ColumnConfig[$columnKey].Width
                $dataGrid.Columns.Add($column)
            } else {
                Write-DebugOutput -Message "Column configuration for '$columnKey' not found in ColumnConfig." -Source $MyInvocation.MyCommand -Level "Error"
            }
        }

        # Store original items for filtering
        $originalItems = $Items

        # Filter Function
        $FilterItems = {
            $searchText = $searchBox.Text.ToLower()
            if ([string]::IsNullOrWhiteSpace($searchText) -or $searchText -eq $SearchPlaceholder.ToLower()) {
                $dataGrid.ItemsSource = $originalItems
            } else {
                $filteredItems = @($originalItems | Where-Object {
                    $_.$SearchProperty.ToLower().Contains($searchText)
                })
                $dataGrid.ItemsSource = $filteredItems
            }
        }

        # Initial load
        $dataGrid.ItemsSource = $originalItems

        # Search on text change
        $searchBox.Add_TextChanged($FilterItems)

        [System.Windows.Controls.Grid]::SetRow($dataGrid, 1)
        [void]$mainGrid.Children.Add($dataGrid)

        # Create button panel
        $buttonPanel = New-Object System.Windows.Controls.StackPanel
        $buttonPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $buttonPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $buttonPanel.Margin = "10"

        $selectButton = New-Object System.Windows.Controls.Button
        $selectButton.Content = "Select"
        $selectButton.Width = 80
        $selectButton.Height = 30
        $selectButton.Margin = "0,0,10,0"
        $selectButton.IsDefault = $true

        $cancelButton = New-Object System.Windows.Controls.Button
        $cancelButton.Content = "Cancel"
        $cancelButton.Width = 80
        $cancelButton.Height = 30
        $cancelButton.IsCancel = $true

        [void]$buttonPanel.Children.Add($selectButton)
        [void]$buttonPanel.Children.Add($cancelButton)

        [System.Windows.Controls.Grid]::SetRow($buttonPanel, 2)
        [void]$mainGrid.Children.Add($buttonPanel)

        $selectionWindow.Content = $mainGrid

        # Event handlers
        $selectButton.Add_Click({
            if ($dataGrid.SelectedItems) {
                $selectedResults = @()
                foreach ($selectedItem in $dataGrid.SelectedItems) {
                    $selectedResults += $selectedItem
                }
                $selectionWindow.Tag = $selectedResults
                $selectionWindow.DialogResult = $true
                $selectionWindow.Close()
            } else {
                $syncHash.ShowMessageBox.Invoke("Please select an item.", "No Selection",
                                                [System.Windows.MessageBoxButton]::OK,
                                                [System.Windows.MessageBoxImage]::Warning)
            }
        })

        $cancelButton.Add_Click({
            $selectionWindow.DialogResult = $false
            $selectionWindow.Close()
        })

        $dataGrid.Add_MouseDoubleClick({
            if ($dataGrid.SelectedItem) {
                $selectionWindow.Tag = @($dataGrid.SelectedItem)
                $selectionWindow.DialogResult = $true
                $selectionWindow.Close()
            }
        })

        # Show dialog
        $result = $selectionWindow.ShowDialog()

        if ($result -eq $true) {
            If($ReturnProperty) {
                # Return the specified property from the selected items
                $returnValues = @()
                foreach ($item in $selectionWindow.Tag) {
                    if ($item -is [PSCustomObject] -and $item.PSObject.Properties[$ReturnProperty]) {
                        $returnValues += $item.$ReturnProperty
                    } else {
                        Write-DebugOutput -Message "Selected item does not have property '$ReturnProperty': $($item | ConvertTo-Json -Compress)" -Source $MyInvocation.MyCommand -Level "Error"
                    }
                }
                return $returnValues
            }Else{
                return $selectionWindow.Tag
            }
        }
        return $null
    }
    catch {
        $syncHash.ShowMessageBox.Invoke( ("{0} {1}: {2}" -f $syncHash.UIConfigs.localeErrorMessages.WindowError, $Title, $_.Exception.Message),
                                        $syncHash.UIConfigs.localeTitles.Error,
                                        [System.Windows.MessageBoxButton]::OK,
                                        [System.Windows.MessageBoxImage]::Error)
        return $null
    }
}

Function Add-GraphButton {
    <#
    .SYNOPSIS
    Dynamically adds Graph query buttons to TextBoxes based on graphQueries configuration.
    .DESCRIPTION
    This function scans all graphQueries configurations and automatically adds "Get" buttons
    next to any TextBox controls that have matching names when Graph is connected.
    #>
    # Get all available graph query configurations
    $graphQueryConfigs = $syncHash.UIConfigs.graphQueries.PSObject.Properties

    foreach ($queryConfig in $graphQueryConfigs) {
        $textBoxName = $queryConfig.Name
        $graphQueryData = $queryConfig.Value

        # Check if corresponding TextBox exists in syncHash
        if (-not $syncHash.$textBoxName) {
            Write-DebugOutput -Message "TextBox '$textBoxName' not found in syncHash - skipping" -Source $MyInvocation.MyCommand -Level "Verbose"
            continue
        }

        $textBox = $syncHash.$textBoxName

        # Verify it's actually a TextBox
        if ($textBox.GetType().Name -ne "TextBox") {
            Write-DebugOutput -Message "Control '$textBoxName' is not a TextBox - skipping" -Source $MyInvocation.MyCommand -Level "Verbose"
            continue
        }

        # Add the Graph button to this TextBox
        Add-GraphButtonToTextBox -TextBox $textBox -TextBoxName $textBoxName -GraphQueryData $graphQueryData
    }
}

Function Add-GraphButtonToTextBox {
    <#
    .SYNOPSIS
    Adds a Graph query button to a specific TextBox.
    .DESCRIPTION
    Creates and inserts a Graph query button next to the specified TextBox using the provided configuration.
    #>
    param(
        [Parameter(Mandatory)]
        [System.Windows.Controls.TextBox]$TextBox,

        [Parameter(Mandatory)]
        [string]$TextBoxName,

        [Parameter(Mandatory)]
        [PSObject]$GraphQueryData
    )

    # Find the parent container (should be a StackPanel or Grid)
    $parentContainer = $TextBox.Parent
    if (-not $parentContainer) {
        Write-DebugOutput -Message "TextBox '$TextBoxName' has no parent container" -Source $MyInvocation.MyCommand -Level "Error"
        return
    }

    # Check if button already exists to prevent duplicates
    $buttonName = "Get$($TextBoxName.Replace('_TextBox', ''))Button"
    $existingButton = $null

    if ($parentContainer.GetType().Name -eq "StackPanel") {
        $existingButton = $parentContainer.Children | Where-Object {
            $_.GetType().Name -eq "Button" -and $_.Name -eq $buttonName
        }
    } elseif ($parentContainer.GetType().Name -eq "Grid") {
        $existingButton = $parentContainer.Children | Where-Object {
            $_.GetType().Name -eq "Button" -and $_.Name -eq $buttonName
        }
    }

    if ($existingButton) {
        Write-DebugOutput -Message "Graph button '$buttonName' already exists for '$TextBoxName'" -Source $MyInvocation.MyCommand -Level "Verbose"
        return
    }

    # Create the Graph query button
    $graphButton = New-Object System.Windows.Controls.Button
    $graphButton.Content = "Get $($GraphQueryData.name)"
    $graphButton.Name = $buttonName
    $graphButton.Width = 100
    $graphButton.Height = 28
    $graphButton.Margin = "8,0,0,0"
    $graphButton.Style = $syncHash.Window.FindResource("SecondaryButton")
    $graphButton.ToolTip = "Select $($GraphQueryData.name.ToLower()) from Microsoft Graph"

    # Add global event handlers
    Add-UIControlEventHandler -Control $graphButton

    # Create the click event handler
    $graphButton.Add_Click({
        try {
            # Get search term from TextBox if it has content (excluding placeholder text)
            $searchTerm = ""
            $textBoxValue = $TextBox.Text
            $placeholderKey = "$TextBoxName"
            $placeholderText = $syncHash.UIConfigs.localePlaceholder.$placeholderKey

            if (![string]::IsNullOrWhiteSpace($textBoxValue) -and $textBoxValue -ne $placeholderText) {
                $searchTerm = $textBoxValue
            }

            Write-DebugOutput -Message "Opening Graph selector for $TextBoxName with search term: '$searchTerm'" -Source $MyInvocation.MyCommand -Level "Info"

            # Show the entity selector
            $selectedItems = Show-GraphSelector -GraphEntityType $TextBoxName -SearchTerm $searchTerm

            if ($null -ne $selectedItems) {
                # Get the first selected item
                $selectedItem = $selectedItems

                # Set the value in the textbox using the configured output property
                if ($selectedItem.($GraphQueryData.outProperty)) {
                    $TextBox.Text = $selectedItem.($GraphQueryData.outProperty)
                    $TextBox.Foreground = [System.Windows.Media.Brushes]::Black
                    $TextBox.FontStyle = [System.Windows.FontStyles]::Normal

                    # Get display name for logging/feedback
                    $displayName = if ($GraphQueryData.tipProperty -and $selectedItem.($GraphQueryData.tipProperty)) {
                        $selectedItem.($GraphQueryData.tipProperty)
                    } else {
                        $selectedItem.($GraphQueryData.outProperty)
                    }

                    Write-DebugOutput -Message "Selected $($GraphQueryData.name.ToLower()): $displayName with value: $($selectedItem.($GraphQueryData.outProperty))" -Source $MyInvocation.MyCommand -Level "Info"

                    # Show success message
                    $syncHash.ShowMessageBox.Invoke(
                        "$($GraphQueryData.name) selected: $displayName",
                        "$($GraphQueryData.name) Selected",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Information
                    )
                } else {
                    Write-DebugOutput -Message "Selected $($GraphQueryData.name.ToLower()) missing required property: $($GraphQueryData.outProperty)" -Source $MyInvocation.MyCommand -Level "Error"
                    $syncHash.ShowMessageBox.Invoke(
                        "Selected item is missing required data property.",
                        "Invalid Selection",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Warning
                    )
                }
            } else {
                Write-DebugOutput -Message "No $($GraphQueryData.name.ToLower()) selected from Graph query" -Source $MyInvocation.MyCommand -Level "Info"
            }
        }
        catch {
            Write-DebugOutput -Message "Error in Dynamic Graph button click for $($GraphQueryData.name): $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            $syncHash.ShowMessageBox.Invoke(
                ($syncHash.UIConfigs.localePopupMessages.GraphError -f $_.Exception.Message),
                $syncHash.UIConfigs.localeTitles.GraphError,
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            )
        }
    }.GetNewClosure())

    # Add the button to the parent container
    try {
        if ($parentContainer.GetType().Name -eq "StackPanel") {
            # For StackPanel (horizontal layout), just add to children
            [void]$parentContainer.Children.Add($graphButton)
        } elseif ($parentContainer.GetType().Name -eq "Grid") {
            # For Grid, we need to be more careful about positioning
            # Try to place it in the same row as the TextBox, next column
            $textBoxRow = [System.Windows.Controls.Grid]::GetRow($TextBox)
            $textBoxColumn = [System.Windows.Controls.Grid]::GetColumn($TextBox)

            [System.Windows.Controls.Grid]::SetRow($graphButton, $textBoxRow)
            [System.Windows.Controls.Grid]::SetColumn($graphButton, $textBoxColumn + 1)
            [void]$parentContainer.Children.Add($graphButton)
        } else {
            Write-DebugOutput -Message "Unsupported parent container type: $($parentContainer.GetType().Name) for TextBox '$TextBoxName'" -Source $MyInvocation.MyCommand -Level "Error"
            return
        }

        Write-DebugOutput -Message "Added Graph button '$buttonName' for TextBox '$TextBoxName'" -Source $MyInvocation.MyCommand -Level "Info"
    }
    catch {
        Write-DebugOutput -Message "Failed to add Graph button to container for '$TextBoxName': $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}