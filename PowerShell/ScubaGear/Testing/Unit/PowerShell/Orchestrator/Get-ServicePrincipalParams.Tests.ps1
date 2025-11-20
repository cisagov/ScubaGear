$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Get-ServicePrincipalParams'

Describe -Tag 'Orchestrator' -Name 'Get-ServicePrincipalParams' {
    InModuleScope Orchestrator {
        Context "Service Principal provided"{
            BeforeAll{
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ScubaConfig')]
                $ScubaConfig = [PSCustomObject]@{
                    CertificateThumbprint = 'WPOEALFN425A'
                    AppID = '34289UFAHWFALL'
                    Organization = 'example.onmicrosoft.com'
                }
            }
            It 'Does not throw exception' {
                {Get-ServicePrincipalParams -ScubaConfig $ScubaConfig} | Should -Not -Throw
            }
            It "All required items are present"{
                $Results = Get-ServicePrincipalParams -ScubaConfig $ScubaConfig
                $Results | Should -BeOfType [hashtable]
                $Results.Count | Should -BeExactly 1
                $Results.CertThumbprintParams.Count | Should -BeExactly 3
            }
        }
        Context "Partial data for Service Principal"{
            It "Only AppId"{
                $ScubaConfig = [PSCustomObject]@{
                    AppID = '34289UFAHWFALL'
                }
                {Get-ServicePrincipalParams -ScubaConfig $ScubaConfig} |
                    Should -Throw  'Missing parameters required for authentication with Service Principal Auth; Run Get-Help Invoke-Scuba for details on correct arguments'
            }
            It "Only Thumbprint Only"{
                $ScubaConfig = [PSCustomObject]@{
                    CertificateThumbprint = 'WPOEALFN425A'
                }
                {Get-ServicePrincipalParams -ScubaConfig $ScubaConfig} |
                    Should -Throw  'Missing parameters required for authentication with Service Principal Auth; Run Get-Help Invoke-Scuba for details on correct arguments'
            }
            It "Only Organization Only"{
                $ScubaConfig = [PSCustomObject]@{
                    Organization = 'example.onmicrosoft.com'
                }
                {Get-ServicePrincipalParams -ScubaConfig $ScubaConfig} |
                    Should -Throw  'Missing parameters required for authentication with Service Principal Auth; Run Get-Help Invoke-Scuba for details on correct arguments'
            }
        }
        Context "No Service Principal provided"{
            It 'Throws an error if no correct Service Principal Params are passed in' {
                $ScubaConfig = [PSCustomObject]@{
                }
                {Get-ServicePrincipalParams -ScubaConfig $ScubaConfig} | Should -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
