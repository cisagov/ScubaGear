BeforeAll {
    Add-Type -AssemblyName PresentationFramework
    $moduleRoot = Join-Path $PSScriptRoot '..\..\..\..'
    $helperPath = Join-Path $moduleRoot 'Modules\ScubaConfigApp\ScubaBaselinePolicyViewerHelpers\ScubaBaselinePolicyViewerHelper.psm1'
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($helperPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        throw ($parseErrors.Message -join "`n")
    }
    # Exercise the actual runspace renderers without opening a viewer or fetching online data.
    foreach ($name in 'createTextBlockWithFormatting', 'processTextContent', 'processPreformattedText', 'processRegularText', 'getMatchingAppendices', 'updateNavigationDisplay') {
        $assignment = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                $node.Left.Extent.Text -eq ('$' + $name)
        }, $true)
        . ([scriptblock]::Create($assignment.Extent.Text))
    }
    function Get-RenderedText {
        param($Block)
        if ($Block -is [System.Windows.Controls.Border]) {
            return Get-RenderedText $Block.Child
        }
        $parts = foreach ($inline in $Block.Inlines) {
            if ($inline -is [System.Windows.Documents.Run]) {
                $inline.Text
            } elseif ($inline -is [System.Windows.Documents.Span]) {
                Get-RenderedText $inline
            } elseif ($inline -is [System.Windows.Documents.LineBreak]) {
                "`n"
            }
        }
        $parts -join ''
    }
    $script:controlConfig = Get-Content (Join-Path $moduleRoot 'Modules\ScubaConfigApp\ScubaBaselineViewer_Control_en-US.json') -Raw | ConvertFrom-Json
    $script:baseline = Get-Content (Join-Path $moduleRoot 'schemas\ScubaBaselines.json') -Raw | ConvertFrom-Json
    $selectionCall = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
            $node.Expression.Extent.Text -eq '$policySelector' -and
            $node.Member.Extent.Text -eq 'Add_SelectionChanged'
    }, $true)
    $script:selectionHandler = $selectionCall.Arguments[0].Expression.ScriptBlock.GetScriptBlock()
    $navigationStart = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$allPolicyData'
    }, $true).Extent.StartOffset
    $navigationEnd = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$getMatchingAppendices'
    }, $true).Extent.StartOffset
    $script:initializeNavigation = [scriptblock]::Create($ast.Extent.Text.Substring($navigationStart, $navigationEnd - $navigationStart))
    $filterCall = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
            $node.Expression.Extent.Text -eq '$filterTextBox' -and $node.Member.Extent.Text -eq 'Add_TextChanged'
    }, $true)
    $script:filterHandler = $filterCall.Arguments[0].Expression.ScriptBlock.GetScriptBlock()
    $script:navigationAssignments = foreach ($name in 'getMatchingAppendices', 'updateNavigationDisplay', 'navigateToAppendix') {
        $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                $node.Left.Extent.Text -eq ('$' + $name)
        }, $true).Extent.Text
    }
}

Describe 'Baseline viewer markdown rendering' {
    It 'renders nested bold text within a link without literal markers' {
        $block = & $createTextBlockWithFormatting '[configure the **Password expiration policy**](https://example.com)'
        Get-RenderedText $block | Should -Be 'configure the Password expiration policy'
        $block.Inlines.FirstInline -is [System.Windows.Documents.Hyperlink] | Should -BeTrue
        $block.Inlines.FirstInline.Inlines | Where-Object FontWeight -eq 'Bold' | Should -Not -BeNullOrEmpty
    }

    It 'renders a link inside italic text as a link' {
        $block = & $createTextBlockWithFormatting '_Adapted from [Microsoft Page](https://example.com)_'
        Get-RenderedText $block | Should -Be 'Adapted from Microsoft Page'
        @($block.Inlines.FirstInline.Inlines | Where-Object { $_ -is [System.Windows.Documents.Hyperlink] }).Count |
            Should -Be 1
    }

    It 'does not treat underscores inside identifiers as emphasis' {
        $block = & $createTextBlockWithFormatting '2147483647 (INT_MAX). Also INT_MIN.'
        Get-RenderedText $block | Should -Be '2147483647 (INT_MAX). Also INT_MIN.'
    }

    It 'does not linkify wildcard URLs inside inline code' {
        $block = & $createTextBlockWithFormatting '`https://*.safelinks.protection.outlook.com/?url=`'
        Get-RenderedText $block | Should -Be 'https://*.safelinks.protection.outlook.com/?url='
        @($block.Inlines | Where-Object { $_ -is [System.Windows.Documents.Hyperlink] }).Count | Should -Be 0
    }

    It 'keeps existing links intact and linkifies standalone URLs once' {
        $block = & $createTextBlockWithFormatting '[Microsoft](https://example.com) and https://example.org'
        Get-RenderedText $block | Should -Be 'Microsoft and https://example.org'
        @($block.Inlines | Where-Object { $_ -is [System.Windows.Documents.Hyperlink] }).Count | Should -Be 2
    }

    It 'does not nest hyperlinks when a link label is a URL' {
        $block = & $createTextBlockWithFormatting '[**https://example.com**](https://example.com)'
        Get-RenderedText $block | Should -Be 'https://example.com'
        $block.Inlines.FirstInline -is [System.Windows.Documents.Hyperlink] | Should -BeTrue
        $block.Inlines.FirstInline.Inlines.FirstInline.Inlines.FirstInline -is [System.Windows.Documents.Run] |
            Should -BeTrue
    }

    It 'joins source-wrapped link labels with a space' {
        $block = & $createTextBlockWithFormatting "[Power Platform admin`ncenter](https://example.com)"
        Get-RenderedText $block | Should -Be 'Power Platform admin center'
    }

    It 'unwraps terminology paragraphs but keeps paragraph boundaries' {
        $block = & $createTextBlockWithFormatting $baseline.keyTerminology
        $text = Get-RenderedText $block
        $text | Should -Match 'Microsoft Entra ID hybrid: This term denotes the scenario when an organization'
        $text | Should -Match 'tenant\.\r?\n\r?\nResource Tenant'
    }

    It 'keeps ordered steps and nested headings separate' {
        $block = & $createTextBlockWithFormatting "1. First`n2. Second`n`n##### Optional:`n`n7. Last"
        Get-RenderedText $block | Should -Be "1. First`n2. Second`n`nOptional:`n`n7. Last"
    }

    It 'keeps fenced code literal including comparison operators and underscores' {
        $block = & $createTextBlockWithFormatting @'
```powershell
$a = "INT_MAX"
if ($a -ne "<b>literal</b>") {
    $a
}
```
'@
        $code = $block.Inlines | Where-Object { $_ -is [System.Windows.Documents.InlineUIContainer] }
        $codeText = Get-RenderedText $code.Child.Child
        $codeText | Should -Match '<b>literal</b>'
        $codeText | Should -Match 'INT_MAX'
        $codeText | Should -Not -Match '```'
        ([regex]::Matches($codeText, 'INT_MAX')).Count | Should -Be 1
    }

    It 'preserves the Power BI blockquote text without quote markers' {
        $implementation = ($baseline.baselines.powerbi | Where-Object id -eq 'MS.POWERBI.3.1v1').implementation
        $block = & $createTextBlockWithFormatting $implementation
        Get-RenderedText $block | Should -Match 'You may need to make a specific security group'
        Get-RenderedText $block | Should -Not -Match '(?m)^>'
    }

    It 'renders HTML images as an image with accessible alternative text' {
        $imagePath = Join-Path $TestDrive 'baseline.png'
        [System.IO.File]::WriteAllBytes($imagePath, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aC1sAAAAASUVORK5CYII='))
        $block = & $createTextBlockWithFormatting ('<img src="' + $imagePath + '" alt="MFA methods" />')
        @($block.Inlines | Where-Object { $_ -is [System.Windows.Documents.InlineUIContainer] }).Count | Should -Be 1
        Get-RenderedText $block | Should -Match 'MFA methods'
        Get-RenderedText $block | Should -Not -Match '<img'
    }

    It 'maps policy notes into their own viewer section' {
        $controlConfig.policyViewerSettings.policyMarkdownMappings.notes.jsonProperty | Should -Contain 'notes'
    }
}

Describe 'Baseline viewer policy selection' {
    BeforeEach {
        $policyViewerSettings = $controlConfig.policyViewerSettings
        $dynamicContentPanels = @{}
        $dynamicExpanders = @{}
        foreach ($key in $policyViewerSettings.policyMarkdownMappings.PSObject.Properties.Name) {
            $dynamicContentPanels[$key] = New-Object System.Windows.Controls.StackPanel
            $dynamicExpanders[$key] = New-Object System.Windows.Controls.Expander
        }
        $script:badgesPanel = New-Object System.Windows.Controls.StackPanel
        $script:policyTitle = New-Object System.Windows.Controls.TextBlock
        $script:policyDescription = New-Object System.Windows.Controls.TextBlock
        $script:syncHash = @{ LoggingEnabled = $false }
        $script:updateExpanderHeadersAndVisibility = {}
        $script:sampleConfigExpander = $null
    }

    It 'renders resources for all 22 affected policies' {
        $singleResourcePolicies = @($baseline.baselines.PSObject.Properties.Value |
            ForEach-Object { $_ } | Where-Object { $_.resources.Count -eq 1 })
        $singleResourcePolicies.Count | Should -Be 22
        foreach ($policy in $singleResourcePolicies) {
            $script:policySelector = [pscustomobject]@{
                SelectedItem = [pscustomobject]@{ IsPolicy = $true; Policy = $policy }
            }
            & $selectionHandler
            $dynamicContentPanels.resources.Children.Count | Should -Be 1 -Because $policy.id
            Get-RenderedText $dynamicContentPanels.resources.Children[0] | Should -Not -Match 'No content available'
        }
    }

    It 'renders legacy singleton resource objects as links' {
        $script:policySelector = [pscustomobject]@{
            SelectedItem = [pscustomobject]@{
                IsPolicy = $true
                Policy = [pscustomobject]@{
                    id = 'MS.AAD.9.1v1'
                    name = 'Policy'
                    resources = [pscustomobject]@{ Name = 'Resource'; Url = 'https://example.com' }
                }
            }
        }
        & $selectionHandler
        Get-RenderedText $dynamicContentPanels.resources.Children[0] | Should -Match 'Resource'
        @($dynamicContentPanels.resources.Children[0].Inlines |
            Where-Object { $_ -is [System.Windows.Documents.Hyperlink] }).Count | Should -Be 1
    }

    It 'populates the Notes panel with nested policy guidance' {
        $script:policySelector = [pscustomobject]@{
            SelectedItem = [pscustomobject]@{
                IsPolicy = $true
                Policy = $baseline.baselines.securitysuite | Where-Object id -eq 'MS.SECURITYSUITE.3.5v1'
            }
        }
        & $selectionHandler
        $dynamicContentPanels.notes.Children.Count | Should -Be 1
        Get-RenderedText $dynamicContentPanels.notes.Children[0] |
            Should -Match 'This action can only be included if at least one device is onboarded'
    }

    It 'displays a selected appendix without showing policy metadata' {
        $script:productNames = @{ aad = 'Microsoft Entra ID' }
        $script:sampleConfigExpander = New-Object System.Windows.Controls.Expander
        $script:policySelector = [pscustomobject]@{
            SelectedItem = [pscustomobject]@{
                Type = 'Appendix'
                ProductKey = 'aad'
                Appendix = $baseline.appendices.aad[1]
            }
        }
        & $selectionHandler
        $policyTitle.Text | Should -Be 'Appendix B: Cross-tenant Access Guidance'
        $policyDescription.Text | Should -Be 'Microsoft Entra ID'
        $dynamicExpanders.implementation.Visibility | Should -Be 'Visible'
        $dynamicExpanders.implementation.IsExpanded | Should -BeTrue
        $sampleConfigExpander.Visibility | Should -Be 'Collapsed'
        $dynamicExpanders.notes.Visibility | Should -Be 'Collapsed'
        $dynamicExpanders.licenseRequirements.Visibility | Should -Be 'Collapsed'
        Get-RenderedText $dynamicContentPanels.implementation.Children[0] |
            Should -Match 'Some of the conditional access policies'
        $badgesPanel.Children.Count | Should -Be 0
    }

    It 'shows the shared introduction and other common sections on launch' {
        $script:jsonData = $baseline
        $script:sampleConfigExpander = $null
        foreach ($name in 'updateExpanderHeadersAndVisibility', 'showDefaultContent') {
            $assignment = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                    $node.Left.Extent.Text -eq ('$' + $name)
            }, $true)
            . ([scriptblock]::Create(($assignment.Extent.Text -replace '\.GetNewClosure\(\)$', '')))
        }
        & $showDefaultContent
        $policyTitle.Text | Should -Be $policyViewerSettings.defaultContentHeaders.title
        $dynamicExpanders.rationale.Header | Should -Be 'Introduction'
        $dynamicExpanders.rationale.Visibility | Should -Be 'Visible'
        $paragraphs = @($dynamicContentPanels.rationale.Children | ForEach-Object { Get-RenderedText $_ })
        $paragraphs.Count | Should -Be 4
        $paragraphs[0] | Should -Match "^The Cybersecurity and Infrastructure Security Agency's"
        $paragraphs[1] | Should -Match '^The CISA SCuBA SCBs for M365'
        $paragraphs[2] | Should -Match '^For non-federal users'
        $paragraphs[3] | Should -Match 'This document is marked TLP:CLEAR'
        foreach ($key in 'implementation', 'licenseRequirements', 'resources') {
            $dynamicExpanders[$key].Visibility | Should -Be 'Visible'
            $dynamicContentPanels[$key].Children.Count | Should -BeGreaterThan 0
        }
        $dynamicExpanders.notes.Visibility | Should -Be 'Collapsed'
    }
}

Describe 'Baseline viewer appendix navigation' {
    BeforeEach {
        $script:jsonData = $baseline
        $script:productNames = @{ aad = 'Microsoft Entra ID'; securitysuite = 'Security Suite'; teams = 'Microsoft Teams' }
        $script:allowedProductIds = @{}
        . $initializeNavigation
        $policySelector = New-Object System.Windows.Controls.ListBox
        $filterTextBox = New-Object System.Windows.Controls.TextBox
        $criticalityFilter = New-Object System.Windows.Controls.ComboBox
        $script:policySelector = $policySelector
        $script:filterTextBox = $filterTextBox
        $script:criticalityFilter = $criticalityFilter
        foreach ($assignment in $navigationAssignments) {
            . ([scriptblock]::Create($assignment))
        }
    }

    It 'appends appendix entries after policies without changing policy counts' {
        foreach ($header in $navigationItems) { $header.IsExpanded = $true }
        & $updateNavigationDisplay
        @($policySelector.Items | Where-Object Type -eq 'Policy').Count | Should -Be 109
        @($policySelector.Items | Where-Object Type -eq 'Appendix').Count | Should -Be 5
        $aadItems = @($policySelector.Items | Where-Object ProductKey -eq 'aad')
        $aadItems[-2].Appendix.name | Should -Be $baseline.appendices.aad[0].name
        $aadItems[-1].Appendix.name | Should -Be $baseline.appendices.aad[1].name
        $aadItems[0].DisplayText | Should -Be "Microsoft Entra ID ($($baseline.baselines.aad.Count))"
    }

    It 'searches appendix text and expands matching products' {
        $filterTextBox = New-Object System.Windows.Controls.TextBox
        $filterTextBox.Text = 'hybrid identity solutions'
        $script:criticalityFilter = [pscustomobject]@{ SelectedItem = [pscustomobject]@{ Tag = 'all' } }
        $script:placeholderText = New-Object System.Windows.Controls.TextBlock
        $clearFilterButton = New-Object System.Windows.Controls.Button
        & $filterHandler
        $entries = @($policySelector.Items | Where-Object Type -eq 'Appendix')
        $entries.Count | Should -Be 1
        $entries[0].Appendix.name | Should -Be $baseline.appendices.aad[0].name
        $clearFilterButton.Visibility | Should -Be 'Visible'
    }

    It 'excludes appendices from criticality-filtered policy results' {
        foreach ($header in $navigationItems) { $header.IsExpanded = $true }
        & $updateNavigationDisplay '' 'shall'
        @($policySelector.Items | Where-Object Type -eq 'Appendix').Count | Should -Be 0
        @($policySelector.Items | Where-Object Type -eq 'Policy').Count | Should -BeGreaterThan 0
    }

    It 'supports older baseline JSON with no appendices' {
        $script:jsonData = [pscustomobject]@{ baselines = $baseline.baselines }
        . $initializeNavigation
        foreach ($header in $navigationItems) { $header.IsExpanded = $true }
        & $updateNavigationDisplay
        @($policySelector.Items | Where-Object Type -eq 'Policy').Count | Should -Be 109
        @($policySelector.Items | Where-Object Type -eq 'Appendix').Count | Should -Be 0
    }

    It 'navigates a policy appendix link to its product appendix entry' {
        foreach ($header in $navigationItems) { $header.IsExpanded = $true }
        & $updateNavigationDisplay
        $policySelector.SelectedItem = $policySelector.Items | Where-Object {
            $_.Type -eq 'Policy' -and $_.Policy.id -eq 'MS.SECURITYSUITE.1.1v1'
        } | Select-Object -First 1
        $block = & $createTextBlockWithFormatting '[Adding Users](#appendix-a-adding-users-to-the-preset-security-policies)'
        $navigateEvent = [System.Windows.Navigation.RequestNavigateEventArgs]::new(
            [uri]'#appendix-a-adding-users-to-the-preset-security-policies', '')
        $navigateEvent.RoutedEvent = [System.Windows.Documents.Hyperlink]::RequestNavigateEvent
        $block.Inlines.FirstInline.RaiseEvent($navigateEvent)
        $navigateEvent.Handled | Should -BeTrue
        $policySelector.SelectedItem.Type | Should -Be 'Appendix'
        $policySelector.SelectedItem.ProductKey | Should -Be 'securitysuite'
    }
}
