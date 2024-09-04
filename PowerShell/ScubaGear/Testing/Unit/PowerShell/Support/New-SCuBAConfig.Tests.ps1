Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Support')

InModuleScope Support {
    Describe -Tag Support -Name 'New-SCuBAConfig' {
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

            function ConvertTo-Yaml {throw 'this will be mocked'}
            Mock -ModuleName Support -CommandName ConvertTo-Yaml { $args[0] }

            $TestPath = New-Item -Path (Join-Path -Path $TestDrive -ChildPath "SampleConfig") -Name "CreateSampleConfigFolder" -ItemType Directory

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

            { New-SCuBAConfig @CMDArgs } | Should -Not -Throw

            Test-Path -Path "$($TestPath)/SampleConfig.yaml" -PathType leaf | Should -Be $true
        }

        Context "When policy IDs are provided in the OmitPolicy parameter" {
            It 'It reminds users to manually add the rationales' {
                # Should warn once to for the reminder to manually add the rationales
                $OmitArgs = $CMDArgs
                $OmitArgs['OmitPolicy'] = @("MS.DEFENDER.1.1v1", "MS.DEFENDER.1.2v1")
                { New-SCuBAConfig @OmitArgs } | Should -Not -Throw
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
                Test-Path -Path "$($TestPath)/SampleConfig.yaml" -PathType leaf | Should -Be $true
            }

            It 'Warns for malformed policy IDs' {
                # The function should recognize that the policy ID does not match the expected
                # format and give an additional warning for this
                $OmitArgs = $CMDArgs
                $OmitArgs['OmitPolicy'] = @("MS.DEFENDER1.1v1")
                { New-SCuBAConfig @OmitArgs } | Should -Not -Throw
                Should -Invoke -CommandName Write-Warning -Exactly -Times 2
                Test-Path -Path "$($TestPath)/SampleConfig.yaml" -PathType leaf | Should -Be $true
            }

            It 'Warns for unexpected product in the policy ID' {
                # The function should recognize that EXAMPLE is not a valid product
                # and give an additional warning for this
                $OmitArgs = $CMDArgs
                $OmitArgs['OmitPolicy'] = @("MS.EXAMPLE.1.1v1", "MS.DEFENDER.1.2v1")
                { New-SCuBAConfig @OmitArgs } | Should -Not -Throw
                Should -Invoke -CommandName Write-Warning -Exactly -Times 2
                Test-Path -Path "$($TestPath)/SampleConfig.yaml" -PathType leaf | Should -Be $true
            }
        }
    }

    AfterAll {
        Remove-Module Support -ErrorAction SilentlyContinue
    }
}
