Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/CreateReport')

InModuleScope CreateReport {
    Describe -Tag CreateReport -Name 'New-Report' {
        BeforeAll {
            Mock -CommandName Write-Warning {}

            New-Item -Path (Join-Path -Path $TestDrive -ChildPath "CreateReportStubs") -Name "CreateReportUnitFolder" -ItemType Directory
            New-Item -Path (Join-Path -Path $TestDrive -ChildPath "CreateReportStubs/CreateReportUnitFolder") -Name "IndividualReports" -ItemType Directory
            $TestOutPath = (Join-Path -Path $TestDrive -ChildPath "CreateReportStubs")
            Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "CreateReportStubs/*") -Destination $TestOutPath -Recurse
            Copy-Item -Path (Join-Path -Path $TestOutPath -ChildPath "TestResults.json") -Destination (Join-Path -Path $TestOutPath -ChildPath "RegoOutput.json")

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ArgToProd')]
            $ArgToProd = @{
                teams         = "Teams";
                exo           = "EXO";
                securitysuite = "SecuritySuite";
                aad           = "AAD";
                powerplatform = "PowerPlatform";
                sharepoint    = "SharePoint";
            }
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ProdToFullName')]
            $ProdToFullName = @{
                Teams         = "Microsoft Teams";
                EXO           = "Exchange Online";
                SecuritySuite = "Security Suite";
                AAD           = "Azure Active Directory";
                PowerPlatform = "Microsoft Power Platform";
                SharePoint    = "SharePoint Online";
            }
        }
        BeforeEach {
            $IndividualReportPath = (Join-Path -Path $TestDrive -ChildPath "CreateReportStubs/CreateReportUnitFolder/IndividualReports")
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'CreateReportParams')]
            $CreateReportParams = @{
                'IndividualReportPath' = $IndividualReportPath
                'OutPath'              = $TestOutPath
                'OutProviderFileName'  = "ProviderSettingsExport"
                'OutRegoFileName'      = "RegoOutput"
                'DarkMode'             = $false
            }
        }
        It 'Creates a report for <Product>' -ForEach @(
            @{Product = 'aad'; WarningCount = 0},
            @{Product = 'securitysuite'; WarningCount = 0},
            @{Product = 'exo'; WarningCount = 0},
            @{Product = 'powerplatform'; WarningCount = 3},
            @{Product = 'sharepoint'; WarningCount = 0},
            @{Product = 'teams'; WarningCount = 12}
        ){
            $CreateReportParams += @{
                'BaselineName'    = $ArgToProd[$Product];
                'FullName'        = $ProdToFullName[$Product];
                'SecureBaselines' = Import-SecureBaseline -ProductNames $Product -BaselinePath (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\baselines" -Resolve)
            }

            { New-Report @CreateReportParams } | Should -Not -Throw
            Should -Invoke -CommandName Write-Warning -Exactly -Times $WarningCount

            $ReportPath = "$($IndividualReportPath)/$($ArgToProd[$Product])Report.html"
            Test-Path -Path $ReportPath -PathType leaf | Should -Be $true

            # The AAD report should render the "Users with Privileged Roles" table built
            # from the privileged_users data in the provider settings export.
            if ($Product -eq 'aad') {
                $ReportContent = Get-Content -Path $ReportPath -Raw
                $ReportContent | Should -Match '<h2>Users with Privileged Roles</h2>'
                $ReportContent | Should -Match 'id="privileged-users"'
                $ReportContent | Should -Match "href='#caps'"
                $ReportContent | Should -Match 'section\.id = tableType;'

                $PrivilegedUsersTable = [regex]::Match($ReportContent, 'id="privileged-users".*?</table>', 'Singleline').Value
                $DataRows = [regex]::Matches($PrivilegedUsersTable, '<tr>.*?</tr>', 'Singleline') | Select-Object -Skip 1
                $FoundNonGlobalAdmin = $false
                foreach ($Row in $DataRows) {
                    $HasGlobalAdmin = $Row.Value -match 'Global Administrator'
                    if (-not $HasGlobalAdmin) {
                        $FoundNonGlobalAdmin = $true
                    }
                    elseif ($FoundNonGlobalAdmin) {
                        throw "Global Administrator user found after non-Global Administrator user in privileged users table"
                    }
                }
            }
        }
    }

    AfterAll {
        Remove-Module CreateReport -ErrorAction SilentlyContinue
    }
}
