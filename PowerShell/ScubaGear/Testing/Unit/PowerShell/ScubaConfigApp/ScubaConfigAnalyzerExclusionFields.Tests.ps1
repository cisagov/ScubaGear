Describe -Tag 'Analyzer' -Name 'JSON-driven analyzer exclusion fields' {
    BeforeAll {
        $root = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $helpers = Join-Path $root 'Modules\ScubaConfigApp\ScubaConfigAnalyzerHelpers'
        $script:moduleNames = @(
            'ScubaConfigAnalyzerSchemaHelper'
            'ScubaConfigAnalyzerExclusionHelper'
            'ScubaConfigAnalyzerCaHelper'
            'ScubaConfigAnalyzerUIHelper'
        )
        foreach ($name in $moduleNames) { Import-Module "$helpers\$name.psm1" -Force }
        $script:controlPath = Join-Path $root 'Modules\ScubaConfigApp\ScubaConfigAnalyzer_Control_en-US.json'
    }

    BeforeEach {
        $control = Get-Content $controlPath -Raw | ConvertFrom-Json
        $definitions = @{}
        foreach ($definition in $control.exclusionDefinitions.PSObject.Properties) {
            $definitions[$definition.Name] = $definition.Value
        }
        $definitions['FutureExclusions'] = '{"fields":[{"name":"Future identities","value":"FutureIds"},{"name":"FallbackIds"}]}' | ConvertFrom-Json
        $control.conditionalAccessAnalysis.exclusionDetectors.rules += @'
{
  "field": "FutureIds",
  "policyPath": "conditions.future.excludeIds",
  "valueKind": "idList",
  "requiresExclusionType": "FutureExclusions"
}
'@ | ConvertFrom-Json
        $script:state = @{
            ScAExclusionDefinitions = $definitions
            ScACaRules = $control.conditionalAccessAnalysis
            ScAFriendlyNames = $control.RequirementFriendlyNames
        }
        foreach ($name in $moduleNames) {
            & (Get-Module $name) { param($State) $script:syncHash = $State } $state
        }
        Mock Show-ScubaAnalyzerDetail -ModuleName ScubaConfigAnalyzerUIHelper {}
        Mock Update-ScubaAnalyzerFullYaml -ModuleName ScubaConfigAnalyzerUIHelper {}
        Mock Set-ScubaAnalyzerStatus -ModuleName ScubaConfigAnalyzerUIHelper {}
        Mock Write-ScubaAnalyzerLog -ModuleName ScubaConfigAnalyzerUIHelper { throw $Message }
    }

    It 'copies every declared <Type> field without a PowerShell field list' -ForEach @(
        @{ Type = 'CapExclusions' }
        @{ Type = 'RoleExclusions' }
        @{ Type = 'AgentExclusions' }
        @{ Type = 'FutureExclusions' }
    ) {
        $values = @{}
        foreach ($field in $state.ScAExclusionDefinitions[$Type].fields) {
            $key = if ($field.value) { $field.value } else { $field.name }
            $values[$key] = @('one', 'one', $null, '', 'two')
        }
        $values['Undeclared'] = @('not-supported')
        $map = Get-ScAExclusionValueMap -ExclusionField $Type -Values $values
        $map.Count | Should -Be ($values.Count - 1)
        foreach ($key in $map.Keys) {
            $map[$key].Count | Should -Be 2
            ($map[$key] -join ',') | Should -Be 'one,two'
            $map[$key][0] = 'changed'
            $values[$key][0] | Should -Be 'one'
        }
        $empty = Get-ScAExclusionValueMap -ExclusionField $Type -Values $null
        foreach ($key in $empty.Keys) {
            ($empty[$key] -is [array]) | Should -BeTrue
            $empty[$key].Count | Should -Be 0
        }
    }

    It 'preserves detection of all existing user-policy exclusion fields' {
        $policy = @'
{
  "Id": "user-policy",
  "DisplayName": "User policy",
  "State": "enabled",
  "Conditions": {
    "Users": {
      "IncludeUsers": ["All"],
      "ExcludeUsers": ["user-id"],
      "ExcludeGroups": ["group-id"],
      "ExcludeGuestsOrExternalUsers": {
        "GuestOrExternalUserTypes": "internalGuest,b2bCollaborationGuest"
      }
    },
    "Applications": {
      "IncludeApplications": ["All"],
      "ExcludeApplications": ["app-id"]
    }
  }
}
'@ | ConvertFrom-Json
        $validation = @'
{
  "exclusionField": "CapExclusions",
  "validationLogic": {
    "type": "conditionalAccessPolicy",
    "requirements": {
      "state": "enabled",
      "conditions": {
        "users": { "includeUsers": ["All"] },
        "applications": { "includeApplications": ["All"] }
      }
    }
  }
}
'@ | ConvertFrom-Json
        $state.ScACaRules.relevanceSignals.rules = @()
        $results = [pscustomobject]@{ Raw = [pscustomobject]@{ conditional_access_policies = @($policy) } }
        $analysis = Get-ScAPolicyAnalysis -ControlId 'test-control' -Results $results -ValidationSchema $validation
        $analysis.TotalPoliciesFound | Should -Be 1
        $candidate = $analysis.AllPolicies[0]
        $candidate.SettingIssueCount | Should -Be 0
        $candidate.ExcludedPrincipalCount | Should -Be 5
        $candidate.DetectedExclusions.Count | Should -Be 4
        $candidate.DetectedExclusions.Users | Should -Contain 'user-id'
        $candidate.DetectedExclusions.Groups | Should -Contain 'group-id'
        $candidate.DetectedExclusions.Applications | Should -Contain 'app-id'
        ($candidate.DetectedExclusions.GuestUserTypes -join ',') | Should -Be 'internalGuest,b2bCollaborationGuest'
    }

    It 'carries a JSON-only future field through detection, policy selection, and both YAML builders' {
        $policy = '{"Id":"candidate","DisplayName":"Future policy","State":"enabled","Conditions":{"Future":{"ExcludeIds":["one","two","one"]}}}' | ConvertFrom-Json
        $validation = '{"exclusionField":"FutureExclusions","validationLogic":{"type":"conditionalAccessPolicy","requirements":{"state":"enabled"}}}' | ConvertFrom-Json
        $state.ScACaRules.relevanceSignals.rules = @()
        $results = [pscustomobject]@{ Raw = [pscustomobject]@{ conditional_access_policies = @($policy) } }
        $analysis = Get-ScAPolicyAnalysis -ControlId 'test-control' -Results $results -ValidationSchema $validation
        $analysis.TotalPoliciesFound | Should -Be 1
        $candidate = $analysis.AllPolicies[0]
        ($candidate.DetectedExclusions.FutureIds -join ',') | Should -Be 'one,two'
        $candidate.DetectedExclusions.FallbackIds.Count | Should -Be 0
        $finding = [pscustomobject]@{
            ControlId = 'test-control'
            Requirement = 'Future requirement'
            ProductConfigKey = 'Aad'
            ExclusionField = 'FutureExclusions'
            AllPolicies = @($candidate)
            BestMatch = $candidate
            SelectedPolicyId = ''
            DetectedExclusions = @{}
            DetectedExclusionValues = @{}
        }
        $state.Findings_List = [pscustomobject]@{ SelectedItem = $finding }
        Select-ScubaAnalyzerPolicy -PolicyId 'candidate'
        $finding.SelectedPolicyId | Should -Be 'candidate'
        ($finding.DetectedExclusionValues.FutureIds -join ',') | Should -Be 'one,two'
        $finding.DetectedExclusionValues.Contains('FallbackIds') | Should -BeFalse
        $finding.DetectedExclusions.FutureIds[0] = 'edited'
        $candidate.DetectedExclusions.FutureIds[0] | Should -Be 'one'
        $finding.DetectedExclusionValues.FutureIds[0] | Should -Be 'one'
        $engineYaml = Build-ScAYamlExclusionsBlock -ProductConfigKey Aad -ControlId 'test-control' `
            -ExclusionField FutureExclusions -ExclusionValues $finding.DetectedExclusionValues
        $uiYaml = New-ScubaAnalyzerControlYamlText -Finding $finding -ExclusionValues $finding.DetectedExclusionValues
        foreach ($yaml in @($engineYaml, $uiYaml)) {
            $yaml | Should -Match 'FutureIds:'
            $yaml | Should -Match '\- one'
            $yaml | Should -Match '\- two'
            $yaml | Should -Not -Match 'Users:|Groups:|Applications:|Agents:'
        }

        $candidate.DetectedExclusions = $null
        Select-ScubaAnalyzerPolicy -PolicyId 'candidate'
        $finding.DetectedExclusionValues.Count | Should -Be 0
        $finding.DetectedExclusions.FutureIds.Count | Should -Be 0
        Should -Invoke Show-ScubaAnalyzerDetail -ModuleName ScubaConfigAnalyzerUIHelper -Times 2 -Exactly
        Should -Invoke Update-ScubaAnalyzerFullYaml -ModuleName ScubaConfigAnalyzerUIHelper -Times 2 -Exactly
    }

    It 'reports detector fields missing from the JSON definition instead of losing values' {
        $state.ScACaRules.exclusionDetectors.rules[-1].field = 'Undeclared'
        $policy = '{"State":"enabled","Conditions":{"Future":{"ExcludeIds":["one"]}}}' | ConvertFrom-Json
        $results = [pscustomobject]@{ Raw = [pscustomobject]@{ conditional_access_policies = @($policy) } }
        $validation = '{"exclusionField":"FutureExclusions","validationLogic":{"type":"conditionalAccessPolicy","requirements":{"state":"enabled"}}}' | ConvertFrom-Json
        { Get-ScAPolicyAnalysis -ControlId 'test-control' -Results $results -ValidationSchema $validation } |
            Should -Throw '*undefined field*Undeclared*'
    }
}
