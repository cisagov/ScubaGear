Describe -tag "Helpers" -name 'ScubaConfigApp Helper Modules Validation' {
    BeforeAll {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'helpersPath')]
        $helpersPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfigApp\ScubaConfigAppHelpers"
    }

    Context 'Helper Module Files Existence' {
        It 'Should have all required helper module files' {
            $expectedHelpers = @(
                'ScubaConfigAppAutoSaveHelper.psm1',
                'ScubaConfigAppDebugHelper.psm1',
                'ScubaConfigAppResultsHelper.psm1',
                'ScubaConfigAppChangeLogHelper.psm1',
                'ScubaConfigAppScubaRunHelper.psm1',
                'ScubaConfigAppDynamicCardHelper.psm1',
                'ScubaConfigAppResetHelper.psm1',
                'ScubaConfigAppGlobalSettingsHelper.psm1',
                'ScubaConfigAppGraphHelper.psm1',
                'ScubaConfigAppImportHelper.psm1',
                'ScubaConfigAppSettingsDataHelper.psm1',
                'ScubaConfigAppProductHelper.psm1',
                'ScubaConfigAppSearchHelper.psm1',
                'ScubaConfigAppToolTipHelper.psm1',
                'ScubaConfigAppCommonUIHelper.psm1',
                'ScubaConfigAppUpdateUIHelper.psm1',
                'ScubaConfigAppYamlPreviewHelper.psm1',
                'ScubaConfigAppSubTabHelper.psm1'
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
                'ScubaConfigAppAutoSaveHelper.psm1' = @(
                    'Get-AutoSaveDirectory',
                    'Test-AutoSaveEnabled',
                    'Save-AutoSavePolicy',
                    'Remove-AutoSavePolicy',
                    'Get-AutoSavePolicies',
                    'Restore-AutoSavePolicies',
                    'Save-AutoSaveSettings',
                    'Show-AutoSaveRestorePrompt',
                    'Restore-AutoSaveWithProgress',
                    'Show-AutoSaveRestoreProgress',
                    'Remove-AutoSaveData',
                    'Restore-AutoSaveSettings',
                    'Clear-AutoSaveData'
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
                    'Test-FieldValidation',
                    'New-FieldListControl',
                    'Add-FieldListControl',
                    'New-FieldListCard'
                )
                'ScubaConfigAppGlobalSettingsHelper.psm1' = @(
                    'New-GlobalSettingsControls',
                    'Update-GlobalSettingsCards'
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
                    'Import-YamlToDataStructures',
                    'Get-PolicyMigrationMap',
                    'Invoke-PolicyMigration'
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
                    'Find-UIFieldBySettingName',
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
                    'Update-ProductNameCheckboxFromData'
                )
                'ScubaConfigAppYamlPreviewHelper.psm1' = @(
                    'Format-YamlMultilineString',
                    'New-YamlPreviewConvert',
                    'New-YamlPreview'
                )
                'ScubaConfigAppSubTabHelper.psm1' = @(
                    'Initialize-ProductSubTabs'
                )
            }

            foreach ($helperModule in $expectedFunctions.Keys) {
                $helperPath = Join-Path $helpersPath $helperModule

                if (Test-Path $helperPath) {
                    $content = Get-Content $helperPath -Raw
                    $expectedFunctionList = $expectedFunctions[$helperModule]

                    foreach ($expectedFunction in $expectedFunctionList) {
                        # Check for function definition (case insensitive)
                        $escapedFunction = [regex]::Escape($expectedFunction)
                        $functionPattern = "(?i)function\s+$escapedFunction\s*[\{\(]"
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

                # Remove comment blocks to avoid false positives from example code
                $contentWithoutComments = $content -replace '(?s)<#.*?#>', ''

                # Check if this module tries to import itself (excluding comments)
                $contentWithoutComments | Should -Not -Match "Import-Module.*$currentModuleName" -Because "Helper module '$($helperFile.Name)' should not import itself"

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

    Context 'Policy Migration Functions' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'uiCfgPath')]
            $uiCfgPath = (Resolve-Path (Join-Path $helpersPath '..\ScubaConfigApp_Control_en-US.json')).Path

            Import-Module (Join-Path $helpersPath 'ScubaConfigAppDebugHelper.psm1')  -Force
            Import-Module (Join-Path $helpersPath 'ScubaConfigAppImportHelper.psm1') -Force

        }

        AfterAll {
            Remove-Module ScubaConfigAppImportHelper -Force -ErrorAction SilentlyContinue
            Remove-Module ScubaConfigAppDebugHelper  -Force -ErrorAction SilentlyContinue
        }

        Context 'Invoke-PolicyMigration - product exclusion blocks (Pass 1)' {
            BeforeEach {
                InModuleScope ScubaConfigAppImportHelper -Parameters @{ cfg = $uiCfgPath } {
                    param($cfg)
                    $script:syncHash = [hashtable]::Synchronized(@{
                        UIConfigPath = $cfg
                        UIConfigs    = @{
                            OfflineBaselineMarkdownPath = '..\..\baselines'
                            baselineControls = @(
                                [PSCustomObject]@{ supportsAllProducts = $true; yamlValue = 'OmitPolicy' }
                                [PSCustomObject]@{ supportsAllProducts = $true; yamlValue = 'AnnotatePolicy' }
                            )
                            policyMigration = @{
                                cacheFileName            = 'ScubaConfigApp_PolicyMigrationMap.json'
                                csvColumns               = [PSCustomObject]@{ oldId = 'Old ID'; newId = 'New ID'; rationale = 'Removal Rationale' }
                                migrationTypes           = [PSCustomObject]@{ removed = 'Removed'; decoupled = 'Decoupled'; direct = 'Direct'; versionBump = 'VersionBump' }
                                reportMaxLinesPerSection = 15
                                localeReportWindow       = [PSCustomObject]@{
                                    title    = 'Legacy Policy Migration Applied'
                                    intro    = 'This configuration file contained {0} legacy policy setting(s).'
                                    outro    = 'Please review the updated settings before saving.'
                                    sections = [PSCustomObject]@{
                                        migrated  = [PSCustomObject]@{ prefix = 'MIGRATED';  heading = 'AUTO-MIGRATED ({0}):' }
                                        decoupled = [PSCustomObject]@{ prefix = 'DECOUPLED'; heading = 'NEEDS REVIEW - POLICY SPLIT ({0}):'; body = 'These policies were decoupled into multiple new policies.' }
                                        dropped   = [PSCustomObject]@{ prefix = 'DROPPED';   heading = 'REMOVED - NO REPLACEMENT ({0}):' }
                                        skipped   = [PSCustomObject]@{ prefix = 'SKIPPED' }
                                    }
                                }
                            }
                        }
                    })
                }
                Mock -ModuleName ScubaConfigAppImportHelper Get-PolicyMigrationMap {
                    return @{
                        'MS.DEFENDER.1.1v1' = [PSCustomObject]@{
                            oldPolicyId = 'MS.DEFENDER.1.1v1'; oldProduct = 'Defender'
                            newPolicyId = 'MS.SECURITYSUITE.1.1v1'; newProduct = 'SecuritySuite'
                            allNewPolicyIds = @('MS.SECURITYSUITE.1.1v1'); migrationNote = 'Moved to SecuritySuite'
                        }
                        'MS.DEFENDER.1.4v1' = [PSCustomObject]@{
                            oldPolicyId = 'MS.DEFENDER.1.4v1'; oldProduct = 'Defender'
                            newPolicyId = 'MS.SECURITYSUITE.1.4v1'; newProduct = 'SecuritySuite'
                            allNewPolicyIds = @('MS.SECURITYSUITE.1.4v1'); migrationNote = 'Moved to SecuritySuite'
                        }
                        'MS.DEFENDER.4.5v1' = [PSCustomObject]@{
                            oldPolicyId = 'MS.DEFENDER.4.5v1'; oldProduct = 'Defender'
                            newPolicyId = $null; newProduct = $null
                            allNewPolicyIds = @(); migrationNote = 'Deprecated, no equivalent'
                        }
                    }
                }
            }

            It 'Should migrate a Defender exclusion key to the SecuritySuite product key' {
                $config = [ordered]@{
                    'Defender' = [ordered]@{ 'MS.DEFENDER.1.1v1' = @{ Rationale = 'test' } }
                }
                $result = Invoke-PolicyMigration -Config $config
                $result.Keys -contains 'SecuritySuite'                             | Should -BeTrue
                $result['SecuritySuite'].Keys -contains 'MS.SECURITYSUITE.1.1v1'  | Should -BeTrue
                $result.Keys -contains 'Defender'                                 | Should -BeFalse
            }

            It 'Should remove the old product key when all its policies have been migrated' {
                $config = [ordered]@{
                    'Defender' = [ordered]@{
                        'MS.DEFENDER.1.1v1' = @{ Rationale = 'test' }
                        'MS.DEFENDER.1.4v1' = @{ SensitiveAccounts = @{} }
                    }
                }
                $result = Invoke-PolicyMigration -Config $config
                $result.Keys -contains 'Defender' | Should -BeFalse
            }

            It 'Should populate MigrationLog with a MIGRATED entry' {
                $config = [ordered]@{
                    'Defender' = [ordered]@{ 'MS.DEFENDER.1.1v1' = @{ Rationale = 'test' } }
                }
                $null = Invoke-PolicyMigration -Config $config
                InModuleScope ScubaConfigAppImportHelper {
                    $script:syncHash.MigrationLog.Count | Should -BeGreaterThan 0
                    $script:syncHash.MigrationLog[0]    | Should -Match 'MIGRATED exclusion'
                }
            }

            It 'Should drop a Defender policy that has no migration target and log DROPPED' {
                $config = [ordered]@{
                    'Defender' = [ordered]@{ 'MS.DEFENDER.4.5v1' = @{ Data = 'irrelevant' } }
                }
                $result = Invoke-PolicyMigration -Config $config
                $result.Keys -contains 'SecuritySuite' | Should -BeFalse
                InModuleScope ScubaConfigAppImportHelper {
                    $script:syncHash.MigrationLog[0] | Should -Match 'DROPPED'
                }
            }

            It 'Should not overwrite an existing SecuritySuite target and log SKIPPED' {
                $config = [ordered]@{
                    'Defender'      = [ordered]@{ 'MS.DEFENDER.1.1v1'      = @{ Rationale = 'old value' } }
                    'SecuritySuite' = [ordered]@{ 'MS.SECURITYSUITE.1.1v1' = @{ Rationale = 'already set' } }
                }
                $result = Invoke-PolicyMigration -Config $config
                $result['SecuritySuite']['MS.SECURITYSUITE.1.1v1']['Rationale'] | Should -Be 'already set'
                InModuleScope ScubaConfigAppImportHelper {
                    $script:syncHash.MigrationLog[0] | Should -Match 'SKIPPED'
                }
            }

            It 'Should leave non-legacy product keys untouched' {
                $config = [ordered]@{
                    'Aad' = [ordered]@{ 'MS.AAD.3.1v1' = @{ CapExclusions = @{} } }
                }
                $result = Invoke-PolicyMigration -Config $config
                $result.Keys -contains 'Aad'                  | Should -BeTrue
                $result['Aad'].Keys -contains 'MS.AAD.3.1v1'  | Should -BeTrue
                InModuleScope ScubaConfigAppImportHelper {
                    $script:syncHash.MigrationLog.Count | Should -Be 0
                }
            }
        }

        Context 'Invoke-PolicyMigration - annotation and omission keys (Pass 2)' {
            BeforeEach {
                InModuleScope ScubaConfigAppImportHelper -Parameters @{ cfg = $uiCfgPath } {
                    param($cfg)
                    $script:syncHash = [hashtable]::Synchronized(@{
                        UIConfigPath = $cfg
                        UIConfigs    = @{
                            OfflineBaselineMarkdownPath = '..\..\baselines'
                            baselineControls = @(
                                [PSCustomObject]@{ supportsAllProducts = $true; yamlValue = 'OmitPolicy' }
                                [PSCustomObject]@{ supportsAllProducts = $true; yamlValue = 'AnnotatePolicy' }
                            )
                            policyMigration = @{
                                cacheFileName            = 'ScubaConfigApp_PolicyMigrationMap.json'
                                csvColumns               = [PSCustomObject]@{ oldId = 'Old ID'; newId = 'New ID'; rationale = 'Removal Rationale' }
                                migrationTypes           = [PSCustomObject]@{ removed = 'Removed'; decoupled = 'Decoupled'; direct = 'Direct'; versionBump = 'VersionBump' }
                                reportMaxLinesPerSection = 15
                                localeReportWindow       = [PSCustomObject]@{
                                    title    = 'Legacy Policy Migration Applied'
                                    intro    = 'This configuration file contained {0} legacy policy setting(s).'
                                    outro    = 'Please review the updated settings before saving.'
                                    sections = [PSCustomObject]@{
                                        migrated  = [PSCustomObject]@{ prefix = 'MIGRATED';  heading = 'AUTO-MIGRATED ({0}):' }
                                        decoupled = [PSCustomObject]@{ prefix = 'DECOUPLED'; heading = 'NEEDS REVIEW - POLICY SPLIT ({0}):'; body = 'These policies were decoupled into multiple new policies.' }
                                        dropped   = [PSCustomObject]@{ prefix = 'DROPPED';   heading = 'REMOVED - NO REPLACEMENT ({0}):' }
                                        skipped   = [PSCustomObject]@{ prefix = 'SKIPPED' }
                                    }
                                }
                            }
                        }
                    })
                }
                Mock -ModuleName ScubaConfigAppImportHelper Get-PolicyMigrationMap {
                    return @{
                        'MS.DEFENDER.1.1v1' = [PSCustomObject]@{
                            oldPolicyId = 'MS.DEFENDER.1.1v1'; oldProduct = 'Defender'
                            newPolicyId = 'MS.SECURITYSUITE.1.1v1'; newProduct = 'SecuritySuite'
                            allNewPolicyIds = @('MS.SECURITYSUITE.1.1v1'); migrationNote = 'Moved'
                        }
                        'MS.DEFENDER.6.2v1' = [PSCustomObject]@{
                            oldPolicyId = 'MS.DEFENDER.6.2v1'; oldProduct = 'Defender'
                            newPolicyId = $null; newProduct = $null
                            allNewPolicyIds = @(); migrationNote = 'No replacement'
                        }
                    }
                }
            }

            It 'Should remap an OmitPolicy entry from Defender to SecuritySuite' {
                $config = [ordered]@{
                    'OmitPolicy' = [ordered]@{ 'MS.DEFENDER.1.1v1' = @{ Rationale = 'omit' } }
                }
                $result = Invoke-PolicyMigration -Config $config
                $result['OmitPolicy'].Keys -contains 'MS.SECURITYSUITE.1.1v1' | Should -BeTrue
                $result['OmitPolicy'].Keys -contains 'MS.DEFENDER.1.1v1'      | Should -BeFalse
                InModuleScope ScubaConfigAppImportHelper {
                    $script:syncHash.MigrationLog[0] | Should -Match 'MIGRATED OmitPolicy'
                }
            }

            It 'Should drop an OmitPolicy entry that has no migration target and log DROPPED OmitPolicy' {
                $config = [ordered]@{
                    'OmitPolicy' = [ordered]@{ 'MS.DEFENDER.6.2v1' = @{ Rationale = 'gone' } }
                }
                $result = Invoke-PolicyMigration -Config $config
                $result['OmitPolicy'].Count | Should -Be 0
                InModuleScope ScubaConfigAppImportHelper {
                    $script:syncHash.MigrationLog[0] | Should -Match 'DROPPED OmitPolicy'
                }
            }

            It 'Should leave AnnotatePolicy entries for non-legacy policies unchanged' {
                $config = [ordered]@{
                    'AnnotatePolicy' = [ordered]@{ 'MS.AAD.3.6v1' = @{ Comment = 'stays' } }
                }
                $result = Invoke-PolicyMigration -Config $config
                $result['AnnotatePolicy'].Keys -contains 'MS.AAD.3.6v1' | Should -BeTrue
                InModuleScope ScubaConfigAppImportHelper {
                    $script:syncHash.MigrationLog.Count | Should -Be 0
                }
            }
        }

        Context 'Get-PolicyMigrationMap - live removedpolicies.md' {
            BeforeEach {
                InModuleScope ScubaConfigAppImportHelper -Parameters @{ cfg = $uiCfgPath } {
                    param($cfg)
                    $script:syncHash = [hashtable]::Synchronized(@{
                        UIConfigPath = $cfg
                        UIConfigs    = @{
                            OfflineBaselineMarkdownPath = '..\..\baselines'
                            PolicyMigrationsCSVPath     = '..\..\mappings\scuba-baseline-policy-migrations.csv'
                            policyMigration             = @{
                                cacheFileName  = 'ScubaConfigApp_PolicyMigrationMap.json'
                                csvColumns     = [PSCustomObject]@{ oldId = 'Old ID'; newId = 'New ID'; rationale = 'Removal Rationale' }
                                migrationTypes = [PSCustomObject]@{ removed = 'Removed'; decoupled = 'Decoupled'; direct = 'Direct'; versionBump = 'VersionBump' }
                                reportMaxLinesPerSection = 15
                            }
                            products = @(
                                [PSCustomObject]@{ id = 'Aad' }
                                [PSCustomObject]@{ id = 'SecuritySuite' }
                                [PSCustomObject]@{ id = 'Exo' }
                                [PSCustomObject]@{ id = 'PowerBI' }
                                [PSCustomObject]@{ id = 'PowerPlatform' }
                                [PSCustomObject]@{ id = 'Sharepoint' }
                                [PSCustomObject]@{ id = 'Teams' }
                            )
                        }
                    })
                }
                # Remove any cache so each test reads the CSV fresh
                $cacheFile = Join-Path $env:TEMP 'ScubaConfigApp_PolicyMigrationMap.json'
                if (Test-Path $cacheFile) { Remove-Item $cacheFile -Force }
            }

            It 'Should return a non-empty hashtable with more than 10 entries' {
                $map = Get-PolicyMigrationMap
                $map       | Should -Not -BeNullOrEmpty
                $map.Count | Should -BeGreaterThan 10
            }

            It 'Should map MS.DEFENDER.1.1v1 to MS.SECURITYSUITE.1.1v1' {
                $map = Get-PolicyMigrationMap
                $map.ContainsKey('MS.DEFENDER.1.1v1')  | Should -BeTrue
                $map['MS.DEFENDER.1.1v1'].newPolicyId  | Should -Be 'MS.SECURITYSUITE.1.1v1'
            }

            It 'Should map MS.DEFENDER.4.5v1 to None (null newPolicyId)' {
                $map = Get-PolicyMigrationMap
                $map.ContainsKey('MS.DEFENDER.4.5v1') | Should -BeTrue
                $map['MS.DEFENDER.4.5v1'].newPolicyId | Should -BeNullOrEmpty
            }

            It 'Should include the MS.EXO.2.2v2 to MS.EXO.2.2v3 version-bump entry' {
                $map = Get-PolicyMigrationMap
                $map.ContainsKey('MS.EXO.2.2v2')  | Should -BeTrue
                $map['MS.EXO.2.2v2'].newPolicyId  | Should -Be 'MS.EXO.2.2v3'
            }
        }
    }
}
