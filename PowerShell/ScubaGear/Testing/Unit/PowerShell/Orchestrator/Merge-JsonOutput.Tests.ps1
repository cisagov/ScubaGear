$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function Merge-JsonOutput -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Merge-JsonOutput' {
        BeforeAll {
            Mock -CommandName Out-File {}
            Mock -CommandName Set-Content {}
            Mock -CommandName Remove-Item {}
            Mock -CommandName Get-Content { "" }
            Mock -CommandName ConvertFrom-Json { @{
                    "ReportSummary"  = @{"Date" = "" }
                    "Results"        = @();
                    "timestamp_zulu" = "";
                }
            }
            Mock -CommandName Add-Member {}
            Mock -CommandName ConvertTo-Json { "" }
        }
        Context 'When creating the json output' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'JsonParameters')]
                $JsonParameters = @{
                    TenantDetails       = @{"DisplayName" = "displayName"; "TenantId" = "tenantId"; "DomainName" = "domainName" };
                    ModuleVersion       = '1.0';
                    OutFolderPath       = "./"
                    OutProviderFileName = "ProviderSettingsExport"
                    OutJsonFileName     = "ScubaResults";
                }
            }
            It 'Merge single result' {
                Mock -CommandName Join-Path { "." }
                $JsonParameters += @{
                    ProductNames    = @("aad");
                }
                { Merge-JsonOutput @JsonParameters } | Should -Not -Throw
                Should -Invoke -CommandName ConvertFrom-Json -Exactly -Times 2
                $JsonParameters.ProductNames = @()
            }
            It 'Merge multiple results' {
                Mock -CommandName Join-Path { "." }
                $JsonParameters += @{
                    ProductNames    = @("aad", "teams");
                }
                { Merge-JsonOutput @JsonParameters } | Should -Not -Throw
                Should -Invoke -CommandName ConvertFrom-Json -Exactly -Times 3
                $JsonParameters.ProductNames = @()
            }
            It 'Delete redundant files' {
                Mock -CommandName Join-Path { "." }
                $JsonParameters += @{
                    ProductNames    = @("aad", "teams");
                }
                { Merge-JsonOutput @JsonParameters } | Should -Not -Throw
                Should -Invoke -CommandName Remove-Item -Exactly -Times 3
                $JsonParameters.ProductNames = @()
            }
            It 'Throws an error when the file Path is too long' {
                $LongText = "Lorem ipsum dolor sit amet, `
                consectetur adipiscing elit, sed do eiusmod tempor `
                incididunt ut labore et dolore magna aliqua. `
                Ut enim ad minim veniam, quis nostrud exercitation `
                ullamco laboris nisi ut aliquip ex ea commodo consequat. `
                Lorem ipsum dolor sit amet, consectetur adipiscing elit,
                `sed do eiusmod "
                $JsonParameters += @{
                    ProductNames    = @("aad", "teams");
                }
                Mock -CommandName Join-Path { "ScubaResults" + $LongText; }
                { Merge-JsonOutput @JsonParameters } | Should -Throw
                $JsonParameters.ProductNames = @()
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}