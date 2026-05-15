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
            function Get-Utf8NoBom {throw 'this will be mocked'}
            Mock -CommandName Get-Utf8NoBom {}
            Mock -CommandName ConvertFrom-Json { @{ "report_uuid"="" } }
        }
        Context 'When creating the reports from Provider and OPA results JSON' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ScubaConfig')]
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    OutProviderFileName = "ProviderSettingsExport"
                    OutRegoFileName = "TestResults"
                    OutReportName = "BaselineReports"
                    OPAPath = "."
                    LogIn = $false
                }
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'TenantDetails')]
                $TenantDetails = '{"DisplayName": "displayName"}'
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'DarkMode')]
                $DarkMode = $false
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleVersion')]
                $ModuleVersion = '1.0'
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'OutFolderPath')]
                $OutFolderPath = "./"
            }
            It 'Do it quietly (Do not automatically show report)' {
                $ScubaConfig.ProductNames = @("aad")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode -Quiet } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-Item -Exactly -Times 0
                $ScubaConfig.ProductNames = @()
            }
            It 'Show report' {
                $ScubaConfig.ProductNames = @("aad")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-Item -Exactly -Times 1 -ParameterFilter {-Not [string]::IsNullOrEmpty($Path) }
                $ScubaConfig.ProductNames = @()
            }
            It 'With -ProductNames "aad", should not throw' {
                $ScubaConfig.ProductNames = @("aad")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode } | Should -Not -Throw
            }
            It 'With -ProductNames "defender", should not throw' {
                $ScubaConfig.ProductNames = @("defender")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode } | Should -Not -Throw
            }
            It 'With -ProductNames "exo", should not throw' {
                $ScubaConfig.ProductNames = @("exo")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode } | Should -Not -Throw
            }
            It 'With -ProductNames "powerplatform", should not throw' {
                $ScubaConfig.ProductNames = @("powerplatform")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode } | Should -Not -Throw
            }
            It 'With -ProductNames "sharepoint", should not throw' {
                $ScubaConfig.ProductNames = @("sharepoint")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode } | Should -Not -Throw
            }
            It 'With -ProductNames "teams", should not throw' {
                $ScubaConfig.ProductNames = @("teams")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode } | Should -Not -Throw
            }
            It 'With all products, should not throw' {
                $ScubaConfig.ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode } | Should -Not -Throw
            }
        }
        Context 'When creating the reports with -Quiet True' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ScubaConfig')]
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    OutProviderFileName = "ProviderSettingsExport"
                    OutRegoFileName = "TestResults"
                    OutReportName = "BaselineReports"
                    OPAPath = "."
                    LogIn = $false
                }
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'DarkMode')]
                $DarkMode = $false
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'TenantDetails')]
                $TenantDetails = '{"DisplayName": "displayName"}'
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleVersion')]
                $ModuleVersion = '1.0'
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'OutFolderPath')]
                $OutFolderPath = "./"
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Quiet')]
                $Quiet = $true
            }
            It 'With all products, should not throw' {
                $ScubaConfig.ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                { Invoke-ReportCreation -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -DarkMode:$DarkMode -Quiet:$Quiet } | Should -Not -Throw
            }
        }
    }
 }

AfterAll {
     Remove-Module Orchestrator -ErrorAction SilentlyContinue
 }
