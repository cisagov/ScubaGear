$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
$ScubaConfigPath = '../../../../Modules/ScubaConfig/ScubaConfig.psm1'
$ConnectionPath = '../../../../Modules/Connection/Connection.psm1'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ScubaConfigPath) -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ConnectionPath) -Function Disconnect-SCuBATenant

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba with Config' {
        BeforeAll {
            Mock -ModuleName Orchestrator Remove-Resources {}
            Mock -ModuleName Orchestrator Import-Resources {}
            Mock -ModuleName Orchestrator Invoke-Connection { @() }
            Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
            Mock -ModuleName Orchestrator Invoke-ProviderList {}
            Mock -ModuleName Orchestrator Invoke-RunRego {}
            Mock -ModuleName Orchestrator Invoke-ReportCreation {}
            Mock -ModuleName Orchestrator Disconnect-SCuBATenant {}
            Mock -CommandName New-Item {}
            Mock -CommandName Copy-Item {}
        }
        Context 'Testing Invoke-Scuba with -ConfigFilePath arg and parameter override' {
            BeforeAll {
            
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'SplatParamsRef')]

                # Set up the reference comparison withunmodified parameters by reading the hash from the config file
                $ConfigFile = ( Join-Path -Path $PSScriptRoot  -ChildPath "orchestrator_config_test.yaml" )
                $Content = Get-Content -Raw -Path $ConfigFile
                $ScubaConfRef = $Content | ConvertFrom-Yaml
                # Set up the splat params to point to this file ( this will be cloned and modified for overrides )
                $SplatParamsRef = @{
                    ConfigFilePath = $ConfigFile
                }

                # Set up the splat params to refernce a config file without authentication parameters
                # but supply then expicitly as arguments.  Use the authentication values from the refrence above

                $ConfigFileNoCreds = ( Join-Path -Path $PSScriptRoot  -ChildPath "orchestrator_config_test_no_creds.yaml" )
                $SplatParamsCreds = @{
                    ConfigFilePath = $ConfigFileNoCreds
                    Organization = $ScubaConfRef.Organization
                    AppID = $ScubaConfRef.AppID
                    CertificateThumbprint = $ScubaConfRef.CertificateThumbprint
                }

                # General function to to compare overrides
                function OverrideTest( $ModKey, $ModValue) {
                    # Add the modified parameter as passed in parameter
                    $SplatParams = $SplatParamsRef.Clone()
                    $SplatParams[$ModKey] = $ModValue
                    Invoke-Scuba @SplatParams
                    # The values setup by the override are propegated by the orchestrator
                    # into the Scuba config singleton
                    $ConfTest = [ScubaConfig]::GetInstance().Configuration
                    $pass = $true
                    if ( (Compare-Object @($ScubaConfRef.keys) @($ConfTest.keys)))
                    {
                        $pass = $false
                    }
                    else
                    {
                        # Test all values to be sure that the override parameter matches modified value
                        # The other values should be the same
                        foreach ($key in $ConfTest.keys )
                        {
                            if ( $key -eq $Modkey ) {
                                $isDifferentValue = (( Compare-Object  $ModValue $ConfTest.$key ) -ne $none )
                            }
                            else {
                                $isDifferentValue =  (( Compare-Object  $ScubaConfRef.$key $ConfTest.$key ) -ne $none )<# Action when all if and elseif conditions are false #>
                            }
                        }
                        if ( $IsDifferentValue )
                        {
                            $pass=$false
                        }
                        return $pass
                    }
                }
                
                # Credentiasl test:  pass the credetails as an argument combined with a
                # config file that does not have them
                function CredsTest() {
                    $pass = $true
                    Invoke-Scuba @SplatParamsCreds
                    $ConfTestCreds = [ScubaConfig]::GetInstance().Configuration

                    # Scuba config should now have the resultes with auth params
                    # Verify that all values are present and match
                    if ( (Compare-Object @($ScubaTestCreds.keys) @($ScubaConfRef.keys)))
                    {
                        $pass = $false
                    }
                    foreach ($key in $ConfTestCreds.keys )
                    {
                         if (( Compare-Object  $ConfTestCreds.$key  $ScubaConfRef.$key ) -ne $none )
                         {
                            $pass = $false
                         }
                    }
                    return $pass
                }
            }

            It "Verify overide parameter ""<parameter>"" with value ""<value>""" -ForEach @(
                @{ Parameter = "M365Environment";       Value = "gcc"                           }
                @{ Parameter = "M365Environment";       Value = "commercial"                    }
                @{ Parameter = "ProductNames";          Value = "teams"                         }
                @{ Parameter = "ProductNames";          Value = @("teams","aad")                }
                @{ Parameter = "OPAPath";               Value = ".."                            }
                @{ Parameter = "Login";                 Value = $false                          }
                @{ Parameter = "DisconnectOnExit";      Value = $true                           }
                @{ Parameter = "OutPath";               Value = ".."                           }
                @{ Parameter = "OutFolderName";         Value = "M365BaselineConformance_mod"   }
                @{ Parameter = "OutProviderFileName";   Value = "ProviderSettingsExport_mod"    }
                @{ Parameter = "OutRegoFileName";       Value = "TestResults_mod"               }
                @{ Parameter = "OutReportName";         Value = "BaselineReports_mod"           }
                @{ Parameter = "Organization";          Value = "mod.sub.domain.com"            }
                @{ Parameter = "AppID";                 Value = "0123456789badbad"              }
                @{ Parameter = "CertificateThumbprint"; Value = "BADBAD9786543210"              }
                ){
                    OverrideTest $Parameter $Value | Should -Be $true
            }

            It "Verify credentials passed in that are not in config file" {
                Invoke-Scuba @SplatParamsCreds
                $ConfTestCreds = [ScubaConfig]::GetInstance().Configuration
                if ( (Compare-Object @($ScubaConfRef.keys) @($ConfTestCreds.keys)))
                {
                    CredsTest | Shoud -Be $true
                }

            }

        }
    }
}
AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}