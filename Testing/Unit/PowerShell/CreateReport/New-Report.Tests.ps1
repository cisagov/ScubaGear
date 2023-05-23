BeforeAll {
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../PowerShell/ScubaGear/Modules/CreateReport')
    New-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "./CreateReportStubs") -Name "CreateReportUnitFolder" -ErrorAction SilentlyContinue -ItemType Directory | Out-Null
    New-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "./CreateReportStubs/CreateReportUnitFolder") -Name "IndividualReports" -ErrorAction SilentlyContinue -ItemType Directory | Out-Null
}

Describe -Tag CreateReport -Name 'New-Report' {
    BeforeAll {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ProductNames')]
        $ProductNames = @("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive")
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
        $IndividualReportPath = (Join-Path -Path $PSScriptRoot -ChildPath "./CreateReportStubs/CreateReportUnitFolder/IndividualReports")
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'CreateReportParams')]
        $CreateReportParams = @{
            'IndividualReportPath' = $IndividualReportPath;
            'OutPath'              = (Join-Path -Path $PSScriptRoot -ChildPath "./CreateReportStubs");
            'OutProviderFileName'  = "ProviderSettingsExport";
            'OutRegoFileName'      = "TestResults";
            'DarkMode'             = $false;
        }
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'SecureBaselines')]
        $SecureBaselines =  Import-SecureBaseline
    }
    It 'Creates a report for <Product>' -ForEach @(
        @{Product = 'aad'; ErrorCount = 33},
        @{Product = 'defender'; ErrorCount = 46},
        @{Product = 'exo'; ErrorCount = 39},
        @{Product = 'onedrive'; ErrorCount = 8},
        @{Product = 'powerplatform'; ErrorCount = 8},
        @{Product = 'sharepoint'; ErrorCount = 6},
        @{Product = 'teams'; ErrorCount = 28}
    ){
        $CreateReportParams += @{
            'BaselineName' = $ArgToProd[$Product];
            'FullName'     = $ProdToFullName[$Product];
            'SecureBaselines' = $SecureBaselines
        }
        New-Report @CreateReportParams -ErrorVariable Err 2>&1 > $null
        $error.Clear() # Clearing the Write-Error messages for excepting missing test results; Otherwise Pester registers as failure
        $Err.Count | Should -BeExactly $ErrorCount
        Test-Path -Path "$($IndividualReportPath)/$($ArgToProd[$Product])Report.html" -PathType leaf | Should -Be $true
    }
}

AfterAll {
    Remove-Module CreateReport -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force -Path (Join-Path -Path $PSScriptRoot -ChildPath "./CreateReportStubs/CreateReportUnitFolder") -ErrorAction SilentlyContinue
}
