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

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs, [bool]$SuppressWarning) {
                    $this.SuccessfulCommands += $Command
                    return @([pscustomobject]@{ Name = $Command })
                }

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    return $this.TryCommand($Command, $CommandArgs, $false)
                }

                [System.Object[]] TryCommand([string]$Command) {
                    return $this.TryCommand($Command, @{}, $false)
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
            function Invoke-EXORestMethod {}
            function Trace-ScubaFunction {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                param($FunctionName, $Parameters, [scriptblock]$ScriptBlock, $LogReturnValue, $LogErrors)
                & $ScriptBlock
            }

            Mock -ModuleName ExportSecuritySuiteProvider Import-Module {}
            Mock -ModuleName ExportSecuritySuiteProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
            }
            Mock -ModuleName ExportSecuritySuiteProvider Invoke-EXORestMethod {
                Write-Information "Mocked Invoke-EXORestMethod called with CmdletName: $CmdletName" -InformationAction Continue
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
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-AdminAuditLogConfig'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-EOPProtectionPolicyRule'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-AntiPhishPolicy'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-AntiPhishRule'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-AcceptedDomain'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-HostedConnectionFilterPolicy'

            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-SafeLinksPolicy'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-SafeLinksRule'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-HostedContentFilterPolicy'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-HostedContentFilterRule'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-MalwareFilterPolicy'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-MalwareFilterRule'

            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-SafeAttachmentPolicy'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-SafeAttachmentRule'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-ATPBuiltInProtectionRule'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-AtpPolicyForO365'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-ATPProtectionPolicyRule'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-DlpCompliancePolicy'

            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-DlpComplianceRule'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-ProtectionAlert'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-UnifiedAuditLogRetentionPolicy'
        }
    }
}

AfterAll {
    Remove-Module ExportSecuritySuiteProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
