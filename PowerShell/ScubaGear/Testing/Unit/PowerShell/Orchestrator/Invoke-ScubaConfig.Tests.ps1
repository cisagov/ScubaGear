using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'
BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules'
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'Orchestrator.psm1') -Force
}

InModuleScope Orchestrator {
    Context  "Parameter override test"{
        BeforeAll{
            function SetupMocks{
                $script:TestSplat = @{}
                Mock -ModuleName Orchestrator Remove-Resources {}
                Mock -ModuleName Orchestrator Import-Resources {}
                Mock -ModuleName Orchestrator Invoke-Connection {
                    $script:TestSplat.Add('LogIn', $LogIn)
                }
                Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
                Mock -ModuleName Orchestrator Invoke-ProviderList {
                    $script:TestSplat.Add('AppID', $ScubaConfig.AppID)
                    $script:TestSplat.Add('Organization', $ScubaConfig.Organization)
                    $script:TestSplat.Add('CertificateThumbprint', $ScubaConfig.CertificateThumbprint)
                }
                Mock -ModuleName Orchestrator Invoke-RunRego {
                    $script:TestSplat.Add('OPAPath', $OPAPath)
                    $script:TestSplat.Add('OutProviderFileName', $OutProviderFileName)
                    $script:TestSplat.Add('OutRegoFileName', $OutRegoFileName)
                }
                Mock -ModuleName Orchestrator Invoke-ReportCreation {
                    $script:TestSplat.Add('ProductNames', $ScubaConfig.ProductNames)
                    $script:TestSplat.Add('M365Environment', $ScubaConfig.M365Environment)
                    $script:TestSplat.Add('OutPath', $ScubaConfig.OutPath)
                    $script:TestSplat.Add('OutFolderName', $ScubaConfig.OutFolderName)
                    $script:TestSplat.Add('OutReportName', $ScubaConfig.OutReportName)
                }
                Mock -ModuleName Orchestrator Merge-JsonOutput {
                    $script:TestSplat.Add('OutJsonFileName', $ScubaConfig.OutJsonFileName)
                }
                function ConvertTo-ResultsCsv {throw 'this will be mocked'}
                Mock -ModuleName Orchestrator ConvertTo-ResultsCsv {}
                function Disconnect-SCuBATenant {
                    $script:TestSplat.Add('DisconnectOnExit', $DisconnectOnExit)
                }
                # Get-ScubaDefault function removed - now uses [ScubaConfig]::ScubaDefault() static method
                Mock -CommandName New-Item {}
                Mock -CommandName Copy-Item {}
            }
        }

        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba config with no command line override' {
            BeforeAll {
                SetupMocks
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@("teams")
                        M365Environment='commercial'
                        OPAPath=$PSScriptRoot
                        Login=$true
                        OutPath=$PSScriptRoot
                        OutFolderName='ScubaReports'
                        OutProviderFileName='TenantSettingsExport'
                        OutRegoFileName='ScubaTestResults'
                        OutReportName='ScubaReports'
                        Organization='sub.domain.com'
                        AppID='12345678-1234-1234-1234-123456789012'
                        CertificateThumbprint='1234567890ABCDEF1234567890ABCDEF12345678'
                    }
                }
                Invoke-SCuBA -ConfigFilePath (Join-Path -Path $PSScriptRoot -ChildPath "orchestrator_config_test.yaml")
            }

            It "Verify parameter ""<parameter>"" with value ""<value>""" -ForEach @(
                @{ Parameter = "M365Environment";       Value = "commercial"           },
                @{ Parameter = "ProductNames";          Value = @("teams")             },
                @{ Parameter = "LogIn";                 Value = $true                  },
                @{ Parameter = "OutFolderName";         Value = "ScubaReports"         },
                @{ Parameter = "OutProviderFileName";   Value = "ProviderSettingsExport" },
                @{ Parameter = "OutRegoFileName";       Value = "TestResults"     },
                @{ Parameter = "OutReportName";         Value = "ScubaReports"         },
                @{ Parameter = "OutJsonFileName";       Value = "ScubaResults"         },
                @{ Parameter = "Organization";          Value = "sub.domain.com"       },
                @{ Parameter = "AppID";                 Value = "12345678-1234-1234-1234-123456789012"  },
                @{ Parameter = "CertificateThumbprint"; Value = "1234567890ABCDEF1234567890ABCDEF12345678"  }
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
                  -OutJsonFileName "JsonResults" `
                  -Organization "good.four.us" `
                  -AppID "87654321-4321-4321-4321-210987654321" `
                  -CertificateThumbprint "ABCDEF1234567890ABCDEF1234567890ABCDEF12" `
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
                @{ Parameter = "OutJsonFileName";       Value = "JsonResults"          },
                @{ Parameter = "Organization";          Value = "good.four.us"         },
                @{ Parameter = "AppID";                 Value = "87654321-4321-4321-4321-210987654321"  },
                @{ Parameter = "CertificateThumbprint"; Value = "ABCDEF1234567890ABCDEF1234567890ABCDEF12"  }
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
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('aad', 'defender', 'exo', 'powerplatform', 'sharepoint', 'teams')
                        M365Environment='commercial'
                        OPAPath=$PSScriptRoot
                        Login=$true
                        OutPath=$PSScriptRoot
                        OutFolderName='ScubaReports'
                        OutProviderFileName='TenantSettingsExport'
                        OutRegoFileName='ScubaTestResults'
                        OutReportName='ScubaReports'
                        Organization='sub.domain.com'
                        AppID='12345678-1234-1234-1234-123456789012'
                        CertificateThumbprint='1234567890ABCDEF1234567890ABCDEF12345678'
                    }
                }
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
}