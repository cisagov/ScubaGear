$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportTeamsProvider.psm1") -Function Export-TeamsProvider -Force

InModuleScope -ModuleName ExportTeamsProvider {
    Describe -Tag 'ExportTeamsProvider' -Name 'Export-TeamsProvider' -ForEach @(
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

            Mock -ModuleName ExportTeamsProvider Import-Module {}

            function Get-CommandTracker {}
            Mock -ModuleName ExportTeamsProvider Get-CommandTracker {
                return [MockCommandTracker]::New()
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
            $Json = Export-TeamsProvider -M365Environment $_ -AccessToken 'token' -BaseUrl 'https://baseTeams.test/adminapi/beta/tenant/InvokeCommand' `
                -UnifiedAccessToken 'token' -UnifiedBaseUrl 'https://unifiedBaseTeams.test/adminapi/beta/tenant/InvokeCommand'
            $ValidJson = Test-SCuBAValidProviderJson -Json $Json | Select-Object -Last 1
            $ValidJson | Should -Be $true
        }

        It "When called with -M365Environment '<_>', records expected command names" {
            $Json = Export-TeamsProvider -M365Environment $_ -AccessToken 'token' -BaseUrl 'https://baseTeams.test/adminapi/beta/tenant/InvokeCommand' `
                -UnifiedAccessToken 'token' -UnifiedBaseUrl 'https://unifiedBaseTeams.test/adminapi/beta/tenant/InvokeCommand'
            $Parsed = ('{' + $Json.TrimEnd(',') + '}') | ConvertFrom-Json
            $Parsed.teams_successful_commands | Should -Contain 'Get-TeamsMeetingPolicyRest'
            $Parsed.teams_successful_commands | Should -Contain 'Get-TeamsTenantFederationConfigurationRest'
            $Parsed.teams_successful_commands | Should -Contain 'Get-TeamsClientConfigurationRest'

            $Parsed.teams_successful_commands | Should -Contain 'Get-TeamsAppPermissionPolicyRest'
            $Parsed.teams_successful_commands | Should -Contain 'Get-TeamsMeetingBroadcastPolicyRest'
            $Parsed.teams_successful_commands | Should -Contain 'Get-TeamsM365UnifiedTenantSettingsRest'
        }

        It "When called with -CertificateBasedAuth '<_>', includes CertificateBasedAuth in JSON output" {
            $Json = Export-TeamsProvider -M365Environment $_ -AccessToken 'token' -BaseUrl 'https://baseTeams.test/adminapi/beta/tenant/InvokeCommand' `
                -UnifiedAccessToken 'token' -UnifiedBaseUrl 'https://unifiedBaseTeams.test/adminapi/beta/tenant/InvokeCommand' -CertificateBasedAuth
            $Parsed = ('{' + $Json.TrimEnd(',') + '}') | ConvertFrom-Json
            if ($_ -in @('commercial', 'gcc')) {
                $Parsed.tenant_app_settings.CertificateBasedAuth | Should -Be $true
            }
        }
    }
}

AfterAll {
    Remove-Module ExportTeamsProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
