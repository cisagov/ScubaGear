$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-RunCached' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-RunCached' {
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
            function Invoke-ReportCreation {}
            Mock -ModuleName Orchestrator Invoke-ReportCreation {}
            function Disconnect-SCuBATenant {}
            Mock -ModuleName Orchestrator Disconnect-SCuBATenant

            Mock -CommandName New-Item {}
            Mock -CommandName Get-Content {}
        }
        Context 'When checking the conformance of commercial tenants' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'SplatParams')]
                $SplatParams = @{
                    M365Environment = 'commercial'
                }
            }
            It 'Given -ProductNames aad should not throw' {
                $SplatParams += @{
                    ProductNames = @("aad")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames defender should not throw' {
                $SplatParams += @{
                    ProductNames = @("defender")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames exo should not throw' {
                $SplatParams += @{
                    ProductNames = @("exo")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames powerplatform should not throw' {
                $SplatParams += @{
                    ProductNames = @("powerplatform")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames teams should not throw' {
                $SplatParams += @{
                    ProductNames = @("teams")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
        }
        Context 'When omitting the export of the commercial tenant provider json' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'SplatParams')]
                $SplatParams = @{
                    M365Environment = 'commercial'
                    ExportProvider = $false
                }
            }
            It 'Given -ProductNames aad should not throw' {
                $SplatParams += @{
                    ProductNames = @("aad")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames defender should not throw' {
                $SplatParams += @{
                    ProductNames = @("defender")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames exo should not throw' {
                $SplatParams += @{
                    ProductNames = @("exo")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames powerplatform should not throw' {
                $SplatParams += @{
                    ProductNames = @("powerplatform")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames teams should not throw' {
                $SplatParams += @{
                    ProductNames = @("teams")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                }
                {Invoke-RunCached @SplatParams} | Should -Not -Throw
            }
        }
        Context 'When checking module version' {
            It 'Given -Version should not throw' {
                {Invoke-RunCached -Version} | Should -Not -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}