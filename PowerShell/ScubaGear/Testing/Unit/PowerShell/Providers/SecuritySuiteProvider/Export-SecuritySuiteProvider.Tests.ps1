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
                switch ($CmdletName) {
                    'Get-AntiPhishRule' {
                        @(
                            [pscustomobject]@{ Name = 'Custom policy 10'; Priority = 10 }
                            [pscustomobject]@{ Name = 'Standard Preset Security Policy'; Priority = 99 }
                            [pscustomobject]@{ Name = 'Custom policy 0'; Priority = 0 }
                            [pscustomobject]@{ Name = 'Strict Preset Security Policy'; Priority = 99 }
                        )
                    }
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
        }

        It "When called with -M365Environment '<_>', orders policy tables by preset and priority" {
            $Json = Export-SecuritySuiteProvider -M365Environment $_ -AccessToken 'token' -ApiEndpoint 'https://example.test/adminapi/beta/tenant/InvokeCommand'
            $Parsed = ('{' + $Json.TrimEnd(',') + '}') | ConvertFrom-Json

            $Parsed.anti_phish_rules.Name | Should -Be @(
                'Strict Preset Security Policy'
                'Standard Preset Security Policy'
                'Custom policy 0'
                'Custom policy 10'
            )
        }
    }

    Describe -Tag 'ExportSecuritySuiteProvider' -Name 'Export-SecuritySuiteProvider error handling' {
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
            function Write-ScubaLog {}
            function Trace-ScubaFunction {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                param($FunctionName, $Parameters, [scriptblock]$ScriptBlock, $LogReturnValue, $LogErrors)
                & $ScriptBlock
            }

            Mock -ModuleName ExportSecuritySuiteProvider Import-Module {}
            Mock -ModuleName ExportSecuritySuiteProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
            }
            Mock -ModuleName ExportSecuritySuiteProvider Write-Warning {}
            Mock -ModuleName ExportSecuritySuiteProvider Write-ScubaLog {}

            function Invoke-ProviderExport {
                $Json = Export-SecuritySuiteProvider -M365Environment 'commercial' -AccessToken 'token' -ApiEndpoint 'https://example.test/adminapi/beta/tenant/InvokeCommand'
                ('{' + $Json.TrimEnd(',') + '}') | ConvertFrom-Json
            }
        }

        It "Surfaces the underlying error when an ATP cmdlet fails with a non-license error" {
            Mock -ModuleName ExportSecuritySuiteProvider Invoke-EXORestMethod {
                if ($CmdletName -eq 'Get-AtpPolicyForO365') {
                    throw "Exchange Online API call 'Get-AtpPolicyForO365' failed: The remote server returned an error: (503) Service Unavailable."
                }
                if ($CmdletName -eq 'Get-DlpComplianceRule') {
                    [pscustomobject]@{
                        Name = $CmdletName
                        ContentContainsSensitiveInformation = @()
                    }
                }
                else {
                    [pscustomobject]@{ Name = $CmdletName }
                }
            }

            $Parsed = Invoke-ProviderExport
            $Parsed.securitysuite_unsuccessful_commands | Should -Contain 'Get-AtpPolicyForO365'
            $Parsed.securitysuite_successful_commands | Should -Not -Contain 'Get-AtpPolicyForO365'
            Should -Invoke -ModuleName ExportSecuritySuiteProvider Write-Warning -ParameterFilter {
                $Message -match 'Get-AtpPolicyForO365' -and $Message -match '503'
            }
        }

        It "Does not report a missing defender license when an ATP cmdlet fails with a non-license error" {
            Mock -ModuleName ExportSecuritySuiteProvider Invoke-EXORestMethod {
                if ($CmdletName -eq 'Get-AtpPolicyForO365') {
                    throw "Exchange Online API call 'Get-AtpPolicyForO365' failed: The remote server returned an error: (503) Service Unavailable."
                }
                if ($CmdletName -eq 'Get-DlpComplianceRule') {
                    [pscustomobject]@{
                        Name = $CmdletName
                        ContentContainsSensitiveInformation = @()
                    }
                }
                else {
                    [pscustomobject]@{ Name = $CmdletName }
                }
            }

            $Parsed = Invoke-ProviderExport
            $Parsed.defender_license | Should -Be $true
        }

        It "Reports a missing defender license without a warning when ATP cmdlets fail with a license error" {
            Mock -ModuleName ExportSecuritySuiteProvider Invoke-EXORestMethod {
                if ($CmdletName -in @('Get-AtpPolicyForO365', 'Get-ATPProtectionPolicyRule')) {
                    throw "Exchange Online API call '$CmdletName' failed: The remote server returned an error: (400) Bad Request."
                }
                if ($CmdletName -eq 'Get-DlpComplianceRule') {
                    [pscustomobject]@{
                        Name = $CmdletName
                        ContentContainsSensitiveInformation = @()
                    }
                }
                else {
                    [pscustomobject]@{ Name = $CmdletName }
                }
            }

            $Parsed = Invoke-ProviderExport
            $Parsed.defender_license | Should -Be $false
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-AtpPolicyForO365'
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-ATPProtectionPolicyRule'
            Should -Invoke -ModuleName ExportSecuritySuiteProvider Write-Warning -Exactly -Times 0 -ParameterFilter {
                $Message -match 'Get-AtpPolicyForO365'
            }
        }

        It "Surfaces the underlying error when a DLP cmdlet fails with a non-license error" {
            Mock -ModuleName ExportSecuritySuiteProvider Invoke-EXORestMethod {
                if ($CmdletName -eq 'Get-DlpCompliancePolicy') {
                    throw "Exchange Online API call 'Get-DlpCompliancePolicy' failed: The operation has timed out."
                }
                if ($CmdletName -eq 'Get-DlpComplianceRule') {
                    [pscustomobject]@{
                        Name = $CmdletName
                        ContentContainsSensitiveInformation = @()
                    }
                }
                else {
                    [pscustomobject]@{ Name = $CmdletName }
                }
            }

            $Parsed = Invoke-ProviderExport
            $Parsed.defender_dlp_license | Should -Be $true
            $Parsed.securitysuite_unsuccessful_commands | Should -Contain 'Get-DlpCompliancePolicy'
            Should -Invoke -ModuleName ExportSecuritySuiteProvider Write-Warning -ParameterFilter {
                $Message -match 'Get-DlpCompliancePolicy' -and $Message -match 'timed out'
            }
        }

        It "Reports a missing DLP license without a warning when DLP cmdlets fail with a license error" {
            Mock -ModuleName ExportSecuritySuiteProvider Invoke-EXORestMethod {
                if ($CmdletName -in @('Get-DlpCompliancePolicy', 'Get-DlpComplianceRule', 'Get-ProtectionAlert')) {
                    throw "Exchange Online API call '$CmdletName' failed: The remote server returned an error: (400) Bad Request."
                }
                if ($CmdletName -eq 'Get-DlpComplianceRule') {
                    [pscustomobject]@{
                        Name = $CmdletName
                        ContentContainsSensitiveInformation = @()
                    }
                }
                else {
                    [pscustomobject]@{ Name = $CmdletName }
                }
            }

            $Parsed = Invoke-ProviderExport
            $Parsed.defender_dlp_license | Should -Be $false
            $Parsed.securitysuite_successful_commands | Should -Contain 'Get-DlpCompliancePolicy'
            Should -Invoke -ModuleName ExportSecuritySuiteProvider Write-Warning -Exactly -Times 0 -ParameterFilter {
                $Message -match 'Get-DlpCompliancePolicy'
            }
        }

        It "Returns valid JSON when a cmdlet fails" {
            Mock -ModuleName ExportSecuritySuiteProvider Invoke-EXORestMethod {
                if ($CmdletName -eq 'Get-AtpPolicyForO365') {
                    throw "Exchange Online API call 'Get-AtpPolicyForO365' failed: The remote server returned an error: (503) Service Unavailable."
                }
                if ($CmdletName -eq 'Get-DlpComplianceRule') {
                    [pscustomobject]@{
                        Name = $CmdletName
                        ContentContainsSensitiveInformation = @()
                    }
                }
                else {
                    [pscustomobject]@{ Name = $CmdletName }
                }
            }

            { Invoke-ProviderExport } | Should -Not -Throw
        }
    }
}

AfterAll {
    Remove-Module ExportSecuritySuiteProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
