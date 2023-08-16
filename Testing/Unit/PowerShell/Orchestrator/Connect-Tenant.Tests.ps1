$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Connect-Tenant' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Connection' {
        Context 'When interactively connecting to commercial Endpoints' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ConnectParams')]
                $ConnectParams = @{
                    LogIn           = $true
                    M365Environment = "commercial"
                    BoundParameters = @{}
                }
                function Connect-Tenant {}
                Mock -ModuleName Orchestrator Connect-Tenant -MockWith {@()}
            }
            It 'With -ProductNames "aad", connects to Microsoft Graph' {
                $ConnectParams += @{
                    ProductNames = 'aad'
                }
                Invoke-Connection @ConnectParams
                Should -Invoke -CommandName Connect-Tenant -Times 1 -Exactly
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "defender", connects to Microsoft Defender for Office 365' {
                $ConnectParams += @{
                    ProductNames = 'defender'
                }
                $FailedAuthList = Invoke-Connection @ConnectParams
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "exo", connects to Exchange Online' {
                $ConnectParams += @{
                    ProductNames = 'exo'
                }
                $FailedAuthList = Invoke-Connection @ConnectParams
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "powerplatform", connects to Power Platform' {
                $ConnectParams += @{
                    ProductNames = 'powerplatform'
                }
                $FailedAuthList = Invoke-Connection @ConnectParams
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "sharepoint", connects to SharePoint Online' {
                $ConnectParams += @{
                    ProductNames = 'sharepoint'
                }
                $FailedAuthList = Invoke-Connection @ConnectParams
                $FailedAuthList.Length | Should -Be 0
            }
            It 'With -ProductNames "teams", connects to Microsoft Teams' {
                $ConnectParams += @{
                    ProductNames = 'teams'
                }
                $FailedAuthList = Invoke-Connection @ConnectParams
                $FailedAuthList.Length | Should -Be 0
            }
            It 'authenticates to all products' {
                $ConnectParams += @{
                    ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                }
                $FailedAuthList = Invoke-Connection @ConnectParams
                $FailedAuthList.Length | Should -Be 0
            }
        }
        Context 'When -Login $false' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ConnectParams')]
                $ConnectParams = @{
                    LogIn           = $false
                    M365Environment = "gcc"
                    BoundParameters = @{}
                }
                function Connect-Tenant {}
                Mock -ModuleName Orchestrator Connect-Tenant -MockWith {@()}
            }
            It 'does not authenticate' {
                $ConnectParams += @{
                    ProductNames = 'aad'
                }
                Invoke-Connection @ConnectParams
                Should -Invoke -CommandName Connect-Tenant -Times 0 -Exactly
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
