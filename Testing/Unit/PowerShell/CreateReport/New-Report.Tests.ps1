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
                onedrive      = "OneDrive";
            }
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ProdToFullName')]
            $ProdToFullName = @{
                Teams         = "Microsoft Teams";
                EXO           = "Exchange Online";
                Defender      = "Microsoft 365 Defender";
                AAD           = "Azure Active Directory";
                PowerPlatform = "Microsoft Power Platform";
                SharePoint    = "SharePoint Online";
                OneDrive      = "OneDrive for Business";
            }
            $IndividualReportPath = (Join-Path -Path "TestDrive:" -ChildPath "CreateReportStubs/CreateReportUnitFolder/IndividualReports")
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'CreateReportParams')]
            $CreateReportParams = @{
                'IndividualReportPath' = $IndividualReportPath
                'OutPath'              = $TestOutPath
                'OutProviderFileName'  = "ProviderSettingsExport"
                'OutRegoFileName'      = "TestResults"
                'DarkMode'             = $false
                'SecureBaselines'      = Import-SecureBaseline
            }
        }
        It 'Creates a report for <Product>' -ForEach @(
            @{Product = 'aad'; WarningCount = 1},
            @{Product = 'defender'; WarningCount = 3},
            @{Product = 'exo'; WarningCount = 2},
            @{Product = 'onedrive'; WarningCount = 8},
            @{Product = 'powerplatform'; WarningCount = 0},
            @{Product = 'sharepoint'; WarningCount = 3},
            @{Product = 'teams'; WarningCount = 5}
        ){
            $CreateReportParams += @{
                'BaselineName' = $ArgToProd[$Product];
                'FullName'     = $ProdToFullName[$Product];
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