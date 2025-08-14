Function Initialize-ResultsTab {
    <#
    .SYNOPSIS
    Initializes the Results tab and scans for existing ScubaGear reports.
    .DESCRIPTION
    This function sets up the Results tab, scans the output directory for existing reports,
    and creates tabs for each found report with formatted timestamps.
    #>
    # Enable the Results tab
    $syncHash.ResultsTab.IsEnabled = $true
    $syncHash.ResultsTab.Header = $syncHash.UIConfigs.Reports.tabName

    # Add event handlers for control buttons
    $syncHash.ResultsRefresh_Button.Add_Click({
        Update-ResultsTab
    })

    $syncHash.ResultsOpenFolder_Button.Add_Click({
        Open-ResultsFolder
    })

    # Initial scan for existing results
    Update-ResultsTab
}

Function Update-ResultsTab {
    <#
    .SYNOPSIS
    Scans for ScubaGear result folders and creates/updates result tabs.
    .DESCRIPTION
    This function searches the output directory for M365BaselineConformance folders,
    parses timestamps, and creates tabs with properly formatted dates.
    Enhanced to search both configured OutPath and default Documents folder.
    #>
    $folderName = $syncHash.AdvancedSettingsData["OutFolderName"]
    If(-Not $folderName) {
        $folderName = $syncHash.UIConfigs.defaultAdvancedSettings.OutFolderName_TextBox
    }

    $jsonfilename = $syncHash.AdvancedSettingsData["OutJsonFileName"]
    If(-Not $jsonfilename) {
        $jsonfilename = $syncHash.UIConfigs.defaultAdvancedSettings.OutJsonFileName_TextBox
    }


    Write-DebugOutput -Message "Refreshing results tabs" -Source $MyInvocation.MyCommand -Level "Info"

    # Get the output directory from settings
    $configuredPath = $syncHash.AdvancedSettingsData["OutPath"]
    $defaultPath = Join-Path $env:USERPROFILE "Documents"  # ScubaGear default location

    # Create list of paths to search
    $searchPaths = @()

    # Add configured path if it exists and is valid
    if (![string]::IsNullOrEmpty($configuredPath) -and $configuredPath -ne "." -and (Test-Path $configuredPath)) {
        $searchPaths += $configuredPath
        Write-DebugOutput -Message "Searching configured path: $configuredPath" -Source $MyInvocation.MyCommand -Level "Info"
    }

    # Always add Documents folder as ScubaGear default
    if ($searchPaths -notcontains $defaultPath) {
        $searchPaths += $defaultPath
        Write-DebugOutput -Message "Searching default Documents path: $defaultPath" -Source $MyInvocation.MyCommand -Level "Info"
    }

    # Clear existing result tabs (keep ResultsEmptyTab)
    $tabsToRemove = @()
    foreach ($tab in $syncHash.ResultsTabControl.Items) {
        if ($tab.Name -ne "ResultsEmptyTab") {
            $tabsToRemove += $tab
        }
    }
    foreach ($tab in $tabsToRemove) {
        $syncHash.ResultsTabControl.Items.Remove($tab)
    }

    # Find all M365BaselineConformance folders from all search paths
    $syncHash.ResultsJsonData = @()
    foreach ($searchPath in $searchPaths) {
        if (Test-Path $searchPath) {

            $foldersInPath = Get-ChildItem -Path $searchPath -Directory -Filter "${folderName}_*" | ForEach-Object {
                $jsonFile = Get-ChildItem -Path $_.FullName -Filter "${jsonfilename}*.json" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
                $TimeNameInfo = Get-ResultsReportTimeStamp -SearchPrefix $folderName -Name $_.BaseName
                [PSCustomObject]@{
                    ReportName = $_.BaseName
                    TabHeader = $TimeNameInfo.TabHeader
                    ReportTimeStamp = $TimeNameInfo.TimeStamp
                    RelativeTime = $TimeNameInfo.RelativeTime
                    ReportPath = $_.FullName
                    JsonResultsPath = $jsonFile
                }
            }
            $syncHash.ResultsJsonData += $foldersInPath
            Write-DebugOutput -Message "Found $($foldersInPath.Count) result folders in: $searchPath" -Source $MyInvocation.MyCommand -Level "Info"
        }
    }

    if ($syncHash.ResultsJsonData -eq 0) {
        # Show ResultsEmptyTab
        $syncHash.ResultsEmptyTab.Visibility = "Visible"
        $syncHash.ResultsTabControl.SelectedItem = $syncHash.ResultsEmptyTab
        Update-ResultsCount 0
    } else {
        # Hide ResultsEmptyTab
        $syncHash.ResultsEmptyTab.Visibility = "Collapsed"

        # Create tabs for each result folder
        foreach ($Report in $syncHash.ResultsJsonData) {
            New-ResultsReportTab -Report $Report
        }

        # Select the most recent tab (first in sorted list)
        if ($syncHash.ResultsTabControl.Items.Count -gt 1) {
            $syncHash.ResultsTabControl.SelectedIndex = 1  # Skip ResultsEmptyTab at index 0
        }

        Update-ResultsCount $syncHash.ResultsJsonData.Count
    }
}



Function Test-ResultsDataValidity {
    <#
    .SYNOPSIS
    Validates ScubaGear data to ensure it's not corrupted or malformed.
    .DESCRIPTION
    Checks for common issues like invalid Summary data where all values are "9" or other placeholder values.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ScubaData,
        [string]$ReportPath
    )

    try {
        Write-DebugOutput -Message "Validating ScubaData for report: $ReportPath" -Source $MyInvocation.MyCommand -Level "Debug"
        Write-DebugOutput -Message "ScubaData type: $($ScubaData.GetType().FullName)" -Source $MyInvocation.MyCommand -Level "Debug"

        # Check if Summary exists
        if (-not $ScubaData.Summary) {
            Write-DebugOutput -Message "No Summary section found in ScubaData" -Source $MyInvocation.MyCommand -Level "Error"
            return $false
        }

        # Check if Results exists
        if (-not $ScubaData.Results) {
            Write-DebugOutput -Message "No Results section found in ScubaData" -Source $MyInvocation.MyCommand -Level "Error"
            return $false
        }

        # Check for invalid Summary data (common issue: all values are "9")
        $summaryProducts = $ScubaData.Summary | Get-Member -MemberType NoteProperty
        if ($summaryProducts -and $summaryProducts.Count -gt 0) {
            $invalidDataCount = 0
            $totalProductsChecked = 0

            foreach ($productName in $summaryProducts.Name) {
                $productSummary = $ScubaData.Summary.$productName
                $totalProductsChecked++

                # Check if all summary values are the same invalid placeholder (like "9")
                $passes = [string]$productSummary.Passes
                $warnings = [string]$productSummary.Warnings
                $failures = [string]$productSummary.Failures
                $manual = [string]$productSummary.Manual
                $errors = [string]$productSummary.Errors

                # Flag as invalid if all values are the same non-zero number (common corruption pattern)
                if ($passes -eq $warnings -and $warnings -eq $failures -and $failures -eq $manual -and $manual -eq $errors -and $passes -ne "0") {
                    Write-DebugOutput -Message "Invalid summary data detected for product $productName`: all values are '$passes' (likely corrupted scan result)" -Source $MyInvocation.MyCommand -Level "Error"
                    $invalidDataCount++
                }

                # Special check for the common "9" corruption pattern
                if ($passes -eq "9" -and $warnings -eq "9" -and $failures -eq "9" -and $manual -eq "9" -and $errors -eq "9") {
                    Write-DebugOutput -Message "Detected '9' corruption pattern for product $productName - this indicates an incomplete or failed ScubaGear scan" -Source $MyInvocation.MyCommand -Level "Error"
                    $invalidDataCount++
                }

                # Also check for obviously invalid values (non-numeric or negative)
                $allValues = @($passes, $warnings, $failures, $manual, $errors)
                foreach ($value in $allValues) {
                    if (-not [int]::TryParse($value, [ref]$null) -or [int]$value -lt 0) {
                        Write-DebugOutput -Message "Invalid summary value detected for product $productName`: '$value' is not a valid non-negative integer" -Source $MyInvocation.MyCommand -Level "Error"
                        $invalidDataCount++
                        break
                    }
                }
            }

            # If more than half the products have invalid data, consider the whole report invalid
            if ($invalidDataCount -gt ($totalProductsChecked / 2)) {
                Write-DebugOutput -Message "Report validation failed: $invalidDataCount of $totalProductsChecked products have invalid summary data" -Source $MyInvocation.MyCommand -Level "Error"
                return $false
            }
        } else {
            Write-DebugOutput -Message "No products found in Summary section" -Source $MyInvocation.MyCommand -Level "Error"
            return $false
        }

        # Check if Results has valid structure
        $resultProducts = $ScubaData.Results | Get-Member -MemberType NoteProperty
        if (-not $resultProducts -or $resultProducts.Count -eq 0) {
            Write-DebugOutput -Message "No products found in Results section" -Source $MyInvocation.MyCommand -Level "Error"
            return $false
        }

        # Check if Results actually contains meaningful data (not just empty arrays)
        $hasValidResults = $false
        foreach ($productName in $resultProducts.Name) {
            $productResults = $ScubaData.Results.$productName
            if ($productResults -and $productResults.Count -gt 0) {
                # Check if any result has meaningful data (Groups with Controls)
                foreach ($group in $productResults) {
                    if ($group.Controls -and $group.Controls.Count -gt 0) {
                        $hasValidResults = $true
                        break
                    }
                }
                if ($hasValidResults) { break }
            }
        }

        if (-not $hasValidResults) {
            Write-DebugOutput -Message "Results section exists but contains no meaningful compliance data" -Source $MyInvocation.MyCommand -Level "Error"
            return $false
        }

        # Basic validation passed
        Write-DebugOutput -Message "ScubaData validation passed for report: $ReportPath" -Source $MyInvocation.MyCommand -Level "Debug"
        return $true

    } catch {
        Write-DebugOutput -Message "Error during ScubaData validation: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        return $false
    }
}

Function New-ResultsReportTab {
    <#
    .SYNOPSIS
    Creates a native WPF tab displaying ScubaGear results from ScubaResults JSON data.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Report
    )

    # Create new TabItem
    $newTab = New-Object System.Windows.Controls.TabItem

    # Create folder-style header using Unicode folder icon
    $folderIcon = [System.Char]::ConvertFromUtf32(0x1F4C1)
    $newTab.Header = "$folderIcon $($Report.TabHeader)"
    #$newTab.Header = "📁 $($Report.TabHeader)"

    $newTab.Name = "Result_$($Report.ReportName -Replace '\W+', '_')"

    if (-not $Report.JsonResultsPath) {
        # No ScubaResults file found
        $noDataTab = New-ResultsNoDataTab -ReportPath $Report.ReportPath -Message "No ScubaResults file found at: $($Report.ReportPath)"
        $newTab.Content = $noDataTab
    } else {
        try {
            $scubaData = Get-Content $Report.JsonResultsPath | ConvertFrom-Json

            # Validate the ScubaData before processing
            $isValidData = Test-ResultsDataValidity -ScubaData $scubaData -ReportPath $Report.ReportPath

            if ($isValidData) {
                $reportContent = New-ResultsContent -ScubaData $scubaData -ReportPath $Report.ReportPath -RelativeTime ($Report.RelativeTime + " (" + $Report.ReportTimeStamp +")")
                $newTab.Content = $reportContent

            } else {
                $noDataTab = New-ResultsNoDataTab -ReportPath $Report.ReportPath -Message "Report data appears to be corrupted or incomplete: $($Report.ReportPath).`n`nThe ScubaResults JSON file contains invalid summary data.`n`nThis may indicate the ScubaGear scan was interrupted or encountered errors."
                $newTab.Content = $noDataTab
            }
        }
        catch {
            $errorTab = New-ResultsNoDataTab -ReportPath $Report.ReportPath -Message "Error reading ScubaResults file: $($Report.JsonResultsPath).`n`nError details: $($_.Exception.Message)"
            $newTab.Content = $errorTab
        }
    }

    # Add to main tab control
    $syncHash.ResultsTabControl.Items.Add($newTab)
    Write-DebugOutput -Message "Added report tab: $($Report.TabHeader) with content type: $($newTab.Content.GetType().FullName)" -Source $MyInvocation.MyCommand -Level "Info"
}


Function New-ResultsContent {
    <#
    .SYNOPSIS
    Creates the content for a results tab using the provided ScubaData.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "ReportPath")]
    param(
        [PSCustomObject[]]$ScubaData,
        [string]$ReportPath,
        [string]$RelativeTime
    )

    # Safety check - validate data before processing
    Write-DebugOutput -Message "New-ResultsContent called for report: $ReportPath" -Source $MyInvocation.MyCommand -Level "Debug"

    if (-not $ScubaData) {
        return New-ResultsNoDataTab -ReportPath $ReportPath -Message "ScubaData is null - returning error tab"
    }

    # Additional validation to double-check data integrity
    if (-not $ScubaData.Summary -or -not $ScubaData.Results) {
        return New-ResultsNoDataTab -ReportPath $ReportPath -Message "ScubaData missing Summary or Results sections - returning error tab"
    }

    # Create the XAML template for the entire report content
    $xamlTemplate = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        VerticalScrollBarVisibility="Auto"
        HorizontalScrollBarVisibility="Auto">
    <StackPanel Margin="8">

        <!-- Tenant Header Card -->
        <Border Style="{DynamicResource Card}" Margin="0,0,0,8">
            <Grid Margin="12">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <!-- Left side - Tenant info -->
                <StackPanel Grid.Column="0">
                    <TextBlock Text="📊 ScubaGear Assessment Report" FontSize="18" FontWeight="Bold" Margin="0,0,0,6"/>

                    <!-- Tenant Info Table -->
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="160"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <TextBlock Grid.Row="0" Grid.Column="0" Text="Tenant Display Name" FontWeight="SemiBold" Margin="0,2"/>
                        <TextBlock Grid.Row="0" Grid.Column="1" Name="TenantDisplayName" Text="{DISPLAY_NAME}" Margin="6,2,0,2"/>

                        <TextBlock Grid.Row="1" Grid.Column="0" Text="Tenant Domain Name" FontWeight="SemiBold" Margin="0,2"/>
                        <TextBlock Grid.Row="1" Grid.Column="1" Name="TenantDomainName" Text="{DOMAIN_NAME}" Margin="6,2,0,2"/>

                        <TextBlock Grid.Row="2" Grid.Column="0" Text="Tenant ID" FontWeight="SemiBold" Margin="0,2"/>
                        <TextBlock Grid.Row="2" Grid.Column="1" Name="TenantId" Text="{TENANT_ID}" Margin="6,2,0,2"/>

                        <TextBlock Grid.Row="3" Grid.Column="0" Text="Report Date" FontWeight="SemiBold" Margin="0,2"/>
                        <TextBlock Grid.Row="3" Grid.Column="1" Name="ReportDate" Text="{REPORT_DATE}" Margin="6,2,0,2"/>

                        <TextBlock Grid.Row="4" Grid.Column="0" Text="Scuba Version" FontWeight="SemiBold" Margin="0,2"/>
                        <TextBlock Grid.Row="4" Grid.Column="1" Name="ScubaVersion" Text="{SCUBA_VERSION}" Margin="6,2,0,2"/>
                    </Grid>
                </StackPanel>

                <!-- Right side - Action buttons and version info -->
                <StackPanel Grid.Column="1" HorizontalAlignment="Right" VerticalAlignment="Top">
                    <Button Name="OpenHtmlBtn" Style="{DynamicResource PrimaryButton}" Content="📄 Open Full HTML Report"
                            Margin="0,0,0,6" Width="190" Height="32"/>
                    <Button Name="OpenFolderBtn" Style="{DynamicResource SecondaryButton}" Content="📁 Open Report Folder"
                            Width="190" Margin="0,0,0,8" Height="32"/>

                    <!-- ScubaGear Version and UUID Info -->

                        <StackPanel VerticalAlignment="bottom">
                            <TextBlock Text="Report UUID:" FontSize="10" Foreground="LightGray"/>
                            <TextBlock Text="{REPORT_UUID}" FontSize="10" FontFamily="Consolas" Margin="0,0,0,0" Foreground="Gray"/>
                        </StackPanel>

                </StackPanel>
            </Grid>
        </Border>

        <!-- Report Tabs -->
        <TabControl Name="ReportTabControl" Margin="0,8,0,0">

            <!-- Summary Tab -->
            <TabItem Header="📊 Baseline Conformance Reports">

                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="8">
                        <ItemsControl Name="SummaryItemsControl">
                            <ItemsControl.ItemTemplate>
                                <DataTemplate>
                                    <Border Style="{DynamicResource Card}" Margin="0,0,0,4">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="280"/>
                                                <ColumnDefinition Width="*"/>
                                            </Grid.ColumnDefinitions>

                                            <!-- Product Name Column -->
                                            <TextBlock Grid.Column="0" FontSize="12" Text="{Binding Product}" FontWeight="SemiBold"
                                                    Foreground="Blue" TextDecorations="Underline"
                                                    VerticalAlignment="Center"/>

                                            <!-- Status Badges Column -->
                                            <ItemsControl Grid.Column="1" ItemsSource="{Binding StatusItems}"
                                                        VerticalAlignment="Center">
                                                <ItemsControl.ItemsPanel>
                                                    <ItemsPanelTemplate>
                                                        <WrapPanel Orientation="Horizontal"/>
                                                    </ItemsPanelTemplate>
                                                </ItemsControl.ItemsPanel>
                                                <ItemsControl.ItemTemplate>
                                                    <DataTemplate>
                                                        <Border Background="{Binding Color}" CornerRadius="8" Padding="6,2" Margin="0,0,4,2">
                                                            <TextBlock Text="{Binding Text}" Foreground="{Binding TextColor}"
                                                                    FontSize="12" FontWeight="SemiBold"/>
                                                        </Border>
                                                    </DataTemplate>
                                                </ItemsControl.ItemTemplate>
                                            </ItemsControl>
                                        </Grid>
                                    </Border>
                                </DataTemplate>
                            </ItemsControl.ItemTemplate>
                        </ItemsControl>
                    </StackPanel>
                </ScrollViewer>

            </TabItem>

            <!-- Product Tabs will be added dynamically -->
            {PRODUCT_TABS}

        </TabControl>
    </StackPanel>
</ScrollViewer>
"@

    # Process the data and replace placeholders
    $processedXaml = $xamlTemplate

    # Replace tenant information placeholders
    $displayName = [string]$ScubaData.MetaData.DisplayName
    $domainName = [string]$ScubaData.MetaData.DomainName
    $tenantId = [string]$ScubaData.MetaData.TenantId

    # Extract ScubaGear version and UUID
    $scubaVersion = if ($ScubaData.MetaData.ToolVersion) { [string]$ScubaData.MetaData.ToolVersion } else { "Unknown" }
    $reportUuid = if ($ScubaData.MetaData.ReportUUID) { [string]$ScubaData.MetaData.ReportUUID } else { "Unknown" }

    $processedXaml = $processedXaml -replace '{DISPLAY_NAME}', $displayName
    $processedXaml = $processedXaml -replace '{DOMAIN_NAME}', $domainName
    $processedXaml = $processedXaml -replace '{TENANT_ID}', $tenantId
    $processedXaml = $processedXaml -replace '{REPORT_DATE}', $RelativeTime
    $processedXaml = $processedXaml -replace '{SCUBA_VERSION}', $scubaVersion
    $processedXaml = $processedXaml -replace '{REPORT_UUID}', $reportUuid

    # Initialize as empty string instead of array
    $productReportTabsXaml = ""
    If($synchash.UIConfigs.Reports.ShowProductSummaryReports -and $ScubaData.Results) {
        Write-DebugOutput -Message "Generating product tabs XAML for $($ScubaData.Results.PSObject.Properties.Count) products" -Source $MyInvocation.MyCommand -Level "Debug"

        # Generate product tabs XAML
        foreach ($productName in ($ScubaData.Results | Get-Member -MemberType NoteProperty).Name) {
            $displayName = switch ($productName) {
                "AAD" { "Azure Active Directory" }
                "Defender" { "Microsoft 365 Defender" }
                "EXO" { "Exchange Online" }
                "PowerPlatform" { "Microsoft Power Platform" }
                "SharePoint" { "SharePoint Online" }
                "Teams" { "Microsoft Teams" }
                default { $productName }
            }

            Write-DebugOutput -Message "Adding tab for product: $productName ($displayName)" -Source $MyInvocation.MyCommand -Level "Verbose"

            $productReportTabsXaml += @"
    <TabItem Header="$displayName">
        <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel Name="${productName}ProductStack" Margin="16">
                <!-- Product content will be populated dynamically -->
            </StackPanel>
        </ScrollViewer>
    </TabItem>
"@
        }

    } else {
        Write-DebugOutput -Message "Product tabs disabled or no 'ScubaData.Results' found" -Source $MyInvocation.MyCommand -Level "Debug"
    }

    Write-DebugOutput -Message "Product tabs XAML length: $($productReportTabsXaml.Length) characters" -Source $MyInvocation.MyCommand -Level "Debug"
    $processedXaml = $processedXaml -replace '\{PRODUCT_TABS\}', $productReportTabsXaml

    # Parse the XAML into a WPF control
    try {
        $reportControl = [Windows.Markup.XamlReader]::Parse($processedXaml)
        Write-DebugOutput -Message ("Successfully parsed XAML report content with product tabs") -Source $MyInvocation.MyCommand -Level "Debug"


        # Set up button event handlers
        $openHtmlBtn = $reportControl.FindName("OpenHtmlBtn")
        $openFolderBtn = $reportControl.FindName("OpenFolderBtn")

        if ($openHtmlBtn) {
            $openHtmlBtn.Add_Click({
                $htmlFile = Get-ChildItem -Path $ReportPath -Name "*.html" | Select-Object -First 1
                if ($htmlFile) {
                    $htmlPath = Join-Path $ReportPath $htmlFile
                    Start-Process $htmlPath
                } else {
                    [System.Windows.MessageBox]::Show("HTML report not found in folder.", "Report Not Found", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                }
            }.GetNewClosure())
        }

        if ($openFolderBtn) {
            $openFolderBtn.Add_Click({
                Start-Process "explorer.exe" -ArgumentList $ReportPath
            }.GetNewClosure())
        }


        # Populate summary data
        $summaryItems = @()
        foreach ($productAbbr in ($ScubaData.Summary | Get-Member -MemberType NoteProperty).Name) {

            Write-DebugOutput -Message "Processing summary data for product: $productAbbr" -Source $MyInvocation.MyCommand -Level "Info"
            $productData = $ScubaData.Summary.$productAbbr

            $displayName = switch ($productAbbr) {
                "AAD" { "Azure Active Directory" }
                "Defender" { "Microsoft 365 Defender" }
                "EXO" { "Exchange Online" }
                "PowerPlatform" { "Microsoft Power Platform" }
                "SharePoint" { "SharePoint Online" }
                "Teams" { "Microsoft Teams" }
                default { $productAbbr }
            }

            # Build styled status badges
            $statusItems = @()

            $passes = if ($productData.Passes -is [array]) { $productData.Passes -join ", " } else { [string]$productData.Passes }
            $warnings = if ($productData.Warnings -is [array]) { $productData.Warnings -join ", " } else { [string]$productData.Warnings }
            $failures = if ($productData.Failures -is [array]) { $productData.Failures -join ", " } else { [string]$productData.Failures }
            $manual = if ($productData.Manual -is [array]) { $productData.Manual -join ", " } else { [string]$productData.Manual }
            $errors = if ($productData.Errors -is [array]) { $productData.Errors -join ", " } else { [string]$productData.Errors }

            # Add status badges with colors
            if ([int]$passes -gt 0) {
                $statusItems += [PSCustomObject]@{
                    Text = "$([char]0x2713) $passes pass$(if([int]$passes -gt 1){'es'})"
                    Color = "#28a745"  # Green
                    TextColor = "White"
                }
            }
            if ([int]$warnings -gt 0) {
                $statusItems += [PSCustomObject]@{
                    Text = "$([char]0x26A0) $warnings warning$(if([int]$warnings -gt 1){'s'})"
                    Color = "#ffc107"  # Yellow/Orange
                    TextColor = "#212529"  # Dark text for better contrast
                }
            }
            if ([int]$failures -gt 0) {
                $statusItems += [PSCustomObject]@{
                    Text = "$([char]0x2717) $failures failure$(if([int]$failures -gt 1){'s'})"
                    Color = "#dc3545"  # Red
                    TextColor = "White"
                }
            }
            if ([int]$manual -gt 0) {
                $statusItems += [PSCustomObject]@{
                    Text = "$([System.Char]::ConvertFromUtf32(0x1F464)) $manual manual check$(if([int]$manual -gt 1){'s'})"
                    Color = "#6f42c1"  # Purple
                    TextColor = "White"
                }
            }
            if ([int]$errors -gt 0) {
                $statusItems += [PSCustomObject]@{
                    Text = "$([char]0x26A1) $errors error$(if([int]$errors -gt 1){'s'})"
                    Color = "#fd7e14"  # Orange
                    TextColor = "White"
                }
            }

            $summaryItems += [PSCustomObject]@{
                Product = $displayName
                StatusItems = $statusItems
            }
        }

        $summaryItemsControl = $reportControl.FindName("SummaryItemsControl")
        if ($summaryItemsControl) {
            $summaryItemsControl.ItemsSource = $summaryItems
        }

        # Populate product tabs with group data
        if ($ScubaData.Results) {
            Write-DebugOutput -Message "Populating product tabs with results data - Found $($ScubaData.Results.PSObject.Properties.Count) products" -Source $MyInvocation.MyCommand -Level "Debug"

            foreach ($productName in ($ScubaData.Results | Get-Member -MemberType NoteProperty).Name) {
                $productData = $ScubaData.Results.$productName
                $productStack = $reportControl.FindName("${productName}ProductStack")

                Write-DebugOutput -Message "Processing product: $productName, Groups count: $($productData.Count), Stack found: $($null -ne $productStack)" -Source $MyInvocation.MyCommand -Level "Verbose"

                if ($productStack) {
                    if ($productData -and $productData.Count -gt 0) {
                        foreach ($group in $productData) {
                            try {
                                Write-DebugOutput -Message "Creating group expander for group: $($group.GroupName)" -Source $MyInvocation.MyCommand -Level "Verbose"

                                # Call function with explicit parameter and capture result
                                $groupExpander = $null
                                $groupExpander = New-ResultsGroupExpanderXaml -GroupData $group

                                if ($null -ne $groupExpander) {
                                    Write-DebugOutput -Message "Group expander type: $($groupExpander.GetType().FullName)" -Source $MyInvocation.MyCommand -Level "Debug"

                                    # Explicitly cast to UIElement to ensure compatibility
                                    $uiElement = [System.Windows.UIElement]$groupExpander
                                    $addResult = $productStack.Children.Add($uiElement)
                                    Write-DebugOutput -Message "Successfully added group expander to product stack: $productName (Add result: $addResult)" -Source $MyInvocation.MyCommand -Level "Debug"
                                } else {
                                    Write-DebugOutput -Message "Group expander was null for product: $productName, group: $($group.GroupName)" -Source $MyInvocation.MyCommand -Level "Error"
                                }
                            } catch {
                                Write-DebugOutput -Message "Error adding group expander to product stack '$productName'`: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"

                            }
                        }
                    } else {
                        return New-ResultsNoDataTab -ReportPath $ReportPath -Message "No compliance data available for this product: $productName"
                    }
                } else {
                    Write-DebugOutput -Message "Product stack not found for: ${productName}ProductStack" -Source $MyInvocation.MyCommand -Level "Error"
                }
            }
        } else {
            Write-DebugOutput -Message "No ScubaData.Results found" -Source $MyInvocation.MyCommand -Level "Error"
        }
        return $reportControl

    } catch {
        return New-ResultsNoDataTab -ReportPath $ReportPath -Message "Error creating XAML report: $($_.Exception.Message)"
    }
}

Function New-ResultsGroupExpanderXaml {
    [OutputType([System.Windows.UIElement])]
    param(
        [Parameter(Mandatory=$true)]
        $GroupData
    )

    try {
        # Simple validation
        if (-not $GroupData) {
            Write-DebugOutput -Message "GroupData is null, returning null" -Source $MyInvocation.MyCommand -Level "Error"
            return $null
        }

        # Create XAML for group expander
        $expanderXaml = @"
<Expander xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Header="🔒 {GROUP_HEADER}"
        Margin="0,0,0,8"
        IsExpanded="False">
    <StackPanel Margin="16,8,8,8">
    {CONTROLS_CONTENT}
    </StackPanel>
</Expander>
"@

        # Build header - simple string conversion with fallbacks
        $groupNumber = if ($GroupData.GroupNumber) { [string]$GroupData.GroupNumber } else { "" }
        $groupName = if ($GroupData.GroupName) { [string]$GroupData.GroupName } else { "Unknown Group" }

        $header = if ($groupNumber) { "$groupNumber. $groupName" } else { $groupName }

        # Escape special XML characters in header
        $safeHeader = $header -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'

        # Build controls content
        $controlsContent = ""
        if ($GroupData.Controls) {
            foreach ($control in $GroupData.Controls) {
                try {
                    # Safe string extraction with simple fallbacks
                    $controlId = if ($control."Control ID") { [string]$control."Control ID" } else { "Unknown" }
                    $result = if ($control.Result) { [string]$control.Result } else { "N/A" }
                    $criticality = if ($control.Criticality) { [string]$control.Criticality } else { "" }
                    $requirement = if ($control.Requirement) { [string]$control.Requirement } else { "" }

                    # Truncate requirement
                    $truncatedRequirement = if ($requirement.Length -gt 100) {
                        $requirement.Substring(0, 100) + "..."
                    } else {
                        $requirement
                    }

                    # Escape special XML characters in all text
                    $safeControlId = $controlId -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
                    $safeResult = $result -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
                    $safeCriticality = $criticality -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
                    $safeRequirement = $truncatedRequirement -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'

                    # Color for result
                    $resultColor = switch ($result) {
                        "Pass" { "Green" }
                        "Fail" { "Red" }
                        "Warning" { "Orange" }
                        "Error" { "Purple" }
                        "N/A" { "Gray" }
                        "Manual" { "Blue" }
                        default { "Black" }
                    }

                    $controlsContent += @"
<Border BorderBrush="LightGray" BorderThickness="1" Margin="0,2" Padding="8" CornerRadius="3">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="120"/>
            <ColumnDefinition Width="80"/>
            <ColumnDefinition Width="80"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Column="0" Text="$safeControlId" FontWeight="SemiBold" VerticalAlignment="Top"/>
        <TextBlock Grid.Column="1" Text="$safeResult" Foreground="$resultColor" VerticalAlignment="Top"/>
        <TextBlock Grid.Column="2" Text="$safeCriticality" VerticalAlignment="Top"/>
        <TextBlock Grid.Column="3" Text="$safeRequirement" TextWrapping="Wrap" VerticalAlignment="Top"/>
    </Grid>
</Border>
"@
                } catch {
                    Write-DebugOutput -Message "Error processing control: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                    # Skip this control and continue
                    continue
                }
            }
        }

        # If no controls were processed successfully, add a placeholder
        if ([string]::IsNullOrWhiteSpace($controlsContent)) {
            $controlsContent = @"
<TextBlock Text="No control data available" FontStyle="Italic" Foreground="Gray" Margin="8"/>
"@
        }

        # Replace placeholders
        $processedXaml = $expanderXaml -replace '\{GROUP_HEADER\}', $safeHeader
        $processedXaml = $processedXaml -replace '\{CONTROLS_CONTENT\}', $controlsContent

        # Debug: Log the processed XAML length for troubleshooting
        Write-DebugOutput -Message "Processed XAML length: $($processedXaml.Length) characters for group: $safeHeader" -Source $MyInvocation.MyCommand -Level "Debug"

        # Parse and return - ensure single object
        Write-DebugOutput -Message "Creating group expander for: $safeHeader" -Source $MyInvocation.MyCommand -Level "Info"
        $parsedControl = [Windows.Markup.XamlReader]::Parse($processedXaml)

        # Ensure we return a single control object, not an array
        if ($parsedControl -is [System.Array]) {
            Write-DebugOutput -Message "XAML parser returned array, taking first element" -Source $MyInvocation.MyCommand -Level "Debug"
            return $parsedControl[0]
        } else {
            Write-DebugOutput -Message "XAML parser returned single object of type: $($parsedControl.GetType().FullName)" -Source $MyInvocation.MyCommand -Level "Debug"
            return $parsedControl
        }

    } catch {
        Write-DebugOutput -Message "Error creating group expander: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        #return New-ResultsNoDataTab
    }
}

Function New-ResultsNoDataTab {
    <#
    .SYNOPSIS
    Creates a "No Data" tab for the results view using XAML.
    #>
    [OutputType([System.Windows.UIElement])]
    param(
        [string]$ReportPath,
        [string]$Message
    )

    Write-DebugOutput -Message "Creating NoDataTab for reason: $Message, ReportPath: $ReportPath" -Source $MyInvocation.MyCommand -Level "Debug"

    # Escape any special XML characters in the message text
    $safeMessageText = $Message -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'

    Write-DebugOutput -Message "NoDataText message set to: $($safeMessageText.Substring(0, [Math]::Min(100, $safeMessageText.Length)))..." -Source $MyInvocation.MyCommand -Level "Debug"

    # Create XAML template for the no data content
    $xamlTemplate = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        VerticalScrollBarVisibility="Auto"
        HorizontalScrollBarVisibility="Auto">
    <StackPanel Margin="20" HorizontalAlignment="Center" VerticalAlignment="Center">
    <TextBlock Text="$safeMessageText"
                FontSize="16"
                TextAlignment="Center"
                Foreground="{DynamicResource MutedTextBrush}"
                TextWrapping="Wrap"
                MaxWidth="600"
                Margin="10"/>
    </StackPanel>
</ScrollViewer>
"@

    try {
        # Parse the XAML into a WPF control
        $noDataControl = [Windows.Markup.XamlReader]::Parse($xamlTemplate)
        Write-DebugOutput -Message "NoDataTab XAML parsed successfully with type: $($noDataControl.GetType().FullName)" -Source $MyInvocation.MyCommand -Level "Debug"

        # Return the parsed control directly
        return $noDataControl

    } catch {
        Write-DebugOutput -Message "Error parsing NoDataTab XAML: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

Function Update-ResultsCount {
    <#
    .SYNOPSIS
    Updates the results count badge in the Results tab header.
    #>
    param([int]$Count)

    $syncHash.ResultsCountText.Text = if ($Count -eq 0) { "No Reports" } elseif ($Count -eq 1) { "1 Report" } else { "$Count Reports" }
}

Function Get-ResultsReportTimeStamp {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$SearchPrefix
    )

    if ($Name -match "${SearchPrefix}_(\d{4})_(\d{2})_(\d{2})_(\d{2})_(\d{2})_(\d{2})") {
        $year = $matches[1]; $month = $matches[2]; $day = $matches[3]
        $hour = $matches[4]; $minute = $matches[5]; $second = $matches[6]
        $timestamp = Get-Date -Year $year -Month $month -Day $day -Hour $hour -Minute $minute -Second $second
        $tabHeader = "$year-$month-$day ($hour`:$minute`:$second)"
        $relativeTime = Get-ResultsRelativeTime $timestamp  # ← Fixed function name
        return [PSCustomObject]@{
            TabHeader = $tabHeader
            TimeStamp = $timestamp
            RelativeTime = $relativeTime
        }
    } else {
        return [PSCustomObject]@{
            TabHeader = $Name
            TimeStamp = "Unknown time"
            RelativeTime  = "Unknown time"
        }
    }
}

Function Get-ResultsRelativeTime {
    <#
    .SYNOPSIS
    Returns a human-readable relative time string.
    #>
    param([DateTime]$DateTime)

    $now = Get-Date
    $timespan = $now - $DateTime

    if ($timespan.TotalDays -lt 1) {
        if ($timespan.TotalHours -lt 1) {
            if ($timespan.TotalMinutes -lt 1) {
                return "Just now"
            } else {
                return "$([math]::Floor($timespan.TotalMinutes)) minutes ago"
            }
        } else {
            return "$([math]::Floor($timespan.TotalHours)) hours ago"
        }
    } elseif ($timespan.TotalDays -lt 7) {
        return "$([math]::Floor($timespan.TotalDays)) days ago"
    } else {
        return $DateTime.ToString("MMM dd, yyyy")
    }
}

Function Open-ResultsFolder {
    <#
    .SYNOPSIS
    Opens the main results folder in Windows Explorer.
    #>

    $outputPath = $syncHash.GeneralSettingsData["OutPath"]
    if ([string]::IsNullOrEmpty($outputPath)) {
        $outputPath = Join-Path $env:USERPROFILE "ScubaResults"
    }

    if (Test-Path $outputPath) {
        Start-Process "explorer.exe" -ArgumentList $outputPath
    } else {
        [System.Windows.MessageBox]::Show(
            "Results folder not found: $outputPath",
            "Folder Not Found",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )
    }
}