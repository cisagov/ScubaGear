<#
.SYNOPSIS
AutoSave helper functions for ScubaGear Configuration Editor.

.DESCRIPTION
This module provides functionality to automatically save and restore user progress
in policy configurations. It saves individual policy data to JSON files and can
restore them when the UI is relaunched.

.NOTES
SAVE FLOW:
    User clicks "Save Exclusions" on MS.AAD.1.1v1
    ↓
    Data saved to ExclusionData hashtable (existing functionality)
    ↓
    Save-AutoSavePolicy called with:
    - CardName: "Exclusions"
    - PolicyId: "MS.AAD.1.1v1"
    - ProductName: "AAD"
    - FlipFieldValueAndPolicyId: $true
    ↓
    File saved to: LOCALAPPDATA\ScubaConfig\AutoSave\Exclusions_MS.AAD.1.1v1.json

RESTORE FLOW:
    UI launches
    ↓
    Check if AutoSaveProgress enabled in JSON config
    ↓
    Scan LOCALAPPDATA\ScubaConfig\AutoSave\ for *.json files
    ↓
    For each file:
    - Parse filename to get CardName and PolicyId
    - Find baselineControl by CardName
    - Get target hashtable from dataControlOutput
    - Restore data to correct hashtable (e.g., ExclusionData)

#policy files
LOCALAPPDATA\ScubaConfig\AutoSave\
├── Exclusions_MS.AAD.1.1v1.json
├── Exclusions_MS.EXO.2.1v1.json
├── Annotate_MS.AAD.3.1v1.json
└── Omit_MS.TEAMS.1.1v1.json

#settings files
LOCALAPPDATA\ScubaConfig\AutoSave\
├── GeneralSettingsData.json
├── AdvancedSettingsData.json
└── GlobalSettingsData.json
#>

Function Get-AutoSaveDirectory {
    <#
    .SYNOPSIS
    Gets the AutoSave directory path, creating it if it doesn't exist.
    .DESCRIPTION
    Returns the standardized AutoSave directory path and ensures the directory exists.
    Uses LOCALAPPDATA for consistent cross-user behavior.
    #>
    [CmdletBinding()]
    param()

    try {
        $autoSaveDir = Join-Path $env:LOCALAPPDATA "ScubaConfig\AutoSave"

        if (-not (Test-Path $autoSaveDir)) {
            New-Item -Path $autoSaveDir -ItemType Directory -Force | Out-Null
            Write-DebugOutput -Message "Created AutoSave directory: $autoSaveDir" -Source $MyInvocation.MyCommand -Level "Info"
        }

        return $autoSaveDir
    }
    catch {
        Write-DebugOutput -Message "Error creating AutoSave directory: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        throw
    }
}

Function Test-AutoSaveEnabled {
    <#
    .SYNOPSIS
    Tests if AutoSave functionality is enabled in the configuration.
    .DESCRIPTION
    Checks the UIConfigs JSON configuration to determine if AutoSaveProgress is enabled.
    #>
    [CmdletBinding()]
    param()

    try {
        $autoSaveConfig = $syncHash.UIConfigs.AutoSaveProgress
        $isEnabled = $autoSaveConfig -eq $true

        Write-DebugOutput -Message "AutoSave enabled: $isEnabled" -Source $MyInvocation.MyCommand -Level "Verbose"
        return $isEnabled
    }
    catch {
        Write-DebugOutput -Message "Error checking AutoSave configuration: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Warning"
        return $false
    }
}

Function Save-AutoSavePolicy {
    <#
    .SYNOPSIS
    Saves policy configuration data to an AutoSave file.
    .DESCRIPTION
    Saves the current policy configuration data to a JSON file in the AutoSave directory.
    Uses configuration-driven approach to determine source data structure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CardName,

        [Parameter(Mandatory = $true)]
        [string]$PolicyId,

        [Parameter(Mandatory = $true)]
        [string]$ProductName,

        [Parameter(Mandatory = $false)]
        [bool]$FlipFieldValueAndPolicyId = $false
    )

    try {
        # Check if AutoSave is enabled
        if (-not (Test-AutoSaveEnabled)) {
            Write-DebugOutput -Message "AutoSave is disabled, skipping save for $CardName/$PolicyId" -Source $MyInvocation.MyCommand -Level "Verbose"
            return
        }

        # Find the baseline control configuration for this card
        $baselineControl = $syncHash.UIConfigs.baselineControls | Where-Object { $_.cardName -eq $CardName }
        if (-not $baselineControl) {
            Write-DebugOutput -Message "No baseline control found for CardName: $CardName" -Source $MyInvocation.MyCommand -Level "Warning"
            return
        }

        # Get the source data hashtable name
        $sourceDataName = $baselineControl.dataControlOutput
        if (-not $sourceDataName) {
            Write-DebugOutput -Message "No dataControlOutput configured for CardName: $CardName" -Source $MyInvocation.MyCommand -Level "Warning"
            return
        }

        # Get the source data hashtable
        $sourceData = $syncHash.$sourceDataName
        if (-not $sourceData) {
            Write-DebugOutput -Message "Source data hashtable '$sourceDataName' not found or empty" -Source $MyInvocation.MyCommand -Level "Warning"
            return
        }

        # Extract the relevant data based on data structure type
        $policyData = $null

        if ($FlipFieldValueAndPolicyId) {
            # Flipped structure: Product -> FieldType -> PolicyId -> FieldData (Annotations/Omissions)
            if ($sourceData[$ProductName] -and $sourceData[$ProductName][$baselineControl.yamlValue] -and $sourceData[$ProductName][$baselineControl.yamlValue][$PolicyId]) {
                $policyData = @{
                    $ProductName = @{
                        $baselineControl.yamlValue = @{
                            $PolicyId = $sourceData[$ProductName][$baselineControl.yamlValue][$PolicyId]
                        }
                    }
                }
            }
        } else {
            # Normal structure: Product -> PolicyId -> ExclusionType -> FieldData (Exclusions)
            if ($sourceData[$ProductName] -and $sourceData[$ProductName][$PolicyId]) {
                $policyData = @{
                    $ProductName = @{
                        $PolicyId = $sourceData[$ProductName][$PolicyId]
                    }
                }
            }
        }

        if (-not $policyData) {
            Write-DebugOutput -Message "No data found to save for $CardName/$ProductName/$PolicyId" -Source $MyInvocation.MyCommand -Level "Verbose"
            return
        }

        # Create filename and save
        $autoSaveDir = Get-AutoSaveDirectory
        $fileName = "${CardName}_${PolicyId}.json"
        $filePath = Join-Path $autoSaveDir $fileName

        $policyData | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8 -Force

        Write-DebugOutput -Message "Saved AutoSave policy data: $filePath" -Source $MyInvocation.MyCommand -Level "Info"
    }
    catch {
        Write-DebugOutput -Message "Error saving AutoSave policy data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

Function Remove-AutoSavePolicy {
    <#
    .SYNOPSIS
    Removes an AutoSave policy file when a policy is deleted.
    .DESCRIPTION
    Deletes the corresponding AutoSave JSON file when a policy configuration is removed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CardName,

        [Parameter(Mandatory = $true)]
        [string]$PolicyId
    )

    try {
        # Check if AutoSave is enabled
        if (-not (Test-AutoSaveEnabled)) {
            Write-DebugOutput -Message "AutoSave is disabled, skipping remove for $CardName/$PolicyId" -Source $MyInvocation.MyCommand -Level "Verbose"
            return
        }

        $autoSaveDir = Get-AutoSaveDirectory
        $fileName = "${CardName}_${PolicyId}.json"
        $filePath = Join-Path $autoSaveDir $fileName

        if (Test-Path $filePath) {
            Remove-Item -Path $filePath -Force
            Write-DebugOutput -Message "Removed AutoSave policy file: $filePath" -Source $MyInvocation.MyCommand -Level "Info"
        } else {
            Write-DebugOutput -Message "AutoSave policy file not found (already removed): $filePath" -Source $MyInvocation.MyCommand -Level "Verbose"
        }
    }
    catch {
        Write-DebugOutput -Message "Error removing AutoSave policy file: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

Function Get-AutoSavePolicies {
    <#
    .SYNOPSIS
    Gets all available AutoSave policy files.
    .DESCRIPTION
    Scans the AutoSave directory and returns information about all saved policy files.
    Returns objects with CardName, PolicyId, and FilePath properties.
    #>
    [CmdletBinding()]
    param()

    try {
        $autoSaveDir = Get-AutoSaveDirectory
        $autoSavePolicies = @()

        if (Test-Path $autoSaveDir) {
            $jsonFiles = Get-ChildItem -Path $autoSaveDir -Filter "*.json" -File

            foreach ($file in $jsonFiles) {
                # Parse filename: CardName_PolicyId.json
                if ($file.BaseName -match '^(.+)_(.+)$') {
                    $cardName = $matches[1]
                    $policyId = $matches[2]

                    $autoSavePolicies += [PSCustomObject]@{
                        CardName = $cardName
                        PolicyId = $policyId
                        FilePath = $file.FullName
                        LastModified = $file.LastWriteTime
                    }
                } else {
                    Write-DebugOutput -Message "Skipping AutoSave file with invalid naming pattern: $($file.Name)" -Source $MyInvocation.MyCommand -Level "Warning"
                }
            }
        }

        Write-DebugOutput -Message "Found $($autoSavePolicies.Count) AutoSave policy files" -Source $MyInvocation.MyCommand -Level "Info"
        return $autoSavePolicies
    }
    catch {
        Write-DebugOutput -Message "Error getting AutoSave policies: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        return @()
    }
}

Function Restore-AutoSavePolicies {
    <#
    .SYNOPSIS
    Restores all AutoSave policy data when the UI launches.
    .DESCRIPTION
    Scans the AutoSave directory and restores all saved policy configurations
    to their appropriate data hashtables. Uses configuration-driven approach.
    #>
    [CmdletBinding()]
    param()

    try {
        # Check if AutoSave is enabled
        if (-not (Test-AutoSaveEnabled)) {
            Write-DebugOutput -Message "AutoSave is disabled, skipping restore" -Source $MyInvocation.MyCommand -Level "Info"
            return
        }

        $autoSavePolicies = Get-AutoSavePolicies

        if ($autoSavePolicies.Count -eq 0) {
            Write-DebugOutput -Message "No AutoSave policy files to restore" -Source $MyInvocation.MyCommand -Level "Info"
            return
        }

        $restoredCount = 0

        foreach ($policy in $autoSavePolicies) {
            try {
                # Find the baseline control configuration for this card
                $baselineControl = $syncHash.UIConfigs.baselineControls | Where-Object { $_.controlType -eq $policy.CardName }
                if (-not $baselineControl) {
                    Write-DebugOutput -Message "No baseline control found for CardName: $($policy.CardName), skipping restore of $($policy.PolicyId)" -Source $MyInvocation.MyCommand -Level "Warning"
                    continue
                }

                # Get the target data hashtable name
                $targetDataName = $baselineControl.dataControlOutput
                if (-not $targetDataName) {
                    Write-DebugOutput -Message "No dataControlOutput configured for CardName: $($policy.CardName), skipping restore of $($policy.PolicyId)" -Source $MyInvocation.MyCommand -Level "Warning"
                    continue
                }

                # Ensure the target hashtable exists
                if (-not $syncHash.$targetDataName) {
                    $syncHash.$targetDataName = [ordered]@{}
                }

                # Load and parse the JSON data
                $jsonContent = Get-Content -Path $policy.FilePath -Raw | ConvertFrom-Json

                # Merge the data into the target hashtable
                foreach ($productName in $jsonContent.PSObject.Properties.Name) {
                    $productData = $jsonContent.$productName

                    # Initialize product level if needed
                    if (-not $syncHash.$targetDataName[$productName]) {
                        $syncHash.$targetDataName[$productName] = [ordered]@{}
                    }

                    # Merge the product data
                    foreach ($key in $productData.PSObject.Properties.Name) {
                        $keyData = $productData.$key

                        # Handle both flipped and normal data structures
                        if ($baselineControl.supportsAllProducts) {
                            # Flipped structure: merge at yamlValue level
                            if (-not $syncHash.$targetDataName[$productName][$key]) {
                                $syncHash.$targetDataName[$productName][$key] = [ordered]@{}
                            }

                            foreach ($policyIdKey in $keyData.PSObject.Properties.Name) {
                                $syncHash.$targetDataName[$productName][$key][$policyIdKey] = $keyData.$policyIdKey
                            }
                        } else {
                            # Normal structure: merge at policy level
                            $syncHash.$targetDataName[$productName][$key] = $keyData
                        }
                    }
                }

                $restoredCount++
                Write-DebugOutput -Message "Restored AutoSave policy: $($policy.CardName)/$($policy.PolicyId) to $targetDataName" -Source $MyInvocation.MyCommand -Level "Info"
            }
            catch {
                Write-DebugOutput -Message "Error restoring AutoSave policy $($policy.CardName)/$($policy.PolicyId): $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }
        }

        Write-DebugOutput -Message "AutoSave restore completed: $restoredCount of $($autoSavePolicies.Count) policies restored" -Source $MyInvocation.MyCommand -Level "Info"
    }
    catch {
        Write-DebugOutput -Message "Error during AutoSave restore: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

Function Save-AutoSaveSettings {
    <#
    .SYNOPSIS
    Saves settings data (General, Advanced, Global) to AutoSave files.
    .DESCRIPTION
    Saves the current settings data to JSON files for the specified settings type.
    Uses configuration-driven approach based on dataValidationKeys.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SettingsType
    )

    try {
        # Check if AutoSave is enabled
        if (-not (Test-AutoSaveEnabled)) {
            Write-DebugOutput -Message "AutoSave is disabled, skipping save for $SettingsType" -Source $MyInvocation.MyCommand -Level "Verbose"
            return
        }

        # Validate settings type exists in configuration using new settingsControl structure
        $settingsControl = $syncHash.UIConfigs.settingsControl
        $matchingTabConfig = $null

        # Find the tab configuration that has this settings type as its dataControlOutput
        foreach ($tabName in $settingsControl.PSObject.Properties.Name) {
            $tabConfig = $settingsControl.$tabName
            if ($tabConfig.dataControlOutput -eq $SettingsType) {
                $matchingTabConfig = $tabConfig
                break
            }
        }

        if (-not $matchingTabConfig) {
            Write-DebugOutput -Message "Settings type '$SettingsType' not found in settingsControl configuration" -Source $MyInvocation.MyCommand -Level "Warning"
            return
        }

        # Before saving, collect current settings data from UI into the data structure
        switch ($SettingsType) {
            "AdvancedSettingsData" {
                if (Get-Command "Set-SettingsDataForAdvancedSection" -ErrorAction SilentlyContinue) {
                    Set-SettingsDataForAdvancedSection
                    Write-DebugOutput -Message "Collected advanced settings data before AutoSave" -Source $MyInvocation.MyCommand -Level "Verbose"
                }
            }
            "GlobalSettingsData" {
                if (Get-Command "Set-SettingsDataForGlobalSection" -ErrorAction SilentlyContinue) {
                    Set-SettingsDataForGlobalSection
                    Write-DebugOutput -Message "Collected global settings data before AutoSave" -Source $MyInvocation.MyCommand -Level "Verbose"
                }
            }
            "GeneralSettingsData" {
                if (Get-Command "Set-SettingsDataForGeneralSection" -ErrorAction SilentlyContinue) {
                    Set-SettingsDataForGeneralSection
                    Write-DebugOutput -Message "Collected general settings data before AutoSave" -Source $MyInvocation.MyCommand -Level "Verbose"
                }
            }
        }

        # Get the source data hashtable (after collection)
        $sourceData = $syncHash.$SettingsType
        if (-not $sourceData -or $sourceData.Count -eq 0) {
            Write-DebugOutput -Message "No data found in $SettingsType to save" -Source $MyInvocation.MyCommand -Level "Verbose"
            return
        }

        # Create filename and save
        $autoSaveDir = Get-AutoSaveDirectory
        $fileName = "${SettingsType}.json"
        $filePath = Join-Path $autoSaveDir $fileName

        $sourceData | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8 -Force

        Write-DebugOutput -Message "Saved AutoSave settings data: $filePath" -Source $MyInvocation.MyCommand -Level "Info"
    }
    catch {
        Write-DebugOutput -Message "Error saving AutoSave settings data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

Function Show-AutoSaveRestorePrompt {
    <#
    .SYNOPSIS
    Shows a dialog asking the user what to do with their previous session.
    .DESCRIPTION
    Prompts the user to choose between restoring last session, removing last session, or restoring later.
    Returns the user's choice.
    #>
    [CmdletBinding()]
    param()

    try {
        # Check if there are any AutoSave files to restore
        $autoSaveDir = Get-AutoSaveDirectory
        if (-not (Test-Path $autoSaveDir)) {
            Write-DebugOutput -Message "No AutoSave directory found, skipping restore prompt" -Source $MyInvocation.MyCommand -Level "Verbose"
            return "none"
        }

        $autoSaveFiles = Get-ChildItem -Path $autoSaveDir -Filter "*.json" -ErrorAction SilentlyContinue
        if (-not $autoSaveFiles -or $autoSaveFiles.Count -eq 0) {
            Write-DebugOutput -Message "No AutoSave files found, skipping restore prompt" -Source $MyInvocation.MyCommand -Level "Verbose"
            return "none"
        }

        # Count how many policies and settings we would restore
        $policyCount = ($autoSaveFiles | Where-Object { $_.Name -like "*_*.json" }).Count
        $settingsCount = ($autoSaveFiles | Where-Object { $_.Name -like "*SettingsData.json" }).Count
        $totalItems = $policyCount + $settingsCount

        if ($totalItems -eq 0) {
            Write-DebugOutput -Message "No valid AutoSave data found, skipping restore prompt" -Source $MyInvocation.MyCommand -Level "Verbose"
            return "none"
        }

        # Get the newest file timestamp for display
        $newestFile = $autoSaveFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $lastSavedTime = $newestFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")

        # Create the prompt message
        $message = @"
A previous session was detected with $totalItems saved items ($policyCount policies, $settingsCount settings configurations).

Last saved: $lastSavedTime

What would you like to do?

- Yes = Restore previous session now
- No = Delete previous session data
- Cancel = Keep data, restore later (show Restore button)
"@

        # Show the dialog with three options
        $result = [System.Windows.MessageBox]::Show(
            $message,
            "Restore Previous Session?",
            [System.Windows.MessageBoxButton]::YesNoCancel,
            [System.Windows.MessageBoxImage]::Question,
            [System.Windows.MessageBoxResult]::Yes
        )

        switch ($result) {
            "Yes" {
                Write-DebugOutput -Message "User chose to restore previous session" -Source $MyInvocation.MyCommand -Level "Info"
                return "restore"
            }
            "No" {
                Write-DebugOutput -Message "User chose to remove previous session" -Source $MyInvocation.MyCommand -Level "Info"
                return "remove"
            }
            "Cancel" {
                Write-DebugOutput -Message "User chose to restore later" -Source $MyInvocation.MyCommand -Level "Info"
                return "later"
            }
            default {
                Write-DebugOutput -Message "Unknown dialog result: $result, defaulting to later" -Source $MyInvocation.MyCommand -Level "Warning"
                return "later"
            }
        }
    }
    catch {
        Write-DebugOutput -Message "Error showing AutoSave restore prompt: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        return "none"
    }
}

Function Restore-AutoSaveWithProgress {
    <#
    .SYNOPSIS
    Restores AutoSave data with a progress dialog.
    .DESCRIPTION
    Restores both policies and settings from AutoSave files while showing progress to the user.
    Uses a runspace-based progress window similar to the YAML import functionality.
    #>
    [CmdletBinding()]
    param()

    $progress = $null
    try {
        Write-DebugOutput -Message "Starting AutoSave restoration with progress" -Source $MyInvocation.MyCommand -Level "Info"

        # Get count of items to restore for progress calculation
        $autoSaveDir = Get-AutoSaveDirectory
        $autoSaveFiles = Get-ChildItem -Path $autoSaveDir -Filter "*.json" -ErrorAction SilentlyContinue
        $policyFiles = $autoSaveFiles | Where-Object { $_.Name -like "*_*.json" }
        $settingsFiles = $autoSaveFiles | Where-Object { $_.Name -like "*SettingsData.json" }
        $totalItems = $policyFiles.Count + $settingsFiles.Count

        if ($totalItems -eq 0) {
            Write-DebugOutput -Message "No AutoSave data to restore" -Source $MyInvocation.MyCommand -Level "Info"
            return
        }

        # Show progress window
        $progress = Show-AutoSaveRestoreProgress -Title "Restoring Previous Session"

        if (-not $progress) {
            throw "Failed to create progress window"
        }

        # Small delay to ensure window is visible
        Start-Sleep -Milliseconds 300

        # Step 1: Restore policies
        $progress.UpdateMessage.Invoke("Restoring policies...", "Processing $($policyFiles.Count) policy configurations")
        Start-Sleep -Milliseconds 200
        Restore-AutoSavePolicies

        # Step 2: Restore settings
        $progress.UpdateMessage.Invoke("Restoring settings...", "Processing $($settingsFiles.Count) settings configurations")
        Start-Sleep -Milliseconds 200
        Restore-AutoSaveSettings

        # Step 3: Update UI
        $progress.UpdateMessage.Invoke("Updating user interface...", "Refreshing UI controls")
        Start-Sleep -Milliseconds 300
        if (Test-AutoSaveEnabled) {
            Update-UIFromSettingsData
        }

        # Step 4: Final processing
        $progress.UpdateMessage.Invoke($syncHash.UIConfigs.localeProgressMessages.SessionRestoreFinalize, $syncHash.UIConfigs.localeProgressMessages.SessionRestoreStatus)
        Start-Sleep -Milliseconds 300

        Write-DebugOutput -Message "AutoSave restoration with progress completed successfully" -Source $MyInvocation.MyCommand -Level "Info"

        # Show completion message
        $syncHash.ShowMessageBox.Invoke(
            $syncHash.UIConfigs.localeProgressMessages.SessionRestoreSuccess -f $policyFiles.Count, $settingsFiles.Count,
            $syncHash.UIConfigs.localeTitles.SessionRestored,
            "OK",
            "Information"
        )

    } catch {
        Write-DebugOutput -Message "Error during AutoSave restoration with progress: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        if ($progress -and $progress.UpdateMessage) {
            $progress.UpdateMessage.Invoke("Restore failed!", "Error: $($_.Exception.Message)")
            Start-Sleep -Milliseconds 1500
        }

        $syncHash.ShowMessageBox.Invoke(
            "An error occurred while restoring the previous session: $($_.Exception.Message)",
            "Restore Error",
            "OK",
            "Error"
        )
    } finally {
        # Always close progress window
        if ($progress -and $progress.Close) {
            $progress.Close.Invoke()
        }
    }
}

Function Show-AutoSaveRestoreProgress {
    <#
    .SYNOPSIS
    Shows a progress window for AutoSave restoration.
    .DESCRIPTION
    Creates a runspace-based progress window similar to the YAML import progress.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    # Create runspace for progress window
    $progressRunspace = [runspacefactory]::CreateRunspace()
    $progressRunspace.ApartmentState = "STA"
    $progressRunspace.ThreadOptions = "ReuseThread"
    $progressRunspace.Open()

    # Define XAML for progress window
    $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Restoring Previous Session"
        Width="400" Height="200"
        WindowStartupLocation="CenterScreen"
        WindowStyle="ToolWindow"
        ResizeMode="NoResize"
        Topmost="True">
    <Window.Resources>
        <Style TargetType="Label">
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="20"/>
            <Setter Property="Margin" Value="0,5"/>
        </Style>
    </Window.Resources>
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Label x:Name="lblMessage" Grid.Row="0" Content="Preparing to restore session..." FontWeight="Bold"/>
        <Label x:Name="lblStatus" Grid.Row="1" Content="Initializing..." Foreground="Gray" FontSize="10"/>
        <ProgressBar x:Name="RestoreProgressBar" Grid.Row="2" IsIndeterminate="True"/>
        <Label Grid.Row="3" Content="Please wait while your previous session is restored..."
               FontStyle="Italic" FontSize="10" HorizontalAlignment="Center" Margin="0,10,0,0"/>
    </Grid>
</Window>
'@

    # Share variables with runspace
    $progressRunspace.SessionStateProxy.SetVariable("xaml", $xaml)
    $progressRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
    $progressRunspace.SessionStateProxy.SetVariable("Title", $Title)

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

            # Set title
            $progressWindow.Title = $Title

            # Get controls
            $lblMessage = $progressWindow.FindName("lblMessage")
            $lblStatus = $progressWindow.FindName("lblStatus")
            $progressBar = $progressWindow.FindName("RestoreProgressBar")

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

            # Update message function
            $updateMessage = {
                param($message, $status)
                $msg = $message
                $stat = $status
                $progressSync.Window.Dispatcher.Invoke([Action]{
                    if ($msg) { $progressSync.Message.Content = $msg }
                    if ($stat) { $progressSync.Status.Content = $stat }
                })
            }

            # Store update function
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
                Write-DebugOutput -Message "Error closing progress window: $($_.Exception.Message)" -Source "Show-AutoSaveRestoreProgress" -Level "Warning"
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
                Write-DebugOutput -Message "Error during cleanup: $($_.Exception.Message)" -Source "Show-AutoSaveRestoreProgress" -Level "Error"
            }

            # Remove from syncHash
            if ($syncHash.ProgressSync) {
                $syncHash.Remove("ProgressSync")
            }
            if ($syncHash.UpdateProgressMessage) {
                $syncHash.Remove("UpdateProgressMessage")
            }
        }
    }
}

Function Remove-AutoSaveData {
    <#
    .SYNOPSIS
    Removes all AutoSave data files.
    .DESCRIPTION
    Deletes all AutoSave files and shows confirmation to the user.
    #>
    [CmdletBinding()]
    param()

    try {
        $autoSaveDir = Get-AutoSaveDirectory
        if (Test-Path $autoSaveDir) {
            $autoSaveFiles = Get-ChildItem -Path $autoSaveDir -Filter "*.json" -ErrorAction SilentlyContinue
            $fileCount = $autoSaveFiles.Count

            if ($fileCount -gt 0) {
                Remove-Item -Path "$autoSaveDir\*.json" -Force -ErrorAction SilentlyContinue
                Write-DebugOutput -Message "Removed $fileCount AutoSave files" -Source $MyInvocation.MyCommand -Level "Info"

                $syncHash.ShowMessageBox.Invoke(
                    "Previous session data has been removed ($fileCount files deleted).",
                    "Session Data Removed",
                    "OK",
                    "Information"
                )
            } else {
                Write-DebugOutput -Message "No AutoSave files found to remove" -Source $MyInvocation.MyCommand -Level "Info"
            }
        }
    }
    catch {
        Write-DebugOutput -Message "Error removing AutoSave data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"

        $syncHash.ShowMessageBox.Invoke(
            "An error occurred while removing session data: $($_.Exception.Message)",
            "Remove Error",
            "OK",
            "Error"
        )
    }
}

Function Restore-AutoSaveSettings {
    <#
    .SYNOPSIS
    Restores all settings data from AutoSave files.
    .DESCRIPTION
    Restores GeneralSettings, AdvancedSettings, and GlobalSettings from AutoSave files.
    Uses configuration-driven approach based on dataValidationKeys.
    #>
    [CmdletBinding()]
    param()

    try {
        # Check if AutoSave is enabled
        if (-not (Test-AutoSaveEnabled)) {
            Write-DebugOutput -Message "AutoSave is disabled, skipping settings restore" -Source $MyInvocation.MyCommand -Level "Info"
            return
        }

        $autoSaveDir = Get-AutoSaveDirectory
        $settingsControl = $syncHash.UIConfigs.settingsControl
        $restoredCount = 0

        # Dynamically restore all settings types from configuration using new settingsControl structure
        foreach ($tabName in $settingsControl.PSObject.Properties.Name) {
            $tabConfig = $settingsControl.$tabName
            $settingsType = $tabConfig.dataControlOutput

            if (-not $settingsType) {
                Write-DebugOutput -Message "No dataControlOutput found for tab: $tabName" -Source $MyInvocation.MyCommand -Level "Verbose"
                continue
            }

            $fileName = "${settingsType}.json"
            $filePath = Join-Path $autoSaveDir $fileName

            if (Test-Path $filePath) {
                try {
                    # Load and parse the JSON data
                    $settingsData = Get-Content -Path $filePath -Raw | ConvertFrom-Json

                    # Ensure the target hashtable exists
                    if (-not $syncHash.$settingsType) {
                        $syncHash.$settingsType = [ordered]@{}
                    }

                    # Restore the settings data
                    foreach ($key in $settingsData.PSObject.Properties.Name) {
                        $syncHash.$settingsType[$key] = $settingsData.$key
                    }

                    $restoredCount++
                    Write-DebugOutput -Message "Restored AutoSave settings: $settingsType from $fileName" -Source $MyInvocation.MyCommand -Level "Info"
                }
                catch {
                    Write-DebugOutput -Message "Error restoring AutoSave settings ${settingsType}: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                }
            } else {
                Write-DebugOutput -Message "No AutoSave file found for ${settingsType}: $fileName" -Source $MyInvocation.MyCommand -Level "Verbose"
            }
        }

        Write-DebugOutput -Message "AutoSave settings restore completed: $restoredCount settings files restored" -Source $MyInvocation.MyCommand -Level "Info"
    }
    catch {
        Write-DebugOutput -Message "Error during AutoSave settings restore: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}

Function Clear-AutoSaveData {
    <#
    .SYNOPSIS
    Clears all AutoSave data files.
    .DESCRIPTION
    Removes all AutoSave files from the AutoSave directory. Useful for cleanup or reset operations.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$PolicyOnly,

        [Parameter(Mandatory = $false)]
        [switch]$SettingsOnly
    )

    try {
        $autoSaveDir = Get-AutoSaveDirectory

        if (-not (Test-Path $autoSaveDir)) {
            Write-DebugOutput -Message "AutoSave directory does not exist, nothing to clear" -Source $MyInvocation.MyCommand -Level "Info"
            return
        }

        $filesToRemove = @()

        if ($PolicyOnly) {
            # Remove only policy files (CardName_PolicyId.json pattern)
            $filesToRemove = Get-ChildItem -Path $autoSaveDir -Filter "*.json" | Where-Object { $_.BaseName -match '^.+_.+$' }
        }
        elseif ($SettingsOnly) {
            # Remove only settings files (SettingsType.json pattern, no underscore)
            $filesToRemove = Get-ChildItem -Path $autoSaveDir -Filter "*.json" | Where-Object { $_.BaseName -notmatch '_' }
        }
        else {
            # Remove all JSON files
            $filesToRemove = Get-ChildItem -Path $autoSaveDir -Filter "*.json"
        }

        $removedCount = 0
        foreach ($file in $filesToRemove) {
            Remove-Item -Path $file.FullName -Force
            $removedCount++
        }

        $typeDescription = if ($PolicyOnly) { "policy" } elseif ($SettingsOnly) { "settings" } else { "all" }
        Write-DebugOutput -Message "Cleared $removedCount $typeDescription AutoSave files" -Source $MyInvocation.MyCommand -Level "Info"
    }
    catch {
        Write-DebugOutput -Message "Error clearing AutoSave data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
    }
}