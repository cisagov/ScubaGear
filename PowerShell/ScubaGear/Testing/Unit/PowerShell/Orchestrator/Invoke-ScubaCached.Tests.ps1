$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-SCuBACached' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-SCuBACached' {
        BeforeAll {
            function Invoke-Connection {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($ScubaConfig, $AutoDetectEnvironment)
            }
            Mock -ModuleName Orchestrator Invoke-Connection { @() }
            function Get-TenantDetail {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($M365Environment)
            }
            Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
            function Invoke-ProviderList {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($ScubaConfig, $TenantDetails, $ModuleVersion, $OutFolderPath, $Guid, $ConnectionResult)
            }
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
            function ConvertTo-RiskyAppsCsv {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator ConvertTo-RiskyAppsCsv {}
            function Set-Utf8NoBom {}
            Mock -ModuleName Orchestrator Set-Utf8NoBom

            Mock -CommandName Write-Debug {}
            Mock -CommandName New-Item {}
            function Initialize-ScubaLogging {}
            Mock -ModuleName Orchestrator Initialize-ScubaLogging {}
            function Write-ScubaLog {}
            Mock -ModuleName Orchestrator Write-ScubaLog {}
            function Write-ScubaRunDetails {}
            Mock -ModuleName Orchestrator Write-ScubaRunDetails {}
            Mock -CommandName Get-Content { "" }
            Mock -CommandName Get-Member { $true }
            Mock -CommandName New-Guid { "00000000-0000-0000-0000-000000000000" }
            Mock -CommandName Get-ChildItem {
                [pscustomobject]@{"FullName"="ScubaResults.json"; "CreationTime"=[DateTime]"2024-01-01"}
            }
            Mock -CommandName Remove-Item {}
            Mock -CommandName ConvertFrom-Json {
                [PSCustomObject]@{"report_uuid"="00000000-0000-0000-0000-000000000000"}
            }
        }

        Context 'When checking module version' {
            It 'Given -Version should not throw' {
                {Invoke-SCuBACached -Version -SilenceBODWarnings} | Should -Not -Throw
            }
        }

        Context 'Interactive environment discovery' {
            BeforeEach {
                Mock Repair-ScubaGearJson {
                    @{
                        JsonObject = @{
                            report_uuid = '00000000-0000-0000-0000-000000000000'
                            Raw = @{ report_uuid = '00000000-0000-0000-0000-000000000000' }
                        }
                        RepairedJson = $false
                    }
                }
            }

            It 'propagates the detected cloud before exporting provider data' {
                Mock Invoke-Connection { @{ DetectedM365Environment = 'dod'; ProdAuthFailed = @() } }
                Invoke-SCuBACached -ProductNames aad -ExportProvider $true -Quiet -SilenceBODWarnings
                Should -Invoke Invoke-Connection -Times 1 -Exactly -ParameterFilter { $AutoDetectEnvironment }
                Should -Invoke Get-TenantDetail -Times 1 -Exactly -ParameterFilter { $M365Environment -eq 'dod' }
                Should -Invoke Invoke-ProviderList -Times 1 -Exactly -ParameterFilter { $ScubaConfig.M365Environment -eq 'dod' }
            }

            It 'bypasses discovery when an environment is explicitly provided' {
                Invoke-SCuBACached -ProductNames aad -ExportProvider $true -M365Environment gcc -Quiet -SilenceBODWarnings
                Should -Invoke Invoke-Connection -Times 1 -Exactly -ParameterFilter { -not $AutoDetectEnvironment }
            }
        }

        Context "When there are multiple ScubaResults*.json files" {
        # It's possible (but not expected) that there are multiple files matching
        # "ScubaResults*.json". In this case, ScubaGear should choose the file
        # created most recently.
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'SplatParams')]
                $SplatParams = @{
                    M365Environment    = 'commercial'
                    SilenceBODWarnings = $true
                }
            }
            It 'Should select the most recently created' {
                Mock -CommandName Get-ChildItem { @(
                    [pscustomobject]@{"FullName"="ScubaResultsOld.json"; "CreationTime"=[DateTime]"2023-01-01"},
                    [pscustomobject]@{"FullName"="ScubaResultsNew.json"; "CreationTime"=[DateTime]"2024-01-01"},
                    [pscustomobject]@{"FullName"="ScubaResultsOldest.json"; "CreationTime"=[DateTime]"2022-01-01"}
                ) }

                Mock -CommandName Get-Content {
                    if ($Path -ne "ScubaResultsNew.json") {
                        # Should be the new one, throw if not
                        throw
                    }
                }

                {Invoke-SCuBACached @SplatParams} | Should -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
