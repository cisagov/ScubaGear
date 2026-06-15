<#
 # SecuritySuite provider uses EXO Admin API calls directly.
#>

$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportSecuritySuiteProvider.psm1") -Function Export-SecuritySuiteProvider -Force

InModuleScope -ModuleName ExportSecuritySuiteProvider {
    Describe -Tag 'ExportSecuritySuiteProvider' -Name 'Export-SecuritySuiteProvider' -ForEach @(
        'commercial',
        'gcc',
        'gcchigh',
        'dod'
    ) {
        BeforeAll {
            class MockCommandTracker {
                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

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
            function Invoke-EXORestMethod {}

            Mock -ModuleName ExportSecuritySuiteProvider Import-Module {}
            Mock -ModuleName ExportSecuritySuiteProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
            }
            Mock -ModuleName ExportSecuritySuiteProvider Invoke-EXORestMethod {
                switch ($CmdletName) {
                    'Get-DlpComplianceRule' {
                        [pscustomobject]@{
                            Name = $CmdletName
                            ContentContainsSensitiveInformation = @()
                        }
                    }
                    default {
                        [pscustomobject]@{ Name = $CmdletName }
                    }
                }
            }

            function Test-SCuBAValidProviderJson {
                param (
                    [string]
                    $Json
                )
                $Json = $Json.TrimEnd(',')
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

        It "When called with -M365Environment '<_>', returns valid JSON" {
            $Json = Export-SecuritySuiteProvider -M365Environment $_ -AccessToken 'token' -ApiEndpoint 'https://example.test/adminapi/beta/tenant/InvokeCommand'
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }

        It "When called with -M365Environment '<_>', records expected command names" {
            $Json = Export-SecuritySuiteProvider -M365Environment $_ -AccessToken 'token' -ApiEndpoint 'https://example.test/adminapi/beta/tenant/InvokeCommand'
            $Parsed = ('{' + $Json.TrimEnd(',') + '}') | ConvertFrom-Json
            $Parsed.defender_successful_commands | Should -Contain 'Get-AdminAuditLogConfig'
            $Parsed.defender_successful_commands | Should -Contain 'Get-EOPProtectionPolicyRule'
            $Parsed.defender_successful_commands | Should -Contain 'Get-AntiPhishPolicy'
        }
    }
}

AfterAll {
    Remove-Module ExportSecuritySuiteProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
