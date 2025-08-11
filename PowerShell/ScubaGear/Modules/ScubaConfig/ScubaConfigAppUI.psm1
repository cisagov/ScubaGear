Function Start-ScubaConfigAppUI {
    <#
    .SYNOPSIS
    Opens the ScubaConfig UI for configuring Scuba settings.

    .DESCRIPTION
    This Function opens a WPF-based UI for configuring Scuba settings.

    .EXAMPLE
    Start-ScubaConfigAppUI
    # Opens the ScubaConfig UI.

    .PARAMETER ConfigFilePath
    Specifies the YAML configuration file to load. If not provided, the default configuration will be used.

    .PARAMETER Language
    Specifies the language for the UI. Default is 'en-US'.

    .PARAMETER Online
    If specified, connects to Microsoft Graph to retrieve additional configuration data.

    .PARAMETER M365Environment
    Specifies the M365 environment to use. Valid values are 'commercial', 'dod', 'gcc', 'gcchigh'. Default is 'commercial'.

    .PARAMETER Passthru
    If specified, returns the configuration object after loading.

    .EXAMPLE
    Start-ScubaConfigAppUI

    .EXAMPLE
    $scubaui = Start-ScubaConfigAppUI -ConfigFilePath "C:\path\to\config.yaml" -Online -M365Environment "gcc" -Passthru

    # To show configurations run:
    $scubaui.GeneralSettingsData | ConvertTo-Json
    $scubaui.AdvancedSettingsData | ConvertTo-Json
    $scubaui.ExclusionData | ConvertTo-Json -Depth 5
    $scubaui.OmissionData | ConvertTo-Json -Depth 5
    $scubaui.AnnotationData | ConvertTo-Json -Depth 5

    .NOTES
    This Function requires the ScubaConfig module to be loaded and the ConvertFrom-Yaml Function to be available.
    https://github.com/cisagov/ScubaGear

    .LINK
    Connect-MgGraph
    ConvertFrom-Yaml
    #>

    [CmdletBinding(DefaultParameterSetName = 'Offline')]
    Param(
        $ConfigFilePath,

        [ValidateSet('en-US')]
        $Language = 'en-US',

        [Parameter(Mandatory = $false,ParameterSetName = 'Online')]
        [switch]$Online,

        [Parameter(Mandatory = $true,ParameterSetName = 'Online')]
        [ValidateSet('commercial', 'dod', 'gcc', 'gcchigh')]
        [string]$M365Environment,

        [Parameter(Mandatory = $false,ParameterSetName = 'Online')]
        [string]$TenantName,

        [switch]$Passthru
    )

    [string]${CmdletName} = $MyInvocation.MyCommand
    Write-Verbose ("{0}: Sequencer started" -f ${CmdletName})

    switch($M365Environment){
        'commercial' {
            $GraphEndpoint = "https://graph.microsoft.com"
            $graphEnvironment = "Global"
        }
        'gcc' {
            $GraphEndpoint = "https://graph.microsoft.com"
            $graphEnvironment = "Global"
        }
        'gcchigh' {
            # Set GCC High environment variables
            $GraphEndpoint = "https://graph.microsoft.us"
            $graphEnvironment = "UsGov"
        }
        'dod' {
            # Set DoD environment variables
            $GraphEndpoint = "https://dod-graph.microsoft.us"
            $graphEnvironment = "UsGovDoD"
        }
        default {
            $GraphEndpoint = "https://graph.microsoft.com"
            $graphEnvironment = "Global"
        }

    }

    $GraphParameters = @{
        Environment = $graphEnvironment
    }
    If($TenantName) {
        $GraphParameters.TenantId = $TenantName
    }
    $GraphParameters.Scopes = @(
        "User.Read.All",
        "Group.Read.All",
        "Policy.Read.All",
        "Organization.Read.All",
        "Application.Read.All"
    )

    # Connect to Microsoft Graph if Online parameter is used
    if ($Online) {
        try {
            #Allow PRMFA: Set-MgGraphOption -EnableLoginByWAM:$true
            Write-Output "Connecting to Microsoft Graph..."
            Connect-MgGraph @GraphParameters -NoWelcome -ErrorAction Stop | Out-Null
            $Online = $true
            Write-Output "Successfully connected to Microsoft Graph"
        }
        catch {
            Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
            $Online = $false
            Break
        }
    } else {
        $Online = $false
    }

    # build a hash table with locale data to pass to runspace
    $syncHash = [hashtable]::Synchronized(@{})
    $Runspace = [runspacefactory]::CreateRunspace()
    $syncHash.Runspace = $Runspace
    $syncHash.GraphConnected = $Online
    $syncHash.XamlPath = "$PSScriptRoot\ScubaConfigAppUI.xaml"
    $syncHash.UIConfigPath = "$PSScriptRoot\ScubaConfigAppUI_Control_$Language.json"
    $syncHash.BaselineConfigPath = "$PSScriptRoot\ScubaBaselines_$Language.json"
    $syncHash.ConfigImportPath = $ConfigFilePath
    $syncHash.GraphEndpoint = $GraphEndpoint
    $syncHash.M365Environment = $M365Environment
    $syncHash.TenantName = $TenantName

    # Initialize debug output structures
    $syncHash.DebugLogData = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())  # For debug download
    $syncHash.DebugFlushTimer = $null

    # Initialize data structures
    $syncHash.GeneralSettingsData = [ordered]@{}
    $syncHash.AdvancedSettingsData = [ordered]@{}
    $syncHash.GlobalSettingsData = [ordered]@{}

    #Baseline control data structures: must be same with UIConfigs.baselineControl.dataControlOutput
    $syncHash.ExclusionData = [ordered]@{}
    $syncHash.OmissionData = [ordered]@{}
    $syncHash.AnnotationData = [ordered]@{}

    #$syncHash.Theme = $Theme

    #build runspace
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "ReuseThread"
    $Runspace.Open() | Out-Null
    $Runspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
    $PowerShellCommand = [PowerShell]::Create().AddScript({

        #Load assembies to display UI
        [System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | out-null
        [System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')      | out-null
        #Load additional assemblies for folder browser and certificate selection
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | out-null
        [System.Reflection.Assembly]::LoadWithPartialName('System.Security') | out-null

        #need to replace compile code in xaml and x:Class and xmlns needs to be removed
        #$xaml = $xaml -replace 'xmlns:x="http://schemas.microsoft

        [string]$XAML = (Get-Content $syncHash.XamlPath -ReadCount 0) -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window' -replace 'Click=".*','/>'
        [xml]$UIXML = $XAML
        $reader = New-Object System.Xml.XmlNodeReader ([xml]$UIXML)
        $syncHash.window = [Windows.Markup.XamlReader]::Load($reader)
        $syncHash.UIXML = $UIXML

         # Store Form Objects In PowerShell
        $UIXML.SelectNodes("//*[@Name]") | ForEach-Object{ $syncHash."$($_.Name)" = $syncHash.Window.FindName($_.Name)}

        Function Write-DebugOutput {
            <#
            .SYNOPSIS
            Writes debug output messages to the debug queue when debug mode is enabled.
            .DESCRIPTION
            This Function adds timestamped debug messages to the syncHash debug queue for troubleshooting and monitoring UI operations.
            #>
            param(
                [string]$Message,
                [string]$Source = "General",
                [string]$Level = "Info"
            )

            if ($syncHash.UIConfigs.DebugMode) {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                $logEntry = "[$timestamp] [$Level] [$Source] $Message"

                $syncHash.Debug_TextBox.AppendText($logEntry + "`r`n")
                $syncHash.Debug_TextBox.ScrollToEnd()
                #$syncHash.DebugOutputQueue.Enqueue($logEntry)
                [void]$syncHash.DebugLogData.Add($logEntry)
            }
        }


        #===========================================================================
        # Search Helper Functions
        #===========================================================================

        Function Show-SearchAndFilterControl{
            <#
            .SYNOPSIS
            Initializes search and filter controls for all tabs.
            .DESCRIPTION
            This Function sets up search boxes, filter dropdowns, and their event handlers for baselineControl tabs.
            #>
            param()

            Write-DebugOutput -Message "Showing search and filter controls" -Source "SearchAndFilter" -Level "Info"
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

            Write-DebugOutput -Message "Hiding search and filter controls" -Source "SearchAndFilter" -Level "Info"

            # Hide all search and filter controls
            Foreach($item in $synchash.UIConfigs.baselineControls) {
                $SearchAndFilterBorder = ($item.controlType + "SearchAndFilterBorder")
                $synchash.$SearchAndFilterBorder.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }

        # Add these Functions after the existing UI helper Function
        Function Get-UniqueCriticalityValues {
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

            Write-DebugOutput -Message "Found criticality values: $($criticalityValues -join ', ')" -Source "SearchAndFilter" -Level "Info"

            # Initialize for each tab type
            $tabTypes = $synchash.UIConfigs.baselineControls.controlType

            foreach ($tabType in $tabTypes)
            {
                Write-DebugOutput -Message "Initializing search and filter for $tabType tab" -Source "SearchAndFilter" -Level "Debug"

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
                                Write-DebugOutput -Message "Auto-cleared search for $currentTabType when switching product tabs" -Source "Tab Navigation" -Level "Debug"
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
                                    Write-DebugOutput -Message "Manually cleared search for $currentTabType when switching product tabs (fallback)" -Source "Tab Navigation" -Level "Debug"
                                }
                            }
                        }
                    }.GetNewClosure())

                    Write-DebugOutput -Message "Added auto-clear search Functionality for $tabType product tabs" -Source "SearchAndFilter" -Level "Verbose"
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

                    Write-DebugOutput -Message "Search textbox initialized for $tabType" -Source "SearchAndFilter" -Level "Debug"
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
                    Write-DebugOutput -Message "Added criticality option: $criticality" -Source "SearchAndFilter" -Level "Debug"
                }

                # Set default selection to "All"
                $criticalityComboBox.SelectedIndex = 0

                # Add filter event handler
                $criticalityComboBox.Add_SelectionChanged({
                    Set-SearchAndFilter -TabType $tabType -Criticality $this.SelectedItem.Tag
                }.GetNewClosure())

                Write-DebugOutput -Message "Criticality filter initialized for $tabType with $($criticalityValues.Count) values" -Source "SearchAndFilter" -Level "Info"

            }#end foreach

            Write-DebugOutput -Message "Search and filter initialization completed" -Source "SearchAndFilter" -Level "Info"

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

            Write-DebugOutput -Message "Applying filter: Search='$searchText', Criticality='$Criticality'" -Source "Filter" -Level "Debug"

            # Apply filter to each product tab
            $productTabControl = $syncHash."$($TabType)ProductTabControl"
            if (-not $productTabControl) {
                Write-DebugOutput -Message "Product tab control not found for $TabType" -Source "Filter" -Level "Warning"
                return
            }

            # Check if there are any enabled product tabs
            $enabledTabs = $productTabControl.Items | Where-Object { $_.IsEnabled }
            if (-not $enabledTabs -or $enabledTabs.Count -eq 0) {
                Write-DebugOutput -Message "No enabled product tabs found for $TabType - skipping filter" -Source "Filter" -Level "Debug"
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
                    Write-DebugOutput -Message "Content container not found for product tab: $($productTab.Header)" -Source "Filter" -Level "Warning"
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
                        $shouldShow = Test-CardMatchesFilter -Card $card -SearchText $searchText -Criticality $Criticality

                        if ($shouldShow) {
                            $card.Visibility = [System.Windows.Visibility]::Visible
                            $visibleInThisProduct++
                        } else {
                            $card.Visibility = [System.Windows.Visibility]::Collapsed
                        }
                    } catch {
                        # If error filtering individual card, make it visible by default
                        Write-DebugOutput -Message "Error filtering card: $($_.Exception.Message)" -Source "Filter" -Level "Warning"
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
                Write-DebugOutput -Message "Product $($productTab.Header): $visibleInThisProduct visible cards" -Source "Filter" -Level "Debug"
            }

            # Update result count
            if ($resultCountTextBlock) {
                $resultCountTextBlock.Text = "$totalVisible policies"
            }

            Write-DebugOutput -Message "Filter applied: $totalVisible policies visible total" -Source "Filter" -Level "Info"
        }

        Function Test-CardMatchesFilter {
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
                Write-DebugOutput -Message "Test-CardMatchesFilter called with non-Border control: $($Card.GetType().Name)" -Source "CardFilter" -Level "Warning"
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
                Write-DebugOutput -Message "Error in Test-CardMatchesFilter: $($_.Exception.Message)" -Source "CardFilter" -Level "Warning"
                return $true
            }
        }

        #===========================================================================
        # UI Helper Functions
        #===========================================================================
        # Helper Function to find controls in a container
        Function Find-ControlInContainer {
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
                    $controls += Find-ControlInContainer -Container $child -ControlType $ControlType
                }
            }

            if ($Container.Content) {
                $controls += Find-ControlInContainer -Container $Container.Content -ControlType $ControlType
            }

            return $controls
        }

        # Recursively find all controls
        Function Find-ControlElement {
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
                $results += Find-ControlElement -Parent $child
            }

            return $results
        }

        # Function to add event handlers to a specific control (for dynamically created controls)
        Function Add-ControlEventHandler {
            <#
            .SYNOPSIS
            Adds event handlers to dynamically created WPF controls.
            .DESCRIPTION
            This Function attaches appropriate event handlers to different types of WPF controls (TextBox, ComboBox, Button, etc.) for user interaction tracking.
            #>
            param(
                [System.Windows.Controls.Control]$Control
            )

            Write-DebugOutput -Message ("Adding event handlers for {0}: {1}" -f $Control.GetType().Name, $Control.Name) -Source $MyInvocation.MyCommand.Name -Level "Verbose"

            switch($Control.GetType().Name) {
                'TextBox' {
                    # Add LostFocus event
                    $Control.Add_LostFocus({
                        $controlName = if ($this.Name) { $this.Name } else { "Unnamed TextBox" }
                        $controlValue = $this.Text
                        Write-DebugOutput -Message ("User changed a {0} named [{1}] value to: {2}" -f $Control.GetType().Name, $controlName, $controlValue) -Source "Control Handler" -Level "Debug"
                    }.GetNewClosure())
                }
                'ComboBox' {
                    # Add SelectionChanged event
                    $Control.Add_SelectionChanged({
                        $controlName = if ($this.Name) { $this.Name } else { "Unnamed ComboBox" }
                        $selectedItem = $this.SelectedItem
                        Write-DebugOutput -Message ("User changed a {0} named [{1}] value to: {2}" -f $Control.GetType().Name, $controlName, $selectedItem) -Source "Control Handler" -Level "Debug"
                    }.GetNewClosure())
                }
                'Button' {
                    # Add Click event
                    $Control.Add_Click({
                        $controlName = if ($this.Name) { $this.Name } else { "Unnamed Button" }
                        $controlContent = if ($this.Content) { " ($($this.Content))" } else { "" }
                        Write-DebugOutput -Message ("User changed a {0} named [{1}] value to: {2}" -f $Control.GetType().Name, $controlName, $controlContent) -Source "Control Handler" -Level "Debug"
                    }.GetNewClosure())
                }
                'CheckBox' {
                    # Add Checked event
                    $Control.Add_Checked({
                        $controlName = if ($this.Name) { $this.Name } else { "Unnamed CheckBox" }
                        $controlTag = if ($this.Tag) { " (Tag: $($this.Tag))" } else { "" }
                        Write-DebugOutput -Message ("User changed a {0} named [{1}] value to: {2}" -f $Control.GetType().Name, $controlName, $controlTag) -Source "Control Handler" -Level "Debug"
                    }.GetNewClosure())

                    # Add Unchecked event
                    $Control.Add_Unchecked({
                        $controlName = if ($this.Name) { $this.Name } else { "Unnamed CheckBox" }
                        $controlTag = if ($this.Tag) { " (Tag: $($this.Tag))" } else { "" }
                        Write-DebugOutput -Message ("User changed a {0} named [{1}] value to: {2}" -f $Control.GetType().Name, $controlName, $controlTag) -Source "Control Handler" -Level "Debug"
                    }.GetNewClosure())
                }
            }
        }

        # Helper Function to find control by setting name
        Function Find-ControlBySettingName {
            <#
            .SYNOPSIS
            Searches for WPF controls using various naming conventions.
            .DESCRIPTION
            This Function attempts to locate controls by trying multiple naming patterns and conventions commonly used in the application.
            #>
            param([string]$SettingName)

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

            # Try each pattern
            foreach ($pattern in $namingPatterns) {
                if ($syncHash.$pattern) {
                    return $syncHash.$pattern
                }
            }

            return $null
        }

        # Function to search recursively for controls
        Function Find-ControlByName {
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
                    $result = Find-ControlByName -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Content -and $parent.Content.Children) {
                foreach ($child in $parent.Content.Children) {
                    $result = Find-ControlByName -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Items) {
                foreach ($item in $parent.Items) {
                    if ($item.Content -and $item.Content.Children) {
                        foreach ($child in $item.Content.Children) {
                            $result = Find-ControlByName -parent $child -targetName $targetName
                            if ($result) { return $result }
                        }
                    }
                }
            }

            return $null
        }

        # Helper Function to update control value based on type
        Function Set-ControlValue {
            <#
            .SYNOPSIS
            Updates control values based on their type and handles focus preservation.
            .DESCRIPTION
            This Function sets values on different types of WPF controls while preserving cursor position and preventing timer interference.
            #>
            param(
                [object]$Control,
                [object]$Value,
                [string]$SettingKey
            )

            switch ($Control.GetType().Name) {
                'TextBox' {
                    # Skip updating if user is currently typing in this control
                    if ($Control.IsFocused -and $Control.IsKeyboardFocused) {
                        return
                    }
                    $Control.Text = $Value
                    $Control.Foreground = [System.Windows.Media.Brushes]::Black
                    $Control.FontStyle = [System.Windows.FontStyles]::Normal
                }
                'TextBlock' {
                    # Skip updating if user is currently typing in this control
                    if ($Control.IsFocused -and $Control.IsKeyboardFocused) {
                        return
                    }
                    $Control.Text = $Value
                }
                'CheckBox' {
                    $Control.IsChecked = [bool]$Value
                }
                'ComboBox' {
                    Set-ComboBoxValue -ComboBox $Control -Value $Value -SettingKey $SettingKey
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
                    Write-DebugOutput -Message ("Setting warning for {0}: {1}" -f $SettingKey,$Control.GetType().Name) -Source $MyInvocation.MyCommand.Name -Level "Warning"
                }
            }
        }

        # Function to search recursively for the list container
        Function Find-ListContainer {
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
                    $result = Find-ListContainer -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Content -and $parent.Content.Children) {
                foreach ($child in $parent.Content.Children) {
                    $result = Find-ListContainer -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Items) {
                foreach ($item in $parent.Items) {
                    if ($item.Content -and $item.Content.Children) {
                        foreach ($child in $item.Content.Children) {
                            $result = Find-ListContainer -parent $child -targetName $targetName
                            if ($result) { return $result }
                        }
                    }
                }
            }

            return $null
        }

        # Function to search recursively for the checkbox
        Function Find-CheckBox {
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
                    $result = Find-CheckBox -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Content -and $parent.Content.Children) {
                foreach ($child in $parent.Content.Children) {
                    $result = Find-CheckBox -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Items) {
                foreach ($item in $parent.Items) {
                    if ($item.Content -and $item.Content.Children) {
                        foreach ($child in $item.Content.Children) {
                            $result = Find-CheckBox -parent $child -targetName $targetName
                            if ($result) { return $result }
                        }
                    }
                }
            }

            return $null
        }

        # Function to search recursively for the textbox
        Function Find-TextBox {
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
                    $result = Find-TextBox -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Content -and $parent.Content.Children) {
                foreach ($child in $parent.Content.Children) {
                    $result = Find-TextBox -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Items) {
                foreach ($item in $parent.Items) {
                    if ($item.Content -and $item.Content.Children) {
                        foreach ($child in $item.Content.Children) {
                            $result = Find-TextBox -parent $child -targetName $targetName
                            if ($result) { return $result }
                        }
                    }
                }
            }

            return $null
        }

        Function Find-DatePicker {
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
                    $result = Find-DatePicker -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Content -and $parent.Content.Children) {
                foreach ($child in $parent.Content.Children) {
                    $result = Find-DatePicker -parent $child -targetName $targetName
                    if ($result) { return $result }
                }
            }

            if ($parent.Items) {
                foreach ($item in $parent.Items) {
                    if ($item.Content -and $item.Content.Children) {
                        foreach ($child in $item.Content.Children) {
                            $result = Find-DatePicker -parent $child -targetName $targetName
                            if ($result) { return $result }
                        }
                    }
                }
            }

            return $null
        }

        # Helper Function to update ComboBox values
        Function Set-ComboBoxValue {
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

            # SPECIAL handling for M365Environment ComboBox
            if ($SettingKey -eq "M365Environment" -or $ComboBox.Name -eq "M365Environment_ComboBox") {
                # For M365Environment, we need to check both id and name values
                # First try to match by id (stored in Tag)
                $selectedItem = $ComboBox.Items | Where-Object { $_.Tag -eq $Value }

                # If not found by id, try to find by name in the configuration
                if (-not $selectedItem) {
                    $envConfig = $syncHash.UIConfigs.M365Environment | Where-Object { $_.name -eq $Value }
                    if ($envConfig) {
                        $selectedItem = $ComboBox.Items | Where-Object { $_.Tag -eq $envConfig.id }
                    }
                }

                if ($selectedItem) {
                    $ComboBox.SelectedItem = $selectedItem
                    Write-DebugOutput -Message "Selected M365Environment: $Value" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    return
                }
            }

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
                $ComboBox.SelectedItem = $selectedItem
                Write-DebugOutput -Message ("Setting ComboBox info for {0}: {1}" -f $SettingKey,$Value)  -Source $MyInvocation.MyCommand.Name -Level "Debug"
            } else {
                Write-DebugOutput -Message ("Could not find ComboBox [{0}] with value: {1}" -f $SettingKey,$Value) -Source $MyInvocation.MyCommand.Name -Level "Warning"
            }
        }

        # Function to validate UI field based on regex and required status
        Function Confirm-RequiredField {
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

            # Get the current value based on control type
            if ($UIElement -is [System.Windows.Controls.TextBox]) {
                $currentValue = $UIElement.Text
            } elseif ($UIElement -is [System.Windows.Controls.ComboBox]) {
                $currentValue = $UIElement.SelectedItem
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
                    $UIElement.BorderBrush = [System.Windows.Media.Brushes]::Red
                    $UIElement.BorderThickness = "2"
                } else {
                    $UIElement.BorderBrush = [System.Windows.Media.Brushes]::Gray
                    $UIElement.BorderThickness = "1"
                }
            }

            # Show error message if requested
            if (-not $isValid -and $ShowMessageBox -and ![string]::IsNullOrWhiteSpace($ErrorMessage)) {
                [System.Windows.MessageBox]::Show($ErrorMessage, $syncHash.UIConfigs.localeTitles.ValidationError, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            }

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

            # Set initial state
            if (![string]::IsNullOrWhiteSpace($InitialValue)) {
                $TextBox.Text = $InitialValue
                $TextBox.Foreground = [System.Windows.Media.Brushes]::Black
                $TextBox.FontStyle = [System.Windows.FontStyles]::Normal
                $TextBox.Tag = "HasValue"
            } else {
                $TextBox.Text = $PlaceholderText
                $TextBox.Foreground = [System.Windows.Media.Brushes]::Gray
                $TextBox.FontStyle = [System.Windows.FontStyles]::Italic
                $TextBox.Tag = "Placeholder"
            }

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

        Function Add-DynamicGraphButtons {
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
                    Write-DebugOutput -Message "TextBox '$textBoxName' not found in syncHash - skipping" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    continue
                }

                $textBox = $syncHash.$textBoxName

                # Verify it's actually a TextBox
                if ($textBox.GetType().Name -ne "TextBox") {
                    Write-DebugOutput -Message "Control '$textBoxName' is not a TextBox - skipping" -Source $MyInvocation.MyCommand.Name -Level "Debug"
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
                Write-DebugOutput -Message "TextBox '$TextBoxName' has no parent container" -Source $MyInvocation.MyCommand.Name -Level "Warning"
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
                Write-DebugOutput -Message "Graph button '$buttonName' already exists for '$TextBoxName'" -Source $MyInvocation.MyCommand.Name -Level "Debug"
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
            Add-ControlEventHandler -Control $graphButton

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

                    Write-DebugOutput -Message "Opening Graph selector for $TextBoxName with search term: '$searchTerm'" -Source "Dynamic Graph Button" -Level "Info"

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

                            Write-DebugOutput -Message "Selected $($GraphQueryData.name.ToLower()): $displayName with value: $($selectedItem.($GraphQueryData.outProperty))" -Source "Dynamic Graph Button" -Level "Info"

                            # Show success message
                            [System.Windows.MessageBox]::Show(
                                "$($GraphQueryData.name) selected: $displayName",
                                "$($GraphQueryData.name) Selected",
                                [System.Windows.MessageBoxButton]::OK,
                                [System.Windows.MessageBoxImage]::Information
                            )
                        } else {
                            Write-DebugOutput -Message "Selected $($GraphQueryData.name.ToLower()) missing required property: $($GraphQueryData.outProperty)" -Source "Dynamic Graph Button" -Level "Warning"
                            [System.Windows.MessageBox]::Show(
                                "Selected item is missing required data property.",
                                "Invalid Selection",
                                [System.Windows.MessageBoxButton]::OK,
                                [System.Windows.MessageBoxImage]::Warning
                            )
                        }
                    } else {
                        Write-DebugOutput -Message "No $($GraphQueryData.name.ToLower()) selected from Graph query" -Source "Dynamic Graph Button" -Level "Info"
                    }
                }
                catch {
                    Write-DebugOutput -Message "Error in Dynamic Graph button click for $($GraphQueryData.name): $($_.Exception.Message)" -Source "Dynamic Graph Button" -Level "Error"
                    [System.Windows.MessageBox]::Show(
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
                    Write-DebugOutput -Message "Unsupported parent container type: $($parentContainer.GetType().Name) for TextBox '$TextBoxName'" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                    return
                }

                Write-DebugOutput -Message "Added Graph button '$buttonName' for TextBox '$TextBoxName'" -Source $MyInvocation.MyCommand.Name -Level "Info"
            }
            catch {
                Write-DebugOutput -Message "Failed to add Graph button to container for '$TextBoxName': $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
            }
        }
        #===========================================================================
        # Help Tooltip Functions
        #===========================================================================

        # Add help icon next to controls
        # Add this function after the existing help functions around line 1357:
        # Consolidated popup function that handles both simple and rich popups
        Function Add-HoverPopup {
            <#
            .SYNOPSIS
            Adds a hover popup to a control.

            .DESCRIPTION
            This function creates a hover popup for a specified control, allowing for additional information to be displayed when the user hovers over the control.

            .PARAMETER Control
            The control to attach the hover popup to.

            .PARAMETER Title
            The title of the hover popup.

            .PARAMETER Content
            The content to display in the hover popup.

            .PARAMETER Placement
            The placement of the hover popup relative to the control.

            .PARAMETER AdditionalSections
            Any additional sections to include in the hover popup.
            #>
            param(
                [Parameter(Mandatory=$true)]
                [System.Windows.Controls.Control]$Control,
                [Parameter(Mandatory=$true)]
                [string]$Title,
                [Parameter(Mandatory=$true)]
                [string]$Content,
                [Parameter(Mandatory=$false)]
                [ValidateSet("Left", "Right", "Top", "Bottom")]
                [string]$Placement = "Right",
                [hashtable]$AdditionalSections = @{}
            )

            # Create the popup
            $popup = New-Object System.Windows.Controls.Primitives.Popup
            $popup.PlacementTarget = $Control
            $popup.Placement = [System.Windows.Controls.Primitives.PlacementMode]::$Placement
            $popup.StaysOpen = $false
            $popup.AllowsTransparency = $true

            # Create popup border
            $popupBorder = New-Object System.Windows.Controls.Border
            $popupBorder.Background = [System.Windows.Media.Brushes]::White
            $popupBorder.BorderBrush = [System.Windows.Media.Brushes]::Gray
            $popupBorder.BorderThickness = "1"
            $popupBorder.CornerRadius = "4"
            $popupBorder.Padding = "10"
            $popupBorder.MaxWidth = if ($AdditionalSections.Count -gt 0) { 350 } else { 300 }

            # Add shadow effect
            $dropShadow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $dropShadow.Color = [System.Windows.Media.Colors]::Gray
            $dropShadow.Direction = 315
            $dropShadow.ShadowDepth = 2
            $dropShadow.Opacity = 0.5
            $popupBorder.Effect = $dropShadow

            # Choose content type based on whether we have additional sections
            if ($AdditionalSections.Count -gt 0) {
                # Use FlowDocument for rich content
                $flowDocViewer = New-Object System.Windows.Controls.FlowDocumentScrollViewer
                $flowDocViewer.VerticalScrollBarVisibility = "Auto"
                $flowDocViewer.HorizontalScrollBarVisibility = "Hidden"
                $flowDocViewer.IsToolBarVisible = $false
                $popupBorder.MaxHeight = 200

                # Create FlowDocument
                $flowDoc = New-Object System.Windows.Documents.FlowDocument
                $flowDoc.FontFamily = "Segoe UI"
                $flowDoc.FontSize = 12

                # Title paragraph
                $titleParagraph = New-Object System.Windows.Documents.Paragraph
                $titleParagraph.Margin = "0,0,0,8"
                $titleRun = New-Object System.Windows.Documents.Run
                $titleRun.Text = $Title
                $titleRun.FontWeight = "Bold"
                $titleRun.FontSize = 14
                $titleRun.Foreground = $syncHash.Window.FindResource("PrimaryBrush")
                $titleParagraph.AddChild($titleRun)
                $flowDoc.AddChild($titleParagraph)

                # Content paragraph
                $contentParagraph = New-Object System.Windows.Documents.Paragraph
                $contentParagraph.Margin = "0,0,0,8"
                $contentRun = New-Object System.Windows.Documents.Run
                $contentRun.Text = $Content
                $contentParagraph.AddChild($contentRun)
                $flowDoc.AddChild($contentParagraph)

                # Additional sections
                foreach ($sectionTitle in $AdditionalSections.Keys) {
                    $sectionParagraph = New-Object System.Windows.Documents.Paragraph
                    $sectionParagraph.Margin = "0,4,0,4"

                    # Section title
                    $sectionTitleRun = New-Object System.Windows.Documents.Run
                    $sectionTitleRun.Text = "$sectionTitle`: "
                    $sectionTitleRun.FontWeight = "Bold"
                    $sectionParagraph.AddChild($sectionTitleRun)

                    # Section content
                    $sectionContentRun = New-Object System.Windows.Documents.Run
                    $sectionContentRun.Text = $AdditionalSections[$sectionTitle]
                    $sectionParagraph.AddChild($sectionContentRun)

                    $flowDoc.AddChild($sectionParagraph)
                }

                $flowDocViewer.Document = $flowDoc
                $popupBorder.Child = $flowDocViewer
            } else {
                # Use simple StackPanel for basic content
                $contentStack = New-Object System.Windows.Controls.StackPanel

                # Title
                $titleBlock = New-Object System.Windows.Controls.TextBlock
                $titleBlock.Text = $Title
                $titleBlock.FontWeight = "Bold"
                $titleBlock.FontSize = 14
                $titleBlock.Foreground = $syncHash.Window.FindResource("PrimaryBrush")
                $titleBlock.Margin = "0,0,0,8"
                [void]$contentStack.Children.Add($titleBlock)

                # Content
                $contentBlock = New-Object System.Windows.Controls.TextBlock
                $contentBlock.Text = $Content
                $contentBlock.FontSize = 12
                $contentBlock.TextWrapping = "Wrap"
                $contentBlock.Foreground = $syncHash.Window.FindResource("TextBrush")
                [void]$contentStack.Children.Add($contentBlock)

                $popupBorder.Child = $contentStack
            }

            $popup.Child = $popupBorder

            # Add mouse events to both the control AND the popup
            $Control.Add_MouseEnter({
                $popup.IsOpen = $true
            }.GetNewClosure())

            $Control.Add_MouseLeave({
                # Only close if mouse is not over the popup
                if (-not $popup.IsMouseOver) {
                    $popup.IsOpen = $false
                }
            }.GetNewClosure())

            # Add popup mouse events to prevent flickering
            $popup.Add_MouseEnter({
                $popup.IsOpen = $true
            }.GetNewClosure())

            $popup.Add_MouseLeave({
                $popup.IsOpen = $false
            }.GetNewClosure())
            return $popup
        }

        Function Initialize-HelpPopups {
            <#
            .SYNOPSIS
            Automatically adds hover popups to all HelpLabel controls in the UI.
            .DESCRIPTION
            This function scans the UI for controls with names ending in "HelpLabel" and adds hover popups with content from the localeHelpTips configuration.
            #>

            Write-DebugOutput -Message "Starting dynamic help popup initialization" -Source $MyInvocation.MyCommand.Name -Level "Info"

            # Find all controls with names ending in "HelpLabel"
            $helpLabels = $syncHash.GetEnumerator() | Where-Object {
                $_.Key -like "*HelpLabel" -and $_.Value -is [System.Windows.Controls.Label]
            }

            Write-DebugOutput -Message "Found $($helpLabels.Count) HelpLabel controls" -Source $MyInvocation.MyCommand.Name -Level "Debug"

            foreach ($helpLabel in $helpLabels) {
                $controlName = $helpLabel.Key
                $control = $helpLabel.Value

                Write-DebugOutput -Message "Processing help label: $controlName" -Source $MyInvocation.MyCommand.Name -Level "Debug"

                # Check if help tip configuration exists in localeHelpTips
                if ($syncHash.UIConfigs.localeHelpTips.PSObject.Properties.Name -contains $controlName) {
                    $helpData = $syncHash.UIConfigs.localeHelpTips.$controlName

                    # Use Title from config if available, otherwise generate from control name
                    $title = $helpData.Title

                    # Get content
                    $content = $helpData.Content

                    $Params = @{
                        Control = $control
                        Title = $title
                        Content = $content
                    }

                    # Check for additional sections to determine popup type
                    if ($helpData.AdditionalSections) {
                        # Convert PSCustomObject to hashtable
                        $additionalSectionsHashtable = [ordered]@{}
                        foreach ($property in $helpData.AdditionalSections.PSObject.Properties) {
                            $additionalSectionsHashtable[$property.Name] = $property.Value
                        }
                        $Params.Add("AdditionalSections", $additionalSectionsHashtable)
                    }

                    If($helpData.Placement) {
                        $Params.Add("Placement", $helpData.Placement)
                    }

                    # Add the hover popup to the control
                    Add-HoverPopup @Params

                    Write-DebugOutput -Message "Added hover popup to: $controlName" -Source $MyInvocation.MyCommand.Name -Level "Info"
                } else {
                    Write-DebugOutput -Message "No help tip configuration found for: $controlName in localeHelpTips" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                }
            }

            Write-DebugOutput -Message "Help popup initialization completed" -Source $MyInvocation.MyCommand.Name -Level "Info"
        }
        #===========================================================================
        # UPDATE UI Functions
        #===========================================================================
        Function Update-AllUIFromData {
            <#
            .SYNOPSIS
            Updates all UI elements from the current data structures.
            .DESCRIPTION
            This Function refreshes all UI components to reflect the current state of the configuration data.
            #>
            try {
                # Update general settings (textboxes, comboboxes)
                Update-GeneralSettingsFromData

                # Update advanced settings
                Update-AdvancedSettingsFromData

                # Update product checkboxes
                Update-ProductNameCheckboxFromData

                # Update all baseline controls (exclusions, annotations, omissions) using consolidated function
                Update-BaselineControlUIFromData

                Write-DebugOutput -Message "All UI elements updated from imported YAML data" -Source $MyInvocation.MyCommand.Name -Level "Info"
            }
            catch {
                Write-DebugOutput -Message "Error updating UI from imported data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
            }
        }

        # Function to update general settings UI from data (Dynamic Version)
        Function Update-GeneralSettingsFromData {
            <#
            .SYNOPSIS
            Updates general settings UI controls from data.
            .DESCRIPTION
            This Function populates general settings controls with values from the GeneralSettings data structure.
            #>
            if (-not $syncHash.GeneralSettingsData) { return }

            try {
                foreach ($settingKey in $syncHash.GeneralSettingsData.Keys) {
                    $settingValue = $syncHash.GeneralSettingsData[$settingKey]

                    # Skip if value is null or empty
                    if ($null -eq $settingValue) { return }

                    # Find the corresponding XAML control using various naming patterns
                    $control = Find-ControlBySettingName -SettingName $settingKey

                    if ($control) {
                        Set-ControlValue -Control $control -Value $settingValue -SettingKey $settingKey
                    } else {
                        Write-DebugOutput -Message ("No UI control found for setting: {0}" -f $settingKey) -Source $MyInvocation.MyCommand.Name -Level "Warning"
                    }
                }
            }
            catch {
                Write-DebugOutput -Message ("Error updating general settings UI: {0}" -f $_.Exception.Message) -Source $MyInvocation.MyCommand.Name -Level "Error"
            }
        }

        # Function to update advanced settings UI from data
        Function Update-AdvancedSettingsFromData {
            <#
            .SYNOPSIS
            Updates advanced settings UI controls from data.
            .DESCRIPTION
            This Function populates advanced settings controls with values from the AdvancedSettings data structure and enables appropriate toggle sections.
            #>
            if (-not $syncHash.AdvancedSettingsData) { return }

            try {
                # First, determine which sections need to be enabled based on imported data
                $sectionsToEnable = @()

                if ($syncHash.UIConfigs.advancedSections) {
                    foreach ($toggleName in $syncHash.UIConfigs.advancedSections.PSObject.Properties.Name) {
                        $sectionConfig = $syncHash.UIConfigs.advancedSections.$toggleName

                        # Check if any setting from this section exists in imported data
                        $sectionHasData = $false
                        foreach ($fieldControlName in $sectionConfig.fields) {
                            $settingName = $fieldControlName -replace '_TextBox$|_CheckBox$', ''
                            if ($syncHash.AdvancedSettingsData.Contains($settingName)) {
                                $sectionHasData = $true
                                break
                            }
                        }

                        # Enable the toggle if this section has data
                        if ($sectionHasData) {
                            $sectionsToEnable += $toggleName
                            $toggleControl = $syncHash.$toggleName
                            if ($toggleControl -and $toggleControl -is [System.Windows.Controls.CheckBox]) {
                                $toggleControl.IsChecked = $true
                                Write-DebugOutput -Message "Enabled advanced section toggle: $toggleName" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                            }
                        }
                    }
                }



                # Now update the actual field values
                foreach ($settingKey in $syncHash.AdvancedSettingsData.Keys) {
                    $settingValue = $syncHash.AdvancedSettingsData[$settingKey]

                    # Skip if value is null or empty
                    if ($null -eq $settingValue) { continue }

                    # Find the corresponding XAML control using various naming patterns
                    $control = Find-ControlBySettingName -SettingName $settingKey

                    if ($control) {
                        Set-ControlValue -Control $control -Value $settingValue -SettingKey $settingKey
                        Write-DebugOutput -Message "Updated advanced setting control: $settingKey = $settingValue" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    } else {
                        Write-DebugOutput -Message "Could not find control for advanced setting: $settingKey" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                    }
                }
            }
            catch {
                Write-DebugOutput -Message "Error updating advanced settings from data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
            }
        }

        Function Update-ProductNameCheckboxFromData{
            <#
            .SYNOPSIS
            Updates product name checkbox controls from data.
            .DESCRIPTION
            This Function sets the checked state of product name checkboxes based on the current configuration data.
            #>
            param([string[]]$ProductNames = $null)

            # Get all product checkboxes
            $allProductCheckboxes = $syncHash.ProductsGrid.Children | Where-Object {
                $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "*ProductCheckBox"
            }

            # Get all available product IDs
            $allProductIds = $syncHash.UIConfigs.products | Select-Object -ExpandProperty id

            # Determine which products to select
            $productsToSelect = @()

            if ($ProductNames) {
                if ($ProductNames -contains '*') {
                    $productsToSelect = $allProductIds
                    Write-DebugOutput -Message "Selecting all products due to '*' value" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                } else {
                    $productsToSelect = $ProductNames
                }
            } elseif ($syncHash.GeneralSettingsData.ProductNames) {
                $productsToSelect = $syncHash.GeneralSettingsData.ProductNames
            }

            try {

                # Get current state
                $currentlyChecked = @()
                foreach ($checkbox in $allProductCheckboxes) {
                    if ($checkbox.IsChecked) {
                        $currentlyChecked += $checkbox.Tag
                    }
                }

                Write-DebugOutput -Message "Currently checked products: $($currentlyChecked -join ', ')" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                Write-DebugOutput -Message "Products to select: $($productsToSelect -join ', ')" -Source $MyInvocation.MyCommand.Name -Level "Debug"

                # First, CHECK the products that should be selected (this ensures we always have at least one checked)
                foreach ($productId in $productsToSelect) {
                    $checkbox = $allProductCheckboxes | Where-Object { $_.Tag -eq $productId }
                    if ($checkbox -and -not $checkbox.IsChecked) {
                        Write-DebugOutput -Message "Checking product: $productId" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                        $checkbox.IsChecked = $true
                    }
                }

                # Now, UNCHECK products that should not be selected (avoiding the minimum selection error)
                foreach ($checkbox in $allProductCheckboxes) {
                    $productId = $checkbox.Tag
                    if ($checkbox.IsChecked -and $productId -notin $productsToSelect) {
                        Write-DebugOutput -Message "Unchecking product: $productId" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                        $checkbox.IsChecked = $false
                    }
                }

                # Now check selected products and create their content
                foreach ($productId in $productsToSelect) {
                    $checkbox = $allProductCheckboxes | Where-Object { $_.Tag -eq $productId }
                    if ($checkbox) {
                        $checkbox.IsChecked = $true
                        #$product = $syncHash.UIConfigs.products | Where-Object { $_.id -eq $productId }

                        Foreach($baseline in $syncHash.UIConfigs.baselineControls) {
                            $tabName = "$($productId)$($baseline.controlType)Tab"
                            if ($syncHash.$tabName) {
                                $syncHash.$tabName.IsEnabled = $true
                                $container = $syncHash.("$($productId)$($baseline.controlType)Content")
                                if ($container -and $container.Children.Count -eq 0) {
                                    New-ProductPolicyCards -ProductName $productId -Container $container -ControlType $baseline.controlType
                                    Write-DebugOutput -Message ("Created content for: {0} ({1})" -f $productId, $baseline.controlType) -Source $MyInvocation.MyCommand.Name -Level "Debug"
                                }
                            }
                        }

                        Write-DebugOutput -Message ("Enabled tabs and ensured content for: {0}" -f $productId) -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    }
                }

                # Apply initial filters now that cards are created
                if ($productsToSelect.Count -gt 0) {
                    # Trigger initial filter for all tab types after a brief delay to ensure cards are rendered
                    $syncHash.Window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [Action]{
                        try {
                            foreach ($tabType in $syncHash.UIConfigs.baselineControls.ControlType) {
                                Set-SearchAndFilter -TabType $tabType
                            }
                            Write-DebugOutput -Message "Initial filters applied after product selection" -Source "ProductUpdate" -Level "Info"
                        } catch {
                            Write-DebugOutput -Message "Error applying initial filters: $($_.Exception.Message)" -Source "ProductUpdate" -Level "Warning"
                        }
                    })
                }
                                # Update GeneralSettings
                if ($productsToSelect.Count -gt 0) {
                    $syncHash.GeneralSettingsData["ProductNames"] = $productsToSelect
                } else {
                    $syncHash.GeneralSettingsData.Remove("ProductNames")
                }

            } catch {
                Write-DebugOutput -Message ("Error updating product checkboxes: {0}" -f $_.Exception.Message) -Source $MyInvocation.MyCommand.Name -Level "Error"
            }
            Write-DebugOutput -Message ("Updated checkboxes and tabs for products: {0}" -f ($productsToSelect -join ', ')) -Source $MyInvocation.MyCommand.Name -Level "Debug"
        }

        Function Update-BaselineControlUIFromData {
        <#
            .SYNOPSIS
            Updates baseline control UI elements from data using configuration-driven approach.
            .DESCRIPTION
            This Function populates baseline control elements with values from the BaselineConfig data structure.
            Uses the baselineControls configuration to handle all types (exclusions, annotations, omissions) dynamically.
            When new baseline controls are added to the config, no code changes are needed.
            #>

            $BaselineControls = $syncHash.UIConfigs.baselineControls

            Foreach($baseline in $BaselineControls) {
                $outputData = $syncHash.($baseline.dataControlOutput)

                # Skip if no data exists for this baseline control
                if (-not $outputData) {
                    Write-DebugOutput -Message "No data found for baseline control: $($baseline.controlType)" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    continue
                }

                Write-DebugOutput -Message "Updating UI for baseline control: $($baseline.controlType)" -Source $MyInvocation.MyCommand.Name -Level "Info"

                # Determine how to update the data based on the baseline control type
                If($baseline.supportsAllProducts) {
                    # Handle controls that support all products (Annotations, Omissions)
                    # Data structure: Product -> yamlValue -> PolicyId -> FieldData
                    Update-PolicyCardsFromData -BaselineConfig $baseline -Data $outputData
                } Else {
                    # Handle product-specific controls (Exclusions)
                    # Data structure: Product -> PolicyId -> ExclusionType -> FieldData
                    Update-ProductCardsFromData -BaselineConfig $baseline -Data $outputData
                }
            }
        }
        Function Update-PolicyCardsFromData {
            <#
            .SYNOPSIS
            Updates UI for baseline controls that support all products (Annotations, Omissions).
            .DESCRIPTION
            Handles data structure: Product -> yamlValue -> PolicyId -> FieldData
            #>
            param(
                [Parameter(Mandatory=$true)]
                $BaselineConfig,
                [Parameter(Mandatory=$true)]
                $Data
            )

            # Iterate through products and policies in hashtable structure
            foreach ($productName in $Data.Keys) {
                foreach ($yamlValue in $Data[$productName].Keys) {
                    foreach ($policyId in $Data[$productName][$yamlValue].Keys) {
                        $policyData = $Data[$productName][$yamlValue][$policyId]

                        try {
                            # Get the checkbox name based on control type
                            $checkboxName = ($policyId.replace('.', '_') + "_$($BaselineConfig.controlType.TrimEnd('s'))Checkbox")
                            $checkbox = $syncHash.$checkboxName

                            if ($checkbox) {
                                # Mark as checked
                                $checkbox.IsChecked = $true

                                # Dynamic field handling for other types (Annotations, etc.)
                                Update-DynamicFields -PolicyId $policyId -FieldData $policyData -BaselineConfig $BaselineConfig

                                # Update visual elements (remove button, header styling)
                                Update-CardVisuals -PolicyId $policyId -BaselineConfig $BaselineConfig
                            }
                        }
                        catch {
                            Write-DebugOutput -Message "Error updating $($BaselineConfig.controlType) UI for policy $policyId in product $productName`: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                        }
                    }
                }
            }
        }


        Function Update-ProductCardsFromData {
            <#
            .SYNOPSIS
            Updates UI for baseline controls that are product-specific (Exclusions).
            .DESCRIPTION
            Handles data structure: Product -> PolicyId -> ExclusionType -> FieldData
            #>
            param(
                [Parameter(Mandatory=$true)]
                $BaselineConfig,
                [Parameter(Mandatory=$true)]
                $Data
            )

            # Iterate through products and policies in hashtable structure
            foreach ($productName in $Data.Keys) {
                foreach ($policyId in $Data[$productName].Keys) {
                    try {
                        # Find the field configuration from the baseline config
                        $baseline = $syncHash.Baselines.$productName | Where-Object { $_.id -eq $policyId }
                        if ($baseline -and $baseline.($BaselineConfig.fieldControlName) -ne $BaselineConfig.defaultFields) {

                            # Get the checkbox name based on control type
                            $checkboxName = ($policyId.replace('.', '_') + "_$($BaselineConfig.controlType.TrimEnd('s'))Checkbox")
                            $checkbox = $syncHash.$checkboxName

                            if ($checkbox) {
                                # Mark as checked
                                $checkbox.IsChecked = $true

                                # Handle dynamic field population
                                $policyData = $Data[$productName][$policyId]
                                Update-DynamicFields -PolicyId $policyId -FieldData $policyData -BaselineConfig $BaselineConfig -Baseline $baseline

                                # Update visual elements (remove button, header styling)
                                Update-CardVisuals -PolicyId $policyId -BaselineConfig $BaselineConfig
                            }
                        }
                    }
                    catch {
                        Write-DebugOutput -Message "Error updating $($BaselineConfig.controlType) UI for policy $policyId in product $productName`: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                    }
                }
            }
        }

        Function Update-DynamicFields {
            <#
            .SYNOPSIS
            Updates fields dynamically based on configuration for any baseline control type.
            #>
            param(
                [string]$PolicyId,
                $FieldData,
                $BaselineConfig,
                $Baseline = $null
            )

            # Determine the field configuration to use
            $fieldConfigName = $BaselineConfig.defaultFields

            # For product-specific controls, get the field configuration from the baseline
            if ($Baseline -and $BaselineConfig.fieldControlName) {
                $fieldConfigName = $Baseline.($BaselineConfig.fieldControlName)
            }

            # Handle legacy annotation format first
            if ($BaselineConfig.controlType -eq "Annotations" -and $FieldData -isnot [hashtable]) {
                $commentTextBoxName = ($PolicyId.replace('.', '_') + "_Comment_TextBox")
                $commentTextBox = $syncHash.$commentTextBoxName
                if ($commentTextBox) {
                    $commentTextBox.Text = $FieldData.ToString()
                    $commentTextBox.Foreground = [System.Windows.Media.Brushes]::Black
                    $commentTextBox.FontStyle = [System.Windows.FontStyles]::Normal
                }
                return
            }

            # Get the field list configuration
            $FieldListConfig = $syncHash.UIConfigs.inputTypes.$fieldConfigName

            if (-not $FieldListConfig) {
                Write-DebugOutput -Message "No field configuration found for: $fieldConfigName" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                return
            }

            # Iterate through field data (YAML key names)
            foreach ($yamlKeyName in $FieldData.Keys) {
                $fieldDataValues = $FieldData[$yamlKeyName]

                # Populate the data fields based on field configuration
                foreach ($field in $FieldListConfig.fields) {
                    # Determine field name for control naming
                    $fieldName = if ($field.value) { $field.value } else { $field.name }

                    # Build control name based on control type and field configuration
                    $controlPrefix = if ($BaselineConfig.controlType -eq "Exclusions") { $fieldConfigName } else { $BaselineConfig.controlType.TrimEnd('s') }
                    $controlName = ($PolicyId.replace('.', '_') + "_" + $controlPrefix + "_" + $fieldName)

                    if ($fieldDataValues.Keys -contains $fieldName) {
                        $fieldValue = $fieldDataValues[$fieldName]

                        if ($field.type -eq "array" -and $fieldValue -is [array]) {
                            # Handle array fields
                            Update-ArrayField -ControlName $controlName -FieldValue $fieldValue
                        } else {
                            # Handle single value fields
                            Update-SingleField -ControlName $controlName -FieldValue $fieldValue -Field $field -PolicyId $PolicyId
                        }
                    }
                }
            }
        }

        Function Update-ArrayField {
            <#
            .SYNOPSIS
            Updates array field controls (lists).
            #>
            param(
                [string]$ControlName,
                [array]$FieldValue
            )

            $listControl = ($ControlName + "_List")
            $listContainer = $syncHash.$listControl

            if ($listContainer) {
                # Clear existing items
                $listContainer.Children.Clear()

                # Add each array item
                foreach ($item in $FieldValue) {
                    $itemPanel = New-Object System.Windows.Controls.StackPanel
                    $itemPanel.Orientation = "Horizontal"
                    $itemPanel.Margin = "0,2,0,2"

                    $itemText = New-Object System.Windows.Controls.TextBlock
                    $itemText.Text = $item
                    $itemText.VerticalAlignment = "Center"
                    $itemText.Margin = "0,0,8,0"

                    $removeBtn = New-Object System.Windows.Controls.Button
                    $removeBtn.Content = "Remove"
                    $removeBtn.Background = [System.Windows.Media.Brushes]::Red
                    $removeBtn.Foreground = [System.Windows.Media.Brushes]::White
                    $removeBtn.Width = 60
                    $removeBtn.Height = 20
                    $removeBtn.Add_Click({
                        $listContainer.Children.Remove($itemPanel)
                        Write-DebugOutput -Message "Item removed: $item" -Source $listContainer -Level "Info"
                    }.GetNewClosure())

                    [void]$itemPanel.Children.Add($itemText)
                    [void]$itemPanel.Children.Add($removeBtn)
                    [void]$listContainer.Children.Add($itemPanel)
                }
            }
        }

        Function Update-SingleField {
            <#
            .SYNOPSIS
            Updates single value field controls (textboxes, datepickers).
            #>
            param(
                [string]$ControlName,
                $FieldValue,
                $Field,
                [string]$PolicyId
            )

            $TextboxControl = ($ControlName + "_TextBox")
            $control = $syncHash.$TextboxControl

            if ($control) {
                $control.Text = $FieldValue
                $control.Foreground = [System.Windows.Media.Brushes]::Black
                $control.FontStyle = [System.Windows.FontStyles]::Normal

                # Also update DatePicker if this is a dateString field
                if ($Field.type -eq "dateString") {
                    $DatePickerControl = ($ControlName + "_DatePicker")
                    $datePicker = $syncHash.$DatePickerControl
                    if ($datePicker) {
                        try {
                            $dateValue = [DateTime]::ParseExact($FieldValue, "yyyy-MM-dd", $null)
                            $datePicker.SelectedDate = $dateValue
                        } catch {
                            Write-DebugOutput -Message "Error parsing date '$FieldValue' for field '$($Field.name)' in policy '$PolicyId': $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                        }
                    }
                }
            }
        }

        Function Update-CardVisuals {
            <#
            .SYNOPSIS
            Updates visual elements of a card (remove button, header styling) based on baseline configuration.
            #>
            param(
                [string]$PolicyId,
                $BaselineConfig
            )

            # Show remove button
            $removeButtonName = ($PolicyId.replace('.', '_') + "_Remove$($BaselineConfig.controlType.TrimEnd('s'))")
            $removeButton = $syncHash.$removeButtonName
            if ($removeButton) {
                $removeButton.Visibility = "Visible"
            }

            # Make policy header bold
            $policyHeaderName = ($PolicyId.replace('.', '_') + "_PolicyHeader")
            if ($syncHash.$policyHeaderName) {
                $syncHash.$policyHeaderName.FontWeight = "Bold"
            }
        }

        #===========================================================================
        # Product Helper Functions
        #===========================================================================

        # Function to collect ProductNames from UI checkboxes and update GeneralSettings
        Function Update-ProductNames {
            <#
            .SYNOPSIS
            Collects checked product checkboxes from UI and updates $syncHash.GeneralSettingsData.ProductNames

            .DESCRIPTION
            This Function scans the UI for checked product checkboxes and updates the GeneralSettings
            with the actual list of selected products. This is used for UI-to-data synchronization.
            #>

            # Collect ProductNames from checked checkboxes
            $selectedProducts = @()
            $allProductCheckboxes = $syncHash.ProductsGrid.Children | Where-Object {
                $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "*ProductCheckBox"
            }

            foreach ($checkbox in $allProductCheckboxes) {
                if ($checkbox.IsChecked) {
                    $selectedProducts += $checkbox.Tag
                    Write-DebugOutput -Message "Checked checkbox: $($checkbox.Tag)" -Source $MyInvocation.MyCommand.Name -Level "Info"
                }
            }

            # Update the GeneralSettings with actual product list
            if ($selectedProducts.Count -gt 0) {
                $syncHash.GeneralSettingsData["ProductNames"] = $selectedProducts
            } else {
                # Remove ProductNames if no products are selected
                $syncHash.GeneralSettingsData.Remove("ProductNames")
            }

            Write-DebugOutput -Message ("Updated ProductNames in GeneralSettings: {0}" -f ($selectedProducts -join ', ')) -Source $MyInvocation.MyCommand.Name -Level "Debug"
        }



        # Function to get ProductNames formatted for YAML output
        Function Get-ProductNamesForYaml {
            <#
            .SYNOPSIS
            Returns ProductNames formatted appropriately for YAML output

            .DESCRIPTION
            This Function determines the correct format for ProductNames in YAML output.
            If all available products are selected, returns ['*'].
            Otherwise, returns the actual list of selected products.
            #>

            # Check if we have any selected products
            if (-not $syncHash.GeneralSettingsData.ProductNames -or $syncHash.GeneralSettingsData.ProductNames.Count -eq 0) {
                Write-DebugOutput -Message "No ProductNames selected, returning empty array for YAML" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                return @()
            }

            # Get all available product IDs
            $allProductIds = $syncHash.UIConfigs.products | Select-Object -ExpandProperty id

            # Check if all products are selected
            $selectedProducts = $syncHash.GeneralSettingsData.ProductNames | Sort-Object
            $availableProducts = $allProductIds | Sort-Object
            $isAllProductsSelected = ($selectedProducts.Count -eq $availableProducts.Count) -and
                                   (-not (Compare-Object $selectedProducts $availableProducts))

            if ($isAllProductsSelected) {
                Write-DebugOutput -Message "All products selected, returning '*' for YAML output" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                return "`nProductNames: ['*']"
            } else {
                Write-DebugOutput -Message ("Returning specific product list for YAML: {0}" -f ($selectedProducts -join ', ')) -Source $MyInvocation.MyCommand.Name -Level "Debug"
                Return ("`nProductNames: " + ($selectedProducts | ForEach-Object { "`n  - $_" }) -join '')
            }
        }

        # Function to populate cards for product policies
        Function New-ProductPolicyCards {
            <#
            .SYNOPSIS
            Creates policy cards for baselineControl.
            .DESCRIPTION
            This Function generates UI cards for each policy baseline of a product, allowing users to configure baselines.
            #>
            param(
                [string]$ProductName,
                [System.Windows.Controls.StackPanel]$Container,
                [string]$ControlType
            )

            $Container.Children.Clear()

            # Get the baseline control configuration for this type
            $baselineControl = $syncHash.UIConfigs.baselineControls | Where-Object { $_.controlType -eq $ControlType }

            if (-not $baselineControl) {
                Write-DebugOutput -Message ("No baseline control configuration found for: {0}" -f $ControlType) -Source $MyInvocation.MyCommand.Name -Level "Warning"
                return
            }

            # Get baselines for this product
            $baselines = $syncHash.Baselines.$ProductName

            if ($null -ne $baselines) {
                # Filter baselines based on the control type
                $filteredBaselines = switch ($ControlType) {
                    "Exclusions" {
                        $baselines | Where-Object { $_.$($baselineControl.fieldControlName) -ne 'none' }
                    }
                    default {
                        $baselines  # Omissions and Annotations use all baselines
                    }
                }

                if ($null -ne $filteredBaselines) {
                    foreach ($baseline in $filteredBaselines) {
                        # Get the field list for this baseline
                        $fieldList = if ($baseline.PSObject.Properties.Name -contains $baselineControl.fieldControlName) {
                            $baseline.$($baselineControl.fieldControlName)
                        } else {
                            $baselineControl.defaultFields
                        }

                        # Get the output data hashtable dynamically
                        $outputData = $syncHash.$($baselineControl.dataControlOutput)

                        $card = New-FieldListCard `
                                    -CardName $baselineControl.CardName `
                                    -PolicyId $baseline.id `
                                    -ProductName $ProductName `
                                    -PolicyName $baseline.name `
                                    -PolicyDescription $baseline.rationale `
                                    -Criticality $baseline.criticality `
                                    -FieldList $fieldList `
                                    -OutputData $outputData `
                                    -ShowFieldType:$baselineControl.showFieldType `
                                    -ShowDescription:$baselineControl.showDescription `
                                    -FlipFieldValueAndPolicyId:$baselineControl.supportsAllProducts

                        if ($card) {
                            [void]$Container.Children.Add($card)
                        }
                    }
                } else {
                    # No applicable baselines
                    $noDataText = New-Object System.Windows.Controls.TextBlock
                    $noDataText.Text = $syncHash.UIConfigs.LocaleInfoMessages.NoPoliciesAvailable
                    $noDataText.Foreground = $syncHash.Window.FindResource("MutedTextBrush")
                    $noDataText.FontStyle = "Italic"
                    $noDataText.HorizontalAlignment = "Center"
                    $noDataText.Margin = "0,50,0,0"
                    [void]$Container.Children.Add($noDataText)
                }
            } else {
                # No baselines available for this product
                $noDataText = New-Object System.Windows.Controls.TextBlock
                $noDataText.Text = $syncHash.UIConfigs.LocaleInfoMessages.NoPoliciesAvailable
                $noDataText.Foreground = $syncHash.Window.FindResource("MutedTextBrush")
                $noDataText.FontStyle = "Italic"
                $noDataText.HorizontalAlignment = "Center"
                $noDataText.Margin = "0,50,0,0"
                [void]$Container.Children.Add($noDataText)
            }
        }


        #===========================================================================
        # Dynamic controls - CARDS
        #===========================================================================
        # Function to validate required fields

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

            Write-DebugOutput -Message ("Dynamic placeholders for validation: {0}" -f ($dynamicPlaceholders -join ', ')) -Source "Test-RequiredField" -Level "Verbose"

            foreach ($inputData in $validInputFields) {
                $FieldListDef = $syncHash.UIConfigs.inputTypes.$inputData
                if (-not $FieldListDef) { continue }

                foreach ($field in $FieldListDef.fields) {
                    # Skip if field is not required
                    if (-not $field.required) { continue }

                    $controlFieldName = ($policyId.replace('.', '_') + "_" + $CardName + "_" + $field.value)
                    $hasValue = $false

                    Write-DebugOutput -Message ("Checking required field: {0}(control: {1})" -f $field.name, $controlFieldName) -Source "Test-RequiredField" -Level "Verbose"

                    if ($field.type -eq "array") {
                        # For arrays, check if list container has any items
                        $listContainerName = ($controlFieldName + "_List")
                        $listContainer = Find-ControlByName -parent $detailsPanel -targetName $listContainerName

                        if ($listContainer -and $listContainer.Children.Count -gt 0) {
                            $hasValue = $true
                        }

                    } elseif ($field.type -eq "boolean") {
                        # Boolean fields always have a value (true or false)
                        $hasValue = $true

                    } elseif ($field.type -eq "dateString" -and $field.valueType -eq "yearmonthday") {
                        # Check DatePicker for date fields
                        $datePickerName = ($controlFieldName + "_DatePicker")
                        $datePicker = Find-ControlByName -parent $detailsPanel -targetName $datePickerName

                        if ($datePicker -and $datePicker.SelectedDate) {
                            $hasValue = $true
                        }

                    } else {
                        # For all other string-based fields, check TextBox
                        $stringFieldName = ($controlFieldName + "_TextBox")
                        $stringTextBox = Find-ControlByName -parent $detailsPanel -targetName $stringFieldName

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
                        Write-DebugOutput -Message ("Required field missing: {0}" -f $field.name) -Source "Test-RequiredField" -Level "Warning"
                    } else {
                        Write-DebugOutput -Message ("Required field has value: {0}" -f $field.name) -Source "Test-RequiredField" -Level "Verbose"
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
                Add-ControlEventHandler -Control $inputTextBox

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

                Add-ControlEventHandler -Control $addButton

                # add button Functionality - capture placeholder properly
                $addButton.Add_Click({
                    $inputBox = $this.Parent.Children[0]
                    $listPanel = $this.Parent.Parent.Children[1]

                    if (![string]::IsNullOrWhiteSpace($inputBox.Text) -and $inputBox.Text -ne $placeholderText) {
                        # Trim the input value
                        $trimmedValue = $inputBox.Text.Trim()

                        # Check if value already exists
                        if ($listContainer.Children.Children | Where-Object { $_.Text -contains $trimmedValue }) {
                            [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localePopupMessages.DuplicateEntry, $syncHash.UIConfigs.localeTitles.DuplicateEntry, "OK", "Warning")
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
                            [System.Windows.MessageBox]::Show($errorMessage, $syncHash.UIConfigs.localeTitles.ValidationError, "OK", "Warning")
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
                Add-ControlEventHandler -Control $booleanCheckBox

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
                        Add-ControlEventHandler -Control $datePicker

                        # Create a "Clear" button next to the DatePicker
                        $clearButton = New-Object System.Windows.Controls.Button
                        $clearButton.Content = "Clear"
                        $clearButton.Name = $fieldName + "_ClearDate"
                        $clearButton.Width = 50
                        $clearButton.Height = 28
                        $clearButton.Margin = "0,0,8,0"

                        # Add global event handlers to dynamically created clear button
                        Add-ControlEventHandler -Control $clearButton

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
                    Add-ControlEventHandler -Control $stringTextBox
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
                Add-ControlEventHandler -Control $graphGetButton

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
                        Write-DebugOutput -Message "No items selected or found from Graph query for $($GraphQueryData.Name)" -Source "Graph Button Click" -Level "Info"
                    }
                }
                catch {
                    Write-DebugOutput -Message "Error in Graph button click: $($_.Exception.Message)" -Source "Graph Button Click" -Level "Error"
                    [System.Windows.MessageBox]::Show(($syncHash.UIConfigs.localePopupMessages.GraphError -f $_.Exception.Message), $syncHash.UIConfigs.localeTitles.GraphError, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
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
                    Write-DebugOutput -Message ("Input data [{0}] not found in configuration" -f $inputData) -Source "New-FieldListCard" -Level "Warning"
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
            Add-ControlEventHandler -Control $checkbox

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

            Add-ControlEventHandler -Control $saveButton
            Add-ControlEventHandler -Control $removeButton

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

                    [System.Windows.MessageBox]::Show($errorMessage, $syncHash.UIConfigs.localeTitles.RequiredFieldsMissing, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
                    return # Exit save operation if validation fails
                }

                # Initialize output data structure
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
                            $listContainer = Find-ListContainer -parent $detailsPanel -targetName $listContainerName

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
                                Write-DebugOutput -Message ("List container not found or empty for: {0}" -f $listContainerName) -Source $this.Name -Level "Warning"
                            }

                        } elseif ($field.type -eq "boolean") {
                            # For boolean, look for the CheckBox
                            $booleanFieldName = ($controlFieldName + "_CheckBox")
                            $booleanCheckBox = Find-CheckBox -parent $detailsPanel -targetName $booleanFieldName

                            if ($booleanCheckBox) {
                                $value = [bool]$booleanCheckBox.IsChecked
                                # Use $field.value for data storage key (YAML output)
                                $fieldCardData[$field.value] = $value
                                Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.CollectedBooleanField -f $inputData, $field.value, $value) -Source $this.Name -Level "Info"
                            } else {
                                Write-DebugOutput -Message ("Boolean field not found for: {0}" -f $booleanFieldName) -Source $this.Name -Level "Warning"
                            }

                        } elseif ($field.type -match "string") {
                            # Check if this is a dateString with yearmonthday - look for DatePicker
                            if ($field.type -eq "dateString") {
                                $datePickerName = ($controlFieldName + "_DatePicker")
                                $datePicker = Find-DatePicker -parent $detailsPanel -targetName $datePickerName

                                if ($datePicker -and $datePicker.SelectedDate) {
                                    $value = $datePicker.SelectedDate.ToString($syncHash.UIConfigs.valueValidations.($Field.valueType).format)
                                    $fieldCardData[$field.value] = $value
                                    Write-DebugOutput -Message ($syncHash.UIConfigs.LocaleInfoMessages.CollectedStringField -f $inputData, $field.value, $value) -Source $this.Name -Level "Info"
                                }
                            } else {
                                $stringFieldName = ($controlFieldName + "_TextBox")
                                $stringTextBox = Find-TextBox -parent $detailsPanel -targetName $stringFieldName

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
                                    Write-DebugOutput -Message ("String textbox not found or empty for: {0}" -f $stringFieldName) -Source $this.Name -Level "Warning"
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
                    [System.Windows.MessageBox]::Show(($syncHash.UIConfigs.LocalePopupMessages.CardSavedSuccess -f $CardName, $ProductName, $policyId, ($savedinputTypes -join ', ')), $syncHash.UIConfigs.localeTitles.Success, "OK", "Information")

                    # Make remove button visible and header bold
                    $removeButton.Visibility = "Visible"
                    $policyHeader.FontWeight = "Bold"

                    # Collapse details panel and uncheck checkbox
                    $detailsPanel.Visibility = "Collapsed"
                    $checkbox.IsChecked = $false
                } else {
                    Write-DebugOutput -Message ("No entries found for {0} fields: {1}" -f $CardName.ToLower(), $inputData) -Source $this.Name -Level "Warning"
                    [System.Windows.MessageBox]::Show(($syncHash.UIConfigs.LocalePopupMessages.NoEntriesFound -f $CardName.ToLower()), $syncHash.UIConfigs.localeTitles.ValidationError, "OK", "Warning")
                }
            }.GetNewClosure())


            # Enhanced remove button click handler for multiple exclusionFields
            $removeButton.Add_Click({
                $policyIdWithUnderscores = $this.Name.Replace(("_" + $CardName + "_RemoveButton"), "")
                $policyId = $policyIdWithUnderscores.Replace("_", ".")

                $result = [System.Windows.MessageBox]::Show(($syncHash.UIConfigs.LocalePopupMessages.RemoveCardPolicyConfirmation -f $CardName.ToLower(), $policyId), $syncHash.UIConfigs.localeTitles.ConfirmRemove, "YesNo", "Question")
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

                    [System.Windows.MessageBox]::Show(($syncHash.UIConfigs.LocalePopupMessages.RemoveCardEntrySuccess -f $CardName, $policyId), $syncHash.UIConfigs.localeTitles.Success, "OK", "Information")

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

        #===========================================================================
        # GRAPH HELPER
        #===========================================================================
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
                        $syncHash.GraphStatusIndicator.Fill = [System.Windows.Media.Brushes]::LimeGreen
                        $syncHash.GraphStatusText.Text = "Graph Connected"
                        $syncHash.GraphStatusText.Foreground = [System.Windows.Media.Brushes]::DarkGreen
                        $syncHash.GraphStatusBorder.Background = [System.Windows.Media.Brushes]::LightGreen
                        $syncHash.GraphStatusBorder.ToolTip = "Microsoft Graph is connected and ready for data queries"

                        Write-DebugOutput -Message "Graph status indicator updated: Connected" -Source "Graph Status" -Level "Info"
                    } else {
                        # Disconnected state - Red indicator
                        $syncHash.GraphStatusIndicator.Fill = [System.Windows.Media.Brushes]::Red
                        $syncHash.GraphStatusText.Text = "Graph Disconnected"
                        $syncHash.GraphStatusText.Foreground = [System.Windows.Media.Brushes]::DarkRed
                        $syncHash.GraphStatusBorder.Background = [System.Windows.Media.Brushes]::LightPink
                        $syncHash.GraphStatusBorder.ToolTip = "Microsoft Graph is not connected - some features may be limited"

                        Write-DebugOutput -Message "Graph status indicator updated: Disconnected" -Source "Graph Status" -Level "Info"
                    }
                })
            } catch {
                Write-DebugOutput -Message "Error updating Graph status indicator: $($_.Exception.Message)" -Source "Graph Status" -Level "Error"
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
                    $result = [System.Windows.MessageBox]::Show(
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

                            [System.Windows.MessageBox]::Show(
                                "Successfully disconnected from Microsoft Graph.",
                                "Graph Disconnected",
                                [System.Windows.MessageBoxButton]::OK,
                                [System.Windows.MessageBoxImage]::Information
                            )
                        } catch {
                            Write-DebugOutput -Message "Error disconnecting from Graph: $($_.Exception.Message)" -Source "Graph Status" -Level "Error"
                            [System.Windows.MessageBox]::Show(
                                "Error disconnecting from Graph: $($_.Exception.Message)",
                                "Disconnect Error",
                                [System.Windows.MessageBoxButton]::OK,
                                [System.Windows.MessageBoxImage]::Error
                            )
                        }
                    }
                } else {
                    # Show connect information
                    [System.Windows.MessageBox]::Show(
                        "Microsoft Graph is not connected.`n`nTo connect Graph, restart the application with the -Online parameter or use Connect-MgGraph manually.",
                        "Graph Connection",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Information
                    )
                }
            })

            # Set initial status
            Update-GraphStatusIndicator -IsConnected $syncHash.GraphConnected

            Write-DebugOutput -Message "Graph status indicator initialized" -Source "Graph Status" -Level "Info"
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

            # Create runspace
            $runspace = [runspacefactory]::CreateRunspace()
            $runspace.Open()

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
                        #Write-DebugOutput -Message "Query configuration not found for: $QueryType" -Source $MyInvocation.MyCommand.Name -Level "Error"
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

                    #Write-DebugOutput -Message "Graph Query URI: $($queryParams.Uri)" -Source $MyInvocation.MyCommand.Name -Level "Information"

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
                    #Write-DebugOutput -Message "Error executing Graph query: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
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
                Write-DebugOutput -Message "Entity type '$entityType' not found in graphQueries configuration" -Source $MyInvocation.MyCommand.Name -Level "Error"
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
                    Write-DebugOutput -Message "Using configuration for graph entity type: $GraphEntityType" -Source $MyInvocation.MyCommand.Name -Level "Verbose"
                }else{
                    Write-DebugOutput -Message "Unsupported graph entity type: $GraphEntityType" -Source $MyInvocation.MyCommand.Name -Level "Error"
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
                Write-DebugOutput -Message "Starting async operation for graph query type: $($config.QueryType) with filter: $filterString" -Source $MyInvocation.MyCommand.Name -Level "Verbose"
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
                    Write-DebugOutput -Message "Graph query successful for entity type: $GraphEntityType, items found: $($result.Data.value.Count)" -Source $MyInvocation.MyCommand.Name -Level "Verbose"
                    $items = $result.Data.value
                    if (-not $items -or $items.Count -eq 0) {
                        [System.Windows.MessageBox]::Show($config.NoResultsMessage, $config.NoResultsTitle,
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
                    Write-DebugOutput -Message "Graph query failed for entity type: $GraphEntityType, error: $($result.Error)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                    [System.Windows.MessageBox]::Show($result.Message, $syncHash.UIConfigs.localeTitles.Error,
                                                    [System.Windows.MessageBoxButton]::OK,
                                                    [System.Windows.MessageBoxImage]::Error)
                    return $null
                }
            }
            catch {
                [System.Windows.MessageBox]::Show(("{0} {1}: {2}" -f $syncHash.UIConfigs.localeErrorMessages.WindowError,$GraphEntityType, $_.Exception.Message),
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
                Write-DebugOutput -Message "Showing $($GraphEntityType.ToLower()) selector with top: $Top" -Source $MyInvocation.MyCommand.Name -Level "Info"
            }Else {
                Write-DebugOutput -Message "Showing $($GraphEntityType.ToLower()) selector with search term: $SearchTerm, top: $Top" -Source $MyInvocation.MyCommand.Name -Level "Info"
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
                        Write-DebugOutput -Message "Column configuration for '$columnKey' not found in ColumnConfig." -Source $MyInvocation.MyCommand.Name -Level "Warning"
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
                        [System.Windows.MessageBox]::Show("Please select an item.", "No Selection",
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
                                Write-DebugOutput -Message "Selected item does not have property '$ReturnProperty': $($item | ConvertTo-Json -Compress)" -Source $MyInvocation.MyCommand.Name -Level "Warning"
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
                [System.Windows.MessageBox]::Show( ("{0} {1}: {2}" -f $syncHash.UIConfigs.localeErrorMessages.WindowError, $Title, $_.Exception.Message),
                                                $syncHash.UIConfigs.localeTitles.Error,
                                                [System.Windows.MessageBoxButton]::OK,
                                                [System.Windows.MessageBoxImage]::Error)
                return $null
            }
        }

        #===========================================================================
        # YAML Control Functions
        #===========================================================================
        Function Show-YamlImportProgress {
            <#
            .SYNOPSIS
            Shows a progress window during YAML import operations.
            .DESCRIPTION
            This Function creates a separate runspace with a XAML-based progress window for YAML import operations.
            It provides real-time feedback during the import process.
            #>
            param(
                [Parameter(Mandatory=$true)]
                [string]$YamlFilePath,
                [string]$WindowTitle = "Importing Configuration",
                [string]$InitialMessage = "Loading YAML configuration..."
            )

            # XAML for the progress window
            $xaml = @"
<Window x:Class="YamlImport.Progress"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="$WindowTitle"
    WindowStyle="None"
    WindowStartupLocation="CenterScreen"
    Height="200" Width="450"
    ResizeMode="NoResize"
    ShowInTaskbar="False"
    Topmost="True">
    <Window.Resources>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
        </Style>
        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="20"/>
            <Setter Property="Margin" Value="20,10,20,20"/>
            <Setter Property="Foreground" Value="#0078D4"/>
        </Style>
    </Window.Resources>
    <Grid Background="#313130">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Title/Icon Row -->
        <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Center" Margin="20,20,20,10">
            <TextBlock Text="&#x1F4E5;" FontSize="24" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <Label Content="$WindowTitle" FontSize="16" FontWeight="Bold" VerticalAlignment="Center"/>
        </StackPanel>

        <!-- Message Row -->
        <Label x:Name="lblMessage" Grid.Row="1" Content="$InitialMessage"
               HorizontalAlignment="Center" VerticalAlignment="Center"
               Margin="20,0,20,0"/>

        <!-- Progress Bar Row -->
        <ProgressBar x:Name="YamlImportProgressBar" Grid.Row="2"
                     IsIndeterminate="True" Margin="20,10,20,10"/>

        <!-- Status Row -->
        <Label x:Name="lblStatus" Grid.Row="3" Content="Please wait..."
               HorizontalAlignment="Center" Margin="20,0,20,10"
               FontSize="10" Opacity="0.8"/>
    </Grid>
</Window>
"@
            [string]$xaml = $xaml -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window' -replace 'Click=".*','/>'

            # Create the runspace for the progress window
            $progressRunspace = [runspacefactory]::CreateRunspace()
            $progressRunspace.ApartmentState = "STA"
            $progressRunspace.ThreadOptions = "ReuseThread"
            $progressRunspace.Open()

            # Share variables with the progress runspace
            $progressRunspace.SessionStateProxy.SetVariable("xaml", $xaml)
            $progressRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
            $progressRunspace.SessionStateProxy.SetVariable("YamlFilePath", $YamlFilePath)

            # Create PowerShell instance for progress window
            $progressPowerShell = [powershell]::Create()
            $progressPowerShell.Runspace = $progressRunspace

            # Script for the progress window
            $progressScript = {
                Add-Type -AssemblyName PresentationFramework
                Add-Type -AssemblyName PresentationCore
                Add-Type -AssemblyName WindowsBase

                try {
                    # Parse XAML
                    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
                    $progressWindow = [Windows.Markup.XamlReader]::Load($reader)
                    $reader.Close()

                    # Get controls
                    $lblMessage = $progressWindow.FindName("lblMessage")
                    $lblStatus = $progressWindow.FindName("lblStatus")
                    $progressBar = $progressWindow.FindName("YamlImportProgressBar")

                    # Create shared hashtable for communication
                    $progressSync = [hashtable]::Synchronized(@{
                        Window = $progressWindow
                        Message = $lblMessage
                        Status = $lblStatus
                        ProgressBar = $progressBar
                        ShouldClose = $false
                        Error = $null
                    })

                    # Store in main syncHash for communication
                    $syncHash.ProgressSync = $progressSync

                    # Update message Function

                    $updateMessage = {
                        <#
                        #https://github.com/PowerShell/PSScriptAnalyzer/issues/1472
                        #added variables to capture used parameters in the script block instead of:
                        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "message")]
                        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "status")]
                        #>
                        param($message, $status)
                        $msg = $message
                        $stat = $status
                        $progressSync.Window.Dispatcher.Invoke([Action]{
                            if ($msg) { $progressSync.Message.Content = $msg }
                            if ($stat) { $progressSync.Status.Content = $stat }
                        })
                    }

                    # Store update Function
                    $syncHash.UpdateProgressMessage = $updateMessage

                    # Show window and wait
                    $progressWindow.ShowDialog()

                } catch {
                    # Store error for main thread
                    if ($syncHash.ProgressSync) {
                        $syncHash.ProgressSync.Error = $_.Exception.Message
                    }
                }
            }

            # Start the progress window
            $progressPowerShell.AddScript($progressScript)
            $progressHandle = $progressPowerShell.BeginInvoke()

            # Wait for progress window to initialize
            $timeout = 0
            while (-not $syncHash.ProgressSync -and $timeout -lt 50) {
                Start-Sleep -Milliseconds 100
                $timeout++
            }

            if (-not $syncHash.ProgressSync) {
                Write-Error -Message "Failed to initialize progress window"
                return $null
            }

            # Return control objects
            return @{
                PowerShell = $progressPowerShell
                Handle = $progressHandle
                Runspace = $progressRunspace
                UpdateMessage = $syncHash.UpdateProgressMessage
                Close = {
                    try {
                        if ($syncHash.ProgressSync -and $syncHash.ProgressSync.Window) {
                            $syncHash.ProgressSync.Window.Dispatcher.Invoke([Action]{
                                $syncHash.ProgressSync.Window.Close()
                            })
                        }
                    } catch {
                        # Ignore close errors
                        Write-Error -Message "Error closing progress window: $($_.Exception.Message)"
                    }

                    # Cleanup
                    try {
                        if ($progressHandle -and $progressPowerShell) {
                            $progressPowerShell.EndInvoke($progressHandle)
                        }
                        if ($progressPowerShell) {
                            $progressPowerShell.Dispose()
                        }
                        if ($progressRunspace) {
                            $progressRunspace.Close()
                            $progressRunspace.Dispose()
                        }
                    } catch {
                        Write-DebugOutput -Message "Error during cleanup: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                    }

                    # Remove from syncHash
                    if ($syncHash.ProgressSync) {
                        $syncHash.Remove("ProgressSync")
                    }
                    if ($syncHash.UpdateProgressMessage) {
                        $syncHash.Remove("UpdateProgressMessage")
                    }
                }.GetNewClosure()
            }
        }

        Function Invoke-YamlImportWithProgress {
            <#
            .SYNOPSIS
            Imports YAML configuration with progress feedback.
            .DESCRIPTION
            This Function handles the complete YAML import process with a progress window showing real-time status updates.
            #>
            param(
                [Parameter(Mandatory=$true)]
                [string]$YamlFilePath,
                [string]$WindowTitle = "Importing Configuration"
            )

            $progress = $null
            try {
                # Show progress window
                Write-DebugOutput -Message "Starting YAML import with progress for: $YamlFilePath" -Source $MyInvocation.MyCommand.Name -Level "Info"
                $progress = Show-YamlImportProgress -YamlFilePath $YamlFilePath -WindowTitle $WindowTitle

                if (-not $progress) {
                    throw "Failed to create progress window"
                }

                # Small delay to ensure window is visible
                Start-Sleep -Milliseconds 300

                # Step 1: Load YAML file
                $progress.UpdateMessage.Invoke("Loading YAML file...", "Reading file content")
                Start-Sleep -Milliseconds 200
                $yamlContent = Get-Content -Path $YamlFilePath -Raw

                # Step 2: Parse YAML
                $progress.UpdateMessage.Invoke("Parsing YAML content...", "Converting to data structures")
                Start-Sleep -Milliseconds 200
                $yamlHash = $yamlContent | ConvertFrom-Yaml

                # Step 3: Clear existing data
                $progress.UpdateMessage.Invoke("Preparing for import...", "Clearing existing configuration")
                Start-Sleep -Milliseconds 200
                $syncHash.ExclusionData = [ordered]@{}
                $syncHash.OmissionData = [ordered]@{}
                $syncHash.AnnotationData = [ordered]@{}
                $syncHash.GeneralSettingsData = [ordered]@{}
                $syncHash.AdvancedSettingsData = [ordered]@{}

                # Step 4: Import data structures
                $progress.UpdateMessage.Invoke("Importing configuration data...", "Processing YAML sections")
                Start-Sleep -Milliseconds 300
                Import-YamlToDataStructures -Config $yamlHash

                # Step 5: Update UI
                $progress.UpdateMessage.Invoke("Updating user interface...", "Applying configuration to controls")
                Start-Sleep -Milliseconds 400

                # Step 6: Final processing
                $progress.UpdateMessage.Invoke("Finalizing import...", "Configuration applied successfully")
                Start-Sleep -Milliseconds 300

                Write-DebugOutput -Message "YAML import completed successfully" -Source $MyInvocation.MyCommand.Name -Level "Info"
                return $true

            } catch {
                Write-DebugOutput -Message "Error during YAML import: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                if ($progress -and $progress.UpdateMessage) {
                    $progress.UpdateMessage.Invoke("Import failed!", "Error: $($_.Exception.Message)")
                    Start-Sleep -Milliseconds 1500
                }
                throw
            } finally {
                # Always close progress window
                if ($progress -and $progress.Close) {
                    $progress.Close.Invoke()
                }
            }
        }

        # Function to import YAML data into core data structures (without UI updates)
        Function Import-YamlToDataStructures {
            <#
            .SYNOPSIS
            Imports YAML configuration data into internal data structures.
            .DESCRIPTION
            This Function parses YAML configuration data and populates the application's internal data structures without updating the UI.
            #>
            param($Config)

            try {
                # Initialize AdvancedSettings if not exists
                if (-not $syncHash.AdvancedSettingsData) {
                    $syncHash.AdvancedSettingsData = [ordered]@{}
                }

                # Get top-level keys (now always hashtable)
                $topLevelKeys = $Config.Keys

                #get all products from UIConfigs
                $productIds = $syncHash.UIConfigs.products | Select-Object -ExpandProperty id

                # Import General Settings that are not product-specific
                $generalSettingsFields = $topLevelKeys | Where-Object {$_ -notin $productIds -and $_ -notin @("OmitPolicy", "AnnotatePolicy")}

                # Separate general settings from advanced settings
                $advancedSettingsList = @()
                if ($syncHash.UIConfigs.advancedSections) {
                    # Get all advanced settings field names from all sections
                    foreach ($sectionKey in $syncHash.UIConfigs.advancedSections.PSObject.Properties.Name) {
                        $sectionConfig = $syncHash.UIConfigs.advancedSections.$sectionKey
                        foreach ($fieldControlName in $sectionConfig.fields) {
                            $settingName = $fieldControlName -replace '_TextBox$|_CheckBox$', ''
                            $advancedSettingsList += $settingName
                        }
                    }
                }

                foreach ($field in $generalSettingsFields) {
                    # Special handling for ProductNames to expand '*' wildcard
                    if ($field -eq "ProductNames" -and $Config[$field] -contains "*") {
                        # Expand '*' to all available products
                        $syncHash.GeneralSettingsData[$field] = $productIds
                        Write-DebugOutput -Message "Imported general setting (expanded wildcard): $field = $($productIds -join ', ')" -Source $MyInvocation.MyCommand.Name -Level "Info"
                    }
                    # Check if this field belongs to advanced settings
                    elseif ($field -in $advancedSettingsList) {
                        $syncHash.AdvancedSettingsData[$field] = $Config[$field]
                        Write-DebugOutput -Message "Imported advanced setting: $field = $($Config[$field])" -Source $MyInvocation.MyCommand.Name -Level "Info"
                    }
                    else {
                        $syncHash.GeneralSettingsData[$field] = $Config[$field]
                        Write-DebugOutput -Message "Imported general setting: $field = $($Config[$field])" -Source $MyInvocation.MyCommand.Name -Level "Info"
                    }
                }

                # Process baseline controls using supportsAllProducts property
                foreach ($baselineControl in $syncHash.UIConfigs.baselineControls) {
                    $OutputData = $syncHash.($baselineControl.dataControlOutput)

                    if ($baselineControl.supportsAllProducts) {
                        # Handle annotations and omissions (supports all products)
                        # YAML structure: yamlValue -> PolicyId -> FieldData
                        # Save structure: Product -> yamlValue -> PolicyId -> FieldData (MUST MATCH SAVE LOGIC!)

                        if ($topLevelKeys -contains $baselineControl.yamlValue) {
                            $controlData = $Config[$baselineControl.yamlValue]

                            foreach ($policyId in $controlData.Keys) {
                                $policyFieldData = $controlData[$policyId]

                                # Find which product this policy belongs to
                                $productName = $null
                                foreach ($product in $syncHash.UIConfigs.products) {
                                    $baseline = $syncHash.Baselines.($product.id) | Where-Object { $_.id -eq $policyId }
                                    if ($baseline) {
                                        $productName = $product.id
                                        break
                                    }
                                }

                                if ($productName) {
                                    # Initialize structure to match save logic: Product -> yamlValue -> PolicyId -> FieldData
                                    if (-not $OutputData[$productName]) {
                                        $OutputData[$productName] = [ordered]@{}
                                    }
                                    if (-not $OutputData[$productName][$baselineControl.yamlValue]) {
                                        $OutputData[$productName][$baselineControl.yamlValue] = [ordered]@{}
                                    }
                                    if (-not $OutputData[$productName][$baselineControl.yamlValue][$policyId]) {
                                        $OutputData[$productName][$baselineControl.yamlValue][$policyId] = [ordered]@{}
                                    }

                                    # Store the field data under the policy ID
                                    foreach ($fieldKey in $policyFieldData.Keys) {
                                        $OutputData[$productName][$baselineControl.yamlValue][$policyId][$fieldKey] = $policyFieldData[$fieldKey]
                                    }

                                    Write-DebugOutput -Message "Imported $($baselineControl.controlType) for [$productName][$($baselineControl.yamlValue)][$policyId]: $($policyFieldData | ConvertTo-Json -Compress)" -Source $MyInvocation.MyCommand.Name -Level "Info"
                                } else {
                                    Write-DebugOutput -Message "Could not find product for policy: $policyId" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                                }
                            }
                        } else {
                            Write-DebugOutput -Message "No $($baselineControl.yamlValue) section found in YAML" -Source $MyInvocation.MyCommand.Name -Level "Info"
                        }

                    } else {
                        # Handle exclusions (product-specific)
                        # YAML structure: Product -> PolicyId -> ExclusionType -> FieldData
                        # Save structure: Product -> PolicyId -> ExclusionType -> FieldData (SAME as YAML)

                        foreach ($productName in $productIds) {
                            if ($topLevelKeys -contains $productName) {
                                $productData = $Config[$productName]

                                foreach ($policyId in $productData.Keys) {
                                    $policyData = $productData[$policyId]

                                    # Verify this policy exists in the baseline for this product
                                    $baseline = $syncHash.Baselines.$productName | Where-Object { $_.id -eq $policyId }
                                    if ($baseline -and $baseline.exclusionField -ne "none") {
                                        # Initialize product and policy levels if they don't exist
                                        if (-not $OutputData[$productName]) {
                                            $OutputData[$productName] = [ordered]@{}
                                        }
                                        if (-not $OutputData[$productName][$policyId]) {
                                            $OutputData[$productName][$policyId] = [ordered]@{}
                                        }

                                        # Copy all the exclusion data for this policy
                                        foreach ($exclusionType in $policyData.Keys) {
                                            $OutputData[$productName][$policyId][$exclusionType] = $policyData[$exclusionType]
                                            Write-DebugOutput -Message "Imported $($baselineControl.controlType) for [$productName][$policyId][$exclusionType]: $($policyData[$exclusionType] | ConvertTo-Json -Compress)" -Source $MyInvocation.MyCommand.Name -Level "Info"
                                        }
                                    } else {
                                        Write-DebugOutput -Message "Policy $policyId not found or doesn't support exclusions for product $productName" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                                    }
                                }
                            } else {
                                Write-DebugOutput -Message "No $productName section found in YAML" -Source $MyInvocation.MyCommand.Name -Level "Info"
                            }
                        }
                    }
                }

                Write-DebugOutput -Message "Successfully imported YAML data to data structures" -Source $MyInvocation.MyCommand.Name -Level "Info"
                # Update UI controls to reflect imported data
                Update-AllUIFromData
                Write-DebugOutput -Message "UI controls updated from imported data" -Source $MyInvocation.MyCommand.Name -Level "Info"

            }
            catch {
                Write-DebugOutput -Message "Error importing data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                throw
            }
        }

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
                return "`n$(' ' * ($IndentLevel * 2))$FieldName`: `"$escapedValue`""
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

            $yamlPreview = @()
            $yamlPreview += '# ScubaGear Configuration File'
            $yamlPreview += "`n# Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            $yamlPreview += "`n`n# Organization Configuration"

            # Process main settings from GeneralSettings data structure instead of UI controls
            if ($syncHash.GeneralSettingsData -and $syncHash.GeneralSettingsData.Count -gt 0) {
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

        #===========================================================================
        # RESET: NEW SESSION
        #===========================================================================
        Function Clear-FieldValue {
            <#
            .SYNOPSIS
            Clears all field values and resets the UI to default state.
            .DESCRIPTION
            This Function resets all configuration data structures and UI controls to their initial empty state for starting a new session.
            #>

            # Clear core data structures
            $syncHash.ExclusionData = [ordered]@{}
            $syncHash.OmissionData = [ordered]@{}
            $syncHash.AnnotationData = [ordered]@{}
            $syncHash.GeneralSettingsData = [ordered]@{}
            $syncHash.AdvancedSettingsData = [ordered]@{}
            $syncHash.GlobalSettingsData = [ordered]@{}

            # Dynamically reset all controls using configuration
            $syncHash.GetEnumerator() | ForEach-Object {
                $controlName = $_.Key
                $control = $_.Value

                if ($control -is [System.Windows.Controls.TextBox]) {
                    # First check if there's a placeholder value
                    if ($syncHash.UIConfigs.localePlaceholder.$controlName) {
                        # Reset to placeholder value with placeholder styling
                        $control.Text = $syncHash.UIConfigs.localePlaceholder.$controlName
                        $control.Foreground = [System.Windows.Media.Brushes]::Gray
                        $control.FontStyle = [System.Windows.FontStyles]::Italic
                        $control.BorderBrush = [System.Windows.Media.Brushes]::Gray
                        $control.BorderThickness = "1"
                    }
                    # Then check if there's a default value in defaultSettings
                    elseif ($syncHash.UIConfigs.defaultAdvancedSettings.$controlName) {
                        $control.Text = $syncHash.UIConfigs.defaultAdvancedSettings.$controlName
                        $control.Foreground = [System.Windows.Media.Brushes]::Black
                        $control.FontStyle = [System.Windows.FontStyles]::Normal
                        $control.BorderBrush = [System.Windows.Media.Brushes]::Gray
                        $control.BorderThickness = "1"
                    }
                    # Fallback for special cases not in config
                    else {
                        $control.Text = ""
                        $control.Foreground = [System.Windows.Media.Brushes]::Black
                        $control.FontStyle = [System.Windows.FontStyles]::Normal
                        $control.BorderBrush = [System.Windows.Media.Brushes]::Gray
                        $control.BorderThickness = "1"
                    }
                }
                elseif ($control -is [System.Windows.Controls.CheckBox]) {
                    # Check if there's a default value in defaultSettings
                    if ($syncHash.UIConfigs.defaultAdvancedSettings.PSObject.Properties.Name -contains $controlName) {
                        $control.IsChecked = $syncHash.UIConfigs.defaultAdvancedSettings.$controlName
                    }
                    # Fallback for controls not in config
                    else {
                        # Don't reset product checkboxes here - handle them separately
                        if (-not $controlName.EndsWith('ProductCheckBox')) {
                            $control.IsChecked = $false
                        }
                    }
                }
                Write-DebugOutput -Message "Cleared value for: $controlName" -Source $MyInvocation.MyCommand.Name -Level "Verbose"
            }

            # Reset specific UI elements that need special handling

            # Uncheck all product checkboxes
            $allProductCheckboxes = $syncHash.ProductsGrid.Children | Where-Object {
                $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "*ProductCheckBox"
            }
            foreach ($checkbox in $allProductCheckboxes) {
                $checkbox.IsChecked = $false
            }

            # Reset M365 Environment to default
            $syncHash.M365Environment_ComboBox.SelectedIndex = 0

            # Reset Advanced Tab toggles (these control visibility, not data)
            $toggleControls = $syncHash.GetEnumerator() | Where-Object { $_.Name -like '*_Toggle' }
            foreach ($toggleName in $toggleControls) {
                if ($toggleName.Value -is [System.Windows.Controls.CheckBox]) {
                    $syncHash.$toggleName.IsChecked = $false
                    $contentName = $toggleName.Replace('_Toggle', '_Content')
                    if ($syncHash.$contentName) {
                        $syncHash.$contentName.Visibility = [System.Windows.Visibility]::Collapsed
                    }
                }
            }

            # Clear global settings UI controls
            if ($syncHash.UIConfigs.globalSettings -and $syncHash.UIConfigs.globalSettings.fields) {
                foreach ($fieldName in $syncHash.UIConfigs.globalSettings.fields) {
                    $inputType = $syncHash.UIConfigs.inputTypes.$fieldName
                    if ($inputType) {
                        foreach ($field in $inputType.fields) {
                            switch ($field.type) {
                                "boolean" {
                                    $checkboxName = "$($field.value)_GlobalCheckBox"
                                    $checkbox = $syncHash[$checkboxName]
                                    if ($checkbox) {
                                        $checkbox.IsChecked = $false
                                    }
                                }
                                "array" {
                                    $listName = "$($field.value)_GlobalList"
                                    $listContainer = $syncHash[$listName]
                                    if ($listContainer) {
                                        $listContainer.Children.Clear()
                                    }
                                    $textBoxName = "$($field.value)_GlobalTextBox"
                                    $textBox = $syncHash[$textBoxName]
                                    if ($textBox) {
                                        # Reset to placeholder
                                        if ($field.valueType -eq "ipAddress") {
                                            $placeholderText = "Enter IP address (e.g., 8.8.8.8)"
                                            $textBox.Text = $placeholderText
                                            $textBox.Foreground = [System.Windows.Media.Brushes]::Gray
                                            $textBox.FontStyle = [System.Windows.FontStyles]::Italic
                                        } else {
                                            $textBox.Clear()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }#end Function : Clear-FieldValue

        #===========================================================================
        # SAVE: COLLECT SETTINGS FROM UI CONTROLS
        #===========================================================================
        # Function to collect general settings from UI controls
        Function Save-GeneralSettingsFromInput {
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
                        Write-DebugOutput -Message "Skipping advanced setting: $placeholderKey" -Source $MyInvocation.MyCommand.Name -Level "Debug"
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
                                If($syncHash.UIConfigs.DebugMode){Write-DebugOutput -Message "Collected General setting: $placeholderKey = $($syncHash.GeneralSettingsData[$settingName])" -Source $MyInvocation.MyCommand.Name -Level "Debug"}
                            }
                        }
                    }
                    catch {
                        Write-DebugOutput -Message "Error processing placeholder key '$placeholderKey': $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Warning"
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
                    If($syncHash.UIConfigs.DebugMode){Write-DebugOutput -Message "Collected M365Environment: $selectedEnv" -Source $MyInvocation.MyCommand.Name -Level "Debug"}
                }
                catch {
                    Write-DebugOutput -Message "Error processing M365Environment: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                }
            }

        } #end Function : Save-GeneralSettingsFromInput

        Function Save-AdvancedSettingsFromInput {
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
                                If($syncHash.UIConfigs.DebugMode){Write-DebugOutput -Message "Collected Advanced setting: $settingName = $($syncHash.AdvancedSettingsData[$settingName])" -Source $MyInvocation.MyCommand.Name -Level "Debug"}
                            }
                        }
                    }
                    catch {
                        Write-DebugOutput -Message "Error processing advanced section '$toggleName': $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                    }
                }
            }

        } #end Function : Save-AdvancedSettingsFromInput

        #===========================================================================
        # GLOBAL SETTINGS Functions
        #===========================================================================
        Function New-GlobalSettingsControls {
            <#
            .SYNOPSIS
            Creates UI controls for global settings using New-FieldListCard with custom save handling.
            .DESCRIPTION
            This Function creates global settings using the working New-FieldListCard but redirects saves to the flat GlobalSettingsData structure.
            #>

            if (-not $syncHash.UIConfigs.globalSettings -or -not $syncHash.UIConfigs.globalSettings.fields) {
                Write-DebugOutput -Message "No global settings fields defined in configuration" -Source $MyInvocation.MyCommand.Name -Level "Info"
                return
            }

            # Clear existing controls
            $syncHash.GlobalSettingsContainer.Children.Clear()

            # Initialize global settings data structure if not exists
            if (-not $syncHash.GlobalSettingsData) {
                $syncHash.GlobalSettingsData = @{}
            }

            Write-DebugOutput -Message "Creating global settings controls for $($syncHash.UIConfigs.globalSettings.fields.Count) fields" -Source $MyInvocation.MyCommand.Name -Level "Info"

            foreach ($fieldName in $syncHash.UIConfigs.globalSettings.fields) {
                $inputType = $syncHash.UIConfigs.inputTypes.$fieldName

                if (-not $inputType) {
                    Write-DebugOutput -Message "Input type not found for global settings field: $fieldName" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                    continue
                }

                Write-DebugOutput -Message "Creating field list card for global settings field: $fieldName" -Source $MyInvocation.MyCommand.Name -Level "Info"

                # Create a temporary data structure that New-FieldListCard can use
                if (-not $syncHash.TempGlobalData) {
                    $syncHash.TempGlobalData = @{}
                }

                # Use a fake policy ID for global settings
                $globalPolicyId = "GlobalSettings.$fieldName"

                $card = New-FieldListCard `
                    -CardName "GlobalSettings" `
                    -PolicyId $globalPolicyId `
                    -ProductName "Global" `
                    -PolicyName $inputType.name `
                    -PolicyDescription $inputType.description `
                    -Criticality "N/A" `
                    -FieldList $fieldName `
                    -OutputData $syncHash.TempGlobalData `
                    -ShowFieldType:$false `
                    -ShowDescription:$true

                if ($card) {
                    $syncHash.GlobalSettingsContainer.Children.Add($card)
                    Write-DebugOutput -Message "Successfully created card for global setting: $fieldName" -Source $MyInvocation.MyCommand.Name -Level "Info"
                } else {
                    Write-DebugOutput -Message "Failed to create card for global setting: $fieldName" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                }
            }

            # Now add auto-save Functionality by watching the temp data structure
            Add-GlobalSettingsAutoSave

            Write-DebugOutput -Message "Global settings controls created successfully" -Source $MyInvocation.MyCommand.Name -Level "Info"
        }

        Function Add-GlobalSettingsAutoSave {
            <#
            .SYNOPSIS
            Adds auto-save Functionality to monitor global settings changes and copy to the main data structure.
            #>

            # Set up a timer to periodically check for changes and auto-save
            if (-not $syncHash.GlobalSettingsTimer) {
                $syncHash.GlobalSettingsTimer = New-Object System.Windows.Threading.DispatcherTimer
                $syncHash.GlobalSettingsTimer.Interval = [TimeSpan]::FromMilliseconds(500)

                $syncHash.GlobalSettingsTimer.Add_Tick({
                    try {
                        if ($syncHash.TempGlobalData -and $syncHash.TempGlobalData["Global"]) {
                            foreach ($policyId in $syncHash.TempGlobalData["Global"].Keys) {
                                if ($policyId -like "GlobalSettings.*") {
                                    #$fieldName = $policyId -replace "^GlobalSettings\.", ""
                                    $policyData = $syncHash.TempGlobalData["Global"][$policyId]

                                    # Extract the actual field values
                                    foreach ($key in $policyData.Keys) {
                                        if ($policyData[$key] -is [hashtable]) {
                                            # Handle nested structure (like input types with multiple fields)
                                            foreach ($innerKey in $policyData[$key].Keys) {
                                                $value = $policyData[$key][$innerKey]
                                                if ($null -ne $value) {
                                                    $syncHash.GlobalSettingsData[$innerKey] = $value
                                                }
                                            }
                                        } else {
                                            # Handle direct values
                                            $value = $policyData[$key]
                                            if ($null -ne $value) {
                                                $syncHash.GlobalSettingsData[$key] = $value
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        Write-DebugOutput -Message "Error in global settings auto-save: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                    }
                })

                $syncHash.GlobalSettingsTimer.Start()
                Write-DebugOutput -Message "Global settings auto-save timer started" -Source $MyInvocation.MyCommand.Name -Level "Info"
            }
        }


        Function Save-GlobalSettingsFromInput {
            <#
            .SYNOPSIS
            Saves global settings from UI controls to data structures.
            .DESCRIPTION
            This Function collects values from global settings UI controls and stores them for YAML export.
            #>

            if (-not $syncHash.UIConfigs.globalSettings -or -not $syncHash.UIConfigs.globalSettings.fields) {
                return
            }

            Write-DebugOutput -Message "Saving global settings from UI input" -Source $MyInvocation.MyCommand.Name -Level "Info"

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
                                Write-DebugOutput -Message "Global setting $($field.value): $($syncHash.GlobalSettingsData[$field.value])" -Source $MyInvocation.MyCommand.Name -Level "Info"
                            }
                        }
                        "array" {
                            # Array data is already managed in the add/remove event handlers
                            Write-DebugOutput -Message "Global setting $($field.value): $($syncHash.GlobalSettingsData[$field.value] -join ', ')" -Source $MyInvocation.MyCommand.Name -Level "Info"
                        }
                    }
                }
            }
        }

        #===========================================================================
        # SCUBA RUN Controls
        #===========================================================================

        Function New-ScubaRunParameterControls {
            <#
            .SYNOPSIS
            Dynamically creates UI controls for ScubaRun parameters based on configuration.
            #>

            if (-not $syncHash.UIConfigs.ScubaRunConfig.powershell.parameters) {
                Write-DebugOutput -Message "No ScubaRun parameters defined in configuration" -Source $MyInvocation.MyCommand.Name -Level "Info"
                return
            }

            # Clear existing dynamic controls
            $syncHash.ScubaRunParametersContainer.Children.Clear()

            $scubaConfig = $syncHash.UIConfigs.ScubaRunConfig
            $parameters = $scubaConfig.powershell.parameters

            Write-DebugOutput -Message "Creating dynamic ScubaRun parameter controls" -Source $MyInvocation.MyCommand.Name -Level "Info"

            foreach ($parameterName in $parameters.PSObject.Properties.Name) {
                $paramConfig = $parameters.$parameterName

                # Skip hidden parameters (they won't show in UI but will be used in commands)
                if ($paramConfig.hidden -eq $true) {
                    Write-DebugOutput -Message "Skipping hidden parameter: $parameterName" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    continue
                }

                Write-DebugOutput -Message "Creating control for parameter: $parameterName" -Source $MyInvocation.MyCommand.Name -Level "Info"

                # Create container for this parameter
                $paramContainer = New-Object System.Windows.Controls.StackPanel
                $paramContainer.Margin = "0,0,0,8"

                # Create the appropriate control based on parameter type
                switch ($paramConfig.type) {
                    "boolean" {
                        $control = New-Object System.Windows.Controls.CheckBox
                        $control.Content = $paramConfig.name
                        $control.IsChecked = $paramConfig.defaultValue
                        $control.IsEnabled = -not $paramConfig.readOnly
                        $control.ToolTip = $paramConfig.description

                        # Store control name for later reference
                        $controlName = $parameterName.Replace("ScubaRun", "") + "_CheckBox"
                        $control.Name = $controlName
                        $syncHash.$controlName = $control

                        Write-DebugOutput -Message "Created CheckBox: $controlName" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    }
                    "string" {
                        # Create label for the parameter
                        $label = New-Object System.Windows.Controls.TextBlock
                        $label.Text = $paramConfig.name
                        $label.FontWeight = "SemiBold"
                        $label.Margin = "0,0,0,4"
                        [void]$paramContainer.Children.Add($label)

                        $control = New-Object System.Windows.Controls.TextBox
                        $control.Text = $paramConfig.defaultValue
                        $control.IsReadOnly = $paramConfig.readOnly
                        $control.ToolTip = $paramConfig.description
                        $control.Height = 36
                        $control.Padding = "8,6"
                        $control.BorderBrush = $syncHash.Window.FindResource("BorderBrush")
                        $control.Background = if ($paramConfig.readOnly) { "#F5F5F5" } else { "#FFFFFF" }
                        $control.Foreground = if ($paramConfig.readOnly) { $syncHash.Window.FindResource("PrimaryBrush") } else { $syncHash.Window.FindResource("TextBrush") }

                        # Store control name for later reference
                        $controlName = $parameterName.Replace("ScubaRun", "") + "_TextBox"
                        $control.Name = $controlName
                        $syncHash.$controlName = $control

                        Write-DebugOutput -Message "Created TextBox: $controlName" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    }
                    "dropdown" {
                        # Create label for the parameter
                        $label = New-Object System.Windows.Controls.TextBlock
                        $label.Text = $paramConfig.name
                        $label.FontWeight = "SemiBold"
                        $label.Margin = "0,0,0,4"
                        [void]$paramContainer.Children.Add($label)

                        #get length of items to determine width
                        $maxItemWidth = ($paramConfig.items | Measure-Object -Property Length -Maximum).Maximum

                        $control = New-Object System.Windows.Controls.ComboBox
                        $control.ItemsSource = $paramConfig.items
                        $control.SelectedItem = $paramConfig.defaultValue
                        $control.IsEnabled = -not $paramConfig.readOnly
                        $control.ToolTip = $paramConfig.description
                        $control.Height = 36
                        $control.MaxWidth = $maxItemWidth + 100
                        $control.HorizontalAlignment = "Left"
                        $control.Padding = "8,6"
                        $control.BorderBrush = $syncHash.Window.FindResource("BorderBrush")
                        $control.Background = if ($paramConfig.readOnly) { "#F5F5F5" } else { "#FFFFFF" }
                        $control.Foreground = if ($paramConfig.readOnly) { $syncHash.Window.FindResource("PrimaryBrush") } else { $syncHash.Window.FindResource("TextBrush") }

                        # Store control name for later reference
                        $controlName = $parameterName.Replace("ScubaRun", "") + "_ComboBox"
                        $control.Name = $controlName
                        $syncHash.$controlName = $control

                        Write-DebugOutput -Message "Created ComboBox: $controlName" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    }
                    default {
                        Write-DebugOutput -Message "Unknown parameter type: $($paramConfig.type) for $parameterName" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                        continue
                    }
                }

                # Add control to container
                [void]$paramContainer.Children.Add($control)

                # Add the parameter container to the main container
                [void]$syncHash.ScubaRunParametersContainer.Children.Add($paramContainer)
            }

            Write-DebugOutput -Message "Dynamic ScubaRun parameter controls created successfully" -Source $MyInvocation.MyCommand.Name -Level "Info"
        }

        Function Initialize-ScubaRunTab {
            <#
            .SYNOPSIS
            Initializes the Scuba Run tab with event handlers and default values.
            #>

            # Create dynamic parameter controls
            New-ScubaRunParameterControls

            # Enable text wrapping for the output textbox to handle long lines
            if ($syncHash.ScubaRunOutput_TextBox) {
                $syncHash.ScubaRunOutput_TextBox.TextWrapping = "Wrap"
                $syncHash.ScubaRunOutput_TextBox.AcceptsReturn = $true
                $syncHash.ScubaRunOutput_TextBox.VerticalScrollBarVisibility = "Auto"
                $syncHash.ScubaRunOutput_TextBox.HorizontalScrollBarVisibility = "Auto"
            }

            # Add event handlers - CORRECTED BUTTON NAME
            $syncHash.ScubaRunStart_Button.Add_Click({
                Start-ScubaGearExecution
            })

            $syncHash.ScubaRunStop_Button.Add_Click({
                Stop-ScubaGearExecution
            })

            $syncHash.ScubaRunClearOutput_Button.Add_Click({
                $syncHash.ScubaRunOutput_TextBox.Clear()
                $syncHash.ScubaRunOutput_TextBox.AppendText("Output cleared...`r`n")
            })

            $syncHash.ScubaRunCopyOutput_Button.Add_Click({
                try {
                    [System.Windows.Clipboard]::SetText($syncHash.ScubaRunOutput_TextBox.Text)
                    Update-ScubaRunStatus "Output copied to clipboard" "Info"
                } catch {
                    Update-ScubaRunStatus "Failed to copy output to clipboard" "Error"
                }
            })

            # Initialize button states and show initial status
            $syncHash.JustCompletedExecution = $false  # Ensure flag is clear on initialization
            Reset-ScubaRunUI

            Write-DebugOutput -Message "ScubaRun tab initialized with correct button event handlers" -Source $MyInvocation.MyCommand.Name -Level "Info"
        }

        Function Update-ScubaRunStatus {
            <#
            .SYNOPSIS
            Updates the status text and output log.
            #>
            param(
                [string]$Message,
                [ValidateSet("Info", "Warning", "Error", "Success")]
                [string]$Level = "Info"
            )

            $timestamp = Get-Date -Format "HH:mm:ss"

            # Process long messages for better readability
            $processedMessage = $Message
            if ($Message.Length -gt 120 -and $Message -match "WARNING:") {
                # Split long warning messages at logical points
                $processedMessage = $Message -replace '\s{3,}', "`r`n    " # Replace multiple spaces with newlines and indentation
                $processedMessage = $processedMessage -replace 'WARNING:\s+', "WARNING:`r`n    " # Put WARNING on its own line
            }

            $logEntry = "[$timestamp] $processedMessage"

            # Update status text
            $syncHash.ScubaRunStatus_TextBlock.Text = $Message


            # Set color based on level
            switch ($Level) {
                "Info" { $syncHash.ScubaRunStatus_TextBlock.Foreground = $syncHash.Window.FindResource("PrimaryBrush") }
                "Warning" { $syncHash.ScubaRunStatus_TextBlock.Foreground = [System.Windows.Media.Brushes]::Orange }
                "Error" { $syncHash.ScubaRunStatus_TextBlock.Foreground = [System.Windows.Media.Brushes]::Red }
                "Success" { $syncHash.ScubaRunStatus_TextBlock.Foreground = [System.Windows.Media.Brushes]::Green }
            }

            # Add to output log
            $syncHash.ScubaRunOutput_TextBox.AppendText("$logEntry`r`n")
            $syncHash.ScubaRunOutput_TextBox.ScrollToEnd()

            Write-DebugOutput -Message $Message -Source $MyInvocation.MyCommand.Name -Level $Level
        }

        Function Test-ScubaRunReadiness {
            <#
            .SYNOPSIS
            Checks if ScubaGear can be run (valid YAML generated).
            #>

            # Check if we have valid configuration data
            $hasValidConfig = $false

            # Check if products are selected
            if ($syncHash.GeneralSettingsData.ProductNames -and $syncHash.GeneralSettingsData.ProductNames.Count -gt 0) {
                $hasValidConfig = $true
            }

            # Check if Organization is set (required)
            if ([string]::IsNullOrWhiteSpace($syncHash.GeneralSettingsData.Organization)) {
                $hasValidConfig = $false
            }

            # Enable/disable run button
            $syncHash.ScubaRunStart_Button.IsEnabled = $hasValidConfig

            # Only update status if we're not preserving a completion message
            if (-not $syncHash.JustCompletedExecution) {
                if ($hasValidConfig) {
                    Update-ScubaRunStatus "Ready to run ScubaGear" "Success"
                } else {
                    Update-ScubaRunStatus "Configuration incomplete - check Main tab" "Warning"
                }
            }

            return $hasValidConfig
        }

        Function Start-ScubaGearExecution {
            <#
            .SYNOPSIS
            Starts ScubaGear execution in a background job.
            #>

            try {
                # Test readiness
                if (-not (Test-ScubaRunReadiness)) {
                    Update-ScubaRunStatus "Cannot run - configuration is incomplete" "Error"
                    return
                }

                # Generate temporary YAML file
                $tempConfigPath = Export-TempYamlConfiguration
                if (-not $tempConfigPath) {
                    Update-ScubaRunStatus "Failed to generate temporary configuration" "Error"
                    return
                }

                # Update UI state
                $syncHash.ScubaRunStart_Button.IsEnabled = $false
                $syncHash.ScubaRunStop_Button.IsEnabled = $true
                $syncHash.ScubaRunStart_Button.Visibility = "Collapsed"
                $syncHash.ScubaRunStop_Button.Visibility = "Visible"

                Update-ScubaRunStatus "Starting ScubaGear execution..." "Info"

                # Build PowerShell command
                $command = Build-ScubaGearCommand -ConfigFilePath $tempConfigPath

                # Debug: Show commands in output
                $syncHash.ScubaRunOutput_TextBox.AppendText("=== SCUBAGEAR EXECUTION STARTING ===`r`n")
                $syncHash.ScubaRunOutput_TextBox.AppendText("Configuration file: $tempConfigPath`r`n")
                $syncHash.ScubaRunOutput_TextBox.AppendText("Commands to execute:`r`n")
                foreach ($cmd in $command) {
                    $syncHash.ScubaRunOutput_TextBox.AppendText("  $cmd`r`n")
                }
                $syncHash.ScubaRunOutput_TextBox.AppendText("=== EXECUTION OUTPUT ===`r`n")
                $syncHash.ScubaRunOutput_TextBox.ScrollToEnd()

                # Start background job
                Start-ScubaGearJob -Command $command

            }
            catch {
                Update-ScubaRunStatus "Error starting ScubaGear: $($_.Exception.Message)" "Error"
                # Reset UI state
                Reset-ScubaRunUI
            }
        }

        Function Export-TempYamlConfiguration {
            <#
            .SYNOPSIS
            Exports current configuration to a temporary YAML file.
            #>

            try {
                # Generate YAML content (reuse existing preview function)
                New-YamlPreview -NoRedirect

                # Get the generated YAML content from the UI
                $yamlContent = $syncHash.YamlPreview_TextBox.Text

                if ([string]::IsNullOrWhiteSpace($yamlContent)) {
                    throw "No YAML content was generated. Please ensure all required fields are filled."
                }

                # Create temp directory if it doesn't exist
                $tempDir = Join-Path $env:TEMP "ScubaConfigRun"
                if (-not (Test-Path $tempDir)) {
                    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
                }

                # Create temp file
                $tempFileName = "ScubaGearConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').yaml"
                $tempFilePath = Join-Path $tempDir $tempFileName

                # Write YAML content
                [System.IO.File]::WriteAllText($tempFilePath, $yamlContent, [System.Text.Encoding]::UTF8)

                Update-ScubaRunStatus "Configuration exported to: $tempFilePath" "Info"
                return $tempFilePath
            }
            catch {
                Update-ScubaRunStatus "Failed to export configuration: $($_.Exception.Message)" "Error"
                return $null
            }
        }

        Function Build-ScubaGearCommand {
            <#
            .SYNOPSIS
            Builds the PowerShell command to execute ScubaGear with required defaults and optional parameters.
            #>
            param([string]$ConfigFilePath)

            # Build command with module import and ScubaGear execution
            $scubaConfig = $syncHash.UIConfigs.ScubaRunConfig
            $cmdParts = @()

            # Add pre-commands from configuration (but skip module installation)
            if ($scubaConfig.powershell.PreCommands) {
                foreach ($preCommand in $scubaConfig.powershell.preCommands) {
                    # Skip any Install-Module commands as they're likely to fail
                    if ($preCommand -notlike "*Install-Module*") {
                        $cmdParts += "$preCommand"
                    }
                }
            }

            # Build the main ScubaGear command with parameters
            $mainCommand = $scubaConfig.powershell.cmdlets
            $parameters = @()

            # REQUIRED DEFAULT PARAMETERS - Always include these
            $parameters += "-ConfigFilePath '$ConfigFilePath'"

            $organizationValue = $syncHash.Organization_TextBox.Text
            $parameters += "-Organization '$organizationValue'"

            # OPTIONAL PARAMETERS - Only add these if they have values and are not the removed defaults
            if ($scubaConfig.powershell.parameters) {
                foreach ($paramName in $scubaConfig.powershell.parameters.PSObject.Properties.Name) {
                    $paramConfig = $scubaConfig.powershell.parameters.$paramName

                    # Skip the removed default parameters (ConfigFilePath and Organization are handled above)
                    if ($paramName -in @("ScubaRunConfigFilePath", "ScubaRunOrganization")) {
                        continue
                    }

                    # Skip hidden parameters
                    if ($paramConfig.hidden -eq $true) {
                        continue
                    }

                    # Map parameter names to actual Invoke-Scuba parameters
                    $actualParamName = $paramName

                    switch ($paramConfig.type) {
                        "string" {
                            # Get value from UI controls
                            $textBoxName = $paramName + "_TextBox"
                            $textBox = $syncHash.$textBoxName
                            if ($textBox -and ![string]::IsNullOrWhiteSpace($textBox.Text)) {
                                $parameters += "-$actualParamName '$($textBox.Text)'"
                                Write-DebugOutput -Message "Added optional string parameter: -$actualParamName '$($textBox.Text)'" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                            }
                        }
                        "boolean" {
                            $checkboxName = $paramName + "_CheckBox"
                            $checkbox = $syncHash.$checkboxName

                            if ($checkbox -and $checkbox.IsChecked) {
                                $parameters += "-$actualParamName"
                                Write-DebugOutput -Message "Added optional boolean parameter: -$actualParamName" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                            }
                        }
                        "dropdown" {
                            $comboBoxName = $paramName + "_ComboBox"
                            $comboBox = $syncHash.$comboBoxName

                            if ($null -ne $comboBox.SelectedItem) {
                                If ($comboBox.SelectedItem -is [string]) {
                                    $parameters += "-$actualParamName '$($comboBox.SelectedItem)'"
                                } else {
                                    $parameters += "-$actualParamName $($comboBox.SelectedItem)"
                                }
                                Write-DebugOutput -Message "Added optional dropdown parameter: -$actualParamName '$($comboBox.SelectedItem)'" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                            }
                        }
                    }
                }
            }

            # Combine main command with parameters
            $fullCommand = "$mainCommand $($parameters -join ' ')"
            $cmdParts += $fullCommand

            # Add post-commands from configuration
            if ($scubaConfig.powershell.PostCommands) {
                foreach ($postCommand in $scubaConfig.powershell.postCommands) {
                    $cmdParts += $postCommand
                }
            }

            # Log the commands for debugging
            Write-DebugOutput -Message "Built ScubaGear commands:" -Source $MyInvocation.MyCommand.Name -Level "Info"
            foreach ($cmd in $cmdParts) {
                Write-DebugOutput -Message "  Command: $cmd" -Source $MyInvocation.MyCommand.Name -Level "Info"
            }

            # Also update the UI to show what will be executed
            Update-ScubaRunStatus "Prepared commands: $($cmdParts.Count) commands ready" "Info"

            return $cmdParts
        }

        
        Function Start-ScubaGearJob {
            <#
            .SYNOPSIS
            Starts ScubaGear in a background PowerShell process with real-time output capture.
            #>
            param([string[]]$Command)

            # Get what powershell version to run based on configuration
            $psVersion = $syncHash.UIConfigs.ScubaRunConfig.powershell.version
            if($psVersion -eq "5.1") {
                $poshPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
            } else {
                $poshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
            }

            # Create a temporary script file to execute all commands in sequence
            $tempScriptDir = Join-Path $env:TEMP "ScubaConfigRun"
            if (-not (Test-Path $tempScriptDir)) {
                New-Item -Path $tempScriptDir -ItemType Directory -Force | Out-Null
            }

            $tempScriptPath = Join-Path $tempScriptDir "ScubaGearExecution_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"

            # Create enhanced script content with real-time output
            $scriptContent = @"
# Enhanced script for real-time output capture
`$ErrorActionPreference = 'Continue'

# Function to write timestamped output
function Write-TimestampedOutput {
    param([string]`$Message, [string]`$Type = 'Info')
    `$timestamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "[`$timestamp] [`$Type] `$Message" -ForegroundColor `$(if (`$Type -eq 'Error') { 'Red' } elseif (`$Type -eq 'Warning') { 'Yellow' } else { 'Green' })
}

Write-TimestampedOutput "Starting ScubaGear execution script..."

"@

            # Add each command with proper variable expansion
            foreach ($cmd in $Command) {
                $scriptContent += @"

Write-TimestampedOutput "Executing: $cmd" "Info"
try {
    # Execute the command directly, allowing variable expansion
    $cmd
    Write-TimestampedOutput "Command completed successfully" "Info"
} catch {
    Write-TimestampedOutput "ERROR executing command: `$(`$_.Exception.Message)" "Error"
}

"@
    }

            $scriptContent += @"

Write-TimestampedOutput "ScubaGear execution script completed." "Info"
"@

            # Write script to file
            $scriptContent | Out-File -FilePath $tempScriptPath -Encoding UTF8

            # Store execution start time for finding the results folder
            $syncHash.ScubaGearExecutionStartTime = Get-Date

            # Create a job with real-time output streaming
            $job = Start-Job -ScriptBlock {
                # Use the appropriate PowerShell executable
                $poshExecutable = $using:poshPath

                if (-not (Test-Path $poshExecutable)) {
                    # Fallback to PowerShell 5.1 if the specified path doesn't exist
                    $poshExecutable = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
                }

                # Execute the script file and capture all output
                & $poshExecutable -ExecutionPolicy Bypass -File $using:tempScriptPath
            }

            # Store job reference and script path for cleanup
            $syncHash.ScubaRunExecutionJob = $job
            $syncHash.TempScriptPath = $tempScriptPath

            # Start enhanced monitoring for real-time output
            Start-ScubaGearMonitoringRealTime
        }
        
        <#
        Function Start-ScubaGearJob {
            <#
            .SYNOPSIS
            Starts ScubaGear in a background job without external script files.
            #
            param([string[]]$Command)

            # Store execution start time for finding the results folder
            $syncHash.ScubaGearExecutionStartTime = Get-Date

            # Create variables to pass to the job
            $configFilePath = $syncHash.TempConfigPath  # Store this when we create the temp config
            $organizationValue = $syncHash.Organization_TextBox.Text
            
            # Get parameter values from UI
            $jobParameters = @{}
            
            # Collect actual parameter values from UI controls
            if ($syncHash.UIConfigs.ScubaRunConfig.powershell.parameters) {
                foreach ($paramName in $syncHash.UIConfigs.ScubaRunConfig.powershell.parameters.PSObject.Properties.Name) {
                    $paramConfig = $syncHash.UIConfigs.ScubaRunConfig.powershell.parameters.$paramName
                    
                    if ($paramConfig.hidden -eq $true) { continue }
                    
                    switch ($paramConfig.type) {
                        "string" {
                            $textBoxName = $paramName + "_TextBox"
                            $textBox = $syncHash.$textBoxName
                            if ($textBox -and ![string]::IsNullOrWhiteSpace($textBox.Text)) {
                                $jobParameters[$paramName] = $textBox.Text
                            }
                        }
                        "boolean" {
                            $checkboxName = $paramName + "_CheckBox"
                            $checkbox = $syncHash.$checkboxName
                            if ($checkbox -and $checkbox.IsChecked) {
                                $jobParameters[$paramName] = $true
                            }
                        }
                        "dropdown" {
                            $comboBoxName = $paramName + "_ComboBox"
                            $comboBox = $syncHash.$comboBoxName
                            if ($null -ne $comboBox.SelectedItem) {
                                $jobParameters[$paramName] = $comboBox.SelectedItem
                            }
                        }
                    }
                }
            }

            # Create a job with direct scriptblock execution
            $job = Start-Job -ScriptBlock {
                param($ConfigPath, $Organization, $Parameters)
                
                # Function to write timestamped output
                function Write-TimestampedOutput {
                    param([string]$Message, [string]$Type = 'Info')
                    $timestamp = Get-Date -Format 'HH:mm:ss'
                    $color = switch ($Type) {
                        'Error' { 'Red' }
                        'Warning' { 'Yellow' }
                        'Success' { 'Green' }
                        default { 'White' }
                    }
                    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
                }

                Write-TimestampedOutput "Starting ScubaGear execution..." "Info"

                try {
                    # Import ScubaGear module if not already loaded
                    if (-not (Get-Module -Name ScubaGear)) {
                        Write-TimestampedOutput "Importing ScubaGear module..." "Info"
                        Import-Module ScubaGear -Force
                    }

                    # Build parameter hashtable for splatting
                    $scubaParams = @{
                        ConfigFilePath = $ConfigPath
                        Organization = $Organization
                    }

                    # Add optional parameters from UI
                    foreach ($key in $Parameters.Keys) {
                        $actualParamName = $key -replace '^ScubaRun', ''  # Remove ScubaRun prefix
                        $scubaParams[$actualParamName] = $Parameters[$key]
                    }

                    Write-TimestampedOutput "Executing: Invoke-SCuBA with $($scubaParams.Count) parameters" "Info"
                    
                    # Execute ScubaGear with parameter splatting
                    Invoke-SCuBA @scubaParams -Verbose

                    Write-TimestampedOutput "ScubaGear execution completed successfully!" "Success"
                }
                catch {
                    Write-TimestampedOutput "ERROR: $($_.Exception.Message)" "Error"
                    Write-TimestampedOutput "Full error details: $($_.Exception)" "Error"
                    throw
                }
            } -ArgumentList $configFilePath, $organizationValue, $jobParameters

            # Store job reference for monitoring
            $syncHash.ScubaRunExecutionJob = $job

            # Start enhanced monitoring for real-time output
            Start-ScubaGearMonitoringRealTime
        }
        #>
        Function Find-ScubaGearResultFolder {
            <#
            .SYNOPSIS
            Finds the most recently created ScubaGear results folder.
            #>
            param([datetime]$StartTime)

            try {
                # Common locations where ScubaGear creates output folders
                $searchPaths = @(
                    "$env:USERPROFILE\Documents",
                    ".",
                    "$env:USERPROFILE\Desktop"
                )

                # Get the folder base name - check UI controls first, then fall back to defaults
                $baseName = "M365BaselineConformance"
                $reportName = "BaselineReports"

                # Try to get values from UI controls if they exist and have actual values
                $folderNameValue = $syncHash.OutFolderName_TextBox.Text
                if (![string]::IsNullOrWhiteSpace($folderNameValue)) {
                    $baseName = $syncHash.UIConfigs.localePlaceholder.OutFolderName_TextBox
                    Write-DebugOutput -Message "Folder placeholder value: '$baseName'" -Source $MyInvocation -Level "Debug"
                }

                $reportNameValue = $syncHash.OutReportName_TextBox.Text
                if (![string]::IsNullOrWhiteSpace($reportNameValue)) {
                    if ($syncHash.UIConfigs.localePlaceholder.OutReportName_TextBox) {
                        $reportName = $syncHash.UIConfigs.localePlaceholder.OutReportName_TextBox
                        Write-DebugOutput -Message "Report placeholder value: '$reportName'" -Source $MyInvocation.MyCommand.Name -Level "Debug"
                    }
                }

                Write-DebugOutput -Message "Looking for folders with base name: '$baseName' and report name: '$reportName'" -Source $MyInvocation.MyCommand.Name -Level "Info"

                $mostRecentFolder = $null
                $mostRecentTime = [datetime]::MinValue

                foreach ($searchPath in $searchPaths) {
                    if (Test-Path $searchPath) {
                        # Look for folders with the pattern: BaseName_YYYY_MM_DD_HH_MM_SS
                        $searchPattern = "$baseName*"
                        Write-DebugOutput -Message "Searching in '$searchPath' for pattern: '$searchPattern'" -Source $MyInvocation.MyCommand.Name -Level "Debug"

                        $scubaFolders = Get-ChildItem -Path $searchPath -Directory -Filter $searchPattern -ErrorAction SilentlyContinue |
                            Where-Object {
                                # Check if folder was created after start time (with 2 minute buffer)
                                $_.CreationTime -gt $StartTime.AddMinutes(-2) -and
                                # Additional check: folder name should match the expected pattern
                                $_.Name -like "$baseName*"
                            } |
                            Sort-Object CreationTime -Descending

                        Write-DebugOutput -Message "Found $($scubaFolders.Count) matching folders in '$searchPath'" -Source $MyInvocation.MyCommand.Name -Level "Debug"

                        if ($scubaFolders -and $scubaFolders.Count -gt 0) {
                            $newestInThisPath = $scubaFolders[0]
                            Write-DebugOutput -Message "Newest folder in this path: '$($newestInThisPath.FullName)' (Created: $($newestInThisPath.CreationTime))" -Source $MyInvocation.MyCommand.Name -Level "Debug"

                            if ($newestInThisPath.CreationTime -gt $mostRecentTime) {
                                $mostRecentFolder = $newestInThisPath
                                $mostRecentTime = $newestInThisPath.CreationTime
                            }
                        }
                    }
                }

                if ($mostRecentFolder) {
                    Write-DebugOutput -Message "Most recent folder found: '$($mostRecentFolder.FullName)'" -Source $MyInvocation.MyCommand.Name -Level "Info"

                    # Check if the HTML report exists with the expected name
                    $htmlFile = Join-Path $mostRecentFolder.FullName "$reportName.html"
                    Write-DebugOutput -Message "Looking for HTML file: '$htmlFile'" -Source $MyInvocation.MyCommand.Name -Level "Debug"

                    if (Test-Path $htmlFile) {
                        Write-DebugOutput -Message "HTML report found: '$htmlFile'" -Source $MyInvocation.MyCommand.Name -Level "Info"
                        return @{
                            Type = "HTML"
                            Path = $htmlFile
                            Folder = $mostRecentFolder.FullName
                        }
                    } else {
                        # Try to find any HTML file in the folder as fallback
                        $htmlFiles = Get-ChildItem -Path $mostRecentFolder.FullName -Filter "*.html" -ErrorAction SilentlyContinue
                        if ($htmlFiles -and $htmlFiles.Count -gt 0) {
                            $fallbackHtml = $htmlFiles[0].FullName
                            Write-DebugOutput -Message "Using fallback HTML file: '$fallbackHtml'" -Source $MyInvocation.MyCommand.Name -Level "Info"
                            return @{
                                Type = "HTML"
                                Path = $fallbackHtml
                                Folder = $mostRecentFolder.FullName
                            }
                        } else {
                            Write-DebugOutput -Message "No HTML files found in folder, returning folder path" -Source $MyInvocation.MyCommand.Name -Level "Info"
                            return @{
                                Type = "Folder"
                                Path = $mostRecentFolder.FullName
                                Folder = $mostRecentFolder.FullName
                            }
                        }
                    }
                } else {
                    Write-DebugOutput -Message "No matching ScubaGear folders found" -Source $MyInvocation.MyCommand.Name -Level "Warning"
                }
            }
            catch {
                Write-DebugOutput -Message "Error finding ScubaGear results: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
            }

            return $null
        }

        Function Start-ScubaGearMonitoringRealTime {
            <#
            .SYNOPSIS
            Monitors the ScubaGear job progress with real-time output capture.
            #>

            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromSeconds(1)  # Check more frequently for real-time feel

            # Track what output we've already processed
            $script:lastOutputCount = 0

            # Fun scuba-themed running messages
            $script:scubaRunningMessages = @(
                "Diving deep... ScubaGear is exploring your settings!",
                "Checking your dive gear... almost ready to surface!",
                "Underwater operations in progress... please hold your breath!",
                "Navigating the reef of configurations... stay tuned!",
                "ScubaGear is adjusting your dive computer... one fin stroke at a time!",
                "Making waves... your ScubaGear is on the move!",
                "Sonar ping! ScubaGear is scanning for updates!",
                "Bubbles rising... ScubaGear is bubbling with activity!",
                "Submerging into configuration depths... please hang tight!",
                "Gear check complete... ScubaGear is on the ascent!",
                "Swimming through policies... current is strong but steady!",
                "Exploring the coral reef of compliance... beautiful formations ahead!",
                "Avoiding the sharks of misconfigurations... smooth sailing!",
                "Tentacles deep in your tenant... mapping every corner!",
                "Freestyle stroke through your security settings!",
                "Oxygen levels good... continuing the deep dive!",
                "Anchored in your environment... collecting treasures of insight!",
                "Charting the underwater map of your M365 landscape!"
            )

            # Status update tracking (update every 3-4 seconds instead of every second)
            $script:statusUpdateCounter = 0
            $script:statusUpdateInterval = 3  # Update status every 3 timer ticks (3 seconds)
            $script:currentMessageIndex = 0

            $timer.Add_Tick({
                if ($syncHash.ScubaRunExecutionJob) {
                    $job = $syncHash.ScubaRunExecutionJob

                    # Capture any new output that's available
                    try {
                        $newOutput = Receive-Job -Job $job -Keep

                        if ($newOutput -and $newOutput.Count -gt $script:lastOutputCount) {
                            # Process only new output lines
                            $newLines = $newOutput[$script:lastOutputCount..($newOutput.Count - 1)]
                            foreach ($line in $newLines) {
                                if (![string]::IsNullOrWhiteSpace($line)) {
                                    # Add to output textbox in real-time
                                    $syncHash.ScubaRunOutput_TextBox.AppendText("$line`r`n")
                                    $syncHash.ScubaRunOutput_TextBox.ScrollToEnd()
                                }
                            }
                            $script:lastOutputCount = $newOutput.Count
                        }
                    } catch {
                        Write-DebugOutput -Message "Error receiving job output: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                    }

                    # Check job state
                    switch ($job.State) {
                        "Running" {
                            # Only update status message every few seconds with rotating messages
                            $script:statusUpdateCounter++
                            if ($script:statusUpdateCounter -ge $script:statusUpdateInterval) {
                                # Get next message in rotation
                                #$currentMessage = $script:scubaRunningMessages[$script:currentMessageIndex]
                                #Update-ScubaRunStatus $currentMessage "Info"

                                #get random message from list
                                $randomMessage = Get-Random -InputObject $script:scubaRunningMessages
                                Update-ScubaRunStatus $randomMessage "Info"

                                # Move to next message (wrap around at end)
                                $script:currentMessageIndex = ($script:currentMessageIndex + 1) % $script:scubaRunningMessages.Count
                                $script:statusUpdateCounter = 0

                                # Vary the interval slightly for more natural feel (3-5 seconds)
                                $script:statusUpdateInterval = Get-Random -Minimum 3 -Maximum 6
                            }
                        }
                        "Completed" {
                            # Get any final output
                            $finalOutput = Receive-Job -Job $job
                            if ($finalOutput -and $finalOutput.Count -gt $script:lastOutputCount) {
                                $finalLines = $finalOutput[$script:lastOutputCount..($finalOutput.Count - 1)]
                                foreach ($line in $finalLines) {
                                    if (![string]::IsNullOrWhiteSpace($line)) {
                                        $syncHash.ScubaRunOutput_TextBox.AppendText("$line`r`n")
                                    }
                                }
                            }

                            # Now try to find the results folder
                            $resultsInfo = Find-ScubaGearResultFolder -StartTime $syncHash.ScubaGearExecutionStartTime

                            if ($resultsInfo) {
                                $syncHash.ScubaRunOutput_TextBox.AppendText("`r`n🎉 EXECUTION COMPLETE! 🎉`r`n")

                                if ($resultsInfo.Type -eq "HTML") {
                                    $syncHash.ScubaRunOutput_TextBox.AppendText("📊 Results available at: $($resultsInfo.Path)`r`n")
                                    $syncHash.ScubaRunOutput_TextBox.AppendText("💡 Tip: Copy this path and paste it into your browser to view the report`r`n")
                                    # Update status with the baseline conformance report path
                                    Update-ScubaRunStatus "✅ ScubaGear Complete | 📊 Report: $($resultsInfo.Path)" "Success"
                                } else {
                                    $syncHash.ScubaRunOutput_TextBox.AppendText("📁 Results folder: $($resultsInfo.Path)`r`n")
                                    # Update status with folder path
                                    Update-ScubaRunStatus "✅ ScubaGear Complete | 📁 Folder: $($resultsInfo.Path)" "Success"
                                }

                                $syncHash.ScubaRunOutput_TextBox.AppendText("📂 Full results folder: $($resultsInfo.Folder)`r`n")
                            } else {
                                # Enhanced fallback message with more specific guidance
                                Update-ScubaRunStatus "✅ ScubaGear Complete | 📁 Check Documents folder for results" "Success"

                                $syncHash.ScubaRunOutput_TextBox.AppendText("`r`n🎉 EXECUTION COMPLETE! 🎉`r`n")
                                $syncHash.ScubaRunOutput_TextBox.AppendText("📁 Check your Documents folder for M365BaselineConformance_* folders`r`n")
                            }

                            Complete-ScubaGearExecution
                            $this.Stop()

                            # Cleanup temp script
                            if ($syncHash.TempScriptPath -and (Test-Path $syncHash.TempScriptPath)) {
                                try {
                                    Remove-Item -Path $syncHash.TempScriptPath -Force -ErrorAction SilentlyContinue
                                    $syncHash.TempScriptPath = $null
                                } catch {
                                    Write-DebugOutput -Message "Error cleaning up temp script file: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                                }
                            }
                        }
                        "Failed" {
                            $failureReason = ""
                            try {
                                $jobError = $job.ChildJobs[0].Error
                                if ($jobError) {
                                    $failureReason = ": $($jobError[-1].Exception.Message)"
                                }
                            } catch {
                                Write-DebugOutput -Message "Error extracting job error message: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                            }

                            Update-ScubaRunStatus "ScubaGear execution failed: $failureReason" "Error"
                            Complete-ScubaGearExecution
                            $this.Stop()
                        }
                        "Stopped" {
                            Update-ScubaRunStatus "ScubaGear execution was stopped" "Warning"
                            Complete-ScubaGearExecution
                            $this.Stop()
                        }
                    }
                }
            })

            $syncHash.ScubaRunExecutionTimer = $timer
            $timer.Start()
        }

        Function Stop-ScubaGearExecution {
            <#
            .SYNOPSIS
            Stops the running ScubaGear job.
            #>

            if ($syncHash.ScubaRunExecutionJob) {
                Stop-Job -Job $syncHash.ScubaRunExecutionJob -Force
                Remove-Job -Job $syncHash.ScubaRunExecutionJob -Force
                $syncHash.ScubaRunExecutionJob = $null
            }

            if ($syncHash.ScubaRunExecutionTimer) {
                $syncHash.ScubaRunExecutionTimer.Stop()
                $syncHash.ScubaRunExecutionTimer = $null
            }

            # Cleanup temporary script file
            if ($syncHash.TempScriptPath -and (Test-Path $syncHash.TempScriptPath)) {
                try {
                    Remove-Item -Path $syncHash.TempScriptPath -Force -ErrorAction SilentlyContinue
                    $syncHash.TempScriptPath = $null
                } catch {
                    Write-DebugOutput -Message "Error cleaning up temp script file: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                }
            }

            Update-ScubaRunStatus "Execution stopped by user" "Warning"
            # Clear completion flag since this is a manual stop, not a completion
            $syncHash.JustCompletedExecution = $false
            Reset-ScubaRunUI
        }

        Function Complete-ScubaGearExecution {
            <#
            .SYNOPSIS
            Completes ScubaGear execution and updates UI.
            #>
            # Cleanup temporary script file
            if ($syncHash.TempScriptPath -and (Test-Path $syncHash.TempScriptPath)) {
                try {
                    Remove-Item -Path $syncHash.TempScriptPath -Force -ErrorAction SilentlyContinue
                    $syncHash.TempScriptPath = $null
                } catch {
                    Write-DebugOutput -Message "Error cleaning up temp script file: $($_.Exception.Message)" -Source $MyInvocation.MyCommand.Name -Level "Error"
                }
            }

            # Set flag to indicate we just completed execution (preserve status message)
            $syncHash.JustCompletedExecution = $true
            Reset-ScubaRunUI
        }


        Function Start-ScubaGearMonitoring {
            <#
            .SYNOPSIS
            Monitors the ScubaGear job progress.
            #>

            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromSeconds(2)

            $timer.Add_Tick({
                if ($syncHash.ScubaRunExecutionJob) {
                    $job = $syncHash.ScubaRunExecutionJob

                    # Check job state
                    switch ($job.State) {
                        "Running" {
                            Update-ScubaRunStatus "ScubaGear is running..." "Info"
                            # You could parse output here if available
                        }
                        "Completed" {
                            $results = Receive-Job -Job $job
                            Update-ScubaRunStatus "ScubaGear completed successfully" "Success"
                            $syncHash.ScubaRunOutput_TextBox.AppendText("$results`r`n")
                            Complete-ScubaGearExecution
                            $this.Stop()
                        }
                        "Failed" {
                            $null = Receive-Job -Job $job -ErrorAction SilentlyContinue
                            Update-ScubaRunStatus "ScubaGear failed: $error" "Error"
                            Complete-ScubaGearExecution
                            $this.Stop()
                        }
                        "Stopped" {
                            Update-ScubaRunStatus "ScubaGear execution was stopped" "Warning"
                            Complete-ScubaGearExecution
                            $this.Stop()
                        }
                    }
                }
            })

            $syncHash.ScubaRunExecutionTimer = $timer
            $timer.Start()
        }

        Function Stop-ScubaGearExecution {
            <#
            .SYNOPSIS
            Stops the running ScubaGear job.
            #>

            if ($syncHash.ScubaRunExecutionJob) {
                Stop-Job -Job $syncHash.ScubaRunExecutionJob -Force
                Remove-Job -Job $syncHash.ScubaRunExecutionJob -Force
                $syncHash.ScubaRunExecutionJob = $null
            }

            if ($syncHash.ScubaRunExecutionTimer) {
                $syncHash.ScubaRunExecutionTimer.Stop()
                $syncHash.ScubaRunExecutionTimer = $null
            }

            Update-ScubaRunStatus "Execution stopped by user" "Warning"
            Reset-ScubaRunUI
        }

        Function Reset-ScubaRunUI {
            <#
            .SYNOPSIS
            Resets the UI to ready state.
            #>

            $syncHash.ScubaRunStart_Button.IsEnabled = $true
            $syncHash.ScubaRunStop_Button.IsEnabled = $false
            $syncHash.ScubaRunStop_Button.Visibility = "Collapsed"
            $syncHash.ScubaRunStart_Button.Visibility = "Visible"

            # Only show "Ready to run" status if we haven't just completed execution
            if (-not $syncHash.JustCompletedExecution) {
                Test-ScubaRunReadiness
            } else {
                # Clear the flag for next time
                $syncHash.JustCompletedExecution = $false
            }
        }

        #===========================================================================
        #
        # LOAD UI
        #
        #===========================================================================
        # Set window icon from DrawingImage resource
        try {
            $iconDrawing = $syncHash.Window.FindResource("ScubaGearIconImage")
            if ($iconDrawing) {
                $syncHash.Window.Icon = $iconDrawing
                Write-DebugOutput -Message "Window icon set from DrawingImage" -Source "Icon Creation" -Level "Info"
            }
        }
        catch {
            Write-DebugOutput -Message "Failed to set window icon: $($_.Exception.Message)" -Source "Icon Creation" -Level "Warning"
        }

        #Import UI configuration file
        $syncHash.UIConfigs = (Get-Content -Path $syncHash.UIConfigPath -Raw) | ConvertFrom-Json
        Write-DebugOutput -Message "UIConfigs loaded: $($syncHash.UIConfigPath)" -Source "UI Launch" -Level "Info"

        #Import baseline configuration file
        $syncHash.Baselines = ((Get-Content -Path $syncHash.BaselineConfigPath -Raw) | ConvertFrom-Json).baselines
        Write-DebugOutput -Message "Baselines loaded: $($syncHash.BaselineConfigPath)" -Source "UI Launch" -Level "Info"

        # Add global event handlers to all UI controls after everything is loaded
        $syncHash.PreviewTab.IsEnabled = $false

        #update version
        $syncHash.Version_TextBlock.Text = "v$($syncHash.UIConfigs.Version)"

        # Show/Hide Debug tab based on DebugUI parameter
        if ($syncHash.UIConfigs.DebugMode) {
            $syncHash.DebugTab.Visibility = "Visible"
            $syncHash.DebugTabInfo_TextBlock.Text = "Debug output is enabled. Real-time debugging information will appear below."
            Write-DebugOutput -Message "Debug is enabled in mode: $($syncHash.UIConfigs.DebugMode)" -Source "UI Launch" -Level "Info"
        } else {
            $syncHash.DebugTab.Visibility = "Collapsed"
        }


        #override locale context
        foreach ($localeElement in $syncHash.UIConfigs.localeContext.PSObject.Properties) {
            $LocaleControl = $syncHash.($localeElement.Name)
            if ($LocaleControl){
                #get type of control
                switch($LocaleControl.GetType().Name) {
                    'TextBlock' {
                        $LocaleControl.Text = $localeElement.Value
                    }
                    'Button' {
                        $LocaleControl.Content = $localeElement.Value
                    }
                    'ComboBox' {
                        $LocaleControl.ToolTip = $localeElement.Value
                    }
                    'CheckBox' {
                        $LocaleControl.Content = $localeElement.Value
                    }
                    'Label' {
                        $LocaleControl.Content = $localeElement.Value
                    }
                }
            }
            Write-DebugOutput -Message "$($localeElement.Name): $($localeElement.Value)" -Source "UI Launch" -Level "Info"

        }

        foreach ($env in $syncHash.UIConfigs.M365Environment) {
            $comboItem = New-Object System.Windows.Controls.ComboBoxItem
            $comboItem.Content = "$($env.displayName) ($($env.name))"
            $comboItem.Tag = $env.id

            $syncHash.M365Environment_ComboBox.Items.Add($comboItem)
            Write-DebugOutput -Message "M365Environment_ComboBox added: $($env.displayName) ($($env.name))" -Source "UI Launch" -Level "Info"
        }

        Add-ControlEventHandler -Control $syncHash.M365Environment_ComboBox

        # Set selection based on parameter or defa          ult to first item
        if ($syncHash.M365Environment) {
            $selectedEnv = $syncHash.M365Environment_ComboBox.Items | Where-Object { $_.Tag -eq $syncHash.M365Environment }
            if ($selectedEnv) {
                $syncHash.M365Environment_ComboBox.SelectedItem = $selectedEnv
            } else {
                # If the specified environment isn't found, default to first item
                $syncHash.M365Environment_ComboBox.SelectedIndex = 0
            }
        } else {
            # Set default selection to first item if no parameter specified
            $syncHash.M365Environment_ComboBox.SelectedIndex = 0
        }
        Write-DebugOutput -Message "M365Environment_ComboBox set: $($syncHash.M365Environment_ComboBox.SelectedItem.Content)" -Source "UI Update" -Level "Info"

        # Populate Products Checkbox dynamically within the ProductsGrid
        #only list three rows then use next column
        # Assume 3 rows, then wrap to next column
        $maxRows = 3
        for ($i = 0; $i -lt $syncHash.UIConfigs.products.Count; $i++) {
            $product = $syncHash.UIConfigs.products[$i]

            $checkBox = New-Object System.Windows.Controls.CheckBox
            $checkBox.Content = $product.displayName
            $checkBox.Name = ($product.id + "ProductCheckBox")
            $checkBox.Tag = $product.id
            $checkBox.Margin = "0,5"

            $row = $i % $maxRows
            $column = [math]::Floor($i / $maxRows)

            [System.Windows.Controls.Grid]::SetRow($checkBox, $row)
            [System.Windows.Controls.Grid]::SetColumn($checkBox, $column)

            [void]$syncHash.ProductsGrid.Children.Add($checkBox)

            # Add event handlers for checked/unchecked
            $checkBox.Add_Checked({
                $checkBox.IsEnabled = $false # Disable checkbox to prevent further changes during processing

                $productId = $this.Tag

                # Only update the data - let the timer handle UI updates
                if (-not $syncHash.GeneralSettingsData.ProductNames) {
                    $syncHash.GeneralSettingsData.ProductNames = @()
                }

                # Add to GeneralSettings if not already present
                if ($syncHash.GeneralSettingsData.ProductNames -notcontains $productId) {
                    # Force array type and add the new product
                    $syncHash.GeneralSettingsData.ProductNames = [System.Array]($syncHash.GeneralSettingsData.ProductNames + $productId.ToLower())
                    Write-DebugOutput -Message "Added [$productId] to ProductNames data" -Source "User Action" -Level "Info"
                }

                #loop through all policies controls tabs for this product
                Foreach($Policy in $syncHash.UIConfigs.baselineControls)
                {
                    $policytab = $syncHash.("$($Policy.controlType)Tab")
                    If($policytab) {
                        $policytab.IsEnabled = $true
                        Write-DebugOutput -Message "Enabled $($Policy.controlType)Tab for: $($productId)" -Source "UI Update" -Level "Info"
                    } else {
                        Write-DebugOutput -Message "No tab found for: $($Policy.controlType)Tab" -Source "UI Update" -Level "Verbose"
                    }

                    #enable sub tabs
                    $producttab = $syncHash.("$($productId)$($Policy.controlType)Tab")
                    If($producttab) {
                        $producttab.IsEnabled = $true
                        Write-DebugOutput -Message "Enabled $($Policy.controlType) sub tab for: $($productId)" -Source "UI Update" -Level "Info"
                    } else {
                        Write-DebugOutput -Message "No sub tab found for: $($productId)$($Policy.controlType)Tab" -Source "UI Update" -Level "Verbose"
                    }

                    #enable content
                    $container = $syncHash.("$($productId)$($Policy.controlType)Content")
                    if ($container) {
                        New-ProductPolicyCards -ProductName $productId -Container $container -ControlType $Policy.controlType
                        Write-DebugOutput -Message "Enabled content container for: $($productId)$($Policy.controlType)Content" -Source "UI Update" -Level "Verbose"
                    } else {
                        Write-DebugOutput -Message "No content container found for: $($productId)$($Policy.controlType)Content" -Source "UI Update" -Level "Verbose"
                    }
                }
                # Re-enable the checkbox after processing
                $checkBox.IsEnabled = $true

            }.GetNewClosure())

            $checkBox.Add_Unchecked({
                $checkBox.IsEnabled = $false # Disable checkbox to prevent further changes during processing
                $productId = $this.Tag

                # Check minimum selection requirement
                if ($syncHash.GeneralSettingsData.ProductNames -and $syncHash.GeneralSettingsData.ProductNames.Count -eq 1 -and $syncHash.GeneralSettingsData.ProductNames -contains $productId) {
                    # This is the last selected product - prevent unchecking
                    Write-DebugOutput -Message "Prevented unchecking last product: $productId" -Source "User Action" -Level "Warning"
                    [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localePopupMessages.ProductSelectionError, "Minimum Selection Required", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

                    # Set the checkbox back to checked
                    $this.IsChecked = $true
                    return
                }

                # Remove from GeneralSettings
                if ($syncHash.GeneralSettingsData.ProductNames -contains $productId) {
                    # Filter out the product and ensure unique values
                    $syncHash.GeneralSettingsData.ProductNames = @($syncHash.GeneralSettingsData.ProductNames | Where-Object { $_ -ne $productId } | Sort-Object -Unique)
                    Write-DebugOutput -Message "Removed [$productId] from ProductNames data" -Source "User Action" -Level "Info"
                }

                #loop through all policies controls for this product
                Foreach($Policy in $syncHash.UIConfigs.baselineControls)
                {
                    # Clear data for this product
                    if ($syncHash.($Policy.dataControlOutput).contains($productId)) {
                        $syncHash.($Policy.dataControlOutput).Remove($productId)
                        Write-DebugOutput -Message "Cleared data for: $productId in $($Policy.dataControlOutput)" -Source "User Action" -Level "Info"
                    }

                    #disable and clear the Content
                    $producttab = $syncHash.("$($productId)$($Policy.controlType)Tab")
                    if ($producttab) {
                        $producttab.IsEnabled = $false
                        Write-DebugOutput -Message "Disabled $($Policy.controlType) sub tab for: $($productId)" -Source "UI Update" -Level "Info"
                    } else {
                        Write-DebugOutput -Message "No sub tab found for: $($productId)$($Policy.controlType)Tab" -Source "UI Update" -Level "Verbose"
                    }

                    $container = $syncHash.("$($productId)$($Policy.controlType)Content")
                    if ($container) {
                        $container.Children.Clear()
                        Write-DebugOutput -Message "Cleared content container for: $($productId)$($Policy.controlType)Content" -Source "User Action" -Level "Info"
                    } else {
                        Write-DebugOutput -Message "No content container found for: $($productId)$($Policy.controlType)Content" -Source "UI Update" -Level "Verbose"
                    }
                }
                # Re-enable the checkbox after processing
                $checkBox.IsEnabled = $true
            }.GetNewClosure())

        }
        $ExclusionSupport = $syncHash.UIConfigs.products | Where-Object { $_.supportsExclusions -eq $true } | Select-Object -ExpandProperty id
        $syncHash.ExclusionsInfo_TextBlock.Text = ($syncHash.UIConfigs.localeContext.ExclusionsInfo_TextBlock -f ($ExclusionSupport -join ', ').ToUpper())

        Foreach($product in $syncHash.UIConfigs.products) {
            # Initialize the OmissionTab and ExclusionTab for each product
            $exclusionTab = $syncHash.("$($product.id)ExclusionsTab")

            if ($product.supportsExclusions) {
                $exclusionTab.Visibility = "Visible"
                Write-DebugOutput -Message "Enabled Exclusion sub tab for: $($product.id)" -Source "UI" -Level "Info"
            }else{
                # Disable the Exclusions tab if the product does not support exclusions
                $exclusionTab.Visibility = "Collapsed"
                Write-DebugOutput -Message "Disabled Exclusion sub tab for: $($product.id)" -Source "UI" -Level "Info"
            }
        }


        # added events to all tab toggles
        $toggleControls = $syncHash.GetEnumerator() | Where-Object { $_.Name -like '*_Toggle' }
        foreach ($toggleName in $toggleControls) {
            $contentName = $toggleName.Name.Replace('_Toggle', '_Content')
            $contentControl = $syncHash[$contentName]

            # Add Checked event handler
            $syncHash[$toggleName.Name].Add_Checked({
                $contentControl.Visibility = "Visible"
            }.GetNewClosure())

            # Add Unchecked event handler
            $syncHash[$toggleName.Name].Add_Unchecked({
                $contentControl.Visibility = "Collapsed"
            }.GetNewClosure())
        }

        # Add event to placeholder TextBoxes
        foreach ($placeholderKey in $syncHash.UIConfigs.localePlaceholder.PSObject.Properties.Name) {
            $control = $syncHash.$placeholderKey
            if ($control -is [System.Windows.Controls.TextBox]) {
                $placeholderText = $syncHash.UIConfigs.localePlaceholder.$placeholderKey
                Initialize-PlaceholderTextBox -TextBox $control -PlaceholderText $placeholderText
            }
        }

        # Handle Organization TextBox with special Graph Connected logic
        if ($syncHash.GraphConnected) {
            try {
                $tenantDetails = (Invoke-MgGraphRequest -Method GET -Uri "$($syncHash.GraphEndpoint)/v1.0/organization" -OutputType PSObject).Value
                $tenantName = ($tenantDetails.VerifiedDomains | Where-Object { $_.IsDefault -eq $true }).Name
                $syncHash.Organization_TextBox.Text = $tenantName
                $syncHash.Organization_TextBox.Foreground = [System.Windows.Media.Brushes]::Gray
                $syncHash.Organization_TextBox.FontStyle = [System.Windows.FontStyles]::Normal
                $syncHash.Organization_TextBox.BorderBrush = [System.Windows.Media.Brushes]::Gray
                $syncHash.Organization_TextBox.BorderThickness = "1"
                $syncHash.Organization_TextBox.isEnabled = $false # Disable editing if Graph is connected

                Add-DynamicGraphButtons
            } catch {
                Write-DebugOutput -Message "Failed to retrieve organization details from Graph: $($_.Exception.Message)" -Source "Graph Request" -Level "Error"
                $syncHash.GraphConnected = $false
                # Fallback to placeholder if Graph request fails
                Initialize-PlaceholderTextBox -TextBox $syncHash.Organization_TextBox -PlaceholderText $syncHash.UIConfigs.localePlaceholder.Organization_TextBox
            } finally {
                # Ensure Graph status indicator is initialized
                Initialize-GraphStatusIndicator
            }
        }

        # If YAMLImport is specified, load the YAML configuration
        # Process YAMLConfigFile parameter AFTER UI is fully initialized
        If($syncHash.ConfigImportPath){
            try {
                Write-DebugOutput -Message "Processing YAMLConfigFile parameter: $($syncHash.ConfigImportPath)" -Source "UI Launch" -Level "Info"

                # Import with progress window
                $importSuccess = Invoke-YamlImportWithProgress -YamlFilePath $syncHash.ConfigImportPath -WindowTitle "Loading Configuration File"

                if ($importSuccess) {
                    Write-DebugOutput -Message "YAMLConfigFile processed successfully" -Source "UI Launch" -Level "Info"
                } else {
                    Write-DebugOutput -Message "YAMLConfigFile processing failed" -Source "UI Launch" -Level "Warning"
                }
            }
            catch {
                Write-DebugOutput -Message "Error processing YAMLConfigFile: $($_.Exception.Message)" -Source "UI Launch" -Level "Error"
                [System.Windows.MessageBox]::Show("Error importing configuration file: $($_.Exception.Message)", "Import Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
        }

        $syncHash.Window.Dispatcher.Invoke([Action]{
            try {
                Write-DebugOutput -Message "UI initialization complete, starting main window" -Source "UI Launch" -Level "Info"
            } catch {
                Write-Error "Dispatcher error: $($_.Exception.Message)"
            }
        })

        # Initialize Global Settings
        Write-DebugOutput -Message "Initializing Global Settings tab" -Source "UI Launch" -Level "Info"
        New-GlobalSettingsControls

        If($syncHash.UIConfigs.EnableScubaRun){
            $syncHash.ScubaRunTab.Visibility = "Visible"
            # Initialize ScubaRun tab
            Write-DebugOutput -Message "Initializing ScubaRun tab" -Source "UI Launch" -Level "Info"
            Initialize-ScubaRunTab
        }else {
            $syncHash.ScubaRunTab.Visibility = "Collapsed"
        }

        $syncHash.ScubaRunPowerShellVersion_TextBlock.Text = "PowerShell $($syncHash.UIConfigs.ScubaRunConfig.powershell.version) required"
        #===========================================================================
        # Button Event Handlers
        #===========================================================================
        # add event handlers to all buttons
        # New Session Button
        $syncHash.NewSessionButton.Add_Click({
            $result = [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localePopupMessages.NewSessionConfirmation, "New Session", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                # Reset all form fields
                Clear-FieldValue
            }
        })

        # Import Button
        $syncHash.ImportButton.Add_Click({
            $openFileDialog = New-Object Microsoft.Win32.OpenFileDialog
            $openFileDialog.Filter = "YAML Files (*.yaml;*.yml)|*.yaml;*.yml|All Files (*.*)|*.*"
            $openFileDialog.Title = "Import ScubaGear Configuration"

            if ($openFileDialog.ShowDialog() -eq $true) {
                try {
                    # Import with progress window
                    $importSuccess = Invoke-YamlImportWithProgress -YamlFilePath $openFileDialog.FileName -WindowTitle "Importing Configuration"

                    if ($importSuccess) {
                        [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localePopupMessages.ImportSuccess, "Import Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    }
                }
                catch {
                    [System.Windows.MessageBox]::Show("Error importing configuration: $($_.Exception.Message)", "Import Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                }
            }
        })

        # Preview & Generate Button
        $syncHash.PreviewButton.Add_Click({

            $syncHash.Window.Dispatcher.Invoke([action]{
                $errorMessages = @()

                # Organization validation (required)
                $orgValid = Confirm-RequiredField -UIElement $syncHash.Organization_TextBox `
                                        -RegexPattern $syncHash.UIConfigs.valueValidations.tenantDomain.pattern `
                                        -PlaceholderText $syncHash.UIConfigs.localePlaceholder.Organization_TextBox

                if (-not $orgValid) {
                    $errorMessages += $syncHash.UIConfigs.localeErrorMessages.OrganizationValidation
                    #navigate to General tab
                    $syncHash.MainTabControl.SelectedItem = $syncHash.MainTab
                }

                # Products validation (at least one product must be selected)
                if (-not $syncHash.GeneralSettingsData.ProductNames -or $syncHash.GeneralSettingsData.ProductNames.Count -eq 0) {
                    $errorMessages += $syncHash.UIConfigs.localeErrorMessages.ProductSelection
                    $syncHash.MainTabControl.SelectedItem = $syncHash.GeneralTab
                    $productsValid = $false
                }else {
                    $productsValid = $true
                }

                If(-not $productsValid) {
                    $syncHash.PreviewTab.IsEnabled = $false
                    $syncHash.MainTabControl.SelectedItem = $syncHash.MainTab
                }

                # Advanced Tab Validations (only if sections are toggled on)

                # Application Section Validations
                if ($syncHash.ApplicationSection_Toggle.IsChecked) {

                    # AppID validation (GUID format)
                    $appIdValid = Confirm-RequiredField -UIElement $syncHash.AppId_TextBox `
                                                    -RegexPattern $syncHash.UIConfigs.valueValidations.guid.pattern `
                                                    -PlaceholderText $syncHash.UIConfigs.localePlaceholder.AppId_TextBox `

                    if (-not $appIdValid) {
                        $errorMessages += $syncHash.UIConfigs.localeErrorMessages.AppIdValidation
                        $syncHash.MainTabControl.SelectedItem = $syncHash.AdvancedTab
                    }

                    # Certificate Thumbprint validation (40 character hex)
                    $certValid = Confirm-RequiredField -UIElement $syncHash.CertificateThumbprint_TextBox `
                                                    -RegexPattern $syncHash.UIConfigs.valueValidations.thumbprint.pattern `
                                                    -PlaceholderText $syncHash.UIConfigs.localePlaceholder.CertificateThumbprint_TextBox

                    if (-not $certValid) {
                        $errorMessages += $syncHash.UIConfigs.localeErrorMessages.CertificateValidation
                        $syncHash.MainTabControl.SelectedItem = $syncHash.AdvancedTab
                    }
                }

                # OPA Section Validations
                if ($syncHash.OpaSection_Toggle.IsChecked) {

                    # OPA Path validation using enhanced Confirm-RequiredField
                    $opaPathValid = Confirm-RequiredField -UIElement $syncHash.OpaPath_TextBox `
                                                    -PlaceholderText $syncHash.UIConfigs.localePlaceholder.OpaPath_TextBox `
                                                    -TestPath `
                                                    -RequiredFiles @("opa_windows_amd64.exe", "opa.exe") `

                    if (-not $opaPathValid) {
                        $errorMessages += ($syncHash.UIConfigs.localeErrorMessages.OpaPathValidation -f $syncHash.OpaPath_TextBox.Text)
                        $syncHash.MainTabControl.SelectedItem = $syncHash.AdvancedTab
                    }

                }

                # Show consolidated error message if there are validation errors
                if ($errorMessages.Count -gt 0) {
                    $syncHash.PreviewTab.IsEnabled = $false
                    #$errorMessages += $syncHash.UIConfigs.localeErrorMessages.PreviewValidation + "`n`n" + ($errorMessages -join "`n")
                    [System.Windows.MessageBox]::Show($errorMessages, "Validation Errors", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
                }else {
                    $syncHash.PreviewTab.IsEnabled = $true
                }

                if ($errorMessages.Count -eq 0) {
                    Save-GeneralSettingsFromInput
                    Save-AdvancedSettingsFromInput
                    Save-GlobalSettingsFromInput
                    # Generate YAML preview
                    New-YamlPreview

                    If($syncHash.UIConfigs.EnableScubaRun){
                        Test-ScubaRunReadiness
                    }
                }
            }) #end Dispatcher.Invoke
        })

        # Copy to Clipboard Button
        $syncHash.CopyYamlButton.Add_Click({
            try {
                $syncHash.Window.Dispatcher.Invoke([Action]{
                    if (![string]::IsNullOrWhiteSpace($syncHash.YamlPreview_TextBox.Text)) {
                        [System.Windows.Clipboard]::SetText($syncHash.YamlPreview_TextBox.Text)
                        [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localePopupMessages.YamlClipboardComplete, "Copy Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    } else {
                        [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localePopupMessages.YamlClipboardNoPreview, "Nothing to Copy", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    }
                })
            }
            catch {
                # Even this must go in Dispatcher
                $syncHash.Window.Dispatcher.Invoke([Action]{
                    [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localePopupMessages.YamlClipboardError -f $_.Exception.Message, "Copy Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                })
            }
        })

        # Download YAML Button
        $syncHash.DownloadYamlButton.Add_Click({
            try {
                if ([string]::IsNullOrWhiteSpace($syncHash.YamlPreview_TextBox.Text)) {
                    [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localeErrorMessages.DownloadNullError, "Nothing to Download", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
                    return
                }

                # Generate filename based on organization name
                $orgName = $syncHash.Organization_TextBox.Text
                if ([string]::IsNullOrWhiteSpace($orgName) -or $orgName -eq $syncHash.UIConfigs.localePlaceholder.Organization_TextBox) {
                    $dateFormat = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
                    $filename = "ScubaGear-Config-$dateFormat.yaml"
                } else {
                    # Remove any invalid filename characters and use organization name
                    $cleanOrgName = $orgName -replace '[\\/:*?"<>|]', '_'
                    $filename = "$cleanOrgName.yaml"
                }

                # Create SaveFileDialog
                $saveFileDialog = New-Object Microsoft.Win32.SaveFileDialog
                $saveFileDialog.Filter = "YAML Files (*.yaml)|*.yaml|All Files (*.*)|*.*"
                $saveFileDialog.Title = "Save ScubaGear Configuration"
                $saveFileDialog.FileName = $filename
                $saveFileDialog.DefaultExt = ".yaml"

                if ($saveFileDialog.ShowDialog() -eq $true) {
                    # Save the YAML content to file
                    $yamlContent = $syncHash.YamlPreview_TextBox.Text
                    [System.IO.File]::WriteAllText($saveFileDialog.FileName, $yamlContent, [System.Text.Encoding]::UTF8)

                    #$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                    #[System.IO.File]::WriteAllText($saveFileDialog.FileName, $yamlContent, $utf8NoBom)
                    #$yamlContent | Out-File -FilePath $saveFileDialog.FileName -Encoding utf8NoBOM

                    [System.Windows.MessageBox]::Show(($syncHash.UIConfigs.localePopupMessages.YamlSaveSuccess -f $saveFileDialog.FileName), "Save Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                }
            }
            catch {
                [System.Windows.MessageBox]::Show(($syncHash.UIConfigs.localePopupMessages.YamlSaveError -f $_.Exception.Message), "Save Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
        })

        $syncHash.DownloadDebugLogButton.Add_Click({
            if ($syncHash.Debug_TextBox.Text -and $syncHash.Debug_TextBox.Text.Count -gt 0) {
                $saveDialog = New-Object Microsoft.Win32.SaveFileDialog
                $saveDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
                $saveDialog.DefaultExt = "txt"
                $saveDialog.FileName = "ScubaGear_Debug_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"

                if ($saveDialog.ShowDialog() -eq $true) {
                    $syncHash.Debug_TextBox.Text | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
                    [System.Windows.MessageBox]::Show("Debug log saved to: $($saveDialog.FileName)", "Debug Log Saved", "OK", "Information")
                }
            }

        })

        # Browse Output Path Button
        $syncHash.BrowseOutPathButton.Add_Click({
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderDialog.Description = "Select Output Path"
            $folderDialog.ShowNewFolderButton = $true

            if ($syncHash.OutPath_TextBox.Text -ne "." -and (Test-Path $syncHash.OutPath_TextBox.Text)) {
                $folderDialog.SelectedPath = $syncHash.OutPath_TextBox.Text
            }

            $result = $folderDialog.ShowDialog()
            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                $syncHash.OutPath_TextBox.Text = $folderDialog.SelectedPath
                #New-YamlPreview
            }
        })

        # Browse OPA Path Button
        $syncHash.BrowseOpaPathButton.Add_Click({
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderDialog.Description = "Select OPA Path"
            $folderDialog.ShowNewFolderButton = $true

            # Check if current textbox has a valid path, otherwise use ScubaGear default
            if ($syncHash.OpaPath_TextBox.Text -ne "." -and (Test-Path $syncHash.OpaPath_TextBox.Text)) {
                $folderDialog.SelectedPath = $syncHash.OpaPath_TextBox.Text
            } else {
                # Default to ScubaGear Tools directory
                $defaultOpaPath = Join-Path $env:UserProfile ".scubagear\Tools"
                $folderDialog.SelectedPath = $defaultOpaPath
            }

            $result = $folderDialog.ShowDialog()
            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                $syncHash.OpaPath_TextBox.Text = $folderDialog.SelectedPath
                #New-YamlPreview
            }
        })

        # Select Certificate Button
        $syncHash.SelectCertificateButton.Add_Click({
            try {
                # Get user certificates with better error handling
                $userCerts = @()
                try {
                    $userCerts = Get-ChildItem -Path "Cert:\CurrentUser\My" -ErrorAction Stop | Where-Object {
                        $_.HasPrivateKey -and
                        $_.NotAfter -gt (Get-Date) -and
                        $_.Subject -notlike "*Microsoft*"
                    } | Sort-Object Subject
                }
                catch {
                    Write-DebugOutput -Message ("Error accessing certificate store: {0}" -f $_.Exception.Message) -Source "Certificate Selection" -Level "Error"
                    [System.Windows.MessageBox]::Show(($syncHash.UIConfigs.localeErrorMessages.CertificateStoreAccessError -f $_.Exception.Message), "Certificate Store Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                    return
                }

                Write-DebugOutput -Message ("Found {0} certificates" -f $userCerts.Count) -Source "Certificate Selection" -Level "Verbose"

                if ($userCerts.Count -eq 0) {
                    [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localeErrorMessages.CertificateNotFound,
                                                    "No Certificates",
                                                    [System.Windows.MessageBoxButton]::OK,
                                                    [System.Windows.MessageBoxImage]::Information)
                    return
                }

                # Prepare data for display
                $displayCerts = $userCerts | ForEach-Object {
                    [PSCustomObject]@{
                        Subject = $_.Subject
                        Issuer = $_.Issuer
                        NotAfter = $_.NotAfter.ToString("yyyy-MM-dd")
                        Thumbprint = $_.Thumbprint
                        Certificate = $_
                    }
                } | Sort-Object Subject

                # Column configuration
                $columnConfig = [ordered]@{
                    Thumbprint = @{ Header = "Thumbprint"; Width = 120 }
                    Subject = @{ Header = "Subject"; Width = 250 }
                    Issuer = @{ Header = "Issued By"; Width = 200 }
                    NotAfter = @{ Header = "Expires"; Width = 100 }
                }

                # Show selector (single selection only for certificates)
                $selectedThumbprint = Show-UISelectionWindow `
                                    -WindowWidth 740 `
                                    -Title "Select Certificate" `
                                    -SearchPlaceholder "Search by subject..." `
                                    -Items $displayCerts `
                                    -ColumnConfig $columnConfig `
                                    -DisplayOrder $columnConfig.Keys `
                                    -SearchProperty "Subject" `
                                    -ReturnProperty "Thumbprint"

                $syncHash.CertificateThumbprint_TextBox.Text = $selectedThumbprint
                $syncHash.CertificateThumbprint_TextBox.Foreground = [System.Windows.Media.Brushes]::Black
                $syncHash.CertificateThumbprint_TextBox.FontStyle = [System.Windows.FontStyles]::Normal
                Write-DebugOutput -Message ($syncHash.UIConfigs.localeInfoMessages.SelectedCertificateThumbprint -f $selectedThumbprint) -Source "Certificate Selection" -Level "Info"
            }
            catch {
                Write-DebugOutput -Message ($syncHash.UIConfigs.localeErrorMessages.CertificateSelectionError -f $_.Exception.Message) -Source "Certificate Selection" -Level "Error"
                [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localeErrorMessages.WindowError,
                                                "Error",
                                                [System.Windows.MessageBoxButton]::OK,
                                                [System.Windows.MessageBoxImage]::Error)

            }
        })

        # Copy Debug Logs Button
        $syncHash.CopyDebugLogsButton.Add_Click({
            try {
                $syncHash.Window.Dispatcher.Invoke([Action]{
                    if (![string]::IsNullOrWhiteSpace($syncHash.Debug_TextBox.Text)) {
                        [System.Windows.Clipboard]::SetText($syncHash.Debug_TextBox.Text)
                        [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localePopupMessages.DebugLogsCopied, "Copy Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    } else {
                        [System.Windows.MessageBox]::Show($syncHash.UIConfigs.localePopupMessages.DebugLogsNoEntries, "Nothing to Copy", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    }
                })
            }
            catch {
                # Even this must go in Dispatcher
                $syncHash.Window.Dispatcher.Invoke([Action]{
                    [System.Windows.MessageBox]::Show(($syncHash.UIConfigs.localePopupMessages.DebugLogsError -f $_.Exception.Message), "Copy Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                })
            }
        })

        If($syncHash.UIConfigs.EnableSearchAndFilter){

            # Initialize search and filter Functionality
            try {
                Show-SearchAndFilterControl
            } catch {
                Hide-SearchAndFilterControl
                Write-DebugOutput -Message "Failed to initialize search and filter: $($_.Exception.Message)" -Source "UI Initialization" -Level "Error"
            }

        }Else{
            #hide search and filter controls
            Hide-SearchAndFilterControl
            Write-DebugOutput -Message "Search and filter Functionality is disabled" -Source "UI Initialization" -Level "Info"
        }

        Initialize-HelpPopups

        #=======================================
        # CLOSE UI
        #=======================================

        # Add Loaded event once
        $syncHash.Window.Add_Loaded({
            $syncHash.isLoaded = $true
            <#
            # Initialize help popups after the window is fully loaded
            $syncHash.Window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [Action]{
                try {
                    Write-DebugOutput -Message "Initializing help popups after window load" -Source "UI Launch" -Level "Info"
                    Initialize-HelpPopups
                } catch {
                    Write-DebugOutput -Message "Error initializing help popups: $($_.Exception.Message)" -Source "UI Launch" -Level "Error"
                }
            })
            #>
        })

        # Closing event (calls Close-UIMainWindow only)
        # Events, UI setup here...
        $syncHash.Window.Add_Closing({
             $syncHash.isClosing = $true

            # Disconnect safely
            if (Get-MgContext) {
                try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch {
                    Write-Error "Error disconnecting from Microsoft Graph: $($_.Exception.Message)"
                }
            }

            # Don't call .Close() here - it’s already in the closing state
            #$syncHash.Window.Close()

            $syncHash.isClosed = $true

            # Optional: GC can be triggered here, but keep it lightweight
            #[System.GC]::Collect()
        })
        # Closed event (final GC only)
        $syncHash.Window.Add_Closed({
            try {

                #Safe to release all memory
                [System.GC]::Collect()
                #[System.GC]::WaitForPendingFinalizers()
                #[System.GC]::Collect()
            } catch {
                Write-Error "Error during final cleanup: $($_.Exception.Message)"
            }
        })

        #always force windows on top
        $syncHash.Window.Topmost = $True

        #hit esc to not force on top
        $syncHash.Window.Add_KeyDown({
            if ($_.Key -eq [System.Windows.Input.Key]::Escape) {
                $syncHash.Window.Topmost = $False
            }
        })

        #$syncHash.UIUpdateTimer.Start()

        $syncHash.Window.ShowDialog()
        $syncHash.Error = $Error
    }) # end scriptblock

    #collect data from runspace
    $Data = $syncHash
    #invoke scriptblock in runspace
    $PowerShellCommand.Runspace = $Runspace
    $AsyncHandle = $PowerShellCommand.BeginInvoke()

    # Wait for the runspace to complete (non-blocking if needed)
    $null = $PowerShellCommand.EndInvoke($AsyncHandle)

    # Now safe to clean up
    $Runspace.Close()
    $Runspace.Dispose()

    If($Passthru){
        return $Data
    }

}

#Set-Alias -Name Invoke-SCuBAConfigAppUI -Value Start-ScubaConfigAppUI -Force

Export-ModuleMember -Function @(
    'Start-ScubaConfigAppUI'
)