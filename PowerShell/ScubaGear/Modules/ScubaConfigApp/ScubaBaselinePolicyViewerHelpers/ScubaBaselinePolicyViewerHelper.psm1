# ScubaGear Baseline Policy Viewer Helper - Runspace Version
# App-independent: shared by Start-SCuBAConfigApp and Start-SCuBAConfigAnalyzer via Show-SCuBABaselinePolicyViewer.
# Provides a runspace-based baseline policy viewer with proper isolation.

Function Show-ScubaBaselinePolicyHelper {
    <#
    .SYNOPSIS
    Launches the baseline policy viewer with a clean accordion design in its own runspace.

    .PARAMETER BaselineFilePath
    The path to the ScubaBaselines.json configuration file.

    .PARAMETER NavigateToPolicyId
    Optional policy ID to navigate to automatically.

    .PARAMETER ControlConfigPath
    Optional override for the viewer control JSON (window chrome + product/section mappings).
    Defaults to this module's own ScubaBaselineViewer_Control_en-US.json, so the viewer is self-contained.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BaselineFilePath,

        [Parameter(Mandatory = $false)]
        [object]$BaselineData,

        [Parameter(Mandatory = $false)]
        [string]$NavigateToPolicyId,

        [Parameter(Mandatory = $false)]
        [string]$ControlConfigPath,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    try {
        # Require either a file path or pre-parsed data
        if (-not $BaselineData -and (-not $BaselineFilePath -or -not (Test-Path $BaselineFilePath))) {
            Write-Error "Baseline configuration file not found: $BaselineFilePath"
            return
        }

        # Self-resolve the viewer's own control file (window chrome + product/section mappings) when the
        # caller didn't override it. It lives at the module root next to the other *_Control_*.json files.
        # $PSScriptRoot is valid here (module scope); it is empty in the runspace.
        if ([string]::IsNullOrWhiteSpace($ControlConfigPath)) {
            $ControlConfigPath = Join-Path $PSScriptRoot "..\ScubaBaselineViewer_Control_en-US.json"
        }

        # Create a new runspace for the baseline viewer UI
        $viewerRunspace = [runspacefactory]::CreateRunspace()
        $viewerRunspace.ApartmentState = "STA"
        $viewerRunspace.ThreadOptions = "ReuseThread"
        $viewerRunspace.Open()

        # Pass required variables to the runspace
        $viewerRunspace.SessionStateProxy.SetVariable("BaselineFilePath", $BaselineFilePath)
        $viewerRunspace.SessionStateProxy.SetVariable("BaselineData", $BaselineData)
        $viewerRunspace.SessionStateProxy.SetVariable("NavigateToPolicyId", $NavigateToPolicyId)
        $viewerRunspace.SessionStateProxy.SetVariable("ControlConfigPath", $ControlConfigPath)

        # External XAML lives in the shared resources folder. Resolve it here - $PSScriptRoot is
        # empty inside the runspace scriptblock, so the path must be passed in.
        $viewerXamlPath = Join-Path $PSScriptRoot "..\ScubaConfigAppResources\ScubaBaselinePolicyViewerUI.xaml"
        $viewerRunspace.SessionStateProxy.SetVariable("ViewerXamlPath", $viewerXamlPath)

        # Create synchronized hashtable for cross-thread communication
        $syncHash = [hashtable]::Synchronized(@{
            Window = $null
            IsClosing = $false
            Error = $null
            NavigationQueue = [System.Collections.Queue]::Synchronized([System.Collections.Queue]::new())
            ViewerLogs = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
            LoggingEnabled = $PassThru.IsPresent
        })
        $viewerRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)

        # Import debug helper module into viewer runspace if PassThru is enabled
        if ($PassThru) {
            try {
                # Find the debug helper module relative to this module
                $debugHelperPath = Join-Path $PSScriptRoot "ScubaConfigAppDebugHelper.psm1"
                if (Test-Path $debugHelperPath) {
                    $viewerRunspace.SessionStateProxy.Path.SetLocation($PSScriptRoot)
                    $importScript = "Import-Module '$debugHelperPath' -Force -ErrorAction SilentlyContinue"
                    $viewerRunspace.SessionStateProxy.InvokeCommand.InvokeScript($importScript)
                    Write-Verbose "Debug helper module imported into viewer runspace"
                } else {
                    Write-Warning "Debug helper module not found at: $debugHelperPath. Logging will not be available."
                }
            } catch {
                Write-Warning "Failed to import debug helper into viewer runspace: $($_.Exception.Message)"
            }
        }

        # Define the main UI script block
        $uiScriptBlock = {
            try {
                # Load required assemblies
                Add-Type -AssemblyName PresentationFramework
                Add-Type -AssemblyName PresentationCore
                Add-Type -AssemblyName WindowsBase

                # Create a simple logging function if logging is enabled
                if ($syncHash.LoggingEnabled) {
                    # Create wrapper for Write-DebugOutput that works with synchronized collection
                    function Write-ViewerLog {
                        param([string]$Message, [string]$Source = "BaselineViewer", [string]$Level = "Info")
                        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                        $logEntry = "[$timestamp] [$Level] [$Source] $Message"
                        [void]$syncHash.ViewerLogs.Add($logEntry)

                        # Also try to use Write-DebugOutput if it exists (from imported module)
                        if (Get-Command Write-DebugOutput -ErrorAction SilentlyContinue) {
                            Write-DebugOutput -Message $Message -Source $Source -Level $Level
                        }
                    }

                    Write-ViewerLog "Baseline Policy Viewer started" -Level "Info"
                }

                # Load baseline data — use pre-parsed object if provided, otherwise read from file
                if ($BaselineData) {
                    $jsonData = $BaselineData
                } else {
                    $jsonData = Get-Content $BaselineFilePath -Raw | ConvertFrom-Json
                }

                # Load control configuration if provided
                $controlConfig = $null
                $policyViewerSettings = $null
                $productNames = @{}
                $allowedProductIds = @{}

                if ($ControlConfigPath -and (Test-Path $ControlConfigPath)) {
                    $controlConfig = Get-Content $ControlConfigPath -Raw | ConvertFrom-Json
                } else {
                    # Try to find the control config relative to the baseline file
                    $possiblePaths = @(
                        (Join-Path (Split-Path $BaselineFilePath -Parent) "ScubaConfigApp_Control_en-US.json"),
                        (Join-Path (Split-Path $BaselineFilePath -Parent) "..\ScubaConfigApp_Control_en-US.json")
                    )
                    foreach ($path in $possiblePaths) {
                        if (Test-Path $path) {
                            $controlConfig = Get-Content $path -Raw | ConvertFrom-Json
                            break
                        }
                    }
                }

                # Extract policy viewer settings and product mappings
                $configSampleRawOnlinePath = $null
                $repoDocsBaseUrl           = $null
                if ($controlConfig) {
                    $policyViewerSettings = $controlConfig.policyViewerSettings

                    # Single doc source: the raw online markdown path (always current with main). It is
                    # used to read the sample YAML content and to resolve the Configurable badge links.
                    $configSampleRawOnlinePath = $controlConfig.configurationSampleMarkdownRawOnlinePath
                    if ($configSampleRawOnlinePath) {
                        $rawDocsIndex = $configSampleRawOnlinePath.IndexOf("docs/")
                        if ($rawDocsIndex -ge 0) {
                            # Convert the raw base (raw.githubusercontent.com/<owner>/<repo>/refs/heads/<branch>/)
                            # to the human github.com/<owner>/<repo>/blob/<branch>/ form so badge links open a
                            # readable rendered page instead of raw markdown.
                            $rawDocsBase     = $configSampleRawOnlinePath.Substring(0, $rawDocsIndex)
                            $repoDocsBaseUrl = $rawDocsBase -replace 'raw\.githubusercontent\.com', 'github.com' -replace '/refs/heads/', '/blob/'
                        }
                    }

                    # Build product names mapping and allowed product id set from control config
                    if ($controlConfig.products) {
                        foreach ($product in $controlConfig.products) {
                            $productNames[$product.id.ToLower()] = $product.name
                            if ($product.showInViewer) {
                                $allowedProductIds[$product.id.ToLower()] = $true
                            }
                        }
                    }
                }

                # Build the JSON-driven sample-configuration map (policyId -> YAML) from the docs markdown.
                # The policy-id -> sample mapping lives in the control JSON so the docs can be reorganized
                # without editing this module.
                $sampleConfigSettings = $null
                $sampleConfigMap = @{}
                if ($policyViewerSettings -and ($policyViewerSettings.PSObject.Properties.Name -contains 'sampleConfigurationSettings')) {
                    $sampleConfigSettings = $policyViewerSettings.sampleConfigurationSettings
                }
                if ($sampleConfigSettings -and $sampleConfigSettings.samples) {
                    try {
                        # Pull the docs markdown from the raw online source (always current with main).
                        $sampleMarkdownText = $null
                        if ($configSampleRawOnlinePath) {
                            try {
                                $sampleMarkdownText = (Invoke-WebRequest -Uri $configSampleRawOnlinePath -UseBasicParsing -TimeoutSec 15).Content
                            } catch {
                                if ($syncHash.LoggingEnabled) { Write-ViewerLog "Sample configuration online fetch failed: $($_.Exception.Message)" -Level "Warning" }
                            }
                        }
                        if (-not [string]::IsNullOrWhiteSpace($sampleMarkdownText)) {
                            foreach ($sample in $sampleConfigSettings.samples) {
                                if (-not $sample.sampleName -or -not $sample.policyIds) { continue }
                                $nameIndex = $sampleMarkdownText.IndexOf($sample.sampleName)
                                if ($nameIndex -lt 0) { continue }
                                $afterName = $sampleMarkdownText.Substring($nameIndex + $sample.sampleName.Length)
                                $fenceMatch = [regex]::Match($afterName, '```(?:ya?ml)?[ \t]*\r?\n([\s\S]*?)\r?\n```')
                                if (-not $fenceMatch.Success) { continue }
                                $sampleYamlText = $fenceMatch.Groups[1].Value
                                foreach ($policyId in $sample.policyIds) {
                                    $sampleConfigMap[$policyId] = $sampleYamlText
                                }
                            }
                        }
                    } catch {
                        if ($syncHash.LoggingEnabled) { Write-ViewerLog "Sample configuration parse failed: $($_.Exception.Message)" -Level "Warning" }
                    }
                }

                # Load the viewer window from the external XAML resource. Raw load keeps x:Name
                # intact for FindName - no ScubaConfigApp-style x:Name->Name normalization needed.
                $xaml = Get-Content $ViewerXamlPath -Raw

                # Load XAML
                $reader = [System.Xml.XmlNodeReader]([xml]$xaml)
                $window = [Windows.Markup.XamlReader]::Load($reader)

                # Store window reference in syncHash
                $syncHash.Window = $window

                # Get UI controls
                $policySelector = $window.FindName("PolicySelector_ListBox")
                $filterTextBox = $window.FindName("FilterTextBox")
                $clearFilterButton = $window.FindName("ClearFilterButton")
                $placeholderText = $window.FindName("PlaceholderText")
                $criticalityFilter = $window.FindName("CriticalityFilter")
                $policyTitle = $window.FindName("PolicyTitle")
                $policyDescription = $window.FindName("PolicyDescription")
                $badgesPanel = $window.FindName("BadgesPanel")
                $policyContent = $window.FindName("PolicyContent")

                # Apply configurable window/header text from the control config (falls back to XAML defaults).
                $windowHeaderCfg = if ($policyViewerSettings -and ($policyViewerSettings.PSObject.Properties.Name -contains 'windowHeader')) { $policyViewerSettings.windowHeader } else { $null }
                if ($windowHeaderCfg) {
                    $headerTitleControl    = $window.FindName("HeaderTitle")
                    $headerSubtitleControl = $window.FindName("HeaderSubtitle")
                    if ($windowHeaderCfg.windowTitle) { $window.Title = $windowHeaderCfg.windowTitle }
                    if ($headerTitleControl -and $windowHeaderCfg.headerTitle) { $headerTitleControl.Text = $windowHeaderCfg.headerTitle }
                    if ($headerSubtitleControl -and $windowHeaderCfg.headerSubtitle) { $headerSubtitleControl.Text = $windowHeaderCfg.headerSubtitle }
                }

                # Dynamic expander storage
                $dynamicExpanders = @{}
                $dynamicContentPanels = @{}

                # Function to create dynamic expanders based on JSON configuration
                $createDynamicExpanders = {
                    if ($policyViewerSettings -and $policyViewerSettings.policyMarkdownMappings) {
                        foreach ($sectionKey in $policyViewerSettings.policyMarkdownMappings.PSObject.Properties.Name) {
                            $sectionConfig = $policyViewerSettings.policyMarkdownMappings.$sectionKey

                            # Create the expander
                            $expander = New-Object System.Windows.Controls.Expander
                            $expander.Header = $sectionConfig.displayName
                            $expander.IsExpanded = if ($null -ne $sectionConfig.isExpanded) { $sectionConfig.isExpanded } else { $false }
                            $expander.Margin = [System.Windows.Thickness]::new(0,0,0,8)

                            # Set styling from configuration
                            if ($sectionConfig.headerBackground) {
                                $expander.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($sectionConfig.headerBackground))
                            }
                            if ($sectionConfig.borderColor) {
                                $expander.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($sectionConfig.borderColor))
                            }

                            # Create header template
                            $headerTemplate = New-Object System.Windows.DataTemplate
                            $headerFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.TextBlock])
                            $headerFactory.SetValue([System.Windows.Controls.TextBlock]::TextProperty, [System.Windows.Data.Binding]::new())
                            $headerFactory.SetValue([System.Windows.Controls.TextBlock]::FontWeightProperty, [System.Windows.FontWeights]::SemiBold)
                            $headerFactory.SetValue([System.Windows.Controls.TextBlock]::FontSizeProperty, 16.0)
                            $headerFactory.SetValue([System.Windows.Controls.TextBlock]::ForegroundProperty, [System.Windows.Media.Brushes]::Black)
                            $headerFactory.SetValue([System.Windows.Controls.TextBlock]::PaddingProperty, [System.Windows.Thickness]::new(8))
                            $headerTemplate.VisualTree = $headerFactory
                            $expander.HeaderTemplate = $headerTemplate

                            # Create content border and panel
                            $contentBorder = New-Object System.Windows.Controls.Border
                            $contentBorder.Padding = [System.Windows.Thickness]::new(16)
                            $contentBorder.BorderThickness = [System.Windows.Thickness]::new(1,0,1,1)

                            if ($sectionConfig.contentBackground) {
                                $contentBorder.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($sectionConfig.contentBackground))
                            }
                            if ($sectionConfig.borderColor) {
                                $contentBorder.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($sectionConfig.borderColor))
                            }

                            $contentPanel = New-Object System.Windows.Controls.StackPanel
                            $contentBorder.Child = $contentPanel
                            $expander.Content = $contentBorder

                            # Store references
                            $dynamicExpanders[$sectionKey] = $expander
                            $dynamicContentPanels[$sectionKey] = $contentPanel

                            # Add to UI
                            [void]$policyContent.Children.Add($expander)
                        }
                    }
                }.GetNewClosure()

                # Create navigation items with expand/collapse functionality
                $allPolicyData = @{}
                $navigationItems = [System.Collections.ArrayList]::new()

                foreach ($productKey in ($jsonData.baselines | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Sort-Object)) {
                    $policies = $jsonData.baselines.$productKey
                    if (-not $policies -or $policies.Count -eq 0) { continue }

                    # Skip products not in the allowed list (showInViewer = true in control config)
                    if ($allowedProductIds.Count -gt 0 -and -not $allowedProductIds[$productKey.ToLower()]) { continue }

                    $productDisplayName = if ($productNames[$productKey]) { $productNames[$productKey] } else { $productKey.ToUpper() }

                    # Store policy data for this product
                    $allPolicyData[$productKey] = $policies

                    # Add product header (initially collapsed)
                    [void]$navigationItems.Add([PSCustomObject]@{
                        DisplayText = "$productDisplayName ($($policies.Count))"
                        TextColor = "White"
                        FontWeight = "Bold"
                        IsPolicy = $false
                        IsExpanded = $false
                        Policy = $null
                        ProductKey = $productKey
                        Type = "ProductHeader"
                    })
                }

                # Function to rebuild the navigation display based on expansion states
                $updateNavigationDisplay = {
                    param($filterText = "", $criticalityFilter = "all")

                    $displayItems = [System.Collections.ArrayList]::new()

                    foreach ($productItem in ($navigationItems | Where-Object { $_.Type -eq "ProductHeader" })) {
                        # Add the product header
                        [void]$displayItems.Add($productItem)

                        # If expanded, add the policies for this product
                        if ($productItem.IsExpanded) {
                            $policies = $allPolicyData[$productItem.ProductKey]
                            foreach ($policy in $policies) {
                                # Apply text filter if specified
                                $textMatch = [string]::IsNullOrEmpty($filterText) -or
                                    $policy.id.ToLower().Contains($filterText.ToLower()) -or
                                    $policy.name.ToLower().Contains($filterText.ToLower())

                                # Apply criticality filter
                                $criticalityMatch = $true
                                if ($criticalityFilter -ne "all") {
                                    $policyText = "$($policy.id) $($policy.name) $($policy.rationale) $($policy.implementation)".ToLower()
                                    if ($criticalityFilter -eq "shall") {
                                        $criticalityMatch = $policyText.Contains("shall")
                                    } elseif ($criticalityFilter -eq "should") {
                                        $criticalityMatch = $policyText.Contains("should")
                                    }
                                }

                                if ($textMatch -and $criticalityMatch) {

                                    [void]$displayItems.Add([PSCustomObject]@{
                                        DisplayText = "   $($policy.id)"
                                        TextColor = "#374151"
                                        FontWeight = "Normal"
                                        IsPolicy = $true
                                        IsExpanded = $false
                                        Policy = $policy
                                        ProductKey = $productItem.ProductKey
                                        Type = "Policy"
                                    })
                                }
                            }
                        }
                    }

                    $policySelector.ItemsSource = $displayItems
                }

                # Bind items to ListBox (initially all collapsed)
                #$allNavigationItems = $navigationItems
                & $updateNavigationDisplay

                # Create dynamic expanders
                & $createDynamicExpanders

                # Create the JSON-driven "Configuration Example" expander (populated per-policy from docs markdown).
                $sampleConfigExpander = $null
                $sampleConfigPanel = $null
                if ($sampleConfigSettings) {
                    $sampleConfigExpander = New-Object System.Windows.Controls.Expander
                    $sampleConfigExpander.Header = if ($sampleConfigSettings.displayName) { $sampleConfigSettings.displayName } else { "Configuration Example" }
                    $sampleConfigExpander.IsExpanded = if ($null -ne $sampleConfigSettings.isExpanded) { [bool]$sampleConfigSettings.isExpanded } else { $false }
                    $sampleConfigExpander.Margin = [System.Windows.Thickness]::new(0,0,0,8)
                    $sampleConfigExpander.Visibility = "Collapsed"
                    if ($sampleConfigSettings.headerBackground) {
                        $sampleConfigExpander.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($sampleConfigSettings.headerBackground))
                    }
                    if ($sampleConfigSettings.borderColor) {
                        $sampleConfigExpander.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($sampleConfigSettings.borderColor))
                    }

                    $sampleHeaderTemplate = New-Object System.Windows.DataTemplate
                    $sampleHeaderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.TextBlock])
                    $sampleHeaderFactory.SetValue([System.Windows.Controls.TextBlock]::TextProperty, [System.Windows.Data.Binding]::new())
                    $sampleHeaderFactory.SetValue([System.Windows.Controls.TextBlock]::FontWeightProperty, [System.Windows.FontWeights]::SemiBold)
                    $sampleHeaderFactory.SetValue([System.Windows.Controls.TextBlock]::FontSizeProperty, 16.0)
                    $sampleHeaderFactory.SetValue([System.Windows.Controls.TextBlock]::ForegroundProperty, [System.Windows.Media.Brushes]::Black)
                    $sampleHeaderFactory.SetValue([System.Windows.Controls.TextBlock]::PaddingProperty, [System.Windows.Thickness]::new(8))
                    $sampleHeaderTemplate.VisualTree = $sampleHeaderFactory
                    $sampleConfigExpander.HeaderTemplate = $sampleHeaderTemplate

                    $sampleContentBorder = New-Object System.Windows.Controls.Border
                    $sampleContentBorder.Padding = [System.Windows.Thickness]::new(16)
                    $sampleContentBorder.BorderThickness = [System.Windows.Thickness]::new(1,0,1,1)
                    if ($sampleConfigSettings.contentBackground) {
                        $sampleContentBorder.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($sampleConfigSettings.contentBackground))
                    }
                    if ($sampleConfigSettings.borderColor) {
                        $sampleContentBorder.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString($sampleConfigSettings.borderColor))
                    }
                    $sampleConfigPanel = New-Object System.Windows.Controls.StackPanel
                    $sampleContentBorder.Child = $sampleConfigPanel
                    $sampleConfigExpander.Content = $sampleContentBorder

                    # Insert the Configuration Example expander directly after the Implementation Instructions
                    # section (falls back to appending at the end if that expander isn't present).
                    $sampleInsertIndex = $policyContent.Children.Count
                    if ($dynamicExpanders.ContainsKey("implementation")) {
                        $implExpanderIndex = $policyContent.Children.IndexOf($dynamicExpanders["implementation"])
                        if ($implExpanderIndex -ge 0) { $sampleInsertIndex = $implExpanderIndex + 1 }
                    }
                    $policyContent.Children.Insert($sampleInsertIndex, $sampleConfigExpander)
                }

                # Criticality filter functionality
                $criticalityFilter.Add_SelectionChanged({
                    $selectedCriticality = if ($criticalityFilter.SelectedItem) { $criticalityFilter.SelectedItem.Tag } else { "all" }
                    $filterText = $filterTextBox.Text.ToLower().Trim()

                    if ([string]::IsNullOrEmpty($filterText) -and $selectedCriticality -eq "all") {
                        # Show normal collapsed/expanded state when no filters applied
                        & $updateNavigationDisplay
                    } else {
                        # When filtering, expand all products that have matching policies
                        #$hasMatches = $false
                        foreach ($productItem in ($navigationItems | Where-Object { $_.Type -eq "ProductHeader" })) {
                            $policies = $allPolicyData[$productItem.ProductKey]
                            $hasMatchingPolicy = $false

                            foreach ($policy in $policies) {
                                $textMatch = [string]::IsNullOrEmpty($filterText) -or
                                    $policy.id.ToLower().Contains($filterText) -or
                                    $policy.name.ToLower().Contains($filterText)

                                $criticalityMatch = $true
                                if ($selectedCriticality -ne "all") {
                                    $policyText = "$($policy.id) $($policy.name) $($policy.rationale) $($policy.implementation)".ToLower()
                                    if ($selectedCriticality -eq "shall") {
                                        $criticalityMatch = $policyText.Contains("shall")
                                    } elseif ($selectedCriticality -eq "should") {
                                        $criticalityMatch = $policyText.Contains("should")
                                    }
                                }

                                if ($textMatch -and $criticalityMatch) {
                                    $hasMatchingPolicy = $true
                                    #$hasMatches = $true
                                    break
                                }
                            }

                            # Temporarily expand products that have matches
                            if ($hasMatchingPolicy) {
                                $productItem.IsExpanded = $true
                            }
                        }

                        & $updateNavigationDisplay $filterText $selectedCriticality
                        #$clearFilterButton.Visibility = if ($hasMatches) { "Visible" } else { "Collapsed" }
                    }
                }.GetNewClosure())

                # Filter functionality with expand/collapse support
                $filterTextBox.Add_TextChanged({
                    $filterText = $filterTextBox.Text.ToLower().Trim()
                    $selectedCriticality = if ($criticalityFilter.SelectedItem) { $criticalityFilter.SelectedItem.Tag } else { "all" }

                    # Handle placeholder visibility
                    if ([string]::IsNullOrEmpty($filterTextBox.Text)) {
                        $placeholderText.Visibility = "Visible"
                    } else {
                        $placeholderText.Visibility = "Hidden"
                    }

                    if ([string]::IsNullOrEmpty($filterText) -and $selectedCriticality -eq "all") {
                        # Show normal collapsed/expanded state when no filters applied
                        & $updateNavigationDisplay
                        $clearFilterButton.Visibility = "Collapsed"
                    } else {
                        # When filtering, expand all products that have matching policies
                        $hasMatches = $false
                        foreach ($productItem in ($navigationItems | Where-Object { $_.Type -eq "ProductHeader" })) {
                            $policies = $allPolicyData[$productItem.ProductKey]
                            $hasMatchingPolicy = $false

                            foreach ($policy in $policies) {
                                $textMatch = [string]::IsNullOrEmpty($filterText) -or
                                    $policy.id.ToLower().Contains($filterText) -or
                                    $policy.name.ToLower().Contains($filterText)

                                $criticalityMatch = $true
                                if ($selectedCriticality -ne "all") {
                                    $policyText = "$($policy.id) $($policy.name) $($policy.rationale) $($policy.implementation)".ToLower()
                                    if ($selectedCriticality -eq "shall") {
                                        $criticalityMatch = $policyText.Contains("shall")
                                    } elseif ($selectedCriticality -eq "should") {
                                        $criticalityMatch = $policyText.Contains("should")
                                    }
                                }

                                if ($textMatch -and $criticalityMatch) {
                                    $hasMatchingPolicy = $true
                                    $hasMatches = $true
                                    break
                                }
                            }

                            # Temporarily expand products that have matches
                            if ($hasMatchingPolicy) {
                                $productItem.IsExpanded = $true
                            }
                        }

                        & $updateNavigationDisplay $filterText $selectedCriticality
                        $clearFilterButton.Visibility = if ($hasMatches) { "Visible" } else { "Collapsed" }
                    }
                }.GetNewClosure())

                # Handle filter textbox focus events for better UX
                $filterTextBox.Add_GotFocus({
                    if ([string]::IsNullOrEmpty($filterTextBox.Text)) {
                        $placeholderText.Visibility = "Hidden"
                    }
                }.GetNewClosure())

                $filterTextBox.Add_LostFocus({
                    if ([string]::IsNullOrEmpty($filterTextBox.Text)) {
                        $placeholderText.Visibility = "Visible"
                    }
                }.GetNewClosure())

                # Clear filter button
                $clearFilterButton.Add_Click({
                    $filterTextBox.Text = ""
                    $criticalityFilter.SelectedIndex = 0  # Reset to "All"
                    # Restore original expansion states (all collapsed)
                    foreach ($productItem in ($navigationItems | Where-Object { $_.Type -eq "ProductHeader" })) {
                        $productItem.IsExpanded = $false
                        $productDisplayName = if ($productNames[$productItem.ProductKey]) { $productNames[$productItem.ProductKey] } else { $productItem.ProductKey.ToUpper() }
                        $policies = $allPolicyData[$productItem.ProductKey]
                        $productItem.DisplayText = "$productDisplayName ($($policies.Count))"
                    }
                    & $updateNavigationDisplay
                    $filterTextBox.Focus()
                }.GetNewClosure())

                # Helper function to create TextBlock with both bold formatting and markdown link support
                $createTextBlockWithFormatting = {
                    param($text, $margin = "0,4,0,4")

                    # Check if this is a note (starts with > or >>)
                    $isNote = $text -match '^\s*>{1,2}\s'

                    if ($isNote) {
                        # Create a border container for notes
                        $border = New-Object System.Windows.Controls.Border
                        $border.Background = [System.Windows.Media.Brushes]::LightBlue
                        $border.BorderBrush = [System.Windows.Media.Brushes]::DodgerBlue
                        $border.BorderThickness = "2,0,0,0"
                        $border.Padding = "12,8,12,8"
                        $border.Margin = $margin

                        # Remove the > or >> prefix from the text
                        $cleanText = $text -replace '^\s*>{1,2}\s*', ''

                        # Create the text block for the note content
                        $noteTextBlock = New-Object System.Windows.Controls.TextBlock
                        $noteTextBlock.TextWrapping = "Wrap"
                        $noteTextBlock.FontStyle = "Italic"
                        $noteTextBlock.Foreground = [System.Windows.Media.Brushes]::DarkBlue

                        # Process the cleaned text for formatting
                        & $processTextContent $cleanText $noteTextBlock

                        $border.Child = $noteTextBlock
                        return $border
                    } else {
                        # Regular text block
                        $textBlock = New-Object System.Windows.Controls.TextBlock
                        $textBlock.TextWrapping = "Wrap"
                        $textBlock.Margin = $margin

                        & $processTextContent $text $textBlock

                        return $textBlock
                    }
                }

                # Helper function to process text content for all formatting types
                $processTextContent = {
                    param($text, $textBlock)

                    # First, handle multiline markdown links specifically (without affecting other newlines)
                    $multilineLinkPattern = '\[([^\]]*?)\r?\n([^\]]*?)\]\s*\(([^)]*?)\)'
                    $text = [regex]::Replace($text, $multilineLinkPattern, {
                        param($match)
                        $linkText = ($match.Groups[1].Value + $match.Groups[2].Value) -replace '\s+', ' '
                        $linkUrl = $match.Groups[3].Value -replace '\s+', ''
                        "[$($linkText.Trim())]($($linkUrl.Trim()))"
                    }, [System.Text.RegularExpressions.RegexOptions]::Multiline)

                    # Also handle links that might span more than 2 lines
                    $extendedMultilineLinkPattern = '\[([\s\S]*?)\]\s*\(([\s\S]*?)\)'
                    $text = [regex]::Replace($text, $extendedMultilineLinkPattern, {
                        param($match)
                        $linkText = $match.Groups[1].Value -replace '\r?\n\s*', ' ' -replace '\s+', ' '
                        $linkUrl = $match.Groups[2].Value -replace '\r?\n\s*', '' -replace '\s+', ''
                        # Only apply if this actually contains newlines (to avoid affecting normal links)
                        if ($match.Groups[0].Value -match '\r?\n') {
                            "[$($linkText.Trim())]($($linkUrl.Trim()))"
                        } else {
                            $match.Groups[0].Value
                        }
                    }, [System.Text.RegularExpressions.RegexOptions]::Singleline)

                    # Handle escaped pipe characters
                    $text = $text -replace '\\\|', '|'

                    # Convert standalone URLs to markdown links (but preserve existing markdown links)
                    $urlPattern = '(?<!\]\()(https?://[^\s\)]+)(?!\))'
                    $text = [regex]::Replace($text, $urlPattern, '[$1]($1)')

                    # Process <pre> blocks separately to handle <b> tags inside them
                    $prePattern = '<pre>(.*?)</pre>'
                    $preMatches = [regex]::Matches($text, $prePattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

                    if ($preMatches.Count -gt 0) {
                        $lastIndex = 0
                        foreach ($preMatch in $preMatches) {
                            # Add text before the <pre> block
                            if ($preMatch.Index -gt $lastIndex) {
                                $beforeText = $text.Substring($lastIndex, $preMatch.Index - $lastIndex)
                                if ($beforeText.Trim()) {
                                    & $processRegularText $beforeText $textBlock
                                }
                            }

                            # Process the <pre> block content
                            $preContent = $preMatch.Groups[1].Value
                            & $processPreformattedText $preContent $textBlock

                            $lastIndex = $preMatch.Index + $preMatch.Length
                        }

                        # Add remaining text after the last <pre> block
                        if ($lastIndex -lt $text.Length) {
                            $remainingText = $text.Substring($lastIndex)
                            if ($remainingText.Trim()) {
                                & $processRegularText $remainingText $textBlock
                            }
                        }
                    } else {
                        # No <pre> blocks, process normally
                        & $processRegularText $text $textBlock
                    }
                }

                # Helper function to process preformatted text (handles <b> tags in <pre> blocks)
                $processPreformattedText = {
                    param($text, $textBlock)

                    # Create a border container for the entire pre block
                    $border = New-Object System.Windows.Controls.Border
                    $border.Background = [System.Windows.Media.Brushes]::LightGray
                    $border.BorderBrush = [System.Windows.Media.Brushes]::Gray
                    $border.BorderThickness = "1"
                    $border.Padding = "12"
                    $border.Margin = "8,4,8,8"
                    $border.CornerRadius = "4"

                    # Create a TextBlock for the pre content
                    $preTextBlock = New-Object System.Windows.Controls.TextBlock
                    $preTextBlock.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas,Monaco,Lucida Console,monospace")
                    $preTextBlock.FontSize = 12
                    $preTextBlock.TextWrapping = "Wrap"

                    # Handle <b> tags within preformatted text
                    $boldPattern = '<b>(.*?)</b>'
                    $lastIndex = 0
                    $boldmatches = [regex]::Matches($text, $boldPattern)

                    foreach ($match in $boldmatches) {
                        # Add text before the bold
                        if ($match.Index -gt $lastIndex) {
                            $beforeText = $text.Substring($lastIndex, $match.Index - $lastIndex)
                            if ($beforeText) {
                                $run = New-Object System.Windows.Documents.Run($beforeText)
                                [void]$preTextBlock.Inlines.Add($run)
                            }
                        }

                        # Add the bold text
                        $boldText = $match.Groups[1].Value
                        $boldRun = New-Object System.Windows.Documents.Run($boldText)
                        $boldRun.FontWeight = "Bold"
                        [void]$preTextBlock.Inlines.Add($boldRun)

                        $lastIndex = $match.Index + $match.Length
                    }

                    # Add any remaining text
                    if ($lastIndex -lt $text.Length) {
                        $remainingText = $text.Substring($lastIndex)
                        if ($remainingText) {
                            $run = New-Object System.Windows.Documents.Run($remainingText)
                            [void]$preTextBlock.Inlines.Add($run)
                        }
                    }

                    # If no bold tags found, add the entire text
                    if ($boldmatches.Count -eq 0) {
                        $run = New-Object System.Windows.Documents.Run($text)
                        [void]$preTextBlock.Inlines.Add($run)
                    }

                    # Add the TextBlock to the border, then add border to main TextBlock
                    $border.Child = $preTextBlock

                    # Create a container to hold the border (since TextBlock.Inlines can't hold Border directly)
                    $inlineUIContainer = New-Object System.Windows.Documents.InlineUIContainer
                    $inlineUIContainer.Child = $border
                    [void]$textBlock.Inlines.Add($inlineUIContainer)

                    # Add line breaks around the pre block
                    [void]$textBlock.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
                }

                # Helper function to process regular text (handles all formatting)
                $processRegularText = {
                    param($text, $textBlock)

                    # Combined pattern for markdown bold **text**, italic _text_, HTML bold <b>text</b>, and markdown links [text](url)
                    $combinedPattern = '(\[([^\]]+)\]\(([^\)]+)\))|(\*\*([^*]+)\*\*)|(_([^_]+)_)|(<b>([^<]*)</b>)'
                    $lastIndex = 0
                    $formatMatches = [regex]::Matches($text, $combinedPattern)

                    foreach ($match in $formatMatches) {
                        # Add text before this match
                        if ($match.Index -gt $lastIndex) {
                            $beforeText = $text.Substring($lastIndex, $match.Index - $lastIndex)
                            if ($beforeText) {
                                $run = New-Object System.Windows.Documents.Run($beforeText)
                                [void]$textBlock.Inlines.Add($run)
                            }
                        }

                        if ($match.Groups[1].Success) {
                            # This is a markdown link [text](url)
                            $linkText = $match.Groups[2].Value
                            $linkUrl = $match.Groups[3].Value

                            try {
                                $hyperlink = New-Object System.Windows.Documents.Hyperlink
                                $hyperlink.NavigateUri = [Uri]$linkUrl
                                $hyperlink.Foreground = [System.Windows.Media.Brushes]::DodgerBlue
                                $hyperlink.TextDecorations = [System.Windows.TextDecorations]::Underline

                                $linkRun = New-Object System.Windows.Documents.Run($linkText)
                                [void]$hyperlink.Inlines.Add($linkRun)

                                $hyperlink.Add_RequestNavigate({
                                    param($eventSender, $eventData)
                                    try {
                                        $null = $eventSender
                                        $url = $eventData.Uri.AbsoluteUri

                                        # Detect internal policy cross-reference links by extracting the policy ID
                                        # directly from the link text (e.g. "MS.SECURITYSUITE.3.1v1 Instructions").
                                        # This is more reliable than parsing the markdown anchor in the URL.
                                        $internalPolicyId = $null
                                        if ($linkText -match '(MS\.[A-Z0-9]+\.\d+\.\d+v\d+)') {
                                            $internalPolicyId = $matches[1]
                                        }

                                        if ($internalPolicyId) {
                                            # Find the product that owns this policy
                                            $targetProductKey = $null
                                            foreach ($productKey in $allPolicyData.Keys) {
                                                foreach ($policy in $allPolicyData[$productKey]) {
                                                    if ($policy.id -eq $internalPolicyId) {
                                                        $targetProductKey = $productKey
                                                        break
                                                    }
                                                }
                                                if ($targetProductKey) { break }
                                            }

                                            if ($targetProductKey) {
                                                # Ensure the product group is expanded so the policy is in the ListBox
                                                $productHeader = $navigationItems | Where-Object { $_.Type -eq "ProductHeader" -and $_.ProductKey -eq $targetProductKey }
                                                if ($productHeader -and -not $productHeader.IsExpanded) {
                                                    $productHeader.IsExpanded = $true
                                                }
                                                & $updateNavigationDisplay

                                                # Select the policy and scroll it into view
                                                foreach ($item in $policySelector.Items) {
                                                    if ($item.Type -eq "Policy" -and $item.Policy -and $item.Policy.id -eq $internalPolicyId) {
                                                        $policySelector.SelectedItem = $item
                                                        $policySelector.ScrollIntoView($item)
                                                        break
                                                    }
                                                }
                                            }
                                            $eventData.Handled = $true
                                        } else {
                                            # Regular external link - open in browser
                                            [System.Diagnostics.Process]::Start($url)
                                            $eventData.Handled = $true
                                        }
                                    } catch { $null }
                                }.GetNewClosure())

                                [void]$textBlock.Inlines.Add($hyperlink)
                            } catch {
                                # If URL is malformed, add as plain text
                                $run = New-Object System.Windows.Documents.Run("[$linkText]($linkUrl)")
                                [void]$textBlock.Inlines.Add($run)
                            }
                        }
                        elseif ($match.Groups[4].Success) {
                            # This is markdown bold **text**
                            $boldText = $match.Groups[5].Value
                            $boldRun = New-Object System.Windows.Documents.Run($boldText)
                            $boldRun.FontWeight = "Bold"
                            [void]$textBlock.Inlines.Add($boldRun)
                        }
                        elseif ($match.Groups[6].Success) {
                            # This is markdown italic _text_
                            $italicText = $match.Groups[7].Value
                            $italicRun = New-Object System.Windows.Documents.Run($italicText)
                            $italicRun.FontStyle = "Italic"
                            [void]$textBlock.Inlines.Add($italicRun)
                        }
                        elseif ($match.Groups[8].Success) {
                            # This is HTML bold <b>text</b>
                            $boldText = $match.Groups[9].Value
                            $boldRun = New-Object System.Windows.Documents.Run($boldText)
                            $boldRun.FontWeight = "Bold"
                            [void]$textBlock.Inlines.Add($boldRun)
                        }

                        $lastIndex = $match.Index + $match.Length
                    }

                    # Add any remaining text after the last match (or all text if no matches)
                    if ($lastIndex -lt $text.Length) {
                        $remainingText = $text.Substring($lastIndex)
                        if ($remainingText) {
                            $run = New-Object System.Windows.Documents.Run($remainingText)
                            [void]$textBlock.Inlines.Add($run)
                        }
                    }
                }

                # Handle selection changes
                $policySelector.Add_SelectionChanged({
                    $selectedItem = $policySelector.SelectedItem

                    if ($selectedItem) {
                        if ($selectedItem.Type -eq "ProductHeader") {
                            # Toggle expansion for product header
                            $selectedItem.IsExpanded = -not $selectedItem.IsExpanded

                            # Update display text without arrows
                            $productDisplayName = if ($productNames[$selectedItem.ProductKey]) { $productNames[$selectedItem.ProductKey] } else { $selectedItem.ProductKey.ToUpper() }
                            $policies = $allPolicyData[$selectedItem.ProductKey]
                            $selectedItem.DisplayText = "$productDisplayName ($($policies.Count))"

                            # Update the navigation display
                            & $updateNavigationDisplay $filterTextBox.Text.ToLower().Trim()

                            # Clear selection so the same product can be clicked again
                            $policySelector.SelectedItem = $null
                        }
                        elseif ($selectedItem.IsPolicy) {
                            # Handle policy selection
                            $selectedPolicy = $selectedItem.Policy

                        # Update header
                        $policyTitle.Text = $selectedPolicy.id
                        $policyDescription.Text = $selectedPolicy.name

                        # Clear all content from dynamic panels (policy-specific content only)
                        [void]$badgesPanel.Children.Clear()
                        foreach ($panel in $dynamicContentPanels.Values) {
                            [void]$panel.Children.Clear()
                        }

                        # Update expander headers and visibility for policy content
                        & $updateExpanderHeadersAndVisibility "policy" $selectedPolicy



                        # Populate dynamic content based on configuration
                        if ($policyViewerSettings -and $policyViewerSettings.policyMarkdownMappings) {
                            foreach ($sectionKey in $policyViewerSettings.policyMarkdownMappings.PSObject.Properties.Name) {
                                $sectionConfig = $policyViewerSettings.policyMarkdownMappings.$sectionKey
                                $contentPanel = $dynamicContentPanels[$sectionKey]

                                if ($contentPanel) {
                                    # Handle array or single property
                                    $jsonProperties = if ($sectionConfig.jsonProperty -is [array]) {
                                        $sectionConfig.jsonProperty
                                    } else {
                                        @($sectionConfig.jsonProperty)
                                    }

                                    # Log processing
                                    if ($syncHash.LoggingEnabled) {
                                        Write-ViewerLog "Processing section: $sectionKey, jsonProperties count: $($jsonProperties.Count), Panel has $($contentPanel.Children.Count) children before processing" -Level "Debug"
                                    }

                                    foreach ($jsonProp in $jsonProperties) {
                                        # Completely dynamic content handling - no hardcoded property names
                                        $propertyData = $selectedPolicy.$jsonProp

                                        if ($propertyData) {
                                            # Log property processing
                                            if ($syncHash.LoggingEnabled) {
                                                $dataType = if ($propertyData -is [array]) { "Array[$($propertyData.Count)]" } else { "String" }
                                                Write-ViewerLog "  Property '$jsonProp' in section '$sectionKey' -> Type: $dataType" -Level "Debug"
                                            }

                                            # Handle different data types dynamically
                                            if ($propertyData -is [array] -and $propertyData.Count -gt 0) {
                                                # Handle all arrays the same way - check each item
                                                foreach ($item in $propertyData) {
                                                    if ($item.Url -and $item.Name) {
                                                        # Handle link objects (resources, mitreMapping)
                                                        $linkBlock = New-Object System.Windows.Controls.TextBlock
                                                        $hyperlink = New-Object System.Windows.Documents.Hyperlink
                                                        $hyperlink.NavigateUri = [Uri]$item.Url
                                                        $hyperlink.Foreground = [System.Windows.Media.Brushes]::DodgerBlue

                                                        $itemName = $item.Name -replace '\r?\n\s*', ' ' -replace '\s+', ' ' -replace '\\\|', '|'
                                                        [void]$hyperlink.Inlines.Add((New-Object System.Windows.Documents.Run($itemName.Trim())))

                                                        $hyperlink.Add_RequestNavigate({
                                                            param($eventSender, $eventData)
                                                            try {
                                                                $null = $eventSender
                                                                [System.Diagnostics.Process]::Start($eventData.Uri.AbsoluteUri)
                                                                $eventData.Handled = $true
                                                            } catch { $null}
                                                        })

                                                        [void]$linkBlock.Inlines.Add((New-Object System.Windows.Documents.Run("• ")))
                                                        [void]$linkBlock.Inlines.Add($hyperlink)

                                                        $linkBlock.Margin = "0,2,0,2"
                                                        [void]$contentPanel.Children.Add($linkBlock)
                                                    } elseif ($item -is [string] -and -not [string]::IsNullOrWhiteSpace($item)) {
                                                        # Handle string items (licenseRequirements, etc.) - display each as separate bullet with markdown support
                                                        if ($syncHash.LoggingEnabled) {
                                                            Write-ViewerLog "    Adding bullet item to '$sectionKey': $item" -Level "Debug"
                                                        }
                                                        $bulletContent = "• $item"
                                                        $bulletText = & $createTextBlockWithFormatting $bulletContent "0,2,0,2"
                                                        [void]$contentPanel.Children.Add($bulletText)
                                                    }
                                                }
                                            #} elseif ($propertyData -is [string] -and -not [string]::IsNullOrWhiteSpace($propertyData) -and $propertyData -ne "N/A") {
                                            } elseif ($propertyData -is [string] -and -not [string]::IsNullOrWhiteSpace($propertyData)) {
                                                # Handle string data (text content, markdown, etc.)
                                                $contentText = & $createTextBlockWithFormatting $propertyData "0,0,0,4"
                                                [void]$contentPanel.Children.Add($contentText)
                                            }
                                        }
                                    }

                                    # Log final child count
                                    if ($syncHash.LoggingEnabled) {
                                        Write-ViewerLog "  Final: section '$sectionKey' panel has $($contentPanel.Children.Count) children after processing" -Level "Debug"
                                    }

                                    # Add "no content" message if panel is still empty
                                    if ($contentPanel.Children.Count -eq 0) {
                                        $noContentText = New-Object System.Windows.Controls.TextBlock
                                        $noContentText.Text = "No content available for this section."
                                        $noContentText.FontStyle = "Italic"
                                        $noContentText.Foreground = [System.Windows.Media.Brushes]::Gray
                                        [void]$contentPanel.Children.Add($noContentText)
                                    }
                                }
                            }
                        }

                        # Populate the JSON-driven Configuration Example expander for this policy.
                        if ($sampleConfigExpander -and $sampleConfigPanel) {
                            [void]$sampleConfigPanel.Children.Clear()
                            $sampleYaml = $sampleConfigMap[$selectedPolicy.id]
                            if (-not [string]::IsNullOrWhiteSpace($sampleYaml)) {
                                if ($sampleConfigSettings.introText) {
                                    $sampleIntro = New-Object System.Windows.Controls.TextBlock
                                    $sampleIntro.Text = $sampleConfigSettings.introText
                                    $sampleIntro.TextWrapping = "Wrap"
                                    $sampleIntro.Margin = "0,0,0,8"
                                    [void]$sampleConfigPanel.Children.Add($sampleIntro)
                                }
                                $sampleCodeBorder = New-Object System.Windows.Controls.Border
                                $sampleCodeBorder.Background = [System.Windows.Media.Brushes]::WhiteSmoke
                                $sampleCodeBorder.BorderBrush = [System.Windows.Media.Brushes]::Gainsboro
                                $sampleCodeBorder.BorderThickness = "1"
                                $sampleCodeBorder.Padding = "12"
                                $sampleCodeBorder.CornerRadius = "4"
                                $sampleScroll = New-Object System.Windows.Controls.ScrollViewer
                                $sampleScroll.HorizontalScrollBarVisibility = "Auto"
                                $sampleScroll.VerticalScrollBarVisibility = "Disabled"
                                $sampleCodeText = New-Object System.Windows.Controls.TextBlock
                                $sampleCodeText.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas,Monaco,Lucida Console,monospace")
                                $sampleCodeText.FontSize = 12
                                $sampleCodeText.TextWrapping = "NoWrap"
                                $sampleCodeText.Text = $sampleYaml
                                $sampleScroll.Content = $sampleCodeText
                                $sampleCodeBorder.Child = $sampleScroll
                                [void]$sampleConfigPanel.Children.Add($sampleCodeBorder)
                                $sampleConfigExpander.Visibility = "Visible"
                            } else {
                                $sampleConfigExpander.Visibility = "Collapsed"
                            }
                        }

                        if ($selectedPolicy.badges -and $selectedPolicy.badges.Count -gt 0) {
                            foreach ($badge in $selectedPolicy.badges) {
                                $badgeButton = New-Object System.Windows.Controls.Button
                                $badgeButton.Content = $badge.label
                                $badgeButton.FontSize = 11
                                $badgeButton.FontWeight = "SemiBold"
                                $badgeButton.Foreground = "White"
                                $badgeButton.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.ColorConverter]::ConvertFromString("#$($badge.color)"))
                                $badgeButton.BorderThickness = 0
                                $badgeButton.Padding = "8,4"
                                $badgeButton.Margin = "0,0,8,0"
                                $badgeButton.Cursor = "Hand"

                                if ($badge.linkUrl -and $badge.linkUrl.StartsWith("http")) {
                                    $badgeButton.Add_Click({
                                        param($eventsender, $eventData)
                                        try {
                                            $badgeData = $eventsender.Tag
                                            [System.Diagnostics.Process]::Start($badgeData.linkUrl)
                                            $eventData.Handled = $true
                                        } catch { $null}
                                    }.GetNewClosure())
                                    $badgeButton.Tag = $badge
                                } elseif ($badge.linkUrl) {
                                    # Resolve relative doc links (e.g. ../../../docs/configuration/configuration.md#anchor)
                                    # to a clickable URL using the repo docs base derived from the control JSON, so the
                                    # Configurable badge navigates to the right documentation section.
                                    $docsBaseUrl = $repoDocsBaseUrl
                                    $docsIndex = $badge.linkUrl.IndexOf("docs/")
                                    if ($docsBaseUrl -and $docsIndex -ge 0) {
                                        $resolvedBadgeUrl = $docsBaseUrl.TrimEnd('/') + "/" + $badge.linkUrl.Substring($docsIndex)
                                        $badgeButton.Tag = [PSCustomObject]@{ linkUrl = $resolvedBadgeUrl }
                                        $badgeButton.Add_Click({
                                            param($eventsender, $eventData)
                                            try {
                                                $badgeData = $eventsender.Tag
                                                [System.Diagnostics.Process]::Start($badgeData.linkUrl)
                                                $eventData.Handled = $true
                                            } catch { $null}
                                        }.GetNewClosure())
                                    }
                                }

                                [void]$badgesPanel.Children.Add($badgeButton)
                            }
                        }
                        }
                    }
                }.GetNewClosure())

                # Function to display default content (Introduction and Key Terminology)
                $showDefaultContent = {
                    # Update header for default content - use configuration from JSON
                    if ($policyViewerSettings -and $policyViewerSettings.defaultContentHeaders) {
                        $policyTitle.Text = $policyViewerSettings.defaultContentHeaders.title
                        $policyDescription.Text = $policyViewerSettings.defaultContentHeaders.description
                    }

                    # Clear all content from dynamic panels
                    [void]$badgesPanel.Children.Clear()
                    foreach ($panel in $dynamicContentPanels.Values) {
                        [void]$panel.Children.Clear()
                    }

                    # Hide the per-policy Configuration Example expander on the default (non-policy) view.
                    if ($sampleConfigExpander) {
                        $sampleConfigExpander.Visibility = "Collapsed"
                        if ($sampleConfigPanel) { [void]$sampleConfigPanel.Children.Clear() }
                    }

                    # Update expander headers and visibility for main content
                    & $updateExpanderHeadersAndVisibility "main" $jsonData

                    # Helper function to create TextBlock with markdown link parsing and bold formatting
                    $createTextBlockWithLinks = {
                        param($text)
                        return & $createTextBlockWithFormatting $text
                    }

                    # Dynamic content mapping using mainMarkdownMappings (completely dynamic - no hardcoded properties)
                    if ($policyViewerSettings -and $policyViewerSettings.mainMarkdownMappings) {
                        foreach ($sectionKey in $policyViewerSettings.mainMarkdownMappings.PSObject.Properties.Name) {
                            $sectionConfig = $policyViewerSettings.mainMarkdownMappings.$sectionKey

                            # Use the same dynamic panel system but with main content mappings
                            # This ensures the expanders are populated with default content using the same structure
                            $contentPanel = $dynamicContentPanels[$sectionKey]

                            if ($contentPanel) {
                                # Handle array or single property dynamically (same as policy system)
                                $jsonProperties = if ($sectionConfig.jsonProperty -is [array]) {
                                    $sectionConfig.jsonProperty
                                } else {
                                    @($sectionConfig.jsonProperty)
                                }

                                foreach ($jsonProp in $jsonProperties) {
                                    # Completely dynamic content handling - access jsonData properties by name
                                    $propertyData = $jsonData.$jsonProp

                                    if ($propertyData -and -not [string]::IsNullOrWhiteSpace($propertyData)) {
                                        # Split content into paragraphs and add to panel
                                        $paragraphs = $propertyData -split "`r?`n`r?`n"
                                        foreach ($paragraph in $paragraphs) {
                                            if (-not [string]::IsNullOrWhiteSpace($paragraph)) {
                                                $paraText = & $createTextBlockWithLinks $paragraph.Trim()
                                                [void]$contentPanel.Children.Add($paraText)
                                            }
                                        }
                                    }
                                }

                                # Add "no content" message if panel is empty after processing all properties
                                if ($contentPanel.Children.Count -eq 0) {
                                    $noContentText = New-Object System.Windows.Controls.TextBlock
                                    $noContentText.Text = "No content available for this section."
                                    $noContentText.FontStyle = "Italic"
                                    $noContentText.Foreground = [System.Windows.Media.Brushes]::Gray
                                    [void]$contentPanel.Children.Add($noContentText)
                                }
                            }
                        }
                    }
                }.GetNewClosure()

                # Function to update expander headers and visibility based on content type
                $updateExpanderHeadersAndVisibility = {
                    param($mappingType, $dataSource)

                    $mappings = if ($mappingType -eq "main") {
                        $policyViewerSettings.mainMarkdownMappings
                    } else {
                        $policyViewerSettings.policyMarkdownMappings
                    }

                    # Update each expander
                    foreach ($sectionKey in $dynamicExpanders.Keys) {
                        $expander = $dynamicExpanders[$sectionKey]
                        #$contentPanel = $dynamicContentPanels[$sectionKey]

                        if ($mappings -and $mappings.$sectionKey) {
                            # Update header and show expander
                            # For section expander, use dynamic content from policySection if available
                            if ($sectionKey -eq "section" -and $mappingType -eq "policy" -and $dataSource.policySection) {
                                $expander.Header = $dataSource.policySection
                            } else {
                                $expander.Header = $mappings.$sectionKey.displayName
                            }
                            $expander.Visibility = "Visible"

                            # Check if there's actual content for this section
                            $hasContent = $false
                            $jsonProperties = if ($mappings.$sectionKey.jsonProperty -is [array]) {
                                $mappings.$sectionKey.jsonProperty
                            } else {
                                @($mappings.$sectionKey.jsonProperty)
                            }

                            foreach ($jsonProp in $jsonProperties) {
                                $propertyData = $dataSource.$jsonProp
                                if ($propertyData) {
                                    # Check for arrays with content
                                    if ($propertyData -is [array] -and $propertyData.Count -gt 0) {
                                        $hasContent = $true
                                        break
                                    }
                                    # Check for non-empty strings
                                    elseif (-not ($propertyData -is [array]) -and -not [string]::IsNullOrWhiteSpace($propertyData)) {
                                        $hasContent = $true
                                        break
                                    }
                                }
                            }

                            # Hide expander if no content exists
                            if (-not $hasContent) {
                                $expander.Visibility = "Collapsed"
                            }
                        } else {
                            # Hide expanders that don't exist in current mapping
                            $expander.Visibility = "Collapsed"
                        }
                    }
                }.GetNewClosure()

                # Remove the problematic expansion handlers that collapse other sections
                # Users should be able to expand multiple sections simultaneously

                # Display default content on startup
                & $showDefaultContent

                # Add timer to check for navigation commands from external sources
                $navigationTimer = New-Object System.Windows.Threading.DispatcherTimer
                $navigationTimer.Interval = [TimeSpan]::FromMilliseconds(500)
                $navigationTimer.Add_Tick({
                    try {
                        while ($syncHash.NavigationQueue.Count -gt 0) {
                            $targetPolicyId = $syncHash.NavigationQueue.Dequeue()
                            Write-Host "Processing navigation request to policy: $targetPolicyId"

                            # Find and navigate to the policy
                            $foundPolicy = $null
                            $foundProductKey = $null

                            foreach ($productKey in $allPolicyData.Keys) {
                                $policies = $allPolicyData[$productKey]
                                foreach ($policy in $policies) {
                                    if ($policy.id -eq $targetPolicyId) {
                                        $foundPolicy = $policy
                                        $foundProductKey = $productKey
                                        break
                                    }
                                }
                                if ($foundPolicy) { break }
                            }

                            if ($foundPolicy) {
                                # Expand the product header
                                $productItem = $navigationItems | Where-Object { $_.Type -eq "ProductHeader" -and $_.ProductKey -eq $foundProductKey }
                                if ($productItem) {
                                    $productItem.IsExpanded = $true
                                    & $updateNavigationDisplay

                                    # Select the policy
                                    $displayedItems = $policySelector.ItemsSource
                                    $policyItem = $displayedItems | Where-Object { $_.IsPolicy -and $_.Policy.id -eq $targetPolicyId }
                                    if ($policyItem) {
                                        $policySelector.SelectedItem = $policyItem
                                        $policySelector.ScrollIntoView($policyItem)
                                        Write-Host "Navigated to policy: $targetPolicyId"
                                    }
                                }
                            } else {
                                Write-Warning "Policy not found for navigation: $targetPolicyId"
                            }
                        }
                    } catch {
                        Write-Warning "Error processing navigation: $($_.Exception.Message)"
                    }
                }.GetNewClosure())
                $navigationTimer.Start()

                # Handle navigation to specific policy if requested
                if (-not [string]::IsNullOrWhiteSpace($NavigateToPolicyId)) {
                    $window.Add_Loaded({
                        try {
                            Write-Host "Searching for policy: $NavigateToPolicyId"

                            # Find the policy in the data and expand its product
                            $foundPolicy = $null
                            $foundProductKey = $null

                            foreach ($productKey in $allPolicyData.Keys) {
                                $policies = $allPolicyData[$productKey]
                                foreach ($policy in $policies) {
                                    if ($policy.id -eq $NavigateToPolicyId) {
                                        $foundPolicy = $policy
                                        $foundProductKey = $productKey
                                        break
                                    }
                                }
                                if ($foundPolicy) { break }
                            }

                            if ($foundPolicy) {
                                Write-Host "Found policy in product: $foundProductKey"

                                # Find and expand the product header
                                $productItem = $navigationItems | Where-Object { $_.Type -eq "ProductHeader" -and $_.ProductKey -eq $foundProductKey }
                                if ($productItem) {
                                    $productItem.IsExpanded = $true

                                    # Update the display to show expanded policies
                                    & $updateNavigationDisplay

                                    # Find the policy item in the displayed items
                                    $displayedItems = $policySelector.ItemsSource
                                    $policyItem = $displayedItems | Where-Object { $_.IsPolicy -and $_.Policy.id -eq $NavigateToPolicyId }

                                    if ($policyItem) {
                                        # Select the policy in the ListBox
                                        $policySelector.SelectedItem = $policyItem
                                        $policySelector.ScrollIntoView($policyItem)

                                        Write-Host "Navigated to policy: $NavigateToPolicyId"
                                    } else {
                                        Write-Warning "Policy item not found in display: $NavigateToPolicyId"
                                    }
                                } else {
                                    Write-Warning "Product header not found for: $foundProductKey"
                                }
                            } else {
                                Write-Warning "Policy not found: $NavigateToPolicyId"
                            }
                        } catch {
                            Write-Warning "Error navigating to policy: $($_.Exception.Message)"
                        }
                    }.GetNewClosure())
                }

                # Add window closing event to properly clean up
                $window.Add_Closing({
                    if ($syncHash.LoggingEnabled) {
                        Write-ViewerLog "Baseline Policy Viewer closing. Total log entries: $($syncHash.ViewerLogs.Count)" -Level "Info"
                    }
                    $syncHash.IsClosing = $true
                    $navigationTimer.Stop()
                }.GetNewClosure())

                # Show the window (non-blocking)
                $window.ShowDialog()

            } catch {
                $syncHash.Error = $_.Exception.Message
                [System.Windows.MessageBox]::Show("Error in baseline viewer: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
        }

        # Start the UI in the runspace (non-blocking)
        $viewerPowerShell = [powershell]::Create()
        $viewerPowerShell.Runspace = $viewerRunspace
        $viewerPowerShell.AddScript($uiScriptBlock) | Out-Null
        $viewerHandle = $viewerPowerShell.BeginInvoke()

        # Return the runspace information for management
        # (Always returned for internal tracking regardless of PassThru parameter)
        return @{
            PowerShell = $viewerPowerShell
            Runspace = $viewerRunspace
            Handle = $viewerHandle
            SyncHash = $syncHash
        }

    } catch {
        Write-Error "Failed to launch baseline viewer in runspace: $($_.Exception.Message)"
        throw
    }
}

# Function to check if viewer is still running
Function Test-BaselineViewerStatus {
    param(
        [Parameter(Mandatory = $true)]
        $ViewerInstance
    )

    if ($ViewerInstance -and $ViewerInstance.Runspace) {
        return $ViewerInstance.Runspace.RunspaceStateInfo.State -eq 'Opened' -and -not $ViewerInstance.SyncHash.IsClosing
    }
    return $false
}

<#
Export-ModuleMember -Function @(
    'Show-ScubaBaselinePolicyHelper',
    'Test-BaselineViewerStatus'
)
#>