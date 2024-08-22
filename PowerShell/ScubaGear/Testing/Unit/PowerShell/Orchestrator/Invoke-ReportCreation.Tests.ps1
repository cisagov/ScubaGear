$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
$CreateReportPath = '../../../../Modules/CreateReport/CreateReport.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function Invoke-ReportCreation -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $CreateReportPath) -Function New-Report, Import-SecureBaseline -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-ReportCreation' {
        BeforeAll {
            Mock -ModuleName Orchestrator New-Report {}
            Mock -ModuleName Orchestrator Pluralize {}
            Mock -ModuleName Orchestrator Import-SecureBaseline {
                @{}
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
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ConfigParameters')]
                $ConfigParameters = @{
                    OutProviderFileName = "ProviderSettingsExport";
                    OutRegoFileName     = "TestResults";
                    OutReportName       = "BaselineReports";
                }
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ReportParameters')]
                $ReportParameters = @{
                    ScubaConfig = @{}
                    TenantDetails       = '{"DisplayName": "displayName"}';
                    DarkMode            = $false;
                    ModuleVersion       = '1.0';
                    OutFolderPath       = "./"
                }
            }
            It 'Do it quietly (Do not automatically show report)' {
                $ConfigParameters += @{
                    ProductNames = @("aad")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)

                { Invoke-ReportCreation @ReportParameters -Quiet} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-Item -Exactly -Times 0
            }
            It 'Show report' {
                $ConfigParameters += @{
                    ProductNames = @("aad")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)
                { Invoke-ReportCreation @ReportParameters} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-Item -Exactly -Times 1 -ParameterFilter {-Not [string]::IsNullOrEmpty($Path) }
            }
            It 'With -ProductNames "aad", should not throw' {
                $ConfigParameters += @{
                    ProductNames = @("aad")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)
                { Invoke-ReportCreation @ReportParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "defender", should not throw' {
                $ConfigParameters += @{
                    ProductNames = @("defender")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)
                { Invoke-ReportCreation @ReportParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "exo", should not throw' {
                $ConfigParameters += @{
                    ProductNames = @("exo")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)
                { Invoke-ReportCreation @ReportParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "powerplatform", should not throw' {
                $ConfigParameters += @{
                    ProductNames = @("powerplatform")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)
                { Invoke-ReportCreation @ReportParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "sharepoint", should not throw' {
                $ConfigParameters += @{
                    ProductNames = @("sharepoint")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)
                { Invoke-ReportCreation @ReportParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "teams", should not throw' {
                $ConfigParameters += @{
                    ProductNames = @("teams")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)
                { Invoke-ReportCreation @ReportParameters } | Should -Not -Throw
            }
            It 'With all products, should not throw' {
                $ConfigParameters += @{
                    ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)
                { Invoke-ReportCreation @ReportParameters } | Should -Not -Throw
            }
        }
        Context 'When creating the reports with -Quiet True' {
            BeforeAll {

                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ConfigPrams')]
                $ConfigParameters = @{
                    OutProviderFileName = "ProviderSettingsExport";
                    OutRegoFileName     = "TestResults";
                    OutReportName       = "BaselineReports";
                }
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ReportParameters')]
                $ReportParameters = @{
                    DarkMode            = $false;
                    TenantDetails       = '{"DisplayName": "displayName"}';
                    ModuleVersion       = '1.0';
                    OutFolderPath       = "./"
                    Quiet               = $true
                }
            }
            It 'With all products, should not throw' {
                $ConfigParameters += @{
                    ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                }
                $ReportParameters['ScubaConfig'] = (New-Object -Type PSObject -Property $ConfigParameters)
                { Invoke-ReportCreation @ReportParameters } | Should -Not -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}