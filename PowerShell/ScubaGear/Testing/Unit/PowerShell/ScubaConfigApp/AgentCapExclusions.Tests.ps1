using module '..\..\..\..\Modules\ScubaConfig\ScubaConfigValidator.psm1'

Describe -Tag 'Analyzer' -Name 'Agent-only Conditional Access exclusions' {
    BeforeAll {
        $root = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        [ScubaConfigValidator]::Initialize("$root\Modules\ScubaConfig")
        $app = Join-Path $root 'Modules\ScubaConfigApp'
        $helpers = Join-Path $app 'ScubaConfigAnalyzerHelpers'
        Import-Module "$helpers\ScubaConfigAnalyzerSchemaHelper.psm1" -Force
        Import-Module "$helpers\ScubaConfigAnalyzerCaHelper.psm1" -Force
        Import-Module "$helpers\ScubaConfigAnalyzerExclusionHelper.psm1" -Force
        $control = Get-Content "$app\ScubaConfigAnalyzer_Control_en-US.json" -Raw | ConvertFrom-Json
        $schema = Get-Content "$root\schemas\ScubaGearResultsBaselineSchema.json" -Raw | ConvertFrom-Json
        $script:validation = $schema.baselineValidations.aad | Where-Object id -EQ 'MS.AAD.9.1v1'
        $configSchemaPath = "$root\Modules\ScubaConfig\ScubaConfigSchema.json"
        $script:configSchema = Get-Content $configSchemaPath -Raw | ConvertFrom-Json
        $definitions = @{ AgentExclusions = $control.exclusionDefinitions.AgentExclusions }
        $state = @{
            ScACaRules = $control.conditionalAccessAnalysis
            ScAFriendlyNames = $control.RequirementFriendlyNames
            ScAExclusionDefinitions = $definitions
        }
        foreach ($moduleName in @('ScubaConfigAnalyzerSchemaHelper', 'ScubaConfigAnalyzerCaHelper', 'ScubaConfigAnalyzerExclusionHelper')) {
            & (Get-Module $moduleName) { param($State) $script:syncHash = $State } $state
        }
        $script:id1 = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        $script:id2 = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    }

    It 'keeps baseline, schema, editor, and analyzer fields aligned and agent-only' {
        $configSchema.schemaMetadata.policyExclusionMappings.'MS.AAD.9.1v1' | Should -Contain 'AgentExclusions'
        $configSchema.schemaMetadata.productCapabilities.Aad.supportedExclusionTypes | Should -Contain 'AgentExclusions'
        $validation.exclusionField | Should -Be 'AgentExclusions'
        $baseline = Get-Content "$root\schemas\ScubaBaselines.json" -Raw | ConvertFrom-Json
        $agentBaseline = @($baseline.baselines.aad | Where-Object id -EQ 'MS.AAD.9.1v1')
        $agentBaseline.Count | Should -Be 1
        $agentBaseline[0].exclusionField | Should -Be 'AgentCapExclusions'
        $editor = Get-Content "$app\ScubaConfigApp_Control_en-US.json" -Raw | ConvertFrom-Json
        @($editor.inputTypes.AgentCapExclusions.fields).Count | Should -Be 1
        $editor.inputTypes.AgentCapExclusions.value | Should -Be 'AgentExclusions'
        $editor.inputTypes.AgentCapExclusions.fields[0].value | Should -Be 'Agents'
        $definitions.AgentExclusions.fields[0].value | Should -Be 'Agents'
    }

    It 'defines AgentExclusions as a GUID-only list of agents and nothing else' {
        $definition = $configSchema.definitions.exclusionTypes.AgentExclusions
        $definition | Should -Not -BeNullOrEmpty
        @($definition.properties.PSObject.Properties.Name) | Should -Be @('Agents')
        $definition.additionalProperties | Should -BeFalse
        $definition.properties.Agents.type | Should -Be 'array'
        $definition.properties.Agents.items.'$ref' | Should -Be '#/definitions/patterns/guid'
        $definition.properties.Agents.uniqueItems | Should -BeTrue
        $configSchema.definitions.exclusionTypes.PSObject.Properties.Name | Should -Not -Contain 'AgentCapExclusions'
        $configSchema.definitions.exclusionTypes.PSObject.Properties.Name | Should -Contain 'AgentExclusions'
        @($configSchema.definitions.patterns.guid.pattern) | Should -Not -BeNullOrEmpty
    }

    It 'accepts AgentExclusions for MS.AAD.9.1v1 and warns about exclusion types it does not support' {
        function Get-ConfigWarning($Exclusions) {
            $file = Join-Path $TestDrive "agent-config-$([guid]::NewGuid()).json"
            @{ ProductNames = @('aad'); Aad = @{ 'MS.AAD.9.1v1' = $Exclusions } } | ConvertTo-Json -Depth 10 | Set-Content $file -Encoding utf8
            $result = [ScubaConfigValidator]::ValidateYamlFile($file, $false, $false)
            @($result.ValidationErrors) + @($result.Warnings) | Where-Object { $_ -match '9\.1v1|AgentExclusions|CapExclusions' }
        }
        @(Get-ConfigWarning @{ AgentExclusions = @{ Agents = @($id1, $id2) } }).Count | Should -Be 0
        (Get-ConfigWarning @{ CapExclusions = @{ Groups = @($id1) } }) -join ' ' | Should -Match "supports exclusion types: AgentExclusions"
        (Get-ConfigWarning @{ AgentCapExclusions = @{ Agents = @($id1) } }) -join ' ' | Should -Match "supports exclusion types: AgentExclusions"
    }

    # Test-Json is PowerShell 7+ only; CI's Windows PowerShell 5.1 skips this check.
    It 'validates agent IDs and rejects application fields in AgentExclusions' -Skip:(-not (Get-Command Test-Json -ErrorAction SilentlyContinue)) {
        $valid = @{ Aad = @{ 'MS.AAD.9.1v1' = @{ AgentExclusions = @{ Agents = @($id1, $id2) } } } } | ConvertTo-Json -Depth 10
        Test-Json -Json $valid -SchemaFile $configSchemaPath | Should -BeTrue
        foreach ($exclusions in @(@{ Agents = @('invalid') }, @{ Agents = @($id1, $id1) }, @{ Applications = @($id1) })) {
            $invalid = @{ Aad = @{ 'MS.AAD.9.1v1' = @{ AgentExclusions = $exclusions } } } | ConvertTo-Json -Depth 10
            Test-Json -Json $invalid -SchemaFile $configSchemaPath -ErrorAction SilentlyContinue | Should -BeFalse
        }
    }

    It 'detects exclusions and generates agent-only YAML for <Shape>' -ForEach @(
        @{ Shape = 'preview strings' }
        @{ Shape = 'normalized arrays' }
    ) {
        $raw = if ($Shape -eq 'preview strings') { "$id1 `t $id2" } else { @($id1, $id2) }
        $policy = [pscustomobject]@{
            DisplayName = 'Risky agents'
            Id = 'test-policy'
            State = 'enabled'
            Conditions = [pscustomobject]@{
                ClientAppTypes = @('all')
                Applications = [pscustomobject]@{ IncludeApplications = 'AllAgentIdResources' }
                AgentIdRiskLevels = 'medium, high'
                ClientApplications = [pscustomobject]@{
                    IncludeAgentIdServicePrincipals = 'All'
                    ExcludeAgentIdServicePrincipals = $raw
                }
            }
            GrantControls = [pscustomobject]@{ BuiltInControls = @('block'); Operator = 'OR' }
        }
        $results = [pscustomobject]@{ Raw = [pscustomobject]@{ conditional_access_policies = @($policy) } }
        $analysis = Get-ScAPolicyAnalysis -ControlId 'MS.AAD.9.1v1' -Results $results -ValidationSchema $validation
        $analysis.TotalPoliciesFound | Should -Be 1
        $match = $analysis.AllPolicies[0]
        $match.SettingIssueCount | Should -Be 0
        $match.ExcludedPrincipalCount | Should -Be 2
        $match.DetectedExclusions.Agents | Should -Contain $id1
        $match.DetectedExclusions.Agents | Should -Contain $id2
        (Get-ScAActionClassification -PolicyAnalysis $analysis).Action | Should -Be 'ADD_EXCLUSIONS'
        $yaml = Build-ScAYamlExclusionsBlock -ProductConfigKey Aad -ControlId 'MS.AAD.9.1v1' -ExclusionField AgentExclusions `
            -ExclusionValues $match.DetectedExclusions -ExclusionDefinitions $definitions
        $yaml | Should -Match 'AgentExclusions:'
        $yaml | Should -Match 'Agents:'
        $yaml | Should -Match $id1
        $yaml | Should -Match $id2
        $yaml | Should -Not -Match 'Applications:|Users:|Groups:'

        $policy.Conditions.ClientApplications.ExcludeAgentIdServicePrincipals = @()
        $analysis = Get-ScAPolicyAnalysis -ControlId 'MS.AAD.9.1v1' -Results $results -ValidationSchema $validation
        (Get-ScAActionClassification -PolicyAnalysis $analysis).Action | Should -Be 'NONE'

        $policy.Conditions.Applications.IncludeApplications = 'Office365'
        $analysis = Get-ScAPolicyAnalysis -ControlId 'MS.AAD.9.1v1' -Results $results -ValidationSchema $validation
        (Get-ScAActionClassification -PolicyAnalysis $analysis).Action | Should -Be 'FIX_POLICY'
    }
}
