using module '..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'
BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules'
    
    # Import the branch version of Orchestrator
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'Orchestrator.psm1') -Force
}

InModuleScope Orchestrator {
    BeforeAll {
        # Set up all mocks ONCE for all tests
        $script:TestSplat = @{}
        
        # Define stub functions that will be mocked
        function ConvertTo-ResultsCsv {throw 'this will be mocked'}
        function Disconnect-SCuBATenant {throw 'this will be mocked'}
        
        Mock -ModuleName Orchestrator Remove-Resources {}
        Mock -ModuleName Orchestrator Import-Resources {}
        Mock -ModuleName Orchestrator Invoke-Connection {
            if ($ScubaConfig) { $script:TestSplat['LogIn'] = $ScubaConfig.LogIn }
        }
        Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
        Mock -ModuleName Orchestrator Invoke-ProviderList {
            if ($ScubaConfig) {
                $script:TestSplat['AppID'] = $ScubaConfig.AppID
                $script:TestSplat['Organization'] = $ScubaConfig.Organization
                $script:TestSplat['CertificateThumbprint'] = $ScubaConfig.CertificateThumbprint
            }
        }
        Mock -ModuleName Orchestrator Invoke-RunRego {
            if ($ScubaConfig) {
                $script:TestSplat['OPAPath'] = $ScubaConfig.OPAPath
                $script:TestSplat['OutProviderFileName'] = $ScubaConfig.OutProviderFileName
                $script:TestSplat['OutRegoFileName'] = $ScubaConfig.OutRegoFileName
            }
        }
        Mock -ModuleName Orchestrator Invoke-ReportCreation {
            if ($ScubaConfig) {
                $script:TestSplat['ProductNames'] = $ScubaConfig.ProductNames
                $script:TestSplat['M365Environment'] = $ScubaConfig.M365Environment
                $script:TestSplat['OutPath'] = $ScubaConfig.OutPath
                $script:TestSplat['OutFolderName'] = $ScubaConfig.OutFolderName
                $script:TestSplat['OutReportName'] = $ScubaConfig.OutReportName
            }
        }
        Mock -ModuleName Orchestrator Merge-JsonOutput {
            if ($ScubaConfig) { $script:TestSplat['OutJsonFileName'] = $ScubaConfig.OutJsonFileName }
        }
        Mock -ModuleName Orchestrator ConvertTo-ResultsCsv {}
        Mock -ModuleName Orchestrator Disconnect-SCuBATenant {
            if ($ScubaConfig) { $script:TestSplat['DisconnectOnExit'] = $ScubaConfig.DisconnectOnExit }
        }
        Mock -CommandName New-Item {}
        Mock -CommandName Copy-Item {}
    }

    Context  "Parameter override test"{

        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba config with no command line override' {
            BeforeAll {
                # Reset TestSplat for this test
                $script:TestSplat = @{}
                
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@("teams")
                        M365Environment='commercial'
                        OPAPath=$PSScriptRoot
                        LogIn=$true
                        DisconnectOnExit=$false
                        OutPath=$PSScriptRoot
                        OutFolderName='ScubaReports'
                        OutProviderFileName='ProviderSettingsExport'
                        OutRegoFileName='TestResults'
                        OutReportName='BaselineReports'
                        OutJsonFileName='ScubaResults'
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
                @{ Parameter = "OutRegoFileName";       Value = "TestResults"          },
                @{ Parameter = "OutReportName";         Value = "BaselineReports"      },
                @{ Parameter = "OutJsonFileName";       Value = "ScubaResults"         },
                @{ Parameter = "Organization";          Value = "sub.domain.com"       },
                @{ Parameter = "AppID";                 Value = "12345678-1234-1234-1234-123456789012"  },
                @{ Parameter = "CertificateThumbprint"; Value = "1234567890ABCDEF1234567890ABCDEF12345678"  }
                ){
                    $script:TestSplat[$Parameter] | Should -BeExactly $Value -Because "got $($script:TestSplat[$Parameter])"
            }
        }
        
        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba with command line ProductNames wild card override' {
            BeforeAll {
                # Reset TestSplat for this test
                $script:TestSplat = @{}
                
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@("teams")
                        M365Environment='commercial'
                        OPAPath=$PSScriptRoot
                        LogIn=$true
                        DisconnectOnExit=$false
                        OutPath=$PSScriptRoot
                        OutFolderName='ScubaReports'
                        OutProviderFileName='ProviderSettingsExport'
                        OutRegoFileName='TestResults'
                        OutReportName='BaselineReports'
                        OutJsonFileName='ScubaResults'
                        Organization='sub.domain.com'
                        AppID='12345678-1234-1234-1234-123456789012'
                        CertificateThumbprint='1234567890ABCDEF1234567890ABCDEF12345678'
                    }
                }
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
                # Reset TestSplat for this test
                $script:TestSplat = @{}
                
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