Import-Module ../../../../PowerShell/ScubaGear/Modules/Connection/Connection.psm1

InModuleScope Connection {
    Describe 'Connect-Tenant' {
        BeforeAll {
            function Connect-MgGraph {}
            Mock -ModuleName Connection Connect-MgGraph -MockWith {}
            function Connect-PnPOnline {}
            Mock -ModuleName Connection Connect-PnPOnline -MockWith {}
            function Connect-SPOService {}
            Mock -ModuleName Connection Connect-SPOService -MockWith {}
            function Connect-MicrosoftTeams {}
            Mock -ModuleName Connection Connect-MicrosoftTeams -MockWith {}
            function Add-PowerAppsAccount {}
            Mock -ModuleName Connection Add-PowerAppsAccount -MockWith {}
            function Connect-EXOHelper {}
            Mock -ModuleName Connection Connect-EXOHelper -MockWith {}
            function Select-MgProfile {}
            Mock -ModuleName Connection Select-MgProfile -MockWith {}
            function Get-MgProfile {}
            Mock -ModuleName Connection Get-MgProfile -MockWith {
                [pscustomobject]@{
                    Name = "alpha";
                }
            }
            function Get-MgOrganization {}
            Mock -ModuleName Connection Get-MgOrganization -MockWith {
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
        Context "When connecting to Commercial Endpoints" {
            It 'With -ProductNames "aad" connects to Microsoft Graph' {
                $ProductNames = @("aad")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'commercial'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "exo" connects to Exchange Online' {
                $ProductNames = @("exo")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'commercial'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "defender" connects to Exchange Online' {
                $ProductNames = @("defender")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'commercial'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "onedrive" connects to SharePoint Online' {
                $ProductNames = @("onedrive")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'commercial'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "powerplatform" connects to Power Platform' {
                $ProductNames = @("powerplatform")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'commercial'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "sharepoint" connects to SharePoint Online' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "sharepoint", "teams")
                $ProductNames = @("sharepoint")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'commercial'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "teams" connects to Microsoft Teams' {
                $ProductNames = @("teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'commercial'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With all products connects to each product' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "powerplatform", "sharepoint", "teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'commercial'
                $FailedAuthList.Length | Should -Be 0
            }
        }
        Context "When connecting to GCC Endpoints" {
            It 'With -ProductNames "aad" connects to Microsoft Graph' {
                $ProductNames = @("aad")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcc'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "exo" connects to Exchange Online' {
                $ProductNames = @("exo")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcc'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "defender" connects to Exchange Online' {
                $ProductNames = @("defender")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcc'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "onedrive" connects to SharePoint Online' {
                $ProductNames = @("onedrive")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcc'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "powerplatform" connects to Power Platform' {
                $ProductNames = @("powerplatform")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcc'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "sharepoint" connects to SharePoint Online' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "sharepoint", "teams")
                $ProductNames = @("sharepoint")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcc'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "teams" connects to Microsoft Teams' {
                $ProductNames = @("teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcc'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With all products connects to each product' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "powerplatform", "sharepoint", "teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcc'
                $FailedAuthList.Length | Should -Be 0
            }
        }
        Context "When connecting to GCC High Endpoints" {
            It 'With -ProductNames "aad" connects to Microsoft Graph' {
                $ProductNames = @("aad")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcchigh'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "exo" connects to Exchange Online' {
                $ProductNames = @("exo")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcchigh'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "defender" connects to Exchange Online' {
                $ProductNames = @("defender")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcchigh'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "onedrive" connects to SharePoint Online' {
                $ProductNames = @("onedrive")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcchigh'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "powerplatform" connects to Power Platform' {
                $ProductNames = @("powerplatform")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcchigh'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "sharepoint" connects to SharePoint Online' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "sharepoint", "teams")
                $ProductNames = @("sharepoint")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcchigh'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "teams" connects to Microsoft Teams' {
                $ProductNames = @("teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcchigh'
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With all products connects to each product' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "powerplatform", "sharepoint", "teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment 'gcchigh'
                $FailedAuthList.Length | Should -Be 0
            }
        }
    }
}
AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
}