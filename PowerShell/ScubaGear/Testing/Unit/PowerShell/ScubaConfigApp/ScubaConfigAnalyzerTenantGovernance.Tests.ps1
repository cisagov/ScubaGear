Describe -Tag 'Analyzer' -Name 'ScubaConfigAnalyzer tenant governance configuration' {
    BeforeAll {
        $scubaGearRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $configAppRoot = Join-Path $scubaGearRoot 'Modules\ScubaConfigApp'
        $helperPath = Join-Path $configAppRoot 'ScubaConfigAnalyzerHelpers\ScubaConfigAnalyzerTenantGovernanceHelper.psm1'
        $controlPath = Join-Path $configAppRoot 'ScubaConfigAnalyzer_Control_en-US.json'
        $xamlPath = Join-Path $configAppRoot 'ScubaConfigAppResources\ScubaConfigAnalyzerUI.xaml'
        $policyStubPath = Join-Path $scubaGearRoot 'Testing\Unit\PowerShell\CreateReport\CreateReportStubs\ProviderSettingsExport.json'

        Import-Module $helperPath -Force
        $control = Get-Content $controlPath -Raw | ConvertFrom-Json
        # $script: scope so the It blocks (separate scriptblocks) can read these without tripping PSUseDeclaredVarsMoreThanAssignments.
        [xml]$script:xaml = Get-Content $xamlPath -Raw
        $policies = @(Get-Content $policyStubPath -Raw | ConvertFrom-Json | Select-Object -ExpandProperty conditional_access_policies)
        $script:document = ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies $policies -TenantId 'test-tenant' `
            -SchemaUrl $control.tenantGovernanceSchemaURL | ConvertFrom-Json
    }

    It 'is disabled by default and declares the UTCM schema URL' {
        $control.GenerateTenantGovernanceConfig | Should -BeFalse
        $control.tenantGovernanceSchemaURL | Should -Be 'https://www.schemastore.org/utcm-monitor.json'
    }

    It 'provides the feature-gated tab and its copy and export controls' {
        foreach ($name in @('TenantGovernanceTab', 'TenantGovernanceJson_TextBox', 'CopyTenantGovernance_Button', 'ExportTenantGovernance_Button')) {
            $xaml.SelectSingleNode("//*[@*[local-name()='Name']='$name']") | Should -Not -BeNullOrEmpty
        }
        $xaml.SelectSingleNode("//*[@*[local-name()='Name']='TenantGovernanceTab']").Visibility | Should -Be 'Collapsed'
    }

    It 'emits a flat baseline object with parameters as an array' {
        $document.PSObject.Properties.Name | Should -Not -Contain 'baseline'
        $document.PSObject.Properties.Name | Should -Contain 'resources'
        (Get-Content $policyStubPath -Raw | ConvertFrom-Json) | Out-Null
        $rawParameters = (ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies $policies -TenantId 'test-tenant' | ConvertFrom-Json).parameters
        ,$rawParameters | Should -BeOfType [System.Object[]]
    }

    It 'creates one Entra Conditional Access resource per collected policy' {
        @($document.resources).Count | Should -Be $policies.Count
        @($document.resources | Where-Object { $_.resourceType -ne 'microsoft.entra.conditionalaccesspolicy' }).Count | Should -Be 0
        @($document.resources | Where-Object { [string]::IsNullOrWhiteSpace($_.properties.DisplayName) }).Count | Should -Be 0
    }

    It 'preserves UTCM collection fields as arrays when a source policy has one value' {
        $singleValuePolicy = $document.resources | Where-Object { $_.properties.IncludeApplications.Count -eq 1 } | Select-Object -First 1
        $singleValuePolicy | Should -Not -BeNullOrEmpty
        ($singleValuePolicy.properties.IncludeApplications -is [array]) | Should -BeTrue
    }

    It 'declares the role/named-location lookup operations and resolves include + exclude group/role/user/app/location references' {
        $control.apiOperations.PSObject.Properties.Name | Should -Contain 'roleLookup'
        $control.apiOperations.PSObject.Properties.Name | Should -Contain 'namedLocationLookup'
        $lookupPaths = @($control.conditionalAccessAnalysis.displayNameLookup.rules | ForEach-Object { $_.policyPath })
        foreach ($p in @(
            'conditions.users.includeGroups', 'conditions.users.excludeGroups',
            'conditions.users.includeRoles', 'conditions.users.excludeRoles',
            'conditions.users.includeUsers', 'conditions.users.excludeUsers',
            'conditions.applications.includeApplications', 'conditions.applications.excludeApplications',
            'conditions.locations.includeLocations', 'conditions.locations.excludeLocations')) {
            $lookupPaths | Should -Contain $p
        }
    }

    It 'emits AuthenticationStrength as the display name, not the id' {
        $policy = [pscustomobject]@{
            DisplayName   = 'CA-PhishResistant'
            Id            = '11111111-1111-1111-1111-111111111111'
            State         = 'enabled'
            GrantControls = [pscustomobject]@{
                Operator               = 'OR'
                AuthenticationStrength = [pscustomobject]@{
                    Id          = '00000000-0000-0000-0000-000000000004'
                    DisplayName = 'Phishing-resistant MFA'
                }
            }
        }
        $doc = ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies @($policy) -TenantId 't' | ConvertFrom-Json
        ($doc.resources | Where-Object { $_.properties.DisplayName -eq 'CA-PhishResistant' }).properties.AuthenticationStrength |
            Should -Be 'Phishing-resistant MFA'
    }

    It 'falls back to the AuthenticationStrength id when the policy has no strength display name' {
        $policy = [pscustomobject]@{
            DisplayName   = 'CA-NoStrengthName'
            Id            = '22222222-2222-2222-2222-222222222222'
            State         = 'enabled'
            GrantControls = [pscustomobject]@{
                AuthenticationStrength = [pscustomobject]@{
                    Id          = '00000000-0000-0000-0000-000000000004'
                    DisplayName = $null
                }
            }
        }
        $doc = ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies @($policy) -TenantId 't' | ConvertFrom-Json
        ($doc.resources | Where-Object { $_.properties.DisplayName -eq 'CA-NoStrengthName' }).properties.AuthenticationStrength |
            Should -Be '00000000-0000-0000-0000-000000000004'
    }

    It 'emits users by UPN and groups/roles/apps/locations by display name' {
        $policy = [pscustomobject]@{
            DisplayName = 'CA-Refs'
            Id          = '33333333-3333-3333-3333-333333333333'
            State       = 'enabled'
            Conditions  = [pscustomobject]@{
                Applications = [pscustomobject]@{
                    IncludeApplications = @('All')
                    ExcludeApplications = @('44444444-4444-4444-4444-444444444444')
                }
                Users        = [pscustomobject]@{
                    IncludeUsers  = @('All')
                    ExcludeUsers  = @('55555555-5555-5555-5555-555555555555')
                    IncludeGroups = @('66666666-6666-6666-6666-666666666666')
                    ExcludeGroups = @('77777777-7777-7777-7777-777777777777')
                    IncludeRoles  = @('88888888-8888-8888-8888-888888888888')
                }
                Locations    = [pscustomobject]@{
                    IncludeLocations = @('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1')
                    ExcludeLocations = @('AllTrusted')
                }
            }
        }
        $names = @{
            '44444444-4444-4444-4444-444444444444' = 'My App'
            '55555555-5555-5555-5555-555555555555' = 'Break Glass Account'   # display name - must NOT win for users
            '66666666-6666-6666-6666-666666666666' = 'All Employees'
            '77777777-7777-7777-7777-777777777777' = 'Exclude Group'
            '88888888-8888-8888-8888-888888888888' = 'Global Administrator'
            'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1' = 'Corporate Network'
        }
        $upns = @{ '55555555-5555-5555-5555-555555555555' = 'breakglass@contoso.com' }
        $doc = ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies @($policy) -TenantId 't' -DisplayNameLookup $names -UserPrincipalNameLookup $upns | ConvertFrom-Json
        $res = $doc.resources | Where-Object { $_.properties.DisplayName -eq 'CA-Refs' }
        $res.properties.ExcludeUsers        | Should -Be 'breakglass@contoso.com'   # UPN, not display name
        $res.properties.ExcludeApplications | Should -Be 'My App'
        $res.properties.IncludeGroups       | Should -Be 'All Employees'
        $res.properties.ExcludeGroups       | Should -Be 'Exclude Group'
        $res.properties.IncludeRoles        | Should -Be 'Global Administrator'
        $res.properties.IncludeLocations    | Should -Be 'Corporate Network'
        $res.properties.ExcludeLocations    | Should -Be 'AllTrusted'   # non-id literals are preserved
        $res.properties.IncludeUsers        | Should -Be 'All'          # non-id literals are preserved
    }

    It 'falls back to display name for a user with no UPN entry, and keeps the id when unresolved' {
        $policy = [pscustomobject]@{
            DisplayName = 'CA-UserFallback'
            Id          = 'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2'
            State       = 'enabled'
            Conditions  = [pscustomobject]@{
                Users = [pscustomobject]@{
                    ExcludeUsers = @('cccccccc-cccc-cccc-cccc-cccccccccccc', 'dddddddd-dddd-dddd-dddd-dddddddddddd')
                }
            }
        }
        $names = @{ 'cccccccc-cccc-cccc-cccc-cccccccccccc' = 'Named User' }
        $doc = ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies @($policy) -TenantId 't' -DisplayNameLookup $names -UserPrincipalNameLookup @{} | ConvertFrom-Json
        $res = $doc.resources | Where-Object { $_.properties.DisplayName -eq 'CA-UserFallback' }
        @($res.properties.ExcludeUsers) | Should -Contain 'Named User'
        @($res.properties.ExcludeUsers) | Should -Contain 'dddddddd-dddd-dddd-dddd-dddddddddddd'
    }

    It 'leaves object ids unchanged when the lookup has no matching entry' {
        $policy = [pscustomobject]@{
            DisplayName = 'CA-Unresolved'
            Id          = '99999999-9999-9999-9999-999999999999'
            State       = 'enabled'
            Conditions  = [pscustomobject]@{
                Users = [pscustomobject]@{
                    ExcludeGroups = @('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
                }
            }
        }
        $doc = ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies @($policy) -TenantId 't' -DisplayNameLookup @{} | ConvertFrom-Json
        ($doc.resources | Where-Object { $_.properties.DisplayName -eq 'CA-Unresolved' }).properties.ExcludeGroups |
            Should -Be 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    }

    It 'emits every policy when no IncludePolicyId filter is supplied' {
        $policies = @(
            [pscustomobject]@{ DisplayName = 'P1'; Id = 'id-1'; State = 'enabled' }
            [pscustomobject]@{ DisplayName = 'P2'; Id = 'id-2'; State = 'enabled' }
        )
        $doc = ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies $policies -TenantId 't' | ConvertFrom-Json
        @($doc.resources).Count | Should -Be 2
    }

    It 'scopes the document to the supplied policy ids (case-insensitive)' {
        $policies = @(
            [pscustomobject]@{ DisplayName = 'P1'; Id = 'AAA-111'; State = 'enabled' }
            [pscustomobject]@{ DisplayName = 'P2'; Id = 'BBB-222'; State = 'enabled' }
            [pscustomobject]@{ DisplayName = 'P3'; Id = 'CCC-333'; State = 'enabled' }
        )
        $doc = ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies $policies -TenantId 't' -IncludePolicyId @('aaa-111', 'CCC-333') | ConvertFrom-Json
        @($doc.resources).Count | Should -Be 2
        @($doc.resources.properties.DisplayName) | Should -Contain 'P1'
        @($doc.resources.properties.DisplayName) | Should -Contain 'P3'
        @($doc.resources.properties.DisplayName) | Should -Not -Contain 'P2'
    }

    It 'collects the best-match (identified) policy id from each finding, excluding other candidates' {
        $findings = @(
            [pscustomobject]@{
                AllPolicies      = @([pscustomobject]@{ Id = 'p-a' }, [pscustomobject]@{ Id = 'p-b' })
                BestMatch        = [pscustomobject]@{ Id = 'p-a' }
                SelectedPolicyId = 'p-a'
            }
            [pscustomobject]@{
                AllPolicies      = @([pscustomobject]@{ Id = 'p-c' })
                BestMatch        = [pscustomobject]@{ Id = 'p-c' }
                SelectedPolicyId = 'p-c'
            }
            [pscustomobject]@{
                AllPolicies      = @([pscustomobject]@{ Id = 'p-d' })
                BestMatch        = $null
                SelectedPolicyId = $null
            }
        )
        $ids = @(Get-ScATenantGovernanceMatchedPolicyId -Findings $findings)
        $ids.Count | Should -Be 2
        $ids | Should -Contain 'p-a'
        $ids | Should -Contain 'p-c'
        $ids | Should -Not -Contain 'p-b'   # relevant-but-not-best candidates are excluded
        $ids | Should -Not -Contain 'p-d'   # findings with no match contribute nothing
    }

    It 'provides the ScubaGear-only checkbox on the tenant governance tab' {
        $xaml.SelectSingleNode("//*[@*[local-name()='Name']='TenantGovernanceScubaOnly_CheckBox']") | Should -Not -BeNullOrEmpty
        $control.localeContext.TenantGovernanceScubaOnly_CheckBox | Should -Not -BeNullOrEmpty
    }
}
