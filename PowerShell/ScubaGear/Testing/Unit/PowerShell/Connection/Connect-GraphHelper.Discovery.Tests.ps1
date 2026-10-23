[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Exercise discovery with and without an existing Graph session.')]
param()
$ConnectionPath = Join-Path $PSScriptRoot '..\..\..\..\Modules\Connection\Connection.psm1'
Import-Module $ConnectionPath -Force

InModuleScope ConnectHelpers {
    Describe 'Connect-GraphHelper discovery' {
        BeforeEach {
            $Global:ScubaGearState.Session = $null
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

        AfterEach { Disconnect-ScubaGraph }

        It 'detects <Environment> without requesting a tenant hint' -TestCases @(
            @{ Environment = 'commercial'; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcc'; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcchigh'; HostName = 'login.microsoftonline.us' },
            @{ Environment = 'dod'; HostName = 'login.microsoftonline.us' }
        ) {
            param($Environment, $HostName)
            $script:DiscoveryHost = $HostName
            $script:MetadataEnvironment = $Environment

            Connect-GraphHelper -Discovery -Scopes @('Organization.Read.All')
            $Result = $Global:ScubaGearState.Session

            $Result.M365Environment | Should -Be $Environment
            $Result.TokenParameters.Tenant | Should -Be $script:DiscoveryTenantId
            Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter {
                $ForCloudDiscovery -and $PassThru -and $Tenant -eq 'organizations' -and
                $ClientId -eq '14d82eec-204b-4c2f-b7e8-296a70dab67e'
            }
            Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter {
                -not $ForCloudDiscovery -and $PassThru -and $Tenant -eq $script:DiscoveryTenantId -and
                $M365Environment -eq $script:MetadataEnvironment -and
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
            { Connect-GraphHelper -Discovery } | Should -Throw '*valid tenant ID*'
            $Global:ScubaGearState.Session | Should -BeNullOrEmpty
            Should -Invoke Get-M365EnvironmentByDomain -Times 0 -Exactly
        }

        It 'rejects unsupported cloud hosts' {
            $script:DiscoveryHost = 'unexpected.example'
            { Connect-GraphHelper -Discovery } | Should -Throw '*unsupported authority*'
            Should -Invoke Get-M365EnvironmentByDomain -Times 0 -Exactly
        }

        It 'rejects a cloud and tenant-metadata mismatch' {
            $script:DiscoveryHost = 'login.microsoftonline.us'
            { Connect-GraphHelper -Discovery } | Should -Throw '*does not match*'
        }

        It 'propagates metadata failures rather than defaulting to commercial' {
            Mock Get-M365EnvironmentByDomain { throw 'Metadata unavailable' }
            { Connect-GraphHelper -Discovery } | Should -Throw '*Metadata unavailable*'
        }

        It 'preserves the previous session if <Stage> fails (existing session: <ExistingSession>)' -TestCases @(
            @{ Stage = 'discovery'; ExistingSession = $false },
            @{ Stage = 'discovery'; ExistingSession = $true },
            @{ Stage = 'metadata'; ExistingSession = $false },
            @{ Stage = 'metadata'; ExistingSession = $true },
            @{ Stage = 'tenant authentication'; ExistingSession = $false },
            @{ Stage = 'tenant authentication'; ExistingSession = $true }
        ) {
            param($Stage, $ExistingSession)
            $script:PreviousSession = if ($ExistingSession) { @{ Account = 'previous-account' } } else { $null }
            $Global:ScubaGearState.Session = $script:PreviousSession
            if ($Stage -eq 'discovery') {
                Mock Get-MsalAccessToken { throw 'Discovery failed' }
            }
            elseif ($Stage -eq 'metadata') {
                Mock Get-M365EnvironmentByDomain { throw 'Metadata failed' }
            }
            else {
                Mock Get-MsalAccessToken { throw 'Tenant authentication failed' } -ParameterFilter { -not $ForCloudDiscovery }
            }

            { Connect-GraphHelper -Discovery } | Should -Throw

            [object]::ReferenceEquals($Global:ScubaGearState.Session, $script:PreviousSession) | Should -BeTrue
        }

        It 'rejects combining discovery with certificate authentication or an explicit environment' {
            { Connect-GraphHelper -Discovery -M365Environment commercial } | Should -Throw
            { Connect-GraphHelper -Discovery -ServicePrincipalParams @{ CertThumbprintParams = @{} } } | Should -Throw
            Should -Invoke Get-MsalAccessToken -Times 0 -Exactly
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

}

InModuleScope Connection {
    Import-Module (Join-Path $PSScriptRoot '..\..\..\..\Modules\Permissions\PermissionsHelper.psm1') -Force
    Describe 'Connect-Tenant environment discovery' {
        BeforeEach {
            $Global:ScubaGearState.Session = $null
            Mock Disconnect-ScubaGraph {}
            Mock Initialize-Msal {}
            Mock Connect-GraphHelper {
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'gcchigh'
                    TokenParameters = @{ Scope = $Scopes; Tenant = '305102d0-7ccc-4007-83bb-ac1f44f8d620' }
                }
            }
            Mock Get-ScubaGearEntraMinimumPermissions { @('Organization.Read.All') }
            Mock Write-Progress {}
        }

        AfterEach {
            $Global:ScubaGearState.Session = $null
        }

        It 'establishes Graph only once with the detected cloud and tenant' {
            $Result = Connect-Tenant -ProductNames aad
            $Result.DetectedM365Environment | Should -Be 'gcchigh'
            $Result.ProdAuthFailed | Should -BeNullOrEmpty
            Should -Invoke Connect-GraphHelper -Times 1 -Exactly -ParameterFilter {
                $Discovery -and $Scopes -contains 'Organization.Read.All'
            }
        }

        It 'discovers the interactive environment even when an explicit environment was supplied' {
            $Result = Connect-Tenant -ProductNames aad -M365Environment gcc
            $Result.DetectedM365Environment | Should -Be 'gcchigh'
            Should -Invoke Connect-GraphHelper -Times 1 -Exactly -ParameterFilter { $Discovery }
        }

        It 'stops before product authentication when discovery fails' {
            Mock Connect-GraphHelper { throw 'Cloud discovery failed' }
            { Connect-Tenant -ProductNames aad } | Should -Throw '*Cloud discovery failed*'
            Should -Invoke Connect-GraphHelper -Times 1 -Exactly -ParameterFilter { $Discovery }
        }

        It 'reuses the existing <Environment> session without discovery or Graph reconnection' -TestCases @(
            @{ Environment = 'commercial' },
            @{ Environment = 'gcc' },
            @{ Environment = 'gcchigh' },
            @{ Environment = 'dod' }
        ) {
            param($Environment)
            $Session = @{
                M365Environment = $Environment
                Account = [pscustomobject]@{ Username = 'user@example.com' }
                TokenParameters = @{ Scope = @('Organization.Read.All') }
            }
            $Global:ScubaGearState.Session = $Session

            $Result = Connect-Tenant -ProductNames aad

            $Result.DetectedM365Environment | Should -Be $Environment
            $Result.ProdAuthFailed | Should -BeNullOrEmpty
            [object]::ReferenceEquals($Global:ScubaGearState.Session, $Session) | Should -BeTrue
            Should -Invoke Connect-GraphHelper -Times 0 -Exactly
            Should -Invoke Disconnect-ScubaGraph -Times 0 -Exactly
        }

        It 'reuses an app-only session without domain or interactive discovery' {
            $ServicePrincipalParams = @{
                CertThumbprintParams = @{
                    AppID = 'test-app'
                    CertificateThumbprint = 'test-certificate'
                    Organization = 'contoso.onmicrosoft.com'
                }
            }
            $Session = @{
                M365Environment = 'gcc'
                Account = $null
                TokenParameters = @{
                    CertificateThumbprint = 'test-certificate'
                    AppID = 'test-app'
                    Tenant = 'contoso.onmicrosoft.com'
                    Scope = 'https://graph.microsoft.com/.default'
                }
            }
            $Global:ScubaGearState.Session = $Session
            Mock Get-M365EnvironmentByDomain { throw 'Domain discovery should not run' }

            $Result = Connect-Tenant -ProductNames aad -M365Environment gcc -ServicePrincipalParams $ServicePrincipalParams

            $Result.DetectedM365Environment | Should -BeNullOrEmpty
            $Result.ProdAuthFailed | Should -BeNullOrEmpty
            [object]::ReferenceEquals($Global:ScubaGearState.Session, $Session) | Should -BeTrue
            Should -Invoke Get-M365EnvironmentByDomain -Times 0 -Exactly
            Should -Invoke Connect-GraphHelper -Times 0 -Exactly
        }
    }
}

AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
}
