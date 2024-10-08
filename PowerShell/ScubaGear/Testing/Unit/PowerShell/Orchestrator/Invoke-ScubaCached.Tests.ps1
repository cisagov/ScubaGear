$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-SCuBACached' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-SCuBACached' {
        BeforeAll {
            Mock -ModuleName Orchestrator Remove-Resources {}
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
            function Merge-JsonOutput {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Merge-JsonOutput {}
            function Disconnect-SCuBATenant {}
            Mock -ModuleName Orchestrator Disconnect-SCuBATenant
            function ConvertTo-ResultsCsv {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator ConvertTo-ResultsCsv {}
            function Set-Utf8NoBom {}
            Mock -ModuleName Orchestrator Set-Utf8NoBom

            Mock -CommandName Write-Debug {}
            Mock -CommandName New-Item {}
            Mock -CommandName Get-Content {}
            Mock -CommandName Get-Member { $true }
            Mock -CommandName New-Guid { "00000000-0000-0000-0000-000000000000" }
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
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames defender should not throw' {
                $SplatParams += @{
                    ProductNames = @("defender")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames exo should not throw' {
                $SplatParams += @{
                    ProductNames = @("exo")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames powerplatform should not throw' {
                $SplatParams += @{
                    ProductNames = @("powerplatform")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames teams should not throw' {
                $SplatParams += @{
                    ProductNames = @("teams")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
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
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames defender should not throw' {
                $SplatParams += @{
                    ProductNames = @("defender")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames exo should not throw' {
                $SplatParams += @{
                    ProductNames = @("exo")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames powerplatform should not throw' {
                $SplatParams += @{
                    ProductNames = @("powerplatform")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames teams should not throw' {
                $SplatParams += @{
                    ProductNames = @("teams")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given an existing UUID should not generate a new one' {
                # Get-Member was mocked above to return True so as far as the
                # provider can tell, the existing output already has a UUID
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
                Should -Invoke -CommandName New-Guid -Exactly -Times 0
            }
            It 'Given output without a UUID should generate a new one' {
                Mock -CommandName Get-Member { $false }
                # Now Get-Member will return False so as far as the provider
                # can tell, the existing output does not have a UUID
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
                Should -Invoke -CommandName New-Guid -Exactly -Times 1
            }
        }
        Context 'When checking module version' {
            It 'Given -Version should not throw' {
                {Invoke-SCuBACached -Version} | Should -Not -Throw
            }
        }
        Context 'When modifying the CSV output files names' {
            It 'Given -OutCsvFileName should not throw' {
                $SplatParams += @{
                    OutCsvFileName = "a"
                }
                {Invoke-SCuBACached -Version} | Should -Not -Throw
            }
            It 'Given -OutActionPlanFileName should not throw' {
                $SplatParams += @{
                    OutActionPlanFileName = "a"
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given both -OutCsvFileName and -OutActionPlanFileName should not throw' {
                $SplatParams += @{
                    OutCsvFileName = "a"
                    OutActionPlanFileName = "b"
                }
                {Invoke-SCuBACached @SplatParams} | Should -Not -Throw
            }
            It 'Given -OutCsvFileName and -OutActionPlanFileName equal should throw' {
                $SplatParams += @{
                    OutCsvFileName = "a"
                    OutActionPlanFileName = "a"
                }
                {Invoke-SCuBACached @SplatParams} | Should -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
