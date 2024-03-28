Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Support')

InModuleScope Support {
    Describe -Tag Support -Name 'New-Config' {
        BeforeAll {

			[Flags()]
			enum SerializationOptions {
				None = 0
				Roundtrip = 1
				DisableAliases = 2
				EmitDefaults = 4
				JsonCompatible = 8
				DefaultToStaticType = 16
				WithIndentedSequences = 32
			}

            Mock -CommandName Write-Warning {}

            Mock -ModuleName Support -CommandName ConvertTo-Yaml { $args[0] }

            $TestPath = New-Item -Path (Join-Path -Path "TestDrive:" -ChildPath "SampleConfig") -Name "CreateSampleConfigFolder" -ItemType Directory

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'CMDArgs')]
            $CMDArgs = @{
                Description = "YAML configuration file with default description";
                ProductNames = @("aad", "defender", "exo", "sharepoint", "teams");
                M365Environment = "commercial";
                OPAPath = ".";
                LogIn = $true;
                DisconnectOnExit = $false;
                OutPath = '.';
                AppID = '0';
                CertificateThumbprint = '0';
                Organization = '0';
                OutFolderName = "M365BaselineConformance";
                OutProviderFileName = "ProviderSettingsExport";
                OutRegoFileName = "TestResults";
                OutReportName = "BaselineReports";
                ConfigLocation = $TestPath;
            }
        }
        It 'Creates a sample configuration' {

            { New-Config @CMDArgs } | Should -Not -Throw

            Test-Path -Path "$($TestPath)/SampleConfig.yaml" -PathType leaf | Should -Be $true
        }
    }

    AfterAll {
        Remove-Module Support -ErrorAction SilentlyContinue
    }
}
