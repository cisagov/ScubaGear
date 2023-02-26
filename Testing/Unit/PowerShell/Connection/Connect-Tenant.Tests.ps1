Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/Connection/Connection.psm1") -Function 'Connect-Tenant' -Force

InModuleScope Connection {
    Describe -Tag 'Connection' -Name 'Connect-Tenant' {
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
        Context "When interactively connecting to Commercial Endpoints" {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'M365Environment')]
                $M365Environment = "commercial"
            }
            It 'With -ProductNames "aad", connects to Microsoft Graph' {
                $ProductNames = @("aad")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "defender", connects to Exchange Online' {
                $ProductNames = @("defender")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "exo", connects to Exchange Online' {
                $ProductNames = @("exo")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "onedrive", connects to SharePoint Online' {
                $ProductNames = @("onedrive")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "powerplatform", connects to Power Platform' {
                $ProductNames = @("powerplatform")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "sharepoint", connects to SharePoint Online' {
                $ProductNames = @("sharepoint")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "teams", connects to Microsoft Teams' {
                $ProductNames = @("teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With all products connects to each product' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "powerplatform", "sharepoint", "teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
        }
        Context "When interactively connecting to GCC Endpoints" {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'M365Environment')]
                $M365Environment = "gcc"
            }
            It 'With -ProductNames "aad", connects to Microsoft Graph' {
                $ProductNames = @("aad")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "defender", connects to Exchange Online' {
                $ProductNames = @("defender")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "exo", connects to Exchange Online' {
                $ProductNames = @("exo")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "onedrive", connects to SharePoint Online' {
                $ProductNames = @("onedrive")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "powerplatform", connects to Power Platform' {
                $ProductNames = @("powerplatform")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "sharepoint", connects to SharePoint Online' {
                $ProductNames = @("sharepoint")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "teams", connects to Microsoft Teams' {
                $ProductNames = @("teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With all products, connects to each product' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "powerplatform", "sharepoint", "teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
        }
        Context "When interactively connecting to GCC High Endpoints" {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'M365Environment')]
                $M365Environment = "gcchigh"
            }
            It 'With -ProductNames "aad", connects to Microsoft Graph' {
                $ProductNames = @("aad")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "defender", connects to Exchange Online' {
                $ProductNames = @("defender")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "exo", connects to Exchange Online' {
                $ProductNames = @("exo")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "onedrive", connects to SharePoint Online' {
                $ProductNames = @("onedrive")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "powerplatform", connects to Power Platform' {
                $ProductNames = @("powerplatform")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "sharepoint", connects to SharePoint Online' {
                $ProductNames = @("sharepoint")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "teams", connects to Microsoft Teams' {
                $ProductNames = @("teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With all products connects to each product' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "powerplatform", "sharepoint", "teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
        }
        Context "When interactively connecting to DOD Endpoints" {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'M365Environment')]
                $M365Environment = "dod"
            }
            It 'With -ProductNames "aad", connects to Microsoft Graph' {
                $ProductNames = @("aad")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "defender", connects to Exchange Online' {
                $ProductNames = @("defender")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "exo", connects to Exchange Online' {
                $ProductNames = @("exo")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "onedrive", connects to SharePoint Online' {
                $ProductNames = @("onedrive")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "powerplatform", connects to Power Platform' {
                $ProductNames = @("powerplatform")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "sharepoint", connects to SharePoint Online' {
                $ProductNames = @("sharepoint")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "teams", connects to Microsoft Teams' {
                $ProductNames = @("teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With all products connects to each product' {
                $ProductNames = @("aad", "defender", "exo", "onedrive", "powerplatform", "sharepoint", "teams")
                $FailedAuthList = Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
                $FailedAuthList.Length | Should -Be 0
            }
        }
    }
}
AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
}