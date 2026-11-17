BeforeAll {
    Import-Module "$PSScriptRoot\..\..\..\..\..\Modules\Providers\ProviderHelpers\AADConditionalAccessHelper.psm1"
}

Describe 'ConvertTo-AgentCapExclusionArray' {
    It 'shows agent inclusions and normalized exclusions in CA report rows' {
        $policy = Get-Content "$PSScriptRoot\CapSnippets\Users.json" -Raw | ConvertFrom-Json
        $policy | Add-Member -NotePropertyName DisplayName -NotePropertyValue 'Risky agents'
        $policy | Add-Member -NotePropertyName State -NotePropertyValue 'enabled'
        $policy.Conditions | Add-Member -NotePropertyName ClientApplications -NotePropertyValue ([pscustomobject]@{
            IncludeAgentIdServicePrincipals = 'All'
            ExcludeAgentIdServicePrincipals = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
        })
        $policy = $policy | ConvertTo-AgentCapExclusionArray
        $report = (Get-CapTracker).ExportCapPolicies(@($policy)) 3>$null | ConvertFrom-Json
        $report.Users | Should -Contain 'Agents included: All'
        $report.Users | Should -Contain 'Agents excluded: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa, bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
        $policy.Conditions.ClientApplications.ExcludeAgentIdServicePrincipals = @()
        $report = (Get-CapTracker).ExportCapPolicies(@($policy)) 3>$null | ConvertFrom-Json
        $report.Users | Should -Contain 'Agents excluded: None'
    }

    It 'displays agent resources instead of counting the preview string as applications' {
        $policy = Get-Content "$PSScriptRoot\CapSnippets\Apps.json" -Raw | ConvertFrom-Json
        $policy.Conditions.Applications.IncludeApplications = 'AllAgentIdResources'
        (Get-CapTracker).GetApplications($policy) | Should -Contain 'Agent resources included: All'
    }

    It 'normalizes <Label> and preserves array shape in JSON' -ForEach @(
        @{ Label = 'null'; Raw = $null; Expected = @() }
        @{ Label = 'empty strings'; Raw = ''; Expected = @() }
        @{ Label = 'whitespace'; Raw = " `t`r`n "; Expected = @() }
        @{ Label = 'one ID'; Raw = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'; Expected = @('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') }
        @{ Label = 'multiple IDs'; Raw = " aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa `t`r`n bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb "; Expected = @('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') }
        @{ Label = 'empty arrays'; Raw = @(); Expected = @() }
        @{ Label = 'singleton arrays'; Raw = @('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'); Expected = @('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') }
        @{ Label = 'multiple-item arrays'; Raw = @('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'); Expected = @('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') }
    ) {
        $policy = [pscustomobject]@{
            Conditions = [pscustomobject]@{
                ClientApplications = [pscustomobject]@{ ExcludeAgentIdServicePrincipals = $Raw }
            }
        }
        $result = $policy | ConvertTo-AgentCapExclusionArray
        $actual = $result.Conditions.ClientApplications.ExcludeAgentIdServicePrincipals
        ($actual -is [array]) | Should -BeTrue
        $actual.Count | Should -Be $Expected.Count
        ($actual -join ',') | Should -Be ($Expected -join ',')
        $roundTrip = $result | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        ($roundTrip.Conditions.ClientApplications.ExcludeAgentIdServicePrincipals -is [array]) | Should -BeTrue
    }

    It 'does not add agent properties to user policies or missing exclusions' {
        foreach ($json in @('{"Conditions":{"Users":{"ExcludeUsers":[]}}}', '{"Conditions":{"ClientApplications":null}}', '{"Conditions":{"ClientApplications":{"IncludeAgentIdServicePrincipals":"All"}}}')) {
            $policy = $json | ConvertFrom-Json
            $before = $policy | ConvertTo-Json -Depth 10
            $result = $policy | ConvertTo-AgentCapExclusionArray
            ($result | ConvertTo-Json -Depth 10) | Should -Be $before
        }
    }

    It 'rejects unexpected input rather than dropping exclusions' -ForEach @(
        @{ Raw = 42 }
        @{ Raw = 'not-an-object-id' }
        @{ Raw = @('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', $null) }
    ) {
        $policy = [pscustomobject]@{
            Id = 'test-policy'
            Conditions = [pscustomobject]@{
                ClientApplications = [pscustomobject]@{ ExcludeAgentIdServicePrincipals = $Raw }
            }
        }
        { $policy | ConvertTo-AgentCapExclusionArray } | Should -Throw '*test-policy*'
    }
}
