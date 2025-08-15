Describe -tag "Helpers" -name 'ScubaConfigApp Helper Modules Validation' {
    BeforeAll {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'helpersPath')]
        $helpersPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigAppHelpers"
    }

    Context 'Helper Module Files Existence' {
        It 'Should have all required helper module files' {
            $expectedHelpers = @(
                'ScubaConfigAppDebugHelper.psm1',
                'ScubaConfigAppResultsHelper.psm1',
                'ScubaConfigAppChangeLogHelper.psm1',
                'ScubaConfigAppScubaRunHelper.psm1',
                'ScubaConfigAppDynamicCardHelper.psm1',
                'ScubaConfigAppResetHelper.psm1',
                'ScubaConfigAppBaselineHelper.psm1',
                'ScubaConfigAppGlobalSettingsHelper.psm1',
                'ScubaConfigAppGraphHelper.psm1',
                'ScubaConfigAppImportHelper.psm1',
                'ScubaConfigAppSettingsDataHelper.psm1',
                'ScubaConfigAppProductHelper.psm1',
                'ScubaConfigAppSearchHelper.psm1',
                'ScubaConfigAppToolTipHelper.psm1',
                'ScubaConfigAppCommonUIHelper.psm1',
                'ScubaConfigAppUpdateUIHelper.psm1',
                'ScubaConfigAppYamlPreviewHelper.psm1'
            )

            foreach ($helper in $expectedHelpers) {
                $helperPath = Join-Path $helpersPath $helper
                Test-Path $helperPath | Should -BeTrue -Because "Helper module '$helper' should exist"
            }
        }

        It 'Should have syntactically valid helper modules' {
            $helperFiles = Get-ChildItem -Path $helpersPath -Filter "*.psm1"

            foreach ($helperFile in $helperFiles) {
                {
                    $tokens = $null
                    $errors = $null
                    [System.Management.Automation.Language.Parser]::ParseFile($helperFile.FullName, [ref]$tokens, [ref]$errors)

                    if ($errors.Count -gt 0) {
                        throw "Parse errors in $($helperFile.Name): $($errors -join '; ')"
                    }
                } | Should -Not -Throw -Because "Helper module '$($helperFile.Name)' should have valid PowerShell syntax"
            }
        }
    }

    Context 'Helper Module Unicode Character Validation' {
        It 'Should not contain problematic Unicode characters in PowerShell code' {
            $helperFiles = Get-ChildItem -Path $helpersPath -Filter "*.psm1"
            $problematicPatterns = @(
                [regex]'[🐛🎉✓⚠✗👤⚡📊📄📁🔒▶▼](?=.*\$)'  # Unicode chars near PowerShell variables
            )

            foreach ($helperFile in $helperFiles) {
                $content = Get-Content $helperFile.FullName -Raw

                foreach ($pattern in $problematicPatterns) {
                    $regexMatches = $pattern.Matches($content)
                    $regexMatches.Count | Should -Be 0 -Because "Helper module '$($helperFile.Name)' should not contain problematic Unicode characters that could cause parsing errors"
                }
            }
        }

        It 'Should not contain Unicode characters that could cause string parsing issues' {
            $helperFiles = Get-ChildItem -Path $helpersPath -Filter "*.psm1"

            foreach ($helperFile in $helperFiles) {
                $content = Get-Content $helperFile.FullName -Raw

                # Check for common problematic Unicode characters in PowerShell strings
                $problematicChars = @(
                    @{ Char = '🐛'; Name = 'Bug emoji' },
                    @{ Char = '🎉'; Name = 'Party emoji' },
                    @{ Char = '✓'; Name = 'Check mark' },
                    @{ Char = '⚠'; Name = 'Warning sign' },
                    @{ Char = '✗'; Name = 'Cross mark' },
                    @{ Char = '👤'; Name = 'User silhouette' },
                    @{ Char = '⚡'; Name = 'Lightning bolt' },
                    @{ Char = '📊'; Name = 'Bar chart' },
                    @{ Char = '📄'; Name = 'Document' },
                    @{ Char = '📁'; Name = 'Folder' },
                    @{ Char = '🔒'; Name = 'Lock' }
                )

                foreach ($charInfo in $problematicChars) {
                    if ($content.Contains($charInfo.Char)) {
                        # Check if it's in a PowerShell string context (between quotes)
                        $lines = $content -split "`n"
                        for ($i = 0; $i -lt $lines.Count; $i++) {
                            if ($lines[$i].Contains($charInfo.Char)) {
                                # Skip if it's in a comment
                                if ($lines[$i].Trim().StartsWith('#')) {
                                    continue
                                }

                                # Check if it's in a string that could cause parsing issues
                                if ($lines[$i] -match '(\$\w+.*?' + [regex]::Escape($charInfo.Char) + '|' + [regex]::Escape($charInfo.Char) + '.*?\$\w+)') {
                                    $false | Should -BeTrue -Because "Helper module '$($helperFile.Name)' contains $($charInfo.Name) character '$($charInfo.Char)' near PowerShell variables on line $($i + 1) which could cause parsing errors"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Context 'Helper Module Content Validation' {
        It 'Should contain proper PowerShell function definitions' {
            $helperFiles = Get-ChildItem -Path $helpersPath -Filter "*.psm1"

            foreach ($helperFile in $helperFiles) {
                $content = Get-Content $helperFile.FullName -Raw

                # Each helper should contain at least one function
                $content | Should -Match 'Function\s+[\w-]+\s*\{' -Because "Helper module '$($helperFile.Name)' should contain at least one function definition"
            }
        }


    }

    Context 'Helper Module Import Validation' {
        It 'Should be importable without errors' {
            $helperFiles = Get-ChildItem -Path $helpersPath -Filter "*.psm1"

            foreach ($helperFile in $helperFiles) {
                {
                    # Try to import the module
                    Import-Module $helperFile.FullName -Force -ErrorAction Stop

                    # Remove the module to clean up
                    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($helperFile.Name)
                    Remove-Module $moduleName -Force -ErrorAction SilentlyContinue
                } | Should -Not -Throw -Because "Helper module '$($helperFile.Name)' should be importable without errors"
            }
        }
    }

    Context 'Helper Module Function Inventory Validation' {
        It 'Should contain all expected functions per helper module' {
            # Define expected functions for each helper module
            $expectedFunctions = @{
                'ScubaConfigAppBaselineHelper.psm1' = @(
                    'Get-ScubaConfigRegoExclusionMappings',
                    'Update-ScubaConfigBaselineWithRego',
                    'Get-ScubaBaselinePolicy',
                    'Get-ScubaPolicyContent'
                )
                'ScubaConfigAppChangeLogHelper.psm1' = @(
                    'Show-ChangelogWindow'
                )
                'ScubaConfigAppDebugHelper.psm1' = @(
                    'Get-DebugSanitizedValue',
                    'Get-DebugSanitizedString',
                    'Export-DebugLog',
                    'Write-DebugOutput',
                    'Show-DebugWindow',
                    'Hide-DebugWindow',
                    'Update-DebugWindow',
                    'Update-DebugDisplayFilter'
                )
                'ScubaConfigAppDynamicCardHelper.psm1' = @(
                    'Test-RequiredField',
                    'New-FieldListControl',
                    'New-FieldListCard'
                )
                'ScubaConfigAppGlobalSettingsHelper.psm1' = @(
                    'New-GlobalSettingsControls',
                    'Add-GlobalSettingsAutoSave'
                )
                'ScubaConfigAppGraphHelper.psm1' = @(
                    'Update-GraphStatusIndicator',
                    'Initialize-GraphStatusIndicator',
                    'Invoke-GraphQueryWithFilter',
                    'Get-GraphEntityConfig',
                    'Show-GraphProgressWindow',
                    'Show-GraphSelector',
                    'Show-UISelectionWindow',
                    'Add-GraphButton',
                    'Add-GraphButtonToTextBox'
                )
                'ScubaConfigAppImportHelper.psm1' = @(
                    'Show-YamlImportProgress',
                    'Invoke-YamlImportWithProgress',
                    'Import-YamlToDataStructures'
                )
                'ScubaConfigAppSettingsDataHelper.psm1' = @(
                    'Set-SettingsDataForGeneralSection',
                    'Set-SettingsDataForAdvancedSection',
                    'Set-SettingsDataForGlobalSection'
                )
                'ScubaConfigAppProductHelper.psm1' = @(
                    'Update-ProductNames',
                    'Get-ProductNamesForYaml',
                    'New-ProductPolicyCards'
                )
                'ScubaConfigAppResetHelper.psm1' = @(
                    'Clear-FieldValue'
                )
                'ScubaConfigAppResultsHelper.psm1' = @(
                    'Initialize-ResultsTab',
                    'Update-ResultsTab',
                    'Test-ResultsDataValidity',
                    'New-ResultsReportTab',
                    'New-ResultsContent',
                    'New-ResultsGroupExpanderXaml',
                    'New-ResultsNoDataTab',
                    'Update-ResultsCount',
                    'Get-ResultsReportTimeStamp',
                    'Get-ResultsRelativeTime',
                    'Open-ResultsFolder'
                )
                'ScubaConfigAppScubaRunHelper.psm1' = @(
                    'New-ScubaRunParameterControls',
                    'Initialize-ScubaRunTab',
                    'Update-ScubaRunStatus',
                    'Test-ScubaRunReadiness',
                    'Start-ScubaGearExecution',
                    'Export-TempYamlConfiguration',
                    'Build-ScubaGearCommand',
                    'Start-ScubaGearJob',
                    'Write-TimestampedOutput',
                    'Find-ScubaGearResultFolder',
                    'Start-ScubaGearMonitoringRealTime',
                    'Stop-ScubaGearExecution',
                    'Complete-ScubaGearExecution',
                    'Start-ScubaGearMonitoring',
                    'Reset-ScubaRunUI'
                )
                'ScubaConfigAppSearchHelper.psm1' = @(
                    'Show-SearchAndFilterControl',
                    'Hide-SearchAndFilterControl',
                    'Add-SearchAndFilterCapability',
                    'Set-SearchAndFilter',
                    'Test-SearchAndFilter'
                )
                'ScubaConfigAppToolTipHelper.psm1' = @(
                    'Add-ToolTipHoverPopup',
                    'Initialize-ToolTipHelp'
                )
                'ScubaConfigAppCommonUIHelper.psm1' = @(
                    'Get-UIConfigCriticalValues',
                    'Find-UIControlInContainer',
                    'Find-UIControlElement',
                    'Add-UIControlEventHandler',
                    'Find-UIControlBySettingName',
                    'Find-UIControlByName',
                    'Set-UIControlValue',
                    'Find-UIListContainer',
                    'Find-UICheckBox',
                    'Find-UITextBox',
                    'Find-UIDatePicker',
                    'Set-UIComboBoxValue',
                    'Confirm-UIRequiredField',
                    'Initialize-PlaceholderTextBox'
                )
                'ScubaConfigAppUpdateUIHelper.psm1' = @(
                    'Update-UIFromSettingsData',
                    'Update-GeneralSettingsFromData',
                    'Update-AdvancedSettingsFromData',
                    'Update-ProductNameCheckboxFromData',
                    'Update-BaselineControlUIFromData',
                    'Update-PolicyCardsFromData',
                    'Update-ProductCardsFromData',
                    'Update-DynamicFields',
                    'Update-ArrayField',
                    'Update-SingleField',
                    'Update-CardVisuals'
                )
                'ScubaConfigAppYamlPreviewHelper.psm1' = @(
                    'Format-YamlMultilineString',
                    'New-YamlPreviewConvert',
                    'New-YamlPreview'
                )
            }

            foreach ($helperModule in $expectedFunctions.Keys) {
                $helperPath = Join-Path $helpersPath $helperModule

                if (Test-Path $helperPath) {
                    $content = Get-Content $helperPath -Raw
                    $expectedFunctionList = $expectedFunctions[$helperModule]

                    foreach ($expectedFunction in $expectedFunctionList) {
                        # Check for function definition (case insensitive)
                        $functionPattern = "(?i)function\s+$([regex]::Escape($expectedFunction))\s*[\{\(]"
                        $content | Should -Match $functionPattern -Because "Helper module '$helperModule' should contain function '$expectedFunction'"
                    }

                    # Verify function count matches expected count
                    $actualFunctions = [regex]::Matches($content, '(?i)function\s+([\w-]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    $actualFunctionNames = $actualFunctions | ForEach-Object { $_.Groups[1].Value }
                    $uniqueActualFunctions = $actualFunctionNames | Sort-Object | Get-Unique

                    # Allow some tolerance for potential duplicate function definitions or helper functions
                    $uniqueActualFunctions.Count | Should -BeGreaterOrEqual $expectedFunctionList.Count -Because "Helper module '$helperModule' should have at least $($expectedFunctionList.Count) unique functions (found $($uniqueActualFunctions.Count))"
                }
            }
        }

        It 'Should not contain duplicate function definitions' {
            $helperFiles = Get-ChildItem -Path $helpersPath -Filter "*.psm1"

            foreach ($helperFile in $helperFiles) {
                $content = Get-Content $helperFile.FullName -Raw

                # Find all function definitions (more precise regex to avoid comments)
                $functionMatches = [regex]::Matches($content, '^\s*function\s+([\w-]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)
                $functionNames = $functionMatches | ForEach-Object { $_.Groups[1].Value.ToLower() }

                # Check for duplicates
                $duplicates = $functionNames | Group-Object | Where-Object { $_.Count -gt 1 }

                if ($duplicates) {
                    $duplicateList = ($duplicates | ForEach-Object { "$($_.Name) ($($_.Count) times)" }) -join ', '
                    $false | Should -BeTrue -Because "Helper module '$($helperFile.Name)' contains duplicate function definitions: $duplicateList"
                }
            }
        }
    }

    Context 'Helper Module Dependencies Validation' {
        It 'Should not have circular dependencies between helpers' {
            $helperFiles = Get-ChildItem -Path $helpersPath -Filter "*.psm1"

            foreach ($helperFile in $helperFiles) {
                $content = Get-Content $helperFile.FullName -Raw
                $currentModuleName = [System.IO.Path]::GetFileNameWithoutExtension($helperFile.Name)

                # Check if this module tries to import itself
                $content | Should -Not -Match "Import-Module.*$currentModuleName" -Because "Helper module '$($helperFile.Name)' should not import itself"

                # Check for potential circular references
                foreach ($otherHelper in $helperFiles) {
                    if ($otherHelper.Name -eq $helperFile.Name) { continue }

                    $otherModuleName = [System.IO.Path]::GetFileNameWithoutExtension($otherHelper.Name)
                    $otherContent = Get-Content $otherHelper.FullName -Raw

                    # If current module imports other module, other module should not import current
                    if ($content -match "Import-Module.*$otherModuleName" -and $otherContent -match "Import-Module.*$currentModuleName") {
                        $false | Should -BeTrue -Because "Circular dependency detected between '$($helperFile.Name)' and '$($otherHelper.Name)'"
                    }
                }
            }
        }
    }

    Context 'Helper Module Documentation Validation' {
        It 'Should contain proper function documentation' {
            $helperFiles = Get-ChildItem -Path $helpersPath -Filter "*.psm1"

            foreach ($helperFile in $helperFiles) {
                $content = Get-Content $helperFile.FullName -Raw

                # If the file contains functions, it should have at least some documentation
                if ($content -match 'Function\s+[\w-]+') {
                    $content | Should -Match '\.SYNOPSIS|\.DESCRIPTION' -Because "Helper module '$($helperFile.Name)' should contain function documentation with SYNOPSIS or DESCRIPTION"
                }
            }
        }
    }
}
