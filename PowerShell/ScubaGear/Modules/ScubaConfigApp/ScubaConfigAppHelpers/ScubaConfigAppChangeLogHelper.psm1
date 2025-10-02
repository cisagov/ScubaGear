# Add this function after the other window functions (around line 1500)
Function Show-ChangelogWindow {
    <#
    .SYNOPSIS
    Opens a window displaying the latest ScubaConfigApp changelog entry.
    #>

    # Don't create multiple changelog windows
    if ($syncHash.ChangelogWindow -and -not $syncHash.ChangelogWindow.IsClosed) {
        $syncHash.ChangelogWindow.Activate()
        return
    }

    try {
        # Read the changelog file
        $latestEntryContent = ""

        if (Test-Path $syncHash.ChangelogPath) {
            $fullChangelogContent = Get-Content $syncHash.ChangelogPath
            Write-DebugOutput -Message "Loaded changelog from: $($syncHash.ChangelogPath)" -Source $MyInvocation.MyCommand -Level "Debug"

            # Extract only the latest changelog entry (first ## section)
            $inLatestEntry = $false
            $latestEntryLines = @()

            foreach ($line in $fullChangelogContent) {
                if ($line -match '^## .*') {
                    if ($inLatestEntry) {
                        # We've hit the next version, stop collecting
                        break
                    } else {
                        # This is the first version entry, start collecting
                        $inLatestEntry = $true
                        # Remove the ## and clean up the line
                        $cleanedLine = $line -replace '^## ', ''
                        $latestEntryLines += "Version: $cleanedLine"
                    }
                } elseif ($inLatestEntry) {
                    # Remove any remaining # markdown headers for cleaner display
                    $cleanedLine = $line -replace '^### ', '' -replace '^#### ', '  * '
                    $latestEntryLines += $cleanedLine
                }
            }

            $latestEntryContent = $latestEntryLines -join "`r`n"

            if ([string]::IsNullOrWhiteSpace($latestEntryContent)) {
                $latestEntryContent = "No changelog entries found."
            }

        } else {
            $latestEntryContent = "Changelog file not found at: $($syncHash.ChangelogPath)"
            Write-DebugOutput -Message "Changelog file not found: $($syncHash.ChangelogPath)" -Source $MyInvocation.MyCommand -Level "Warning"
        }

        # Create the changelog window XAML
        $changelogWindowXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="What's New - ScubaConfigApp"
        Height="600"
        Width="800"
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
            <TextBlock Text="What's New in Scuba Configuration Editor" FontSize="18" FontWeight="Bold" Margin="0,0,0,8"/>
            <TextBlock Text="Latest changelog entry - click 'View Full Changelog' below to see complete version history"
                       FontSize="12" Foreground="Gray" TextWrapping="Wrap"/>
        </StackPanel>

        <!-- Latest Changelog Entry -->
        <Border Grid.Row="1" BorderBrush="#D0D5E0" BorderThickness="1" CornerRadius="4">
            <TextBox x:Name="ChangelogContent_TextBox"
                     IsReadOnly="True"
                     VerticalScrollBarVisibility="Auto"
                     HorizontalScrollBarVisibility="Disabled"
                     FontFamily="Segoe UI"
                     FontSize="12"
                     Background="White"
                     Foreground="#333333"
                     Padding="16"
                     TextWrapping="Wrap"
                     AcceptsReturn="True"
                     BorderThickness="0"/>
        </Border>

        <!-- Footer -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
            <Button x:Name="ViewFullChangelog_Button" Content="View Full Changelog" Padding="12,6" Margin="0,0,12,0"/>
            <Button x:Name="ChangelogClose_Button" Content="Close" Padding="12,6" IsCancel="True"/>
        </StackPanel>
    </Grid>
</Window>
"@

        # Parse XAML
        $changelogWindow = [Windows.Markup.XamlReader]::Parse($changelogWindowXaml)
        $syncHash.ChangelogWindow = $changelogWindow
        $syncHash.ChangelogWindow.Icon = $syncHash.ImgPath

        # Get references to controls
        $changelogTextBox = $changelogWindow.FindName("ChangelogContent_TextBox")
        $viewFullChangelogButton = $changelogWindow.FindName("ViewFullChangelog_Button")
        $closeButton = $changelogWindow.FindName("ChangelogClose_Button")

        # Set content
        $changelogTextBox.Text = $latestEntryContent

        # Event handlers
        $viewFullChangelogButton.Add_Click({
            try {
                # Always open the changelog file in Microsoft Edge
                $edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
                if (Test-Path $edgePath) {
                    Start-Process -FilePath $edgePath -ArgumentList $syncHash.ChangelogPath
                    Write-DebugOutput -Message "Opened full changelog file in Edge: $($syncHash.ChangelogPath)" -Source $MyInvocation.MyCommand -Level "Info"
                } else {
                    # Fallback to default application if Edge is not found
                    Invoke-Item -Path $syncHash.ChangelogPath
                    Write-DebugOutput -Message "Edge not found, opened changelog with default app: $($syncHash.ChangelogPath)" -Source $MyInvocation.MyCommand -Level "Info"
                }
            } catch {
                Write-DebugOutput -Message "Error opening full changelog: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                $syncHash.ShowMessageBox.Invoke("Could not open full changelog file: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            }
        })

        $closeButton.Add_Click({
            $syncHash.ChangelogWindow.Close()
        })

        # Handle window closing
        $changelogWindow.Add_Closing({
            $syncHash.ChangelogWindow = $null
        })

        # Set owner if main window exists
        if ($syncHash.Window) {
            $changelogWindow.Owner = $syncHash.Window
        }

        # Show the window
        $syncHash.ChangelogWindow.Show()
        $syncHash.ChangelogWindow.Activate()

        Write-DebugOutput -Message "Changelog window opened successfully" -Source $MyInvocation.MyCommand -Level "Info"

    } catch {
        Write-DebugOutput -Message "Error creating changelog window: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        $syncHash.ShowMessageBox.Invoke("Failed to open changelog window: $($_.Exception.Message)", "Changelog Window Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}