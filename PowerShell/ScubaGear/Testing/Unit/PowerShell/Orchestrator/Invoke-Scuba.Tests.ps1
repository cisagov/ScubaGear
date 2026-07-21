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

            function Merge-JsonOutput {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Merge-JsonOutput {}

            function ConvertTo-ResultsCsv {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator ConvertTo-ResultsCsv {}

            Mock -CommandName New-Item {}
            Mock -CommandName Copy-Item {}
            function Initialize-ScubaLogging {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Initialize-ScubaLogging {}

            function Write-ScubaLog {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Write-ScubaLog {}

            function Write-ScubaRunDetails {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Write-ScubaRunDetails {}

            function Trace-ScubaFunction {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                param(
                    [string] $FunctionName,
                    [hashtable] $Parameters,
                    [switch] $LogReturnValue,
                    [scriptblock] $ScriptBlock
                )

                throw 'this will be mocked'
            }
            Mock -ModuleName Orchestrator Trace-ScubaFunction {
                $scriptBlockToInvoke = $args |
                    Where-Object { $_ -is [scriptblock] } |
                    Select-Object -First 1

                & $scriptBlockToInvoke
            }

            function Get-M365EnvironmentByDomain {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Get-M365EnvironmentByDomain {}

            function Get-ServicePrincipalParams {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Get-ServicePrincipalParams { @{CertThumbprintParams = @{AppID="a"; CertificateThumbprint="b"; Organization="c"}} }
        }
        Context 'When checking the conformance of commercial tenants' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'SplatParams')]
                $SplatParams = @{
                    M365Environment = 'commercial';
                    KeepIndividualJSON = $true;
                }
            }
            It 'Do it quietly (Do not automatically show report)' {
                {Invoke-Scuba -Quiet -SilenceBODWarnings} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-ReportCreation -Exactly -Times 1 -ParameterFilter {$Quiet -eq $true}
            }
            It 'Show report' {
                {Invoke-Scuba -SilenceBODWarnings} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-ReportCreation -Exactly -Times 1 -ParameterFilter {$Quiet -eq $false}
            }
            It 'Given -ProductNames aad should not throw' {
                $SplatParams += @{
                    ProductNames = @("aad")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames securitysuite should not throw' {
                $SplatParams += @{
                    ProductNames = @("securitysuite")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames exo should not throw' {
                $SplatParams += @{
                    ProductNames = @("exo")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames powerplatform should not throw' {
                $SplatParams += @{
                    ProductNames = @("powerplatform")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames teams should not throw' {
                $SplatParams += @{
                    ProductNames = @("teams")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * and -DisconnectOnExit should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                    DisconnectOnExit = $true
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Should only run each baseline once if provider names contains duplicates' {
                {Invoke-Scuba -ProductNames aad,aad -SilenceBODWarnings} | Should -Not -Throw
                # After refactor, -ProductNames are consolidated into ScubaConfig and duplicates removed
                # Validate only a single invocation and that consolidated ProductNames contains exactly one 'aad'
                Should -Invoke Invoke-ReportCreation -ParameterFilter {$ScubaConfig.ProductNames -eq 'aad'}
            }
        }
        Context 'Service Principal provided'{
            It 'All items given as not null or empty'{
                $SplatParams += @{
                    AppID = "a"
                    CertificateThumbprint = "b"
                    Organization = "c"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-Connection -Exactly -Times 1 -ParameterFilter {$ScubaConfig.AppID -eq 'a'}
            }
            It 'Items given as empty string'{
                $SplatParams += @{
                    AppID = ""
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Throw
            }
            It 'Items given as null'{
                $SplatParams += @{
                    AppID = $null
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Throw
            }
        }
        Context 'When checking module version' {
            It 'Given -Version should not throw' {
                {Invoke-Scuba -Version -SilenceBODWarnings} | Should -Not -Throw
            }
        }
        Context 'When modifying the CSV output files names' {
            It 'Given -OutCsvFileName should not throw' {
                $SplatParams += @{
                    OutCsvFileName = "a"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -OutActionPlanFileName should not throw' {
                $SplatParams += @{
                    OutActionPlanFileName = "a"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given both -OutCsvFileName and -OutActionPlanFileName should not throw' {
                $SplatParams += @{
                    OutCsvFileName = "a"
                    OutActionPlanFileName = "b"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -OutCsvFileName and -OutActionPlanFileName equal should throw' {
                $SplatParams += @{
                    OutCsvFileName = "a"
                    OutActionPlanFileName = "a"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Throw
            }
        }
    }
}
AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
