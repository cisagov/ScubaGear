Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/Connection/Connection.psm1") -Function 'Connect-Tenant' -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1") -Force

InModuleScope Connection {
    Describe -Tag 'Connection' -Name "Connect-Tenant" -ForEach @(
        @{Endpoint = 'commercial'}
        @{Endpoint = 'gcc'}
        @{Endpoint = 'gcchigh'}
        @{Endpoint = 'dod'}
    ){
        BeforeAll {
            Mock Connect-MgGraph -MockWith {}
            Mock Connect-PnPOnline -MockWith {}
            Mock Connect-SPOService -MockWith {}
            Mock Connect-MicrosoftTeams -MockWith {}
            Mock Add-PowerAppsAccount -MockWith {}
            function Connect-EXOHelper {}
            Mock Connect-EXOHelper -MockWith {}
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
        It 'With Endpoint:  <Endpoint>; ProductNames: <ProductNames>' -ForEach @(
            @{ProductNames = "aad"}
            @{ProductNames = "defender"}
            @{ProductNames = "exo"}
            @{ProductNames = "powerplatform"}
            @{ProductNames = "sharepoint"}
            @{ProductNames = "teams"}
            @{ProductNames = "aad", "defender", "exo", "powerplatform", "sharepoint", "teams"}

        ){
            $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $Endpoint
            $FailedAuthList.Length | Should -Be 0
        }
    }
}
AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
    Remove-Module ConnectHelper -ErrorAction SilentlyContinue
}
