BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Function 'Connect-GraphHelper' -Force
}

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-GraphHelper' {
        BeforeAll {
            function Get-MsalAccessToken {
                param($Scope, $ClientId, $Tenant, $M365Environment, $DisableBroker, $CertificateThumbprint, $AppID)
                throw 'this will be mocked'
            }
            Mock -ModuleName ConnectHelpers Get-MsalAccessToken {'plain-text-token'}
        }
        context 'Without Service Principal'{
            It 'Invalid M365Environment parameter' {
                {Connect-GraphHelper -M365Environment 'invalid_parameter'} | Should -Throw
            }
            It 'Invokes for commercial environment' {
                Connect-GraphHelper -M365Environment 'commercial'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $M365Environment -eq 'commercial' -and -not $DisableBroker
                }
            }
            It 'Invokes for gcc environment' {
                Connect-GraphHelper -M365Environment 'gcc'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $M365Environment -eq 'gcc' -and -not $DisableBroker
                }
            }
            It 'Invokes for gcchigh environment' {
                Connect-GraphHelper -M365Environment 'gcchigh'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $M365Environment -eq 'gcchigh' -and -not $DisableBroker
                }
            }
            It 'Invokes for dod environment' {
                Connect-GraphHelper -M365Environment 'dod'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $M365Environment -eq 'dod' -and -not $DisableBroker
                }
            }
            It 'Uses system-browser authentication when requested' {
                Connect-GraphHelper -M365Environment 'gcc' -Scopes 'Organization.Read.All' -UseSystemBrowserAuthentication
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $ClientId -eq '14d82eec-204b-4c2f-b7e8-296a70dab67e' -and
                    $Tenant -eq 'organizations' -and
                    $M365Environment -eq 'gcc' -and
                    $Scope -contains 'Organization.Read.All' -and
                    $DisableBroker
                }
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
                Connect-GraphHelper -M365Environment 'commercial' -ServicePrincipalParams $sp -UseSystemBrowserAuthentication
                Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $CertificateThumbprint -eq 'A thumbprint' -and
                    $AppID -eq 'My Id' -and
                    $Tenant -eq 'My Organization' -and
                    $M365Environment -eq 'commercial'
                }
            }
        }
    }

    Describe -Tag 'Connection' -Name 'Get-TeamsAccessTokens' {
        BeforeAll {
            Mock -ModuleName ConnectHelpers Get-MsalAccessToken {
                if ($Scope -like '*graph*') { return 'graph-token' }
                return 'teams-token'
            }
        }

        It 'returns Graph then Teams tokens for <M365Environment>' -ForEach @(
            @{M365Environment = 'commercial'; GraphScope = 'https://graph.microsoft.com/.default'}
            @{M365Environment = 'gcc'; GraphScope = 'https://graph.microsoft.com/.default'}
            @{M365Environment = 'gcchigh'; GraphScope = 'https://graph.microsoft.us/.default'}
            @{M365Environment = 'dod'; GraphScope = 'https://graph.microsoft.us/.default'}
        ) {
            $Tokens = @(Get-TeamsAccessTokens -M365Environment $M365Environment)
            $Tokens | Should -Be @('graph-token', 'teams-token')
            Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                $Scope -eq $GraphScope -and
                $ClientId -eq '12128f48-ec9e-42f0-b203-ea49fb6af367' -and
                $Tenant -eq 'organizations' -and
                $M365Environment -eq $M365Environment
            }
            Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                $Scope -eq '48ac35b8-9aa8-4d74-927d-1f4a14a0b239/.default'
            }
        }

        It 'disables broker for both system-browser Teams tokens' {
            Get-TeamsAccessTokens -M365Environment 'gcc' -DisableBroker
            Should -Invoke -ModuleName ConnectHelpers -CommandName Get-MsalAccessToken -Times 2 -ParameterFilter {
                $DisableBroker
            }
        }
    }

    Describe -Tag 'Connection' -Name 'Invoke-ScubaGraphRequest' {
        BeforeEach {
            $Script:ScubaGraphSession = @{
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
            $Script:ScubaGraphSession = $null
            { Invoke-ScubaGraphRequest -Uri '/v1.0/organization' } | Should -Throw '*not connected*'
        }

        It 'adds a bearer token and resolves relative Graph URIs' {
            Mock Invoke-RestMethod { [pscustomobject]@{ id = 'tenant-id' } }

            $result = Invoke-ScubaGraphRequest -Uri '/v1.0/organization'

            $result.id | Should -Be 'tenant-id'
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
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
