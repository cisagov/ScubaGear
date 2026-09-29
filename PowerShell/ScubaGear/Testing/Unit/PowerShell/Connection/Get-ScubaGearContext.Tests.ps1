[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()
BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Function 'Get-ScubaGearContext' -Force
}

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Get-ScubaGearContext' {
        BeforeAll {
            function Invoke-ScubaGraphRequest {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($Uri, $Method)
                throw 'this will be mocked'
            }
        }

        Context 'When ScubaGear is not connected to Microsoft Graph' {
            BeforeAll {
                $Global:ScubaGearState.Session = $null
            }

            It 'Warns and returns nothing' {
                $Warnings = $null
                $Result = Get-ScubaGearContext -WarningVariable Warnings -WarningAction SilentlyContinue
                $Result | Should -BeNullOrEmpty
                $Warnings | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When connected with a delegated (interactive) session' {
            BeforeAll {
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'commercial'
                    GraphEndpoint = 'https://graph.microsoft.com'
                    TokenParameters = @{
                        Scope = @('Organization.Read.All')
                        ClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
                        Tenant = 'organizations'
                    }
                }
                Mock -ModuleName ConnectHelpers Invoke-ScubaGraphRequest {
                    param($Uri, $Method)
                    if ($Uri -eq '/v1.0/organization') {
                        return [pscustomobject]@{ value = @([pscustomobject]@{ id = 'tenant-guid'; displayName = 'Contoso' }) }
                    }
                    if ($Uri -eq '/v1.0/me') {
                        return [pscustomobject]@{ userPrincipalName = 'jane.doe@contoso.com'; mail = 'jane.doe@contoso.com' }
                    }
                    throw "Unexpected Uri: $Uri"
                }
            }

            It 'Resolves the signed-in user via GET /v1.0/me' {
                $Result = Get-ScubaGearContext
                $Result.Account | Should -Be 'jane.doe@contoso.com'
                $Result.AuthType | Should -Be 'Delegated'
                $Result.TenantId | Should -Be 'tenant-guid'
                $Result.TenantName | Should -Be 'Contoso'
                $Result.ClientId | Should -Be '14d82eec-204b-4c2f-b7e8-296a70dab67e'
                $Result.Environment | Should -Be 'commercial'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Invoke-ScubaGraphRequest -Times 1 -ParameterFilter { $Uri -eq '/v1.0/me' }
            }
        }

        Context 'When connected with a service principal (app-only) session' {
            BeforeAll {
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'gcchigh'
                    GraphEndpoint = 'https://graph.microsoft.us'
                    TokenParameters = @{
                        Scope = @('https://graph.microsoft.us/.default')
                        CertificateThumbprint = 'A thumbprint'
                        AppID = '11111111-2222-3333-4444-555555555555'
                        Tenant = 'contoso.onmicrosoft.com'
                    }
                }
                Mock -ModuleName ConnectHelpers Invoke-ScubaGraphRequest {
                    param($Uri, $Method)
                    if ($Uri -eq '/v1.0/organization') {
                        return [pscustomobject]@{ value = @([pscustomobject]@{ id = 'tenant-guid'; displayName = 'Contoso' }) }
                    }
                    if ($Uri -like "/v1.0/servicePrincipals(appId='*'*") {
                        return [pscustomobject]@{ displayName = 'ScubaGear Automation' }
                    }
                    throw "Unexpected Uri: $Uri"
                }
            }

            It 'Resolves the service principal instead of calling /v1.0/me' {
                $Result = Get-ScubaGearContext
                $Result.Account | Should -Be '11111111-2222-3333-4444-555555555555 (service principal)'
                $Result.AppDisplayName | Should -Be 'ScubaGear Automation'
                $Result.AuthType | Should -Be 'AppOnly'
                $Result.ClientId | Should -Be '11111111-2222-3333-4444-555555555555'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Invoke-ScubaGraphRequest -Times 0 -ParameterFilter { $Uri -eq '/v1.0/me' }
            }
        }

        Context 'When Microsoft Graph calls fail' {
            BeforeAll {
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'commercial'
                    GraphEndpoint = 'https://graph.microsoft.com'
                    TokenParameters = @{
                        Scope = @('Organization.Read.All')
                        ClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
                        Tenant = 'organizations'
                    }
                }
                Mock -ModuleName ConnectHelpers Invoke-ScubaGraphRequest { throw 'Insufficient privileges to complete the operation.' }
            }

            It 'Degrades gracefully instead of throwing' {
                { $Script:Result = Get-ScubaGearContext -WarningAction SilentlyContinue -ErrorAction Stop } | Should -Not -Throw
                $Script:Result.Account | Should -Be 'Unknown'
                $Script:Result.TenantId | Should -BeNullOrEmpty
            }
        }
    }
}

AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
