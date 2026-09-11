<#
 # Due to how the Error handling was implemented, mocked API calls have to be mocked inside a
 # mocked CommandTracker class
#>

$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportPowerBIProvider.psm1") -Function Export-PowerBIProvider -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ProviderHelpers/CommandTracker.psm1") -Force

InModuleScope -ModuleName ExportPowerBIProvider {
    Describe -Tag 'ExportPowerBIProvider' -Name "Export-PowerBIProvider" {
        BeforeAll {
            Mock Import-Module {}
            class MockCommandTracker {
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    try {
                        switch ($Command) {
                            "Invoke-ScubaRestMethod" {
                                $CommandArgs.BaseUrl | Should -Be 'https://api.powerbi.com'
                                $CommandArgs.AccessToken | Should -Be 'mock-access-token'
                                $CommandArgs.Endpoint | Should -Be '/v1/admin/tenantsettings'
                                $CommandArgs.Method | Should -Be 'GET'
                                $this.SuccessfulCommands += $Command
                                return [pscustomobject]@{
                                    tenantSettings = @(
                                        @{ settingName = "ExampleSetting"; enabled = $true }
                                    )
                                }
                            }
                            default {
                                throw "ERROR you forgot to create a mock method for this cmdlet: $($Command)"
                            }
                        }
                        return @()
                    }
                    catch {
                        Write-Warning "Error running $($Command). $($_)"
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
            }
            function Get-CommandTracker {}
            Mock -ModuleName ExportPowerBIProvider Get-CommandTracker {
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

        It "When LicenseFound is true, calls Invoke-ScubaRestMethod with the tenant settings endpoint and returns valid JSON" {
            $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-access-token' -BaseUrl 'https://api.powerbi.com'
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
            $Json | Should -Match '"powerbi_license_found": true'
            $Json | Should -Match 'ExampleSetting'
        }

        It "When LicenseFound is false, does not call Invoke-ScubaRestMethod and returns empty tenant settings" {
            $Json = Export-PowerBIProvider -LicenseFound $false
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
            $Json | Should -Match '"powerbi_license_found": false'
            $Json | Should -Not -Match 'ExampleSetting'
        }

        It "When LicenseFound is true but AccessToken is missing, throws" {
            { Export-PowerBIProvider -LicenseFound $true -BaseUrl 'https://api.powerbi.com' } | Should -Throw "*AccessToken and BaseUrl must be provided*"
        }

        It "When LicenseFound is true but BaseUrl is missing, throws" {
            { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-access-token' } | Should -Throw "*AccessToken and BaseUrl must be provided*"
        }
    }
}
