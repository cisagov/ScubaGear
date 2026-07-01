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

    $progress        = $null
    $importSucceeded = $false
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

        # Pre-process: extract GUID display names from inline YAML comments (e.g. "- guid #DisplayName")
        # ConvertFrom-Yaml strips comments, so we harvest them from raw text before parsing.
        if ($syncHash.IdDisplayNameCache) { $syncHash.IdDisplayNameCache.Clear() }
        if ($syncHash.OrphanedIds) { $syncHash.OrphanedIds.Clear() }
        foreach ($line in ($yamlContent -split "`r?`n")) {
            if ($line -match '^\s*-\s+([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})\s+#(.+)$') {
                $syncHash.IdDisplayNameCache[$matches[1]] = $matches[2].Trim()
            }
        }

        $yamlHash = $yamlContent | ConvertFrom-Yaml

        # Step 2.5: If Graph is connected, resolve any IDs not already covered by inline comments.
        # Which YAML field names contain raw object IDs is determined entirely by the graphQueries
        # configuration - specifically entries whose outProperty is "id".  No field names are
        # hardcoded here; the config drives the discovery.
        if ($syncHash.GraphConnected) {
            $progress.UpdateMessage.Invoke("Resolving display names...", "Looking up IDs via Microsoft Graph")

            # Build the set of field names that store raw object IDs from the control config.
            $guidFieldNames = @{}
            $syncHash.UIConfigs.graphQueries.PSObject.Properties |
                Where-Object { $_.Value.outProperty -eq 'id' } |
                ForEach-Object { $guidFieldNames[$_.Name] = $true }

            if ($guidFieldNames.Count -gt 0) {
                # Walk the parsed YAML iteratively and collect IDs from those fields.
                $uncachedIds = [System.Collections.Generic.List[string]]::new()
                $stack = [System.Collections.Generic.Stack[object]]::new()
                $stack.Push($yamlHash)

                while ($stack.Count -gt 0) {
                    $node = $stack.Pop()
                    if ($node -is [hashtable] -or $node -is [System.Collections.IDictionary]) {
                        foreach ($key in @($node.Keys)) {
                            $val = $node[$key]
                            if ($guidFieldNames.ContainsKey($key) -and
                                $val -is [System.Collections.IEnumerable] -and
                                $val -isnot [string]) {
                                # Collect IDs not already in the cache (GUID format check is a
                                # sanity guard; the field name from config is the real selector).
                                foreach ($item in $val) {
                                    if ($item -is [string] -and
                                        $item -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' -and
                                        -not $syncHash.IdDisplayNameCache[$item]) {
                                        $uncachedIds.Add($item)
                                    }
                                }
                            } elseif ($val -is [hashtable] -or $val -is [System.Collections.IDictionary]) {
                                $stack.Push($val)
                            }
                        }
                    }
                }

                $uniqueUncachedIds = @($uncachedIds | Sort-Object -Unique)
                if ($uniqueUncachedIds.Count -gt 0) {
                    $progress.UpdateMessage.Invoke(
                        "Resolving display names...",
                        "Querying Graph for $($uniqueUncachedIds.Count) object ID(s)...")

                    Write-DebugOutput -Message "Resolving $($uniqueUncachedIds.Count) uncached IDs via Graph" -Source $MyInvocation.MyCommand -Level "Info"
                    $resolvedNames = Resolve-GraphIdsBatch -Ids $uniqueUncachedIds

                    # Populate display-name cache for found IDs.
                    foreach ($id in $resolvedNames.Keys) {
                        $syncHash.IdDisplayNameCache[$id] = $resolvedNames[$id]
                    }

                    # Track IDs that Graph did not return - object may have been deleted.
                    $notFound = @($uniqueUncachedIds | Where-Object { -not $resolvedNames.ContainsKey($_) })
                    foreach ($id in $notFound) { $syncHash.OrphanedIds[$id] = $true }

                    if ($notFound.Count -gt 0) {
                        $progress.UpdateMessage.Invoke(
                            "Resolving display names...",
                            "$($resolvedNames.Count) resolved, $($notFound.Count) not found in directory")
                        Write-DebugOutput -Message "$($notFound.Count) ID(s) not found in Graph: $($notFound -join ', ')" -Source $MyInvocation.MyCommand -Level "Warning"
                        Start-Sleep -Milliseconds 600
                    }
                }
            }
            Start-Sleep -Milliseconds 200
        }

        # Step 3: Clear existing data
        $progress.UpdateMessage.Invoke("Preparing for import...", "Clearing existing configuration")
        Start-Sleep -Milliseconds 200
        # Clear in-place rather than replacing so card closures that captured these object
        # references at creation time continue to point at the live data stores.
        $syncHash.ExclusionData.Clear()
        $syncHash.OmissionData.Clear()
        $syncHash.AnnotationData.Clear()
        $syncHash.GeneralSettingsData.Clear()
        $syncHash.AdvancedSettingsData.Clear()

        # Step 4: Import data structures (migration runs automatically inside)
        $progress.UpdateMessage.Invoke("Importing configuration data...", "Processing YAML sections")
        Start-Sleep -Milliseconds 300
        Import-YamlToDataStructures -Config $yamlHash

        # Step 5: Update UI
        $progress.UpdateMessage.Invoke("Updating user interface...", "Applying configuration to controls")
        Start-Sleep -Milliseconds 400

        # Step 6: Final processing
        $progress.UpdateMessage.Invoke("Finalizing import...", "Configuration applied successfully")
        Start-Sleep -Milliseconds 300

        $importSucceeded = $true
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
        # Always close progress window first
        if ($progress -and $progress.Close) {
            $progress.Close.Invoke()
        }
        # Show migration report if legacy policies were remapped (only on success)
        if ($importSucceeded -and $syncHash.MigrationLog -and $syncHash.MigrationLog.Count -gt 0) {
            $bullet    = [char]0x2022
            $migCfg    = $syncHash.UIConfigs.policyMigration
            $rptCfg    = $migCfg.localeReportWindow
            $maxLines  = [int]$migCfg.reportMaxLinesPerSection

            $migrated  = @($syncHash.MigrationLog | Where-Object { $_ -match "^$($rptCfg.sections.migrated.prefix)"  })
            $decoupled = @($syncHash.MigrationLog | Where-Object { $_ -match "^$($rptCfg.sections.decoupled.prefix)" })
            $dropped   = @($syncHash.MigrationLog | Where-Object { $_ -match "^$($rptCfg.sections.dropped.prefix)"   })

            $sections = [System.Collections.ArrayList]::new()

            if ($migrated.Count -gt 0) {
                $heading = $rptCfg.sections.migrated.heading -f $migrated.Count
                $lines   = ($migrated | Select-Object -First $maxLines | ForEach-Object { "$bullet $_" }) -join "`n"
                if ($migrated.Count -gt $maxLines) { $lines += "`n$bullet ... and $($migrated.Count - $maxLines) more" }
                [void]$sections.Add("$heading`n$lines")
            }
            if ($decoupled.Count -gt 0) {
                $heading = $rptCfg.sections.decoupled.heading -f $decoupled.Count
                $body    = $rptCfg.sections.decoupled.body
                $lines   = ($decoupled | ForEach-Object { "$bullet $_" }) -join "`n"
                [void]$sections.Add("$heading`n$body`n$lines")
            }
            if ($dropped.Count -gt 0) {
                $heading = $rptCfg.sections.dropped.heading -f $dropped.Count
                $lines   = ($dropped | ForEach-Object { "$bullet $_" }) -join "`n"
                [void]$sections.Add("$heading`n$lines")
            }

            $total = $syncHash.MigrationLog.Count
            $msg   = ($rptCfg.intro -f $total) + "`n`n" +
                     ($sections -join "`n`n") +
                     "`n`n" + $rptCfg.outro

            $icon = if ($decoupled.Count -gt 0) { [System.Windows.MessageBoxImage]::Warning } else { [System.Windows.MessageBoxImage]::Information }
            $syncHash.ShowMessageBox.Invoke(
                $msg,
                $rptCfg.title,
                [System.Windows.MessageBoxButton]::OK,
                $icon
            )
            $syncHash.MigrationLog = @()
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

        # Apply legacy policy migration before processing (Defender → SecuritySuite, etc.)
        $Config = Invoke-PolicyMigration -Config $Config

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

# =============================================================================
# Legacy Policy Migration Functions
# Automatically migrates old Defender/EXO policy settings found in imported
# YAML files to their SecuritySuite equivalents using the mapping defined in
# mappings\scuba-baseline-policy-migrations.csv.
# =============================================================================

Function Get-PolicyMigrationMap {
    <#
    .SYNOPSIS
    Builds or retrieves a cached policy migration map from the migrations CSV.
    .DESCRIPTION
    Reads PowerShell\ScubaGear\mappings\scuba-baseline-policy-migrations.csv to build
    a migration map that maps old Defender/EXO policy IDs to their SecuritySuite
    equivalents. The resulting map is cached to
    $env:TEMP\ScubaConfigApp_PolicyMigrationMap.json for performance. The cache is
    invalidated automatically when the source CSV is newer.
    .OUTPUTS
    Hashtable keyed by old policy ID, each value a PSCustomObject with:
      oldPolicyId, oldProduct, newPolicyId, newProduct, allNewPolicyIds, migrationNote.
    Returns an empty hashtable if the CSV cannot be found.
    #>

    $migCfg    = $syncHash.UIConfigs.policyMigration
    $cacheFile = Join-Path $env:TEMP $migCfg.cacheFileName

    # Locate the CSV using the path stored in the JSON config
    $moduleDir = Split-Path $syncHash.UIConfigPath -Parent
    $csvPath   = Join-Path $moduleDir $syncHash.UIConfigs.PolicyMigrationsCSVPath

    try {
        $csvPath = (Resolve-Path $csvPath -ErrorAction Stop).Path
    } catch {
        Write-DebugOutput -Message "Migration CSV not found at: $csvPath" -Source $MyInvocation.MyCommand -Level "Warning"
        return @{}
    }

    # Return cached map when it is still current
    if (Test-Path $cacheFile) {
        $cacheAge  = (Get-Item $cacheFile).LastWriteTime
        $sourceAge = (Get-Item $csvPath).LastWriteTime
        if ($cacheAge -ge $sourceAge) {
            try {
                $cached = Get-Content $cacheFile -Raw | ConvertFrom-Json
                $map    = @{}
                foreach ($entry in $cached.migrations) { $map[$entry.oldPolicyId] = $entry }
                Write-DebugOutput -Message "Loaded policy migration map from cache ($($map.Count) entries)" -Source $MyInvocation.MyCommand -Level "Info"
                return $map
            } catch {
                Write-DebugOutput -Message "Cache read failed; rebuilding: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Warning"
            }
        }
    }

    Write-DebugOutput -Message "Building policy migration map from CSV: $csvPath" -Source $MyInvocation.MyCommand -Level "Info"

    # Build product code map from the products list: uppercase id -> id (e.g. SECURITYSUITE -> SecuritySuite)
    # Legacy products (e.g. DEFENDER) are not in the list; they fall back to the raw uppercase code.
    $productCodeMap = @{}
    foreach ($product in $syncHash.UIConfigs.products) { $productCodeMap[$product.id.ToUpper()] = $product.id }
    $colOldId    = $migCfg.csvColumns.oldId
    $colNewId    = $migCfg.csvColumns.newId
    $colRationale= $migCfg.csvColumns.rationale
    $typeRemoved  = $migCfg.migrationTypes.removed
    $typeDecoupled= $migCfg.migrationTypes.decoupled
    $typeDirect   = $migCfg.migrationTypes.direct

    $migrations   = [System.Collections.ArrayList]::new()
    $migrationMap = @{}

    foreach ($row in (Import-Csv -Path $csvPath)) {
        $oldPolicyId = $row.$colOldId.Trim()
        if ([string]::IsNullOrWhiteSpace($oldPolicyId)) { continue }

        # Derive old product from policy ID (e.g. MS.DEFENDER.1.1v1 → Defender)
        $oldProduct = $null
        if ($oldPolicyId -match '^MS\.([A-Z]+)\.') {
            $code = $matches[1]
            $oldProduct = if ($productCodeMap.ContainsKey($code)) { $productCodeMap[$code] } else { $code }
        }

        # New ID may be "None", a single ID, or a range like "MS.X.1.1v1 - MS.X.1.4v1"
        # Extract all policy IDs present; use the first as the canonical migration target.
        $rawNewId        = $row.$colNewId.Trim()
        $allNewPolicyIds = @([regex]::Matches($rawNewId, 'MS\.[A-Z]+\.\d+\.\d+v\d+') |
                             Select-Object -ExpandProperty Value)
        $newPolicyId     = if ($allNewPolicyIds.Count -gt 0) { $allNewPolicyIds[0] } else { $null }

        # Derive new product from new policy ID
        $newProduct = $null
        if ($newPolicyId -and $newPolicyId -match '^MS\.([A-Z]+)\.') {
            $code = $matches[1]
            $newProduct = if ($productCodeMap.ContainsKey($code)) { $productCodeMap[$code] } else { $code }
        }

        $migrationType = if (-not $newPolicyId)               { $typeRemoved   }
                        elseif ($allNewPolicyIds.Count -gt 1)  { $typeDecoupled }
                        else                                   { $typeDirect    }

        $entry = [PSCustomObject]@{
            oldPolicyId     = $oldPolicyId
            oldProduct      = $oldProduct
            newPolicyId     = $newPolicyId
            newProduct      = $newProduct
            allNewPolicyIds = $allNewPolicyIds
            migrationNote   = $row.$colRationale.Trim()
            migrationType   = $migrationType
        }
        $migrationMap[$oldPolicyId] = $entry
        [void]$migrations.Add($entry)
    }

    # Persist to cache
    try {
        $cacheObj = [ordered]@{
            version     = '1.0'
            generatedAt = (Get-Date -Format 'o')
            sourceFile  = $csvPath
            migrations  = $migrations.ToArray()
        }
        $cacheObj | ConvertTo-Json -Depth 6 | Out-File -FilePath $cacheFile -Encoding utf8 -Force
        Write-DebugOutput -Message "Policy migration map cached: $cacheFile ($($migrations.Count) entries)" -Source $MyInvocation.MyCommand -Level "Info"
    } catch {
        Write-DebugOutput -Message "Failed to write migration cache: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Warning"
    }

    return $migrationMap
}

Function Invoke-PolicyMigration {
    <#
    .SYNOPSIS
    Migrates legacy Defender/EXO policy settings to SecuritySuite equivalents.
    .DESCRIPTION
    Applies the policy migration map to a parsed YAML config hashtable produced by
    ConvertFrom-Yaml. Two classes of data are handled:

      1. Product-level exclusion keys  (e.g., "Defender", "Exo") containing old
         policy IDs - moved to the correct new product key with the new policy ID.
      2. Annotation/omission keys (e.g., "AnnotatePolicy", "OmitPolicy") containing
         old policy IDs as keys - remapped to the corresponding new policy IDs.

    Policies removed with no SecuritySuite replacement are silently dropped with a
    note in the migration log.

    Results are stored in $syncHash.MigrationLog (an ArrayList of strings) and the
    modified config hashtable is returned.
    .PARAMETER Config
    The hashtable produced by ConvertFrom-Yaml representing the user's YAML file.
    .OUTPUTS
    The migrated config hashtable.
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Config
    )

    $syncHash.MigrationLog           = [System.Collections.ArrayList]::new()
    $syncHash.MigrationPendingReview  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # Tracks new products that actually received migrated data, so the product
    # checkboxes (driven by ProductNames) can be kept in sync. Values are derived
    # entirely from the CSV migration map - nothing here is hardcoded.
    $migratedToProducts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # Helper: returns $true only if $policyId has a renderable card for $controlType.
    # A card is renderable when the policy exists in Baselines with a non-'none' fieldControlName value,
    # OR the control supports all products (annotations/omissions always render).
    $HasRenderableCard = {
        param([string]$ControlType, [string]$ProductId, [string]$PolicyId)
        $ctrl = $syncHash.UIConfigs.baselineControls | Where-Object { $_.controlType -eq $ControlType } | Select-Object -First 1
        if (-not $ctrl) { return $false }
        if ($ctrl.supportsAllProducts) { return $true }   # annotations/omissions always render
        $baseline = $syncHash.Baselines.($ProductId) | Where-Object { $_.id -eq $PolicyId } | Select-Object -First 1
        if (-not $baseline) { return $false }
        $fieldVal = $baseline.($ctrl.fieldControlName)
        return ($fieldVal -and $fieldVal -ne 'none')
    }

    $migrationMap = Get-PolicyMigrationMap
    if ($migrationMap.Count -eq 0) {
        Write-DebugOutput -Message "No migration map loaded; skipping legacy policy migration" -Source $MyInvocation.MyCommand -Level "Info"
        return $Config
    }

    # Load log prefix tokens and migration type labels from the JSON config
    $migCfg         = $syncHash.UIConfigs.policyMigration
    $pfxMigrated    = $migCfg.localeReportWindow.sections.migrated.prefix
    $pfxDecoupled   = $migCfg.localeReportWindow.sections.decoupled.prefix
    $pfxSkipped     = $migCfg.localeReportWindow.sections.skipped.prefix
    $pfxDropped     = $migCfg.localeReportWindow.sections.dropped.prefix
    $typeDecoupled  = $migCfg.migrationTypes.decoupled

    # Collect the yamlValue keys used by annotation/omission controls so they are
    # not treated as product exclusion blocks in Pass 1.
    $annotationYamlKeys = @(
        $syncHash.UIConfigs.baselineControls |
        Where-Object { $_.supportsAllProducts -eq $true } |
        Select-Object -ExpandProperty yamlValue
    )

    #---------------------------------------------------------------------------
    # Pass 1 - Product-level exclusion blocks
    #   YAML: <ProductKey> → <OldPolicyId> → exclusion data
    #   Goal: move old policy ID to <NewProductKey>/<NewPolicyId>
    #---------------------------------------------------------------------------
    foreach ($productKey in @($Config.Keys)) {          # snapshot keys
        if ($productKey -in $annotationYamlKeys) { continue }

        $productData = $Config[$productKey]
        if (-not ($productData -is [System.Collections.IDictionary])) { continue }

        $policiesToMigrate = @($productData.Keys) | Where-Object { $migrationMap.ContainsKey($_) }
        if ($policiesToMigrate.Count -eq 0) { continue }

        foreach ($oldPolicyId in $policiesToMigrate) {
            $entry = $migrationMap[$oldPolicyId]

            if (-not $entry.newPolicyId -or -not $entry.newProduct) {
                $productData.Remove($oldPolicyId)
                [void]$syncHash.MigrationLog.Add(
                    "$pfxDropped exclusion [$productKey][$oldPolicyId] - no replacement policy. Rationale: $($entry.migrationNote)")
                Write-DebugOutput -Message "Dropped removed-policy exclusion: [$productKey][$oldPolicyId]" -Source $MyInvocation.MyCommand -Level "Warning"
                continue
            }

            $newProductKey = $entry.newProduct
            $newPolicyId   = $entry.newPolicyId
            [void]$migratedToProducts.Add($entry.newProduct.ToLower())

            # Create the target product key if it does not yet exist in the config
            if (-not ($Config.Keys -contains $newProductKey)) {
                $Config[$newProductKey] = [ordered]@{}
            }
            $targetData = $Config[$newProductKey]

            if (-not ($targetData.Keys -contains $newPolicyId)) {
                $targetData[$newPolicyId] = $productData[$oldPolicyId]
                if ($entry.migrationType -eq $typeDecoupled) {
                    [void]$syncHash.MigrationLog.Add(
                        "$pfxDecoupled exclusion [$productKey][$oldPolicyId] → [$newProductKey][$newPolicyId] (policy split into: $($entry.allNewPolicyIds -join ', '))")
                } else {
                    [void]$syncHash.MigrationLog.Add(
                        "$pfxMigrated exclusion [$productKey][$oldPolicyId] → [$newProductKey][$newPolicyId]")
                }
                Write-DebugOutput -Message "Migrated exclusion: [$productKey][$oldPolicyId] → [$newProductKey][$newPolicyId]" -Source $MyInvocation.MyCommand -Level "Info"
                if (& $HasRenderableCard 'Exclusions' $newProductKey $newPolicyId) {
                    [void]$syncHash.MigrationPendingReview.Add("Exclusions|$newPolicyId")
                } else {
                    Write-DebugOutput -Message "Skipping MigrationPendingReview for [$newPolicyId]: no renderable Exclusion card" -Source $MyInvocation.MyCommand -Level "Info"
                }
            } else {
                [void]$syncHash.MigrationLog.Add(
                    "$pfxSkipped exclusion [$productKey][$oldPolicyId] → [$newProductKey][$newPolicyId] (target already configured)")
                Write-DebugOutput -Message "Migration skipped - target already configured: [$newProductKey][$newPolicyId]" -Source $MyInvocation.MyCommand -Level "Warning"
            }
            $productData.Remove($oldPolicyId)
        }

        # Remove the old product key if it is now empty (e.g., an old Defender section)
        if ($productData.Count -eq 0) {
            $Config.Remove($productKey)
            Write-DebugOutput -Message "Removed empty product key after migration: $productKey" -Source $MyInvocation.MyCommand -Level "Info"
        }
    }

    #---------------------------------------------------------------------------
    # Pass 2 - Annotation / omission keys (AnnotatePolicy, OmitPolicy, etc.)
    #   YAML: <yamlValue> → <OldPolicyId> → field data
    #   Goal: remap old policy ID key to new policy ID key
    #---------------------------------------------------------------------------
    foreach ($yamlValue in $annotationYamlKeys) {
        if (-not ($Config.Keys -contains $yamlValue)) { continue }

        $controlData = $Config[$yamlValue]
        if (-not ($controlData -is [System.Collections.IDictionary])) { continue }

        # Resolve controlType once per yamlValue so pending keys are scope-aware
        $yamlControlType = ($syncHash.UIConfigs.baselineControls | Where-Object { $_.yamlValue -eq $yamlValue }).controlType

        $policiesToMigrate = @($controlData.Keys) | Where-Object { $migrationMap.ContainsKey($_) }

        foreach ($oldPolicyId in $policiesToMigrate) {
            $entry = $migrationMap[$oldPolicyId]

            if (-not $entry.newPolicyId) {
                $controlData.Remove($oldPolicyId)
                [void]$syncHash.MigrationLog.Add(
                    "$pfxDropped $yamlValue [$oldPolicyId] - no replacement policy. Rationale: $($entry.migrationNote)")
                Write-DebugOutput -Message "Dropped removed-policy $yamlValue entry: [$oldPolicyId]" -Source $MyInvocation.MyCommand -Level "Warning"
                continue
            }

            $newPolicyId = $entry.newPolicyId
            if ($entry.newProduct) { [void]$migratedToProducts.Add($entry.newProduct.ToLower()) }

            if (-not ($controlData.Keys -contains $newPolicyId)) {
                $controlData[$newPolicyId] = $controlData[$oldPolicyId]
                if ($entry.migrationType -eq $typeDecoupled) {
                    [void]$syncHash.MigrationLog.Add(
                        "$pfxDecoupled $yamlValue [$oldPolicyId] → [$newPolicyId] (policy split into: $($entry.allNewPolicyIds -join ', '))")
                } else {
                    [void]$syncHash.MigrationLog.Add("$pfxMigrated $yamlValue [$oldPolicyId] → [$newPolicyId]")
                }
                Write-DebugOutput -Message "Migrated ${yamlValue}: [$oldPolicyId] → [$newPolicyId]" -Source $MyInvocation.MyCommand -Level "Info"
                if (& $HasRenderableCard $yamlControlType '' $newPolicyId) {
                    [void]$syncHash.MigrationPendingReview.Add("$yamlControlType|$newPolicyId")
                } else {
                    Write-DebugOutput -Message "Skipping MigrationPendingReview for [$newPolicyId]: no renderable $yamlControlType card" -Source $MyInvocation.MyCommand -Level "Info"
                }
            } else {
                [void]$syncHash.MigrationLog.Add(
                    "$pfxSkipped $yamlValue [$oldPolicyId] → [$newPolicyId] (target already configured)")
                Write-DebugOutput -Message "Migration skipped - ${yamlValue} target exists: [$newPolicyId]" -Source $MyInvocation.MyCommand -Level "Warning"
            }
            $controlData.Remove($oldPolicyId)
        }
    }

    #---------------------------------------------------------------------------
    # Pass 3 - ProductNames remap
    #   Keeps the product selection in sync with the migrated data. Fully driven
    #   by the CSV migration map + the products list in the control JSON:
    #     * product codes that no longer exist (e.g. defender) are replaced with
    #       their mapped successor (e.g. securitysuite)
    #     * any product that actually received migrated data is ensured selected
    #   Nothing is hardcoded here.
    #---------------------------------------------------------------------------
    if (($Config.Keys -contains 'ProductNames') -and $Config['ProductNames']) {
        $validProductIds = @($syncHash.UIConfigs.products | Select-Object -ExpandProperty id | ForEach-Object { $_.ToLower() })

        # Build old->new product rename map from the migration map. Only applied to
        # products that no longer exist as selectable products (e.g. defender).
        $productRenameMap = @{}
        foreach ($mEntry in $migrationMap.Values) {
            if ($mEntry.oldProduct -and $mEntry.newProduct) {
                $oldP = $mEntry.oldProduct.ToLower()
                $newP = $mEntry.newProduct.ToLower()
                if (($oldP -ne $newP) -and ($validProductIds -notcontains $oldP) -and (-not $productRenameMap.ContainsKey($oldP))) {
                    $productRenameMap[$oldP] = $newP
                }
            }
        }

        $remapped            = [System.Collections.Generic.List[string]]::new()
        $productNamesChanged = $false

        foreach ($p in @($Config['ProductNames'])) {
            $pl = "$p".ToLower()
            if ($validProductIds -contains $pl) {
                if (-not $remapped.Contains($pl)) { [void]$remapped.Add($pl) }
            } elseif ($productRenameMap.ContainsKey($pl)) {
                $newP = $productRenameMap[$pl]
                if (-not $remapped.Contains($newP)) { [void]$remapped.Add($newP) }
                $productNamesChanged = $true
                [void]$syncHash.MigrationLog.Add("$pfxMigrated ProductNames [$pl] -> [$newP]")
                Write-DebugOutput -Message "Migrated ProductNames: [$pl] -> [$newP]" -Source $MyInvocation.MyCommand -Level "Info"
            } else {
                if (-not $remapped.Contains($pl)) { [void]$remapped.Add($pl) }
            }
        }

        # Ensure any product that actually received migrated data is selected.
        foreach ($mp in $migratedToProducts) {
            $mpl = $mp.ToLower()
            if (($validProductIds -contains $mpl) -and (-not $remapped.Contains($mpl))) {
                [void]$remapped.Add($mpl)
                $productNamesChanged = $true
                Write-DebugOutput -Message "Added migrated product to ProductNames: [$mpl]" -Source $MyInvocation.MyCommand -Level "Info"
            }
        }

        if ($productNamesChanged) {
            $Config['ProductNames'] = [string[]]$remapped
            Write-DebugOutput -Message "ProductNames after migration: $($remapped -join ', ')" -Source $MyInvocation.MyCommand -Level "Info"
        }
    }

    Write-DebugOutput -Message "Policy migration complete: $($syncHash.MigrationLog.Count) change(s)" -Source $MyInvocation.MyCommand -Level "Info"
    return $Config
}

