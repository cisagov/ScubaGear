$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-ReportCreation' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-ReportCreation' {
        BeforeAll {
            function New-Report {}
            Mock -ModuleName Orchestrator New-Report {}
            function Pluralize {}
            Mock -ModuleName Orchestrator Pluralize {}
            function Import-SecureBaseline{}
            Mock -ModuleName Orchestrator Import-SecureBaseline {
                return @()
            }
            Mock -CommandName Write-Progress {}
            Mock -CommandName Join-Path { "." }
            Mock -CommandName Out-File {}
            Mock -CommandName ConvertTo-Html {}
            Mock -CommandName Copy-Item {}
            Mock -CommandName Get-Content {}
            Mock -CommandName Add-Type {}
            Mock -CommandName Invoke-Item {}

        }
        Context 'When creating the reports from Provider and OPA results JSON' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ProviderParameters')]
                $ProviderParameters = @{
                    TenantDetails       = '{"DisplayName": "displayName"}';
                    DarkMode            = $false;
                    ModuleVersion       = '1.0';
                    OutFolderPath       = "./"
                    OutProviderFileName = "ProviderSettingsExport"
                    OutRegoFileName     = "TestResults"
                    OutReportName       = "BaselineReports"
                }
            }
            It 'Do it quietly (Do not automatically show report)' {
                $ProviderParameters += @{
                    ProductNames = @("aad")
                }
                { Invoke-ReportCreation @ProviderParameters -Quiet} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-Item -Exactly -Times 0
                $ProviderParameters.ProductNames = @()
            }
            It 'Show report' {
                $ProviderParameters += @{
                    ProductNames = @("aad")
                }
                { Invoke-ReportCreation @ProviderParameters} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-Item -Exactly -Times 1 -ParameterFilter {-Not [string]::IsNullOrEmpty($Path) }
                $ProviderParameters.ProductNames = @()
            }
            It 'With -ProductNames "aad", should not throw' {
                $ProviderParameters += @{
                    ProductNames = @("aad")
                }
                { Invoke-ReportCreation @ProviderParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "defender", should not throw' {
                $ProviderParameters += @{
                    ProductNames = @("defender")
                }
                { Invoke-ReportCreation @ProviderParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "exo", should not throw' {
                $ProviderParameters += @{
                    ProductNames = @("exo")
                }
                { Invoke-ReportCreation @ProviderParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "powerplatform", should not throw' {
                $ProviderParameters += @{
                    ProductNames = @("powerplatform")
                }
                { Invoke-ReportCreation @ProviderParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "sharepoint", should not throw' {
                $ProviderParameters += @{
                    ProductNames = @("sharepoint")
                }
                { Invoke-ReportCreation @ProviderParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "teams", should not throw' {
                $ProviderParameters += @{
                    ProductNames = @("teams")
                }
                { Invoke-ReportCreation @ProviderParameters } | Should -Not -Throw
            }
            It 'With all products, should not throw' {
                $ProviderParameters += @{
                    ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                }
                { Invoke-ReportCreation @ProviderParameters } | Should -Not -Throw
            }
        }
        Context 'When creating the reports with -Quiet True' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ProviderParameters')]
                $ProviderParameters = @{
                    DarkMode            = $false;
                    TenantDetails       = '{"DisplayName": "displayName"}';
                    ModuleVersion       = '1.0';
                    OutFolderPath       = "./"
                    OutProviderFileName = "ProviderSettingsExport"
                    OutRegoFileName     = "TestResults"
                    OutReportName       = "BaselineReports"
                    Quiet               = $true
                }
            }
            It 'With all products, should not throw' {
                $ProviderParameters += @{
                    ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                }
                { Invoke-ReportCreation @ProviderParameters } | Should -Not -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}