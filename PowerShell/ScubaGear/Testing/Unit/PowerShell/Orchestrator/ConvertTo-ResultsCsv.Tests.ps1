$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function ConvertTo-ResultsCsv -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'ConvertTo-ResultsCsv' {
        BeforeAll {
            Mock -CommandName Join-Path { "." }
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Out-File {}
            Mock -CommandName Set-Content {}
            Mock -CommandName Remove-Item {}
            Mock -CommandName Get-Content { "" }
            Mock -CommandName Format-PlainText { "" }
            Mock -CommandName Add-Member {}
            Mock -CommandName Get-FileEncoding
            Mock -CommandName ConvertTo-Csv { "" }
            Mock -CommandName Write-Warning {}
            Mock -CommandName Get-ChildItem {
                [pscustomobject]@{"FullName"="ScubaResults_00000000-0000-0000-0000-000000000000.json"; "CreationTime"=[DateTime]"2024-01-01"}
            }
        }

        It 'Handles multiple products, control groups, and controls' {
            # Test to validate that the 3-way nested for loop properly finds all controls
            Mock -CommandName ConvertFrom-Json { @{
                "Results"=[PSCustomObject]@{
                    "EXO"=@(
                        @{
                            "Controls"=@(
                                @{
                                    "Requirement"="123";
                                    "Details"="123";
                                },
                                @{
                                    "Requirement"="123";
                                    "Details"="123";
                                }
                            )
                        },
                        @{
                            "Controls"=@(
                                @{
                                    "Requirement"="123";
                                    "Details"="123";
                                }
                            )
                        }
                    );
                    "AAD"=@(
                        @{
                            "Controls"=@(
                                @{
                                    "Requirement"="123";
                                    "Details"="123";
                                }
                            )
                        }
                    );
                }}
            }
            $CsvParameters = @{
                ProductNames          = @("exo", "aad");
                OutFolderPath         = ".";
                FullScubaResultsName  = "ScubaResults";
                OutCsvFileName        = "ScubaResults";
                OutActionPlanFileName = "ActionPlan";
                Guid                  = "00000000-0000-0000-0000-000000000000";
                NumberOfUUIDCharactersToTruncate = "18";
            }
            { ConvertTo-ResultsCsv @CsvParameters} | Should -Not -Throw
            Should -Invoke -CommandName ConvertFrom-Json -Exactly -Times 1
            Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            # Each control contributes two calls, EXO has 3 controls, AAD has 1 = 3*2 + 1*2 = 8
            Should -Invoke -CommandName Format-PlainText -Exactly -Times 8
        }

        It 'Handles file not found errors' {
            # Test to validate that a warning is printed if there is an error opening the ScubaResults file
            Mock -CommandName ConvertFrom-Json {}
            Mock -CommandName Get-Content { throw "File not found" }
            $CsvParameters = @{
                ProductNames          = @("exo", "aad");
                OutFolderPath         = ".";
                FullScubaResultsName  = "ScubaResults";
                OutCsvFileName        = "ScubaResults";
                OutActionPlanFileName = "ActionPlan";
                NumberOfUUIDCharactersToTruncate = "18";
            }
            { ConvertTo-ResultsCsv @CsvParameters} | Should -Not -Throw
            Should -Invoke -CommandName Format-PlainText -Exactly -Times 0
            Should -Invoke -CommandName Write-Warning -Exactly -Times 1
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}