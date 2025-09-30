$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-Connection' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Connection' {
        BeforeAll {
            function Connect-Tenant {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Connect-Tenant {@('aad')}
        }
        It 'Login is false'{
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    LogIn = $false
                    M365Environment = 'commercial'
                }
                Invoke-Connection -ScubaConfig $ScubaConfig -BoundParameters @{} | Should -BeNullOrEmpty
        }
        It 'Login is true'{
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    LogIn = $true
                    M365Environment = 'commercial'
                }
                Invoke-Connection -ScubaConfig $ScubaConfig -BoundParameters @{} | Should -Not -BeNullOrEmpty
        }
        It 'Has AppId'{
                Mock -ModuleName Orchestrator Connect-Tenant {@('aad')}
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    LogIn = $true
                    M365Environment = 'commercial'
                }
                $BoundParameters = @{
                    AppID = "a"
                    CertificateThumbprint = "b"
                    Organization = "c"
                }
                Invoke-Connection -ScubaConfig $ScubaConfig -BoundParameters $BoundParameters | Should -Not -BeNullOrEmpty
                Should -Invoke -CommandName Connect-Tenant -Exactly -Times 1
        }
    }
}
