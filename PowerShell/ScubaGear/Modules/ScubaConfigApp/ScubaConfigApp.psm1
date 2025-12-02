# Helper function to show message boxes on top of the main window
function Show-ScubaMessageBox {
    param(
        [string]$Message,
        [string]$Title = "ScubaGear Configuration",
        [System.Windows.MessageBoxButton]$Button = [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::Information
    )

    # Use the main window handle to ensure message box appears on top
    if ($syncHash.Window) {
        # Get the window handle
        $windowHelper = New-Object System.Windows.Interop.WindowInteropHelper($syncHash.Window)
        $handle = $windowHelper.Handle

        # Import user32.dll to use MessageBox with owner handle
        Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            public class Win32MessageBox {
                [DllImport("user32.dll", CharSet = CharSet.Unicode)]
                public static extern int MessageBox(IntPtr hWnd, string text, string caption, uint type);
            }
"@

        # Convert WPF enums to Win32 constants
        $buttonValue = switch ($Button) {
            ([System.Windows.MessageBoxButton]::OK) { 0x0 }
            ([System.Windows.MessageBoxButton]::OKCancel) { 0x1 }
            ([System.Windows.MessageBoxButton]::YesNo) { 0x4 }
            ([System.Windows.MessageBoxButton]::YesNoCancel) { 0x3 }
            default { 0x0 }
        }

        $iconValue = switch ($Icon) {
            ([System.Windows.MessageBoxImage]::Information) { 0x40 }
            ([System.Windows.MessageBoxImage]::Question) { 0x20 }
            ([System.Windows.MessageBoxImage]::Warning) { 0x30 }
            ([System.Windows.MessageBoxImage]::Error) { 0x10 }
            default { 0x40 }
        }

        $result = [Win32MessageBox]::MessageBox($handle, $Message, $Title, ($buttonValue -bor $iconValue))

        # Convert Win32 result back to WPF enum
        switch ($result) {
            1 { return [System.Windows.MessageBoxResult]::OK }
            2 { return [System.Windows.MessageBoxResult]::Cancel }
            6 { return [System.Windows.MessageBoxResult]::Yes }
            7 { return [System.Windows.MessageBoxResult]::No }
            default { return [System.Windows.MessageBoxResult]::OK }
        }
    } else {
        # Fallback to standard MessageBox if window not available
        return [System.Windows.MessageBox]::Show($Message, $Title, $Button, $Icon)
    }
}

Function Start-SCuBAConfigApp {
    <#
    .SYNOPSIS
    Opens the ScubaConfig UI for configuring Scuba settings.

    .DESCRIPTION
    This Function opens a WPF-based UI for configuring Scuba settings.

    .EXAMPLE
    Start-SCuBAConfigApp
    # Opens the ScubaConfig UI.

    .PARAMETER ConfigFilePath
    Specifies the YAML configuration file to load. If not provided, the default configuration will be used.

    .PARAMETER Language
    Specifies the language for the UI. Default is 'en-US'.

    .PARAMETER Online
    If specified, connects to Microsoft Graph to retrieve additional configuration data.

    .PARAMETER M365Environment
    Specifies the M365 environment to use. Valid values are 'commercial', 'dod', 'gcc', 'gcchigh'. Default is 'commercial'.

    .PARAMETER Passthru
    If specified, returns the configuration object after loading.

    .EXAMPLE
    Start-SCuBAConfigApp

    .EXAMPLE
    $scubaui = Start-SCuBAConfigApp -ConfigFilePath "C:\path\to\config.yaml" -Online -M365Environment "gcc" -Passthru

    # To show configurations run:
    $scubaui.GeneralSettingsData | ConvertTo-Json
    $scubaui.AdvancedSettingsData | ConvertTo-Json
    $scubaui.ExclusionData | ConvertTo-Json -Depth 5
    $scubaui.OmissionData | ConvertTo-Json -Depth 5
    $scubaui.AnnotationData | ConvertTo-Json -Depth 5

    .NOTES
    This Function requires the ScubaConfig module to be loaded and the ConvertFrom-Yaml Function to be available.
    https://github.com/cisagov/ScubaGear

    .LINK
    Connect-MgGraph
    ConvertFrom-Yaml
    #>

    [CmdletBinding(DefaultParameterSetName = 'Offline')]
    Param(
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$ConfigFilePath,

        [ValidateSet('en-US')]
        $Language = 'en-US',

        [Parameter(Mandatory = $false,ParameterSetName = 'Online')]
        [switch]$Online,

        [Parameter(Mandatory = $false,ParameterSetName = 'Online')]
        [ValidateSet('commercial', 'dod', 'gcc', 'gcchigh')]
        [string]$M365Environment = 'commercial',

        [Parameter(Mandatory = $false,ParameterSetName = 'Online')]
        [string]$TenantName,

        [switch]$Passthru
    )

    [string]${CmdletName} = $MyInvocation.MyCommand
    Write-Verbose ("{0}: Sequencer started" -f ${CmdletName})

    switch($M365Environment){
        'commercial' {
            $GraphEndpoint = "https://graph.microsoft.com"
            $graphEnvironment = "Global"
        }
        'gcc' {
            $GraphEndpoint = "https://graph.microsoft.com"
            $graphEnvironment = "Global"
        }
        'gcchigh' {
            # Set GCC High environment variables
            $GraphEndpoint = "https://graph.microsoft.us"
            $graphEnvironment = "UsGov"
        }
        'dod' {
            # Set DoD environment variables
            $GraphEndpoint = "https://dod-graph.microsoft.us"
            $graphEnvironment = "UsGovDoD"
        }
        default {
            $GraphEndpoint = "https://graph.microsoft.com"
            $graphEnvironment = "Global"
        }

    }

    $GraphParameters = @{
        Environment = $graphEnvironment
    }
    If($TenantName) {
        $GraphParameters.TenantId = $TenantName
    }
    $GraphParameters.Scopes = @(
        "User.Read.All",
        "Group.Read.All",
        "Organization.Read.All",
        "Application.Read.All"
    )

    # Connect to Microsoft Graph if Online parameter is used
    if ($Online) {
        try {
            #Allow PRMFA: Set-MgGraphOption -EnableLoginByWAM:$true
            Write-Output ""
            Write-Output "Connecting to Microsoft Graph..."
            Connect-MgGraph @GraphParameters -NoWelcome -ErrorAction Stop | Out-Null

            #ensure user is authenticated
            Invoke-MgGraphRequest -Method GET -Uri "$GraphEndpoint/v1.0/me" -ErrorAction Stop | Out-Null
            Write-Output " - Successfully connected to Microsoft Graph"
            $GraphConnected = $true
        }
        catch {
            Write-Error " - Failed to connect to Microsoft Graph: $($_.Exception.Message)"
            $GraphConnected = $false
            Break
        }
    } else {
        $GraphConnected = $false
    }

    Write-Output "Launching ScubaConfigApp...please wait."
    If($ConfigFilePath){
        Write-Output "Importing configuration from $ConfigFilePath..."
    }

    # build a hash table with locale data to pass to runspace
    $syncHash = [hashtable]::Synchronized(@{})
    $Runspace = [runspacefactory]::CreateRunspace()
    $syncHash.Runspace = $Runspace

    # Store the helper function in syncHash for access from event handlers
    $syncHash.ShowMessageBox = ${function:Show-ScubaMessageBox}

    # Build the syncHash with necessary paths and parameters
    $syncHash.Online = $Online
    $syncHash.GraphConnected = $GraphConnected
    $syncHash.XamlPath = "$PSScriptRoot\ScubaConfigAppResources\ScubaConfigAppUI.xaml"
    $syncHash.ChangelogPath = "$PSScriptRoot\ScubaConfigApp_CHANGELOG.md"
    $syncHash.ImgPath = "$PSScriptRoot\ScubaConfigAppResources\ScubaConfigApp_logo.png"
    $syncHash.IcoPath = "$PSScriptRoot\ScubaConfigAppResources\ScubaConfigApp_logo.ico"
    $syncHash.UIConfigPath = "$PSScriptRoot\ScubaConfigApp_Control_$Language.json"
    $syncHash.BaselineConfigPath = "$PSScriptRoot\ScubaBaselines_$Language.json"
    $syncHash.HelperModulesPath = "$PSScriptRoot\ScubaConfigAppHelpers"
    $syncHash.ConfigImportPath = $ConfigFilePath
    $syncHash.GraphEndpoint = $GraphEndpoint
    $syncHash.M365Environment = $M365Environment
    $syncHash.TenantName = $TenantName

    # Initialize debug output structures
    $syncHash.DebugLogData = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())  # For debug download
    $syncHash.DebugSanitizeMapping = @{} #for mapping when using sanitized data

    # Initialize data structures
    $syncHash.GeneralSettingsData = [ordered]@{}
    $syncHash.AdvancedSettingsData = [ordered]@{}
    $syncHash.GlobalSettingsData = [ordered]@{}

    #Baseline control data structures: must be same with UIConfigs.baselineControl.dataControlOutput
    $syncHash.ExclusionData = [ordered]@{}
    $syncHash.OmissionData = [ordered]@{}
    $syncHash.AnnotationData = [ordered]@{}
    #build runspace
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "ReuseThread"
    $Runspace.Open() | Out-Null
    $Runspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
    $PowerShellCommand = [PowerShell]::Create().AddScript({

        #Load assembies to display UI
        [System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | out-null
        [System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')      | out-null
        #Load additional assemblies for folder browser and certificate selection
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | out-null
        [System.Reflection.Assembly]::LoadWithPartialName('System.Security') | out-null

        #need to replace compile code in xaml and x:Class and xmlns needs to be removed
        [string]$XAML = (Get-Content $syncHash.XamlPath -ReadCount 0) -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window' -replace 'Click=".*','/>'
        [xml]$UIXML = $XAML
        $reader = New-Object System.Xml.XmlNodeReader ([xml]$UIXML)
        $syncHash.window = [Windows.Markup.XamlReader]::Load($reader)
        $syncHash.UIXML = $UIXML

         # Store Form Objects In PowerShell
        $UIXML.SelectNodes("//*[@Name]") | ForEach-Object{ $syncHash."$($_.Name)" = $syncHash.Window.FindName($_.Name)}

        #parse changelog for version for a more accurate version
        If(Test-Path $syncHash.ChangelogPath){
            $ChangeLog = Get-Content $syncHash.ChangelogPath
            $Changedetails = (($ChangeLog -match '##')[0].TrimStart('##') -split '-').Trim()
            #update version
            $syncHash.Version_TextBlock.Text = "v$($Changedetails[0])"
        }Else{
            $syncHash.Version_TextBlock.Text = (Get-Date -Format "1.MM.dd")
        }


        #===========================================================================
        # Import modules
        #===========================================================================
        Import-Module "$($syncHash.HelperModulesPath)\ScubaConfigAppDebugHelper.psm1"

        #loop thru each module and import exclude the debug helper
        Get-ChildItem -Path $syncHash.HelperModulesPath -Filter '*.psm1' | Where-Object { $_.Name -ne "ScubaConfigAppDebugHelper.psm1" } | ForEach-Object {
            Try{
                Import-Module "$($_.FullName)" -Force -ErrorAction Stop
                Write-DebugOutput -Message "'$($_.Name)' module loaded successfully" -Source "Module Import" -Level "Info"
            } Catch {
                Write-DebugOutput -Message "Failed to load '$($_.Name)' module: $($_.Exception.Message)" -Source "Module Import" -Level "Error"
            }
        }
        #===========================================================================
        #
        # LOAD UI
        #
        #===========================================================================
        $source = "Initialization"
        # Set window icon from DrawingImage resource
        $syncHash.Window.Icon = $syncHash.IcoPath
        $syncHash.LogoImage.Source = $syncHash.ImgPath

        # Set TaskbarItemInfo to display custom icon as overlay in taskbar
        try {
            $taskbarInfo = New-Object System.Windows.Shell.TaskbarItemInfo

            # Load the icon for taskbar overlay
            if (Test-Path $syncHash.IcoPath) {
                $iconStream = [System.IO.File]::OpenRead($syncHash.IcoPath)
                $iconDecoder = New-Object System.Windows.Media.Imaging.IconBitmapDecoder(
                    $iconStream,
                    [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
                    [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                )
                $taskbarInfo.Overlay = $iconDecoder.Frames[0]
                $iconStream.Close()

                Write-DebugOutput -Message "TaskbarItemInfo overlay icon set successfully" -Source $source -Level "Info"
            }

            # Set initial progress state to None (no progress bar shown)
            $taskbarInfo.ProgressState = [System.Windows.Shell.TaskbarItemProgressState]::None

            # Attach TaskbarItemInfo to the window
            $syncHash.Window.TaskbarItemInfo = $taskbarInfo
            $syncHash.TaskbarInfo = $taskbarInfo

            Write-DebugOutput -Message "TaskbarItemInfo initialized successfully" -Source $source -Level "Info"
        }
        catch {
            Write-DebugOutput -Message "Failed to set TaskbarItemInfo: $($_.Exception.Message)" -Source $source -Level "Warning"
        }

        $syncHash.UIConfigs = (Get-Content -Path $syncHash.UIConfigPath -Raw) | ConvertFrom-Json
        Write-DebugOutput -Message "UIConfigs loaded: $($syncHash.UIConfigPath)" -Source $source -Level "Info"

        # Cascading baseline loading strategy
        $syncHash.Baselines = $null
        $ModuleBasePath = Split-Path $syncHash.UIConfigPath -Parent
        $RegoTestPath = Join-Path $ModuleBasePath $syncHash.UIConfigs.OfflineRegoFolderPath

        # Strategy 1: Local Rego parsing from markdown baselines (primary strategy when PullOnlineBaselines is false)
        if (-not $syncHash.UIConfigs.PullOnlineBaselines -and (Test-Path $RegoTestPath)) {
            try {
                Write-DebugOutput -Message "Attempting to dynamically parse baselines from local Rego markdown files" -Source $source -Level "Verbose"

                $RegoResolvedPath = (Resolve-Path $RegoTestPath).Path
                $BaselineDestPath = "$env:Temp\ScubaBaselines_Dynamic.json"

                # Create empty baseline structure for Rego to populate
                $emptyBaseline = @{ baselines = @{} } | ConvertTo-Json -Depth 10
                $emptyBaseline | Out-File -FilePath $BaselineDestPath -Encoding utf8 -Force

                # Use local markdown baselines directory
                $LocalBaselineMarkdownPath = Join-Path $ModuleBasePath $syncHash.UIConfigs.OfflineBaselineMarkdownPath
                $LocalBaselineMarkdownResolved = (Resolve-Path $LocalBaselineMarkdownPath).Path

                Write-DebugOutput -Message "Local baseline markdown path: $LocalBaselineMarkdownResolved" -Source $source -Level "Verbose"
                Write-DebugOutput -Message "Local Rego path: $RegoResolvedPath" -Source $source -Level "Verbose"

                Update-ScubaConfigBaselineWithRego `
                    -ConfigFilePath $BaselineDestPath `
                    -GitHubDirectoryUrl $LocalBaselineMarkdownResolved `
                    -RegoDirectory $RegoResolvedPath `
                    -AdditionalFields @('criticality')

                $JsonConfigData = (Get-Content -Path $BaselineDestPath -Raw | ConvertFrom-Json)
                $syncHash.Baselines = $JsonConfigData.baselines
                Write-DebugOutput -Message "Successfully loaded baselines using: Local Rego Dynamic Parsing" -Source $source -Level "Info"
            }
            catch {
                Write-DebugOutput -Message "Failed to load baselines using Local Rego parsing: $($_.Exception.Message)" -Source $source -Level "Warning"
                $syncHash.Baselines = $null
            }
        }

        # Strategy 2: Online Markdown with Rego processing (if online and enabled)
        if (-not $syncHash.Baselines -and $syncHash.Online -and $syncHash.UIConfigs.PullOnlineBaselines -and (Test-Path $RegoTestPath)) {
            try {
                Write-DebugOutput -Message "Attempting to load baselines from online markdown files in this directory: $($syncHash.UIConfigs.OnlineBaselineMarkdownURL)" -Source $source -Level "Verbose"

                $RegoResolvedPath = (Resolve-Path $RegoTestPath).Path
                $BaselineDestPath = "$env:Temp\ScubaBaselines.json"

                # Create empty baseline structure for Rego to populate
                $emptyBaseline = @{ baselines = @{} } | ConvertTo-Json -Depth 10
                $emptyBaseline | Out-File -FilePath $BaselineDestPath -Encoding utf8 -Force

                Update-ScubaConfigBaselineWithRego `
                    -ConfigFilePath $BaselineDestPath `
                    -GitHubDirectoryUrl $syncHash.UIConfigs.OnlineBaselineMarkdownURL `
                    -RegoDirectory $RegoResolvedPath `
                    -AdditionalFields @('criticality')

                $JsonConfigData = (Get-Content -Path $BaselineDestPath -Raw | ConvertFrom-Json)
                $syncHash.Baselines = $JsonConfigData.baselines
                Write-DebugOutput -Message "Successfully loaded baselines using: Online Markdown with Rego Baseline" -Source $source -Level "Info"
            }
            catch {
                Write-DebugOutput -Message "Failed to load baselines using Online Markdown with Rego Baseline: $($_.Exception.Message)" -Source $source -Level "Warning"
                $syncHash.Baselines = $null
            }
        }

        # Strategy 3: Online JSON baseline (if previous strategies failed and online is enabled)
        if (-not $syncHash.Baselines -and $syncHash.Online -and $syncHash.UIConfigs.PullOnlineBaselines) {
            try {
                Write-DebugOutput -Message "Attempting to load baselines from online JSON: $($syncHash.UIConfigs.OnlineBaselineJsonURL)" -Source $source -Level "Verbose"

                $onlineBaselines = (Invoke-RestMethod -Uri $syncHash.UIConfigs.OnlineBaselineJsonURL -ErrorAction Stop).baselines
                $syncHash.Baselines = $onlineBaselines
                Write-DebugOutput -Message "Successfully loaded baselines using: Online JSON Baseline" -Source $source -Level "Info"
            }
            catch {
                Write-DebugOutput -Message "Failed to load baselines using Online JSON Baseline: $($_.Exception.Message)" -Source $source -Level "Warning"
                $syncHash.Baselines = $null
            }
        }

        # Strategy 4: Local baseline JSON file (final fallback)
        if (-not $syncHash.Baselines -and (Test-Path $syncHash.BaselineConfigPath)) {
            try {
                Write-DebugOutput -Message "Loading baselines from local JSON file: $($syncHash.BaselineConfigPath)" -Source $source -Level "Verbose"
                $syncHash.Baselines = ((Get-Content -Path $syncHash.BaselineConfigPath -Raw) | ConvertFrom-Json).baselines
                Write-DebugOutput -Message "Successfully loaded baselines using: Local Baseline JSON File" -Source $source -Level "Info"
            }
            catch {
                Write-DebugOutput -Message "Failed to load baselines using Local Baseline JSON File: $($_.Exception.Message)" -Source $source -Level "Warning"
                $syncHash.Baselines = $null
            }
        }

        # Final error if all strategies failed
        if (-not $syncHash.Baselines) {
            Write-DebugOutput -Message "All baseline loading strategies failed. Unable to load baseline configuration." -Source $source -Level "Error"
            Write-Error "Failed to load baseline configuration. Please ensure Rego files and baseline markdown files are available."
        }

        # Add global event handlers to all UI controls after everything is loaded
        $syncHash.PreviewTab.IsEnabled = $false

        # Initialize debug toggle button
        If($syncHash.UIConfigs.DebugMode){
            $syncHash.DebugButton.Visibility = "Visible"
        }Else{
            $syncHash.DebugButton.Visibility = "Collapsed"
        }

        #override locale context
        foreach ($localeElement in $syncHash.UIConfigs.localeContext.PSObject.Properties) {
            $LocaleControl = $syncHash.($localeElement.Name)
            if ($LocaleControl){
                #get type of control
                switch($LocaleControl.GetType().Name) {
                    'TextBlock' {
                        $LocaleControl.Text = $localeElement.Value
                    }
                    'Button' {
                        $LocaleControl.Content = $localeElement.Value
                    }
                    'ComboBox' {
                        $LocaleControl.ToolTip = $localeElement.Value
                    }
                    'CheckBox' {
                        $LocaleControl.Content = $localeElement.Value
                    }
                    'Label' {
                        $LocaleControl.Content = $localeElement.Value
                    }
                }
            }
            Write-DebugOutput -Message "$($localeElement.Name): $($localeElement.Value)" -Source $source -Level "Info"

        }

        foreach ($env in $syncHash.UIConfigs.M365Environment) {
            $comboItem = New-Object System.Windows.Controls.ComboBoxItem
            $comboItem.Content = "$($env.displayName) ($($env.name))"
            $comboItem.Tag = $env.id

            $syncHash.M365Environment_ComboBox.Items.Add($comboItem)
            Write-DebugOutput -Message "M365Environment_ComboBox added: $($env.displayName) ($($env.name))" -Source $source -Level "Info"
        }

        Add-UIControlEventHandler -Control $syncHash.M365Environment_ComboBox

        # Set selection based on parameter or defa          ult to first item
        if ($syncHash.M365Environment) {
            $selectedEnv = $syncHash.M365Environment_ComboBox.Items | Where-Object { $_.Tag -eq $syncHash.M365Environment }
            if ($selectedEnv) {
                $syncHash.M365Environment_ComboBox.SelectedItem = $selectedEnv
            } else {
                # If the specified environment isn't found, default to first item
                $syncHash.M365Environment_ComboBox.SelectedIndex = 0
            }
        } else {
            # Set default selection to first item if no parameter specified
            $syncHash.M365Environment_ComboBox.SelectedIndex = 0
        }
        Write-DebugOutput -Message "M365Environment_ComboBox set: $($syncHash.M365Environment_ComboBox.SelectedItem.Content)" -Source $source -Level "Info"

        # Populate Products Checkbox dynamically within the ProductsGrid
        #only list three rows then use next column
        # Assume 3 rows, then wrap to next column
        $maxRows = 3
        for ($i = 0; $i -lt $syncHash.UIConfigs.products.Count; $i++) {
            $product = $syncHash.UIConfigs.products[$i]

            $checkBox = New-Object System.Windows.Controls.CheckBox
            $checkBox.Content = $product.displayName
            $checkBox.Name = ($product.id + "ProductCheckBox")
            $checkBox.Tag = $product.id
            $checkBox.Margin = "0,5"

            $row = $i % $maxRows
            $column = [math]::Floor($i / $maxRows)

            [System.Windows.Controls.Grid]::SetRow($checkBox, $row)
            [System.Windows.Controls.Grid]::SetColumn($checkBox, $column)

            [void]$syncHash.ProductsGrid.Children.Add($checkBox)

            # Add event handlers for checked/unchecked
            $checkBox.Add_Checked({
                $checkBox.IsEnabled = $false # Disable checkbox to prevent further changes during processing

                $productId = $this.Tag

                # Only update the data - let the timer handle UI updates
                if (-not $syncHash.GeneralSettingsData.ProductNames) {
                    $syncHash.GeneralSettingsData.ProductNames = @()
                }

                # Add to GeneralSettings if not already present
                if ($syncHash.GeneralSettingsData.ProductNames -notcontains $productId) {
                    # Force array type and add the new product
                    $syncHash.GeneralSettingsData.ProductNames = [System.Array]($syncHash.GeneralSettingsData.ProductNames + $productId.ToLower())
                    Write-DebugOutput -Message "Added '$productId 'to ProductNames data" -Source $source -Level "Info"
                }

                #loop through all policies controls tabs for this product
                Foreach($Policy in $syncHash.UIConfigs.baselineControls)
                {
                    $policytab = $syncHash.("$($Policy.controlType)Tab")
                    If($policytab) {
                        $policytab.IsEnabled = $true
                        Write-DebugOutput -Message "Enabled '$($Policy.controlType)Tab' for: $($productId)" -Source $source -Level "Info"
                    } else {
                        Write-DebugOutput -Message "No tab found for: $($Policy.controlType)Tab" -Source $source -Level "Verbose"
                    }

                    #enable sub tabs
                    $producttab = $syncHash.("$($productId)$($Policy.controlType)Tab")
                    If($producttab) {
                        $producttab.IsEnabled = $true
                        Write-DebugOutput -Message "Enabled '$($Policy.controlType)Tab' sub tab for: $($productId)" -Source $source -Level "Info"
                    } else {
                        Write-DebugOutput -Message "No sub tab found for: $($productId)$($Policy.controlType)Tab" -Source $source -Level "Verbose"
                    }

                    #enable content
                    $container = $syncHash.("$($productId)$($Policy.controlType)Content")
                    if ($container) {
                        New-ProductPolicyCards -ProductName $productId -Container $container -ControlType $Policy.controlType
                        Write-DebugOutput -Message "Enabled content container for: $($productId)$($Policy.controlType)Content" -Source $source -Level "Verbose"
                    } else {
                        Write-DebugOutput -Message "No content container found for: $($productId)$($Policy.controlType)Content" -Source $source -Level "Verbose"
                    }
                }
                # Re-enable the checkbox after processing
                $checkBox.IsEnabled = $true

            }.GetNewClosure())

            $checkBox.Add_Unchecked({
                $checkBox.IsEnabled = $false # Disable checkbox to prevent further changes during processing
                $productId = $this.Tag

                # Check minimum selection requirement
                $minimumRequired = if ($syncHash.UIConfigs.MinimumProductsRequired) { $syncHash.UIConfigs.MinimumProductsRequired } else { 1 }
                if ($syncHash.GeneralSettingsData.ProductNames -and ($syncHash.GeneralSettingsData.ProductNames.Count -eq $minimumRequired) -and $syncHash.GeneralSettingsData.ProductNames -contains $productId) {
                    # This is the last selected product - prevent unchecking
                    Write-DebugOutput -Message "Prevented unchecking last product: $productId (minimum $minimumRequired required)" -Source $source -Level "Error"
                    $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.localePopupMessages.ProductSelectionError -f $minimumRequired), "Minimum Selection Required", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

                    # Set the checkbox back to checked
                    $this.IsChecked = $true
                    return
                }

                # Remove from GeneralSettings
                if ($syncHash.GeneralSettingsData.ProductNames -contains $productId) {
                    # Filter out the product and ensure unique values
                    $syncHash.GeneralSettingsData.ProductNames = @($syncHash.GeneralSettingsData.ProductNames | Where-Object { $_ -ne $productId } | Sort-Object -Unique)
                    Write-DebugOutput -Message "Removed '$productId' from ProductNames data" -Source $source -Level "Info"
                }

                #loop through all policies controls for this product
                Foreach($Policy in $syncHash.UIConfigs.baselineControls)
                {
                    # Clear data for this product
                    if ($syncHash.($Policy.dataControlOutput).contains($productId)) {
                        $syncHash.($Policy.dataControlOutput).Remove($productId)
                        Write-DebugOutput -Message "Cleared data for: $productId in $($Policy.dataControlOutput)" -Source $source -Level "Info"
                    }

                    #disable and clear the Content
                    $producttab = $syncHash.("$($productId)$($Policy.controlType)Tab")
                    if ($producttab) {
                        $producttab.IsEnabled = $false
                        Write-DebugOutput -Message "Disabled '$($Policy.controlType)Tab' sub tab for: $($productId)" -Source $source -Level "Info"
                    } else {
                        Write-DebugOutput -Message "No sub tab found for: $($productId)$($Policy.controlType)Tab" -Source $source -Level "Verbose"
                    }

                    $container = $syncHash.("$($productId)$($Policy.controlType)Content")
                    if ($container) {
                        $container.Children.Clear()
                        Write-DebugOutput -Message "Cleared content container for: $($productId)$($Policy.controlType)Content" -Source $source -Level "Info"
                    } else {
                        Write-DebugOutput -Message "No content container found for: $($productId)$($Policy.controlType)Content" -Source $source -Level "Verbose"
                    }
                }
                # Re-enable the checkbox after processing
                $checkBox.IsEnabled = $true
            }.GetNewClosure())

        }
        $ExclusionSupport = $syncHash.UIConfigs.products | Where-Object { $_.supportsExclusions -eq $true } | Select-Object -ExpandProperty id
        $syncHash.ExclusionsInfo_TextBlock.Text = ($syncHash.UIConfigs.localeContext.ExclusionsInfo_TextBlock -f ($ExclusionSupport -join ', ').ToUpper())

        Foreach($product in $syncHash.UIConfigs.products) {
            # Initialize the OmissionTab and ExclusionTab for each product
            $exclusionTab = $syncHash.("$($product.id)ExclusionsTab")

            if ($product.supportsExclusions) {
                $exclusionTab.Visibility = "Visible"
                Write-DebugOutput -Message "Enabled Exclusion sub tab for: $($product.id)" -Source $source -Level "Info"
            }else{
                # Disable the Exclusions tab if the product does not support exclusions
                $exclusionTab.Visibility = "Collapsed"
                Write-DebugOutput -Message "Disabled Exclusion sub tab for: $($product.id)" -Source $source -Level "Info"
            }
        }


        # added events to all tab toggles
        $toggleControls = $syncHash.GetEnumerator() | Where-Object { $_.Name -like '*_Toggle' }
        foreach ($toggleName in $toggleControls) {
            $contentName = $toggleName.Name.Replace('_Toggle', '_Content')
            $contentControl = $syncHash[$contentName]

            # Add Checked event handler
            $syncHash[$toggleName.Name].Add_Checked({
                $contentControl.Visibility = "Visible"
            }.GetNewClosure())

            # Add Unchecked event handler
            $syncHash[$toggleName.Name].Add_Unchecked({
                $contentControl.Visibility = "Collapsed"
            }.GetNewClosure())
        }

        # Add event to placeholder TextBoxes
        foreach ($placeholderKey in $syncHash.UIConfigs.localePlaceholder.PSObject.Properties.Name) {
            $control = $syncHash.$placeholderKey
            if ($control -is [System.Windows.Controls.TextBox]) {
                $placeholderText = $syncHash.UIConfigs.localePlaceholder.$placeholderKey
                Initialize-PlaceholderTextBox -TextBox $control -PlaceholderText $placeholderText
            }
        }

        # Initialize Global Settings
        Write-DebugOutput -Message "Initializing Global Settings tab" -Source $source -Level "Info"
        New-GlobalSettingsControls

        # Handle Organization TextBox with special Graph Connected logic
        if ($syncHash.GraphConnected) {
            try {
                $tenantDetails = (Invoke-MgGraphRequest -Method GET -Uri "$($syncHash.GraphEndpoint)/v1.0/organization" -OutputType PSObject).Value
                $tenantName = ($tenantDetails.VerifiedDomains | Where-Object { $_.IsDefault -eq $true }).Name
                $syncHash.Organization_TextBox.Text = $tenantName
                $syncHash.Organization_TextBox.Foreground = [System.Windows.Media.Brushes]::Gray
                $syncHash.Organization_TextBox.FontStyle = [System.Windows.FontStyles]::Normal
                $syncHash.Organization_TextBox.BorderBrush = [System.Windows.Media.Brushes]::Gray
                $syncHash.Organization_TextBox.BorderThickness = "1"
                $syncHash.Organization_TextBox.isEnabled = $false # Disable editing if Graph is connected

                Add-GraphButton
            } catch {
                Write-DebugOutput -Message "Failed to retrieve organization details from Graph: $($_.Exception.Message)" -Source $source -Level "Error"
                $syncHash.GraphConnected = $false
                # Fallback to placeholder if Graph request fails
                Initialize-PlaceholderTextBox -TextBox $syncHash.Organization_TextBox -PlaceholderText $syncHash.UIConfigs.localePlaceholder.Organization_TextBox
            } finally {
                # Ensure Graph status indicator is initialized
                Initialize-GraphStatusIndicator
            }
        }

        Write-DebugOutput -Message "Initializing ToolTip Help" -Source $source -Level "Info"
        Initialize-ToolTipHelp

        # If YAMLImport is specified, load the YAML configuration
        # Process YAMLConfigFile parameter AFTER UI is fully initialized
        If($syncHash.ConfigImportPath){
            try {
                Write-DebugOutput -Message "Processing YAMLConfigFile parameter: $($syncHash.ConfigImportPath)" -Source $source -Level "Info"

                # Import with progress window
                $importSuccess = Invoke-YamlImportWithProgress -YamlFilePath $syncHash.ConfigImportPath -WindowTitle "Loading Configuration File"

                if ($importSuccess) {
                    Write-DebugOutput -Message "YAMLConfigFile processed successfully" -Source $source -Level "Info"
                } else {
                    Write-DebugOutput -Message "YAMLConfigFile processing failed" -Source $source -Level "Error"
                }
            }
            catch {
                Write-DebugOutput -Message "Error processing YAMLConfigFile: $($_.Exception.Message)" -Source $source -Level "Error"
                $syncHash.ShowMessageBox.Invoke("Error importing configuration file: $($_.Exception.Message)", "Import Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
        }

        If($syncHash.UIConfigs.AutoSaveProgress)
        {
            # Show prompt asking user what to do with previous session
            $userChoice = Show-AutoSaveRestorePrompt

            switch ($userChoice) {
                "restore" {
                    # User wants to restore now - will be done after window loads
                    $script:AutoSaveRestoreChoice = "restore"
                    Write-DebugOutput -Message "AutoSave restoration scheduled for after window load" -Source $source -Level "Info"
                }
                "remove" {
                    # User wants to remove previous session data
                    Remove-AutoSaveData
                    $script:AutoSaveRestoreChoice = "none"
                }
                "later" {
                    # User wants to restore later - keep files but don't restore now
                    $script:AutoSaveRestoreChoice = "later"
                    Write-DebugOutput -Message "AutoSave restoration deferred - user can restore later from menu" -Source $source -Level "Info"
                    # Show the Restore Session button so user can restore manually later
                    $script:ShowRestoreButton = $true
                }
                default {
                    # No previous session or error
                    $script:AutoSaveRestoreChoice = "none"
                }
            }
        }

        If($syncHash.UIConfigs.EnableScubaRun)
        {
            $syncHash.ScubaRunTab.Visibility = "Visible"
            # Initialize ScubaRun tab
            Write-DebugOutput -Message "Initializing ScubaRun tab" -Source $source -Level "Info"
            Initialize-ScubaRunTab

            If($syncHash.UIConfigs.EnableResultReader) {
                # Initialize Results tab
                Write-DebugOutput -Message "Initializing Results tab" -Source $source -Level "Info"
                $syncHash.ResultsTab.Visibility = "Visible"
                Initialize-ResultsTab
            }Else{
                $syncHash.ResultsTab.Visibility = "Collapsed"
            }
        }else {
            $syncHash.ScubaRunTab.Visibility = "Collapsed"
        }

        $syncHash.ScubaRunPowerShellVersion_TextBlock.Text = "PowerShell $($syncHash.UIConfigs.ScubaRunConfig.powershell.version) required"

        #===========================================================================
        # Button Event Handlers
        #===========================================================================
        $syncHash.ChangelogButton.Add_Click({
            Write-DebugOutput -Message "Changelog button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            Show-ChangelogWindow
        }.GetNewClosure())


        # add event handlers to all buttons
        # New Session Button
        $syncHash.NewSessionButton.Add_Click({
            Write-DebugOutput -Message "New Session button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            $result = $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localePopupMessages.NewSessionConfirmation, "New Session", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                # Reset all form fields
                Clear-FieldValue
            }
        })

        # Restore Session Button
        $syncHash.RestoreSessionButton.Add_Click({
            Write-DebugOutput -Message "Restore Session button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            try {
                Restore-AutoSaveWithProgress
                # Hide the button after successful restore
                $syncHash.RestoreSessionButton.Visibility = "Collapsed"
            } catch {
                Write-DebugOutput -Message "Error during manual session restore: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                $syncHash.ShowMessageBox.Invoke(
                    "An error occurred while restoring the session: $($_.Exception.Message)",
                    "Restore Error",
                    "OK",
                    "Error"
                )
            }
        })

        # Import Button
        $syncHash.ImportButton.Add_Click({
            Write-DebugOutput -Message "Import button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            $openFileDialog = New-Object Microsoft.Win32.OpenFileDialog
            $openFileDialog.Filter = "YAML Files (*.yaml;*.yml)|*.yaml;*.yml|All Files (*.*)|*.*"
            $openFileDialog.Title = "Import ScubaGear Configuration"

            if ($openFileDialog.ShowDialog() -eq $true) {
                try {
                    # Import with progress window
                    $importSuccess = Invoke-YamlImportWithProgress -YamlFilePath $openFileDialog.FileName -WindowTitle "Importing Configuration"

                    if ($importSuccess) {
                        $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localePopupMessages.ImportSuccess, "Import Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    }
                }
                catch {
                    $syncHash.ShowMessageBox.Invoke("Error importing configuration: $($_.Exception.Message)", "Import Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                }
            }
        })

        # Preview & Generate Button - Dynamic Validation Version
        $syncHash.PreviewButton.Add_Click({
            Write-DebugOutput -Message "Preview button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            $syncHash.Window.Dispatcher.Invoke([action]{

                # Perform dynamic validation based on requiredFields configuration
                $validationResults = Invoke-RequiredFieldValidation

                if (-not $validationResults.IsValid) {
                    # Disable preview tab
                    $syncHash.PreviewTab.IsEnabled = $false

                    # Navigate to the first tab with errors
                    Switch-FirstErrorTab -TabsToNavigate $validationResults.TabsToNavigate

                    # Format and show error messages
                    $formattedErrors = $validationResults.Errors | ForEach-Object { "`n - $_" }
                    $errorMessage = "The following validation errors occurred: $($formattedErrors -join '')"

                    Write-DebugOutput -Message "Validation failed with $($validationResults.Errors.Count) errors" -Source $MyInvocation.MyCommand -Level "Info"
                    $syncHash.ShowMessageBox.Invoke($errorMessage, "Validation Errors", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
                } else {
                    # All validations passed
                    $syncHash.PreviewTab.IsEnabled = $true

                    Write-DebugOutput -Message "All validations passed; generating preview" -Source $MyInvocation.MyCommand -Level "Info"

                    # Update settings data for each section
                    Set-SettingsDataForGeneralSection
                    Set-SettingsDataForAdvancedSection
                    Set-SettingsDataForGlobalSection

                    # Update UI elements
                    Update-UIFromSettingsData

                    # Generate YAML preview
                    New-YamlPreview

                    If($syncHash.UIConfigs.EnableScubaRun){
                        Test-ScubaRunReadiness
                    }
                }
            }) #end Dispatcher.Invoke
        })

        # Copy to Clipboard Button
        $syncHash.CopyYamlButton.Add_Click({
            Write-DebugOutput -Message "Copy to Clipboard button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            try {
                $syncHash.Window.Dispatcher.Invoke([Action]{
                    if (![string]::IsNullOrWhiteSpace($syncHash.YamlPreview_TextBox.Text)) {
                        [System.Windows.Clipboard]::SetText($syncHash.YamlPreview_TextBox.Text)
                        $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localePopupMessages.YamlClipboardComplete, "Copy Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    } else {
                        $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localePopupMessages.YamlClipboardNoPreview, "Nothing to Copy", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    }
                })
            }
            catch {
                # Even this must go in Dispatcher
                $syncHash.Window.Dispatcher.Invoke([Action]{
                    $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localePopupMessages.YamlClipboardError -f $_.Exception.Message, "Copy Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                })
            }
        })

        # Download YAML Button
        $syncHash.DownloadYamlButton.Add_Click({
            Write-DebugOutput -Message "Download YAML button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            try {
                if ([string]::IsNullOrWhiteSpace($syncHash.YamlPreview_TextBox.Text)) {
                    $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.DownloadNullError, "Nothing to Download", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
                    return
                }

                # Generate filename based on organization name
                $orgName = $syncHash.Organization_TextBox.Text
                if ([string]::IsNullOrWhiteSpace($orgName) -or $orgName -eq $syncHash.UIConfigs.localePlaceholder.Organization_TextBox) {
                    $dateFormat = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
                    $filename = "ScubaGear-Config-$dateFormat.yaml"
                } else {
                    # Remove any invalid filename characters and use organization name
                    $cleanOrgName = $orgName -replace '[\\/:*?"<>|]', '_'
                    $filename = "$cleanOrgName.yaml"
                }

                # Create SaveFileDialog
                $saveFileDialog = New-Object Microsoft.Win32.SaveFileDialog
                $saveFileDialog.Filter = "YAML Files (*.yaml)|*.yaml|All Files (*.*)|*.*"
                $saveFileDialog.Title = "Save ScubaGear Configuration"
                $saveFileDialog.FileName = $filename
                $saveFileDialog.DefaultExt = ".yaml"

                if ($saveFileDialog.ShowDialog() -eq $true) {
                    # Save the YAML content to file
                    $yamlContent = $syncHash.YamlPreview_TextBox.Text
                    [System.IO.File]::WriteAllText($saveFileDialog.FileName, $yamlContent, [System.Text.Encoding]::UTF8)

                    #$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                    #[System.IO.File]::WriteAllText($saveFileDialog.FileName, $yamlContent, $utf8NoBom)
                    #$yamlContent | Out-File -FilePath $saveFileDialog.FileName -Encoding utf8NoBOM

                    $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.localePopupMessages.YamlSaveSuccess -f $saveFileDialog.FileName), "Save Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                }
            }
            catch {
                $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.localePopupMessages.YamlSaveError -f $_.Exception.Message), "Save Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
        })

        # Add click event handler
        $syncHash.DebugButton.Add_Click({
            Write-DebugOutput -Message "Debug button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            try {
                if ($syncHash.DebugWindow -and $syncHash.DebugWindow.IsVisible -and -not $syncHash.DebugWindow.IsClosed) {
                    Hide-DebugWindow
                } else {
                    Show-DebugWindow
                }
            } catch {
                Write-DebugOutput -Message "Error toggling debug window: $($_.Exception.Message)" -Source $source -Level "Error"
                # Clear invalid window reference
                $syncHash.DebugWindow = $null
                $syncHash.DebugOutput_TextBox = $null
                $syncHash.DebugAutoScroll_CheckBox = $null
                $syncHash.DebugStatus_TextBlock = $null
                # Try to show window again
                Show-DebugWindow
            }
        })


        # Browse Output Path Button
        $syncHash.BrowseOutPathButton.Add_Click({
            Write-DebugOutput -Message "Browse Output Path button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderDialog.Description = "Select an output path"
            $folderDialog.ShowNewFolderButton = $true

            if ($syncHash.OutPath_TextBox.Text -ne "." -and (Test-Path $syncHash.OutPath_TextBox.Text)) {
                $folderDialog.SelectedPath = $syncHash.OutPath_TextBox.Text
            }

            $result = $folderDialog.ShowDialog()
            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                $syncHash.OutPath_TextBox.Text = $folderDialog.SelectedPath
                #New-YamlPreview
            }
        })

        # Browse OPA Path Button
        $syncHash.BrowseOpaPathButton.Add_Click({
            Write-DebugOutput -Message "Browse OPA Path button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderDialog.Description = "Select OPA Path"
            $folderDialog.ShowNewFolderButton = $true

            # Check if current textbox has a valid path, otherwise use ScubaGear default
            if ($syncHash.OpaPath_TextBox.Text -ne "." -and (Test-Path $syncHash.OpaPath_TextBox.Text)) {
                $folderDialog.SelectedPath = $syncHash.OpaPath_TextBox.Text
            } else {
                # Default to ScubaGear Tools directory
                $defaultOpaPath = Join-Path $env:UserProfile ".scubagear\Tools"
                $folderDialog.SelectedPath = $defaultOpaPath
            }

            $result = $folderDialog.ShowDialog()
            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                $syncHash.OpaPath_TextBox.Text = $folderDialog.SelectedPath
                #New-YamlPreview
            }
        })

        # Select Certificate Button
        $syncHash.SelectCertificateButton.Add_Click({
            Write-DebugOutput -Message "Select Certificate button clicked" -Source $MyInvocation.MyCommand -Level "Verbose"
            try {
                # Get user certificates with better error handling
                $userCerts = @()
                try {
                    $userCerts = Get-ChildItem -Path "Cert:\CurrentUser\My" -ErrorAction Stop | Where-Object {
                        $_.HasPrivateKey -and
                        $_.NotAfter -gt (Get-Date) -and
                        $_.Subject -notlike "*Microsoft*"
                    } | Sort-Object Subject
                }
                catch {
                    Write-DebugOutput -Message ("Error accessing certificate store: {0}" -f $_.Exception.Message) -Source $Source -Level "Error"
                    $syncHash.ShowMessageBox.Invoke(($syncHash.UIConfigs.localeErrorMessages.CertificateStoreAccessError -f $_.Exception.Message), "Certificate Store Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                    return
                }

                Write-DebugOutput -Message ("Found {0} certificates" -f $userCerts.Count) -Source $Source -Level "Verbose"

                if ($userCerts.Count -eq 0) {
                    $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.CertificateNotFound,
                                                    "No Certificates",
                                                    [System.Windows.MessageBoxButton]::OK,
                                                    [System.Windows.MessageBoxImage]::Information)
                    return
                }

                # Prepare data for display
                $displayCerts = $userCerts | ForEach-Object {
                    [PSCustomObject]@{
                        Subject = $_.Subject
                        Issuer = $_.Issuer
                        NotAfter = $_.NotAfter.ToString("yyyy-MM-dd")
                        Thumbprint = $_.Thumbprint
                        Certificate = $_
                    }
                } | Sort-Object Subject

                # Column configuration
                $columnConfig = [ordered]@{
                    Thumbprint = @{ Header = "Thumbprint"; Width = 120 }
                    Subject = @{ Header = "Subject"; Width = 250 }
                    Issuer = @{ Header = "Issued By"; Width = 200 }
                    NotAfter = @{ Header = "Expires"; Width = 100 }
                }

                # Show selector (single selection only for certificates)
                $selectedThumbprint = Show-UISelectionWindow `
                                    -WindowWidth 740 `
                                    -Title "Select a Certificate" `
                                    -SearchPlaceholder "Search by subject..." `
                                    -Items $displayCerts `
                                    -ColumnConfig $columnConfig `
                                    -DisplayOrder $columnConfig.Keys `
                                    -SearchProperty "Subject" `
                                    -ReturnProperty "Thumbprint"

                $syncHash.CertificateThumbprint_TextBox.Text = $selectedThumbprint
                $syncHash.CertificateThumbprint_TextBox.Foreground = [System.Windows.Media.Brushes]::Black
                $syncHash.CertificateThumbprint_TextBox.FontStyle = [System.Windows.FontStyles]::Normal
                Write-DebugOutput -Message ($syncHash.UIConfigs.localeInfoMessages.SelectedCertificateThumbprint -f $selectedThumbprint) -Source $Source -Level "Info"
            }
            catch {
                Write-DebugOutput -Message ($syncHash.UIConfigs.localeErrorMessages.CertificateSelectionError -f $_.Exception.Message) -Source $Source -Level "Error"
                $syncHash.ShowMessageBox.Invoke($syncHash.UIConfigs.localeErrorMessages.WindowError,
                                                "Error",
                                                [System.Windows.MessageBoxButton]::OK,
                                                [System.Windows.MessageBoxImage]::Error)

            }
        })

        #===========================================================================
        # Tab Change Event Handlers for AutoSave Settings
        #===========================================================================

        # Track the currently selected tab to determine when to save settings
        $script:PreviousTabName = $null

        # Add SelectionChanged event handler to MainTabControl for AutoSave functionality
        $syncHash.MainTabControl.Add_SelectionChanged({
            try {
                # Get the currently selected tab
                $selectedTab = $syncHash.MainTabControl.SelectedItem
                if (-not $selectedTab) { return }

                # Get the tab name
                $currentTabName = $selectedTab.Name

                # If we have a previous tab and AutoSave is enabled, save the settings for the previous tab
                if ($script:PreviousTabName -and (Test-AutoSaveEnabled)) {

                    # Use settingsControl configuration to map tab names to settings types
                    $settingsControl = $syncHash.UIConfigs.settingsControl

                    # Find the settings configuration for the previous tab
                    $tabConfig = $settingsControl.PSObject.Properties | Where-Object { $_.Name -eq $script:PreviousTabName }

                    if ($tabConfig -and $tabConfig.Value.dataControlOutput) {
                        $settingsType = $tabConfig.Value.dataControlOutput

                        Write-DebugOutput -Message "Tab changed from $script:PreviousTabName to $currentTabName, saving $settingsType" -Source $MyInvocation.MyCommand -Level "Verbose"
                        Save-AutoSaveSettings -SettingsType $settingsType
                    }
                }

                # Update the previous tab name for next time
                $script:PreviousTabName = $currentTabName

            } catch {
                Write-DebugOutput -Message "Error in tab change AutoSave handler: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }
        })

        Write-DebugOutput -Message "Tab change AutoSave event handlers initialized" -Source $source -Level "Info"

        If($syncHash.UIConfigs.EnableSearchAndFilter){

            # Initialize search and filter Functionality
            try {
                Show-SearchAndFilterControl
            } catch {
                Hide-SearchAndFilterControl
                Write-DebugOutput -Message "Failed to initialize search and filter: $($_.Exception.Message)" -Source $source -Level "Error"
            }

        }Else{
            #hide search and filter controls
            Hide-SearchAndFilterControl
            Write-DebugOutput -Message "Search and filter Functionality is disabled" -Source $source -Level "Info"
        }

        Write-DebugOutput -Message "UI initialization complete, starting main window" -Source $source -Level "Info"
        #=======================================
        # CLOSE UI
        #=======================================

        # Add Loaded event once
        $syncHash.Window.Add_Loaded({
            #once window loads, set to not be on top anymore
            $syncHash.Window.Topmost = $false
            $syncHash.isLoaded = $true

            # Restore AutoSave data after the window is fully loaded
            $syncHash.Window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [Action]{
                try {
                    # Check if user chose to restore during initialization
                    if ($script:AutoSaveRestoreChoice -eq "restore") {
                        Write-DebugOutput -Message "Starting AutoSave restoration with progress after window load" -Source $MyInvocation.MyCommand -Level "Info"

                        # Use the new progress-based restoration
                        Restore-AutoSaveWithProgress
                    } else {
                        Write-DebugOutput -Message "AutoSave restoration skipped - user choice: $script:AutoSaveRestoreChoice" -Source $MyInvocation.MyCommand -Level "Info"
                    }

                    # Show Restore Session button if user chose to restore later
                    if ($script:ShowRestoreButton -eq $true) {
                        $syncHash.RestoreSessionButton.Visibility = "Visible"
                        Write-DebugOutput -Message "Restore Session button made visible for later restoration" -Source $MyInvocation.MyCommand -Level "Info"
                    }

                } catch {
                    Write-DebugOutput -Message "Error during AutoSave restoration: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                }
            })

            <#
            # Initialize help popups after the window is fully loaded
            $syncHash.Window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [Action]{
                try {
                    Write-DebugOutput -Message "Initializing help popups after window load" -Source $MyInvocation.MyCommand -Level "Info"
                    Initialize-ToolTipHelp
                } catch {
                    Write-DebugOutput -Message "Error initializing help popups: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
                }
            })
            #>
        })

        # Closing event (calls Close-UIMainWindow only)
        # Events, UI setup here...
        $syncHash.Window.Add_Closing({
            # Show simple confirmation dialog
            $result = $syncHash.ShowMessageBox.Invoke(
                $syncHash.UIConfigs.localePopupMessages.CloseConfirmation,
                "Confirm Close",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )

            # If user clicked "No", cancel the close operation
            if ($result -eq [System.Windows.MessageBoxResult]::No) {
                $args[1].Cancel = $true
                return
            }

            # Save current tab settings before closing (if AutoSave is enabled)
            try {
                if ((Test-AutoSaveEnabled) -and $script:PreviousTabName) {
                    # Use settingsControl configuration to map tab names to settings types
                    $settingsControl = $syncHash.UIConfigs.settingsControl

                    # Find the settings configuration for the previous tab
                    $tabConfig = $settingsControl.PSObject.Properties | Where-Object { $_.Name -eq $script:PreviousTabName }

                    if ($tabConfig -and $tabConfig.Value.dataControlOutput) {
                        $settingsType = $tabConfig.Value.dataControlOutput
                        Write-DebugOutput -Message "Saving current tab settings before closing: $settingsType" -Source $MyInvocation.MyCommand -Level "Info"
                        Save-AutoSaveSettings -SettingsType $settingsType
                    }
                }
            } catch {
                Write-DebugOutput -Message "Error saving settings during window close: $($_.Exception.Message)" -Source $MyInvocation.MyCommand -Level "Error"
            }

            # Close debug window if open
            if ($syncHash.DebugWindow) {
                $syncHash.DebugWindow.Close()
            }

            # If user clicked "Yes", proceed with normal closing operations
            $syncHash.isClosing = $true

            # Disconnect safely
            if (Get-MgContext) {
                try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch {
                    Write-Error "Error disconnecting from Microsoft Graph: $($_.Exception.Message)"
                }
            }

            # Don't call .Close() here - it’s already in the closing state
            #$syncHash.Window.Close()

            $syncHash.isClosed = $true

            # Optional: GC can be triggered here, but keep it lightweight
            #[System.GC]::Collect()
        })
        # Closed event (final GC only)
        $syncHash.Window.Add_Closed({
            try {

                #Safe to release all memory
                [System.GC]::Collect()
                #[System.GC]::WaitForPendingFinalizers()
                #[System.GC]::Collect()
            } catch {
                Write-Error "Error during final cleanup: $($_.Exception.Message)"
            }
        })

        #always force windows on top first
        $syncHash.Window.Topmost = $True

        #hit esc to not force on top
        #hit esc again to force on top
        $syncHash.Window.Add_KeyDown({
            if ($_.Key -eq [System.Windows.Input.Key]::Escape) {
                if ($syncHash.Window.Topmost) {
                    Write-DebugOutput -Message "Escape key pressed - disabling always on top" -Source $source -Level "Info"
                } else {
                    Write-DebugOutput -Message "Escape key pressed - enabling always on top" -Source $source -Level "Info"
                }
                $syncHash.Window.Topmost = -not $syncHash.Window.Topmost
            }
        })

        #$syncHash.UIUpdateTimer.Start()

        $syncHash.Window.ShowDialog()
        $syncHash.Error = $Error
    }) # end scriptblock

    #collect data from runspace
    $Data = $syncHash
    #invoke scriptblock in runspace
    $PowerShellCommand.Runspace = $Runspace
    $AsyncHandle = $PowerShellCommand.BeginInvoke()

    # Wait for the runspace to complete (non-blocking if needed)
    $null = $PowerShellCommand.EndInvoke($AsyncHandle)

    # Now safe to clean up
    $Runspace.Close()
    $Runspace.Dispose()

    #show graph was disconnected if it was online
    if ($Data.GraphConnected -eq $true) {
        Write-Output "================================="
        Write-Output "Disconnected from Microsoft Graph"
    }
    if ($Data.Error.Count -eq 0) {
        Write-Output "ScubaConfigApp closed successfully with no errors"
    } else {
        Write-Output "ScubaConfigApp closed with $($Data.Error.Count) error(s)"
    }

    If($Passthru){
        return $Data
    }
}

Export-ModuleMember -Function @(
    'Start-SCuBAConfigApp'
)