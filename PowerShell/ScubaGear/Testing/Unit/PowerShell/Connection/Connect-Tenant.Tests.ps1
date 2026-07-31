Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Connection/Connection.psm1") -Function 'Connect-Tenant' -Force

InModuleScope Connection {
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Permissions/PermissionsHelper.psm1") -Force

    Describe -Tag 'Connection' -Name "Connect-Tenant as <Endpoint>" -ForEach @(
        @{Endpoint = 'commercial'},
        @{Endpoint = 'gcc'},
        @{Endpoint = 'gcchigh'},
        @{Endpoint = 'dod'}
    ){
        BeforeAll {
            function Connect-GraphHelper {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($UseSystemBrowserAuthentication, $ServicePrincipalParams, $M365Environment, $Scopes)
                throw 'this will be mocked'
            }
            Mock Connect-GraphHelper -MockWith {}
            # SharePoint now uses REST API - no PnP/SPO connection needed
            function Connect-MicrosoftTeams {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($DisableWAM, $AccessTokens, $CertificateThumbprint, $ApplicationId, $TenantId, $TeamsEnvironmentName)
                throw 'this will be mocked'
            }
            Mock Connect-MicrosoftTeams -MockWith {}
            function Get-TeamsAccessTokens {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($M365Environment, [switch]$DisableBroker)
                throw 'this will be mocked'
            }
            Mock Get-TeamsAccessTokens -MockWith { return @('mock-graph-token', 'mock-teams-token') }
            function Get-ExchangeOnlineApiEndpoint {throw 'this will be mocked'}
            Mock Get-ExchangeOnlineApiEndpoint -MockWith { return "https://mock.outlook.office365.com/adminapi/beta/TenantId/InvokeCommand" }
            function Get-ExchangeOnlineScope {throw 'this will be mocked'}
            Mock Get-ExchangeOnlineScope -MockWith { return "https://outlook.office365.com/.default" }
            function Invoke-GraphDirectly {throw 'this will be mocked'}
            Mock Invoke-GraphDirectly -MockWith {
                return [pscustomobject]@{
                    Value = [pscustomobject]@{
                        DisplayName     = "DisplayName";
                        Name            = "DomainName";
                        Id              = "TenantId";
                        VerifiedDomains = @(
                            @{ isInitial = $false; Name = "example.onmicrosoft.com" },
                            @{ isInitial = $true; Name = "contoso.onmicrosoft.com" }
                        )
                    }
                }
            }
            function Get-MsalAccessToken {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($Scope, $ClientId, $Tenant, $M365Environment, $DisableBroker, $CertificateThumbprint, $AppID)
                throw 'this will be mocked'
            }
            Mock Get-MsalAccessToken -MockWith { return "mock-access-token" }
            Mock -CommandName Write-Progress {
            }
        }
        Context 'With Endpoint:  <Endpoint>; ProductNames: <ProductNames>' -ForEach @(
            @{ProductNames = "aad"; Services = @('Connect-GraphHelper'); EXOHelperCalls = 0}
            @{ProductNames = "securitysuite"; Services = @('Get-MsalAccessToken'); EXOHelperCalls = 0}
            @{ProductNames = "exo"; Services = @('Get-MsalAccessToken'); EXOHelperCalls = 1}
            @{ProductNames = "powerplatform"; Services = @('Connect-GraphHelper'); EXOHelperCalls = 0}
            @{ProductNames = "sharepoint"; Services = @('Connect-GraphHelper'); EXOHelperCalls = 0}  # SharePoint uses REST API, only needs Graph for tenant info
            @{ProductNames = "teams"; Services = @('Connect-MicrosoftTeams'); EXOHelperCalls = 0}
            @{
                ProductNames = "aad", "securitysuite", "exo", "powerplatform", "sharepoint", "teams"
                Services = @(
                    'Connect-GraphHelper',
                    'Get-MsalAccessToken',
                    'Connect-MicrosoftTeams'
                )
            }

        ){

            It "No Service Principal" {
                $ConnectionResult = Connect-Tenant -ProductNames $ProductNames -M365Environment $Endpoint
                $ConnectionResult.ProdAuthFailed.Count | Should -Be 0
            }
            It "With Service Principal" {
                $ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint
                $ServicePrincipalParams =@{
                    CertThumbprintParams = @{
                        AppID = "a"
                        CertificateThumbprint = "b"
                        Organization = "c"
                    }
                }
                Connect-Tenant -ProductNames $ProductNames -M365Environment $Endpoint -ServicePrincipalParams $ServicePrincipalParams
                foreach ($Service in $Services){
                    Should -Invoke -CommandName $Service -Times 1 -Because "only want to authenticate to needed service once"
                }
            }

        }
        Context 'System browser authentication' {
            It 'disables broker for Exchange and Compliance token acquisition' {
                Connect-Tenant -ProductNames 'exo' -M365Environment $Endpoint -UseSystemBrowserAuthentication
                Should -Invoke -CommandName Get-MsalAccessToken -Times 2 -ParameterFilter {
                    $ClientId -eq 'fb78d390-0c51-40cd-8e17-fdbfab77341b' -and $DisableBroker
                }
            }

            It 'disables broker for Power Platform token acquisition' {
                Connect-Tenant -ProductNames 'powerplatform' -M365Environment $Endpoint -UseSystemBrowserAuthentication
                Should -Invoke -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $ClientId -eq '1950a258-227b-4e31-a9cf-717495945fc2' -and $DisableBroker
                }
            }

            It 'disables broker for SharePoint token acquisition' {
                Connect-Tenant -ProductNames 'sharepoint' -M365Environment $Endpoint -UseSystemBrowserAuthentication
                Should -Invoke -CommandName Get-MsalAccessToken -Times 1 -ParameterFilter {
                    $ClientId -eq '9bc3ab49-b65d-410a-85ad-de819febfddc' -and $DisableBroker
                }
            }

            It 'uses system-browser Graph authentication and edition-compatible Teams authentication' {
                Connect-Tenant -ProductNames 'aad', 'teams' -M365Environment $Endpoint -UseSystemBrowserAuthentication
                Should -Invoke -CommandName Connect-GraphHelper -Times 1 -ParameterFilter {
                    $UseSystemBrowserAuthentication -and -not $ServicePrincipalParams
                }
                if ($PSEdition -eq 'Desktop') {
                    Should -Invoke -CommandName Get-TeamsAccessTokens -Times 0
                    Should -Invoke -CommandName Connect-MicrosoftTeams -Times 1 -ParameterFilter {
                        -not $DisableWAM -and
                        -not $AccessTokens -and
                        -not $CertificateThumbprint
                    }
                }
                else {
                    Should -Invoke -CommandName Get-TeamsAccessTokens -Times 1 -ParameterFilter {
                        $DisableBroker
                    }
                    Should -Invoke -CommandName Connect-MicrosoftTeams -Times 1 -ParameterFilter {
                        -not $DisableWAM -and
                        $AccessTokens.Count -eq 2 -and
                        -not $CertificateThumbprint
                    }
                }
            }

            It 'retains WAM when system browser authentication is disabled' {
                Connect-Tenant -ProductNames 'teams' -M365Environment $Endpoint
                Should -Invoke -CommandName Get-TeamsAccessTokens -Times 0
                Should -Invoke -CommandName Connect-MicrosoftTeams -Times 1 -ParameterFilter {
                    -not $DisableWAM -and -not $AccessTokens -and -not $CertificateThumbprint
                }
            }

            It 'does not pass delegated controls to service principal connections' {
                $ServicePrincipalParams = @{
                    CertThumbprintParams = @{
                        AppID = 'a'
                        CertificateThumbprint = 'b'
                        Organization = 'c'
                    }
                }
                Connect-Tenant -ProductNames 'aad', 'teams' -M365Environment $Endpoint `
                    -ServicePrincipalParams $ServicePrincipalParams -UseSystemBrowserAuthentication
                Should -Invoke -CommandName Connect-GraphHelper -Times 0 -ParameterFilter {
                    $UseSystemBrowserAuthentication
                }
                Should -Invoke -CommandName Get-TeamsAccessTokens -Times 0
                Should -Invoke -CommandName Connect-MicrosoftTeams -Times 0 -ParameterFilter {
                    $DisableWAM -or $AccessTokens
                }
            }
        }
    }
}
AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
    Remove-Module ConnectHelper -ErrorAction SilentlyContinue
}
