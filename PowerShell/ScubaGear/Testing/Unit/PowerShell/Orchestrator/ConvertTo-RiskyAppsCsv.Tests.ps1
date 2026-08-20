$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function ConvertTo-RiskyAppsCsv -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'ConvertTo-RiskyAppsCsv' {
        BeforeAll {
            Mock -CommandName Get-FileEncoding { 'utf8' }
            Mock -CommandName Write-Warning {}
            Mock -CommandName Write-ScubaLog {}
        }

        BeforeEach {
            $script:TempOutPath = Join-Path $TestDrive "RiskyAppsCsvTests_$(New-Guid)"
            New-Item -ItemType Directory -Path $script:TempOutPath | Out-Null
            $script:CsvPath = Join-Path $script:TempOutPath "RiskyApps.csv"
        }

        AfterEach {
            if (Test-Path -LiteralPath $script:TempOutPath) {
                Remove-Item -LiteralPath $script:TempOutPath -Recurse -Force
            }
        }

        It 'Skips CSV creation when AAD is not assessed' {
            $Params = @{
                ProductNames         = @("exo");
                OutFolderPath        = $script:TempOutPath;
                FullScubaResultsName = "ScubaResults.json";
                OutProviderFileName  = "ProviderSettingsExport";
            }
            { ConvertTo-RiskyAppsCsv @Params } | Should -Not -Throw
            Test-Path -LiteralPath $script:CsvPath | Should -Be $false
        }

        It 'Writes headers only when no risky apps are present' {
            $ScubaResults = @{
                Raw = @{
                    risky_applications = @()
                    risky_third_party_service_principals = @()
                }
            } | ConvertTo-Json -Depth 5
            Set-Content -LiteralPath (Join-Path $script:TempOutPath "ScubaResults.json") -Value $ScubaResults -Encoding utf8

            $Params = @{
                ProductNames         = @("aad");
                OutFolderPath        = $script:TempOutPath;
                FullScubaResultsName = "ScubaResults.json";
                OutProviderFileName  = "ProviderSettingsExport";
            }
            { ConvertTo-RiskyAppsCsv @Params } | Should -Not -Throw
            Test-Path -LiteralPath $script:CsvPath | Should -Be $true

            $CsvContent = @(Get-Content -LiteralPath $script:CsvPath)
            $CsvContent.Count | Should -Be 1
            $CsvContent[0] | Should -Match 'Display Name'
            $CsvContent[0] | Should -Match 'Severity Score'
            $CsvContent[0] | Should -Match 'Risky Permissions'
            $CsvContent[0] | Should -Match 'Active Password Credentials Exceeding 180 Days'
            $CsvContent[0] | Should -Match 'Active Key Credentials Exceeding 365 Days'
        }

        It 'Creates remediation rows from ScubaResults Raw data sorted by severity score' {
            $Now = Get-Date
            $ActiveLongPasswordStart = $Now.AddDays(-400)
            $ActiveLongPasswordEnd = $Now.AddDays(10)
            $ExpiredPasswordStart = $Now.AddDays(-400)
            $ExpiredPasswordEnd = $Now.AddDays(-10)
            $ActiveLongKeyStart = $Now.AddDays(-800)
            $ActiveLongKeyEnd = $Now.AddDays(10)

            $ScubaResults = [PSCustomObject]@{
                Raw = [PSCustomObject]@{
                    risky_applications = @(
                        [PSCustomObject]@{
                            DisplayName = "Lower Risk App"
                            IsMultiTenantEnabled = $false
                            SeverityScore = 10
                            ScoreBreakdown = [PSCustomObject]@{ HighestRiskLevel = "Low" }
                            PrivilegedRoles = @()
                            PasswordCredentials = @()
                            KeyCredentials = @()
                            Permissions = @(
                                [PSCustomObject]@{
                                    RoleDisplayName = "User.Read"
                                    RoleType = "Delegated"
                                    RiskLevel = "Low"
                                    IsRisky = $true
                                }
                            )
                        },
                        [PSCustomObject]@{
                            DisplayName = "Higher Risk App"
                            IsMultiTenantEnabled = $true
                            SeverityScore = 80
                            ScoreBreakdown = [PSCustomObject]@{ HighestRiskLevel = "High" }
                            PrivilegedRoles = @()
                            PasswordCredentials = @(
                                [PSCustomObject]@{
                                    StartDateTime = $ActiveLongPasswordStart
                                    EndDateTime = $ActiveLongPasswordEnd
                                },
                                [PSCustomObject]@{
                                    StartDateTime = $ExpiredPasswordStart
                                    EndDateTime = $ExpiredPasswordEnd
                                }
                            )
                            KeyCredentials = @(
                                [PSCustomObject]@{
                                    StartDateTime = $ActiveLongKeyStart
                                    EndDateTime = $ActiveLongKeyEnd
                                }
                            )
                            Permissions = @(
                                [PSCustomObject]@{
                                    RoleDisplayName = "User.Read.All"
                                    RoleType = "Application"
                                    RiskLevel = "High"
                                    IsRisky = $true
                                },
                                [PSCustomObject]@{
                                    RoleDisplayName = "Application.ReadWrite.All"
                                    RoleType = "Application"
                                    RiskLevel = "Critical"
                                    IsRisky = $true
                                },
                                [PSCustomObject]@{
                                    RoleDisplayName = "Files.Read.All"
                                    RoleType = "Delegated"
                                    RiskLevel = "Medium"
                                    IsRisky = $true
                                },
                                [PSCustomObject]@{
                                    RoleDisplayName = "User.Read"
                                    RoleType = "Delegated"
                                    RiskLevel = "Low"
                                    IsRisky = $false
                                }
                            )
                        }
                    )
                    risky_third_party_service_principals = @(
                        [PSCustomObject]@{
                            DisplayName = "Third Party SP"
                            SignInAudience = "AzureADMultipleOrgs"
                            SeverityScore = 50
                            ScoreBreakdown = [PSCustomObject]@{ HighestRiskLevel = "Medium" }
                            PrivilegedRoles = @("Global Administrator", "Application Administrator")
                            PasswordCredentials = $null
                            KeyCredentials = $null
                            Permissions = @(
                                [PSCustomObject]@{
                                    RoleDisplayName = "Mail.ReadWrite"
                                    RoleType = "Delegated"
                                    RiskLevel = "Medium"
                                    IsRisky = $true
                                },
                                [PSCustomObject]@{
                                    RoleDisplayName = "Directory.Read.All"
                                    RoleType = "Application"
                                    RiskLevel = "High"
                                    IsRisky = $true
                                }
                            )
                        }
                    )
                }
            } | ConvertTo-Json -Depth 8
            Set-Content -LiteralPath (Join-Path $script:TempOutPath "ScubaResults.json") -Value $ScubaResults -Encoding utf8

            $Params = @{
                ProductNames         = @("aad");
                OutFolderPath        = $script:TempOutPath;
                FullScubaResultsName = "ScubaResults.json";
                OutProviderFileName  = "ProviderSettingsExport";
            }
            { ConvertTo-RiskyAppsCsv @Params } | Should -Not -Throw

            $Rows = @(Import-Csv -LiteralPath $script:CsvPath)
            $Rows.Count | Should -Be 3
            $Rows[0].'Display Name' | Should -Be "Higher Risk App"
            $Rows[0].'Severity Score' | Should -Be "80"
            $Rows[0].'Risk Level' | Should -Be "High"
            $Rows[0].'Risky Permissions' | Should -Be "Application.ReadWrite.All (Critical, Application); User.Read.All (High, Application); Files.Read.All (Medium, Delegated)"
            $Rows[0].'Multi-Tenant' | Should -Be "True"
            $Rows[0].'Third-Party Service Principal' | Should -Be "False"
            $Rows[0].'Active Password Credentials' | Should -Be "1"
            $Rows[0].'Expired Password Credentials' | Should -Be "1"
            $Rows[0].'Active Password Credentials Exceeding 180 Days' | Should -Be "1"
            $Rows[0].'Active Key Credentials' | Should -Be "1"
            $Rows[0].'Active Key Credentials Exceeding 365 Days' | Should -Be "1"

            $Rows[1].'Display Name' | Should -Be "Third Party SP"
            $Rows[1].'Third-Party Service Principal' | Should -Be "True"
            $Rows[1].'Multi-Tenant' | Should -Be "True"
            $Rows[1].'Assigned Privileged Roles' | Should -Be "Global Administrator; Application Administrator"
            $Rows[1].'Risky Permissions' | Should -Be "Directory.Read.All (High, Application); Mail.ReadWrite (Medium, Delegated)"

            $Rows[2].'Display Name' | Should -Be "Lower Risk App"
            $Rows[2].'Severity Score' | Should -Be "10"
            $Rows[2].'Risky Permissions' | Should -Be "User.Read (Low, Delegated)"
        }

        It 'Falls back to ProviderSettingsExport when ScubaResults is missing' {
            $ProviderSettings = [PSCustomObject]@{
                risky_applications = @(
                    [PSCustomObject]@{
                        DisplayName = "Provider App"
                        IsMultiTenantEnabled = $false
                        SeverityScore = 25
                        ScoreBreakdown = [PSCustomObject]@{ HighestRiskLevel = "Medium" }
                        PrivilegedRoles = @()
                        PasswordCredentials = @()
                        KeyCredentials = @()
                        Permissions = @()
                    }
                )
                risky_third_party_service_principals = @()
            } | ConvertTo-Json -Depth 6
            Set-Content -LiteralPath (Join-Path $script:TempOutPath "ProviderSettingsExport.json") -Value $ProviderSettings -Encoding utf8

            $Params = @{
                ProductNames         = @("aad");
                OutFolderPath        = $script:TempOutPath;
                FullScubaResultsName = "ScubaResults.json";
                OutProviderFileName  = "ProviderSettingsExport";
            }
            { ConvertTo-RiskyAppsCsv @Params } | Should -Not -Throw

            $Rows = @(Import-Csv -LiteralPath $script:CsvPath)
            $Rows.Count | Should -Be 1
            $Rows[0].'Display Name' | Should -Be "Provider App"
            $Rows[0].'Risk Level' | Should -Be "Medium"
        }

        It 'Warns without throwing when output creation fails' {
            Mock -CommandName Get-Content { throw "File not found" }
            $Params = @{
                ProductNames         = @("aad");
                OutFolderPath        = $script:TempOutPath;
                FullScubaResultsName = "ScubaResults.json";
                OutProviderFileName  = "ProviderSettingsExport";
            }
            # Create a ScubaResults path so Get-Content is attempted
            Set-Content -LiteralPath (Join-Path $script:TempOutPath "ScubaResults.json") -Value "{}" -Encoding utf8
            { ConvertTo-RiskyAppsCsv @Params } | Should -Not -Throw
            Should -Invoke -CommandName Write-Warning -Exactly -Times 1
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
