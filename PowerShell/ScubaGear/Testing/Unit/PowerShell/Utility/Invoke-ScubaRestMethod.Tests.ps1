$UtilityPath = '../../../../Modules/Utility/Utility.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $UtilityPath) -Function 'Invoke-ScubaRestMethod' -Force

InModuleScope Utility {
    Describe -Tag 'Utility' -Name 'Invoke-ScubaRestMethod' {
        BeforeAll {
            function New-FakeHttpWebResponse {
                param(
                    [int]$StatusCode,
                    [string]$RetryAfter
                )
                $Headers = [System.Net.WebHeaderCollection]::new()
                if ($RetryAfter) {
                    $Headers.Add('Retry-After', $RetryAfter)
                }
                $FakeResponse = [PSCustomObject]@{
                    StatusCode        = $StatusCode
                    StatusDescription = "Status $StatusCode"
                    ContentType       = "application/json"
                    ContentLength     = 0
                    Headers           = $Headers
                }
                $FakeResponse | Add-Member -MemberType ScriptMethod -Name GetResponseStream -Value { return $null }
                return $FakeResponse
            }

            function New-FakeRestException {
                param(
                    [int]$StatusCode,
                    [string]$RetryAfter
                )
                $Ex = New-Object System.Exception "Simulated HTTP $StatusCode"
                $FakeResponse = New-FakeHttpWebResponse -StatusCode $StatusCode -RetryAfter $RetryAfter
                $Ex | Add-Member -NotePropertyName Response -NotePropertyValue $FakeResponse -Force
                return $Ex
            }
        }

        Context 'Successful call' {
            It 'Returns the response on the first attempt without retrying' {
                Mock -ModuleName Utility Invoke-RestMethod { return [pscustomobject]@{ result = 'ok' } }
                $Result = Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' -MaxRetries 3
                $Result.result | Should -Be 'ok'
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 1 -Exactly
            }
        }

        Context '429 retry behavior' {
            It 'Retries on 429 and succeeds once the throttling clears' {
                $script:CallCount = 0
                Mock -ModuleName Utility Invoke-RestMethod {
                    $script:CallCount++
                    if ($script:CallCount -eq 1) {
                        throw (New-FakeRestException -StatusCode 429)
                    }
                    return [pscustomobject]@{ result = 'ok' }
                }
                $Result = Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                    -MaxRetries 2 -RetryDelaySeconds 0 -WarningAction SilentlyContinue
                $Result.result | Should -Be 'ok'
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 2 -Exactly
            }

            It 'Exhausts retries on persistent 429 and throws the original exception' {
                Mock -ModuleName Utility Invoke-RestMethod { throw (New-FakeRestException -StatusCode 429) }
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                        -MaxRetries 2 -RetryDelaySeconds 0 -WarningAction SilentlyContinue -InformationAction SilentlyContinue } | Should -Throw
                # 1 initial attempt + 2 retries = 3 calls
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 3 -Exactly
            }

            It 'Honors the Retry-After header value when sleeping between attempts' {
                Mock -ModuleName Utility Invoke-RestMethod { throw (New-FakeRestException -StatusCode 429 -RetryAfter '12') }
                Mock -ModuleName Utility Start-Sleep { }
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                        -MaxRetries 1 -RetryDelaySeconds 5 -WarningAction SilentlyContinue -InformationAction SilentlyContinue } | Should -Throw
                Should -Invoke -ModuleName Utility Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 12 }
            }

            It 'Honors a PS 5.1-style HTTP-date Retry-After header value' {
                $RetryAfter = [DateTimeOffset]::UtcNow.AddSeconds(60).ToString('R')
                $Response = New-FakeHttpWebResponse -StatusCode 429 -RetryAfter $RetryAfter
                $Seconds = Get-RetryAfterSeconds -HttpResponseObject $Response -DefaultSeconds 5
                $Seconds | Should -BeGreaterOrEqual 59
                $Seconds | Should -BeLessOrEqual 60
            }

            It 'Honors a PS 7-style HTTP-date Retry-After header value' {
                Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
                $Response = [System.Net.Http.HttpResponseMessage]::new()
                try {
                    $RetryAfter = [DateTimeOffset]::UtcNow.AddSeconds(60).ToString('R')
                    $Response.Headers.RetryAfter = [System.Net.Http.Headers.RetryConditionHeaderValue]::Parse($RetryAfter)
                    $Seconds = Get-RetryAfterSeconds -HttpResponseObject $Response -DefaultSeconds 5
                    $Seconds | Should -BeGreaterOrEqual 59
                    $Seconds | Should -BeLessOrEqual 60
                }
                finally {
                    $Response.Dispose()
                }
            }

            It 'Clamps a past HTTP-date Retry-After header value to zero' {
                $RetryAfter = [DateTimeOffset]::UtcNow.AddMinutes(-1).ToString('R')
                $Response = New-FakeHttpWebResponse -StatusCode 429 -RetryAfter $RetryAfter
                Get-RetryAfterSeconds -HttpResponseObject $Response -DefaultSeconds 5 | Should -Be 0
            }

            It 'Caps an excessively large Retry-After value at 3600 seconds' {
                Mock -ModuleName Utility Invoke-RestMethod { throw (New-FakeRestException -StatusCode 429 -RetryAfter '999999999') }
                Mock -ModuleName Utility Start-Sleep { }
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                        -MaxRetries 1 -RetryDelaySeconds 5 -WarningAction SilentlyContinue -InformationAction SilentlyContinue } | Should -Throw
                Should -Invoke -ModuleName Utility Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 3600 }
            }
        }

        Context '500/503 retry behavior' {
            It 'Retries on 503 with backoff and eventually throws after exhausting retries' {
                Mock -ModuleName Utility Invoke-RestMethod { throw (New-FakeRestException -StatusCode 503) }
                Mock -ModuleName Utility Start-Sleep { }
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                        -MaxRetries 2 -RetryDelaySeconds 5 -WarningAction SilentlyContinue -InformationAction SilentlyContinue } | Should -Throw
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 3 -Exactly
                # First retry waits 5s, second retry doubles to 10s
                Should -Invoke -ModuleName Utility Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 5 }
                Should -Invoke -ModuleName Utility Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 10 }
            }
        }

        Context 'Transient connection error retry behavior' {
            BeforeAll {
                Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
            }

            It 'Retries on a connection timeout (WebException) and succeeds once the connection recovers' {
                $script:CallCount = 0
                Mock -ModuleName Utility Invoke-RestMethod {
                    $script:CallCount++
                    if ($script:CallCount -eq 1) {
                        throw (New-Object System.Net.WebException('The operation has timed out', [System.Net.WebExceptionStatus]::Timeout))
                    }
                    return [pscustomobject]@{ result = 'ok' }
                }
                $Result = Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                    -MaxRetries 2 -RetryDelaySeconds 0 -WarningAction SilentlyContinue
                $Result.result | Should -Be 'ok'
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 2 -Exactly
            }

            It 'Exhausts retries on a persistent connection timeout and throws the original exception' {
                Mock -ModuleName Utility Invoke-RestMethod { throw (New-Object System.Net.WebException('The operation has timed out', [System.Net.WebExceptionStatus]::Timeout)) }
                Mock -ModuleName Utility Start-Sleep { }
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                        -MaxRetries 2 -RetryDelaySeconds 1 -WarningAction SilentlyContinue -InformationAction SilentlyContinue } | Should -Throw '*timed out*'
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 3 -Exactly
            }

            It 'Does not retry on a non-transient WebException status with no response object' {
                Mock -ModuleName Utility Invoke-RestMethod { throw (New-Object System.Net.WebException('Trust failure', [System.Net.WebExceptionStatus]::TrustFailure)) }
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                        -MaxRetries 3 -InformationAction SilentlyContinue } | Should -Throw
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 1 -Exactly
            }

            It 'Retries on a PS7-style HttpRequestException with no response object' {
                $script:CallCount2 = 0
                Mock -ModuleName Utility Invoke-RestMethod {
                    $script:CallCount2++
                    if ($script:CallCount2 -eq 1) {
                        throw (New-Object System.Net.Http.HttpRequestException('Connection reset by peer'))
                    }
                    return [pscustomobject]@{ result = 'ok' }
                }
                $Result = Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                    -MaxRetries 2 -RetryDelaySeconds 0 -WarningAction SilentlyContinue
                $Result.result | Should -Be 'ok'
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 2 -Exactly
            }
        }

        Context 'Non-retryable errors' {
            It 'Does not retry on 404 and throws immediately' {
                Mock -ModuleName Utility Invoke-RestMethod { throw (New-FakeRestException -StatusCode 404) }
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                        -MaxRetries 3 -InformationAction SilentlyContinue } | Should -Throw
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 1 -Exactly
            }

            It 'Does not retry when MaxRetries is not specified (defaults to 0)' {
                Mock -ModuleName Utility Invoke-RestMethod { throw (New-FakeRestException -StatusCode 429) }
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                        -InformationAction SilentlyContinue } | Should -Throw
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 1 -Exactly
            }
        }

        Context 'Header, timeout, and body pass-through' {
            It 'Passes AdditionalHeaders, TimeoutSec, Method, and Body to Invoke-RestMethod' {
                Mock -ModuleName Utility Invoke-RestMethod { return [pscustomobject]@{ result = 'ok' } }
                $null = Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                    -Method POST -Body '{"a":1}' -TimeoutSec 30 -AdditionalHeaders @{ 'X-Custom' = 'value' }
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $Body -eq '{"a":1}' -and
                    $TimeoutSec -eq 30 -and
                    $Headers['X-Custom'] -eq 'value' -and
                    $Headers['Authorization'] -eq 'Bearer tok'
                }
            }

            It 'Does not allow AdditionalHeaders to override the Authorization header' {
                Mock -ModuleName Utility Invoke-RestMethod { return [pscustomobject]@{ result = 'ok' } }
                $null = Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' `
                    -AdditionalHeaders @{ 'Authorization' = 'Bearer spoofed' } -WarningAction SilentlyContinue
                Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                    $Headers['Authorization'] -eq 'Bearer tok'
                }
            }
        }

        Context 'Parameter validation' {
            It 'Rejects a negative MaxRetries value' {
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' -MaxRetries -1 } | Should -Throw
            }

            It 'Rejects a negative RetryDelaySeconds value' {
                { Invoke-ScubaRestMethod -BaseUrl 'https://example.com' -AccessToken 'tok' -Endpoint '/x' -RetryDelaySeconds -1 } | Should -Throw
            }
        }
    }

    $TenantId = '11111111-2222-3333-4444-555555555555'

    $restApiCases = @(
        @{ Function = 'Get-SPOTenantRest'; Product = 'sharepoint'; Method = 'GET'; Path = '/_api/SPO.Tenant' },
        @{ Function = 'Get-PowerPlatformTenantSettingsRest'; Product = 'powerplatform'; Method = 'POST'; Path = '/providers/Microsoft.BusinessAppPlatform/listTenantSettings?api-version=2023-06-01' },
        @{ Function = 'Get-PowerPlatformEnvironmentsRest'; Product = 'powerplatform'; Method = 'GET'; Path = '/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments?api-version=2023-06-01' },
        @{ Function = 'Get-PowerPlatformDlpPoliciesRest'; Product = 'powerplatform'; Method = 'GET'; Path = '/providers/Microsoft.BusinessAppPlatform/scopes/admin/apiPolicies?api-version=2016-11-01' },
        @{ Function = 'Get-PowerPlatformTenantIsolationRest'; Product = 'powerplatform'; Method = 'GET'; Path = "/providers/PowerPlatform.Governance/v1/tenants/$TenantId/tenantIsolationPolicy?api-version=2020-06-01" },
        @{ Function = 'Get-TeamsMeetingPolicyRest'; Product = 'teams'; Method = 'GET'; Path = '/Skype.Policy/configurations/TeamsMeetingPolicy' },
        @{ Function = 'Get-TeamsTenantFederationConfigurationRest'; Product = 'teams'; Method = 'GET'; Path = '/Skype.Policy/configurations/TenantFederationSettings' },
        @{ Function = 'Get-TeamsClientConfigurationRest'; Product = 'teams'; Method = 'GET'; Path = '/Skype.Policy/configurations/TeamsClientConfiguration' },
        @{ Function = 'Get-TeamsAppPermissionPolicyRest'; Product = 'teams'; Method = 'GET'; Path = '/Skype.Policy/configurations/TeamsAppPermissionPolicy' },
        @{ Function = 'Get-TeamsMeetingBroadcastPolicyRest'; Product = 'teams'; Method = 'GET'; Path = '/Skype.Policy/configurations/TeamsMeetingBroadcastPolicy' },
        @{ Function = 'Get-TeamsM365UnifiedTenantSettingsRest'; Product = 'teamsunified'; Method = 'GET'; Path = '/AdminAppCatalog/ps/v2/admin/unifiedApp/settings' },
        @{ Function = 'Get-PowerBITenantSettingsRest'; Product = 'powerbi'; Method = 'GET'; Path = '/v1/admin/tenantsettings' },
        # EXO and Security & Compliance post to the default (non-redirected) InvokeCommand endpoint.
        @{ Function = 'Invoke-EXORestMethod'; Product = 'exo'; Method = 'POST'; Path = "/adminapi/beta/$TenantId/InvokeCommand" },
        @{ Function = 'Invoke-EXORestMethod'; Product = 'securitysuite'; Method = 'POST'; Path = "/adminapi/beta/$TenantId/InvokeCommand" }
    )

    # SharePoint URLs use 'contoso' for the {domain} placeholder.
    $serviceBaseUrls = @{
        sharepoint    = [ordered]@{ commercial = 'https://contoso-admin.sharepoint.com'; gcc = 'https://contoso-admin.sharepoint.com'; gcchigh = 'https://contoso-admin.sharepoint.us'; dod = 'https://contoso-admin.sharepoint-mil.us' }
        powerplatform = [ordered]@{ commercial = 'https://api.bap.microsoft.com'; gcc = 'https://gov.api.bap.microsoft.us'; gcchigh = 'https://high.api.bap.microsoft.us'; dod = 'https://api.appsplatform.us' }
        teams         = [ordered]@{ commercial = 'https://api.interfaces.records.teams.microsoft.com'; gcc = 'https://api.interfaces.records.teams.microsoft.com'; gcchigh = 'https://api.interfaces.records.gov.teams.microsoft.us'; dod = 'https://api.interfaces.records.gov.teams.microsoft.us' }
        teamsunified  = [ordered]@{ commercial = 'https://substrate.office.com'; gcc = 'https://substrate.office.com' }
        powerbi       = [ordered]@{ commercial = 'https://api.powerbi.com'; gcc = 'https://api.powerbigov.us'; gcchigh = 'https://api.high.powerbigov.us'; dod = 'https://api.mil.powerbigov.us' }
        exo           = [ordered]@{ commercial = 'https://outlook.office365.com'; gcc = 'https://outlook.office365.com'; gcchigh = 'https://outlook.office365.us'; dod = 'https://outlook-dod.office365.us' }
        securitysuite = [ordered]@{ commercial = 'https://ps.compliance.protection.outlook.com'; gcc = 'https://ps.compliance.protection.outlook.com'; gcchigh = 'https://ps.compliance.protection.office365.us'; dod = 'https://ps.compliance.protection.office365.us' }
    }

    # Build a case for each API in every environment its product supports
    $combinedRestCases = [System.Collections.ArrayList]::new()
    foreach ($testCase in $restApiCases) {
        foreach ($env in $serviceBaseUrls[$testCase.Product].GetEnumerator()) {
            $null = $combinedRestCases.Add(@{
                EnvName        = $env.Key
                Function       = $testCase.Function
                Product        = $testCase.Product
                ExpectedMethod = $testCase.Method
                ExpectedUri    = "$($env.Value)$($testCase.Path)"
                TenantId       = $TenantId
            })
        }
    }

    $coverageCase = @{ Covered = @($combinedRestCases | ForEach-Object { "$($_.Function)|$($_.EnvName)" }) }

    Describe -Tag 'Utility' -Name 'Invoke-ScubaRestMethod API endpoints' {
        BeforeAll {
            $HelperPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Providers/ProviderHelpers'
            foreach ($Helper in 'SPORestHelper', 'PowerPlatformRestHelper', 'TeamsRestHelper', 'PowerBIRestHelper', 'EXORestHelper') {
                Import-Module (Join-Path -Path $HelperPath -ChildPath "$Helper.psm1") -Force
            }
            Mock -ModuleName Utility Invoke-RestMethod { return [pscustomobject]@{ value = @(); d = [pscustomobject]@{} } }
        }

        # Tests that each REST helper sends the expected URL and method. The base URL and path come from ScubaGearApiCatalog.json.
        It 'calls <ExpectedUri> with <ExpectedMethod> for <Function> in <EnvName>' -TestCases $combinedRestCases {
            param($EnvName, $Function, $Product, $ExpectedMethod, $ExpectedUri, $TenantId)

            # ExpectedMethod and ExpectedUri are only read inside the -ParameterFilter below, which PSScriptAnalyzer cannot see.
            $null = $ExpectedMethod, $ExpectedUri

            $BaseUrl = Get-ScubaGearServiceEndpoint -Product $Product -Environment $EnvName -Domain 'contoso'
            $Params = @{ AccessToken = 'tok' }
            switch ($Function) {
                'Get-SPOTenantRest' { $Params.AdminUrl = $BaseUrl }
                'Get-PowerPlatformTenantIsolationRest' { $Params.BaseUrl = $BaseUrl; $Params.TenantId = $TenantId }
                'Invoke-EXORestMethod' { $Params.ApiEndpoint = "$BaseUrl/adminapi/beta/$TenantId/InvokeCommand"; $Params.CmdletName = 'Get-OrganizationConfig' }
                default { $Params.BaseUrl = $BaseUrl }
            }

            $null = & $Function @Params

            Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -eq $ExpectedUri -and $Method -eq $ExpectedMethod -and $Headers['Authorization'] -eq 'Bearer tok'
            }
        }

        It 'covers every REST helper in the catalog for each supported environment' -TestCases @($coverageCase) {
            param($Covered)

            $Missing = Get-ScubaGearCatalog | Where-Object { $_.entryType -eq 'restHelper' } | ForEach-Object {
                $Entry = $_
                $Entry.supportedEnv | ForEach-Object { "$($Entry.functionName)|$_" }
            } | Where-Object { $_ -notin $Covered }

            $Missing | Should -BeNullOrEmpty -Because 'each REST helper and environment in the catalog should have an expected URL above'
        }
    }
}

AfterAll {
    Remove-Module SPORestHelper, PowerPlatformRestHelper, TeamsRestHelper, PowerBIRestHelper, EXORestHelper -Force -ErrorAction SilentlyContinue
}
