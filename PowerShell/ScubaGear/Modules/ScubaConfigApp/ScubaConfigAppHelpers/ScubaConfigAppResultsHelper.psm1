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
    Scans for ScubaGear result folders and creates/updates result tabs using simple background jobs.
    .DESCRIPTION
    This function searches the output directory for M365BaselineConformance folders,
    parses timestamps, and creates tabs with properly formatted dates.
    Uses PowerShell jobs for background processing to prevent UI blocking.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
    [CmdletBinding()]
    param()

    # Prevent multiple concurrent scans
    if ($syncHash.ResultsScanInProgress) {
        Write-DebugOutput -Message "Results scan already in progress, skipping" -Source $MyInvocation.MyCommand -Level "Info"
        return
    }

    $syncHash.ResultsScanInProgress = $true

    # Show progress indicator immediately
    $syncHash.ResultsScanProgress.Visibility = "Visible"
    $syncHash.ResultsScanStatus.Text = "Scanning for ScubaGear reports..."
    $syncHash.ResultsProgressBar.IsIndeterminate = $true

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

    # Show loading state
    $syncHash.ResultsEmptyTab.Visibility = "Visible"
    $syncHash.ResultsTabControl.SelectedItem = $syncHash.ResultsEmptyTab
    Update-ResultsCount 0

    # Update empty tab content to show loading message
    $loadingContent = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        VerticalScrollBarVisibility="Auto"
        HorizontalScrollBarVisibility="Auto">
    <StackPanel Margin="20" HorizontalAlignment="Center" VerticalAlignment="Center">
        <TextBlock Text="Loading: Scanning for ScubaGear reports..."
                   FontSize="16"
                   TextAlignment="Center"
                   Foreground="{DynamicResource MutedTextBrush}"
                   Margin="10"/>
        <TextBlock Text="Please wait while we search for existing reports..."
                   FontSize="12"
                   TextAlignment="Center"
                   Foreground="{DynamicResource MutedTextBrush}"
                   Margin="10"/>
    </StackPanel>
</ScrollViewer>
"@
    try {
        $loadingControl = [Windows.Markup.XamlReader]::Parse($loadingContent)
        $syncHash.ResultsEmptyTab.Content = $loadingControl
    } catch {
        Write-DebugOutput -Message "Error creating loading content: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Warning"
    }

    # Get configuration values for the background job
    $folderName = $syncHash.AdvancedSettingsData["OutFolderName"]
    if (-not $folderName) {
        $folderName = $syncHash.UIConfigs.defaultAdvancedSettings.OutFolderName_TextBox
    }

    $jsonfilename = $syncHash.AdvancedSettingsData["OutJsonFileName"]
    if (-not $jsonfilename) {
        $jsonfilename = $syncHash.UIConfigs.defaultAdvancedSettings.OutJsonFileName_TextBox
    }

    $configuredPath = $syncHash.AdvancedSettingsData["OutPath"]
    $defaultPath = Join-Path $env:USERPROFILE "Documents"

    # Create list of paths to search
    $searchPaths = @()
    if (![string]::IsNullOrEmpty($configuredPath) -and $configuredPath -ne "." -and (Test-Path $configuredPath)) {
        $searchPaths += $configuredPath
    }
    if ($searchPaths -notcontains $defaultPath) {
        $searchPaths += $defaultPath
    }

    $maximumResults = $syncHash.UIConfigs.MaximumResults

    # Start background job with simple script block
    $job = Start-Job -ScriptBlock {
        param($SearchPaths, $FolderName, $JsonFileName, $MaxResults)

        function Get-ResultsReportTimeStamp {
            param([string]$Name, [string]$SearchPrefix)
            if ($Name -match "${SearchPrefix}_(\d{4})_(\d{2})_(\d{2})_(\d{2})_(\d{2})_(\d{2})") {
                $year = $matches[1]; $month = $matches[2]; $day = $matches[3]
                $hour = $matches[4]; $minute = $matches[5]; $second = $matches[6]
                $timestamp = Get-Date -Year $year -Month $month -Day $day -Hour $hour -Minute $minute -Second $second
                $tabHeader = "$year-$month-$day ($hour`:$minute`:$second)"

                # Calculate relative time
                $now = Get-Date
                $timespan = $now - $timestamp
                if ($timespan.TotalDays -lt 1) {
                    if ($timespan.TotalHours -lt 1) {
                        if ($timespan.TotalMinutes -lt 1) {
                            $relativeTime = "Just now"
                        } else {
                            $relativeTime = "$([math]::Floor($timespan.TotalMinutes)) minutes ago"
                        }
                    } else {
                        $relativeTime = "$([math]::Floor($timespan.TotalHours)) hours ago"
                    }
                } elseif ($timespan.TotalDays -lt 7) {
                    $relativeTime = "$([math]::Floor($timespan.TotalDays)) days ago"
                } else {
                    $relativeTime = $timestamp.ToString("MMM dd, yyyy")
                }

                return [PSCustomObject]@{
                    TabHeader = $tabHeader
                    TimeStamp = $timestamp
                    RelativeTime = $relativeTime
                }
            } else {
                return [PSCustomObject]@{
                    TabHeader = $Name
                    TimeStamp = "Unknown time"
                    RelativeTime = "Unknown time"
                }
            }
        }

        $resultsData = @()
        foreach ($searchPath in $SearchPaths) {
            if (Test-Path $searchPath) {
                $foldersInPath = Get-ChildItem -Path $searchPath -Directory -Filter "${FolderName}_*" -ErrorAction SilentlyContinue |
                    Sort-Object -Property LastWriteTime -Descending |
                    Select-Object -First $MaxResults |
                    ForEach-Object {
                        $jsonFile = Get-ChildItem -Path $_.FullName -Filter "${JsonFileName}*.json" -ErrorAction SilentlyContinue |
                            Select-Object -First 1 -ExpandProperty FullName
                        $timeNameInfo = Get-ResultsReportTimeStamp -SearchPrefix $FolderName -Name $_.BaseName
                        [PSCustomObject]@{
                            ReportName = $_.BaseName
                            TabHeader = $timeNameInfo.TabHeader
                            ReportTimeStamp = $timeNameInfo.TimeStamp
                            RelativeTime = $timeNameInfo.RelativeTime
                            ReportPath = $_.FullName
                            JsonResultsPath = $jsonFile
                        }
                    }
                $resultsData += $foldersInPath
            }
        }

        return $resultsData

    } -ArgumentList $searchPaths, $folderName, $jsonfilename, $maximumResults

    # Use a timer to poll job status instead of events
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)  # Check every 500ms

    $timer.Add_Tick({
        if ($job.State -eq 'Completed' -or $job.State -eq 'Failed' -or $job.State -eq 'Stopped') {
            $timer.Stop()

            try {
                if ($job.State -eq 'Completed') {
                    $resultsData = Receive-Job -Job $job -ErrorAction Stop

                    Write-DebugOutput -Message "Job completed successfully. Results count: $($resultsData.Count)" -Source "Update-ResultsTab" -Level "Info"

                    # Hide progress indicator
                    $syncHash.ResultsScanProgress.Visibility = "Collapsed"
                    $syncHash.ResultsScanInProgress = $false

                    if ($resultsData -and $resultsData.Count -gt 0) {
                        # Store results
                        $syncHash.ResultsJsonData = $resultsData

                        # Hide empty tab and create result tabs
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
                        Write-DebugOutput -Message "Successfully loaded $($syncHash.ResultsJsonData.Count) results" -Source "Update-ResultsTab" -Level "Info"

                    } else {
                        # Show empty results
                        $syncHash.ResultsEmptyTab.Visibility = "Visible"
                        $syncHash.ResultsTabControl.SelectedItem = $syncHash.ResultsEmptyTab
                        Update-ResultsCount 0

                        # Reset empty tab content to default "no results" message
                        $emptyContent = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        VerticalScrollBarVisibility="Auto"
        HorizontalScrollBarVisibility="Auto">
    <StackPanel Margin="20" HorizontalAlignment="Center" VerticalAlignment="Center">
        <TextBlock Text="No ScubaGear reports found"
                   FontSize="16"
                   TextAlignment="Center"
                   Foreground="{DynamicResource MutedTextBrush}"
                   Margin="10"/>
        <TextBlock Text="Run ScubaGear to generate reports that will appear here."
                   FontSize="12"
                   TextAlignment="Center"
                   Foreground="{DynamicResource MutedTextBrush}"
                   Margin="10"/>
    </StackPanel>
</ScrollViewer>
"@
                        try {
                            $emptyControl = [Windows.Markup.XamlReader]::Parse($emptyContent)
                            $syncHash.ResultsEmptyTab.Content = $emptyControl
                        } catch {
                            Write-DebugOutput -Message "Error creating empty content: $($_.Exception.Message)" -Source "Update-ResultsTab" -Level "Warning"
                        }

                        Write-DebugOutput -Message "No results found in search paths" -Source "Update-ResultsTab" -Level "Info"
                    }

                } else {
                    # Job failed or stopped
                    $jobErrors = Receive-Job -Job $job -ErrorAction SilentlyContinue
                    $errorMessage = if ($jobErrors) { $jobErrors -join "; " } else { "Job failed with state: $($job.State)" }

                    Write-DebugOutput -Message "Job failed with state: $($job.State). Error: $errorMessage" -Source "Update-ResultsTab" -Level "Error"

                    # Hide progress indicator
                    $syncHash.ResultsScanProgress.Visibility = "Collapsed"
                    $syncHash.ResultsScanInProgress = $false

                    # Show error state
                    $syncHash.ResultsEmptyTab.Visibility = "Visible"
                    $syncHash.ResultsTabControl.SelectedItem = $syncHash.ResultsEmptyTab
                    Update-ResultsCount 0

                    $errorContent = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        VerticalScrollBarVisibility="Auto"
        HorizontalScrollBarVisibility="Auto">
    <StackPanel Margin="20" HorizontalAlignment="Center" VerticalAlignment="Center">
        <TextBlock Text="Error scanning for reports"
                   FontSize="16"
                   TextAlignment="Center"
                   Foreground="Red"
                   Margin="10"/>
        <TextBlock Text="$errorMessage"
                   FontSize="12"
                   TextAlignment="Center"
                   Foreground="{DynamicResource MutedTextBrush}"
                   TextWrapping="Wrap"
                   MaxWidth="400"
                   Margin="10"/>
    </StackPanel>
</ScrollViewer>
"@
                    try {
                        $errorControl = [Windows.Markup.XamlReader]::Parse($errorContent)
                        $syncHash.ResultsEmptyTab.Content = $errorControl
                    } catch {
                        Write-DebugOutput -Message "Error creating error content: $($_.Exception.Message)" -Source "Update-ResultsTab" -Level "Warning"
                    }
                }

            } catch {
                Write-DebugOutput -Message "Error processing job results: $($_.Exception.Message)" -Source "Update-ResultsTab" -Level "Error"

                # Hide progress indicator
                $syncHash.ResultsScanProgress.Visibility = "Collapsed"
                $syncHash.ResultsScanInProgress = $false

                # Show error state
                $syncHash.ResultsEmptyTab.Visibility = "Visible"
                $syncHash.ResultsTabControl.SelectedItem = $syncHash.ResultsEmptyTab
                Update-ResultsCount 0
            } finally {
                # Clean up the job
                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            }
        } else {
            # Job still running - update status if needed
            $syncHash.ResultsScanStatus.Text = "Scanning for ScubaGear reports..."
        }
    }.GetNewClosure())

    # Start the timer
    $timer.Start()

    Write-DebugOutput -Message "Background job started for results scanning (Job ID: $($job.Id))" -Source $MyInvocation.MyCommand -Level "Info"
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

    # Create folder-style header using text prefix
    $newTab.Header = "Report: $($Report.TabHeader)"

    $newTab.Name = "Result_$($Report.ReportName -Replace '\W+', '_')"

    # Load content immediately instead of lazy loading
    try {
        if (Test-Path $Report.JsonResultsPath) {
            $jsonContent = Get-Content $Report.JsonResultsPath -Raw
            $scubaData = $jsonContent | ConvertFrom-Json

            # Validate the data
            $isValidData = Test-ResultsDataValidity -ScubaData $scubaData -ReportPath $Report.ReportPath

            if ($isValidData) {
                $relativeTimeString = $Report.RelativeTime + " (" + $Report.ReportTimeStamp + ")"
                $reportContent = New-ResultsContent -ScubaData $scubaData -ReportPath $Report.ReportPath -RelativeTime $relativeTimeString
                $newTab.Content = $reportContent
            } else {
                $errorTab = New-ResultsNoDataTab -ReportPath $Report.ReportPath -Message "Report data appears to be corrupted or incomplete.`n`nThe ScubaResults JSON file contains invalid summary data.`n`nThis may indicate the ScubaGear scan was interrupted or encountered errors."
                $newTab.Content = $errorTab
            }
        } else {
            $errorTab = New-ResultsNoDataTab -ReportPath $Report.ReportPath -Message "JSON file not found: $($Report.JsonResultsPath)"
            $newTab.Content = $errorTab
        }
    } catch {
        Write-DebugOutput -Message "Error loading report content: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        $errorTab = New-ResultsNoDataTab -ReportPath $Report.ReportPath -Message "Error loading report content: $($_.Exception.Message)"
        $newTab.Content = $errorTab
    }

    # Add to main tab control
    $syncHash.ResultsTabControl.Items.Add($newTab)
    Write-DebugOutput -Message "Added report tab with immediate content loading: $($Report.TabHeader)" -Source $MyInvocation.MyCommand -Level "Info"
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

Function New-ResultsContent {
    <#
    .SYNOPSIS
    Creates the content for a results tab using the provided ScubaData.
    Optimized for faster loading with simplified product tabs.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "ReportPath")]
    param(
        [PSCustomObject[]]$ScubaData,
        [string]$ReportPath,
        [string]$RelativeTime
    )

    Write-DebugOutput -Message "New-ResultsContent called for report: $ReportPath" -Source $MyInvocation.MyCommand -Level "Debug"

    # Safety check - validate data before processing
    if (-not $ScubaData) {
        return New-ResultsNoDataTab -ReportPath $ReportPath -Message "ScubaData is null - returning error tab"
    }

    if (-not $ScubaData.Summary -or -not $ScubaData.Results) {
        return New-ResultsNoDataTab -ReportPath $ReportPath -Message "ScubaData missing Summary or Results sections - returning error tab"
    }

    # Create simplified XAML template (without heavy product tabs initially)
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
                    <TextBlock Text="ScubaGear Assessment Report" FontSize="18" FontWeight="Bold" Margin="0,0,0,6"/>

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

                <!-- Right side - Action buttons -->
                <StackPanel Grid.Column="1" HorizontalAlignment="Right" VerticalAlignment="Top">
                    <Button Name="OpenHtmlBtn" Style="{DynamicResource PrimaryButton}" Content="Open Full HTML Report"
                            Margin="0,0,0,6" Width="190" Height="32"/>
                    <Button Name="OpenFolderBtn" Style="{DynamicResource SecondaryButton}" Content="Open Report Folder"
                            Width="190" Margin="0,0,0,8" Height="32"/>
                    <Button Name="OpenYamlBtn" Style="{DynamicResource SecondaryButton}" Content="View Configuration"
                            Width="190" Margin="0,0,0,8" Height="32" Visibility="Collapsed"/>

                    <StackPanel VerticalAlignment="bottom">
                        <TextBlock Text="Report UUID:" FontSize="10" Foreground="LightGray"/>
                        <TextBlock Text="{REPORT_UUID}" FontSize="10" FontFamily="Consolas" Margin="0,0,0,0" Foreground="Gray"/>
                    </StackPanel>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Summary Section Only (Fast Loading) -->
        <Border Style="{DynamicResource Card}" Margin="0,0,0,8">
            <StackPanel Margin="12">
                <TextBlock Text="Baseline Conformance Summary" FontSize="16" FontWeight="SemiBold" Margin="0,0,0,8"/>
                <ItemsControl Name="SummaryItemsControl">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Border Style="{DynamicResource Card}" Margin="0,0,0,4">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="280"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>

                                    <TextBlock Grid.Column="0" FontSize="12" Text="{Binding Product}" FontWeight="SemiBold"
                                            Foreground="Blue" TextDecorations="Underline"
                                            VerticalAlignment="Center"/>

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
        </Border>

        <!-- Product Detail Tabs -->
        <Border Style="{DynamicResource Card}" Margin="0,0,0,8">
            <StackPanel Margin="12">
                <TextBlock Text="Detailed Product Results" FontSize="16" FontWeight="SemiBold" Margin="0,0,0,8"/>

                <TabControl Name="ProductTabControl" Margin="0,8,0,0">
                    {PRODUCT_TABS}
                </TabControl>
            </StackPanel>
        </Border>

    </StackPanel>
</ScrollViewer>
"@

    # Process the data and replace placeholders
    $processedXaml = $xamlTemplate

    # Replace tenant information placeholders with proper XML escaping
    function XmlEscape([string]$s) {
        if ($null -eq $s) { return "" }
        $s = [string]$s
        # Remove control characters that are illegal in XML
        $s = $s -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''
        # Replace special XML characters with entities
        $s = $s -replace '&', '&amp;'
        $s = $s -replace '<', '&lt;'
        $s = $s -replace '>', '&gt;'
        $s = $s -replace '"', '&quot;'
        $s = $s -replace "'", '&apos;'
        return $s
    }

    $displayName = XmlEscape([string]$ScubaData.MetaData.DisplayName)
    $domainName = XmlEscape([string]$ScubaData.MetaData.DomainName)
    $tenantId = XmlEscape([string]$ScubaData.MetaData.TenantId)
    $scubaVersion = XmlEscape($(if ($ScubaData.MetaData.ToolVersion) { [string]$ScubaData.MetaData.ToolVersion } else { "Unknown" }))
    $reportUuid = XmlEscape($(if ($ScubaData.MetaData.ReportUUID) { [string]$ScubaData.MetaData.ReportUUID } else { "Unknown" }))

    $processedXaml = $processedXaml -replace '{DISPLAY_NAME}', $displayName
    $processedXaml = $processedXaml -replace '{DOMAIN_NAME}', $domainName
    $processedXaml = $processedXaml -replace '{TENANT_ID}', $tenantId
    $processedXaml = $processedXaml -replace '{REPORT_DATE}', (XmlEscape([string]$RelativeTime))
    $processedXaml = $processedXaml -replace '{SCUBA_VERSION}', $scubaVersion
    $processedXaml = $processedXaml -replace '{REPORT_UUID}', $reportUuid

    # Generate product tabs
    $productTabsXaml = ""
    foreach ($productAbbr in ($ScubaData.Summary | Get-Member -MemberType NoteProperty).Name) {
        # Try to get display name from UIConfigs first, fallback to switch statement
        $productDisplayName = $syncHash.UIConfigs.products | Where-Object { $_.Id -eq $productAbbr } | Select-Object -ExpandProperty Name

        # Escape the product display name for XML
        $safeProductDisplayName = $productDisplayName -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'

        # Generate groups content for this product
        $groupsContent = ""
        if ($ScubaData.Results.$productAbbr) {
            foreach ($group in $ScubaData.Results.$productAbbr) {
                $groupNumber = if ($group.GroupNumber) { [string]$group.GroupNumber } else { "" }
                $groupName = if ($group.GroupName) { [string]$group.GroupName } else { "Unknown Group" }
                $groupHeader = if ($groupNumber) { "$groupNumber. $groupName" } else { $groupName }

                # Escape XML characters
                $safeGroupHeader = $groupHeader -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'

                # Generate controls for this group
                $controlsContent = ""
                if ($group.Controls) {
                    foreach ($control in $group.Controls) {
                        $controlId = if ($control."Control ID") { [string]$control."Control ID" } else { "Unknown" }
                        $result = if ($control.Result) { [string]$control.Result } else { "N/A" }
                        $criticality = if ($control.Criticality) { [string]$control.Criticality } else { "" }
                        $requirement = if ($control.Requirement) { [string]$control.Requirement } else { "" }

                        # Truncate requirement if too long
                        if ($requirement.Length -gt 100) {
                            $requirement = $requirement.Substring(0, 100) + "..."
                        }

                        # Color based on result
                        $resultColor = switch ($result) {
                            "Pass" { "#28a745" }
                            "Fail" { "#dc3545" }
                            "Warning" { "#ffc107" }
                            "Manual" { "#6f42c1" }
                            "Error" { "#fd7e14" }
                            default { "#6c757d" }
                        }

                # Escape XML characters more thoroughly
                $safeControlId = $controlId -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
                $safeResult = $result -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
                $safeCriticality = $criticality -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'
                $safeRequirement = $requirement -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'

                        $controlsContent += @"
<Border BorderBrush="LightGray" BorderThickness="1" Margin="0,2" Padding="8" CornerRadius="3">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="120"/>
            <ColumnDefinition Width="60"/>
            <ColumnDefinition Width="150"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <TextBlock Grid.Column="0" Text="$safeControlId" FontWeight="SemiBold" VerticalAlignment="Top"/>
        <TextBlock Grid.Column="1" Text="$safeResult" Foreground="$resultColor" VerticalAlignment="Top"/>
        <TextBlock Grid.Column="2" Text="$safeCriticality" VerticalAlignment="Top"/>
        <TextBlock Grid.Column="3" Text="$safeRequirement" TextWrapping="Wrap" VerticalAlignment="Top"/>
    </Grid>
</Border>
"@
                    }
                }

                if ([string]::IsNullOrWhiteSpace($controlsContent)) {
                    $controlsContent = @"
<TextBlock Text="No control data available" FontStyle="Italic" Foreground="Gray" Margin="8"/>
"@
                }

                $groupsContent += @"
<Expander Header="$safeGroupHeader" Margin="0,0,0,8" IsExpanded="False">
    <StackPanel Margin="16,8,8,8">
        $controlsContent
    </StackPanel>
</Expander>
"@
            }
        }

        if ([string]::IsNullOrWhiteSpace($groupsContent)) {
            $groupsContent = @"
<TextBlock Text="No group data available for this product" FontStyle="Italic" Foreground="Gray" Margin="8"/>
"@
        }

        $productTabsXaml += @"
<TabItem Header="$safeProductDisplayName">
    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Margin="8">
        <StackPanel>
            $groupsContent
        </StackPanel>
    </ScrollViewer>
</TabItem>
"@
    }

    # Replace the product tabs placeholder
    $processedXaml = $processedXaml -replace '\{PRODUCT_TABS\}', $productTabsXaml

    # Sanitize XAML before parsing to prevent XML entity errors
    # Remove any illegal control characters
    if ($processedXaml -match '[\x00-\x08\x0B\x0C\x0E-\x1F]') {
        Write-DebugOutput -Message "Warning: Removing illegal control characters from XAML" -Source $MyInvocation.MyCommand -Level "Warning"
        $processedXaml = $processedXaml -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''
    }

    # Parse the XAML into a WPF control
    try {
        # Add debug logging before parsing
        Write-DebugOutput -Message "About to parse XAML of length: $($processedXaml.Length)" -Source $MyInvocation.MyCommand -Level "Debug"

        try {
            $reportControl = [Windows.Markup.XamlReader]::Parse($processedXaml)
        } catch [System.Xml.XmlException] {
            # Provide detailed context to help diagnose the malformed XML
            $xmlEx = $_.Exception
            Write-DebugOutput -Message "XmlException parsing XAML: $($xmlEx.Message) at Line $($xmlEx.LineNumber), Position $($xmlEx.LinePosition)" -Source $MyInvocation.MyCommand -Level "Error"

            # Dump the XAML to a temp file for debugging
            $dumpPath = Join-Path ([IO.Path]::GetTempPath()) ("ScubaGear_FailingReport_{0}.xaml" -f ([Guid]::NewGuid().ToString()))
            try {
                Set-Content -Path $dumpPath -Value $processedXaml -Encoding UTF8 -ErrorAction Stop
                Write-DebugOutput -Message "Dumped failing XAML to: $dumpPath" -Source $MyInvocation.MyCommand -Level "Error"
            } catch {
                Write-DebugOutput -Message "Failed to write XAML dump: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }

            # Try a conservative sanitization: escape stray '&' characters and retry once
            $sanitized = $processedXaml -replace '&(?!amp;|lt;|gt;|quot;|apos;|#\d+;)', '&amp;'
            Write-DebugOutput -Message "Attempting to parse sanitized XAML (escaped stray ampersands)" -Source $MyInvocation.MyCommand -Level "Warning"
            try {
                $reportControl = [Windows.Markup.XamlReader]::Parse($sanitized)
                Write-DebugOutput -Message "Successfully parsed sanitized XAML after fallback" -Source $MyInvocation.MyCommand -Level "Debug"
            } catch {
                Write-DebugOutput -Message "Sanitized XAML parse failed: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                throw $xmlEx # Rethrow the original XML exception with context
            }
        }
        Write-DebugOutput -Message "Successfully parsed simplified XAML report content" -Source $MyInvocation.MyCommand -Level "Debug"

        # Set up button event handlers
        $openHtmlBtn = $reportControl.FindName("OpenHtmlBtn")
        $openFolderBtn = $reportControl.FindName("OpenFolderBtn")
        $openYamlBtn = $reportControl.FindName("OpenYamlBtn")

        if ($openHtmlBtn) {
            $openHtmlBtn.Add_Click({
                #minimize main window
                $syncHash.Window.WindowState = [System.Windows.WindowState]::Minimized

                $htmlFile = Get-ChildItem -Path $ReportPath -Name "*.html" | Select-Object -First 1
                if ($htmlFile) {
                    $htmlPath = Join-Path $ReportPath $htmlFile
                    Start-Process $htmlPath
                } else {
                    $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.HtmlReportNotFound, $syncHash.UIConfigs.localeTitles.ReportNotFound, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                }
            }.GetNewClosure())
        }

        if ($openFolderBtn) {
            $openFolderBtn.Add_Click({
                Start-Process "explorer.exe" -ArgumentList $ReportPath
            }.GetNewClosure())
        }

        # YAML Configuration button
        if ($openYamlBtn) {
            $yamlConfigPath = Join-Path $ReportPath "ScubaGearConfiguration.yaml"
            if (Test-Path $yamlConfigPath) {
                $openYamlBtn.Visibility = "Visible"
                $openYamlBtn.Add_Click({
                    try {
                        Show-ConfigurationViewer -ConfigFilePath $yamlConfigPath
                    } catch {
                        $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.ConfigurationViewerError -f $_.Exception.Message, $syncHash.UIConfigs.localeTitles.ConfigurationViewerError, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                    }
                }.GetNewClosure())
            }
        }

        # Populate summary data (this is fast)
        $summaryItems = @()
        foreach ($productAbbr in ($ScubaData.Summary | Get-Member -MemberType NoteProperty).Name) {
            $productData = $ScubaData.Summary.$productAbbr

            $displayName = $syncHash.UIConfigs.products | Where-Object { $_.Id -eq $productAbbr } | Select-Object -ExpandProperty Name

            # Build status badges quickly
            $statusItems = @()
            $passes = [string]$productData.Passes
            $warnings = [string]$productData.Warnings
            $manual = [string]$productData.Manual
            $errors = [string]$productData.Errors

            if ([int]$passes -gt 0) {
                $statusItems += [PSCustomObject]@{ Text = "PASS: $passes pass$(if([int]$passes -gt 1){'es'})"; Color = "#28a745"; TextColor = "White" }
            }
            if ([int]$warnings -gt 0) {
                $statusItems += [PSCustomObject]@{ Text = "WARN: $warnings warning$(if([int]$warnings -gt 1){'s'})"; Color = "#ffc107"; TextColor = "#212529" }
            }
            if ([int]$failures -gt 0) {
                $statusItems += [PSCustomObject]@{ Text = "FAIL: $failures failure$(if([int]$failures -gt 1){'s'})"; Color = "#dc3545"; TextColor = "White" }
            }
            if ([int]$manual -gt 0) {
                $statusItems += [PSCustomObject]@{ Text = "MANUAL: $manual manual check$(if([int]$manual -gt 1){'s'})"; Color = "#6f42c1"; TextColor = "White" }
            }
            if ([int]$errors -gt 0) {
                $statusItems += [PSCustomObject]@{ Text = "ERROR: $errors error$(if([int]$errors -gt 1){'s'})"; Color = "#fd7e14"; TextColor = "White" }
            }

            $summaryItems += [PSCustomObject]@{ Product = $displayName; StatusItems = $statusItems }
        }

        $summaryItemsControl = $reportControl.FindName("SummaryItemsControl")
        if ($summaryItemsControl) {
            $summaryItemsControl.ItemsSource = $summaryItems
        }

        return $reportControl

    } catch {
        Write-DebugOutput -Message "Error parsing XAML: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"

        # Save the processed XAML to a temp file for debugging
        $dumpPath = $null
        try {
            $dumpPath = Join-Path ([IO.Path]::GetTempPath()) ("ScubaGear_FailingReport_{0}.xaml" -f ([Guid]::NewGuid().ToString()))
            Set-Content -Path $dumpPath -Value $processedXaml -Encoding UTF8 -ErrorAction Stop
            Write-DebugOutput -Message "Dumped failing XAML to: $dumpPath" -Source $MyInvocation.MyCommand -Level "Error"
        } catch {
            Write-DebugOutput -Message "Failed to write XAML dump: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        }

        $errorMessage = "Error creating simplified report: $($_.Exception.Message)"
        if ($dumpPath) {
            $errorMessage += "`n`nFailing XAML saved to: $dumpPath"
        }

        return New-ResultsNoDataTab -ReportPath $ReportPath -Message $errorMessage
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
        Header="&#x1F512; {GROUP_HEADER}"
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

    $outputPath = $syncHash.AdvancedSettingsData["OutPath"]
    if ([string]::IsNullOrEmpty($outputPath)) {
        $outputPath = Join-Path $env:USERPROFILE "Documents"
    }

    if (Test-Path $outputPath) {
        Start-Process "explorer.exe" -ArgumentList $outputPath
    } else {
        $syncHash.ShowMessageBox.Invoke(
            "Results folder not found: $outputPath",
            "Folder Not Found",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )
    }
}