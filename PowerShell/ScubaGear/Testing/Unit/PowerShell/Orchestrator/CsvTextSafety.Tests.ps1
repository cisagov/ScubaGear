$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'CSV export text safety' {
        BeforeAll {
            Mock -CommandName Get-FileEncoding { 'utf8' }
            Mock -CommandName Write-ScubaLog {}
            Mock -CommandName Write-Warning { throw "Unexpected export warning: $Message" }
        }

        It 'Escapes <Value> in results and action-plan text after HTML removal' -ForEach @(
            @{ Value = '=1+1'; Expected = "'=1+1" },
            @{ Value = '+1+1'; Expected = "'+1+1" },
            @{ Value = '-1+1'; Expected = "'-1+1" },
            @{ Value = '@SUM(1,1)'; Expected = "'@SUM(1,1)" },
            @{ Value = 'Ordinary text'; Expected = 'Ordinary text' },
            @{ Value = 'Text with "quotes", commas'; Expected = 'Text with "quotes", commas' }
        ) {
            $Source = Join-Path $TestDrive 'ScubaResults.json'
            $Data = @{
                Results = @{
                    AAD = @(@{
                        Controls = @([ordered]@{
                            ID = 'MS.AAD.1.1v1'
                            Requirement = "<b>$Value</b>"
                            Result = 'Fail'
                            Details = $Value
                            Comment = $Value
                        })
                    })
                }
            } | ConvertTo-Json -Depth 10
            Set-Content -LiteralPath $Source -Value $Data -Encoding utf8
            $Params = @{
                ProductNames = @('aad')
                OutFolderPath = $TestDrive
                FullScubaResultsName = 'ScubaResults.json'
                OutCsvFileName = 'Results'
                OutActionPlanFileName = 'ActionPlan'
            }
            ConvertTo-ResultsCsv @Params
            foreach ($Name in @('Results', 'ActionPlan')) {
                $Rows = @(Import-Csv -LiteralPath (Join-Path $TestDrive "$Name.csv"))
                $Rows.Count | Should -Be 1
                $Rows[0].Requirement | Should -BeExactly $Expected
                $Rows[0].Details | Should -BeExactly $Expected
                $Rows[0].Comment | Should -BeExactly $Expected
                $Rows[0].ID | Should -BeExactly 'MS.AAD.1.1v1'
            }
            $Plan = Import-Csv -LiteralPath (Join-Path $TestDrive 'ActionPlan.csv')
            $Plan.'Non-Compliance Reason' | Should -BeExactly ' '
            (Get-Content -LiteralPath $Source -Raw).TrimEnd() | Should -BeExactly $Data
        }

        It 'Escapes <Value> in both risky-application record types' -ForEach @(
            @{ Value = '=1+1'; Expected = "'=1+1" },
            @{ Value = '+1+1'; Expected = "'+1+1" },
            @{ Value = '-1+1'; Expected = "'-1+1" },
            @{ Value = '@SUM(1,1)'; Expected = "'@SUM(1,1)" },
            @{ Value = 'Ordinary text'; Expected = 'Ordinary text' }
        ) {
            $App = @{
                DisplayName = $Value
                SeverityScore = 42
                ScoreBreakdown = @{ HighestRiskLevel = 'High' }
                IsMultiTenantEnabled = $true
                PrivilegedRoles = @($Value)
                PasswordCredentials = @()
                KeyCredentials = @()
                Permissions = @(@{
                    RoleDisplayName = $Value
                    RoleType = 'Application'
                    RiskLevel = 'High'
                    IsRisky = $true
                })
            }
            $Provider = @{
                Raw = @{
                    risky_applications = @($App)
                    risky_third_party_service_principals = @($App)
                }
            } | ConvertTo-Json -Depth 10
            Set-Content -LiteralPath (Join-Path $TestDrive 'ScubaResults.json') -Value $Provider -Encoding utf8
            $Params = @{
                ProductNames = @('aad')
                OutFolderPath = $TestDrive
                FullScubaResultsName = 'ScubaResults.json'
                OutProviderFileName = 'ProviderSettingsExport'
            }
            ConvertTo-RiskyAppsCsv @Params
            $Rows = @(Import-Csv -LiteralPath (Join-Path $TestDrive 'RiskyApps.csv'))
            $Rows.Count | Should -Be 2
            foreach ($Row in $Rows) {
                $Row.'Display Name' | Should -BeExactly $Expected
                $Row.'Assigned Privileged Roles' | Should -BeExactly $Expected
                $Row.'Risky Permissions' | Should -BeExactly "$Expected (High, Application)"
                $Row.'Severity Score' | Should -BeExactly '42'
                $Row.'Multi-Tenant' | Should -BeExactly 'True'
                $Row.'Active Password Credentials' | Should -BeExactly '0'
            }
            @($Rows.'Third-Party Service Principal' | Sort-Object) | Should -Be @('False', 'True')
        }

        It 'Copies rows without changing types, order, or the original text' {
            $Original = [pscustomobject][ordered]@{
                Comment = '=1+1'
                Count = -2
                Enabled = $true
                Missing = $null
                Empty = ''
            }
            $Safe = $Original | ConvertTo-CsvSafeObject
            $Safe.Comment | Should -BeExactly "'=1+1"
            $Original.Comment | Should -BeExactly '=1+1'
            $Safe.Count | Should -BeOfType ([int])
            $Safe.Count | Should -Be -2
            $Safe.Enabled | Should -BeOfType ([bool])
            $Safe.Missing | Should -BeNullOrEmpty
            $Safe.Empty | Should -BeExactly ''
            @($Safe.PSObject.Properties.Name) | Should -Be @($Original.PSObject.Properties.Name)
            ($Safe | ConvertTo-CsvSafeObject).Comment | Should -BeExactly "'=1+1"
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
