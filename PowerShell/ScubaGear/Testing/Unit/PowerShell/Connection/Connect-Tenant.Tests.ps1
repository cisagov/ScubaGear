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
            function Connect-GraphHelper {throw 'this will be mocked'}
            Mock Connect-GraphHelper -MockWith {}
            # SharePoint now uses REST API - no PnP/SPO connection needed
            function Connect-MicrosoftTeams{throw 'this will be mocked'}
            Mock Connect-MicrosoftTeams -MockWith {}
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
            function Get-MsalAccessToken {throw 'this will be mocked'}
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
    }
}
AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
    Remove-Module ConnectHelper -ErrorAction SilentlyContinue
}
