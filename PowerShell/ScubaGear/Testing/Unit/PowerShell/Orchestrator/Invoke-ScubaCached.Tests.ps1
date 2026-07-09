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
                {Invoke-SCuBACached -Version} | Should -Not -Throw
            }
        }

        Context "When there are multiple ScubaResults*.json files" {
        # It's possible (but not expected) that there are multiple files matching
        # "ScubaResults*.json". In this case, ScubaGear should choose the file
        # created most recently.
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
