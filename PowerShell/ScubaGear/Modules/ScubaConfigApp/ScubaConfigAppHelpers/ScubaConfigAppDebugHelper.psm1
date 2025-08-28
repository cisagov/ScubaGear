Function Get-DebugSanitizedValue{
    <#
    .SYNOPSIS
    Creates a consistent fake replacement for sensitive values.
    .DESCRIPTION
    This function takes a sensitive value and returns a consistent fake replacement,
    storing the mapping for troubleshooting purposes.
    #>
    param(
        [string]$OriginalValue,
        [string]$ValueType
    )

    # Ensure DebugSanitizeMapping is initialized
    if (-not $syncHash.DebugSanitizeMapping) {
        $syncHash.DebugSanitizeMapping = @{}
    }

    # Check if we already have a mapping for this value
    if ($syncHash.DebugSanitizeMapping.ContainsKey($OriginalValue)) {
        return $syncHash.DebugSanitizeMapping[$OriginalValue]
    }

    # Generate fake replacement based on type
    $fakeValue = switch ($ValueType) {
        "email" {
            # Generate consistent fake email like user1@example.com, user2@example.com, etc.
            $userCount = ($syncHash.DebugSanitizeMapping.Values | Where-Object { $_ -like "*@example.com" }).Count + 1
            "user$userCount@example.com"
        }
        "domain" {
            # Generate consistent fake domain like domain1.com, domain2.com, etc.
            $domainCount = ($syncHash.DebugSanitizeMapping.Values | Where-Object { $_ -like "domain*.com" }).Count + 1
            "domain$domainCount.com"
        }
        "guid" {
            # Generate consistent fake GUID using incrementing pattern
            $guidCount = ($syncHash.DebugSanitizeMapping.Values | Where-Object { $_ -match "^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$" }).Count
            $hexBase = ($guidCount + 1).ToString("x").PadLeft(8, '0')
            "$hexBase-$($hexBase.Substring(0,4))-$($hexBase.Substring(0,4))-$($hexBase.Substring(0,4))-$($hexBase.PadRight(12, $hexBase.Substring(0,1)))"
        }
        "semicolonList" {
            # Handle semicolon-separated lists (like user principal names)
            $listCount = ($syncHash.DebugSanitizeMapping.Values | Where-Object { $_ -like "*user*@example.com*" }).Count + 1
            "User $listCount;user$listCount@example.com"
        }
        default {
            # Generic replacement for unknown types
            $genericCount = ($syncHash.DebugSanitizeMapping.Values | Where-Object { $_ -like "sanitized-value-*" }).Count + 1
            "sanitized-value-$genericCount"
        }
    }

    # Store the mapping
    $syncHash.DebugSanitizeMapping[$OriginalValue] = $fakeValue

    return $fakeValue
}

Function Get-DebugSanitizedString {
    <#
    .SYNOPSIS
    Sanitizes a string by replacing sensitive values with consistent fake ones.
    .DESCRIPTION
    This function scans a string for sensitive patterns and replaces them with
    consistent fake values based on the valueValidations configuration.
    #>
    param(
        [string]$InputString
    )

    if ([string]::IsNullOrEmpty($InputString)) {
        return $InputString
    }

    $sanitizedString = $InputString

    # Define built-in sensitive patterns as fallback
    $builtInPatterns = @{
        "guid" = @{
            pattern = '[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}'
            sensitive = $true
        }
        "email" = @{
            pattern = '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
            sensitive = $true
        }
        "domain" = @{
            pattern = '(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}'
            sensitive = $true
        }
    }

    # Use built-in patterns designed for text search instead of UIConfigs validation patterns
    # UIConfigs patterns are designed for validation (anchored) while built-in patterns are for finding within text
    $patternsToUse = $builtInPatterns

    Write-DebugOutput -Message "Using built-in patterns optimized for text search and sanitization" -Source $MyInvocation.MyCommand -Level "Debug"

    # Log the patterns being used for debugging
    foreach ($patternName in $patternsToUse.Keys) {
        $pattern = $patternsToUse[$patternName]
        Write-DebugOutput -Message "Using pattern '$patternName': $($pattern.pattern)" -Source $MyInvocation.MyCommand -Level "Debug"
    }

    # Process each validation pattern marked as sensitive
    foreach ($validationName in $patternsToUse.Keys) {
        $validation = $patternsToUse[$validationName]

        # Only process if marked as sensitive
        if ($validation.sensitive -eq $true -and $validation.pattern) {
            try {
                Write-DebugOutput -Message "Checking pattern '$validationName': $($validation.pattern)" -Source $MyInvocation.MyCommand -Level "Debug"

                # Find all matches in the string
                $regexMatches = [regex]::Matches($sanitizedString, $validation.pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

                Write-DebugOutput -Message "Found $($regexMatches.Count) matches for pattern '$validationName'" -Source $MyInvocation.MyCommand -Level "Debug"

                foreach ($match in $regexMatches) {
                    $originalValue = $match.Value
                    $fakeValue = Get-DebugSanitizedValue-OriginalValue $originalValue -ValueType $validationName

                    Write-DebugOutput -Message "Replacing '$originalValue' with '$fakeValue'" -Source $MyInvocation.MyCommand -Level "Debug"

                    # Replace all occurrences of this specific value
                    $sanitizedString = $sanitizedString -replace [regex]::Escape($originalValue), $fakeValue
                }
            }
            catch {
                Write-DebugOutput -Message "Error processing validation pattern '$validationName': $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }
        }
    }

    return $sanitizedString
}

Function Export-DebugLog {
    <#
    .SYNOPSIS
    Exports debug logs with optional sanitization and includes mapping file.
    .DESCRIPTION
    This function exports the debug log to a file, optionally sanitizing sensitive data.
    If sanitization is applied, it also creates a mapping file for troubleshooting.
    #>
    param(
        [bool]$SanitizeData = $false
    )

    try {
        # Check if debug data is available
        if (-not $syncHash.DebugLogData -or $syncHash.DebugLogData.Count -eq 0) {
            $syncHash.ShowMessageBox.Invoke(
                "No debug data available to export.",
                "Export Error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            )
            return
        }

        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $baseFileName = "ScubaGear-Debug-$timestamp"

        # Use SaveFileDialog for the main log file
        $saveDialog = New-Object Microsoft.Win32.SaveFileDialog
        $saveDialog.Filter = "Log Files (*.log)|*.log|Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
        $saveDialog.FileName = if ($SanitizeData) { "$baseFileName-sanitized.log" } else { "$baseFileName.log" }
        $saveDialog.Title = if ($SanitizeData) { $syncHash.UIConfigs.localeTitles.ExportSanitizedDebugLog } else { $syncHash.UIConfigs.localeTitles.ExportDebugLog }

        if ($saveDialog.ShowDialog() -eq $true) {
            $logFilePath = $saveDialog.FileName

            # Prepare log content
            if ($SanitizeData) {
                Write-DebugOutput -Message "Starting sanitized debug log export..." -Source $MyInvocation.MyCommand -Level "Info"

                # Ensure DebugSanitizeMapping is initialized
                if (-not $syncHash.DebugSanitizeMapping) {
                    $syncHash.DebugSanitizeMapping = @{}
                }

                # Clear existing mappings for fresh start
                $syncHash.DebugSanitizeMapping.Clear()

                # Create a snapshot copy of the debug log to avoid collection modification issues
                $debugLogSnapshot = @()
                try {
                    # Lock the collection while creating snapshot
                    $syncHash.DebugLogData.ForEach({ $debugLogSnapshot += $_ })
                }
                catch {
                    # Fallback: convert to array to create a copy
                    $debugLogSnapshot = $syncHash.DebugLogData.ToArray()
                }

                Write-DebugOutput -Message "Created snapshot of $($debugLogSnapshot.Count) debug log entries for sanitization" -Source $MyInvocation.MyCommand -Level "Debug"

                # Join all log entries into a single string for more efficient processing
                $fullLogContent = $debugLogSnapshot -join "`n"
                Write-DebugOutput -Message "Processing entire log content ($(($fullLogContent).Length) characters) for sanitization..." -Source $MyInvocation.MyCommand -Level "Debug"

                # Sanitize the entire content at once instead of line by line
                $sanitizedContent = Get-DebugSanitizedString -InputString $fullLogContent

                # Write sanitized content to file
                $sanitizedContent | Out-File -FilePath $logFilePath -Encoding UTF8

                # Create mapping file if there are any mappings
                if ($syncHash.DebugSanitizeMapping.Count -gt 0) {
                    $mappingFilePath = $logFilePath -replace '\.(log|txt)$', '-mapping.json'

                    # Create mapping data with metadata
                    $mappingData = @{
                        metadata = @{
                            exportTimestamp = $timestamp
                            totalMappings = $syncHash.DebugSanitizeMapping.Count
                            logFilePath = Split-Path $logFilePath -Leaf
                            description = "Sanitization mappings for troubleshooting. Original values on left, sanitized values on right."
                        }
                        mappings = $syncHash.DebugSanitizeMapping
                    }

                    # Export mapping to JSON
                    $mappingData | ConvertTo-Json -Depth 3 | Out-File -FilePath $mappingFilePath -Encoding UTF8

                    # Update status with both files
                    $syncHash.DebugStatus_TextBlock.Text = $syncHash.UIConfigs.localeStatusMessages.SanitizedLogExported -f $saveDialog.FileName, (Split-Path $mappingFilePath -Leaf)

                    # Show success message with mapping info
                    $syncHash.ShowMessageBox.Invoke(
                        $syncHash.UIConfigs.localeProgressMessages.SanitizedDebugLogExportSuccess -f $saveDialog.FileName, $mappingFilePath,
                        $syncHash.UIConfigs.localeTitles.ExportSuccessful,
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Information
                    )
                } else {
                    $syncHash.DebugStatus_TextBlock.Text = $syncHash.UIConfigs.localeStatusMessages.DebugLogExportedNoSensitiveData -f $saveDialog.FileName

                    $syncHash.ShowMessageBox.Invoke(
                        $syncHash.UIConfigs.localeProgressMessages.DebugLogExportNoSensitiveData -f $saveDialog.FileName,
                        $syncHash.UIConfigs.localeTitles.ExportSuccessful,
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Information
                    )
                }
            } else {
                # Export raw debug logs without sanitization
                # Create a snapshot copy to avoid collection modification issues
                $debugLogSnapshot = @()
                try {
                    # Lock the collection while creating snapshot
                    $syncHash.DebugLogData.ForEach({ $debugLogSnapshot += $_ })
                }
                catch {
                    # Fallback: convert to array to create a copy
                    $debugLogSnapshot = $syncHash.DebugLogData.ToArray()
                }

                Write-DebugOutput -Message "Created snapshot of $($debugLogSnapshot.Count) debug log entries for export" -Source $MyInvocation.MyCommand -Level "Debug"

                $debugLogSnapshot | Out-File -FilePath $logFilePath -Encoding UTF8
                $syncHash.DebugStatus_TextBlock.Text = $syncHash.UIConfigs.localeStatusMessages.DebugLogExported -f $saveDialog.FileName

                $syncHash.ShowMessageBox.Invoke(
                    $syncHash.UIConfigs.localeProgressMessages.DebugLogExportSuccess -f $saveDialog.FileName,
                    $syncHash.UIConfigs.localeTitles.ExportSuccessful,
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Information
                )
            }

            Write-DebugOutput -Message "Debug log export completed: $logFilePath (Sanitized: $SanitizeData)" -Source $MyInvocation.MyCommand -Level "Info"
        }
    } catch {
        $syncHash.DebugStatus_TextBlock.Text = $syncHash.UIConfigs.localeStatusMessages.ExportFailed -f $_.Exception.Message
        $syncHash.ShowMessageBox.Invoke(
            $syncHash.UIConfigs.localeProgressMessages.DebugLogExportError -f $_.Exception.Message,
            $syncHash.UIConfigs.localeTitles.ExportError,
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        Write-DebugOutput -Message "Debug log export failed: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}
Function Write-DebugOutput {
    <#
    .SYNOPSIS
    Writes debug output messages to the debug queue when debug mode is enabled.
    .DESCRIPTION
    This Function adds timestamped debug messages to the syncHash debug queue for troubleshooting and monitoring UI operations.
    Enhanced to also update the floating debug window if open.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Source,

        [ValidateSet("Verbose", "Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )

    if ($syncHash.UIConfigs.DebugMode) {

        #get BIAS time
        [string]$LogTime = (Get-Date -Format 'HH:mm:ss.fff').ToString()
        [string]$LogDate = (Get-Date -Format 'MM-dd-yyyy').ToString()
        [int32]$script:LogTimeZoneBias = [timezone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes
        [string]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias

        #  Get the file name of the source script
        If($Source){
            $ScriptSource = $Source
        }
        Else{
            Try {
                If ($script:MyInvocation.Value.ScriptName) {
                    [string]$ScriptSource = Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf -ErrorAction SilentlyContinue
                }
                Else {
                    [string]$ScriptSource = Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf -ErrorAction SilentlyContinue
                }
            }
            Catch {
                $ScriptSource = ''
            }
        }

        If($null -eq $ScriptSource) {
            $ScriptSource = ''
        }

        #generate CMTrace log format
        #$LogFormat = "<![LOG[$Message]LOG]!>" + "<time=`"$LogTimePlusBias`" " + "date=`"$LogDate`" " + "component=`"$ScriptSource`" " + "context=`"$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + "type=`"$Severity`" " + "thread=`"$PID`" " + "file=`"$ScriptSource`">"
        #[void]$syncHash.DebugLogData.Add( $LogFormat  )

        $formattedMessage = "[$LogDate][$LogTimePlusBias][$Level][$ScriptSource] $Message"
        # Add to debug log data
        [void]$syncHash.DebugLogData.Add( $formattedMessage )

        # Update debug window if it's open
        Update-DebugWindow -NewContent "$formattedMessage`r`n"
    }
}

# Debug search helper functions
Function Search-DebugLog {
    param([string]$searchTerm)

    $syncHash.DebugSearchMatches = @()
    $syncHash.DebugSearchCurrentIndex = -1
    $syncHash.DebugSearchTerm = $searchTerm

    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        $syncHash.DebugSearchStatus_TextBlock.Text = ""
        $syncHash.DebugSearchPrev_Button.IsEnabled = $false
        $syncHash.DebugSearchNext_Button.IsEnabled = $false
        return
    }

    $debugText = $syncHash.DebugOutput_TextBox.Text
    if ([string]::IsNullOrEmpty($debugText)) {
        $syncHash.DebugSearchStatus_TextBlock.Text = $syncHash.UIConfigs.localeStatusMessages.NoSearchText
        $syncHash.DebugSearchPrev_Button.IsEnabled = $false
        $syncHash.DebugSearchNext_Button.IsEnabled = $false
        return
    }

    # Find all matches (case insensitive)
    $index = 0
    while (($index = $debugText.IndexOf($searchTerm, $index, [System.StringComparison]::OrdinalIgnoreCase)) -ne -1) {
        $syncHash.DebugSearchMatches += $index
        $index += $searchTerm.Length
    }

    if ($syncHash.DebugSearchMatches.Count -eq 0) {
        $syncHash.DebugSearchStatus_TextBlock.Text = "No matches found"
        $syncHash.DebugSearchPrev_Button.IsEnabled = $false
        $syncHash.DebugSearchNext_Button.IsEnabled = $false
    } else {
        $syncHash.DebugSearchCurrentIndex = 0
        $syncHash.DebugSearchStatus_TextBlock.Text = "Found $($syncHash.DebugSearchMatches.Count) matches"
        $syncHash.DebugSearchPrev_Button.IsEnabled = $true
        $syncHash.DebugSearchNext_Button.IsEnabled = $true
        Get-DebugSearchMatch
    }
}

Function Get-DebugSearchMatch {
    if ($syncHash.DebugSearchMatches.Count -eq 0 -or $syncHash.DebugSearchCurrentIndex -eq -1) {
        return
    }

    $matchIndex = $syncHash.DebugSearchMatches[$syncHash.DebugSearchCurrentIndex]
    $searchLength = $syncHash.DebugSearchTerm.Length

    # Select the match in the TextBox and scroll to it, but don't change focus
    $syncHash.DebugOutput_TextBox.SelectionStart = $matchIndex
    $syncHash.DebugOutput_TextBox.SelectionLength = $searchLength
    $syncHash.DebugOutput_TextBox.ScrollToLine($syncHash.DebugOutput_TextBox.GetLineIndexFromCharacterIndex($matchIndex))
    # Removed: $syncHash.DebugOutput_TextBox.Focus() - this was stealing focus from search box

    # Update status
    $currentMatch = $syncHash.DebugSearchCurrentIndex + 1
    $totalMatches = $syncHash.DebugSearchMatches.Count
    $syncHash.DebugSearchStatus_TextBlock.Text = "Match $currentMatch of $totalMatches"
}

Function Show-DebugWindow {
    <#
    .SYNOPSIS
    Creates and displays the floating debug window.
    #>

    # Don't create multiple debug windows
    if ($syncHash.DebugWindow -and -not $syncHash.DebugWindow.IsClosed) {
        $syncHash.DebugWindow.Activate()
        return
    }

    try {
        # Create debug window XAML
        $debugWindowXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ScubaGear Debug Console"
        Height="600"
        Width="1024"
        WindowStartupLocation="CenterOwner"
        Background="#F6FBFE"
        Foreground="#333333"
        ShowInTaskbar="True"
    Topmost="False">

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0" Orientation="Vertical" Margin="0,0,0,16">
            <!-- Controls Row -->
            <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                <TextBlock Text="Debug Console" FontSize="16" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,16,0"/>
                <CheckBox x:Name="DebugAutoScroll_CheckBox" Content="Auto-scroll" IsChecked="True" VerticalAlignment="Center" Margin="0,0,16,0"/>
                <CheckBox x:Name="DebugHideVerbose_CheckBox" Content="Hide Verbose Logs" IsChecked="False" VerticalAlignment="Center" Margin="16,0,16,0"/>
                <CheckBox x:Name="DebugHideDebug_CheckBox" Content="Hide Debug Logs" IsChecked="False" VerticalAlignment="Center" Margin="0,0,16,0"/>
                <Button x:Name="DebugClearLogs_Button" Content="Clear" Padding="8,4" Margin="16,0,8,0"/>
                <Button x:Name="DebugExport_Button" Content="Export" Padding="8,4" Margin="0,0,8,0"/>
                <CheckBox x:Name="DebugSanitizeExport_CheckBox" Content="Sanitize Export" IsChecked="False" VerticalAlignment="Center" Margin="16,0,0,0"/>
            </StackPanel>

            <!-- Search Row -->
            <StackPanel Orientation="Horizontal" Margin="0,0,0,0">
                <TextBlock VerticalAlignment="Center" Margin="0,0,8,0">
                    <TextBlock.Text>Search:</TextBlock.Text>
                </TextBlock>
                <TextBox x:Name="DebugSearch_TextBox" Width="500" Padding="4" Margin="0,0,8,0"
                         ToolTip="Enter search term and click Search button"/>
                <Button x:Name="DebugSearchStart_Button" Padding="6,2" Margin="0,0,8,0"
                        ToolTip="Start search for entered term">
                    <TextBlock Text="&#x1F50D; Search"/>
                </Button>
                <Button x:Name="DebugSearchPrev_Button" Padding="6,2" Margin="0,0,4,0"
                        ToolTip="Find previous match" IsEnabled="False">
                    <TextBlock Text="&#x2B06; Prev"/>
                </Button>
                <Button x:Name="DebugSearchNext_Button" Padding="6,2" Margin="0,0,8,0"
                        ToolTip="Find next match" IsEnabled="False">
                    <TextBlock Text="&#x2B07; Next"/>
                </Button>
                <Button x:Name="DebugClearSearch_Button" Padding="6,2" Margin="0,0,8,0"
                        ToolTip="Clear search and highlighting">
                    <TextBlock Text="&#x2716; Clear"/>
                </Button>
                <TextBlock x:Name="DebugSearchStatus_TextBlock" VerticalAlignment="Center" Margin="8,0,0,0"
                           Foreground="#666666" Text=""/>
            </StackPanel>
        </StackPanel>

        <!-- Debug Output -->
        <Border Grid.Row="1" BorderBrush="#D0D5E0" BorderThickness="1" CornerRadius="4">
            <TextBox x:Name="DebugOutput_TextBox"
                        IsReadOnly="True"
                        VerticalScrollBarVisibility="Auto"
                        HorizontalScrollBarVisibility="Auto"
                        FontFamily="Consolas, Courier New, monospace"
                        FontSize="12"
                        Background="#1E1E1E"
                        Foreground="#FFFFFF"
                        SelectionBrush="#FFD700"
                        SelectionTextBrush="#000000"
                        IsInactiveSelectionHighlightEnabled="True"
                        Padding="8"
                        TextWrapping="NoWrap"
                        AcceptsReturn="True"/>
        </Border>

        <!-- Footer -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
            <TextBlock x:Name="DebugStatus_TextBlock" Text="Debug console ready" Foreground="#666666" VerticalAlignment="Center" Margin="0,0,16,0"/>
        </StackPanel>
    </Grid>
</Window>
"@

        # Parse XAML
        $debugWindow = [Windows.Markup.XamlReader]::Parse($debugWindowXaml)
        $syncHash.DebugWindow = $debugWindow
        $syncHash.DebugWindow.Icon = $syncHash.ImgPath

        $syncHash.DebugOutput_TextBox = $debugWindow.FindName("DebugOutput_TextBox")
        $syncHash.DebugAutoScroll_CheckBox = $debugWindow.FindName("DebugAutoScroll_CheckBox")
        $syncHash.DebugStatus_TextBlock = $debugWindow.FindName("DebugStatus_TextBlock")

        #filter checkbox event handlers
        $syncHash.DebugHideVerbose_CheckBox = $debugWindow.FindName("DebugHideVerbose_CheckBox")
        $syncHash.DebugHideDebug_CheckBox = $debugWindow.FindName("DebugHideDebug_CheckBox")

        $syncHash.DebugHideVerbose_CheckBox.Add_Checked({
            Update-DebugDisplayFilter
        })

        $syncHash.DebugHideVerbose_CheckBox.Add_Unchecked({
            Update-DebugDisplayFilter
        })

        $syncHash.DebugHideDebug_CheckBox.Add_Checked({
            Update-DebugDisplayFilter
        })

        $syncHash.DebugHideDebug_CheckBox.Add_Unchecked({
            Update-DebugDisplayFilter
        })

        # Set up sanitize checkbox reference and event handlers
        $syncHash.DebugSanitizeExport_CheckBox = $debugWindow.FindName("DebugSanitizeExport_CheckBox")

        $syncHash.DebugSanitizeExport_CheckBox.Add_Checked({
            $syncHash.DebugStatus_TextBlock.Text = "Sanitization enabled - sensitive data will be replaced with consistent fake values"
        })

        $syncHash.DebugSanitizeExport_CheckBox.Add_Unchecked({
            $syncHash.DebugStatus_TextBlock.Text = "Sanitization disabled - original data will be exported"
        })

        # Set up search controls and variables
        $syncHash.DebugSearch_TextBox = $debugWindow.FindName("DebugSearch_TextBox")
        $syncHash.DebugSearchStart_Button = $debugWindow.FindName("DebugSearchStart_Button")
        $syncHash.DebugSearchPrev_Button = $debugWindow.FindName("DebugSearchPrev_Button")
        $syncHash.DebugSearchNext_Button = $debugWindow.FindName("DebugSearchNext_Button")
        $syncHash.DebugClearSearch_Button = $debugWindow.FindName("DebugClearSearch_Button")
        $syncHash.DebugSearchStatus_TextBlock = $debugWindow.FindName("DebugSearchStatus_TextBlock")

        # Search state variables
        $syncHash.DebugSearchMatches = @()
        $syncHash.DebugSearchCurrentIndex = -1
        $syncHash.DebugSearchTerm = ""

        # Search event handlers
        $syncHash.DebugSearchStart_Button.Add_Click({
            $searchTerm = $syncHash.DebugSearch_TextBox.Text
            Search-DebugLog -searchTerm $searchTerm
        })

        # Allow Enter key in search box to trigger search
        $syncHash.DebugSearch_TextBox.Add_KeyDown({
            if ($_.Key -eq "Return") {
                $searchTerm = $syncHash.DebugSearch_TextBox.Text
                Search-DebugLog -searchTerm $searchTerm
            }
        })

        $syncHash.DebugSearchPrev_Button.Add_Click({
            if ($syncHash.DebugSearchMatches.Count -gt 0) {
                $syncHash.DebugSearchCurrentIndex--
                if ($syncHash.DebugSearchCurrentIndex -lt 0) {
                    $syncHash.DebugSearchCurrentIndex = $syncHash.DebugSearchMatches.Count - 1
                }
                Get-DebugSearchMatch
            }
        })

        $syncHash.DebugSearchNext_Button.Add_Click({
            if ($syncHash.DebugSearchMatches.Count -gt 0) {
                $syncHash.DebugSearchCurrentIndex++
                if ($syncHash.DebugSearchCurrentIndex -ge $syncHash.DebugSearchMatches.Count) {
                    $syncHash.DebugSearchCurrentIndex = 0
                }
                Get-DebugSearchMatch
            }
        })

        $syncHash.DebugClearSearch_Button.Add_Click({
            $syncHash.DebugSearch_TextBox.Text = ""
            $syncHash.DebugOutput_TextBox.SelectionLength = 0
            $syncHash.DebugSearchStatus_TextBlock.Text = ""
            $syncHash.DebugSearchMatches = @()
            $syncHash.DebugSearchCurrentIndex = -1
            $syncHash.DebugSearchPrev_Button.IsEnabled = $false
            $syncHash.DebugSearchNext_Button.IsEnabled = $false
        })

        # Set up event handlers
        $debugWindow.FindName("DebugClearLogs_Button").Add_Click({
            $syncHash.DebugOutput_TextBox.Clear()
            $syncHash.DebugStatus_TextBlock.Text = "Debug output cleared"
        })

        $debugWindow.FindName("DebugExport_Button").Add_Click({
            try {
                $shouldSanitize = $syncHash.DebugSanitizeExport_CheckBox.IsChecked -eq $true

                if ($shouldSanitize) {
                    # Use sanitized export with mapping file
                    Export-DebugLog -SanitizeData $true
                } else {
                    # Use regular export (existing behavior)
                    Export-DebugLog -SanitizeData $false
                }
            } catch {
                $syncHash.DebugStatus_TextBlock.Text = "Export failed: $($_.Exception.Message)"
            }
        })

        # Handle window closing - set flag to prevent recursive calls
        $debugWindow.Add_Closing({

            # Set closing flag to prevent Hide-DebugWindow from calling Close again
            $syncHash.DebugWindowClosing = $true

            # Clean up references
            $syncHash.DebugWindow = $null
            $syncHash.DebugOutput_TextBox = $null
            $syncHash.DebugAutoScroll_CheckBox = $null
            $syncHash.DebugStatus_TextBlock = $null
        })

        # Set owner if main window exists
        if ($syncHash.Window) {
            $debugWindow.Owner = $syncHash.Window
        }

        # Show the window
        $syncHash.DebugWindow.Show()
        $syncHash.DebugWindow.Activate()

        # Update debug output with current log if available
        if ($syncHash.DebugLogData.Count -gt 0) {
            $debugText = $syncHash.DebugLogData -join "`r`n"
            $syncHash.DebugOutput_TextBox.Text = $debugText
            if ($syncHash.DebugAutoScroll_CheckBox.IsChecked) {
                $syncHash.DebugOutput_TextBox.ScrollToEnd()
            }
        }


        $syncHash.DebugStatus_TextBlock.Text = "Debug window opened successfully"
        Write-DebugOutput -Message "Debug window opened" -Source $MyInvocation.MyCommand -Level "Info"

    } catch {
        Write-DebugOutput -Message "Error creating debug window: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.FailedToOpenDebugWindow -f $_.Exception.Message, $syncHash.UIConfigs.localeTitles.DebugWindowError, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}

Function Hide-DebugWindow {
    try {
        # Check if we're already closing to prevent recursive calls
        if ($syncHash.DebugWindowClosing) {
            return
        }

        if ($syncHash.DebugWindow -and -not $syncHash.DebugWindow.IsClosed) {
            # Set the closing flag
            $syncHash.DebugWindowClosing = $true

            # Try to close the window
            $syncHash.DebugWindow.Close()

            Write-DebugOutput -Message "Debug window closed" -Source $MyInvocation.MyCommand -Level "Info"
        } else {
            # Window is already closed or doesn't exist, just clear references
            $syncHash.DebugWindow = $null
            $syncHash.DebugOutput_TextBox = $null
            $syncHash.DebugAutoScroll_CheckBox = $null
            $syncHash.DebugStatus_TextBlock = $null
            $syncHash.DebugWindowClosing = $false
        }
    } catch {
        Write-DebugOutput -Message "Error closing debug window: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"

        # Force clear all references regardless of error
        $syncHash.DebugWindow = $null
        $syncHash.DebugOutput_TextBox = $null
        $syncHash.DebugAutoScroll_CheckBox = $null
        $syncHash.DebugStatus_TextBlock = $null
        $syncHash.DebugWindowClosing = $false
    }
}



# Add this function to filter debug logs based on checkbox states
Function Update-DebugDisplayFilter {
    <#
    .SYNOPSIS
    Filters the debug output display based on the filter checkboxes.
    #>

    if (-not ($syncHash.DebugWindow -and -not $syncHash.DebugWindow.IsClosed)) {
        return
    }

    try {
        $syncHash.DebugWindow.Dispatcher.Invoke([Action]{
            # Get filter states
            $hideVerbose = $syncHash.DebugHideVerbose_CheckBox.IsChecked
            $hideDebug = $syncHash.DebugHideDebug_CheckBox.IsChecked

            # Filter the debug log data
            $filteredLogs = $syncHash.DebugLogData | Where-Object {
                $logLine = $_

                # Check if we should hide this log level
                if ($hideVerbose -and $logLine -match '\[Verbose\]') {
                    return $false
                }
                if ($hideDebug -and $logLine -match '\[Debug\]') {
                    return $false
                }

                return $true
            }

            # Update the display
            $syncHash.DebugOutput_TextBox.Text = $filteredLogs -join "`r`n"

            # Auto-scroll if enabled
            if ($syncHash.DebugAutoScroll_CheckBox.IsChecked) {
                $syncHash.DebugOutput_TextBox.ScrollToEnd()
            }

            # Update status
            $totalLogs = $syncHash.DebugLogData.Count
            $visibleLogs = $filteredLogs.Count
            $hiddenLogs = $totalLogs - $visibleLogs

            if ($syncHash.DebugStatus_TextBlock) {
                if ($hiddenLogs -gt 0) {
                    $syncHash.DebugStatus_TextBlock.Text = "Showing $visibleLogs of $totalLogs logs ($hiddenLogs hidden)"
                } else {
                    $syncHash.DebugStatus_TextBlock.Text = "Showing all $totalLogs logs"
                }
            }
        })
    } catch {
        Write-Error "Error updating debug filter: $($_.Exception.Message)"
    }
}

# Modified Update-DebugWindow function to respect filters when adding new content
Function Update-DebugWindow {
    <#
    .SYNOPSIS
    Updates the debug window with new content, respecting current filters.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "NewContent")]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NewContent
    )

    try {
        # Only update if debug window is open and valid
        if ($syncHash.DebugWindow -and -not $syncHash.DebugWindow.IsClosed) {
            # Use Dispatcher.Invoke to ensure thread safety
            $syncHash.DebugWindow.Dispatcher.Invoke([Action]{
                try {
                    # Check if this new content should be displayed based on filters
                    $hideVerbose = $syncHash.DebugHideVerbose_CheckBox.IsChecked
                    $hideDebug = $syncHash.DebugHideDebug_CheckBox.IsChecked

                    $shouldDisplay = $true
                    if ($hideVerbose -and $NewContent -match '\[Verbose\]') {
                        $shouldDisplay = $false
                    }
                    if ($hideDebug -and $NewContent -match '\[Debug\]') {
                        $shouldDisplay = $false
                    }

                    # Only append if it should be displayed
                    if ($shouldDisplay) {
                        # Ensure there's a newline before appending if TextBox has content and doesn't end with newline
                        $currentText = $syncHash.DebugOutput_TextBox.Text
                        if ($currentText.Length -gt 0 -and -not $currentText.EndsWith("`r`n") -and -not $currentText.EndsWith("`n")) {
                            $syncHash.DebugOutput_TextBox.AppendText("`r`n")
                        }

                        $syncHash.DebugOutput_TextBox.AppendText($NewContent)

                        # Auto-scroll if enabled
                        if ($syncHash.DebugAutoScroll_CheckBox.IsChecked) {
                            $syncHash.DebugOutput_TextBox.ScrollToEnd()
                        }
                    }

                    # Update status with timestamp
                    if ($syncHash.DebugStatus_TextBlock) {
                        $syncHash.DebugStatus_TextBlock.Text = "Last update: $(Get-Date -Format 'HH:mm:ss')"
                    }
                } catch {
                    Write-Error "Error in debug window update: $($_.Exception.Message)"
                }
            })
        }
    } catch {
        Write-Error "Error updating debug window: $($_.Exception.Message)"
    }
}