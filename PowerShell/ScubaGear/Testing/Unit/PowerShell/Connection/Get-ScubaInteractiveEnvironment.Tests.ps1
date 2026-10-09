$ConnectionPath = Join-Path $PSScriptRoot '..\..\..\..\Modules\Connection\Connection.psm1'
Import-Module $ConnectionPath -Force

InModuleScope Connection {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\..\Modules\Permissions\PermissionsHelper.psm1') -Force
    Describe 'Get-ScubaInteractiveEnvironment' {
        BeforeEach {
            $script:DiscoveryTenantId = '305102d0-7ccc-4007-83bb-ac1f44f8d620'
            $script:DiscoveryHost = 'login.microsoftonline.com'
            $script:MetadataEnvironment = 'commercial'
            Mock Get-MsalAccessToken {
                [pscustomobject]@{
                    TenantId = $script:DiscoveryTenantId
                    Account = [pscustomobject]@{ Environment = $script:DiscoveryHost }
                }
            }
            Mock Get-M365EnvironmentByDomain { $script:MetadataEnvironment }
        }

        It 'detects <Environment> without requesting a tenant hint' -TestCases @(
            @{ Environment = 'commercial'; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcc'; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcchigh'; HostName = 'login.microsoftonline.us' },
            @{ Environment = 'dod'; HostName = 'login.microsoftonline.us' }
        ) {
            param($Environment, $HostName)
            $script:DiscoveryHost = $HostName
            $script:MetadataEnvironment = $Environment

            $Result = Get-ScubaInteractiveEnvironment -Scopes @('Organization.Read.All')

            $Result.M365Environment | Should -Be $Environment
            $Result.TenantId | Should -Be $script:DiscoveryTenantId
            Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter {
                $MultiCloudSupport -and $PassThru -and $Tenant -eq 'organizations' -and
                $ClientId -eq '14d82eec-204b-4c2f-b7e8-296a70dab67e'
            }
            Should -Invoke Get-M365EnvironmentByDomain -Times 1 -Exactly -ParameterFilter {
                $AuthorityHost -eq $script:DiscoveryHost -and $TenantDomain -eq $script:DiscoveryTenantId
            }
        }

        It 'rejects an absent or invalid tenant ID before fetching metadata' -TestCases @(
            @{ TenantValue = $null }, @{ TenantValue = 'invalid' }, @{ TenantValue = [guid]::Empty.ToString() }
        ) {
            param($TenantValue)
            $script:DiscoveryTenantId = $TenantValue
            { Get-ScubaInteractiveEnvironment -Scopes @('Organization.Read.All') } | Should -Throw '*valid tenant ID*'
            Should -Invoke Get-M365EnvironmentByDomain -Times 0 -Exactly
        }

        It 'rejects unsupported cloud hosts' {
            $script:DiscoveryHost = 'unexpected.example'
            { Get-ScubaInteractiveEnvironment -Scopes @('Organization.Read.All') } | Should -Throw '*unsupported authority*'
            Should -Invoke Get-M365EnvironmentByDomain -Times 0 -Exactly
        }

        It 'rejects a cloud and tenant-metadata mismatch' {
            $script:DiscoveryHost = 'login.microsoftonline.us'
            { Get-ScubaInteractiveEnvironment -Scopes @('Organization.Read.All') } | Should -Throw '*does not match*'
        }

        It 'propagates metadata failures rather than defaulting to commercial' {
            Mock Get-M365EnvironmentByDomain { throw 'Metadata unavailable' }
            { Get-ScubaInteractiveEnvironment -Scopes @('Organization.Read.All') } | Should -Throw '*Metadata unavailable*'
        }
    }

    Describe 'Get-M365EnvironmentByDomain' {
        It 'maps tenant metadata to <Environment> at the appropriate authority' -TestCases @(
            @{ Environment = 'commercial'; Region = 'NA'; SubScope = $null; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'commercial'; Region = 'EU'; SubScope = $null; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcc'; Region = 'NA'; SubScope = 'GCC'; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcchigh'; Region = 'USGov'; SubScope = 'DODCON'; HostName = 'login.microsoftonline.us' },
            @{ Environment = 'dod'; Region = 'USGov'; SubScope = 'DOD'; HostName = 'login.microsoftonline.us' }
        ) {
            param($Environment, $Region, $SubScope, $HostName)
            $script:Region = $Region
            $script:SubScope = $SubScope
            Mock Invoke-RestMethod {
                [pscustomobject]@{ tenant_region_scope = $script:Region; tenant_region_sub_scope = $script:SubScope }
            }

            Get-M365EnvironmentByDomain -TenantDomain 'tenant-id' -AuthorityHost $HostName | Should -Be $Environment
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -eq "https://$HostName/tenant-id/.well-known/openid-configuration"
            }
        }

        It 'rejects missing or unsupported metadata' -TestCases @(
            @{ Region = $null; SubScope = $null },
            @{ Region = 'USGov'; SubScope = $null },
            @{ Region = 'USGov'; SubScope = 'unknown' }
        ) {
            param($Region, $SubScope)
            $script:Region = $Region
            $script:SubScope = $SubScope
            Mock Invoke-RestMethod {
                [pscustomobject]@{ tenant_region_scope = $script:Region; tenant_region_sub_scope = $script:SubScope }
            }
            { Get-M365EnvironmentByDomain -TenantDomain 'tenant-id' } | Should -Throw
        }
    }

    Describe 'Connect-Tenant environment discovery' {
        BeforeEach {
            Mock Disconnect-ScubaGraph {}
            Mock Get-ScubaInteractiveEnvironment {
                [pscustomobject]@{
                    M365Environment = 'gcchigh'
                    TenantId = '305102d0-7ccc-4007-83bb-ac1f44f8d620'
                }
            }
            Mock Connect-GraphHelper {}
            Mock Get-ScubaGearEntraMinimumPermissions { @('Organization.Read.All') }
            Mock Write-Progress {}
        }

        It 'establishes Graph only once with the detected cloud and tenant' {
            $Result = Connect-Tenant -ProductNames aad
            $Result.DetectedM365Environment | Should -Be 'gcchigh'
            $Result.ProdAuthFailed | Should -BeNullOrEmpty
            Should -Invoke Connect-GraphHelper -Times 1 -Exactly -ParameterFilter {
                $M365Environment -eq 'gcchigh' -and $TenantId -eq '305102d0-7ccc-4007-83bb-ac1f44f8d620'
            }
        }

        It 'preserves explicit environment settings and bypasses discovery' {
            $Result = Connect-Tenant -ProductNames aad -M365Environment gcc
            $Result.DetectedM365Environment | Should -BeNullOrEmpty
            Should -Invoke Get-ScubaInteractiveEnvironment -Times 0 -Exactly
            Should -Invoke Connect-GraphHelper -Times 1 -Exactly -ParameterFilter { $M365Environment -eq 'gcc' }
        }

        It 'stops before product authentication when discovery fails' {
            Mock Get-ScubaInteractiveEnvironment { throw 'Cloud discovery failed' }
            { Connect-Tenant -ProductNames aad } | Should -Throw '*Cloud discovery failed*'
            Should -Invoke Connect-GraphHelper -Times 0 -Exactly
        }
    }
}

AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
}
