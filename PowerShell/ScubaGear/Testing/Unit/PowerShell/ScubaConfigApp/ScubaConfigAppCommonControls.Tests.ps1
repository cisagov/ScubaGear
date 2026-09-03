Describe -tag "Config" -name 'ScubaConfigApp Common Controls (Analyzer + Baseline Viewer)' {
    BeforeAll {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'moduleRoot')]
        $moduleRoot = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp"
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'appControlPath')]
        $appControlPath = Join-Path $moduleRoot 'ScubaConfigApp_Control_en-US.json'
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'analyzerControlPath')]
        $analyzerControlPath = Join-Path $moduleRoot 'ScubaConfigAnalyzer_Control_en-US.json'
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'viewerControlPath')]
        $viewerControlPath = Join-Path $moduleRoot 'ScubaBaselineViewer_Control_en-US.json'
    }

    Context 'ScubaBaselineViewer_Control_en-US.json' {
        It 'exists at the module root (next to the other *_Control_*.json files)' {
            Test-Path $viewerControlPath | Should -BeTrue -Because 'the viewer control is a peer of the app and analyzer controls'
        }

        It 'is valid, parseable JSON' {
            { Get-Content $viewerControlPath -Raw | ConvertFrom-Json } | Should -Not -Throw -Because 'the viewer control must be readable at launch'
        }

        It 'has a products array where each entry has id, name, and showInViewer' {
            $viewerControl = Get-Content $viewerControlPath -Raw | ConvertFrom-Json
            $products = @($viewerControl.products)
            $products.Count | Should -BeGreaterThan 0 -Because 'the viewer needs at least one product to list'
            foreach ($product in $products) {
                $product.PSObject.Properties.Name | Should -Contain 'id'
                $product.PSObject.Properties.Name | Should -Contain 'name'
                $product.PSObject.Properties.Name | Should -Contain 'showInViewer'
            }
        }

        It 'has policyViewerSettings with its required sub-sections' {
            $viewerControl = Get-Content $viewerControlPath -Raw | ConvertFrom-Json
            $viewerControl.policyViewerSettings | Should -Not -BeNullOrEmpty
            foreach ($section in @('windowHeader', 'defaultContentHeaders', 'mainMarkdownMappings', 'policyMarkdownMappings')) {
                $viewerControl.policyViewerSettings.PSObject.Properties.Name | Should -Contain $section -Because "policyViewerSettings must define '$section'"
            }
        }
    }

    Context 'ScubaConfigApp_Control_en-US.json (viewer config moved out)' {
        It 'no longer contains a policyViewerSettings block' {
            $appControl = Get-Content $appControlPath -Raw | ConvertFrom-Json
            $appControl.PSObject.Properties.Name | Should -Not -Contain 'policyViewerSettings' -Because 'it moved to ScubaBaselineViewer_Control_en-US.json'
        }

        It 'products no longer carry a showInViewer field' {
            $appControl = Get-Content $appControlPath -Raw | ConvertFrom-Json
            foreach ($product in @($appControl.products)) {
                $product.PSObject.Properties.Name | Should -Not -Contain 'showInViewer' -Because 'showInViewer is now defined in the viewer control'
            }
        }

        It 'has a boolean EnablePolicyViewer flag (gates the per-policy viewer button)' {
            $appControl = Get-Content $appControlPath -Raw | ConvertFrom-Json
            $appControl.PSObject.Properties.Name | Should -Contain 'EnablePolicyViewer'
            $appControl.EnablePolicyViewer | Should -BeOfType [System.Boolean]
        }

        It 'has a boolean PullOnlineBaselines flag (shared by app + viewer)' {
            $appControl = Get-Content $appControlPath -Raw | ConvertFrom-Json
            $appControl.PSObject.Properties.Name | Should -Contain 'PullOnlineBaselines'
            $appControl.PullOnlineBaselines | Should -BeOfType [System.Boolean]
        }
    }

    Context 'ScubaConfigAnalyzer_Control_en-US.json online-baseline dev toggle' {
        It 'is valid, parseable JSON' {
            { Get-Content $analyzerControlPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'has an independent boolean PullOnlineBaselines flag' {
            $analyzerControl = Get-Content $analyzerControlPath -Raw | ConvertFrom-Json
            $analyzerControl.PSObject.Properties.Name | Should -Contain 'PullOnlineBaselines'
            $analyzerControl.PullOnlineBaselines | Should -BeOfType [System.Boolean]
        }

        It 'defines OnlineBaselineSchemaURL and OnlineApiCatalogURL as http(s) URLs' {
            $analyzerControl = Get-Content $analyzerControlPath -Raw | ConvertFrom-Json
            $analyzerControl.OnlineBaselineSchemaURL | Should -Match '^https?://'
            $analyzerControl.OnlineApiCatalogURL | Should -Match '^https?://'
        }

        It 'still defines the local schema path keys' {
            $analyzerControl = Get-Content $analyzerControlPath -Raw | ConvertFrom-Json
            foreach ($key in @('BaselineSchemaPath', 'ApiCatalogPath', 'ConfigSchemaPath')) {
                $analyzerControl.PSObject.Properties.Name | Should -Contain $key
            }
        }
    }
}

Describe -tag "Helpers" -name 'Baseline Policy Viewer helper (app-independent)' {
    BeforeAll {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'moduleRoot')]
        $moduleRoot = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp"
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'viewerHelperPath')]
        $viewerHelperPath = Join-Path $moduleRoot 'ScubaBaselinePolicyViewerHelpers\ScubaBaselinePolicyViewerHelper.psm1'
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'viewerXamlPath')]
        $viewerXamlPath = Join-Path $moduleRoot 'ScubaConfigAppResources\ScubaBaselinePolicyViewerUI.xaml'
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'oldHelperPath')]
        $oldHelperPath = Join-Path $moduleRoot 'ScubaConfigAppHelpers\ScubaConfigAppBaselineUIViewerHelper.psm1'
    }

    Context 'Module relocation' {
        It 'lives in its own ScubaBaselinePolicyViewerHelpers folder' {
            Test-Path $viewerHelperPath | Should -BeTrue
        }

        It 'no longer lives under ScubaConfigAppHelpers' {
            Test-Path $oldHelperPath | Should -BeFalse -Because 'the module was moved to make the viewer app-independent'
        }

        It 'has valid PowerShell syntax' {
            {
                $tokens = $null
                $errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($viewerHelperPath, [ref]$tokens, [ref]$errors)
                if ($errors.Count -gt 0) { throw "Parse errors: $($errors -join '; ')" }
            } | Should -Not -Throw
        }

        It 'exports Show-ScubaBaselinePolicyHelper and Test-BaselineViewerStatus' {
            $module = Import-Module $viewerHelperPath -Force -PassThru
            try {
                $module.ExportedCommands.Keys | Should -Contain 'Show-ScubaBaselinePolicyHelper'
                $module.ExportedCommands.Keys | Should -Contain 'Test-BaselineViewerStatus'
            } finally {
                Remove-Module $module -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Externalized XAML' {
        It 'ScubaBaselinePolicyViewerUI.xaml exists and is well-formed XML' {
            Test-Path $viewerXamlPath | Should -BeTrue
            { [xml](Get-Content $viewerXamlPath -Raw) } | Should -Not -Throw
        }
    }
}
