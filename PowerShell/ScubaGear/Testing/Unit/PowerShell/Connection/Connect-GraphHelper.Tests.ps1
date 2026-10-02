[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()
BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Function 'Connect-GraphHelper' -Force
}

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-GraphHelper' {
        BeforeAll {
            function Get-MsalAccessToken {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($Scope, $ClientId, $Tenant, $M365Environment, $CertificateThumbprint, $AppID)
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
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
