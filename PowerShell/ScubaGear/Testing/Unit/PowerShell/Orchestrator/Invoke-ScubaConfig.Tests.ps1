$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
$ScubaConfigPath = '../../../../PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1'
$ConnectionPath = '../../../../PowerShell/ScubaGear/Modules/Connection/Connection.psm1'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-SCuBA' -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ScubaConfigPath)
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ConnectionPath) -Function Disconnect-SCuBATenant

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba with Config' {
        BeforeAll {
            function Remove-Resources {}
            Mock -ModuleName Orchestrator Remove-Resources {}
            function Import-Resources {}
            Mock -ModuleName Orchestrator Import-Resources {}
            function Invoke-Connection {}
            Mock -ModuleName Orchestrator Invoke-Connection { @() }
            function Get-TenantDetail {}
            Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
            function Invoke-ProviderList {}
            Mock -ModuleName Orchestrator Invoke-ProviderList {}
            function Invoke-RunRego {}
            Mock -ModuleName Orchestrator Invoke-RunRego {}

            Mock -ModuleName Orchestrator Invoke-ReportCreation {}
            function Disconnect-SCuBATenant {}
            Mock -ModuleName Orchestrator Disconnect-SCuBATenant {}

            Mock -CommandName New-Item {}
            Mock -CommandName Copy-Item {}
        }
        Context 'Testing Invoke-Scuba with -ConfigFilePath arg and parameter override' {
            BeforeAll {
                $ConfigFile = ( Join-Path -Path $PSScriptRoot  -ChildPath "orchestrator_config_test.yaml" )
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'SplatParamsRef')]
                $SplatParamsRef = @{
                    ConfigFilePath = $ConfigFile
                }
                [ScubaConfig]::GetInstance().LoadConfig($ConfigFile)
                $ScubaConfRef= [ScubaConfig]::GetInstance().Configuration.Clone()

                function OverrideTest( $ModKey, $ModValue) {
                    $SplatParams = $SplatParamsRef.Clone()
                    $SplatParams[$ModKey] = $ModValue
                    Invoke-Scuba @SplatParams
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
            }
            It "Verify overide parameter ""<parameter>"" with value ""<value>""" -ForEach @(
                @{ Parameter = "M365Environment";       Value = "gcc"                           }
                @{ Parameter = "ProductNames";          Value = "teams"                         }
                @{ Parameter = "OPAPath";               Value = ".."                            }
                @{ Parameter = "Login";                 Value = $false                          }
                @{ Parameter = "DisconnectOnExit";      Value = $true                           }
                @{ Parameter = "OutPath";               Value = $true                           }
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

        }
    }
}
AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}