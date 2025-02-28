Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/CreateReport')

InModuleScope CreateReport {
    Describe -Tag CreateReport -Name 'Get-TestResult' {
        Context "When the control is valid" {
            BeforeAll {
                # PS Script Analyzer doesn't play well with Pester scoping and can't tell that
                # these variables *are* used. Using the script scope is the suggested workaround.
                # See https://github.com/PowerShell/PSScriptAnalyzer/issues/946.
                $script:ExampleReportDetails = "Example details"
                $script:NormalControl = [PSCustomObject]@{
                    MalformedDescription=$false;
                    Deleted=$false;
                }
            }
            Context "When the control is implemented" {
                It 'Returns pass if the test passed for SHALLs' {
                    $Test = [PSCustomObject]@{
                        RequirementMet=$true;
                        Criticality="Shall";
                        ReportDetails=$ExampleReportDetails;
                    }
                    $MissingCommands = $null
                    $Control = $NormalControl
                    $Result = Get-TestResult $Test $MissingCommands $Control
                    $Result.DisplayString | Should -Be "Pass"
                    $Result.SummaryKey | Should -Be "Passes"
                    $Result.Details | Should -Be $ExampleReportDetails
                }
                It 'Returns pass if the test passed for SHOULDs' {
                    $Test = [PSCustomObject]@{
                        RequirementMet=$true;
                        Criticality="Should";
                        ReportDetails=$ExampleReportDetails;
                    }
                    $MissingCommands = $null
                    $Control = $NormalControl
                    $Result = Get-TestResult $Test $MissingCommands $Control
                    $Result.DisplayString | Should -Be "Pass"
                    $Result.SummaryKey | Should -Be "Passes"
                    $Result.Details | Should -Be $ExampleReportDetails
                }
                It 'Returns fail for failed SHALLs' {
                    $Test = [PSCustomObject]@{
                        RequirementMet=$false;
                        Criticality="Shall";
                        ReportDetails=$ExampleReportDetails;
                    }
                    $MissingCommands = $null
                    $Control = $NormalControl
                    $Result = Get-TestResult $Test $MissingCommands $Control
                    $Result.DisplayString | Should -Be "Fail"
                    $Result.SummaryKey | Should -Be "Failures"
                    $Result.Details | Should -Be $ExampleReportDetails
                }
                It 'Returns warning for failed SHOULDs' {
                    $Test = [PSCustomObject]@{
                        RequirementMet=$false;
                        Criticality="Should";
                        ReportDetails=$ExampleReportDetails;
                    }
                    $MissingCommands = $null
                    $Control = $NormalControl
                    $Result = Get-TestResult $Test $MissingCommands $Control
                    $Result.DisplayString | Should -Be "Warning"
                    $Result.SummaryKey | Should -Be "Warnings"
                    $Result.Details | Should -Be $ExampleReportDetails
                }
            }
            Context "When the control is not implemented" {
                It 'Returns N/A for not implemented SHALLs' {
                    $Test = [PSCustomObject]@{
                        RequirementMet=$false;
                        Criticality="Shall/Not-Implemented";
                        ReportDetails=$ExampleReportDetails;
                    }
                    $MissingCommands = $null
                    $Control = $NormalControl
                    $Result = Get-TestResult $Test $MissingCommands $Control
                    $Result.DisplayString | Should -Be "N/A"
                    $Result.SummaryKey | Should -Be "Manual"
                    $Result.Details | Should -Be $ExampleReportDetails
                }
                It 'Returns N/A for not implemented SHOULDs' {
                    $Test = [PSCustomObject]@{
                        RequirementMet=$false;
                        Criticality="Should/Not-Implemented";
                        ReportDetails=$ExampleReportDetails;
                    }
                    $MissingCommands = $null
                    $Control = $NormalControl
                    $Result = Get-TestResult $Test $MissingCommands $Control
                    $Result.DisplayString | Should -Be "N/A"
                    $Result.SummaryKey | Should -Be "Manual"
                    $Result.Details | Should -Be $ExampleReportDetails
                }
                It 'Returns N/A for third-party SHALLs' {
                    $Test = [PSCustomObject]@{
                        RequirementMet=$false;
                        Criticality="Shall/3rd Party";
                        ReportDetails=$ExampleReportDetails;
                    }
                    $MissingCommands = $null
                    $Control = $NormalControl
                    $Result = Get-TestResult $Test $MissingCommands $Control
                    $Result.DisplayString | Should -Be "N/A"
                    $Result.SummaryKey | Should -Be "Manual"
                    $Result.Details | Should -Be $ExampleReportDetails
                }
                It 'Returns N/A for third-party SHOULDs' {
                    $Test = [PSCustomObject]@{
                        RequirementMet=$false;
                        Criticality="Should/3rd Party";
                        ReportDetails=$ExampleReportDetails;
                    }
                    $MissingCommands = $null
                    $Control = $NormalControl
                    $Result = Get-TestResult $Test $MissingCommands $Control
                    $Result.DisplayString | Should -Be "N/A"
                    $Result.SummaryKey | Should -Be "Manual"
                    $Result.Details | Should -Be $ExampleReportDetails
                }
            }
        }

        Context "When the control/test has errors" {
            BeforeAll {
                $script:ScubaGitHubUrl = "https://github.com/cisagov/ScubaGear"
                $script:ExampleMissingCommand1 = "Get-Example1"
                $script:ExampleMissingCommand2 = "Get-Example2"
                $script:ExampleMissingDetails = @("This test depends on the following command(s) which did not execute ",
                    "successfully: Get-Example1, Get-Example2. See terminal output for more details.") -Join ""
            }
            It 'When the test has missing commands and passed' {
                $Test = [PSCustomObject]@{
                    RequirementMet=$true;
                    Criticality="Should";
                    ReportDetails=$ExampleReportDetails;
                }
                $MissingCommands = @($ExampleMissingCommand1, $ExampleMissingCommand2)
                $Control = [PSCustomObject]@{
                    MalformedDescription=$false;
                    Deleted=$false;
                }
                $Result = Get-TestResult $Test $MissingCommands $Control
                $Result.DisplayString | Should -Be "Error"
                $Result.SummaryKey | Should -Be "Errors"
                $Result.Details | Should -Be $ExampleMissingDetails
            }
            It 'When the test has missing commands and failed' {
                $Test = [PSCustomObject]@{
                    RequirementMet=$true;
                    Criticality="Should";
                    ReportDetails=$ExampleReportDetails;
                }
                $MissingCommands = @($ExampleMissingCommand1, $ExampleMissingCommand2)
                $Control = [PSCustomObject]@{
                    MalformedDescription=$false;
                    Deleted=$false;
                }
                $Result = Get-TestResult $Test $MissingCommands $Control
                $Result.DisplayString | Should -Be "Error"
                $Result.SummaryKey | Should -Be "Errors"
                $Result.Details | Should -Be $ExampleMissingDetails
            }
            It 'When the control has been deleted' {
                $Test = [PSCustomObject]@{
                    RequirementMet=$true;
                    Criticality="Should";
                    ReportDetails=$ExampleReportDetails;
                }
                $MissingCommands = @($ExampleMissingCommand1, $ExampleMissingCommand2)
                $Control = [PSCustomObject]@{
                    MalformedDescription=$false;
                    Deleted=$true;
                }
                $Result = Get-TestResult $Test $MissingCommands $Control
                $Result.DisplayString | Should -Be "-"
                $Result.SummaryKey | Should -Be "-"
                $Result.Details | Should -Be "-"
            }
            It 'When the control description is malformed' {
                $Test = [PSCustomObject]@{
                    RequirementMet=$true;
                    Criticality="Should";
                    ReportDetails=$ExampleReportDetails;
                }
                $MissingCommands = @($ExampleMissingCommand1, $ExampleMissingCommand2)
                $Control = [PSCustomObject]@{
                    MalformedDescription=$true;
                    Deleted=$true;
                }
                $Result = Get-TestResult $Test $MissingCommands $Control
                $Result.DisplayString | Should -Be "Error"
                $Result.SummaryKey | Should -Be "Errors"
                $Result.Details | Should -Be "Report issue on <a href=`"$ScubaGitHubUrl/issues`" target=`"_blank`">GitHub</a>"
            }
        }
    }

    AfterAll {
        Remove-Module CreateReport -ErrorAction SilentlyContinue
    }
}
