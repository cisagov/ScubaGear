BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/CreateReport
    New-Item -Path "./CreateReportStubs" -Name "CreateReportUnitFolder" -ErrorAction SilentlyContinue -ItemType Directory | Out-Null
    New-Item -Path "./CreateReportStubs/CreateReportUnitFolder" -Name "IndividualReports" -ErrorAction SilentlyContinue -ItemType Directory | Out-Null
}

Describe 'New-Report' {
    It 'Given all of the ProductNames, creates an HTML report for each of them' {
        $ProductNames = @("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive")
        $ProdToFullName = @{
            Teams = "Microsoft Teams";
            EXO = "Exchange Online";
            Defender = "Microsoft 365 Defender";
            AAD = "Azure Active Directory";
            PowerPlatform = "Microsoft Power Platform";
            SharePoint = "SharePoint Online";
            OneDrive = "OneDrive for Business";
        }
        $ArgToProd = @{
            teams = "Teams";
            exo = "EXO";
            defender = "Defender";
            aad = "AAD";
            powerplatform = "PowerPlatform";
            sharepoint = "SharePoint";
            onedrive = "OneDrive";
        }
        $IndividualReportPath = "./CreateReportStubs/CreateReportUnitFolder/IndividualReports"
        foreach ($N in $ProductNames) {
            $CreateReportParams = @{
                'BaselineName'         = $ArgToProd[$N];
                'FullName'             = $ProdToFullName[$N];
                'IndividualReportPath' = $IndividualReportPath;
                'OutPath'              = "./CreateReportStubs";
                'OutProviderFileName'  = "ProviderSettingsExport";
                'OutRegoFileName'      = "TestResults";
            }
            New-Report @CreateReportParams
            Test-Path -Path "$($IndividualReportPath)/$($N)Report.html" -PathType leaf | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module CreateReport -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force -Path "./CreateReportStubs/CreateReportUnitFolder" -ErrorAction SilentlyContinue
}
