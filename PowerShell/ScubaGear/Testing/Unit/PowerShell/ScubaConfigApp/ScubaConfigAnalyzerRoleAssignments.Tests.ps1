Describe -Tag 'Analyzer' -Name 'MS.AAD.7.4v1 privileged role assignments' {
    BeforeAll {
        $script:root = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $helpers = Join-Path $root 'Modules\ScubaConfigApp\ScubaConfigAnalyzerHelpers'
        foreach ($file in Get-ChildItem $helpers -Filter '*.psm1') { Import-Module $file.FullName -Force }
        $script:state = [hashtable]::Synchronized(@{})
        foreach ($file in Get-ChildItem $helpers -Filter '*.psm1') {
            & (Get-Module $file.BaseName) { param($State) $script:syncHash = $State } $state
        }
        $script:paths = @{
            BaselineSchemaPath  = Join-Path $root 'schemas\ScubaGearResultsBaselineSchema.json'
            AnalyzerControlPath = Join-Path $root 'Modules\ScubaConfigApp\ScubaConfigAnalyzer_Control_en-US.json'
            ConfigSchemaPath    = Join-Path $root 'schemas\ScubaConfigSchema.json'
        }

        function New-RoleAssignmentResult {
            param($Raw, [string]$Result = 'Fail', [string]$Details = '3 role(s) that contain users with permanent active assignment: Global Administrator')
            $resultsFile = Join-Path $TestDrive ("aad74-{0}.json" -f [guid]::NewGuid().ToString('n'))
            @{
                MetaData = @{ DisplayName = 'Test'; DomainName = 'test.onmicrosoft.com'; TenantId = 'tid' }
                Summary  = @{ AAD = @{ Passes = 0; Failures = 1; Warnings = 0; Errors = 0; Manual = 0 } }
                Results  = @{ AAD = @(@{ GroupName = 'Privileged Identity Management'; Controls = @(@{
                    'Control ID' = 'MS.AAD.7.4v1'
                    Requirement  = 'Permanent active role assignments SHALL NOT be allowed for highly privileged roles.'
                    Result       = $Result
                    Details      = $Details
                }) }) }
                Raw = $Raw
            } | ConvertTo-Json -Depth 8 | Set-Content $resultsFile -Encoding utf8
            $analysis = Invoke-ScubaConfigAnalysis -ResultsPath $resultsFile -Product aad @paths
            @($analysis.Findings | Where-Object ControlId -EQ 'MS.AAD.7.4v1')[0]
        }

        function New-PrivilegedRaw {
            param([bool]$PimGroupEnrolled)
            $role = @{
                DisplayName = 'Global Administrator'
                Assignments = @(
                    @{ PrincipalId = 'user-permanent'; EndDateTime = $null }
                    @{ PrincipalId = 'user-expiring'; EndDateTime = '2027-06-01T00:00:00Z' }
                    @{ PrincipalId = 'group-1'; EndDateTime = $null }
                    @{ PrincipalId = 'sp-1'; EndDateTime = $null }
                )
            }
            if ($PimGroupEnrolled) {
                $role.Rules = @(@{ RuleSource = 'PIM Admins'; RuleSourceType = 'PIM Group' })
            }
            @{
                privileged_users = @{
                    'user-permanent' = @{ DisplayName = 'Break Glass' }
                    'user-expiring'  = @{ DisplayName = 'Admin' }
                }
                privileged_service_principals = @{
                    'sp-1' = @{ DisplayName = 'Sync Account' }
                }
                privileged_roles = @($role)
            }
        }
    }

    It 'does not recommend a Conditional Access policy when imported results have no role data' {
        $finding = New-RoleAssignmentResult -Raw @{}
        $finding.Result | Should -Be 'Fail'
        $finding.RequiresAction | Should -Not -Be 'CREATE_POLICY'
        $finding.RootCause | Should -Match 'not Conditional Access'
        $finding.RootCause | Should -Not -Match 'create a new one'
        ($finding.Recommendations -join ' ') | Should -Match 'PIM'
        ($finding.Recommendations -join ' ') | Should -Match 'PIM for Groups'
        ($finding.Recommendations -join ' ') | Should -Match 'do not assume every group'
        $finding.ExclusionField | Should -Be 'RoleExclusions'
        ($finding.RemediationSteps -join ' ') | Should -Match 'PIM for Groups'
    }

    It 'lists permanent users and service principals under Users, and other principals as groups that still need PIM enrollment checked' {
        $finding = New-RoleAssignmentResult -Raw (New-PrivilegedRaw -PimGroupEnrolled $true)
        $finding.RequiresAction | Should -Be 'FIX_TENANT'
        $finding.ConfigAction | Should -Be 'EXCLUDE'
        $finding.RootCause | Should -Match 'Global Administrator'
        $finding.RootCause | Should -Match 'not Conditional Access'
        $finding.RootCause | Should -Not -Match 'Conditional Access policy'
        @($finding.DetectedExclusionValues['Users']) | Should -Contain 'user-permanent'
        @($finding.DetectedExclusionValues['Users']) | Should -Contain 'sp-1'
        @($finding.DetectedExclusionValues['Users']) | Should -Not -Contain 'user-expiring'
        @($finding.DetectedExclusionValues['Groups']) | Should -Be @('group-1')
        $joined = $finding.Recommendations -join ' '
        $joined | Should -Match 'PIM Admins'
        $joined | Should -Match 'Confirm each group'
        $joined | Should -Match 'Sync Account'
        $finding.YamlBlock | Should -Match 'user-permanent'
        $finding.YamlBlock | Should -Match 'group-1'
        $finding.YamlBlock | Should -Not -Match 'user-expiring'
    }

    It 'does not treat an unmatched group as enrolled in PIM for Groups' {
        $finding = New-RoleAssignmentResult -Raw (New-PrivilegedRaw -PimGroupEnrolled $false)
        ($finding.Recommendations -join ' ') | Should -Match 'do not show PIM for Groups enrollment'
        ($finding.Recommendations -join ' ') | Should -Not -Match 'Confirm each group'
    }

    It 'gives a live scan the same role-assignment guidance and RoleExclusions' {
        $withData = Invoke-ScubaTenantScan -Product aad -TenantData (New-PrivilegedRaw -PimGroupEnrolled $true) @paths
        $finding = @($withData.Findings | Where-Object ControlId -EQ 'MS.AAD.7.4v1')[0]
        $finding.Result | Should -Be 'Fail'
        $finding.RequiresAction | Should -Be 'FIX_TENANT'
        $finding.ConfigAction | Should -Be 'EXCLUDE'
        $finding.RootCause | Should -Not -Match 'Conditional Access policy'
        $finding.ExclusionField | Should -Be 'RoleExclusions'
        @($finding.DetectedExclusionValues['Users']) | Should -Contain 'user-permanent'
        @($finding.DetectedExclusionValues['Groups']) | Should -Be @('group-1')

        $withoutData = Invoke-ScubaTenantScan -Product aad -TenantData @{} @paths
        $manual = @($withoutData.Findings | Where-Object ControlId -EQ 'MS.AAD.7.4v1')[0]
        $manual.Result | Should -Be 'Manual'
        $manual.RequiresAction | Should -Not -Be 'CREATE_POLICY'
        $manual.RootCause | Should -Match 'not Conditional Access'
        $manual.ExclusionField | Should -Be 'RoleExclusions'
        ($manual.Recommendations -join ' ') | Should -Match 'PIM for Groups'
    }
}
