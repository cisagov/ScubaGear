Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../PowerShell/ScubaGear/Modules/CreateReport')

InModuleScope CreateReport {
    Describe -Tag CreateReport -Name 'New-Report' {
        BeforeAll {
            Mock -CommandName Write-Warning {}

            New-Item -Path (Join-Path -Path "TestDrive:" -ChildPath "CreateReportStubs") -Name "CreateReportUnitFolder" -ItemType Directory
            New-Item -Path (Join-Path -Path "TestDrive:" -ChildPath "CreateReportStubs/CreateReportUnitFolder") -Name "IndividualReports" -ItemType Directory
            $TestOutPath = (Join-Path -Path "TestDrive:" -ChildPath "CreateReportStubs")
            Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "CreateReportStubs/*") -Destination $TestOutPath -Recurse

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ArgToProd')]
            $ArgToProd = @{
                teams         = "Teams";
                exo           = "EXO";
                defender      = "Defender";
                aad           = "AAD";
                powerplatform = "PowerPlatform";
                sharepoint    = "SharePoint";
            }
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ProdToFullName')]
            $ProdToFullName = @{
                Teams         = "Microsoft Teams";
                EXO           = "Exchange Online";
                Defender      = "Microsoft 365 Defender";
                AAD           = "Azure Active Directory";
                PowerPlatform = "Microsoft Power Platform";
                SharePoint    = "SharePoint Online";
            }
        }
        BeforeEach {
            $IndividualReportPath = (Join-Path -Path "TestDrive:" -ChildPath "CreateReportStubs/CreateReportUnitFolder/IndividualReports")
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'CreateReportParams')]
            $CreateReportParams = @{
                'IndividualReportPath' = $IndividualReportPath
                'OutPath'              = $TestOutPath
                'OutProviderFileName'  = "ProviderSettingsExport"
                'OutRegoFileName'      = "TestResults"
                'DarkMode'             = $false
            }
        }
        It 'Creates a report for <Product>' -ForEach @(
            @{Product = 'aad'; WarningCount = 0},
            @{Product = 'defender'; WarningCount = 9},
            @{Product = 'exo'; WarningCount = 0},
            @{Product = 'powerplatform'; WarningCount = 2},
            @{Product = 'sharepoint'; WarningCount = 0},
            @{Product = 'teams'; WarningCount = 11}
        ){
            $CreateReportParams += @{
                'BaselineName'    = $ArgToProd[$Product];
                'FullName'        = $ProdToFullName[$Product];
                'SecureBaselines' = Import-SecureBaseline -ProductNames $Product
            }

            { New-Report @CreateReportParams } | Should -Not -Throw
            Should -Invoke -CommandName Write-Warning -Exactly -Times $WarningCount

            Test-Path -Path "$($IndividualReportPath)/$($ArgToProd[$Product])Report.html" -PathType leaf | Should -Be $true
        }
    }

    AfterAll {
        Remove-Module CreateReport -ErrorAction SilentlyContinue
    }
}