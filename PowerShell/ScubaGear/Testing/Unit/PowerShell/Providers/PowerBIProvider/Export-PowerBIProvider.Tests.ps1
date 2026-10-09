<#
 #
 # Due to how the Error handling was implemented, mocked API calls have to be mocked inside a
 # mocked CommandTracker class.
 #
 # The Power BI Admin REST API commonly fails with 403/401 when nobody has logged into
 # the Power BI portal, when the interactive user lacks the Fabric Administrator role,
 # or when the service principal security group tenant setting is not configured.
 # These tests lock down the custom guidance emitted for those conditions, and make sure
 # unrelated failures do NOT emit that guidance.
#>

$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportPowerBIProvider.psm1") -Function Export-PowerBIProvider -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ProviderHelpers/CommandTracker.psm1") -Force

InModuleScope -ModuleName ExportPowerBIProvider {
    Describe -Tag 'PowerBIProvider' -Name "Export-PowerBIProvider" {
        BeforeAll {
            class MockCommandTracker {
                # The provider throws on unexpected failures, so its tracker instance is discarded before the
                # caller can inspect it. These static logs capture what was recorded anyway.
                static [System.Collections.Generic.List[string]]$Successful = [System.Collections.Generic.List[string]]::new()
                static [System.Collections.Generic.List[string]]$UnSuccessful = [System.Collections.Generic.List[string]]::new()

                static [void] Reset() {
                    [MockCommandTracker]::Successful.Clear()
                    [MockCommandTracker]::UnSuccessful.Clear()
                }

                [string[]]$SuccessfulCommands = @()
                [string[]]$UnSuccessfulCommands = @()

                [System.Object[]] TryCommand([string]$Command, [hashtable]$CommandArgs) {
                    throw "ERROR the Power BI provider should not route calls through TryCommand: $($Command)"
                }

                [System.Object[]] TryCommand([string]$Command) {
                    return $this.TryCommand($Command, @{})
                }

                [void] AddSuccessfulCommand([string]$Command) {
                    $this.SuccessfulCommands += $Command
                    [MockCommandTracker]::Successful.Add($Command)
                }

                [void] AddUnSuccessfulCommand([string]$Command) {
                    $this.UnSuccessfulCommands += $Command
                    [MockCommandTracker]::UnSuccessful.Add($Command)
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

            # The provider emits a bare JSON fragment, so wrap it in braces before parsing.
            function ConvertFrom-ProviderJson {
                param (
                    [string]
                    $Json
                )
                ConvertFrom-Json "{$($Json.TrimEnd(','))}" -ErrorAction Stop
            }

            # Real tenant settings shape: an object carrying a tenantSettings array.
            function New-MockAdminSettings {
                [pscustomobject]@{
                    tenantSettings = @(
                        [pscustomobject]@{
                            settingName = "PublishToWeb"
                            title       = "Publish to web"
                            enabled     = $false
                        },
                        [pscustomobject]@{
                            settingName           = "ServicePrincipalAccessPermissionAPIs"
                            enabled               = $true
                            enabledSecurityGroups = @(
                                [pscustomobject]@{
                                    graphId = "00000000-0000-0000-0000-000000000000"
                                    name    = "PBI SP Group"
                                }
                            )
                        }
                    )
                }
            }

            # Mimics what Get-PowerBITenantSettingsRest (via Invoke-ScubaRestMethod) rethrows for an HTTP failure.
            function New-RestError {
                param ([string]$Message)
                [System.Net.WebException]::new($Message)
            }

            # Mimics an HTTP failure that carries a response, where the provider reads the status code
            # instead of the message text.
            class MockHttpException : System.Exception {
                [object]$Response

                MockHttpException([string]$Message, [int]$StatusCode) : base($Message) {
                    $this.Response = [pscustomobject]@{ StatusCode = $StatusCode }
                }
            }

            function New-RestErrorWithStatus {
                param ([string]$Message, [int]$StatusCode)
                [MockHttpException]::new($Message, $StatusCode)
            }
        }

        Context 'When the tenant has no Power BI license' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { throw "should not be called" }
            }

            It 'returns valid JSON without calling the Power BI API' {
                $Json = Export-PowerBIProvider -LicenseFound $false | Select-Object -Last 1
                { ConvertFrom-ProviderJson -Json $Json } | Should -Not -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Get-PowerBITenantSettingsRest -Times 0 -Exactly
            }

            It 'reports powerbi_license_found as false with empty tenant settings' {
                $Json = Export-PowerBIProvider -LicenseFound $false | Select-Object -Last 1
                $Parsed = ConvertFrom-ProviderJson -Json $Json
                $Parsed.powerbi_license_found | Should -Be $false
                @($Parsed.powerbi_tenant_settings).Count | Should -Be 0
            }

            It 'does not require AccessToken or BaseUrl' {
                { Export-PowerBIProvider -LicenseFound $false } | Should -Not -Throw
            }

            It 'does not emit the permissions guidance banner' {
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
                Export-PowerBIProvider -LicenseFound $false | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }
        }

        # The Rego composes its report details from powerbi_license_reason, so the reason has to
        # survive the trip from Connect-Tenant through this provider and into the JSON verbatim.
        Context 'When reporting why the license check failed' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { throw "should not be called" }
            }

            It 'emits the tenant-level reason' {
                $Reason = 'No Power BI or Fabric license found in the tenant.'
                $Json = Export-PowerBIProvider -LicenseFound $false -LicenseReason $Reason | Select-Object -Last 1
                (ConvertFrom-ProviderJson -Json $Json).powerbi_license_reason | Should -Be $Reason
            }

            It 'emits the per-user reason' {
                $Reason = 'Current user does not have a Power BI or Fabric license assigned. Assign a license (e.g., Microsoft Fabric (Free), Power BI Pro) to the running user.'
                $Json = Export-PowerBIProvider -LicenseFound $false -LicenseReason $Reason | Select-Object -Last 1
                (ConvertFrom-ProviderJson -Json $Json).powerbi_license_reason | Should -Be $Reason
            }

            # Parentheses and commas in the per-user reason must not break the JSON fragment.
            It 'produces valid JSON for a reason containing punctuation' {
                $Reason = 'Assign a license (e.g., Microsoft Fabric (Free), Power BI Pro) to the "running" user.'
                $Json = Export-PowerBIProvider -LicenseFound $false -LicenseReason $Reason | Select-Object -Last 1
                { ConvertFrom-ProviderJson -Json $Json } | Should -Not -Throw
                (ConvertFrom-ProviderJson -Json $Json).powerbi_license_reason | Should -Be $Reason
            }

            # Empty is what makes the Rego fall back to its original generic message.
            It 'emits an empty reason when none is supplied' {
                $Json = Export-PowerBIProvider -LicenseFound $false | Select-Object -Last 1
                (ConvertFrom-ProviderJson -Json $Json).powerbi_license_reason | Should -Be ''
            }

            It 'emits an empty reason on the licensed path' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { New-MockAdminSettings }
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                (ConvertFrom-ProviderJson -Json $Json).powerbi_license_reason | Should -Be ''
                (ConvertFrom-ProviderJson -Json $Json).powerbi_access_denied_reason | Should -Be ''
            }
        }

        Context 'When LicenseFound is true but credentials are incomplete' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { throw "should not be called" }
            }

            It 'throws when AccessToken is missing' {
                { Export-PowerBIProvider -LicenseFound $true -BaseUrl 'https://api.powerbi.com' } |
                    Should -Throw '*AccessToken and BaseUrl must be provided*'
            }

            It 'throws when BaseUrl is missing' {
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' } |
                    Should -Throw '*AccessToken and BaseUrl must be provided*'
            }

            It 'throws when AccessToken is an empty string' {
                { Export-PowerBIProvider -LicenseFound $true -AccessToken '' -BaseUrl 'https://api.powerbi.com' } |
                    Should -Throw '*AccessToken and BaseUrl must be provided*'
            }

            It 'throws when BaseUrl is an empty string' {
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl '' } |
                    Should -Throw '*AccessToken and BaseUrl must be provided*'
            }

            It 'does not call the Power BI API when credentials are incomplete' {
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' } | Should -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Get-PowerBITenantSettingsRest -Times 0 -Exactly
            }
        }

        Context 'When the Power BI API returns tenant settings' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { New-MockAdminSettings }
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
            }

            It 'returns valid JSON' {
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                { ConvertFrom-ProviderJson -Json $Json } | Should -Not -Throw
            }

            It 'projects tenantSettings into powerbi_tenant_settings keyed by settingName' {
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                $Settings = @((ConvertFrom-ProviderJson -Json $Json).powerbi_tenant_settings)
                $Settings.Count | Should -Be 2
                $Settings.settingName | Should -Contain 'PublishToWeb'
                $Settings.settingName | Should -Contain 'ServicePrincipalAccessPermissionAPIs'
            }

            It 'preserves nested security group details that the Rego needs' {
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                $Settings = @((ConvertFrom-ProviderJson -Json $Json).powerbi_tenant_settings)
                $SpSetting = $Settings | Where-Object { $_.settingName -eq 'ServicePrincipalAccessPermissionAPIs' }
                @($SpSetting.enabledSecurityGroups).Count | Should -Be 1
                $SpSetting.enabledSecurityGroups[0].name | Should -Be 'PBI SP Group'
            }

            It 'records Get-PowerBITenantSettingsRest as a successful command so the Rego resolves it' {
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                $Parsed = ConvertFrom-ProviderJson -Json $Json
                @($Parsed.powerbi_successful_commands) | Should -Contain 'Get-PowerBITenantSettingsRest'
                @($Parsed.powerbi_unsuccessful_commands).Count | Should -Be 0
            }

            It 'reports powerbi_license_found as true' {
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                (ConvertFrom-ProviderJson -Json $Json).powerbi_license_found | Should -Be $true
            }

            It 'calls Get-PowerBITenantSettingsRest with the supplied token and base URL' {
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.high.powerbigov.us' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Get-PowerBITenantSettingsRest -Times 1 -Exactly -ParameterFilter {
                    $BaseUrl -eq 'https://api.high.powerbigov.us' -and
                    $AccessToken -eq 'mock-token'
                }
            }

            It 'does not emit the permissions guidance banner on success' {
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }
        }

        Context 'When the Power BI API returns an empty response' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
            }

            It 'throws an actionable error when an empty array is returned' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { @() }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' } |
                    Should -Throw '*No tenant settings were returned*'
            }

            It 'throws an actionable error when null is returned' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { $null }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' } |
                    Should -Throw '*No tenant settings were returned*'
            }

            It 'does not emit the permissions guidance banner for an empty response' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { @() }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' } | Should -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }

            It 'still returns valid JSON when the response lacks a tenantSettings property' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { [pscustomobject]@{ unexpected = 'shape' } }
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                { ConvertFrom-ProviderJson -Json $Json } | Should -Not -Throw
            }
        }

        Context 'When the Power BI API returns 403 Forbidden under interactive auth' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (403) Forbidden.")
                }
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
            }

            It 'returns the interactive fix in powerbi_access_denied_reason' {
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                $Result = ConvertFrom-ProviderJson -Json $Json
                $Result.powerbi_access_denied_reason | Should -Match '403 Forbidden'
                $Result.powerbi_access_denied_reason | Should -Match 'Fabric Administrator role'
                @($Result.powerbi_tenant_settings).Count | Should -Be 0
                $Result.powerbi_successful_commands | Should -Not -Contain 'Get-PowerBITenantSettingsRest'
            }

            It 'tells the user they need the Fabric Administrator role' {
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -ParameterFilter {
                    $MessageData -match 'Fabric Administrator role'
                }
            }

            It 'tells the user to sign into the Power BI portal at least once' {
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -ParameterFilter {
                    $MessageData -match 'sign into the Power BI portal at least once'
                }
            }

            It 'does not show the service principal security group guidance' {
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly -ParameterFilter {
                    $MessageData -match 'security group for the service principal'
                }
            }
        }

        Context 'When the Power BI API returns 403 Forbidden under service principal auth' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (403) Forbidden.")
                }
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
            }

            It 'returns the service principal fix in powerbi_access_denied_reason' {
                $Json = Export-PowerBIProvider -CertificateBasedAuth -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                $Result = ConvertFrom-ProviderJson -Json $Json
                $Result.powerbi_access_denied_reason | Should -Match 'security group for the service principal'
                $Result.powerbi_access_denied_reason | Should -Match 'noninteractive\.md#power-bi-tenant-setting'
                $Result.powerbi_access_denied_reason | Should -Match 'Tenant.Read.All'
            }

            It 'tells the user to configure a security group for the service principal' {
                Export-PowerBIProvider -CertificateBasedAuth -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -ParameterFilter {
                    $MessageData -match 'security group for the service principal'
                }
            }

            It 'links to the noninteractive Power BI tenant setting documentation' {
                Export-PowerBIProvider -CertificateBasedAuth -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -ParameterFilter {
                    $MessageData -match 'noninteractive\.md#power-bi-tenant-setting'
                }
            }

            It 'does not show the interactive Fabric Administrator guidance' {
                Export-PowerBIProvider -CertificateBasedAuth -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly -ParameterFilter {
                    $MessageData -match 'Fabric Administrator role'
                }
            }

            It 'treats -CertificateBasedAuth:$false as interactive auth' {
                Export-PowerBIProvider -CertificateBasedAuth:$false -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -ParameterFilter {
                    $MessageData -match 'Fabric Administrator role'
                }
            }
        }

        Context 'When the Power BI API returns 401 Unauthorized' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (401) Unauthorized.")
                }
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
            }


            It 'reports 401 Unauthorized in powerbi_access_denied_reason' {
                $Json = Export-PowerBIProvider -CertificateBasedAuth -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                (ConvertFrom-ProviderJson -Json $Json).powerbi_access_denied_reason | Should -Match '401 Unauthorized'
            }

            It 'shows the service principal guidance under service principal auth' {
                Export-PowerBIProvider -CertificateBasedAuth -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -ParameterFilter {
                    $MessageData -match 'security group for the service principal'
                }
            }

            It 'shows the interactive guidance under interactive auth' {
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -ParameterFilter {
                    $MessageData -match 'Fabric Administrator role'
                }
            }
        }

        # When there's a response, its status code decides rather than the message text
        Context 'When the failure carries an HTTP response' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
                Mock -ModuleName ExportPowerBIProvider Write-Warning {}
            }

            # PS 7 formats this as "403 (Forbidden)", so the (403) message fallback would not match it
            It 'shows the fix for a 403 using the status code' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestErrorWithStatus -Message "Response status code does not indicate success: 403 (Forbidden)." -StatusCode 403)
                }
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                (ConvertFrom-ProviderJson -Json $Json).powerbi_access_denied_reason | Should -Match '403 Forbidden.*Fabric Administrator role'
            }

            It 'does not show guidance for a 500 whose message contains (403)' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestErrorWithStatus -Message "Upstream call failed with (403) while proxying" -StatusCode 500)
                }
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                (ConvertFrom-ProviderJson -Json $Json).powerbi_access_denied_reason | Should -Be ''
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }
        }

        Context 'When the Power BI API fails for a reason unrelated to permissions' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
                Mock -ModuleName ExportPowerBIProvider Write-Warning {}
            }

            # Matches what TryCommand did before, so the report shows these policies as errors
            # instead of leaving Power BI out
            It 'still returns JSON with Get-PowerBITenantSettingsRest unsuccessful and no access denied reason' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (429) Too Many Requests.")
                }
                $Json = Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Select-Object -Last 1
                $Result = ConvertFrom-ProviderJson -Json $Json
                $Result.powerbi_unsuccessful_commands | Should -Contain 'Get-PowerBITenantSettingsRest'
                $Result.powerbi_successful_commands | Should -Not -Contain 'Get-PowerBITenantSettingsRest'
                $Result.powerbi_access_denied_reason | Should -Be ''
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Warning -Times 1 -Exactly
            }

            # Guards against the guidance banner firing on any failure, which would send
            # users chasing permissions problems they do not have.
            It 'does not emit guidance for a 500 Internal Server Error' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (500) Internal Server Error.")
                }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null } | Should -Not -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }

            It 'does not emit guidance for a 429 Too Many Requests' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (429) Too Many Requests.")
                }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null } | Should -Not -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }

            It 'does not emit guidance for a 404 Not Found' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (404) Not Found.")
                }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null } | Should -Not -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }

            It 'does not emit guidance for a network failure with no status code' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "Unable to connect to the remote server")
                }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null } | Should -Not -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }

            # When the exception has no HTTP response, the provider falls back to looking for "(401)" or
            # "(403)" in the error message. These messages mention 403 or Forbidden without that exact
            # form, so they must not be mistaken for a permissions error.
            It 'does not emit guidance when a message contains 403 outside of parentheses' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "Correlation id 4030f1ac-0000-0000-0000-000000000000 request failed")
                }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null } | Should -Not -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }

            It 'does not emit guidance when a message contains Forbidden but no status code' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "Operation Forbidden by tenant policy")
                }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null } | Should -Not -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -Times 0 -Exactly
            }
        }

        Context 'Debug logging of the permissions guidance' {
            BeforeEach {
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
                Mock -ModuleName ExportPowerBIProvider Write-Warning {}
                Mock -ModuleName ExportPowerBIProvider Write-ScubaLog {}
            }

            It 'logs the interactive guidance on a 403' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (403) Forbidden.")
                }
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-ScubaLog -Times 1 -Exactly -ParameterFilter {
                    $Data.AuthType -eq 'Interactive' -and
                    $Data.Guidance -match 'Fabric Administrator role' -and
                    $Data.Error -match '403'
                }
            }

            It 'logs the service principal guidance on a 403' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (403) Forbidden.")
                }
                Export-PowerBIProvider -CertificateBasedAuth -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-ScubaLog -Times 1 -Exactly -ParameterFilter {
                    $Data.AuthType -eq 'ServicePrincipal' -and
                    $Data.Guidance -match 'security group for the service principal' -and
                    $Data.Guidance -match 'noninteractive\.md#power-bi-tenant-setting'
                }
            }

            It 'logs the guidance on a 401' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (401) Unauthorized.")
                }
                Export-PowerBIProvider -CertificateBasedAuth -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-ScubaLog -Times 1 -Exactly
            }

            It 'logs the guidance at Info level' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (403) Forbidden.")
                }
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-ScubaLog -Times 1 -Exactly -ParameterFilter {
                    $Level -eq 'Info'
                }
            }

            It 'does not log guidance for a failure unrelated to permissions' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (500) Internal Server Error.")
                }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null } | Should -Not -Throw
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-ScubaLog -Times 0 -Exactly -ParameterFilter {
                    $Message -eq 'Power BI permissions guidance'
                }
            }

            It 'does not log guidance when the API call succeeds' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { New-MockAdminSettings }
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-ScubaLog -Times 0 -Exactly
            }

            # Guards the console and log copies against drifting apart.
            It 'logs the same guidance text it prints to the console' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (403) Forbidden.")
                }
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-Information -ParameterFilter {
                    $MessageData -match 'Fabric Administrator role'
                }
                Should -Invoke -ModuleName ExportPowerBIProvider -CommandName Write-ScubaLog -ParameterFilter {
                    $Data.Guidance -match 'Fabric Administrator role'
                }
            }
        }

        Context 'Command tracking' {
            BeforeEach {
                [MockCommandTracker]::Reset()
                Mock -ModuleName ExportPowerBIProvider Write-Information {}
                Mock -ModuleName ExportPowerBIProvider Write-Warning {}
            }

            It 'records Get-PowerBITenantSettingsRest as unsuccessful when the API returns 403 Forbidden' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (403) Forbidden.")
                }
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                [MockCommandTracker]::UnSuccessful | Should -Contain 'Get-PowerBITenantSettingsRest'
                [MockCommandTracker]::Successful | Should -Not -Contain 'Get-PowerBITenantSettingsRest'
            }

            It 'records Get-PowerBITenantSettingsRest as unsuccessful when the API returns 401 Unauthorized' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (401) Unauthorized.")
                }
                Export-PowerBIProvider -CertificateBasedAuth -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                [MockCommandTracker]::UnSuccessful | Should -Contain 'Get-PowerBITenantSettingsRest'
                [MockCommandTracker]::Successful | Should -Not -Contain 'Get-PowerBITenantSettingsRest'
            }

            It 'records Get-PowerBITenantSettingsRest as unsuccessful when the API fails for an unrelated reason' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (500) Internal Server Error.")
                }
                { Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null } | Should -Not -Throw
                [MockCommandTracker]::UnSuccessful | Should -Contain 'Get-PowerBITenantSettingsRest'
                [MockCommandTracker]::Successful | Should -Not -Contain 'Get-PowerBITenantSettingsRest'
            }

            It 'records Get-PowerBITenantSettingsRest only as successful when the API call succeeds' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest { New-MockAdminSettings }
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                [MockCommandTracker]::Successful | Should -Contain 'Get-PowerBITenantSettingsRest'
                [MockCommandTracker]::UnSuccessful | Should -Not -Contain 'Get-PowerBITenantSettingsRest'
            }

            It 'does not double count Get-PowerBITenantSettingsRest on the failure path' {
                Mock -ModuleName ExportPowerBIProvider Get-PowerBITenantSettingsRest {
                    throw (New-RestError -Message "The remote server returned an error: (403) Forbidden.")
                }
                Export-PowerBIProvider -LicenseFound $true -AccessToken 'mock-token' -BaseUrl 'https://api.powerbi.com' | Out-Null
                @([MockCommandTracker]::UnSuccessful).Count | Should -Be 1
            }
        }
    }
}

AfterAll {
    Remove-Module ExportPowerBIProvider -Force -ErrorAction SilentlyContinue
    Remove-Module CommandTracker -Force -ErrorAction SilentlyContinue
}
