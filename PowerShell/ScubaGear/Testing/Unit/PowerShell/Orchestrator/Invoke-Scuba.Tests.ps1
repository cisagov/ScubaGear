$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-SCuBA' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba' {
        BeforeAll {
            Mock -ModuleName Orchestrator Remove-Resources {}
            Mock -ModuleName Orchestrator Import-Resources {}
            Mock -ModuleName Orchestrator Invoke-Connection { @() }
            function Get-TenantDetail {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
            function Invoke-ProviderList {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Invoke-ProviderList {}
            function Invoke-RunRego {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Invoke-RunRego {}

            Mock -ModuleName Orchestrator Invoke-ReportCreation {}
            Mock -ModuleName Orchestrator Merge-JsonOutput {}
            function Disconnect-SCuBATenant {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Disconnect-SCuBATenant {}

            function Get-ScubaDefault {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Get-ScubaDefault {"."}

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
            It 'Should only run each baseline once if provider names contains duplicates' {
                {Invoke-Scuba -ProductNames aad,aad} | Should -Not -Throw
                Should -Invoke Invoke-ReportCreation -ParameterFilter {$ProductNames -eq 'aad'}
            }
        }
        Context 'Service Principal provided'{
            It 'All items given as not null or empty'{
                $SplatParams += @{
                    AppID = "a"
                    CertificateThumbprint = "b"
                    Organization = "c"
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-Connection -Exactly -Times 1 -ParameterFilter {$BoundParameters['AppID'] -eq $SplatParams['AppId']}
            }
            It 'Items given as empty string'{
                $SplatParams += @{
                    AppID = ""
                }
                {Invoke-Scuba @SplatParams} | Should -Throw
            }
            It 'Items given as null'{
                $SplatParams += @{
                    AppID = $null
                }
                {Invoke-Scuba @SplatParams} | Should -Throw
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
