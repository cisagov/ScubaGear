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

        function Copy-ScATestValue {
            param($Value, [string]$NullSentinel)
            if ($null -eq $Value) { return $NullSentinel }
            if ($Value -is [string] -or $Value -is [ValueType]) { return $Value }
            if ($Value -is [System.Collections.IDictionary]) {
                $copy = @{}
                foreach ($key in @($Value.Keys)) {
                    $copy[$key] = Copy-ScATestValue -Value $Value[$key] -NullSentinel $NullSentinel
                }
                return $copy
            }
            if ($Value -is [System.Collections.IEnumerable]) {
                $items = [System.Collections.Generic.List[object]]::new()
                foreach ($item in @($Value)) {
                    $items.Add((Copy-ScATestValue -Value $item -NullSentinel $NullSentinel))
                }
                return $items.ToArray()
            }
            return $Value
        }

        function New-RoleAssignmentResult {
            param(
                $Raw,
                [string]$Result = 'Fail',
                [string]$Details = '3 role(s) that contain users with permanent active assignment: Global Administrator',
                [string]$ControlId = 'MS.AAD.7.4v1',
                [string]$Requirement = 'Permanent active role assignments SHALL NOT be allowed for highly privileged roles.'
            )
            $resultsFile = Join-Path $TestDrive ("aad74-{0}.json" -f [guid]::NewGuid().ToString('n'))
            # Windows PowerShell ConvertTo-Json omits $null properties. Rego matches an explicit
            # JSON null, so the results file has to keep EndDateTime: null.
            $sentinel = '___SCA_JSON_NULL___'
            $document = @{
                MetaData = @{ DisplayName = 'Test'; DomainName = 'test.onmicrosoft.com'; TenantId = 'tid' }
                Summary  = @{ AAD = @{ Passes = 0; Failures = 1; Warnings = 0; Errors = 0; Manual = 0 } }
                Results  = @{ AAD = @(@{ GroupName = 'Privileged Identity Management'; Controls = @(@{
                    'Control ID' = $ControlId
                    Requirement  = $Requirement
                    Result       = $Result
                    Details      = $Details
                }) }) }
                Raw = $Raw
            }
            $json = (Copy-ScATestValue -Value $document -NullSentinel $sentinel | ConvertTo-Json -Depth 8).Replace(('"' + $sentinel + '"'), 'null')
            Set-Content -Path $resultsFile -Value $json -Encoding utf8
            $analysis = Invoke-ScubaConfigAnalysis -ResultsPath $resultsFile -Product aad @paths
            @($analysis.Findings | Where-Object ControlId -EQ $ControlId)[0]
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

    It 'keeps an imported command error as a permission check when role data is missing' {
        $finding = New-RoleAssignmentResult -Raw @{} -Result 'Error' -Details 'Error running Get-PrivilegedRole'
        $finding.Result | Should -Be 'Error'
        $finding.RequiresAction | Should -Be 'CHECK_PERMISSIONS'
        $finding.ConfigAction | Should -Be 'REVIEW'
        $finding.RootCause | Should -Be 'Command execution error'
        ($finding.Recommendations -join ' ') | Should -Match 'Microsoft Graph permissions'
        ($finding.Recommendations -join ' ') | Should -Not -Match 'RoleExclusions'
        [string]$finding.YamlBlock | Should -Not -Match 'RoleExclusions:'
    }

    It 'keeps imported N/A and Omitted results as manual review' {
        foreach ($status in @('N/A', 'Omitted')) {
            $finding = New-RoleAssignmentResult -Raw @{} -Result $status -Details $status
            $finding.Result | Should -Be $status
            $finding.RequiresAction | Should -Be 'REVIEW'
            $finding.ConfigAction | Should -Be 'REVIEW'
            $finding.RootCause | Should -Be 'Manual review required'
        }
    }

    It 'keeps an ordinary unimplemented N/A control as manual review' {
        $finding = New-RoleAssignmentResult -Raw @{} -Result 'N/A' -ControlId 'MS.AAD.2.2v1' -Requirement 'A notification SHOULD be sent to the administrator when high-risk users are detected' -Details 'N/A'
        $finding.Result | Should -Be 'N/A'
        $finding.RequiresAction | Should -Be 'REVIEW'
        $finding.ConfigAction | Should -Be 'REVIEW'
        $finding.RootCause | Should -Be 'Manual review required'
    }

    It 'offers RoleExclusions only when EndDateTime is JSON null, matching the Rego policy' {
        $raw = @{
            privileged_users = @{
                'user-null'       = @{ DisplayName = 'Permanent' }
                'user-missing'    = @{ DisplayName = 'Missing End' }
                'user-blank'      = @{ DisplayName = 'Blank End' }
                'user-whitespace' = @{ DisplayName = 'Whitespace End' }
            }
            privileged_roles = @(@{
                DisplayName = 'Global Administrator'
                Assignments = @(
                    @{ PrincipalId = 'user-null'; EndDateTime = $null }
                    @{ PrincipalId = 'user-missing' }
                    @{ PrincipalId = 'user-blank'; EndDateTime = '' }
                    @{ PrincipalId = 'user-whitespace'; EndDateTime = '   ' }
                )
            })
        }
        $direct = Get-ScAPrivilegedRoleAssignmentAnalysis -Raw $raw
        @($direct.ExclusionValues['Users']) | Should -Be @('user-null')

        $finding = New-RoleAssignmentResult -Raw $raw
        @($finding.DetectedExclusionValues['Users']) | Should -Be @('user-null')
        $finding.YamlBlock | Should -Match 'user-null'
        $finding.YamlBlock | Should -Not -Match 'user-missing'
        $finding.YamlBlock | Should -Not -Match 'user-blank'
        $finding.YamlBlock | Should -Not -Match 'user-whitespace'
    }
}
