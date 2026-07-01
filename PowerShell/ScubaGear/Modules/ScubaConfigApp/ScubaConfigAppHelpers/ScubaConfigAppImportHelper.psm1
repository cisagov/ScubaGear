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
            <TextBlock Text="&#x1F4E5;" FontSize="24" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="White"/>
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
                Write-DebugOutput -Message "Error during cleanup: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
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
        Write-DebugOutput -Message "Starting YAML import with progress for: $YamlFilePath" -Source $MyInvocation.MyCommand -Level "Info"
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

        Write-DebugOutput -Message "YAML import completed successfully" -Source $MyInvocation.MyCommand -Level "Info"
        return $true

    } catch {
        Write-DebugOutput -Message "Error during YAML import: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
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

    Write-DebugOutput "Starting YAML import to data structures" -Source "Import-YamlToDataStructures" -Level "Debug"

    try {
        # Initialize AdvancedSettings if not exists
        if (-not $syncHash.AdvancedSettingsData) {
            Write-DebugOutput "Initializing AdvancedSettingsData structure" -Source "Import-YamlToDataStructures" -Level "Verbose"
            $syncHash.AdvancedSettingsData = [ordered]@{}
        }

        # Get top-level keys (now always hashtable)
        $topLevelKeys = $Config.Keys
        Write-DebugOutput "Found $($topLevelKeys.Count) top-level keys in YAML config" -Source "Import-YamlToDataStructures" -Level "Verbose"

        #get all products from UIConfigs
        $productIds = $syncHash.UIConfigs.products | Select-Object -ExpandProperty id

        # Get data validation keys from UIConfigs using new settingsControl structure
        $settingsControl = $syncHash.UIConfigs.settingsControl

        Write-DebugOutput -Message "Processing dynamic settings from settingsControl configuration" -Source $MyInvocation.MyCommand -Level "Info"

        # Import General Settings that are not product-specific or baseline controls
        $generalSettingsFields = $topLevelKeys | Where-Object {$_ -notin $productIds}

        foreach ($field in $generalSettingsFields) {
            $fieldValue = $Config[$field]

            # Dynamically find which settings type this field belongs to
            $matchingTabConfig = $null
            foreach ($tabName in $settingsControl.PSObject.Properties.Name) {
                $tabConfig = $settingsControl.$tabName
                if ($tabConfig.validationKeys -and $field -in $tabConfig.validationKeys) {
                    $matchingTabConfig = $tabConfig
                    break
                }
            }

            if ($matchingTabConfig -and $matchingTabConfig.dataControlOutput) {
                # Initialize the data structure if it doesn't exist
                $syncHashPropertyName = $matchingTabConfig.dataControlOutput  # e.g., "GeneralSettingsData", "AdvancedSettingsData", "GlobalSettingsData"
                if (-not $syncHash.$syncHashPropertyName) {
                    $syncHash.$syncHashPropertyName = [ordered]@{}
                }

                # Special handling for ProductNames to expand '*' wildcard
                if ($field -eq "ProductNames" -and $fieldValue -contains "*") {
                    # Expand '*' to all available products
                    $syncHash.$syncHashPropertyName[$field] = $productIds
                    Write-DebugOutput -Message "Imported $syncHashPropertyName setting (expanded wildcard): $field = $($productIds -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"
                } else {
                    $syncHash.$syncHashPropertyName[$field] = $fieldValue
                    Write-DebugOutput -Message "Imported $syncHashPropertyName setting: $field = $fieldValue" -Source $MyInvocation.MyCommand -Level "Info"
                }
            } else {
                Write-DebugOutput -Message "Skipping invalid/unknown setting key: $field (not found in any settingsControl validationKeys)" -Source $MyInvocation.MyCommand -Level "Warning"
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

                            Write-DebugOutput -Message "Imported $($baselineControl.controlType) for '$productName\$($baselineControl.yamlValue)\$policyId' with value: $($policyFieldData | ConvertTo-Json -Compress)" -Source $MyInvocation.MyCommand -Level "Info"
                        } else {
                            Write-DebugOutput -Message "Could not find product for policy: $policyId" -Source $MyInvocation.MyCommand -Level "Error"
                        }
                    }
                } else {
                    Write-DebugOutput -Message "No '$($baselineControl.yamlValue)' section found in YAML" -Source $MyInvocation.MyCommand -Level "Info"
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
                                    Write-DebugOutput -Message "Imported '$($baselineControl.controlType)' for '$productName\$policyId\$exclusionType' with value: $($policyData[$exclusionType] | ConvertTo-Json -Compress)" -Source $MyInvocation.MyCommand -Level "Info"
                                }
                            } else {
                                Write-DebugOutput -Message "Policy '$policyId' not found or doesn't support exclusions for product $productName" -Source $MyInvocation.MyCommand -Level "Error"
                            }
                        }
                    } else {
                        Write-DebugOutput -Message "No '$productName' section found in YAML" -Source $MyInvocation.MyCommand -Level "Info"
                    }
                }
            }
        }

        Write-DebugOutput -Message "Successfully imported YAML data to data structures" -Source $MyInvocation.MyCommand -Level "Info"
        # Update UI controls to reflect imported data
        Update-UIFromSettingsData
        Write-DebugOutput -Message "UI controls updated from imported data" -Source $MyInvocation.MyCommand -Level "Info"

    }
    catch {
        Write-DebugOutput -Message "Error importing data: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
        throw
    }
}

