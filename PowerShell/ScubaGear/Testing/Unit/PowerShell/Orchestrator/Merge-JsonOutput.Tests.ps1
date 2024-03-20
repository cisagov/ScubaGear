$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function Merge-JsonOutput -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Merge-JsonOutput' {
        BeforeAll {
            Mock -CommandName Join-Path { "." }
            Mock -CommandName Out-File {}
            Mock -CommandName Remove-Item {}
            Mock -CommandName Get-Content { "" }
            Mock -CommandName ConvertFrom-Json { @{
                "ReportSummary"=@{"Date"=""}
                "Results"=@();
                "timestamp_zulu"="";
            }
            }
            Mock -CommandName Add-Member {}
            Mock -CommandName ConvertTo-Json { "" }
        }
        Context 'When creating the json output' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'JsonParameters')]
                $JsonParameters = @{
                    TenantDetails       = @{"DisplayName" = "displayName"; "TenantId" = "tenantId"; "DomainName" = "domainName"};
                    ModuleVersion       = '1.0';
                    OutFolderPath       = "./"
                    OutProviderFileName = "ProviderSettingsExport"
                    OutJsonFileName       = "ScubaResults"
                }
            }
            It 'Merge single result' {
                $JsonParameters += @{
                    ProductNames = @("aad")
                }
                { Merge-JsonOutput @JsonParameters} | Should -Not -Throw
                Should -Invoke -CommandName ConvertFrom-Json -Exactly -Times 2
                $JsonParameters.ProductNames = @()
            }
            It 'Merge multiple results' {
                $JsonParameters += @{
                    ProductNames = @("aad", "teams")
                }
                { Merge-JsonOutput @JsonParameters} | Should -Not -Throw
                Should -Invoke -CommandName ConvertFrom-Json -Exactly -Times 3
                $JsonParameters.ProductNames = @()
            }
            It 'Delete redundant files' {
                $JsonParameters += @{
                    ProductNames = @("aad", "teams")
                }
                { Merge-JsonOutput @JsonParameters} | Should -Not -Throw
                Should -Invoke -CommandName Remove-Item -Exactly -Times 3
                $JsonParameters.ProductNames = @()
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}