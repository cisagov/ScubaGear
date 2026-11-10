Describe -Tag 'Analyzer' -Name 'Config Analyzer handles policy exemption relationships (MS.AAD.2.1v2 / MS.AAD.2.2v2)' {
    BeforeAll {
        $scubaGearRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $configAppRoot = Join-Path $scubaGearRoot 'Modules\ScubaConfigApp'
        $helpersPath   = Join-Path $configAppRoot 'ScubaConfigAnalyzerHelpers'
        $script:controlPath      = Join-Path $configAppRoot 'ScubaConfigAnalyzer_Control_en-US.json'
        $script:baselinePath     = Join-Path $scubaGearRoot 'schemas\ScubaGearResultsBaselineSchema.json'
        $script:configSchemaPath = Join-Path $scubaGearRoot 'schemas\ScubaConfigSchema.json'

        # The helpers share state through $syncHash; give every helper module the same instance.
        $script:sharedState = [hashtable]::Synchronized(@{
            ScAModuleRoot = $helpersPath; ScAProductMap = @{}; ScAApiOperations = @{}; ScAExclusionDefinitions = @{}
            ScAMachineSpecificConfigKeys = @(); ScAConfigurableMap = @{}; ScAProductCapabilities = @{}; ScAApiCatalog = @{}
            ScAExclusionRelationships = @{}
        })
        $script:helperModules = @(Get-ChildItem $helpersPath -Filter '*.psm1' | ForEach-Object {
            $module = Import-Module $_.FullName -Force -PassThru -WarningAction SilentlyContinue
            & $module { $script:syncHash = $args[0] } $sharedState
            $module
        })

        $script:baseline = Get-Content $baselinePath -Raw | ConvertFrom-Json
        $script:configSchema = Get-Content $configSchemaPath -Raw | ConvertFrom-Json
        $analyzerControl = Get-Content $controlPath -Raw | ConvertFrom-Json
        Import-ScAAnalyzerRules -AnalyzerSchema $analyzerControl
        Import-ScAConfigurableMap -ConfigSchemaPath $configSchemaPath

        $script:phishingResistant = [pscustomobject]@{ Id = '00000000-0000-0000-0000-000000000004'; DisplayName = 'Phishing-resistant MFA'; AllowedCombinations = @('fido2') }
        $script:mfa               = [pscustomobject]@{ Id = '00000000-0000-0000-0000-000000000002'; DisplayName = 'Multifactor authentication' }
        $script:passwordless      = [pscustomobject]@{ Id = '00000000-0000-0000-0000-000000000003'; DisplayName = 'Passwordless MFA' }

        function New-RiskPolicy {
            param($Strength, [string[]]$IncludeUsers = @('All'), [string[]]$IncludeGroups = @(), [string[]]$ExcludeUsers = @(), [string]$Name = 'Risk policy', [string]$Id = 'p1')
            [pscustomobject]@{
                DisplayName = $Name; Id = $Id; State = 'enabled'
                Conditions = [pscustomobject]@{
                    Users = [pscustomobject]@{ IncludeUsers = $IncludeUsers; IncludeGroups = $IncludeGroups; ExcludeUsers = $ExcludeUsers; ExcludeGroups = @() }
                    Applications = [pscustomobject]@{ IncludeApplications = @('All') }
                    UserRiskLevels = @('high'); SignInRiskLevels = @()
                }
                GrantControls = [pscustomobject]@{ BuiltInControls = @('riskRemediation'); Operator = 'AND'; AuthenticationStrength = $Strength }
                SessionControls = [pscustomobject]@{ SignInFrequency = [pscustomobject]@{ IsEnabled = $true; FrequencyInterval = 'everyTime' } }
            }
        }

        function Get-Analysis {
            param([string]$ControlId, $Policy)
            $validation = $baseline.baselineValidations.aad | Where-Object id -EQ $ControlId
            $results = [pscustomobject]@{ Raw = [pscustomobject]@{ conditional_access_policies = @($Policy) } }
            Get-ScAPolicyAnalysis -ControlId $ControlId -Results $results -ValidationSchema $validation
        }

        # Minimal ScubaResults JSON with one failing AAD control per entry, and the CA policies in Raw.
        function New-ResultsFile {
            param([string[]]$ControlIds, $Policies, $ScubaConfig, [string]$Result = 'Fail')
            $controls = @($ControlIds | ForEach-Object { [ordered]@{ 'Control ID' = $_; Requirement = "Requirement $_"; Result = $Result; Criticality = 'Shall'; Details = 'See conditional access policy' } })
            $raw = [ordered]@{ conditional_access_policies = @($Policies) }
            if ($ScubaConfig) { $raw['scuba_config'] = $ScubaConfig }
            $results = [ordered]@{
                MetaData = [ordered]@{ DisplayName = 'Contoso'; DomainName = 'contoso.onmicrosoft.com'; TenantId = 'tenant'; TimestampZulu = '2026-01-01T00:00:00Z' }
                Summary  = [ordered]@{ AAD = [ordered]@{ Passes = 0; Failures = @($controls).Count; Warnings = 0; Errors = 0; Manual = 0 } }
                Results  = [ordered]@{ AAD = @([ordered]@{ GroupName = 'Risk Based Policies'; GroupNumber = '2'; GroupReferenceURL = ''; Controls = $controls }) }
                Raw      = $raw
            }
            $file = Join-Path $TestDrive "results-$([guid]::NewGuid()).json"
            $results | ConvertTo-Json -Depth 30 | Set-Content -Path $file -Encoding UTF8
            $file
        }

        function Invoke-Analysis {
            param($ResultsFile)
            Invoke-ScubaConfigAnalysis -ResultsPath $ResultsFile -Product aad -IncludePassing `
                -AnalyzerControlPath $controlPath -BaselineSchemaPath $baselinePath -ConfigSchemaPath $configSchemaPath
        }
    }

    AfterAll {
        $script:helperModules | Remove-Module -Force -ErrorAction SilentlyContinue
    }

    Context 'Baseline validation entries for the renumbered risk policies' {
        It 'models MS.AAD.2.1v2 with a phishing-resistant authentication strength' {
            $entry = $baseline.baselineValidations.aad | Where-Object id -EQ 'MS.AAD.2.1v2'
            $requirements = $entry.validationLogic.requirements
            $requirements.grantControls.authenticationStrength.id | Should -Be '00000000-0000-0000-0000-000000000004'
            $requirements.grantControls.builtInControls | Should -Contain 'riskRemediation'
            $requirements.grantControls.operator | Should -Be 'AND'
            @($requirements.conditions.users.includeUsers) | Should -Be @('All')
            $requirements.sessionControls.signInFrequency.frequencyInterval | Should -Be 'everyTime'
            $entry.exclusionField | Should -Be 'CapExclusions'
        }

        It 'models MS.AAD.2.2v2 with structured requirements the generic engine can evaluate' {
            $entry = $baseline.baselineValidations.aad | Where-Object id -EQ 'MS.AAD.2.2v2'
            $requirements = $entry.validationLogic.requirements
            $entry.validationLogic.type | Should -Be 'conditionalAccessPolicy'
            $entry.exclusionField | Should -Be 'CapExclusions'
            # Free text cannot be compared with a policy; the scope is modeled as all users.
            @($requirements.conditions.users.includeUsers) | Should -Be @('All')
            @($requirements.conditions.userRiskLevels) | Should -Be @('high')
            @($requirements.conditions.signInRiskLevels).Count | Should -Be 0
            $requirements.grantControls.builtInControls | Should -Contain 'riskRemediation'
            $requirements.grantControls.operator | Should -Be 'AND'
            $strengthIds = @($requirements.grantControls.anyOf | ForEach-Object { $_.authenticationStrength.id })
            $strengthIds | Should -Contain '00000000-0000-0000-0000-000000000002'
            $strengthIds | Should -Not -Contain '00000000-0000-0000-0000-000000000004'
            $entry.notes | Should -Match 'MS\.AAD\.2\.1v2'
            $entry.exceptions | Should -Match 'MS\.AAD\.2\.1v2'
        }

        It 'keeps MS.AAD.2.3v2 (notification) and MS.AAD.2.4v1 (block) after the renumber' {
            $aad = $baseline.baselineValidations.aad
            $notification = $aad | Where-Object id -EQ 'MS.AAD.2.3v2'
            $notification.validationLogic.type | Should -Be 'identityProtectionSetting'
            $notification.exclusionField | Should -Be 'none'
            $block = $aad | Where-Object id -EQ 'MS.AAD.2.4v1'
            $block.validationLogic.requirements.grantControls.builtInControls | Should -Contain 'block'
            @($block.validationLogic.requirements.conditions.signInRiskLevels) | Should -Be @('high')
            @($aad | Where-Object { $_.id -in @('MS.AAD.2.2v1', 'MS.AAD.2.3v1') }).Count | Should -Be 0
        }

        It 'only lists policies in the baseline that exist in the config schema exclusion mappings' {
            $mappings = $configSchema.schemaMetadata.policyExclusionMappings
            foreach ($id in 'MS.AAD.2.1v2', 'MS.AAD.2.2v2', 'MS.AAD.2.4v1') {
                $mappings.$id | Should -Contain 'CapExclusions'
                ($baseline.baselineValidations.aad | Where-Object id -EQ $id).exclusionField | Should -Be 'CapExclusions'
            }
        }
    }

    Context 'Get-ScAPolicyAnalysis' {
        It 'MS.AAD.2.1v2 accepts a phishing-resistant strength and rejects an MFA strength' {
            (Get-Analysis 'MS.AAD.2.1v2' (New-RiskPolicy $phishingResistant)).AllPolicies[0].MeetsCriteria | Should -BeTrue
            $mfaAnalysis = Get-Analysis 'MS.AAD.2.1v2' (New-RiskPolicy $mfa)
            $mfaAnalysis.AllPolicies[0].SettingIssueCount | Should -BeGreaterThan 0
            (Get-ScAActionClassification -PolicyAnalysis $mfaAnalysis).Action | Should -Be 'FIX_POLICY'
        }

        It 'MS.AAD.2.2v2 accepts <Name> authentication strength' -ForEach @(
            @{ Name = 'the built-in MFA'; Strength = 'mfa' }
            @{ Name = 'the built-in Passwordless MFA'; Strength = 'passwordless' }
        ) {
            $analysis = Get-Analysis 'MS.AAD.2.2v2' (New-RiskPolicy (Get-Variable $Strength -ValueOnly))
            $analysis.TotalPoliciesFound | Should -Be 1
            $analysis.AllPolicies[0].Issues | Should -BeNullOrEmpty
            $analysis.AllPolicies[0].MeetsCriteria | Should -BeTrue
            (Get-ScAActionClassification -PolicyAnalysis $analysis).Action | Should -Be 'NONE'
        }

        It 'MS.AAD.2.2v2 flags a phishing-resistant-only strength as a setting issue' {
            $analysis = Get-Analysis 'MS.AAD.2.2v2' (New-RiskPolicy $phishingResistant)
            $analysis.AllPolicies[0].SettingIssueCount | Should -BeGreaterThan 0
            ($analysis.AllPolicies[0].Issues -join ' ') | Should -Match 'authenticationStrength|Authentication'
            (Get-ScAActionClassification -PolicyAnalysis $analysis).Action | Should -Be 'FIX_POLICY'
        }

        It 'MS.AAD.2.2v2 no longer reports the free-text scope as a failed requirement' {
            $analysis = Get-Analysis 'MS.AAD.2.2v2' (New-RiskPolicy $mfa)
            ($analysis.AllPolicies[0].Issues -join ' ') | Should -Not -Match 'exempted from'
            ($analysis.AllPolicies[0].Issues -join ' ') | Should -Not -Match 'includeUsers'
        }

        It 'MS.AAD.2.2v2 reports excluded break-glass accounts as config exclusions for the MFA policy itself' {
            $analysis = Get-Analysis 'MS.AAD.2.2v2' (New-RiskPolicy $mfa -ExcludeUsers @('bg1'))
            $match = $analysis.AllPolicies[0]
            $match.SettingIssueCount | Should -Be 0
            $match.ExcludedPrincipalCount | Should -Be 1
            $match.DetectedExclusions.Users | Should -Contain 'bg1'
            (Get-ScAActionClassification -PolicyAnalysis $analysis).Action | Should -Be 'ADD_EXCLUSIONS'
        }

        It 'MS.AAD.2.2v2 models the all-users scope only (a policy that includes only a group is not a candidate)' {
            $analysis = Get-Analysis 'MS.AAD.2.2v2' (New-RiskPolicy $mfa -IncludeUsers @() -IncludeGroups @('exempt-group'))
            $analysis.TotalPoliciesFound | Should -Be 0
        }
    }

    Context 'Relationship metadata' {
        It 'loads policyExclusionRelationships from the config schema without hardcoding policy ids' {
            $relationship = Get-ScAExclusionRelationship -ControlId 'MS.AAD.2.1v2'
            $expected = $configSchema.schemaMetadata.policyExclusionRelationships.'MS.AAD.2.1v2'
            @($relationship.Dependents) | Should -Be @($expected.dependents)
            $relationship.Note | Should -Be $expected.note
            Get-ScAExclusionRelationship -ControlId 'MS.AAD.2.2v2' | Should -BeNullOrEmpty
            Get-ScAExclusionRelationship -ControlId 'MS.AAD.3.1v1' | Should -BeNullOrEmpty
        }

        It 'returns the schema note as a follow-up only for a parent policy with exemptions' {
            $note = $configSchema.schemaMetadata.policyExclusionRelationships.'MS.AAD.2.1v2'.note
            $followUp = @(Get-ScAExclusionFollowUp -ControlId 'MS.AAD.2.1v2' -HasExclusions $true)
            $followUp.Count | Should -Be 1
            $followUp[0] | Should -Match '^Follow-up \(MS\.AAD\.2\.2v2\): '
            $followUp[0] | Should -Match ([regex]::Escape($note))
            @(Get-ScAExclusionFollowUp -ControlId 'MS.AAD.2.1v2' -HasExclusions $false).Count | Should -Be 0
            @(Get-ScAExclusionFollowUp -ControlId 'MS.AAD.2.2v2' -HasExclusions $true).Count | Should -Be 0
            @(Get-ScAExclusionFollowUp -ControlId 'MS.AAD.3.1v1' -HasExclusions $true).Count | Should -Be 0
        }

        It 'builds a commented dependent stub that keeps the YAML valid' {
            $stub = Get-ScAYamlDependentStub -ControlId 'MS.AAD.2.1v2'
            $stub | Should -Match '(?m)^  # MS\.AAD\.2\.2v2:'
            $stub | Should -Match '(?m)^  #   CapExclusions:'
            $stub | Should -Match '(?m)^  #     Users:'
            ($stub -split "`r?`n" | Where-Object { $_ }) | ForEach-Object { $_ | Should -Match '^\s*#' }
        }

        It 'skips the stub when the dependent already has its own block, and for non-parent policies' {
            Get-ScAYamlDependentStub -ControlId 'MS.AAD.2.1v2' -ExistingControlIds @('MS.AAD.2.2v2') | Should -BeNullOrEmpty
            Get-ScAYamlDependentStub -ControlId 'MS.AAD.3.1v1' | Should -BeNullOrEmpty
        }

        It 'is empty when the relationship metadata is missing' {
            $saved = $sharedState.ScAExclusionRelationships
            try {
                $sharedState.ScAExclusionRelationships = @{}
                @(Get-ScAExclusionFollowUp -ControlId 'MS.AAD.2.1v2' -HasExclusions $true).Count | Should -Be 0
                Get-ScAYamlDependentStub -ControlId 'MS.AAD.2.1v2' | Should -BeNullOrEmpty
            } finally {
                $sharedState.ScAExclusionRelationships = $saved
            }
        }
    }

    Context 'Invoke-ScubaConfigAnalysis and Get-ScubaAnalyzerConfigYaml' {
        It 'adds a follow-up recommendation and the dependent stub when MS.AAD.2.1v2 exemptions are suggested' {
            $policy = New-RiskPolicy $phishingResistant -ExcludeUsers @('11111111-1111-1111-1111-111111111111')
            $analysis = Invoke-Analysis (New-ResultsFile -ControlIds 'MS.AAD.2.1v2' -Policies @($policy))
            $finding = $analysis.Findings | Where-Object ControlId -EQ 'MS.AAD.2.1v2'
            $finding.ConfigAction | Should -Be 'EXCLUDE'
            $finding.DetectedExclusionValues.Users | Should -Contain '11111111-1111-1111-1111-111111111111'
            ($finding.Recommendations -join "`n") | Should -Match 'Follow-up \(MS\.AAD\.2\.2v2\)'
            $finding.YamlBlock | Should -Match '(?m)^  MS\.AAD\.2\.1v2:'
            $finding.YamlBlock | Should -Match '(?m)^  # MS\.AAD\.2\.2v2:'

            $yaml = Get-ScubaAnalyzerConfigYaml -Analysis $analysis
            $yaml | Should -Match '(?m)^  MS\.AAD\.2\.1v2:\r?\n    CapExclusions:\r?\n      Users:\r?\n        - 11111111-1111-1111-1111-111111111111'
            $yaml | Should -Match '(?m)^  # MS\.AAD\.2\.2v2:'
            $yaml | Should -Not -Match '(?m)^  MS\.AAD\.2\.2v2:'
        }

        It 'shows the follow-up stub in the per-control YAML text' {
            $policy = New-RiskPolicy $phishingResistant -ExcludeUsers @('11111111-1111-1111-1111-111111111111')
            $analysis = Invoke-Analysis (New-ResultsFile -ControlIds 'MS.AAD.2.1v2' -Policies @($policy))
            $finding = $analysis.Findings | Where-Object ControlId -EQ 'MS.AAD.2.1v2'
            New-ScubaAnalyzerControlYamlText -Finding $finding -ExclusionValues $finding.DetectedExclusionValues | Should -Match '(?m)^  # MS\.AAD\.2\.2v2:'
        }

        It 'does not add the stub when the dependent policy has its own exclusions' {
            $parent = New-RiskPolicy $phishingResistant -ExcludeUsers @('11111111-1111-1111-1111-111111111111') -Name 'Phishing-resistant' -Id 'p1'
            $dependent = New-RiskPolicy $mfa -ExcludeUsers @('22222222-2222-2222-2222-222222222222') -Name 'MFA' -Id 'p2'
            $analysis = Invoke-Analysis (New-ResultsFile -ControlIds 'MS.AAD.2.1v2', 'MS.AAD.2.2v2' -Policies @($parent, $dependent))
            $yaml = Get-ScubaAnalyzerConfigYaml -Analysis $analysis
            $yaml | Should -Match '(?m)^  MS\.AAD\.2\.1v2:'
            $yaml | Should -Match '(?m)^  MS\.AAD\.2\.2v2:\r?\n    CapExclusions:\r?\n      Users:\r?\n        - 22222222-2222-2222-2222-222222222222'
            $yaml | Should -Not -Match '(?m)^  # MS\.AAD\.2\.2v2:'
            $dependentFinding = $analysis.Findings | Where-Object ControlId -EQ 'MS.AAD.2.2v2'
            ($dependentFinding.Recommendations -join "`n") | Should -Not -Match 'Follow-up'
        }

        It 'adds neither recommendation nor stub for a parent policy without exemptions' {
            $policy = New-RiskPolicy $mfa
            $analysis = Invoke-Analysis (New-ResultsFile -ControlIds 'MS.AAD.2.1v2' -Policies @($policy))
            $finding = $analysis.Findings | Where-Object ControlId -EQ 'MS.AAD.2.1v2'
            ($finding.Recommendations -join "`n") | Should -Not -Match 'Follow-up'
            $finding.YamlBlock | Should -BeNullOrEmpty
            Get-ScubaAnalyzerConfigYaml -Analysis $analysis | Should -Not -Match 'MS\.AAD\.2\.2v2'
        }

        It 'adds the stub for exemptions already configured in the imported results configuration' {
            $scubaConfig = [ordered]@{
                ProductNames = @('aad')
                Aad = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ CapExclusions = [ordered]@{ Groups = @('33333333-3333-3333-3333-333333333333') } } }
            }
            $analysis = Invoke-Analysis (New-ResultsFile -ControlIds 'MS.AAD.2.1v2' -Policies @(New-RiskPolicy $phishingResistant) -ScubaConfig $scubaConfig -Result 'Pass')
            $finding = $analysis.Findings | Where-Object ControlId -EQ 'MS.AAD.2.1v2'
            $finding.ConfiguredExclusionValues.Groups | Should -Contain '33333333-3333-3333-3333-333333333333'
            ($finding.Recommendations -join "`n") | Should -Match 'Follow-up \(MS\.AAD\.2\.2v2\)'
            $yaml = Get-ScubaAnalyzerConfigYaml -Analysis $analysis
            $yaml | Should -Match '33333333-3333-3333-3333-333333333333'
            $yaml | Should -Match '(?m)^  # MS\.AAD\.2\.2v2:'
        }
    }
}
