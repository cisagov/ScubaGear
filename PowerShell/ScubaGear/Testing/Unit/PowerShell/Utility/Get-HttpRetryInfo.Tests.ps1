$UtilityPath = '../../../../Modules/Utility/Utility.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $UtilityPath) -Function 'Get-HttpRetryInfo' -Force

InModuleScope Utility {
    Describe -Tag 'Utility' -Name 'Get-HttpRetryInfo' {
        BeforeAll {
            # Not loaded by default on PS 5.1 Desktop; must be loaded explicitly before the types can be constructed.
            Add-Type -AssemblyName System.Net.Http

            # Attaches a response object the same way Invoke-WebRequest does, so the helper reads it from .Response.
            function New-ErrorWithResponse {
                param($Response)
                $ErrorWithResponse = [System.Exception]::new('HTTP request failed')
                $ErrorWithResponse | Add-Member -NotePropertyName Response -NotePropertyValue $Response
                $ErrorWithResponse
            }
        }

        Context 'Response from PS 7+ (HttpResponseMessage)' {
            It 'Returns the status code and the typed Retry-After delay' {
                # TooManyRequests isn't a named HttpStatusCode value on .NET Framework (PS 5.1), so build the raw value
                # the same way .NET does for a real 429 response.
                $Response = [System.Net.Http.HttpResponseMessage]::new([Enum]::ToObject([System.Net.HttpStatusCode], 429))
                $Response.Headers.RetryAfter = [System.Net.Http.Headers.RetryConditionHeaderValue]::new([TimeSpan]::FromSeconds(9))

                $Info = Get-HttpRetryInfo -Exception (New-ErrorWithResponse -Response $Response)

                $Info.StatusCode | Should -Be 429
                $Info.RetryAfterSeconds | Should -Be 9
                $Info.IsNetworkError | Should -BeFalse
            }

            It 'Returns 0 for Retry-After when the header is missing' {
                $Response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::ServiceUnavailable)

                $Info = Get-HttpRetryInfo -Exception (New-ErrorWithResponse -Response $Response)

                $Info.StatusCode | Should -Be 503
                $Info.RetryAfterSeconds | Should -Be 0
            }
        }

        Context 'Response from PS 5.1 (HttpWebResponse)' {
            # HttpWebResponse has no public constructor, so use a stand-in with the real WebHeaderCollection type.
            It 'Reads Retry-After through the WebHeaderCollection indexer' {
                $Headers = [System.Net.WebHeaderCollection]::new()
                $Headers.Add('Retry-After', '7')
                $Response = [pscustomobject]@{ StatusCode = [Enum]::ToObject([System.Net.HttpStatusCode], 429); Headers = $Headers }

                $Info = Get-HttpRetryInfo -Exception (New-ErrorWithResponse -Response $Response)

                $Info.StatusCode | Should -Be 429
                $Info.RetryAfterSeconds | Should -Be 7
                $Info.IsNetworkError | Should -BeFalse
            }

            It 'Converts an HTTP-date Retry-After into seconds from now' {
                $Headers = [System.Net.WebHeaderCollection]::new()
                $Headers.Add('Retry-After', [DateTimeOffset]::UtcNow.AddSeconds(30).ToString('r'))
                $Response = [pscustomobject]@{ StatusCode = 503; Headers = $Headers }

                $Info = Get-HttpRetryInfo -Exception (New-ErrorWithResponse -Response $Response)

                $Info.RetryAfterSeconds | Should -BeGreaterThan 0
                $Info.RetryAfterSeconds | Should -BeLessOrEqual 31
            }

            It 'Never returns a negative delay for an HTTP-date in the past' {
                $Headers = [System.Net.WebHeaderCollection]::new()
                $Headers.Add('Retry-After', [DateTimeOffset]::UtcNow.AddMinutes(-5).ToString('r'))
                $Response = [pscustomobject]@{ StatusCode = 503; Headers = $Headers }

                (Get-HttpRetryInfo -Exception (New-ErrorWithResponse -Response $Response)).RetryAfterSeconds | Should -Be 0
            }

            It 'Ignores a Retry-After value it cannot parse' {
                $Headers = [System.Net.WebHeaderCollection]::new()
                $Headers.Add('Retry-After', 'soon')
                $Response = [pscustomobject]@{ StatusCode = 429; Headers = $Headers }

                (Get-HttpRetryInfo -Exception (New-ErrorWithResponse -Response $Response)).RetryAfterSeconds | Should -Be 0
            }
        }

        Context 'No response (timeouts and network failures)' {
            It 'Treats a <Name> as a network error' -ForEach @(
                @{ Name = 'PS 5.1 timeout (WebException)'; Exception = [System.Net.WebException]::new('The operation has timed out', [System.Net.WebExceptionStatus]::Timeout) }
                @{ Name = 'PS 7 timeout (TaskCanceledException)'; Exception = [System.Threading.Tasks.TaskCanceledException]::new('The request was canceled due to the configured HttpClient.Timeout of 30 seconds elapsing.') }
                @{ Name = 'TimeoutException'; Exception = [System.TimeoutException]::new('timed out') }
                @{ Name = 'socket error wrapped in another exception'; Exception = [System.Exception]::new('Send failed', [System.Net.Sockets.SocketException]::new(10054)) }
                @{ Name = 'dropped connection (IOException)'; Exception = [System.IO.IOException]::new('Unable to read data from the transport connection') }
            ) {
                $Info = Get-HttpRetryInfo -Exception $Exception

                $Info.IsNetworkError | Should -BeTrue
                $Info.StatusCode | Should -Be 0
                $Info.RetryAfterSeconds | Should -Be 0
            }

            It 'Treats a PS 7 HttpRequestException (DNS or connection failure) as a network error' {
                $RequestError = [System.Net.Http.HttpRequestException]::new('No such host is known.')

                (Get-HttpRetryInfo -Exception $RequestError).IsNetworkError | Should -BeTrue
            }

            It 'Does not treat an ordinary error as a network error' {
                $Info = Get-HttpRetryInfo -Exception ([System.Management.Automation.RuntimeException]::new('Invalid JSON primitive'))

                $Info.IsNetworkError | Should -BeFalse
                $Info.StatusCode | Should -Be 0
            }
        }
    }
}

AfterAll {
    Remove-Module Utility -Force -ErrorAction SilentlyContinue
}
