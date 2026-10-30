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
                $Global:ScubaGearState.LastRun = $null
            }

            It 'Warns and returns nothing' {
                $Warnings = $null
                $Result = Get-ScubaGearContext -WarningVariable Warnings -WarningAction SilentlyContinue
                $Result | Should -BeNullOrEmpty
                $Warnings | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When the last run has disconnected' {
            BeforeEach {
                $Global:ScubaGearState.Session = $null
                Mock -ModuleName ConnectHelpers Invoke-ScubaGraphRequest { throw 'No Graph call is possible after a disconnect.' }
            }

            AfterAll {
                $Global:ScubaGearState.LastRun = $null
            }

            It 'Shows the user and tenant the last run used, labeled as disconnected' {
                $Global:ScubaGearState.LastRun = [pscustomobject]@{
                    AuthType = 'Delegated'; Account = 'jane.doe@contoso.com'; AppId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
                    Tenant = 'tenant-guid'; Environment = 'commercial'; DisconnectedAtZulu = '2026-10-29T12:00:00.000Z'
                }
                $Result = Get-ScubaGearContext -InformationAction SilentlyContinue
                $Result.Status | Should -Be 'Disconnected (last run)'
                $Result.Account | Should -Be 'jane.doe@contoso.com'
                $Result.AuthType | Should -Be 'Delegated'
                $Result.ClientId | Should -Be '14d82eec-204b-4c2f-b7e8-296a70dab67e'
                $Result.Tenant | Should -Be 'tenant-guid'
                $Result.Environment | Should -Be 'commercial'
                $Result.DisconnectedAtZulu | Should -Be '2026-10-29T12:00:00.000Z'
            }

            It 'Shows the app the last run used for a service principal' {
                $Global:ScubaGearState.LastRun = [pscustomobject]@{
                    AuthType = 'AppOnly'; Account = $null; AppId = '11111111-2222-3333-4444-555555555555'
                    Tenant = 'contoso.onmicrosoft.com'; Environment = 'gcchigh'; DisconnectedAtZulu = '2026-10-29T12:00:00.000Z'
                }
                $Result = Get-ScubaGearContext -InformationAction SilentlyContinue
                $Result.Status | Should -Be 'Disconnected (last run)'
                $Result.Account | Should -Be '11111111-2222-3333-4444-555555555555 (service principal)'
                $Result.AuthType | Should -Be 'AppOnly'
            }

            It 'Makes no Microsoft Graph calls and does not warn' {
                $Global:ScubaGearState.LastRun = [pscustomobject]@{
                    AuthType = 'Delegated'; Account = 'jane.doe@contoso.com'; AppId = 'app'
                    Tenant = 'tenant-guid'; Environment = 'commercial'; DisconnectedAtZulu = '2026-10-29T12:00:00.000Z'
                }
                $Result = Get-ScubaGearContext -WarningVariable ContextWarnings -InformationAction SilentlyContinue
                $Result | Should -Not -BeNullOrEmpty
                $ContextWarnings | Should -BeNullOrEmpty
                Should -Invoke -ModuleName ConnectHelpers -CommandName Invoke-ScubaGraphRequest -Times 0 -Exactly
            }

            It 'Says it is showing the last run, not a live connection' {
                $Global:ScubaGearState.LastRun = [pscustomobject]@{
                    AuthType = 'Delegated'; Account = 'jane.doe@contoso.com'; AppId = 'app'
                    Tenant = 'tenant-guid'; Environment = 'commercial'; DisconnectedAtZulu = '2026-10-29T12:00:00.000Z'
                }
                $Output = Get-ScubaGearContext 6>&1
                @($Output | Where-Object { $_ -is [System.Management.Automation.InformationRecord] -and $_.MessageData -like '*disconnected*most recent run*' }).Count | Should -Be 1
            }
        }

        Context 'Get-ScubaGearRunIdentity' {
            AfterAll {
                $Global:ScubaGearState.Session = $null
            }

            It 'Returns nothing when there is no session' {
                $Global:ScubaGearState.Session = $null
                Get-ScubaGearRunIdentity | Should -BeNullOrEmpty
            }

            It 'Returns the user, app, tenant and environment of a delegated session' {
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'commercial'
                    Account = [pscustomobject]@{ Username = 'jane.doe@contoso.com' }
                    TokenParameters = @{ Scope = @('Organization.Read.All'); ClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'; Tenant = 'tenant-guid' }
                }
                $Result = Get-ScubaGearRunIdentity
                $Result.AuthType | Should -Be 'Delegated'
                $Result.Account | Should -Be 'jane.doe@contoso.com'
                $Result.AppId | Should -Be '14d82eec-204b-4c2f-b7e8-296a70dab67e'
                $Result.Tenant | Should -Be 'tenant-guid'
                $Result.Environment | Should -Be 'commercial'
            }

            It 'Returns the app and no account for a service principal session' {
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'gcchigh'
                    Account = $null
                    TokenParameters = @{ CertificateThumbprint = 'A thumbprint'; AppID = '11111111-2222-3333-4444-555555555555'; Tenant = 'contoso.onmicrosoft.com' }
                }
                $Result = Get-ScubaGearRunIdentity
                $Result.AuthType | Should -Be 'AppOnly'
                $Result.Account | Should -BeNullOrEmpty
                $Result.AppId | Should -Be '11111111-2222-3333-4444-555555555555'
                $Result.Tenant | Should -Be 'contoso.onmicrosoft.com'
            }

            It 'Contains no tokens or certificate thumbprint' {
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'commercial'
                    Account = [pscustomobject]@{ Username = 'jane.doe@contoso.com' }
                    TokenParameters = @{ Scope = @('Organization.Read.All'); ClientId = 'client'; Tenant = 'tenant-guid'; CertificateThumbprint = $null }
                }
                (Get-ScubaGearRunIdentity).PSObject.Properties.Name | Sort-Object |
                    Should -Be @('Account', 'AppId', 'AuthType', 'Environment', 'Tenant')
            }
        }

        Context 'Disconnect-ScubaGraph records the last run' {
            BeforeEach {
                $Global:ScubaGearState.LastRun = $null
                $Global:ScubaGearState.MsalAppCache = @{ 'PUB:client' = [pscustomobject]@{ Name = 'cached app' } }
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'commercial'
                    Account = [pscustomobject]@{ Username = 'jane.doe@contoso.com' }
                    TokenParameters = @{ Scope = @('Organization.Read.All'); ClientId = 'client'; Tenant = 'tenant-guid' }
                }
            }

            AfterAll {
                $Global:ScubaGearState.LastRun = $null
            }

            It 'Saves who the session was signed in as' {
                Disconnect-ScubaGraph
                $Global:ScubaGearState.LastRun.Account | Should -Be 'jane.doe@contoso.com'
                $Global:ScubaGearState.LastRun.AuthType | Should -Be 'Delegated'
                $Global:ScubaGearState.LastRun.Tenant | Should -Be 'tenant-guid'
                $Global:ScubaGearState.LastRun.DisconnectedAtZulu | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$'
            }

            It 'Still clears the session and the token cache' {
                Disconnect-ScubaGraph
                $Global:ScubaGearState.Session | Should -BeNullOrEmpty
                $Global:ScubaGearState.MsalAppCache.Count | Should -Be 0
            }

            It 'Keeps no token or other credential material in the saved record' {
                Disconnect-ScubaGraph
                $Global:ScubaGearState.LastRun.PSObject.Properties.Name | Sort-Object |
                    Should -Be @('Account', 'AppId', 'AuthType', 'DisconnectedAtZulu', 'Environment', 'Tenant')
            }

            It 'Does not erase the saved record when disconnecting again with no session' {
                Disconnect-ScubaGraph
                Disconnect-ScubaGraph
                $Global:ScubaGearState.LastRun.Account | Should -Be 'jane.doe@contoso.com'
            }

            It 'Replaces the saved record with the newest run' {
                Disconnect-ScubaGraph
                $Global:ScubaGearState.Session = @{
                    M365Environment = 'gcchigh'
                    Account = $null
                    TokenParameters = @{ CertificateThumbprint = 'A thumbprint'; AppID = 'app-2'; Tenant = 'other.onmicrosoft.us' }
                }
                Disconnect-ScubaGraph
                $Global:ScubaGearState.LastRun.AuthType | Should -Be 'AppOnly'
                $Global:ScubaGearState.LastRun.AppId | Should -Be 'app-2'
                $Global:ScubaGearState.LastRun.Account | Should -BeNullOrEmpty
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
                    param($Uri)
                    if ($Uri -eq '/v1.0/organization') {
                        return [pscustomobject]@{ value = @([pscustomobject]@{
                            id = 'tenant-guid'
                            displayName = 'Contoso'
                            verifiedDomains = @(
                                [pscustomobject]@{ name = 'contoso.com'; isInitial = $false; isDefault = $true },
                                [pscustomobject]@{ name = 'contoso.onmicrosoft.com'; isInitial = $true; isDefault = $false }
                            )
                        }) }
                    }
                    if ($Uri -eq '/v1.0/me') {
                        return [pscustomobject]@{ userPrincipalName = 'jane.doe@contoso.com'; mail = 'jane.doe@contoso.com' }
                    }
                    if ($Uri -eq "/v1.0/servicePrincipals(appId='14d82eec-204b-4c2f-b7e8-296a70dab67e')") {
                        return [pscustomobject]@{ displayName = 'Contoso Graph Client' }
                    }
                    throw "Unexpected Uri: $Uri"
                }
            }

            It 'Resolves the signed-in user via GET /v1.0/me' {
                $Result = Get-ScubaGearContext
                $Result.Status | Should -Be 'Connected'
                $Result.Account | Should -Be 'jane.doe@contoso.com'
                $Result.AuthType | Should -Be 'Delegated'
                $Result.TenantId | Should -Be 'tenant-guid'
                $Result.TenantName | Should -Be 'Contoso'
                $Result.TenantDomain | Should -Be 'contoso.onmicrosoft.com'
                $Result.AppDisplayName | Should -Be 'Contoso Graph Client'
                $Result.ClientId | Should -Be '14d82eec-204b-4c2f-b7e8-296a70dab67e'
                $Result.Environment | Should -Be 'commercial'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Invoke-ScubaGraphRequest -Times 1 -ParameterFilter { $Uri -eq '/v1.0/me' }
                Should -Invoke Invoke-ScubaGraphRequest -Times 1 -Exactly -ParameterFilter {
                    $Uri -eq "/v1.0/servicePrincipals(appId='14d82eec-204b-4c2f-b7e8-296a70dab67e')"
                }
            }

            It 'uses the documented Graph client name when service principal lookup is denied' {
                Mock Invoke-ScubaGraphRequest { throw 'Insufficient privileges' } -ParameterFilter {
                    $Uri -like '/v1.0/servicePrincipals*'
                }

                $Result = Get-ScubaGearContext -WarningVariable ContextWarnings

                $Result.AppDisplayName | Should -Be 'Microsoft Graph Command Line Tools'
                $Result.Account | Should -Be 'jane.doe@contoso.com'
                $Result.TenantDomain | Should -Be 'contoso.onmicrosoft.com'
                $ContextWarnings | Should -BeNullOrEmpty
                $Global:ScubaGearState.Session.TokenParameters.Scope | Should -Be @('Organization.Read.All')
            }

            It 'does not substitute the Graph client name for an unknown client' {
                $SavedClientId = $Global:ScubaGearState.Session.TokenParameters.ClientId
                try {
                    $Global:ScubaGearState.Session.TokenParameters.ClientId = 'unknown-client'
                    Mock Invoke-ScubaGraphRequest { throw 'Insufficient privileges' } -ParameterFilter {
                        $Uri -like '/v1.0/servicePrincipals*'
                    }

                    $Result = Get-ScubaGearContext -WarningVariable ContextWarnings -WarningAction SilentlyContinue

                    $Result.AppDisplayName | Should -BeNullOrEmpty
                    $Result.ClientId | Should -Be 'unknown-client'
                    $Result.Account | Should -Be 'jane.doe@contoso.com'
                    @($ContextWarnings).Count | Should -Be 1
                }
                finally {
                    $Global:ScubaGearState.Session.TokenParameters.ClientId = $SavedClientId
                }
            }

            It 'leaves the tenant domain empty when the initial domain is unavailable' {
                Mock Invoke-ScubaGraphRequest {
                    [pscustomobject]@{ value = @([pscustomobject]@{
                        id = 'tenant-guid'
                        displayName = 'Contoso'
                        verifiedDomains = @([pscustomobject]@{ name = 'contoso.com'; isInitial = $false; isDefault = $true })
                    }) }
                } -ParameterFilter { $Uri -eq '/v1.0/organization' }

                $Result = Get-ScubaGearContext

                $Result.TenantDomain | Should -BeNullOrEmpty
                $Result.TenantName | Should -Be 'Contoso'
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
                    param($Uri)
                    if ($Uri -eq '/v1.0/organization') {
                        return [pscustomobject]@{ value = @([pscustomobject]@{
                            id = 'tenant-guid'
                            displayName = 'Contoso'
                            verifiedDomains = @([pscustomobject]@{ name = 'contoso.onmicrosoft.com'; isInitial = $true })
                        }) }
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
                $Result.TenantDomain | Should -Be 'contoso.onmicrosoft.com'
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
                $Script:Result.TenantDomain | Should -BeNullOrEmpty
            }
        }
    }
}

AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
