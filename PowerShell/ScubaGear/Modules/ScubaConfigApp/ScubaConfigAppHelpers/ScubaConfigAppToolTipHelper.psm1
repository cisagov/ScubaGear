# Consolidated popup function that handles both simple and rich popups
Function Add-ToolTipHoverPopup {
    <#
    .SYNOPSIS
    Adds a hover popup to a control.

    .DESCRIPTION
    This function creates a hover popup for a specified control, allowing for additional information to be displayed when the user hovers over the control.

    .PARAMETER Control
    The control to attach the hover popup to.

    .PARAMETER Title
    The title of the hover popup.

    .PARAMETER Content
    The content to display in the hover popup.

    .PARAMETER Placement
    The placement of the hover popup relative to the control.

    .PARAMETER AdditionalSections
    Any additional sections to include in the hover popup.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Controls.Control]$Control,
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
        [string]$Content,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Left", "Right", "Top", "Bottom")]
        [string]$Placement = "Right",
        [hashtable]$AdditionalSections = @{}
    )

    # Create the popup
    $popup = New-Object System.Windows.Controls.Primitives.Popup
    $popup.PlacementTarget = $Control
    $popup.Placement = [System.Windows.Controls.Primitives.PlacementMode]::$Placement
    $popup.StaysOpen = $false
    $popup.AllowsTransparency = $true

    # Create popup border
    $popupBorder = New-Object System.Windows.Controls.Border
    $popupBorder.Background = [System.Windows.Media.Brushes]::White
    $popupBorder.BorderBrush = [System.Windows.Media.Brushes]::Gray
    $popupBorder.BorderThickness = "1"
    $popupBorder.CornerRadius = "4"
    $popupBorder.Padding = "10"
    $popupBorder.MaxWidth = if ($AdditionalSections.Count -gt 0) { 350 } else { 300 }

    # Add shadow effect
    $dropShadow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $dropShadow.Color = [System.Windows.Media.Colors]::Gray
    $dropShadow.Direction = 315
    $dropShadow.ShadowDepth = 2
    $dropShadow.Opacity = 0.5
    $popupBorder.Effect = $dropShadow

    # Choose content type based on whether we have additional sections
    if ($AdditionalSections.Count -gt 0) {
        # Use FlowDocument for rich content
        $flowDocViewer = New-Object System.Windows.Controls.FlowDocumentScrollViewer
        $flowDocViewer.VerticalScrollBarVisibility = "Auto"
        $flowDocViewer.HorizontalScrollBarVisibility = "Hidden"
        $flowDocViewer.IsToolBarVisible = $false
        $popupBorder.MaxHeight = 200

        # Create FlowDocument
        $flowDoc = New-Object System.Windows.Documents.FlowDocument
        $flowDoc.FontFamily = "Segoe UI"
        $flowDoc.FontSize = 12

        # Title paragraph
        $titleParagraph = New-Object System.Windows.Documents.Paragraph
        $titleParagraph.Margin = "0,0,0,8"
        $titleRun = New-Object System.Windows.Documents.Run
        $titleRun.Text = $Title
        $titleRun.FontWeight = "Bold"
        $titleRun.FontSize = 14
        $titleRun.Foreground = $syncHash.Window.FindResource("PrimaryBrush")
        $titleParagraph.AddChild($titleRun)
        $flowDoc.AddChild($titleParagraph)

        # Content paragraph
        $contentParagraph = New-Object System.Windows.Documents.Paragraph
        $contentParagraph.Margin = "0,0,0,8"
        $contentRun = New-Object System.Windows.Documents.Run
        $contentRun.Text = $Content
        $contentParagraph.AddChild($contentRun)
        $flowDoc.AddChild($contentParagraph)

        # Additional sections
        foreach ($sectionTitle in $AdditionalSections.Keys) {
            $sectionParagraph = New-Object System.Windows.Documents.Paragraph
            $sectionParagraph.Margin = "0,4,0,4"

            # Section title
            $sectionTitleRun = New-Object System.Windows.Documents.Run
            $sectionTitleRun.Text = "$sectionTitle`: "
            $sectionTitleRun.FontWeight = "Bold"
            $sectionParagraph.AddChild($sectionTitleRun)

            # Section content
            $sectionContentRun = New-Object System.Windows.Documents.Run
            $sectionContentRun.Text = $AdditionalSections[$sectionTitle]
            $sectionParagraph.AddChild($sectionContentRun)

            $flowDoc.AddChild($sectionParagraph)
        }

        $flowDocViewer.Document = $flowDoc
        $popupBorder.Child = $flowDocViewer
    } else {
        # Use simple StackPanel for basic content
        $contentStack = New-Object System.Windows.Controls.StackPanel

        # Title
        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = $Title
        $titleBlock.FontWeight = "Bold"
        $titleBlock.FontSize = 14
        $titleBlock.Foreground = $syncHash.Window.FindResource("PrimaryBrush")
        $titleBlock.Margin = "0,0,0,8"
        [void]$contentStack.Children.Add($titleBlock)

        # Content
        $contentBlock = New-Object System.Windows.Controls.TextBlock
        $contentBlock.Text = $Content
        $contentBlock.FontSize = 12
        $contentBlock.TextWrapping = "Wrap"
        $contentBlock.Foreground = $syncHash.Window.FindResource("TextBrush")
        [void]$contentStack.Children.Add($contentBlock)

        $popupBorder.Child = $contentStack
    }

    $popup.Child = $popupBorder

    # Add mouse events to both the control AND the popup
    $Control.Add_MouseEnter({
        $popup.IsOpen = $true
    }.GetNewClosure())

    $Control.Add_MouseLeave({
        # Only close if mouse is not over the popup
        if (-not $popup.IsMouseOver) {
            $popup.IsOpen = $false
        }
    }.GetNewClosure())

    # Add popup mouse events to prevent flickering
    $popup.Add_MouseEnter({
        $popup.IsOpen = $true
    }.GetNewClosure())

    $popup.Add_MouseLeave({
        $popup.IsOpen = $false
    }.GetNewClosure())
    return $popup
}

Function Initialize-ToolTipHelp {
    <#
    .SYNOPSIS
    Automatically adds hover popups to all HelpLabel controls in the UI.
    .DESCRIPTION
    This function scans the UI for controls with names ending in "HelpLabel" and adds hover popups with content from the localeHelpTips configuration.
    #>

    Write-DebugOutput -Message "Starting dynamic help popup initialization" -Source $MyInvocation.MyCommand -Level "Info"

    # Find all controls with names ending in "HelpLabel"
    $helpLabels = $syncHash.GetEnumerator() | Where-Object {
        $_.Key -like "*HelpLabel" -and $_.Value -is [System.Windows.Controls.Label]
    }

    Write-DebugOutput -Message "Found $($helpLabels.Count) HelpLabel controls" -Source $MyInvocation.MyCommand -Level "Verbose"

    foreach ($helpLabel in $helpLabels) {
        $controlName = $helpLabel.Key
        $control = $helpLabel.Value

        Write-DebugOutput -Message "Processing help label: $controlName" -Source $MyInvocation.MyCommand -Level "Verbose"

        # Check if help tip configuration exists in localeHelpTips
        if ($syncHash.UIConfigs.localeHelpTips.PSObject.Properties.Name -contains $controlName) {
            $helpData = $syncHash.UIConfigs.localeHelpTips.$controlName

            # Use Title from config if available, otherwise generate from control name
            $title = $helpData.Title

            # Get content
            $content = $helpData.Content

            $Params = @{
                Control = $control
                Title = $title
                Content = $content
            }

            # Check for additional sections to determine popup type
            if ($helpData.AdditionalSections) {
                # Convert PSCustomObject to hashtable
                $additionalSectionsHashtable = [ordered]@{}
                foreach ($property in $helpData.AdditionalSections.PSObject.Properties) {
                    $additionalSectionsHashtable[$property.Name] = $property.Value
                }
                $Params.Add("AdditionalSections", $additionalSectionsHashtable)
            }

            If($helpData.Placement) {
                $Params.Add("Placement", $helpData.Placement)
            }

            # Add the hover popup to the control
            Add-ToolTipHoverPopup @Params

            Write-DebugOutput -Message "Added hover popup to: $controlName" -Source $MyInvocation.MyCommand -Level "Info"
        } else {
            Write-DebugOutput -Message "No help tip configuration found for: $controlName in localeHelpTips" -Source $MyInvocation.MyCommand -Level "Verbose"
        }
    }

    Write-DebugOutput -Message "Help popup initialization completed" -Source $MyInvocation.MyCommand -Level "Info"
}

