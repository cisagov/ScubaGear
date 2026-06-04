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
                    "report_uuid" = "00000000-0000-0000-0000-000000000000"
                    "scuba_config"   = @{
                        "OrgName"     = "Test Organization";
                        "OrgUnitName" = "Test Unit";
                    }
                }
            }
            Mock -CommandName Add-Member {}
            Mock -CommandName ConvertTo-Json { "" }
        }
        Context 'When creating the json output' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'JsonParameters')]
                $JsonParameters = @{
                    TenantDetails                    = @{"DisplayName" = "displayName"; "TenantId" = "tenantId"; "DomainName" = "domainName" };
                    ModuleVersion                    = '1.0';
                    OutFolderPath                    = "./";
                    OutProviderFileName              = "ProviderSettingsExport";
                    FullScubaResultsName             = "ScubaResults.json";
                    Guid                             = "00000000-0000-0000-0000-000000000000";
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
        }
        Context 'When OrgName and OrgUnitName are present in scuba_config' {
            BeforeAll {
                Mock -CommandName Join-Path { "." }
                Mock -CommandName ConvertFrom-Json { @{
                        "ReportSummary"  = @{"Date" = "" }
                        "Results"        = @();
                        "timestamp_zulu" = "";
                        "report_uuid"    = "00000000-0000-0000-0000-000000000000"
                        "scuba_config"   = @{
                            "OrgName"     = "My Agency";
                            "OrgUnitName" = "My Division";
                        }
                    }
                }
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MergeParams')]
                $MergeParams = @{
                    TenantDetails       = @{"DisplayName" = "displayName"; "TenantId" = "tenantId"; "DomainName" = "domainName" };
                    ModuleVersion       = '1.0';
                    OutFolderPath       = "./";
                    OutProviderFileName = "ProviderSettingsExport";
                    FullScubaResultsName = "ScubaResults.json";
                    Guid                = "00000000-0000-0000-0000-000000000000";
                    ProductNames        = @("aad");
                }
            }
            It 'Does not throw when OrgName and OrgUnitName are set' {
                { Merge-JsonOutput @MergeParams } | Should -Not -Throw
            }
        }
        Context 'When OrgName and OrgUnitName are absent from scuba_config' {
            BeforeAll {
                Mock -CommandName Join-Path { "." }
                Mock -CommandName ConvertFrom-Json { @{
                        "ReportSummary"  = @{"Date" = "" }
                        "Results"        = @();
                        "timestamp_zulu" = "";
                        "report_uuid"    = "00000000-0000-0000-0000-000000000000"
                        "scuba_config"   = @{}
                    }
                }
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MergeParams')]
                $MergeParams = @{
                    TenantDetails       = @{"DisplayName" = "displayName"; "TenantId" = "tenantId"; "DomainName" = "domainName" };
                    ModuleVersion       = '1.0';
                    OutFolderPath       = "./";
                    OutProviderFileName = "ProviderSettingsExport";
                    FullScubaResultsName = "ScubaResults.json";
                    Guid                = "00000000-0000-0000-0000-000000000000";
                    ProductNames        = @("aad");
                }
            }
            It 'Does not throw when OrgName and OrgUnitName are null' {
                { Merge-JsonOutput @MergeParams } | Should -Not -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
