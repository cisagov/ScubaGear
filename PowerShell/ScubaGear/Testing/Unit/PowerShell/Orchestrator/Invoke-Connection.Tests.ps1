$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-Connection' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Connection' {
        BeforeAll {
            function Connect-Tenant {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Connect-Tenant {$null}
        }
        It 'Basic connection without AppID'{
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    M365Environment = 'commercial'
                }
                {Invoke-Connection -ScubaConfig $ScubaConfig} | Should -Not -Throw
        }
        It 'Connection with all required parameters'{
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    M365Environment = 'commercial'
                }
                {Invoke-Connection -ScubaConfig $ScubaConfig} | Should -Not -Throw
        }
        It 'Has AppId - Service Principal Auth'{
                Mock -ModuleName Orchestrator Connect-Tenant {$null}
                Mock -ModuleName Orchestrator Get-ServicePrincipalParams { @{CertThumbprintParams = @{AppID="a"; CertificateThumbprint="b"; Organization="c"}} }
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    M365Environment = 'commercial'
                    LogIn = $true
                    AppID = "a"
                    CertificateThumbprint = "b"
                    Organization = "c"
                }
                Invoke-Connection -ScubaConfig $ScubaConfig
                Should -Invoke -CommandName Connect-Tenant -Exactly -Times 1 -Scope It
        }
    }
}
