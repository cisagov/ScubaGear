using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()
BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Function 'Connect-GraphHelper' -Force
}

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-GraphHelper' {
        BeforeEach { $Global:ScubaGearState.Session = $null }
        BeforeAll {
            function Get-MsalAccessToken {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($Scope, $ClientId, $Tenant, $M365Environment, $CertificateThumbprint, $AppID, [switch]$PassThru, [switch]$ForceRefresh)
                throw 'this will be mocked'
            }
            Mock -ModuleName ConnectHelpers Get-MsalAccessToken {'plain-text-token'}
        }
        context 'Without Service Principal'{
            It 'reads the Graph client ID from configuration defaults' {
                $ClientIds = [ScubaConfig]::GetConfigDefaults().AuthenticationClientIdHashtable
                $SavedClientId = $ClientIds.aad
                try {
                    $ClientIds.aad = '11111111-2222-3333-4444-555555555555'

                    Connect-GraphHelper -M365Environment 'commercial'

                    $Global:ScubaGearState.Session.TokenParameters.ClientId | Should -Be $ClientIds.aad
                    Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter {
                        $ClientId -eq '11111111-2222-3333-4444-555555555555'
                    }
                }
                finally {
                    $ClientIds.aad = $SavedClientId
                }
            }

            It 'Invalid M365Environment parameter' {
                {Connect-GraphHelper -M365Environment 'invalid_parameter'} | Should -Throw
            }
            It 'Invokes for commercial environment' {
                Connect-GraphHelper -M365Environment 'commercial'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $M365Environment -eq 'commercial'
                }
            }
            It 'Invokes for gcc environment' {
                Connect-GraphHelper -M365Environment 'gcc'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $M365Environment -eq 'gcc'
                }
            }
            It 'Invokes for gcchigh environment' {
                Connect-GraphHelper -M365Environment 'gcchigh'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $M365Environment -eq 'gcchigh'
                }
            }
            It 'Invokes for dod environment' {
                Connect-GraphHelper -M365Environment 'dod'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $M365Environment -eq 'dod'
                }
            }
            It 'pins the discovered tenant and uses <GraphEndpoint> for <Environment>' -TestCases @(
                @{ Environment = 'gcchigh'; GraphEndpoint = 'https://graph.microsoft.us' },
                @{ Environment = 'dod'; GraphEndpoint = 'https://dod-graph.microsoft.us' }
            ) {
                param($Environment, $GraphEndpoint)
                Connect-GraphHelper -M365Environment $Environment -TenantId '305102d0-7ccc-4007-83bb-ac1f44f8d620'
                $Global:ScubaGearState.Session.GraphEndpoint | Should -Be $GraphEndpoint
                $Global:ScubaGearState.Session.TokenParameters.Tenant | Should -Be '305102d0-7ccc-4007-83bb-ac1f44f8d620'
                Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter {
                    $Tenant -eq '305102d0-7ccc-4007-83bb-ac1f44f8d620'
                }
            }
        }
        context 'Session publication' {
            It 'uses the current tenant when another Graph caller requests additional scopes without TenantId' {
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'gcc'
                    TokenParameters = @{
                        ClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
                        Tenant = 'discovered-tenant'
                    }
                }

                Connect-GraphHelper -M365Environment gcc -Scopes @('Application.Read.All')

                Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter {
                    $Tenant -eq 'discovered-tenant' -and
                    $Scope -contains 'Application.Read.All'
                }
            }
            It 'publishes the complete session only after token acquisition succeeds' {
                $Global:ScubaGearState.Session = @{ Account = 'previous-account' }
                Mock Get-MsalAccessToken {
                    $Global:ScubaGearState.Session.Account | Should -Be 'previous-account'
                    [pscustomobject]@{
                        AccessToken = 'test-token'
                        Account = [pscustomobject]@{ Username = 'user@example.com' }
                    }
                }

                Connect-GraphHelper -M365Environment 'gcc' -TenantId 'test-tenant'

                $Global:ScubaGearState.Session.M365Environment | Should -Be 'gcc'
                $Global:ScubaGearState.Session.GraphEndpoint | Should -Be 'https://graph.microsoft.com'
                $Global:ScubaGearState.Session.TokenParameters.Tenant | Should -Be 'test-tenant'
                $Global:ScubaGearState.Session.Account.Username | Should -Be 'user@example.com'
                Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter { $PassThru }
            }

            It 'uses <ExpectedTenant> when the requested tenant or environment differs from the existing session' -TestCases @(
                @{ Environment = 'gcc'; RequestedTenant = 'explicit-tenant'; ExpectedTenant = 'explicit-tenant' },
                @{ Environment = 'commercial'; RequestedTenant = $null; ExpectedTenant = 'organizations' }
            ) {
                param($Environment, $RequestedTenant, $ExpectedTenant)
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'gcc'
                    TokenParameters = @{ Tenant = 'existing-tenant' }
                }

                Connect-GraphHelper -M365Environment $Environment -TenantId $RequestedTenant

                $Global:ScubaGearState.Session.TokenParameters.Tenant | Should -Be $ExpectedTenant
                Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter { $Tenant -eq $ExpectedTenant }
            }

            It 'preserves the prior session after authentication fails (existing session: <ExistingSession>)' -TestCases @(
                @{ ExistingSession = $false },
                @{ ExistingSession = $true }
            ) {
                param($ExistingSession)
                $Global:ScubaGearState.Session = if ($ExistingSession) { @{ Account = 'previous-account' } } else { $null }
                $SavedSession = $Global:ScubaGearState.Session
                $SavedAppCache = $Global:ScubaGearState.MsalAppCache
                Mock Get-MsalAccessToken {
                    throw 'Authentication failed'
                }

                { Connect-GraphHelper -M365Environment 'commercial' } | Should -Throw '*Authentication failed*'

                [object]::ReferenceEquals($Global:ScubaGearState.Session, $SavedSession) | Should -BeTrue
                [object]::ReferenceEquals($Global:ScubaGearState.MsalAppCache, $SavedAppCache) | Should -BeTrue
            }
        }
        context 'With Service Principal'{
            It 'Invoke with Service Principal parameters'{
                $sp = @{
                    CertThumbprintParams = @{
                        CertificateThumbprint = 'A thumbprint';
                        AppID = 'My Id';
                        Organization = 'My Organization';
                    }
                }
                Connect-GraphHelper -M365Environment 'commercial' -ServicePrincipalParams $sp
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $CertificateThumbprint -eq 'A thumbprint' -and
                    $AppID -eq 'My Id' -and
                    $Tenant -eq 'My Organization' -and
                    $M365Environment -eq 'commercial'
                }
            }

            # The Graph audience differs by cloud, and DoD has its own root, so its token scope must name it
            # (https://dod-graph.microsoft.us) instead of the GCC High root.
            It 'requests the <ExpectedScope> scope and publishes <ExpectedEndpoint> for <Environment>' -TestCases @(
                @{ Environment = 'commercial'; ExpectedScope = 'https://graph.microsoft.com/.default'; ExpectedEndpoint = 'https://graph.microsoft.com' },
                @{ Environment = 'gcc'; ExpectedScope = 'https://graph.microsoft.com/.default'; ExpectedEndpoint = 'https://graph.microsoft.com' },
                @{ Environment = 'gcchigh'; ExpectedScope = 'https://graph.microsoft.us/.default'; ExpectedEndpoint = 'https://graph.microsoft.us' },
                @{ Environment = 'dod'; ExpectedScope = 'https://dod-graph.microsoft.us/.default'; ExpectedEndpoint = 'https://dod-graph.microsoft.us' }
            ) {
                param($Environment, $ExpectedScope, $ExpectedEndpoint)
                $sp = @{
                    CertThumbprintParams = @{
                        CertificateThumbprint = 'A thumbprint';
                        AppID = 'My Id';
                        Organization = 'My Organization';
                    }
                }
                Connect-GraphHelper -M365Environment $Environment -ServicePrincipalParams $sp
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter {
                    $Scope -eq $ExpectedScope -and $M365Environment -eq $Environment
                }
                $Global:ScubaGearState.Session.TokenParameters.Scope | Should -Be $ExpectedScope
                $Global:ScubaGearState.Session.GraphEndpoint | Should -Be $ExpectedEndpoint
                # The scope's host must be the same Graph root the requests are sent to.
                $ExpectedScope | Should -Be "$($Global:ScubaGearState.Session.GraphEndpoint)/.default"
            }
        }
    }

    Describe -Tag 'Connection' -Name 'Invoke-ScubaGraphRequest' {
        BeforeEach {
            $Global:ScubaGearState.Session = @{
                M365Environment = 'commercial'
                GraphEndpoint = 'https://graph.microsoft.com'
                TokenParameters = @{
                    Scope = @('Organization.Read.All')
                    ClientId = 'test-client'
                    Tenant = 'organizations'
                    M365Environment = 'commercial'
                }
            }
            Mock Get-MsalAccessToken { 'test-token' }
        }

        It 'requires an active Graph session' {
            $Global:ScubaGearState.Session = $null
            { Invoke-ScubaGraphRequest -Uri '/v1.0/organization' } | Should -Throw '*not connected*'
        }

        It 'adds a bearer token and resolves relative Graph URIs' {
            Mock Invoke-RestMethod { [pscustomobject]@{ id = 'tenant-id' } }

            $result = Invoke-ScubaGraphRequest -Uri '/v1.0/organization'

            $result.id | Should -Be 'tenant-id'
            Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter { $ClientId -eq 'test-client' }
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq 'https://graph.microsoft.com/v1.0/organization' -and
                $Headers.Authorization -eq 'Bearer test-token'
            }
        }

        It 'aggregates Graph collection pages' {
            Mock Invoke-RestMethod {
                if ($Uri -eq 'https://graph.microsoft.com/page2') {
                    return [pscustomobject]@{ value = @([pscustomobject]@{ id = '2' }) }
                }
                [pscustomobject]@{
                    value = @([pscustomobject]@{ id = '1' })
                    '@odata.nextLink' = 'https://graph.microsoft.com/page2'
                }
            }

            $result = Invoke-ScubaGraphRequest -Uri '/v1.0/users'

            @($result.value.id) | Should -Be @('1', '2')
            Should -Invoke Invoke-RestMethod -Times 2
        }

        It 'retries a transient transport failure' {
            $Script:RequestCount = 0
            Mock Start-Sleep
            Mock Invoke-RestMethod {
                $Script:RequestCount++
                if ($Script:RequestCount -eq 1) {
                    throw [System.Net.Http.HttpRequestException]::new('Temporary Graph connection failure')
                }
                [pscustomobject]@{ id = 'tenant-id' }
            }

            $result = Invoke-ScubaGraphRequest -Uri '/v1.0/organization'

            $result.id | Should -Be 'tenant-id'
            Should -Invoke Invoke-RestMethod -Times 2
            Should -Invoke Start-Sleep -Times 1 -ParameterFilter { $Seconds -eq 1 }
        }

        It 'recovers from a 401 by refreshing the Graph token without clearing product caches' {
            $SavedCache = @{ 'PUB:other-product' = [pscustomobject]@{} }
            $Global:ScubaGearState.MsalAppCache = $SavedCache
            $Script:RequestCount = 0
            Mock Invoke-RestMethod {
                $Script:RequestCount++
                if ($Script:RequestCount -eq 1) {
                    $Failure = [System.Exception]::new('Unauthorized')
                    $Failure | Add-Member NoteProperty Response ([pscustomobject]@{ StatusCode = 401 })
                    throw $Failure
                }
                [pscustomobject]@{ id = 'tenant-id' }
            }

            (Invoke-ScubaGraphRequest -Uri '/v1.0/organization').id | Should -Be 'tenant-id'
            Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter { $ForceRefresh -and $ClientId -eq 'test-client' }
            Should -Invoke Get-MsalAccessToken -Times 1 -Exactly -ParameterFilter { -not $ForceRefresh }
            [object]::ReferenceEquals($Global:ScubaGearState.MsalAppCache, $SavedCache) | Should -BeTrue
            $Global:ScubaGearState.Session.TokenParameters.ContainsKey('ForceRefresh') | Should -BeFalse
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
