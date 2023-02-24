BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/CreateReport
    New-Item -Path "./CreateReportStubs" -Name "CreateReportUnitFolder" -ErrorAction SilentlyContinue -ItemType Directory | Out-Null
    New-Item -Path "./CreateReportStubs/CreateReportUnitFolder" -Name "IndividualReports" -ErrorAction SilentlyContinue -ItemType Directory | Out-Null
}

Describe -Tag CreateReport -Name 'New-Report' {
    Context "Light mode case" {
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
            $IndividualReportPath = "./CreateReportStubs/CreateReportUnitFolder/IndividualReports"
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'CreateReportParams')]
            $CreateReportParams = @{
                'IndividualReportPath' = $IndividualReportPath;
                'OutPath'              = "./CreateReportStubs";
                'OutProviderFileName'  = "ProviderSettingsExport";
                'OutRegoFileName'      = "TestResults";
            }
        }
        It 'Creates a report for Azure Active Directory' {
            $ProductName = 'aad'
            $CreateReportParams += @{
                'BaselineName' = $ArgToProd[$ProductName];
                'FullName'     = $ProdToFullName[$ProductName];
            }
            New-Report @CreateReportParams
            Test-Path -Path "$($IndividualReportPath)/$($ArgToProd[$ProductName])Report.html" -PathType leaf | Should -Be $true
        }
        It 'Creates a report for Microsoft Defender for Office 365' {
            $ProductName = 'defender'
            $CreateReportParams += @{
                'BaselineName' = $ArgToProd[$ProductName];
                'FullName'     = $ProdToFullName[$ProductName];
            }
            New-Report @CreateReportParams
            Test-Path -Path "$($IndividualReportPath)/$($ArgToProd[$ProductName])Report.html" -PathType leaf | Should -Be $true
        }
        It 'Creates a report for Exchange Online' {
            $ProductName = 'exo'
            $CreateReportParams += @{
                'BaselineName' = $ArgToProd[$ProductName];
                'FullName'     = $ProdToFullName[$ProductName];
            }
            New-Report @CreateReportParams
            Test-Path -Path "$($IndividualReportPath)/$($ArgToProd[$ProductName])Report.html" -PathType leaf | Should -Be $true
        }
        It 'Creates a report for One Drive for Business' {
            $ProductName = 'onedrive'
            $CreateReportParams += @{
                'BaselineName' = $ArgToProd[$ProductName];
                'FullName'     = $ProdToFullName[$ProductName];
            }
            New-Report @CreateReportParams
            Test-Path -Path "$($IndividualReportPath)/$($ArgToProd[$ProductName])Report.html" -PathType leaf | Should -Be $true
        }
        It 'Creates a report for Power Platform' {
            $ProductName = 'powerplatform'
            $CreateReportParams += @{
                'BaselineName' = $ArgToProd[$ProductName];
                'FullName'     = $ProdToFullName[$ProductName];
            }
            New-Report @CreateReportParams
            Test-Path -Path "$($IndividualReportPath)/$($ArgToProd[$ProductName])Report.html" -PathType leaf | Should -Be $true
        }
        It 'Creates a report for SharePoint Online' {
            $ProductName = 'sharepoint'
            $CreateReportParams += @{
                'BaselineName' = $ArgToProd[$ProductName];
                'FullName'     = $ProdToFullName[$ProductName];
            }
            New-Report @CreateReportParams
            Test-Path -Path "$($IndividualReportPath)/$($ArgToProd[$ProductName])Report.html" -PathType leaf | Should -Be $true
        }
        It 'Creates a report for Microsoft Teams' {
            $ProductName = 'teams'
            $CreateReportParams += @{
                'BaselineName' = $ArgToProd[$ProductName];
                'FullName'     = $ProdToFullName[$ProductName];
            }
            New-Report @CreateReportParams
            Test-Path -Path "$($IndividualReportPath)/$($ArgToProd[$ProductName])Report.html" -PathType leaf | Should -Be $true
        }
    }
}

AfterAll {
    Remove-Module CreateReport -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force -Path "./CreateReportStubs/CreateReportUnitFolder" -ErrorAction SilentlyContinue
}
