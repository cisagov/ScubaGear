<#
 # Due to how the Error handling was implemented, mocked API calls have to be mocked inside a
 # mocked CommandTracker class
#>

$ProviderPath = "../../../../../PowerShell/ScubaGear/Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportSharePointProvider.psm1") -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ProviderHelpers/CommandTracker.psm1") -Force

InModuleScope -ModuleName ExportSharePointProvider {
    Describe -Tag 'SharePointProvider' -Name "Export-SharePointProvider" {
        BeforeAll {
            class MockCommandTracker {
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    # This is where you decide where you mock functions called by CommandTracker :)
                    try {
                        switch ($Command) {
                            "Get-MgBetaOrganization" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{
                                    VerifiedDomains = @(
                                        @{
                                            "isInitial" = $true;
                                            "Name"      = "contoso.onmicrosoft.com";
                                        }
                                        @{
                                            "isInitial" = $false;
                                            "Name"      = "example.onmicrosoft.com";
                                        }
                                    )
                                }
                            }
                            { ($_ -eq "Get-SPOSite") -or ($_ -eq "Get-PnPTenantSite") } {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            { ($_ -eq "Get-SPOTenant") -or ($_ -eq "Get-PnPTenant") } {
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
            Mock -ModuleName ExportSharePointProvider Get-CommandTracker {
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
        Context 'When Running Interactively' {
            It "with -M365Environment 'commercial', returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'commercial'
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It "with -M365Environment 'gcc', returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'gcc'
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It "with -M365Environment 'gcchigh', returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'gcchigh'
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It "with -M365Environment 'dod', returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'dod'
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
        }
        Context 'When running with Service Principals' {
            It "with -M365Environment commercial, returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment commercial -PnPFlag
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It "with -M365Environment gcc, returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'gcc' -PnPFlag
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It "with -M365Environment gcchigh, returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'gcchigh' -PnPFlag
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It "with -M365Environment dod, returns valid JSON" {
                $Json = Export-SharePointProvider -M365Environment 'dod' -PnPFlag
                $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
        }
    }
}
AfterAll {
    Remove-Module ExportSharePointProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
