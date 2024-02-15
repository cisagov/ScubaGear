$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Get-ServicePrincipalParams'

Describe -Tag 'Orchestrator' -Name 'Get-ServicePrincipalParams' {
    InModuleScope Orchestrator {
        Context "Service Principal provided"{
            BeforeAll{
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'BoundParameters')]
                $BoundParameters = @{
                    CertificateThumbprint = 'WPOEALFN425A'
                    AppID = '34289UFAHWFALL'
                    Organization = 'example.onmicrosoft.com'
                }
            }
            It 'Does not throw exception' {
                {Get-ServicePrincipalParams -BoundParameters $BoundParameters} | Should -Not -Throw
            }
            It "All required items are present"{
                $Results = Get-ServicePrincipalParams -BoundParameters $BoundParameters
                $Results | Should -BeOfType [hashtable]
                $Results.Count | Should -BeExactly 1
                $Results.CertThumbprintParams.Count | Should -BeExactly 3
            }
        }
        Context "Partial data for Service Principal"{
            It "Only AppId"{
                $BoundParameters = @{
                    AppID = '34289UFAHWFALL'
                }
                {Get-ServicePrincipalParams -BoundParameters $BoundParameters} |
                    Should -Throw  'Missing parameters required for authentication with Service Principal Auth; Run Get-Help Invoke-Scuba for details on correct arguments'
            }
            It "Only Thumbprint Only"{
                $BoundParameters = @{
                    CertificateThumbprint = 'WPOEALFN425A'
                }
                {Get-ServicePrincipalParams -BoundParameters $BoundParameters} |
                    Should -Throw  'Missing parameters required for authentication with Service Principal Auth; Run Get-Help Invoke-Scuba for details on correct arguments'
            }
            It "Only Organization Only"{
                $BoundParameters = @{
                    Organization = 'example.onmicrosoft.com'
                }
                {Get-ServicePrincipalParams -BoundParameters $BoundParameters} |
                    Should -Throw  'Missing parameters required for authentication with Service Principal Auth; Run Get-Help Invoke-Scuba for details on correct arguments'
            }
        }
        Context "No Service Principal provided"{
            It 'Throws an error if no correct Service Principal Params are passed in' {
                $BoundParameters = @{
                }
                {Get-ServicePrincipalParams -BoundParameters $BoundParameters} | Should -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}