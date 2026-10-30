<#
 # Tests for the SI Provider shell.
 # The provider does not export any settings yet, so these tests only lock down
 # the JSON fragment shape that Invoke-ProviderList concatenates with the other
 # providers. Each follow-up policy group adds tests for the settings it exports.
#>

$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportSIProvider.psm1") -Function Export-SIProvider -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ProviderHelpers/CommandTracker.psm1") -Force

InModuleScope -ModuleName ExportSIProvider {
    Describe -Tag 'SIProvider' -Name "Export-SIProvider" {
        BeforeAll {
            class MockCommandTracker {
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    throw "ERROR the SI provider shell should not call any commands: $($Command)"
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
            Mock -ModuleName ExportSIProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
            }

            # The provider emits a bare JSON fragment, so wrap it in braces before parsing.
            function ConvertFrom-ProviderJson {
                param (
                    [string]
                    $Json
                )
                ConvertFrom-Json "{$($Json.TrimEnd(','))}" -ErrorAction Stop
            }
        }
        It "returns valid JSON" {
            $Json = Export-SIProvider
            { ConvertFrom-ProviderJson -Json $Json } | Should -Not -Throw
        }
        It "returns empty si_successful_commands and si_unsuccessful_commands" {
            $Output = ConvertFrom-ProviderJson -Json (Export-SIProvider)
            $Output.PSObject.Properties.Name | Should -Be @('si_successful_commands', 'si_unsuccessful_commands')
            @($Output.si_successful_commands).Count | Should -Be 0
            @($Output.si_unsuccessful_commands).Count | Should -Be 0
        }
        It "ends with a trailing comma so Invoke-ProviderList can concatenate it" {
            $Json = Export-SIProvider
            $Json.TrimEnd() | Should -Match ',$'
        }
    }
}
AfterAll {
    Remove-Module ExportSIProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
