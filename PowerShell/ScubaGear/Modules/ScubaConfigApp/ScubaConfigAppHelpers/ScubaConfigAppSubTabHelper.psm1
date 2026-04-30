Function Initialize-ProductSubTabs {
    <#
    .SYNOPSIS
    Dynamically creates product sub-tabs for Exclusions, Annotations, and Omissions tab controls.

    .DESCRIPTION
    Generates a TabItem, ScrollViewer, and StackPanel for each product/controlType combination
    defined in UIConfigs. Registers each control in syncHash using the conventional naming pattern
    ({ProductId}{ControlType}Tab / {ProductId}{ControlType}Content) so that existing checkbox
    event handlers can locate them without any additional changes.
    Exclusion tabs are collapsed for products that have supportsExclusions set to false.
    Adding a new product to UIConfigs.products automatically creates its sub-tabs in all three
    sections without requiring any XAML changes.
    #>
    $source = $MyInvocation.MyCommand
    Write-DebugOutput -Message "Initializing product sub-tabs dynamically" -Source $source -Level "Info"

    Foreach ($control in $syncHash.UIConfigs.baselineControls) {
        $tabControlName = "$($control.controlType)ProductTabControl"
        $tabControl     = $syncHash.$tabControlName

        if ($null -eq $tabControl) {
            Write-DebugOutput -Message "TabControl not found: $tabControlName" -Source $source -Level "Warning"
            continue
        }

        Foreach ($product in $syncHash.UIConfigs.products) {
            $tabName     = "$($product.id)$($control.controlType)Tab"
            $contentName = "$($product.id)$($control.controlType)Content"

            # StackPanel - content host, populated later when the product checkbox is selected
            $stackPanel      = New-Object System.Windows.Controls.StackPanel
            $stackPanel.Name = $contentName

            # ScrollViewer
            $scrollViewer                             = New-Object System.Windows.Controls.ScrollViewer
            $scrollViewer.VerticalScrollBarVisibility = "Auto"
            $scrollViewer.Margin                      = [System.Windows.Thickness]::new(0, 16, 0, 0)
            $scrollViewer.Style                       = $syncHash.Window.FindResource("ModernScrollViewer")
            $scrollViewer.Content                     = $stackPanel

            # TabItem - style is inherited from the TabControl.Resources implicit style
            $tabItem           = New-Object System.Windows.Controls.TabItem
            $tabItem.Header    = $product.id.ToUpper()
            $tabItem.IsEnabled = $false
            $tabItem.Content   = $scrollViewer

            # Exclusions: collapse tabs for products that don't support exclusions
            if ($control.controlType -eq "Exclusions" -and -not $product.supportsExclusions) {
                $tabItem.Visibility = "Collapsed"
                Write-DebugOutput -Message "Collapsed Exclusion sub tab (supportsExclusions=false): $($product.id)" -Source $source -Level "Info"
            }

            # Register in syncHash so existing event handlers resolve them by convention name
            $syncHash[$tabName]     = $tabItem
            $syncHash[$contentName] = $stackPanel

            [void]$tabControl.Items.Add($tabItem)
            Write-DebugOutput -Message "Created sub-tab: $tabName" -Source $source -Level "Verbose"
        }

        Write-DebugOutput -Message "Initialized $($tabControl.Items.Count) sub-tabs for: $tabControlName" -Source $source -Level "Info"
    }

    # Update the Exclusions info text block
    $ExclusionSupport = $syncHash.UIConfigs.products | Where-Object { $_.supportsExclusions -eq $true } | Select-Object -ExpandProperty id
    $syncHash.ExclusionsInfo_TextBlock.Text = ($syncHash.UIConfigs.localeContext.ExclusionsInfo_TextBlock -f ($ExclusionSupport -join ', ').ToUpper())
}
