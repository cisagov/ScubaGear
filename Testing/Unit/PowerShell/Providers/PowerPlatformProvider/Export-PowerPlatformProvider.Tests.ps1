<#
 # Due to how the Error handling was implemented, mocked API calls have to be mocked inside a
 # mocked CommandTracker class
#>

$ProviderPath = "../../../../../PowerShell/ScubaGear/Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportPowerPlatformProvider.psm1") -Function Export-PowerPlatformProvider -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ProviderHelpers/CommandTracker.psm1") -Force

InModuleScope -ModuleName ExportPowerPlatformProvider {
    Describe -Tag 'ExportPowerPlatformProvider' -Name "Export-PowerPlatformProvider" {
        BeforeAll {
            class MockCommandTracker {
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    # This is where you decide where you mock functions called by CommandTracker :)
                    try {
                        switch ($Command) {
                            "Get-TenantDetailsFromGraph" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{
                                    Domains     = @(
                                        @{
                                            Name    = "example.onmicrosoft.com";
                                            initial = $true;
                                        },
                                        @{
                                            Name    = "contoso.onmicrosoft.com";
                                            initial = $false;
                                        }
                                    );
                                    DisplayName = "DisplayName";
                                    TenantId    = "TenantId";
                                }
                            }
                            "Get-TenantSettings" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-AdminPowerAppEnvironment" {
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{}
                            }
                            "Get-AdminPowerAppEnvironment" {
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
            Mock -ModuleName ExportPowerPlatformProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
            }
            function Get-DlpPolicy {}
            Mock -ModuleName ExportPowerPlatformProvider Get-DlpPolicy -MockWith {}
            function Get-PowerAppTenantIsolationPolicy {}
            Mock -ModuleName ExportPowerPlatformProvider Get-PowerAppTenantIsolationPolicy -MockWith {}
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
        It "When called with -M365Environment 'commercial', returns valid JSON" {
            Mock -CommandName Invoke-WebRequest {
                return [pscustomobject]@{
                    Content = '{"tenant_region_scope": "NA","tenant_region_sub_scope": ""}'
                }
            }
            $Json = Export-PowerPlatformProvider -M365Environment 'commercial'
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'gcc', returns valid JSON" {
            Mock -CommandName Invoke-WebRequest {
                return [pscustomobject]@{
                    Content = '{"tenant_region_scope": "NA","tenant_region_sub_scope": "GCC"}'
                }
            }
            $Json = Export-PowerPlatformProvider -M365Environment 'gcc'
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'gcchigh', returns valid JSON" {
            Mock -CommandName Invoke-WebRequest {
                return [pscustomobject]@{
                    Content = '{"tenant_region_scope": "USGov","tenant_region_sub_scope": "DODCON"}'
                }
            }
            $Json = Export-PowerPlatformProvider -M365Environment 'gcchigh'
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'dod', returns valid JSON" {
            Mock -CommandName Invoke-WebRequest {
                return [pscustomobject]@{
                    Content = '{"tenant_region_scope": "USGov","tenant_region_sub_scope": "DOD"}'
                }
            }
            $Json = Export-PowerPlatformProvider -M365Environment 'dod'
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
        It "When called with -M365Environment 'commercial', from a non-NA tenant returns valid json" {
            Mock -CommandName Invoke-WebRequest {
                return [pscustomobject]@{
                    Content = '{"tenant_region_scope": "EU","tenant_region_sub_scope": ""}'
                }
            }
            $Json = Export-PowerPlatformProvider -M365Environment 'commercial'
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }
    }
}
AfterAll {
    Remove-Module ExportPowerPlatformProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
