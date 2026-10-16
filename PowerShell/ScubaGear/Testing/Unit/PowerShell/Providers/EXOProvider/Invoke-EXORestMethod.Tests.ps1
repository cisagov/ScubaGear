Describe -Tag 'EXOProvider' -Name 'Invoke-EXORestMethod' {
    BeforeAll {
        # Imported here rather than at the top of the file. Other test files reload EXORestHelper through
        # CommandTracker during discovery, which drops a top-level import before this file's tests run.
        $HelperPath = '../../../../../Modules/Providers/ProviderHelpers/EXORestHelper.psm1'
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Function Invoke-EXORestMethod -Force

        # An HTTP error carries a .Response, but a timeout does not.
        function New-HttpError {
            param(
                [int]$StatusCode,
                [hashtable]$Headers = @{}
            )
            $HttpError = [System.Exception]::new("The remote server returned an error: ($StatusCode).")
            $Response = [pscustomobject]@{ StatusCode = $StatusCode; Headers = $Headers }
            $Response | Add-Member -MemberType ScriptMethod -Name GetResponseStream -Value { return $null }
            $HttpError | Add-Member -NotePropertyName Response -NotePropertyValue $Response
            $HttpError
        }

        function New-TimeoutError {
            [System.Net.WebException]::new('The operation has timed out', [System.Net.WebExceptionStatus]::Timeout)
        }

        $script:InvokeParams = @{
            CmdletName  = 'Get-SafeAttachmentPolicy'
            ApiEndpoint = 'https://outlook.office365.com/adminapi/beta/tenant-id/InvokeCommand'
            AccessToken = 'exo-test-token'
        }
        $script:SuccessResponse = [pscustomobject]@{ value = @([pscustomobject]@{ Name = 'Built-In Protection Policy' }) }
    }

    BeforeEach {
        $script:Calls = 0
        $script:Sleeps = @()
        Mock -ModuleName Utility Write-Warning {}
        Mock -ModuleName Utility Write-Information {}
        Mock -ModuleName Utility Start-Sleep {
            param([double]$Seconds)
            $script:Sleeps += $Seconds
        }
    }

    It 'Returns the value from a successful call without retrying' {
        Mock -ModuleName Utility Invoke-RestMethod { $script:Calls++; $script:SuccessResponse }

        (Invoke-EXORestMethod @script:InvokeParams).Name | Should -Be 'Built-In Protection Policy'
        $script:Calls | Should -Be 1
        $script:Sleeps.Count | Should -Be 0
        Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $TimeoutSec -eq 30 -and $Method -eq 'POST'
        }
    }

    Context 'Retryable failures' {
        It 'Retries after a <Name> and returns the result from the second try' -ForEach @(
            @{ Name = 'timeout'; ErrorFactory = { New-TimeoutError } }
            @{ Name = 'dropped connection'; ErrorFactory = { [System.IO.IOException]::new('Unable to read data from the transport connection') } }
            @{ Name = 'wrapped socket error'; ErrorFactory = { [System.Exception]::new('Send failed', [System.Net.Sockets.SocketException]::new(10054)) } }
            @{ Name = 'TimeoutException'; ErrorFactory = { [System.TimeoutException]::new('Request expired') } }
            @{ Name = 'PS 7 timeout'; ErrorFactory = { [System.Threading.Tasks.TaskCanceledException]::new('Request canceled') } }
            @{ Name = '429'; ErrorFactory = { New-HttpError -StatusCode 429 } }
            @{ Name = '500'; ErrorFactory = { New-HttpError -StatusCode 500 } }
            @{ Name = '502'; ErrorFactory = { New-HttpError -StatusCode 502 } }
            @{ Name = '503'; ErrorFactory = { New-HttpError -StatusCode 503 } }
            @{ Name = '504'; ErrorFactory = { New-HttpError -StatusCode 504 } }
        ) {
            $script:FirstError = & $ErrorFactory
            Mock -ModuleName Utility Invoke-RestMethod {
                $script:Calls++
                if ($script:Calls -eq 1) { throw $script:FirstError }
                $script:SuccessResponse
            }

            (Invoke-EXORestMethod @script:InvokeParams).Name | Should -Be 'Built-In Protection Policy'
            $script:Calls | Should -Be 2
            $script:Sleeps | Should -Be @(5)
        }

        It 'Says it is retrying a timeout so it shows up in the logs' {
            Mock -ModuleName Utility Invoke-RestMethod {
                $script:Calls++
                if ($script:Calls -eq 1) { throw (New-TimeoutError) }
                $script:SuccessResponse
            }

            Invoke-EXORestMethod @script:InvokeParams | Out-Null

            Should -Invoke -ModuleName Utility Write-Warning -Times 1 -Exactly -ParameterFilter {
                $Message -match 'transient connection error' -and $Message -match 'attempt 1 of 2'
            }
        }

        It 'Backs off 5s then 10s and throws the original error after 3 timeouts' {
            Mock -ModuleName Utility Invoke-RestMethod { $script:Calls++; throw (New-TimeoutError) }

            { Invoke-EXORestMethod @script:InvokeParams } |
                Should -Throw "Exchange Online API call 'Get-SafeAttachmentPolicy' failed: The operation has timed out"
            $script:Calls | Should -Be 3
            $script:Sleeps | Should -Be @(5, 10)
        }

        It 'Waits for the Retry-After value sent with HTTP <StatusCode>' -ForEach @(
            @{ StatusCode = 429 }
            @{ StatusCode = 500 }
            @{ StatusCode = 502 }
            @{ StatusCode = 503 }
            @{ StatusCode = 504 }
        ) {
            Mock -ModuleName Utility Invoke-RestMethod {
                $script:Calls++
                if ($script:Calls -eq 1) { throw (New-HttpError -StatusCode $StatusCode -Headers @{ 'Retry-After' = '17' }) }
                $script:SuccessResponse
            }

            Invoke-EXORestMethod @script:InvokeParams | Out-Null

            $script:Sleeps | Should -Be @(17)
        }

        It 'Backs off and stops after three attempts on persistent HTTP <StatusCode>' -ForEach @(
            @{ StatusCode = 429 }
            @{ StatusCode = 500 }
            @{ StatusCode = 502 }
            @{ StatusCode = 503 }
            @{ StatusCode = 504 }
        ) {
            Mock -ModuleName Utility Invoke-RestMethod {
                $script:Calls++
                throw (New-HttpError -StatusCode $StatusCode)
            }

            { Invoke-EXORestMethod @script:InvokeParams } | Should -Throw "*($StatusCode)*"
            $script:Calls | Should -Be 3
            $script:Sleeps | Should -Be @(5, 10)
        }
    }

    Context 'Failures that should not be retried' {
        It 'Throws right away on a <StatusCode>' -ForEach @(
            @{ StatusCode = 400 }
            @{ StatusCode = 401 }
            @{ StatusCode = 403 }
            @{ StatusCode = 404 }
        ) {
            Mock -ModuleName Utility Invoke-RestMethod { $script:Calls++; throw (New-HttpError -StatusCode $StatusCode) }

            { Invoke-EXORestMethod @script:InvokeParams } | Should -Throw "*($StatusCode)*"
            $script:Calls | Should -Be 1
            $script:Sleeps.Count | Should -Be 0
        }

        It 'Throws right away when the response is not valid JSON' {
            Mock -ModuleName Utility Invoke-RestMethod { $script:Calls++; throw [System.ArgumentException]::new('Invalid JSON primitive') }

            { Invoke-EXORestMethod @script:InvokeParams } | Should -Throw "Exchange Online API call 'Get-SafeAttachmentPolicy' failed:*"
            $script:Calls | Should -Be 1
        }
    }
}

$HelperPath = '../../../../../Modules/Providers/ProviderHelpers/EXORestHelper.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Function 'Invoke-EXORestMethod', 'Get-ComplianceApiEndpoint', 'Get-ExchangeOnlineApiEndpoint' -Force

InModuleScope EXORestHelper {
    Describe -Tag 'EXORestHelper' -Name 'Invoke-EXORestMethod' {
        Context 'Delegation to Invoke-ScubaRestMethod' {
            It 'Passes the expected parameters and returns the value property of the response' {
                Mock -ModuleName EXORestHelper Invoke-ScubaRestMethod {
                    return [pscustomobject]@{ value = @(@{ Name = 'Test Domain' }) }
                }
                $Result = Invoke-EXORestMethod -CmdletName 'Get-RemoteDomain' -ApiEndpoint 'https://outlook.office365.com/adminapi/beta/tenant123/InvokeCommand' -AccessToken 'tok'
                @($Result)[0].Name | Should -Be 'Test Domain'
                Should -Invoke -ModuleName EXORestHelper Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                    $BaseUrl -eq 'https://outlook.office365.com/adminapi/beta/tenant123/InvokeCommand' -and
                    $Endpoint -eq '' -and
                    $AccessToken -eq 'tok' -and
                    $Method -eq 'POST' -and
                    $TimeoutSec -eq 30 -and
                    $MaxRetries -eq 2 -and
                    $RetryDelaySeconds -eq 5 -and
                    $AdditionalHeaders['Prefer'] -eq 'odata.maxpagesize=1000' -and
                    $AdditionalHeaders['X-ResponseFormat'] -eq 'json' -and
                    $AdditionalHeaders['User-Agent'] -eq 'ScubaGear' -and
                    ($Body | ConvertFrom-Json).CmdletInput.CmdletName -eq 'Get-RemoteDomain'
                }
            }

            It 'Passes the Parameters hashtable through in the request body' {
                Mock -ModuleName EXORestHelper Invoke-ScubaRestMethod {
                    return [pscustomobject]@{ value = @() }
                }
                $null = Invoke-EXORestMethod -CmdletName 'Get-Something' -ApiEndpoint 'https://outlook.office365.com/adminapi/beta/tenant123/InvokeCommand' `
                    -AccessToken 'tok' -Parameters @{ Identity = 'test' }
                Should -Invoke -ModuleName EXORestHelper Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                    ($Body | ConvertFrom-Json).CmdletInput.Parameters.Identity -eq 'test'
                }
            }

            It 'Wraps failures with a descriptive error message' {
                Mock -ModuleName EXORestHelper Invoke-ScubaRestMethod { throw "Simulated failure" }
                { Invoke-EXORestMethod -CmdletName 'Get-RemoteDomain' -ApiEndpoint 'https://outlook.office365.com/adminapi/beta/tenant123/InvokeCommand' -AccessToken 'tok' } |
                    Should -Throw "*Exchange Online API call 'Get-RemoteDomain' failed*"
            }
        }
    }

    Describe -Tag 'EXORestHelper', 'Network' -Name 'Resolve-ScubaFrontDoorEndpoint (via Get-ComplianceApiEndpoint / Get-ExchangeOnlineApiEndpoint)' {
        Context 'Front-door does not redirect (falls back to default endpoint)' {
            It 'Get-ExchangeOnlineApiEndpoint falls back to the default InvokeCommand endpoint' {
                Mock -ModuleName EXORestHelper Get-ScubaGearServiceEndpoint { return 'https://httpbin.org' }
                $Endpoint = Get-ExchangeOnlineApiEndpoint -TenantId 'tenant123' -TenantDomain 'contoso.onmicrosoft.com' `
                    -M365Environment 'commercial' -AccessToken 'tok'
                $Endpoint | Should -Be 'https://httpbin.org/adminapi/beta/tenant123/InvokeCommand'
            }

            It 'Get-ComplianceApiEndpoint falls back to the default InvokeCommand endpoint without throwing' {
                Mock -ModuleName EXORestHelper Get-ScubaGearServiceEndpoint { return 'https://httpbin.org' }
                $Endpoint = Get-ComplianceApiEndpoint -TenantId 'tenant123' -TenantDomain 'contoso.onmicrosoft.com' `
                    -M365Environment 'commercial' -AccessToken 'tok'
                $Endpoint | Should -Be 'https://httpbin.org/adminapi/beta/tenant123/InvokeCommand'
            }
        }

        Context 'Discovery call fails outright' {
            It 'Get-ExchangeOnlineApiEndpoint throws' {
                Mock -ModuleName EXORestHelper Get-ScubaGearServiceEndpoint { return 'https://this-host-does-not-exist-scubagear-test.invalid' }
                { Get-ExchangeOnlineApiEndpoint -TenantId 'tenant123' -TenantDomain 'contoso.onmicrosoft.com' `
                        -M365Environment 'commercial' -AccessToken 'tok' } | Should -Throw
            }

            It 'Get-ComplianceApiEndpoint does not throw and falls back to the default endpoint' {
                Mock -ModuleName EXORestHelper Get-ScubaGearServiceEndpoint { return 'https://this-host-does-not-exist-scubagear-test.invalid' }
                $Endpoint = Get-ComplianceApiEndpoint -TenantId 'tenant123' -TenantDomain 'contoso.onmicrosoft.com' `
                    -M365Environment 'commercial' -AccessToken 'tok' -WarningAction SilentlyContinue
                $Endpoint | Should -Be 'https://this-host-does-not-exist-scubagear-test.invalid/adminapi/beta/tenant123/InvokeCommand'
            }
        }
    }
}
