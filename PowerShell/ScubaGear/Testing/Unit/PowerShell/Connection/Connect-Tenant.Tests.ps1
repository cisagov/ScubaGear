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
            function Connect-PnPOnline {throw 'this will be mocked'}
            function Connect-PnPOnline {throw 'this will be mocked'}
            Mock Connect-PnPOnline -MockWith {}
            function Connect-SPOService {throw 'this will be mocked'}
            Mock Connect-SPOService -MockWith {}
            function Connect-MicrosoftTeams{throw 'this will be mocked'}
            Mock Connect-MicrosoftTeams -MockWith {}
            function Add-PowerAppsAccount{throw 'this will be mocked'}
            Mock Add-PowerAppsAccount -MockWith {}
            function Connect-EXOHelper {throw 'this will be mocked'}
            Mock -ModuleName Connection Connect-EXOHelper -MockWith {}
            function Get-MgBetaOrganization {throw 'this will be mocked'}
            Mock Get-MgBetaOrganization -MockWith {
                return [pscustomobject]@{
                    DisplayName     = "DisplayName";
                    Name            = "DomainName";
                    Id              = "TenantId";
                    VerifiedDomains = @(
                        @{
                            isInitial = $false;
                            Name      = "example.onmicrosoft.com"
                        },
                        @{
                            isInitial = $true;
                            Name      = "contoso.onmicrosoft.com"
                        }
                    )
                }
            }
            Mock -CommandName Write-Progress {
            }
        }
        Context 'With Endpoint:  <Endpoint>; ProductNames: <ProductNames>' -ForEach @(
            @{ProductNames = "aad"; Services = @('Connect-GraphHelper')}
            @{ProductNames = "defender"; Services = @('Connect-EXOHelper')}
            @{ProductNames = "exo"; Services = @('Connect-EXOHelper')}
            @{ProductNames = "powerplatform"; Services = @('Add-PowerAppsAccount')}
            @{ProductNames = "sharepoint"; Services = @('Connect-GraphHelper', 'Connect-PnPOnline')}
            @{ProductNames = "teams"; Services = @('Connect-MicrosoftTeams')}
            @{
                ProductNames = "aad", "defender", "exo", "powerplatform", "sharepoint", "teams"
                Services = @(
                    'Connect-GraphHelper',
                    'Connect-EXOHelper',
                    'Add-PowerAppsAccount',
                    'Connect-PnPOnline',
                    'Connect-MicrosoftTeams'
                )
            }

        ){

            It "No Service Principal" {
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $Endpoint
                $FailedAuthList.Length | Should -Be 0
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
                    Should -Invoke -CommandName $Service -Exactly -Times 1 -Because "only want to authenticate to needed service once"
                }
            }

        }
    }
}
AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
    Remove-Module ConnectHelper -ErrorAction SilentlyContinue
}
