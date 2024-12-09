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
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    # This is where you decide where you mock functions called by CommandTracker :)
                    try {
                        switch ($Command) {
                            "Get-MgBetaIdentityConditionalAccessPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-MgBetaSubscribedSku" {
                                $this.SuccessfulCommands += $Command
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
                            }
                            "Get-MgBetaUserCount" {
                                $this.SuccessfulCommands += $Command
                                return 10
                            }
                            "Get-PrivilegedUser" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-PrivilegedRole" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-MgBetaPolicyAuthorizationPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-MgBetaDirectorySetting" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                             "Get-MgBetaPolicyAuthenticationMethodPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-MgBetaDomain" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-ApplicationsWithRiskyPermissions" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-ServicePrincipalsWithRiskyPermissions" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-FirstPartyRiskyApplications" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-ThirdPartyRiskyServicePrincipals" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            default {
                                throw "ERROR you forgot to create a mock method for this cmdlet: $($Command)"
                            }
                        }
                        $Result = @()
                        $this.SuccessfulCommands += $Command
                        return $Result
                    }
                    catch {
                        Write-Warning "Error running $($Command). $($_)"
                        $this.UnSuccessfulCommands += $Command
                        $Result = @()
                        return $Result
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
            }
            function Get-CommandTracker {}
            Mock -ModuleName 'ExportAADProvider' Get-CommandTracker {
                return [MockCommandTracker]::New()
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
                    $ValidJson = $false;
                }
                $ValidJson
            }
        }
        It "With a AAD P2 license, returns valid JSON" {
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
