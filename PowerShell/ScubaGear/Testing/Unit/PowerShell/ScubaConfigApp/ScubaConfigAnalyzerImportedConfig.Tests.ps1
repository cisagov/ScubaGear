using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe -Tag 'Analyzer' -Name 'ScubaConfigAnalyzer carries the imported results configuration into the generated YAML' {
    BeforeAll {
        $scubaGearRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $configAppRoot = Join-Path $scubaGearRoot 'Modules\ScubaConfigApp'
        $helpersPath   = Join-Path $configAppRoot 'ScubaConfigAnalyzerHelpers'
        $controlPath   = Join-Path $configAppRoot 'ScubaConfigAnalyzer_Control_en-US.json'
        $baselinePath  = Join-Path $scubaGearRoot 'schemas\ScubaGearResultsBaselineSchema.json'
        $script:configSchemaPath = Join-Path $scubaGearRoot 'Modules\ScubaConfig\ScubaConfigSchema.json'
        $sampleResults = Join-Path $scubaGearRoot 'Sample-Reports\ScubaResults_fa5589b7-d528-4f80.json'

        # The helpers share state through $syncHash; give every helper module the same instance.
        $sharedState = [hashtable]::Synchronized(@{
            ScAModuleRoot = $helpersPath; ScAProductMap = @{}; ScAApiOperations = @{}; ScAExclusionDefinitions = @{}
            ScAMachineSpecificConfigKeys = @(); ScAConfigurableMap = @{}; ScAProductCapabilities = @{}; ScAApiCatalog = @{}
        })
        $script:helperModules = @(Get-ChildItem $helpersPath -Filter '*.psm1' | Where-Object { $_.Name -ne 'ScubaConfigAnalyzerUIHelper.psm1' } | ForEach-Object {
            $module = Import-Module $_.FullName -Force -PassThru -WarningAction SilentlyContinue
            & $module { $script:syncHash = $args[0] } $sharedState
            $module
        })

        # Sample results plus a scuba_config resembling a run that used a config file.
        $results = Get-Content $sampleResults -Raw | ConvertFrom-Json
        $cfg = $results.Raw.scuba_config
        $cfg | Add-Member -NotePropertyName OrgName -NotePropertyValue 'Contoso: HQ'
        $cfg | Add-Member -NotePropertyName ConfigFilePath -NotePropertyValue 'C:\not\a\config\key.yaml'
        $cfg | Add-Member -NotePropertyName Aad -NotePropertyValue ([pscustomobject]@{
            'MS.AAD.1.1v1' = [pscustomobject]@{ CapExclusions = [pscustomobject]@{ Users = @('aaaaaaaa-0000-0000-0000-000000000001'); Groups = @() } }
            'MS.AAD.7.4v1' = [pscustomobject]@{ RoleExclusions = [pscustomobject]@{ Users = @('bbbbbbbb-0000-0000-0000-000000000002') } }
        })
        $cfg | Add-Member -NotePropertyName Exo -NotePropertyValue ([pscustomobject]@{ 'MS.EXO.1.1v2' = [pscustomobject]@{ AllowedForwardingDomains = @('partner.com') } })
        $cfg | Add-Member -NotePropertyName OmitPolicy -NotePropertyValue ([pscustomobject]@{ 'MS.TEAMS.1.1v1' = [pscustomobject]@{ Rationale = 'Handled by third party: yes'; Expiration = '2027-01-31' } })
        $cfg | Add-Member -NotePropertyName AnnotatePolicy -NotePropertyValue ([pscustomobject]@{ 'MS.AAD.3.1v1' = [pscustomobject]@{ Comment = 'Tracked in ticket #42'; RemediationDate = '2027-03-01T00:00:00'; IncorrectResult = $false } })
        $script:raw = $results.Raw

        $script:resultsPath = Join-Path $TestDrive 'ScubaResults.json'
        $results | ConvertTo-Json -Depth 30 | Set-Content -Path $resultsPath -Encoding UTF8

        $script:analysis = Invoke-ScubaConfigAnalysis -ResultsPath $resultsPath -Product aad -IncludePassing `
            -AnalyzerControlPath $controlPath -BaselineSchemaPath $baselinePath -ConfigSchemaPath $configSchemaPath
        $script:yaml = Get-ScubaAnalyzerConfigYaml -Analysis $analysis
    }

    AfterAll {
        $script:helperModules | Remove-Module -Force -ErrorAction SilentlyContinue
    }

    Context 'Get-ScAImportedConfig' {
        It 'keeps only ScubaGear config keys, dropping run-time values and defaults' {
            $imported = Get-ScAImportedConfig -Raw $raw -ConfigSchemaPath $configSchemaPath
            $imported.Keys | Should -Contain 'Aad'
            $imported.Keys | Should -Contain 'OmitPolicy'
            $imported.Keys | Should -Contain 'AnnotatePolicy'
            $imported.Keys | Should -Not -Contain 'ConfigFilePath'
            $imported.Keys | Should -Not -Contain 'LogIn'
            $imported.Keys | Should -Not -Contain 'OutFolderName'
            $imported['M365Environment'] | Should -Be 'gcc'
        }

        It 'folds switch parameters back to booleans and drops empty values' {
            $imported = Get-ScAImportedConfig -Raw $raw -ConfigSchemaPath $configSchemaPath
            $imported['KeepIndividualJSON'] | Should -BeTrue
            $imported.Keys | Should -Not -Contain 'Organization'
            $imported['Aad']['MS.AAD.1.1v1']['CapExclusions'].Keys | Should -Not -Contain 'Groups'
        }

        It 'returns dates in the yyyy-MM-dd format the config schema requires' {
            $imported = Get-ScAImportedConfig -Raw $raw -ConfigSchemaPath $configSchemaPath
            $imported['AnnotatePolicy']['MS.AAD.3.1v1']['RemediationDate'] | Should -Be '2027-03-01'
            ConvertTo-ScAConfigValue -Value ([datetime]'2027-01-31') | Should -Be '2027-01-31'
        }

        It 'returns nothing when the results carry no scuba_config' {
            Get-ScAImportedConfig -Raw ([pscustomobject]@{ conditional_access_policies = @() }) -ConfigSchemaPath $configSchemaPath | Should -BeNullOrEmpty
        }
    }

    Context 'Get-ScubaAnalyzerConfigYaml with an imported configuration' {
        It 'exposes the imported configuration on the analysis' {
            $analysis.ImportedConfig | Should -Not -BeNullOrEmpty
        }

        It 'keeps the imported settings, product list and environment' {
            $yaml | Should -Match '(?m)^M365Environment: gcc\r?$'
            $yaml | Should -Match '(?m)^OrgName: ''Contoso: HQ''\r?$'
            $yaml | Should -Match '(?m)^KeepIndividualJSON: true\r?$'
            $yaml | Should -Match '(?m)^  - teams\r?$'
        }

        It 'comments out machine-specific paths' {
            $yaml | Should -Match '(?m)^# OPAPath: '
            $yaml | Should -Not -Match '(?m)^OPAPath:'
        }

        It 'keeps imported exclusions, including products that were not analyzed' {
            $yaml | Should -Match 'aaaaaaaa-0000-0000-0000-000000000001'
            $yaml | Should -Match 'bbbbbbbb-0000-0000-0000-000000000002'
            $yaml | Should -Match '(?m)^Exo:\r?\n  MS\.EXO\.1\.1v2:\r?\n    AllowedForwardingDomains:\r?\n      - partner\.com'
        }

        It 'does not restore imported exclusions that an override cleared' {
            $cleared = Get-ScubaAnalyzerConfigYaml -Analysis $analysis -ExclusionOverrides @{
                'MS.AAD.1.1v1' = @{ Users = @() }
            }
            $cleared | Should -Not -Match 'aaaaaaaa-0000-0000-0000-000000000001'
            $cleared | Should -Not -Match 'MS\.AAD\.1\.1v1'
            $cleared | Should -Match 'bbbbbbbb-0000-0000-0000-000000000002'
        }

        It 'keeps OmitPolicy and AnnotatePolicy' {
            $yaml | Should -Match '(?m)^OmitPolicy:\r?\n  MS\.TEAMS\.1\.1v1:\r?\n    Rationale: ''Handled by third party: yes''\r?\n    Expiration: ''2027-01-31'''
            $yaml | Should -Match '(?m)^AnnotatePolicy:\r?\n  MS\.AAD\.3\.1v1:'
            $yaml | Should -Match '(?m)^    IncorrectResult: false\r?$'
        }

        It 'appends the analyzer''s detected exclusions to the imported ones' {
            $detected = @($analysis.Findings | Where-Object {
                $_.ExclusionField -eq 'CapExclusions' -and $_.DetectedExclusionValues.Contains('Users') -and
                -not $raw.scuba_config.Aad.PSObject.Properties[$_.ControlId]
            }) | Select-Object -First 1
            $detected | Should -Not -BeNullOrEmpty
            $yaml | Should -Match ([regex]::Escape("  $($detected.ControlId):"))
            $yaml | Should -Match ([regex]::Escape(@($detected.DetectedExclusionValues.Users)[0]))
        }

        It 'writes each control only once' {
            $controlLines = @([regex]::Matches($yaml, '(?m)^  (MS\.[^:]+):\r?$') | ForEach-Object { $_.Groups[1].Value })
            @($controlLines).Count | Should -BeGreaterThan 0
            @($controlLines | Group-Object | Where-Object { $_.Count -gt 1 }).Count | Should -Be 0
        }

        It 'lets an explicit environment override the imported one' {
            Get-ScubaAnalyzerConfigYaml -Analysis $analysis -M365Environment 'gcchigh' | Should -Match '(?m)^M365Environment: gcchigh\r?$'
        }

        It 'produces YAML that parses back to the merged configuration' -Skip:(-not (Get-Module -ListAvailable powershell-yaml)) {
            Import-Module powershell-yaml
            $parsed = $yaml | ConvertFrom-Yaml
            $parsed.M365Environment | Should -Be 'gcc'
            $parsed.OmitPolicy.'MS.TEAMS.1.1v1'.Expiration | Should -Be '2027-01-31'
            $parsed.AnnotatePolicy.'MS.AAD.3.1v1'.IncorrectResult | Should -BeFalse
            $parsed.Exo.'MS.EXO.1.1v2'.AllowedForwardingDomains | Should -Be @('partner.com')
        }

        It 'produces YAML that ScubaGear accepts as a configuration file' -Skip:(-not (Get-Module -ListAvailable powershell-yaml)) {
            $yamlPath = Join-Path $TestDrive 'AnalyzerMergedConfig.yaml'
            Set-Content -Path $yamlPath -Value $yaml -Encoding UTF8
            $result = [ScubaConfig]::ValidateConfigFile($yamlPath)
            $result.IsValid | Should -BeTrue -Because ($result.ValidationErrors -join '; ')
        }
    }

    Context 'Format-ScAYamlScalar' {
        It 'quotes values YAML would read as another type' {
            Format-ScAYamlScalar '2027-01-31' | Should -Be "'2027-01-31'"
            Format-ScAYamlScalar 'true' | Should -Be "'true'"
            Format-ScAYamlScalar '42' | Should -Be "'42'"
            Format-ScAYamlScalar 'a: b' | Should -Be "'a: b'"
            Format-ScAYamlScalar "it's #1" | Should -Be "'it''s #1'"
        }

        It 'leaves ordinary values unquoted' {
            Format-ScAYamlScalar 'aaaaaaaa-0000-0000-0000-000000000001' | Should -Be 'aaaaaaaa-0000-0000-0000-000000000001'
            Format-ScAYamlScalar 'user@contoso.com' | Should -Be 'user@contoso.com'
            Format-ScAYamlScalar $true | Should -Be 'true'
            Format-ScAYamlScalar 18 | Should -Be '18'
        }
    }
}
