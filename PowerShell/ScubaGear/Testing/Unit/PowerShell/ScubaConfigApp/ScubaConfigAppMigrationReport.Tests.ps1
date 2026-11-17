Describe 'Config App migration reporting and optional viewer buttons' {
    BeforeAll {
        $root = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $app = Join-Path $root 'Modules\ScubaConfigApp'
        Import-Module "$app\ScubaConfigAppHelpers\ScubaConfigAppImportHelper.psm1" -Force
        $script:config = (Get-Content "$app\ScubaConfigApp_Control_en-US.json" -Raw | ConvertFrom-Json).policyMigration
        $script:arrow = [char]0x2192
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            "$app\ScubaConfigAppHelpers\ScubaConfigAppDynamicCardHelper.psm1",
            [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) { throw ($parseErrors -join "`n") }
        $buttonGuard = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.IfStatementAst] -and
            $node.Extent.Text -match '^\s*if\s*\(\$showBaselineButton' -and
            $node.Extent.Text.Contains('$buttonPanel.Children.Add($baselinePolicyButton)')
        }, $true)
        $script:addViewerButton = [scriptblock]::Create($buttonGuard.Extent.Text)
    }

    It 'shows a successful migration mapping between the intro and outro' {
        $text = Format-PolicyMigrationReport -MigrationLog @("MIGRATED exclusion [Aad][MS.AAD.3.2v1] $arrow [Aad][MS.AAD.3.2v2]") -MigrationConfig $config
        $text | Should -Match 'contained 1 legacy policy setting'
        $text | Should -Match 'MS.AAD.3.2v1.*MS.AAD.3.2v2'
        $text | Should -Match 'Please review the updated settings before saving'
    }

    It 'shows a mapping and retention warning when the target already exists' {
        $text = Format-PolicyMigrationReport -MigrationLog @("SKIPPED exclusion [Aad][MS.AAD.3.2v1] $arrow [Aad][MS.AAD.3.2v2] (target already configured)") -MigrationConfig $config
        $text | Should -Match 'MS.AAD.3.2v1.*MS.AAD.3.2v2'
        $text | Should -Match 'Existing target settings were retained'
        $text | Should -Match 'legacy values were not merged'
    }

    It 'renders all JSON-defined outcome types, including a future type' {
        $reportConfig = $config | ConvertTo-Json -Depth 20 | ConvertFrom-Json
        $reportConfig.localeReportWindow.sections | Add-Member -NotePropertyName future `
            -NotePropertyValue ([pscustomobject]@{ prefix = 'FUTURE'; heading = 'Future outcome ({0})' })
        $log = @('MIGRATED one', 'DECOUPLED two', 'DROPPED three', 'SKIPPED four', 'FUTURE five', 'UNKNOWN six')
        $text = Format-PolicyMigrationReport -MigrationLog $log -MigrationConfig $reportConfig
        foreach ($entry in $log) { $text | Should -Match ([regex]::Escape($entry)) }
        $text | Should -Match 'contained 6 legacy policy setting'
        $text | Should -Match 'Future outcome \(1\)'
    }

    It 'limits section details according to JSON metadata' {
        $reportConfig = $config | ConvertTo-Json -Depth 20 | ConvertFrom-Json
        $reportConfig.reportMaxLinesPerSection = 1
        $text = Format-PolicyMigrationReport -MigrationLog @('MIGRATED first', 'MIGRATED second') -MigrationConfig $reportConfig
        $text | Should -Match 'MIGRATED first'
        $text | Should -Not -Match 'MIGRATED second'
        $text | Should -Match 'and 1 more'
    }

    It 'adds the optional baseline button only when enabled and non-null' -ForEach @(
        @{ Enabled = $true; HasButton = $false; Expected = 0 }
        @{ Enabled = $false; HasButton = $true; Expected = 0 }
        @{ Enabled = $true; HasButton = $true; Expected = 1 }
    ) {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'showBaselineButton')]
        $showBaselineButton = $Enabled
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'baselinePolicyButton')]
        $baselinePolicyButton = if ($HasButton) { [pscustomobject]@{ Content = 'View Baseline Policies' } } else { $null }
        $buttonPanel = [pscustomobject]@{ Children = [System.Collections.Generic.List[object]]::new() }
        & $addViewerButton
        $buttonPanel.Children.Count | Should -Be $Expected
    }
}
