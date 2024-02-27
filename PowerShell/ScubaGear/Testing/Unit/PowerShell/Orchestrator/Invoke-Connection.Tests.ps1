$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-Connection' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Connection' {
        BeforeAll {
            function Connect-Tenant {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Connect-Tenant {@('aad')}
        }
        It 'Login is false'{
            Invoke-Connection -Login $false -ProductNames 'aad' -BoundParameters @{} | Should -BeNullOrEmpty
        }
        It 'Login is true'{
            Invoke-Connection -Login $true -ProductNames 'aad' -BoundParameters @{} | Should -Not -BeNullOrEmpty
        }
        It 'Has AppId'{
            Mock -ModuleName Orchestrator Connect-Tenant {@('aad')}
            $BoundParameters = @{
                AppID = "a"
                CertificateThumbprint = "b"
                Organization = "c"
            }
            Invoke-Connection -Login $true -ProductNames 'aad' -BoundParameters $BoundParameters | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName Connect-Tenant -Exactly -Times 1
        }
    }
}