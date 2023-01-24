BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/CreateReport
}

Describe 'New-Report' {
    It 'Given 4 parameters, creates an HTML report' {
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
        foreach ($N in $ProductNames){
            $CreateReportParams = @{
                'BaselineName' = $ArgToProd[$N];
                'FullName' = $ProdToFullName[$N];
                'IndividualReportPath' = "./";
                'OutPath' = $PSScriptRoot;
                'OutProviderFileName' = "ProviderSettingsExport";
                'OutRegoFileName' = "TestResults";
            }
            New-Report @CreateReportParams
            Test-Path -Path "./$($N)Report.html" -PathType leaf | Should -Be $true
        }
    }
}
