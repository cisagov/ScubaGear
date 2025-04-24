<#
 # Due to how the Error handling was implemented, mocked API calls have to be mocked inside a
 # mocked CommandTracker class
#>

$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function Export-AADProvider -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ProviderHelpers/CommandTracker.psm1") -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ProviderHelpers/AADConditionalAccessHelper.psm1") -Force

InModuleScope -ModuleName ExportAADProvider {
    Describe -Tag 'ExportAADProvider' -Name "Export-AADProvider" {
        BeforeAll {
            function Get-MgBetaUserCount { 10 }
            class MockCommandTracker {
                [hashtable]$MockCommands = @{}
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    try {
                        if ($this.MockCommands.ContainsKey($Command)) {
                            $this.SuccessfulCommands += $Command
                            $MockFunction = $this.MockCommands[$Command]
                            return & $MockFunction $CommandArgs
                        } 
                        else {
                            Write-Warning "A mock function does not exist for $($Command). $($_)"
                            throw $_
                        }
                    }
                    catch {
                        Write-Warning "Error occurred in mock TryCommand. $($_)"
                        $this.UnSuccessfulCommands += $Command
                        return @()
                    }
                }

                [System.Object[]] TryCommand([string]$Command) {
                    return $this.TryCommand($Command, @{})
                }

                [void] AddSuccessfulCommand([string]$Command) {
                    $this.SuccessfulCommands += $Command
                }

                [void] AddUnSuccessfulCommand([string]$Command) {
                    $this.UnSuccessfulCommands += $Command
                }

                [string[]] GetUnSuccessfulCommands() {
                    return $this.UnSuccessfulCommands
                }

                [string[]] GetSuccessfulCommands() {
                    return $this.SuccessfulCommands
                }

                [void] AddMockCommand([string]$CommandName, [scriptblock]$MockFunction) {
                    $this.MockCommands[$CommandName] = $MockFunction
                }
            }
            
            $MockCommandTracker = [MockCommandTracker]::New()
            function Get-CommandTracker {}
            Mock -ModuleName 'ExportAADProvider' Get-CommandTracker {
                return $MockCommandTracker
            }

            class MockCapTracker {
                [string] ExportCapPolicies([System.Object]$Caps) {
                    return "[]"
                }
            }
            function Get-CapTracker {}
            Mock -ModuleName 'ExportAADProvider' Get-CapTracker  {
                return [MockCapTracker]::New()
            }

            function Add-DefaultMockCommands {
                param (
                    [MockCommandTracker]$Tracker
                )

                $Tracker.AddMockCommand("Get-MgBetaIdentityConditionalAccessPolicy", {
                    param($CmdArgs)
                    return [pscustomobject]@{}
                })

                $Tracker.AddMockCommand("Get-MgBetaSubscribedSku", {
                    param($cmdArgs)
                    return [pscustomobject]@{
                        ServicePlans = @(
                            @{
                                ProvisioningStatus = 'Success'
                            }
                        )
                        ServicePlanName = 'AAD_PREMIUM_P2'
                        SkuPartNumber = 'AAD_Tester'
                        SkuId = '00000-00000-00000-00000'
                        ConsumedUnits = 5
                        PrepaidUnits = @{
                            Enabled = 10
                            Suspended = 0
                            Warning = 0
                        }
                    }
                })

                $Tracker.AddMockCommand("Get-MgBetaUserCount", {
                    param($cmdArgs)
                    return 10
                })
            
                $Tracker.AddMockCommand("Get-PrivilegedUser", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            
                $Tracker.AddMockCommand("Get-PrivilegedRole", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            
                $Tracker.AddMockCommand("Get-MgBetaPolicyAuthorizationPolicy", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            
                $Tracker.AddMockCommand("Get-MgBetaDirectorySetting", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            
                $Tracker.AddMockCommand("Get-MgBetaPolicyAuthenticationMethodPolicy", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            
                $Tracker.AddMockCommand("Get-MgBetaDomain", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            
                $Tracker.AddMockCommand("Get-ApplicationsWithRiskyPermissions", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            
                $Tracker.AddMockCommand("Get-ServicePrincipalsWithRiskyPermissions", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            
                $Tracker.AddMockCommand("Format-RiskyApplications", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            
                $Tracker.AddMockCommand("Format-RiskyThirdPartyServicePrincipals", {
                    param($cmdArgs)
                    return [pscustomobject]@{}
                })
            }
            
            Add-DefaultMockCommands -Tracker $MockCommandTracker

            function Test-SCuBAValidProviderJson {
                param (
                    [string]
                    $Json
                )
                $Json = $Json.TrimEnd(",")
                $Json = "{$($Json)}"
                $ValidJson = $true
                try {
                    ConvertFrom-Json $Json -ErrorAction Stop | Out-Null
                }
                catch {
                    $ValidJson = $false
                }
                $ValidJson
            }
        }
        
        It "With a AAD P2 license, returns valid JSON" {
            $Json = Export-AADProvider
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }

        It "returns valid JSON if Format-RiskyApplications and Format-ThirdPartyServicePrincipals return $null" {
            # Override defaults
            $MockCommandTracker.AddMockCommand("Format-RiskyApplications", {
                param($cmdArgs)
                return $null
            })

            $MockCommandTracker.AddMockCommand("Format-RiskyThirdPartyServicePrincipals", {
                param($cmdArgs)
                return $null
            })

            $Json = Export-AADProvider
            Write-Output $Json > testjsonoutput.json
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }

        It "returns valid JSON if Format-RiskyApplications and Format-ThirdPartyServicePrincipals both return @($null)" {
            # Override defaults
            $MockCommandTracker.AddMockCommand("Format-RiskyApplications", {
                param($cmdArgs)
                return @($null)
            })

            $MockCommandTracker.AddMockCommand("Format-RiskyThirdPartyServicePrincipals", {
                param($cmdArgs)
                return @($null)
            })

            $Json = Export-AADProvider
            Write-Output $Json > testjsonoutput.json
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}
AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction 'SilentlyContinue'
    Remove-Module CommandTracker -Force -ErrorAction 'SilentlyContinue'
    Remove-Module AADConditionalAccessHelper -Force -ErrorAction 'SilentlyContinue'
}
