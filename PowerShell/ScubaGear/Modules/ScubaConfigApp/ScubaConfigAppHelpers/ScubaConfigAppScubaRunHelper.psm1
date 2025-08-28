Function Export-ConfigurationToResultsFolder {
    <#
    .SYNOPSIS
    Exports the current configuration YAML to the ScubaGear results folder.
    #>
    param([string]$ResultsFolder)

    try {
        if (-not (Test-Path $ResultsFolder)) {
            Write-DebugOutput -Message "Results folder not found: $ResultsFolder" -Source $MyInvocation.MyCommand -Level "Warning"
            return
        }

        # Generate current YAML configuration
        New-YamlPreview -NoRedirect
        $yamlContent = $syncHash.YamlPreview_TextBox.Text

        if ([string]::IsNullOrWhiteSpace($yamlContent)) {
            Write-DebugOutput -Message "No YAML content available to export" -Source $MyInvocation.MyCommand -Level "Warning"
            return
        }

        # Create configuration file in results folder
        $configFileName = "ScubaGearConfiguration.yaml"
        $configFilePath = Join-Path $ResultsFolder $configFileName

        # Write YAML content to file
        [System.IO.File]::WriteAllText($configFilePath, $yamlContent, [System.Text.Encoding]::UTF8)

        Write-DebugOutput -Message "Configuration exported to: $configFilePath" -Source $MyInvocation.MyCommand -Level "Info"

        # Add to output log
        $syncHash.ScubaRunOutput_TextBox.AppendText("Configuration file saved: $configFilePath`r`n")

        return $configFilePath
    }
    catch {
        Write-DebugOutput -Message "Error exporting configuration to results folder: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        return $null
    }
}

Function Show-ConfigurationViewer {
    <#
    .SYNOPSIS
    Opens a simple window to display the configuration file content.
    #>
    param([string]$ConfigFilePath)

    try {
        if (-not (Test-Path $ConfigFilePath)) {
            $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.ConfigurationFileNotFound -f $ConfigFilePath, $syncHash.UIConfigs.localeTitles.ConfigurationViewer, "OK", "Error")
            return
        }

        # Read configuration content
        $configContent = [System.IO.File]::ReadAllText($ConfigFilePath, [System.Text.Encoding]::UTF8)

        # Create a new window
        $configWindow = New-Object System.Windows.Window
        $configWindow.Title = "ScubaGear Configuration Viewer"
        $configWindow.Width = 800
        $configWindow.Height = 600
        $configWindow.WindowStartupLocation = "CenterOwner"
        $configWindow.Owner = $syncHash.Window
        $configWindow.Icon = $syncHash.Window.Icon

        # Create main grid
        $grid = New-Object System.Windows.Controls.Grid
        $configWindow.Content = $grid

        # Define rows
        $headerRow = New-Object System.Windows.Controls.RowDefinition
        $headerRow.Height = "Auto"
        $contentRow = New-Object System.Windows.Controls.RowDefinition
        $contentRow.Height = "*"
        $buttonRow = New-Object System.Windows.Controls.RowDefinition
        $buttonRow.Height = "Auto"

        $grid.RowDefinitions.Add($headerRow)
        $grid.RowDefinitions.Add($contentRow)
        $grid.RowDefinitions.Add($buttonRow)

        # Header
        $headerText = New-Object System.Windows.Controls.TextBlock
        $headerText.Text = "Configuration File: $(Split-Path $ConfigFilePath -Leaf)"
        $headerText.FontSize = 14
        $headerText.FontWeight = "Bold"
        $headerText.Margin = "10"
        $headerText.HorizontalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetRow($headerText, 0)
        $grid.Children.Add($headerText)

        # Content TextBox
        $contentTextBox = New-Object System.Windows.Controls.TextBox
        $contentTextBox.Text = $configContent
        $contentTextBox.IsReadOnly = $true
        $contentTextBox.AcceptsReturn = $true
        $contentTextBox.TextWrapping = "NoWrap"
        $contentTextBox.VerticalScrollBarVisibility = "Auto"
        $contentTextBox.HorizontalScrollBarVisibility = "Auto"
        $contentTextBox.FontFamily = "Consolas, Courier New, monospace"
        $contentTextBox.FontSize = 12
        $contentTextBox.Margin = "10,0,10,10"
        $contentTextBox.Background = "#F5F5F5"
        $contentTextBox.BorderBrush = $syncHash.Window.FindResource("BorderBrush")
        [System.Windows.Controls.Grid]::SetRow($contentTextBox, 1)
        $grid.Children.Add($contentTextBox)

        # Button panel
        $buttonPanel = New-Object System.Windows.Controls.StackPanel
        $buttonPanel.Orientation = "Horizontal"
        $buttonPanel.HorizontalAlignment = "Center"
        $buttonPanel.Margin = "10"
        [System.Windows.Controls.Grid]::SetRow($buttonPanel, 2)

        # Copy button
        $copyButton = New-Object System.Windows.Controls.Button
        $copyButton.Content = "Copy to Clipboard"
        $copyButton.Width = 120
        $copyButton.Height = 30
        $copyButton.Margin = "0,0,10,0"
        $copyButton.Add_Click({
            try {
                [System.Windows.Clipboard]::SetText($contentTextBox.Text)
                $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.ConfigurationCopiedToClipboard, $syncHash.UIConfigs.localeTitles.ConfigurationViewer, "OK", "Information")
            } catch {
                $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.FailedToCopyToClipboard -f $_.Exception.Message, $syncHash.UIConfigs.localeTitles.ConfigurationViewer, "OK", "Error")
            }
        })
        $buttonPanel.Children.Add($copyButton)

        # Close button
        $closeButton = New-Object System.Windows.Controls.Button
        $closeButton.Content = "Close"
        $closeButton.Width = 80
        $closeButton.Height = 30
        $closeButton.Add_Click({
            $configWindow.Close()
        })
        $buttonPanel.Children.Add($closeButton)

        $grid.Children.Add($buttonPanel)

        # Show window
        $configWindow.ShowDialog()
    }
    catch {
        $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.ConfigurationViewerError -f $_.Exception.Message, $syncHash.UIConfigs.localeTitles.ConfigurationViewer, "OK", "Error")
        Write-DebugOutput -Message "Error in Show-ConfigurationViewer: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

Function New-ScubaRunParameterControls {
    <#
    .SYNOPSIS
    Dynamically creates UI controls for ScubaRun parameters based on configuration.
    #>

    if (-not $syncHash.UIConfigs.ScubaRunConfig.powershell.parameters) {
        Write-DebugOutput -Message "No ScubaRun parameters defined in configuration" -Source $MyInvocation.MyCommand -Level "Info"
        return
    }

    # Clear existing dynamic controls
    $syncHash.ScubaRunParametersContainer.Children.Clear()

    $scubaConfig = $syncHash.UIConfigs.ScubaRunConfig
    $parameters = $scubaConfig.powershell.parameters

    Write-DebugOutput -Message "Creating dynamic ScubaRun parameter controls" -Source $MyInvocation.MyCommand -Level "Info"

    foreach ($parameterName in $parameters.PSObject.Properties.Name) {
        $paramConfig = $parameters.$parameterName

        # Skip hidden parameters (they won't show in UI but will be used in commands)
        if ($paramConfig.hidden -eq $true) {
            Write-DebugOutput -Message "Skipping hidden parameter: $parameterName" -Source $MyInvocation.MyCommand -Level "Verbose"
            continue
        }

        Write-DebugOutput -Message "Creating control for parameter: $parameterName" -Source $MyInvocation.MyCommand -Level "Info"

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

                Write-DebugOutput -Message "Created CheckBox: $controlName" -Source $MyInvocation.MyCommand -Level "Verbose"
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

                Write-DebugOutput -Message "Created TextBox: $controlName" -Source $MyInvocation.MyCommand -Level "Verbose"
            }
            "dropdown" {
                # Create label for the parameter
                $label = New-Object System.Windows.Controls.TextBlock
                $label.Text = $paramConfig.name
                $label.FontWeight = "SemiBold"
                $label.Margin = "0,0,0,4"
                [void]$paramContainer.Children.Add($label)

                #get length of items to determine width
                $maxItemWidth = ($paramConfig.items | ForEach-Object { $_.Length } | Sort-Object -Descending)[0]

                $control = New-Object System.Windows.Controls.ComboBox
                $control.ItemsSource = $paramConfig.items
                $control.SelectedItem = $paramConfig.defaultValue
                $control.IsEnabled = -not $paramConfig.readOnly
                $control.ToolTip = $paramConfig.description
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

                Write-DebugOutput -Message "Created ComboBox: $controlName" -Source $MyInvocation.MyCommand -Level "Verbose"
            }
            default {
                Write-DebugOutput -Message "Unknown parameter type: $($paramConfig.type) for $parameterName" -Source $MyInvocation.MyCommand -Level "Error"
                continue
            }
        }

        # Add control to container
        [void]$paramContainer.Children.Add($control)

        # Add the parameter container to the main container
        [void]$syncHash.ScubaRunParametersContainer.Children.Add($paramContainer)
    }

    Write-DebugOutput -Message "Dynamic ScubaRun parameter controls created successfully" -Source $MyInvocation.MyCommand -Level "Info"
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
            Update-ScubaRunStatus -Message "Output copied to clipboard" -Level "Info"
        } catch {
            Update-ScubaRunStatus -Message "Failed to copy output to clipboard" -Level "Error"
        }
    })

    $syncHash.ScubaRunViewConfig_Button.Add_Click({
        if ($syncHash.LastScubaRunResultsFolder) {
            $configFilePath = Join-Path $syncHash.LastScubaRunResultsFolder "ScubaGearConfiguration.yaml"
            if (Test-Path $configFilePath) {
                Show-ConfigurationViewer -ConfigFilePath $configFilePath
            } else {
                $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.ConfigurationFileNotFoundInResults -f $configFilePath, $syncHash.UIConfigs.localeTitles.ConfigurationViewer, "OK", "Warning")
            }
        } else {
            $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.NoConfigurationFileAvailable, $syncHash.UIConfigs.localeTitles.ConfigurationViewer, "OK", "Information")
        }
    })

    # Initialize button states and show initial status
    $syncHash.JustCompletedExecution = $false  # Ensure flag is clear on initialization
    $syncHash.ScubaRunViewConfig_Button.IsEnabled = $false  # Start with View Configuration button disabled
    Reset-ScubaRunUI

    Write-DebugOutput -Message "ScubaRun tab initialized with correct button event handlers" -Source $MyInvocation.MyCommand -Level "Info"
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

    # Map "Success" to "Info" for debug output since Write-DebugOutput doesn't accept "Success"
    $debugLevel = if ($Level -eq "Success") { "Info" } else { $Level }
    If($Message) {
        Write-DebugOutput -Message $Message -Source $MyInvocation.MyCommand -Level $debugLevel
    }
}

Function Test-ScubaRunReadiness {
    <#
    .SYNOPSIS
    Checks if ScubaGear can be run (valid YAML generated).
    #>

    # Check if we have valid configuration data
    $hasValidConfig = $false

    # Check if products are selected
    if ($syncHash.GeneralSettingsData.ProductNames.Count -gt 0) {
        $hasValidConfig = $true
    }else{
        Write-DebugOutput -Message "ScubaRun not allowed. No products are selected." -Source $MyInvocation.MyCommand -Level "Error"
    }

    # Check if Organization is set (required)
    if ([string]::IsNullOrWhiteSpace($syncHash.GeneralSettingsData.Organization)) {
        $hasValidConfig = $false
        Write-DebugOutput -Message "ScubaRun not allowed. Organization is not set." -Source $MyInvocation.MyCommand -Level "Error"
    }

    # Determine run mode based on AppId and CertificateThumbprint
    # If both AppId and CertificateThumbprint have values, it's non-interactive mode
    if (![string]::IsNullOrWhiteSpace($syncHash.AdvancedSettingsData.AppId) -and ![string]::IsNullOrWhiteSpace($syncHash.AdvancedSettingsData.CertificateThumbprint)) {
        $runMode = "[non-interactive mode]"
    }else{
        $runMode = "[interactive mode]"
    }

    # Enable/disable run button
    $syncHash.ScubaRunStart_Button.IsEnabled = $hasValidConfig

    # Only update status if we're not preserving a completion message
    if (-not $syncHash.JustCompletedExecution) {
        if ($hasValidConfig) {
            Update-ScubaRunStatus -Message ($syncHash.UIConfigs.localeInfoMessages.ScubaRunReady -f $runMode) -Level "Success"
        } else {
            Update-ScubaRunStatus -Message $syncHash.UIConfigs.localeErrorMessages.ScubaRunIncomplete -Level "Error"
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
            Update-ScubaRunStatus -Message $syncHash.UIConfigs.localeErrorMessages.ScubaRunIncomplete -Level "Error"
            return
        }

        # Generate temporary YAML file
        $tempConfigPath = Export-TempYamlConfiguration
        if (-not $tempConfigPath) {
            Update-ScubaRunStatus -Message $syncHash.UIConfigs.localeErrorMessages.ScubaRunConfigFailed -Level "Error"
            return
        }

        # Update UI state
        $syncHash.ScubaRunStart_Button.IsEnabled = $false
        $syncHash.ScubaRunStop_Button.IsEnabled = $true
        $syncHash.ScubaRunStart_Button.Visibility = "Collapsed"
        $syncHash.ScubaRunStop_Button.Visibility = "Visible"

        Update-ScubaRunStatus -Message "Starting ScubaGear execution..." -Level "Info"

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
        Update-ScubaRunStatus -Message "Error starting ScubaGear: $($_.Exception.Message)" -Level "Error"
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

        Update-ScubaRunStatus -Message "Configuration exported to: $tempFilePath" -Level "Info"
        return $tempFilePath
    }
    catch {
        Update-ScubaRunStatus -Message "Failed to export configuration: $($_.Exception.Message)" -Level "Error"
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
                        Write-DebugOutput -Message "Added optional string parameter: -$actualParamName '$($textBox.Text)'" -Source $MyInvocation.MyCommand -Level "Debug"
                    }
                }
                "boolean" {
                    $checkboxName = $paramName + "_CheckBox"
                    $checkbox = $syncHash.$checkboxName

                    if ($checkbox -and $checkbox.IsChecked) {
                        $parameters += "-$actualParamName"
                        Write-DebugOutput -Message "Added optional boolean parameter: -$actualParamName" -Source $MyInvocation.MyCommand -Level "Debug"
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
                        Write-DebugOutput -Message "Added optional dropdown parameter: -$actualParamName '$($comboBox.SelectedItem)'" -Source $MyInvocation.MyCommand -Level "Debug"
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
    Write-DebugOutput -Message "Built ScubaGear commands:" -Source $MyInvocation.MyCommand -Level "Info"
    foreach ($cmd in $cmdParts) {
        Write-DebugOutput -Message "  Command: $cmd" -Source $MyInvocation.MyCommand -Level "Info"
    }

    # Also update the UI to show what will be executed
    Update-ScubaRunStatus -Message "Prepared commands: $($cmdParts.Count) commands ready" -Level "Info"

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

Write-TimestampedOutput "Executing: $cmd" -Level "Info"
try {
# Execute the command directly, allowing variable expansion
$cmd
Write-TimestampedOutput "Command completed successfully" -Level "Info"
} catch {
Write-TimestampedOutput "ERROR executing command: `$(`$_.Exception.Message)" -Level "Error"
}

"@
}

    $scriptContent += @"

Write-TimestampedOutput "ScubaGear execution script completed." -Level "Info"
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
        $ReportPathValue = $syncHash.OutFolderName_TextBox.Text
        if (![string]::IsNullOrWhiteSpace($ReportPathValue)) {
            $baseName = $syncHash.UIConfigs.localePlaceholder.OutFolderName_TextBox
            Write-DebugOutput -Message "Folder placeholder value: '$baseName'" -Source $MyInvocation -Level "Debug"
        }

        $reportNameValue = $syncHash.OutReportName_TextBox.Text
        if (![string]::IsNullOrWhiteSpace($reportNameValue)) {
            if ($syncHash.UIConfigs.localePlaceholder.OutReportName_TextBox) {
                $reportName = $syncHash.UIConfigs.localePlaceholder.OutReportName_TextBox
                Write-DebugOutput -Message "Report placeholder value: '$reportName'" -Source $MyInvocation.MyCommand -Level "Debug"
            }
        }

        Write-DebugOutput -Message "Looking for folders with base name: '$baseName' and report name: '$reportName'" -Source $MyInvocation.MyCommand -Level "Info"

        $mostRecentFolder = $null
        $mostRecentTime = [datetime]::MinValue

        foreach ($searchPath in $searchPaths) {
            if (Test-Path $searchPath) {
                # Look for folders with the pattern: BaseName_YYYY_MM_DD_HH_MM_SS
                $searchPattern = "$baseName*"
                Write-DebugOutput -Message "Searching in '$searchPath' for pattern: '$searchPattern'" -Source $MyInvocation.MyCommand -Level "Debug"

                $scubaFolders = Get-ChildItem -Path $searchPath -Directory -Filter $searchPattern -ErrorAction SilentlyContinue |
                    Where-Object {
                        # Check if folder was created after start time (with 2 minute buffer)
                        $_.CreationTime -gt $StartTime.AddMinutes(-2) -and
                        # Additional check: folder name should match the expected pattern
                        $_.Name -like "$baseName*"
                    } |
                    Sort-Object CreationTime -Descending

                Write-DebugOutput -Message "Found $($scubaFolders.Count) matching folders in '$searchPath'" -Source $MyInvocation.MyCommand -Level "Debug"

                if ($scubaFolders -and $scubaFolders.Count -gt 0) {
                    $newestInThisPath = $scubaFolders[0]
                    Write-DebugOutput -Message "Newest folder in this path: '$($newestInThisPath.FullName)' (Created: $($newestInThisPath.CreationTime))" -Source $MyInvocation.MyCommand -Level "Debug"

                    if ($newestInThisPath.CreationTime -gt $mostRecentTime) {
                        $mostRecentFolder = $newestInThisPath
                        $mostRecentTime = $newestInThisPath.CreationTime
                    }
                }
            }
        }

        if ($mostRecentFolder) {
            Write-DebugOutput -Message "Most recent folder found: '$($mostRecentFolder.FullName)'" -Source $MyInvocation.MyCommand -Level "Info"

            # Check if the HTML report exists with the expected name
            $htmlFile = Join-Path $mostRecentFolder.FullName "$reportName.html"
            Write-DebugOutput -Message "Looking for HTML file: '$htmlFile'" -Source $MyInvocation.MyCommand -Level "Debug"

            if (Test-Path $htmlFile) {
                Write-DebugOutput -Message "HTML report found: '$htmlFile'" -Source $MyInvocation.MyCommand -Level "Info"
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
                    Write-DebugOutput -Message "Using fallback HTML file: '$fallbackHtml'" -Source $MyInvocation.MyCommand -Level "Info"
                    return @{
                        Type = "HTML"
                        Path = $fallbackHtml
                        Folder = $mostRecentFolder.FullName
                    }
                } else {
                    Write-DebugOutput -Message "No HTML files found in folder, returning folder path" -Source $MyInvocation.MyCommand -Level "Info"
                    return @{
                        Type = "Folder"
                        Path = $mostRecentFolder.FullName
                        Folder = $mostRecentFolder.FullName
                    }
                }
            }
        } else {
            Write-DebugOutput -Message "No matching ScubaGear folders found" -Source $MyInvocation.MyCommand -Level "Error"
        }
    }
    catch {
        Write-DebugOutput -Message "Error finding ScubaGear results: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
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
                Write-DebugOutput -Message "Error receiving job output: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }

            # Check job state
            switch ($job.State) {
                "Running" {
                    # Only update status message every few seconds with rotating messages
                    $script:statusUpdateCounter++
                    if ($script:statusUpdateCounter -ge $script:statusUpdateInterval) {
                        # Get next message in rotation
                        #$currentMessage = $script:scubaRunningMessages[$script:currentMessageIndex]
                        #Update-ScubaRunStatus -Message $currentMessage -Level "Info"

                        #get random message from list
                        $randomMessage = Get-Random -InputObject $script:scubaRunningMessages
                        Update-ScubaRunStatus -Message $randomMessage -Level "Info"

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
                        # Export configuration YAML to the results folder
                        Export-ConfigurationToResultsFolder -ResultsFolder $resultsInfo.Folder

                        $syncHash.ScubaRunOutput_TextBox.AppendText("`r`n*** EXECUTION COMPLETE! ***`r`n")

                        if ($resultsInfo.Type -eq "HTML") {
                            $syncHash.ScubaRunOutput_TextBox.AppendText("Results available at: $($resultsInfo.Path)`r`n")
                            $syncHash.ScubaRunOutput_TextBox.AppendText("Tip: Copy this path and paste it into your browser to view the report`r`n")
                            # Update status with the baseline conformance report path
                            Update-ScubaRunStatus -Message "ScubaGear Complete |Report: $($resultsInfo.Path)" -Level "Success"
                        } else {
                            $syncHash.ScubaRunOutput_TextBox.AppendText("Results folder: $($resultsInfo.Path)`r`n")
                            # Update status with folder path
                            Update-ScubaRunStatus -Message "ScubaGear Complete | Folder: $($resultsInfo.Path)" -Level "Success"
                        }

                        $syncHash.ScubaRunOutput_TextBox.AppendText("Full results folder: $($resultsInfo.Folder)`r`n")

                        # Store the results folder path for the View Configuration button
                        $syncHash.LastScubaRunResultsFolder = $resultsInfo.Folder
                    } else {
                        # Enhanced fallback message with more specific guidance
                        Update-ScubaRunStatus -Message "ScubaGear Complete | Check Documents folder for results" -Level "Success"

                        $syncHash.ScubaRunOutput_TextBox.AppendText("`r`n*** EXECUTION COMPLETE! ***`r`n")
                        $syncHash.ScubaRunOutput_TextBox.AppendText("Check your Documents folder for M365BaselineConformance_* folders`r`n")
                    }

                    Complete-ScubaGearExecution
                    $this.Stop()

                    # Cleanup temp script
                    if ($syncHash.TempScriptPath -and (Test-Path $syncHash.TempScriptPath)) {
                        try {
                            Remove-Item -Path $syncHash.TempScriptPath -Force -ErrorAction SilentlyContinue
                            $syncHash.TempScriptPath = $null
                        } catch {
                            Write-DebugOutput -Message "Error cleaning up temp script file: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
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
                        Write-DebugOutput -Message "Error extracting job error message: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                    }

                    Update-ScubaRunStatus -Message "ScubaGear execution failed: $failureReason" -Level "Error"
                    Complete-ScubaGearExecution
                    $this.Stop()
                }
                "Stopped" {
                    Update-ScubaRunStatus -Message "ScubaGear execution was stopped" -Level "Error"
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
            Write-DebugOutput -Message "Error cleaning up temp script file: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        }
    }

    Update-ScubaRunStatus -Message "Execution stopped by user" -Level "Error"
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
            Write-DebugOutput -Message "Error cleaning up temp script file: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        }
    }

    # Set flag to indicate we just completed execution (preserve status message)
    $syncHash.JustCompletedExecution = $true

    # Enable View Configuration button if we have a results folder
    if ($syncHash.LastScubaRunResultsFolder) {
        $configFilePath = Join-Path $syncHash.LastScubaRunResultsFolder "ScubaGearConfiguration.yaml"
        if (Test-Path $configFilePath) {
            $syncHash.ScubaRunViewConfig_Button.IsEnabled = $true
            Write-DebugOutput -Message "Enabled View Configuration button for: $configFilePath" -Source $MyInvocation.MyCommand -Level "Info"
        }
    }

    # Ensure Results tab is enabled and refresh it
    If($syncHash.UIConfigs.EnableResultReader) {
        $syncHash.ResultsTab.IsEnabled = $true
        Update-ResultsTab
    }

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
                    Update-ScubaRunStatus -Message "ScubaGear is running..." -Level "Info"
                    # You could parse output here if available
                }
                "Completed" {
                    $results = Receive-Job -Job $job
                    Update-ScubaRunStatus -Message "ScubaGear completed successfully" -Level "Success"
                    $syncHash.ScubaRunOutput_TextBox.AppendText("$results`r`n")
                    Complete-ScubaGearExecution
                    $this.Stop()
                }
                "Failed" {
                    $null = Receive-Job -Job $job -ErrorAction SilentlyContinue
                    Update-ScubaRunStatus -Message "ScubaGear failed: $error" -Level "Error"
                    Complete-ScubaGearExecution
                    $this.Stop()
                }
                "Stopped" {
                    Update-ScubaRunStatus -Message "ScubaGear execution was stopped" -Level "Error"
                    Complete-ScubaGearExecution
                    $this.Stop()
                }
            }
        }
    })

    $syncHash.ScubaRunExecutionTimer = $timer
    $timer.Start()
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