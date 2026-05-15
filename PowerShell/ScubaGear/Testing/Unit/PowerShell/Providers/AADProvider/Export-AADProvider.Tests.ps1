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
                [hashtable]$MockCommands
                [string[]]$SuccessfulCommands
                [string[]]$UnSuccessfulCommands

                MockCommandTracker() {
                    $this.MockCommands = @{}
                    $this.SuccessfulCommands = @()
                    $this.UnSuccessfulCommands = @()

                    $this.AddDefaultMockCommands()
                }

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    try {
                        if ($this.MockCommands.ContainsKey($Command)) {
                            $this.SuccessfulCommands += $Command
                            $MockFunction = $this.MockCommands[$Command]
                            return & $MockFunction $CommandArgs
                        }
                        else {
                            throw "A mock function does not exist for $($Command). $($_)"
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

                [void] AddDefaultMockCommands() {
                    $this.AddMockCommand("Get-MgBetaIdentityConditionalAccessPolicy", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Get-MgBetaSubscribedSku", {
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

                    $this.AddMockCommand("Get-MgBetaUserCount", {
                        return 10
                    })

                    $this.AddMockCommand("Get-PrivilegedUser", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Get-PrivilegedRole", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Get-MgBetaPolicyAuthorizationPolicy", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Get-MgBetaDirectorySetting", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Get-MgBetaPolicyAuthenticationMethodPolicy", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Get-MgBetaDomain", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Get-ApplicationsWithRiskyPermissions", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Get-ServicePrincipalsWithRiskyPermissions", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Format-RiskyApplications", {
                        return [pscustomobject]@{}
                    })

                    $this.AddMockCommand("Format-RiskyThirdPartyServicePrincipals", {
                        return [pscustomobject]@{}
                    })
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
            $MockCommandTracker.AddMockCommand("Format-RiskyApplications", { return $null })
            $MockCommandTracker.AddMockCommand("Format-RiskyThirdPartyServicePrincipals", { return $null })

            $Json = Export-AADProvider
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }

        It "returns valid JSON if Format-RiskyApplications and Format-ThirdPartyServicePrincipals both return @($null)" {
            # Override defaults
            $MockCommandTracker.AddMockCommand("Format-RiskyApplications", { return @($null) })
            $MockCommandTracker.AddMockCommand("Format-RiskyThirdPartyServicePrincipals", { return @($null) })

            $Json = Export-AADProvider
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
