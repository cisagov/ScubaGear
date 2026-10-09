BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Utility' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'Utility.psm1') -Force
}

InModuleScope Utility {
    # Each fixed endpoint path is pinned here, the same way Invoke-GraphDirectly.Tests.ps1 pins every
    # Graph URL, so an edit to the catalog JSON that changes a path fails a test instead of the live call.
    $EndpointCases = @(
        @{ FunctionName = 'Get-SPOTenantRest';                         Expected = '/_api/SPO.Tenant' }
        @{ FunctionName = 'Get-PowerPlatformTenantSettingsRest';       Expected = '/providers/Microsoft.BusinessAppPlatform/listTenantSettings?api-version=2023-06-01' }
        @{ FunctionName = 'Get-PowerPlatformEnvironmentsRest';         Expected = '/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments?api-version=2023-06-01' }
        @{ FunctionName = 'Get-PowerPlatformDlpPoliciesRest';          Expected = '/providers/Microsoft.BusinessAppPlatform/scopes/admin/apiPolicies?api-version=2016-11-01' }
        @{ FunctionName = 'Get-TeamsMeetingPolicyRest';                Expected = '/Skype.Policy/configurations/TeamsMeetingPolicy' }
        @{ FunctionName = 'Get-TeamsTenantFederationConfigurationRest'; Expected = '/Skype.Policy/configurations/TenantFederationSettings' }
        @{ FunctionName = 'Get-TeamsClientConfigurationRest';          Expected = '/Skype.Policy/configurations/TeamsClientConfiguration' }
        @{ FunctionName = 'Get-TeamsAppPermissionPolicyRest';          Expected = '/Skype.Policy/configurations/TeamsAppPermissionPolicy' }
        @{ FunctionName = 'Get-TeamsMeetingBroadcastPolicyRest';       Expected = '/Skype.Policy/configurations/TeamsMeetingBroadcastPolicy' }
        @{ FunctionName = 'Get-TeamsM365UnifiedTenantSettingsRest';    Expected = '/AdminAppCatalog/ps/v2/admin/unifiedApp/settings' }
        @{ FunctionName = 'Get-PowerBITenantSettingsRest';             Expected = '/v1/admin/tenantsettings' }
    )

    # Every function name that production code passes to Get-ScubaGearRestEndpoint, so a new helper
    # added without a catalog entry fails here rather than at runtime.
    $ModulesRoot = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules' -Resolve
    $CallerCases = Get-ChildItem -Path $ModulesRoot -Include '*.psm1', '*.ps1' -Recurse -File |
        Where-Object { $_.Name -ne 'Utility.psm1' } |
        Select-String -Pattern "Get-ScubaGearRestEndpoint\s+-FunctionName\s+'([^']+)'" |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Sort-Object -Unique |
        ForEach-Object { @{ FunctionName = $_ } }

    Describe -Tag 'PermissionsHelper' -Name 'Get-ScubaGearRestEndpoint' {

        Context 'Fixed endpoint paths' {
            It 'returns <Expected> for <FunctionName>' -TestCases $EndpointCases {
                param($FunctionName, $Expected)
                Get-ScubaGearRestEndpoint -FunctionName $FunctionName | Should -BeExactly $Expected
            }
        }

        Context 'Path parameter substitution' {
            It 'substitutes {TenantId} in the tenant isolation endpoint' {
                $TenantId = '11111111-2222-3333-4444-555555555555'
                $Result = Get-ScubaGearRestEndpoint -FunctionName 'Get-PowerPlatformTenantIsolationRest' -PathParameters @{ TenantId = $TenantId }
                $Result | Should -BeExactly "/providers/PowerPlatform.Governance/v1/tenants/$TenantId/tenantIsolationPolicy?api-version=2020-06-01"
            }

            It 'leaves the {TenantId} placeholder in place when no PathParameters are supplied' {
                Get-ScubaGearRestEndpoint -FunctionName 'Get-PowerPlatformTenantIsolationRest' |
                    Should -BeExactly '/providers/PowerPlatform.Governance/v1/tenants/{TenantId}/tenantIsolationPolicy?api-version=2020-06-01'
            }

            It 'ignores PathParameters that have no matching placeholder' {
                Get-ScubaGearRestEndpoint -FunctionName 'Get-SPOTenantRest' -PathParameters @{ TenantId = 'unused' } |
                    Should -BeExactly '/_api/SPO.Tenant'
            }
        }

        Context 'Invalid function names' {
            It 'throws when the function has no catalog entry' {
                { Get-ScubaGearRestEndpoint -FunctionName 'Get-DoesNotExistRest' } |
                    Should -Throw "*No REST API * entry found for function 'Get-DoesNotExistRest'*"
            }

            It 'throws for a dynamic endpoint that is not stored in the catalog' {
                # Get-ExchangeOnlineApiEndpoint is resolved per tenant, so it has no catalog entry.
                { Get-ScubaGearRestEndpoint -FunctionName 'Get-ExchangeOnlineApiEndpoint' } |
                    Should -Throw "*No REST API * entry found for function 'Get-ExchangeOnlineApiEndpoint'*"
            }

            It 'is case-insensitive on the function name, matching PowerShell conventions' {
                Get-ScubaGearRestEndpoint -FunctionName 'get-spotenantrest' | Should -BeExactly '/_api/SPO.Tenant'
            }
        }

        Context 'Production callers' {
            It 'has a fixed endpointPath for <FunctionName>, which production code requests' -TestCases $CallerCases {
                { Get-ScubaGearRestEndpoint -FunctionName $FunctionName } | Should -Not -Throw
            }

            It 'pins every endpoint path that production code requests' {
                $Pinned = $EndpointCases | ForEach-Object { $_.FunctionName }
                $Pinned += 'Get-PowerPlatformTenantIsolationRest'
                $Unpinned = $CallerCases | ForEach-Object { $_.FunctionName } | Where-Object { $_ -notin $Pinned }
                $Unpinned | Should -BeNullOrEmpty -Because 'each endpoint path should have an expected value in the table above'
            }
        }
    }
}

AfterAll {
    Remove-Module Utility -ErrorAction SilentlyContinue
}
