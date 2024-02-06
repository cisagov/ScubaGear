$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Force

InModuleScope Orchestrator {
    Context  "Parameter override test"{
        BeforeAll{
            $ConnectionPath = '../../../../Modules/Connection/Connection.psm1'
            Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ConnectionPath) -Function Disconnect-SCuBATenant -Force

            function SetupMocks{
                $script:TestSplat = @{}
                Mock -ModuleName Orchestrator Remove-Resources {}
                Mock -ModuleName Orchestrator Import-Resources {}
                Mock -ModuleName Orchestrator Invoke-Connection {
                    $script:TestSplat.Add('LogIn', $LogIn)
                }
                Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
                Mock -ModuleName Orchestrator Invoke-ProviderList {
                    $script:TestSplat.Add('AppID', $BoundParameters.AppID)
                    $script:TestSplat.Add('Organization', $BoundParameters.Organization)
                    $script:TestSplat.Add('CertificateThumbprint', $BoundParameters.CertificateThumbprint)
                }
                Mock -ModuleName Orchestrator Invoke-RunRego {
                    $script:TestSplat.Add('OPAPath', $OPAPath)
                    $script:TestSplat.Add('OutProviderFileName', $OutProviderFileName)
                    $script:TestSplat.Add('OutRegoFileName', $OutRegoFileName)
                }
                Mock -ModuleName Orchestrator Invoke-ReportCreation {
                    $script:TestSplat.Add('ProductNames', $ProductNames)
                    $script:TestSplat.Add('M365Environment', $M365Environment)
                    $script:TestSplat.Add('OutPath', $ScubaConfig.OutPath)
                    $script:TestSplat.Add('OutFolderName', $ScubaConfig.OutFolderName)
                    $script:TestSplat.Add('OutReportName', $ScubaConfig.OutReportName)
                }
                Mock -ModuleName Orchestrator Disconnect-SCuBATenant {
                    $script:TestSplat.Add('DisconnectOnExit', $DisconnectOnExit)
                }
                function Get-ScubaDefault {throw 'this will be mocked'}
                Mock -ModuleName Orchestrator Get-ScubaDefault {"."}
                Mock -CommandName New-Item {}
                Mock -CommandName Copy-Item {}
            }
        }

        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba config with no command line override' {
            BeforeAll {
                SetupMocks
                Invoke-SCuBA -ConfigFilePath (Join-Path -Path $PSScriptRoot -ChildPath "orchestrator_config_test.yaml")
            }

            It "Verify parameter ""<parameter>"" with value ""<value>""" -ForEach @(
                @{ Parameter = "M365Environment";       Value = "commercial"           },
                @{ Parameter = "ProductNames";          Value = @("teams")             },
                @{ Parameter = "OPAPath";               Value = "."                    },
                @{ Parameter = "LogIn";                 Value = $true                  },
                @{ Parameter = "OutPath";               Value = ".."                   },
                @{ Parameter = "OutFolderName";         Value = "ScubaReports"         },
                @{ Parameter = "OutProviderFileName";   Value = "TenantSettingsExport" },
                @{ Parameter = "OutRegoFileName";       Value = "ScubaTestResults"     },
                @{ Parameter = "OutReportName";         Value = "ScubaReports"         },
                @{ Parameter = "Organization";          Value = "sub.domain.com"       },
                @{ Parameter = "AppID";                 Value = "7892dfe467aef9023be"  },
                @{ Parameter = "CertificateThumbprint"; Value = "8A673F1087453ABC894"  }
                ){
                    $script:TestSplat[$Parameter] | Should -BeExactly $Value -Because "got $($script:TestSplat[$Parameter])"
            }
        }
        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba config with command line override' {
            BeforeAll {
                SetupMocks
                Invoke-SCuBA `
                  -M365Environment "gcc" `
                  -ProductNames "aad" `
                  -OPAPath $env:TEMP `
                  -LogIn:$false `
                  -OutPath $env:TEMP `
                  -OutFolderName "MyReports" `
                  -OutProviderFileName "MySettingsExport" `
                  -OutRegoFileName "RegoResults" `
                  -OutReportName "MyReport" `
                  -Organization "good.four.us" `
                  -AppID "1212121212121212121" `
                  -CertificateThumbprint "AB123456789ABCDEF01" `
                  -ConfigFilePath (Join-Path -Path $PSScriptRoot -ChildPath "orchestrator_config_test.yaml")
            }

            It "Verify parameter ""<parameter>"" with value ""<value>""" -ForEach @(
                @{ Parameter = "M365Environment";       Value = "gcc"                  },
                @{ Parameter = "ProductNames";          Value = @("aad")               },
                @{ Parameter = "OPAPath";               Value = $env:TEMP              },
                @{ Parameter = "LogIn";                 Value = $false                 },
                @{ Parameter = "OutPath";               Value = $env:TEMP              },
                @{ Parameter = "OutFolderName";         Value = "MyReports"            },
                @{ Parameter = "OutProviderFileName";   Value = "MySettingsExport"     },
                @{ Parameter = "OutRegoFileName";       Value = "RegoResults"          },
                @{ Parameter = "OutReportName";         Value = "MyReport"             },
                @{ Parameter = "Organization";          Value = "good.four.us"         },
                @{ Parameter = "AppID";                 Value = "1212121212121212121"  },
                @{ Parameter = "CertificateThumbprint"; Value = "AB123456789ABCDEF01"  }
                ){
                    $script:TestSplat[$Parameter] | Should -BeExactly $Value -Because "got $($script:TestSplat[$Parameter])"
            }
        }

        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba with command line ProductNames wild card override' {
            BeforeAll {
                SetupMocks
                Invoke-SCuBA `
                  -ProductNames "*" `
                  -ConfigFilePath (Join-Path -Path $PSScriptRoot -ChildPath "orchestrator_config_test.yaml")
            }

            It "Verify parameter, ProductNames, with wildcard CLI override"{
                $script:TestSplat['ProductNames'] | Should -BeExactly @('aad', 'defender', 'exo', 'powerplatform', 'sharepoint', 'teams') -Because "got $($script:TestSplat['ProductNames'])"
            }
        }

        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba with config file ProductNames wild card' {
            BeforeAll {
                SetupMocks
                Invoke-SCuBA `
                  -ConfigFilePath (Join-Path -Path $PSScriptRoot -ChildPath "product_wildcard_config_test.yaml")
            }

            It "Verify parameter, ProductNames, reflects all products"{
                $script:TestSplat['ProductNames'] | Should -BeExactly @('aad', 'defender', 'exo', 'powerplatform', 'sharepoint', 'teams') -Because "got $($script:TestSplat['ProductNames'])"
            }
        }
    }
}
AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
    Remove-Module Connection -ErrorAction SilentlyContinue
}
