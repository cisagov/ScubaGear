$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-SCuBA' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba' {
        BeforeAll {
            function Remove-Resources {}
            Mock -ModuleName Orchestrator Remove-Resources {}
            function Import-Resources {}
            Mock -ModuleName Orchestrator Import-Resources {}
            function Invoke-Connection {}
            Mock -ModuleName Orchestrator Invoke-Connection { @() }
            function Get-TenantDetail {}
            Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
            function Invoke-ProviderList {}
            Mock -ModuleName Orchestrator Invoke-ProviderList {}
            function Invoke-RunRego {}
            Mock -ModuleName Orchestrator Invoke-RunRego {}

            Mock -ModuleName Orchestrator Invoke-ReportCreation {}
            function Disconnect-SCuBATenant {}
            Mock -ModuleName Orchestrator Disconnect-SCuBATenant {}

            Mock -CommandName New-Item {}
            Mock -CommandName Copy-Item {}
        }
        Context 'When checking the conformance of commercial tenants' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'SplatParams')]
                $SplatParams = @{
                    M365Environment = 'commercial';
                }
            }
            It 'Do it quietly (Do not automatically show report)' {
                {Invoke-Scuba -Quiet} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-ReportCreation -Exactly -Times 1 -ParameterFilter {$Quiet -eq $true}
            }
            It 'Show report' {
                {Invoke-Scuba} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-ReportCreation -Exactly -Times 1 -ParameterFilter {$Quiet -eq $false}
            }
            It 'Given -ProductNames aad should not throw' {
                $SplatParams += @{
                    ProductNames = @("aad")
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames defender should not throw' {
                $SplatParams += @{
                    ProductNames = @("defender")
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames exo should not throw' {
                $SplatParams += @{
                    ProductNames = @("exo")
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames powerplatform should not throw' {
                $SplatParams += @{
                    ProductNames = @("powerplatform")
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames teams should not throw' {
                $SplatParams += @{
                    ProductNames = @("teams")
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * and -DisconnectOnExit should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                    DisconnectOnExit = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
        }
        Context 'When checking module version' {
            It 'Given -Version should not throw' {
                {Invoke-Scuba -Version} | Should -Not -Throw
            }
        }
    }
}
AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}