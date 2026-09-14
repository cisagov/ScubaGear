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
        }
    }
}
