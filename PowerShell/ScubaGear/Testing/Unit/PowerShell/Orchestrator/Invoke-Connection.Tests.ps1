$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-Connection' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Connection' {
        BeforeAll {
            function Connect-Tenant {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($ProductNames, $M365Environment, $ServicePrincipalParams)
                throw 'this will be mocked'
            }
            Mock -ModuleName Orchestrator Connect-Tenant {$null}
            function Get-ServicePrincipalParams {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Get-ServicePrincipalParams { @{CertThumbprintParams = @{AppID="a"; CertificateThumbprint="b"; Organization="c"}} }
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
        It 'omits the default environment when interactive discovery is requested' {
            $ScubaConfig = [pscustomobject]@{
                ProductNames = @('aad')
                M365Environment = 'commercial'
                LogIn = $true
            }
            Mock Connect-Tenant {
                [pscustomobject]@{ DetectedM365Environment = 'gcchigh'; ProdAuthFailed = @() }
            }
            $Result = Invoke-Connection -ScubaConfig $ScubaConfig -AutoDetectEnvironment
            $Result.DetectedM365Environment | Should -Be 'gcchigh'
            Should -Invoke Connect-Tenant -Times 1 -Exactly -ParameterFilter { -not $M365Environment }
        }
        It 'passes the supplied environment when discovery is disabled' {
            $ScubaConfig = [pscustomobject]@{
                ProductNames = @('aad')
                M365Environment = 'dod'
                LogIn = $true
            }
            Invoke-Connection -ScubaConfig $ScubaConfig
            Should -Invoke Connect-Tenant -Times 1 -Exactly -ParameterFilter { $M365Environment -eq 'dod' }
        }
    }
}
