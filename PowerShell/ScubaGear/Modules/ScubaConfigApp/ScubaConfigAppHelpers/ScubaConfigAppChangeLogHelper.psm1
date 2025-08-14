# Add this function after the other window functions (around line 1500)
Function Show-ChangelogWindow {
    <#
    .SYNOPSIS
    Opens a window displaying the ScubaConfigApp changelog.
    #>

    # Don't create multiple changelog windows
    if ($syncHash.ChangelogWindow -and -not $syncHash.ChangelogWindow.IsClosed) {
        $syncHash.ChangelogWindow.Activate()
        return
    }

    try {
        # Read the changelog file
        $changelogContent = ""
        if (Test-Path $syncHash.ChangelogPath) {
            $changelogContent = Get-Content $syncHash.ChangelogPath -Raw
            Write-DebugOutput -Message "Loaded changelog from: $($syncHash.ChangelogPath)" -Source $MyInvocation.MyCommand -Level "Debug"
        } else {
            $changelogContent = "Changelog file not found at: $($syncHash.ChangelogPath)"
            Write-DebugOutput -Message "Changelog file not found: $($syncHash.ChangelogPath)" -Source $MyInvocation.MyCommand -Level "Warning"
        }

        # Create the changelog window XAML
        $changelogWindowXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ScubaConfigApp Changelog"
        Height="700"
        Width="900"
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
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,16">
            <TextBlock Text="ScubaConfigApp Changelog" FontSize="18" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,16,0"/>
            <TextBlock x:Name="ChangelogPath_TextBlock" Text="" FontSize="11" Foreground="Gray" VerticalAlignment="Center"/>
        </StackPanel>

        <!-- Changelog Content -->
        <Border Grid.Row="1" BorderBrush="#D0D5E0" BorderThickness="1" CornerRadius="4">
            <TextBox x:Name="ChangelogContent_TextBox"
                     IsReadOnly="True"
                     VerticalScrollBarVisibility="Auto"
                     HorizontalScrollBarVisibility="Auto"
                     FontFamily="Consolas, Courier New, monospace"
                     FontSize="12"
                     Background="White"
                     Foreground="#333333"
                     Padding="12"
                     TextWrapping="Wrap"
                     AcceptsReturn="True"/>
        </Border>

        <!-- Footer -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,16,0,0">
            <Button x:Name="ChangelogClose_Button" Content="Close" Padding="12,6" IsCancel="True"/>
        </StackPanel>
    </Grid>
</Window>
"@

        # Parse XAML
        $changelogWindow = [Windows.Markup.XamlReader]::Parse($changelogWindowXaml)
        $syncHash.ChangelogWindow = $changelogWindow

        # Get references to controls
        $changelogTextBox = $changelogWindow.FindName("ChangelogContent_TextBox")
        $changelogPathTextBlock = $changelogWindow.FindName("ChangelogPath_TextBlock")
        $closeButton = $changelogWindow.FindName("ChangelogClose_Button")

        # Set content
        $changelogTextBox.Text = $changelogContent
        $changelogPathTextBlock.Text = "Source: $($syncHash.ChangelogPath)"

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
        [System.Windows.MessageBox]::Show("Failed to open changelog window: $($_.Exception.Message)", "Changelog Window Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}