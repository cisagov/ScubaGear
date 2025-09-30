<#
 # Due to how the Error handling was implemented, mocked API calls have to be mocked inside a
 # mocked CommandTracker class
#>

$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") -Function Export-EXOProvider -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ProviderHelpers/CommandTracker.psm1") -Force

InModuleScope -ModuleName ExportEXOProvider {
    Describe -Tag 'ExportEXOProvider' -Name "Export-EXOProvider" {
        BeforeAll {
            Mock Import-Module {}
            class MockCommandTracker {
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    # This is where you decide where you mock functions called by CommandTracker :)
                    try {
                        switch ($Command) {
                            "Get-RemoteDomain" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-AcceptedDomain" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-ScubaSpfRecord" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-DkimSigningConfig" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-ScubaDkimRecord" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-ScubaDmarcRecord" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-TransportConfig" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-SharingPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-TransportRule" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-HostedConnectionFilterPolicy" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-OrganizationConfig" {
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
            Mock -ModuleName ExportEXOProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
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
        It "When called, returns valid JSON" {
            $Json = Export-EXOProvider -PreferredDnsResolvers @() -SkipDoH $false
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
