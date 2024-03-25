Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Support')

InModuleScope CreateReport {
    Describe -Tag CreateReport -Name 'New-Config' {
        BeforeAll {
            Mock -CommandName Write-Warning {}

            $TestPath = New-Item -Path (Join-Path -Path "TestDrive:" -ChildPath "SampleConfig") -Name "CreateSampleConfigFolder" -ItemType Directory

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'CMDArgs')]
            CMDArgs = @{
                $Description = "YAML configuration file with default description";
                $ProductNames = @("aad", "defender", "exo", "sharepoint", "teams");
                $M365Environment = "commercial";
                $OPAPath = ".";
                $LogIn = $true;
                $DisconnectOnExit = $false;
                $OutPath = '.';
                $AppID = '';
                $CertificateThumbprint = '';
                $Organization = '';
                $OutFolderName = "M365BaselineConformance";
                $OutProviderFileName = "ProviderSettingsExport";
                $OutRegoFileName = "TestResults";
                $OutReportName = "BaselineReports";
                $ConfigLocation = $TestPath;
            }
        }
        It 'Creates a sample configuration' {

            New-Config @CMDArgs | Should -Not -Throw

            Test-Path -Path "$($TestPath)/SampleConfig.yaml" -PathType leaf | Should -Be $true
        }
    }

    AfterAll {
        Remove-Module Support -ErrorAction SilentlyContinue
    }
}
