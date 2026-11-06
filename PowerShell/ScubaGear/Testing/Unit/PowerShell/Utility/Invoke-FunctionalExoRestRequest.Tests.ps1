Describe 'Invoke-FunctionalExoRestRequest' {
    BeforeAll {
        $FunctionalTestUtilsPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../../../Testing/Functional/Products/FunctionalTestUtils.ps1'
        . $FunctionalTestUtilsPath

        $script:EXOApiEndpoint = 'https://outlook.office365.com/adminapi/beta/tenant-id/InvokeCommand'
        $script:EXOAccessToken = 'exo-test-token'
    }

    BeforeEach {
        $script:RestRequestCalls = @()
        $script:SleepCalls = @()

        Mock Write-Information { }
        Mock Start-Sleep {
            param([int] $Seconds)
            $script:SleepCalls += $Seconds
        }
    }

    Context 'Successful responses' {
        It 'returns the value property from a successful response' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                return @{
                    value = @(
                        @{ Name = 'Default'; AutoForwardEnabled = $true }
                    )
                }
            }

            $result = Invoke-FunctionalExoRestRequest `
                -CmdletName 'Get-RemoteDomain' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken

            $result | Should -Not -BeNullOrEmpty
            # PowerShell unwraps single-element arrays; access .Name directly
            ($result | Select-Object -First 1).Name | Should -Be 'Default'
            $script:RestRequestCalls.Count | Should -Be 1
        }

        It 'returns null when response is null' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                return $null
            }

            $result = Invoke-FunctionalExoRestRequest `
                -CmdletName 'Get-TransportConfig' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken

            $result | Should -BeNullOrEmpty
            $script:RestRequestCalls.Count | Should -Be 1
        }
    }

    Context 'HTTP error retry logic' {
        It 'retries on HTTP 500 then succeeds on second attempt' {
            $script:Attempt = 0
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                $script:Attempt++
                if ($script:Attempt -eq 1) {
                    throw "Request to endpoint failed with HTTP status code 500. Internal Server Error"
                }
                return @{ value = @(@{ SmtpClientAuthenticationDisabled = $true }) }
            }

            $result = Invoke-FunctionalExoRestRequest `
                -CmdletName 'Get-TransportConfig' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -BaseDelaySeconds 0

            $result | Should -Not -BeNullOrEmpty
            $script:RestRequestCalls.Count | Should -Be 2
        }

        It 'retries on HTTP 503 and exhausts retries then throws' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                throw "Request to endpoint failed with HTTP status code 503. Service Unavailable"
            }

            { Invoke-FunctionalExoRestRequest `
                -CmdletName 'Set-TransportConfig' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -Parameters @{ SmtpClientAuthenticationDisabled = $true } `
                -MaxRetries 3 `
                -BaseDelaySeconds 0 } | Should -Throw '*503*'

            $script:RestRequestCalls.Count | Should -Be 3
        }

        It 'does not retry on HTTP 403 (non-transient)' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                throw "Request to endpoint failed with HTTP status code 403. Forbidden"
            }

            { Invoke-FunctionalExoRestRequest `
                -CmdletName 'Set-OrganizationConfig' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -Parameters @{ AuditDisabled = $false } `
                -BaseDelaySeconds 0 } | Should -Throw '*403*'

            $script:RestRequestCalls.Count | Should -Be 1
        }
    }

    Context '404 tolerance for Get-* and Remove-* cmdlets' {
        It 'returns null on 404 for Get-* cmdlets' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                throw "Request to endpoint failed with HTTP status code 404. Not Found"
            }

            $result = Invoke-FunctionalExoRestRequest `
                -CmdletName 'Get-TransportRule' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -BaseDelaySeconds 0

            $result | Should -BeNullOrEmpty
            $script:RestRequestCalls.Count | Should -Be 1
        }

        It 'returns null on 404 for Remove-* cmdlets (idempotent deletion)' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                throw "Request to endpoint failed with HTTP status code 404. Not Found"
            }

            $result = Invoke-FunctionalExoRestRequest `
                -CmdletName 'Remove-SharingPolicy' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -Parameters @{ Identity = 'NonExistentPolicy' } `
                -BaseDelaySeconds 0

            $result | Should -BeNullOrEmpty
            $script:RestRequestCalls.Count | Should -Be 1
        }

        It 'throws on 404 for Set-* cmdlets' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                throw "Request to endpoint failed with HTTP status code 404. Not Found"
            }

            { Invoke-FunctionalExoRestRequest `
                -CmdletName 'Set-RemoteDomain' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -Parameters @{ Identity = 'Default'; AutoForwardEnabled = $false } `
                -BaseDelaySeconds 0 } | Should -Throw '*404*'

            $script:RestRequestCalls.Count | Should -Be 1
        }
    }

    Context 'Embedded API errors in 200 OK responses' {
        It 'detects @odata.error in response body and throws' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                return @{
                    '@odata.error' = @{ code = 'AccessDenied'; message = 'Insufficient privileges' }
                    value = $null
                }
            }

            { Invoke-FunctionalExoRestRequest `
                -CmdletName 'Set-OrganizationConfig' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -Parameters @{ AuditDisabled = $false } `
                -BaseDelaySeconds 0 } | Should -Throw '*API-level error*'

            $script:RestRequestCalls.Count | Should -Be 1
        }

        It 'detects error property in response body and throws' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                return @{
                    error = @{ code = 'InvalidArgument'; message = 'Parameter is invalid' }
                    value = $null
                }
            }

            { Invoke-FunctionalExoRestRequest `
                -CmdletName 'New-TransportRule' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -Parameters @{ Name = 'Test' } `
                -BaseDelaySeconds 0 } | Should -Throw '*API-level error*'

            $script:RestRequestCalls.Count | Should -Be 1
        }

        It 'retries on transient embedded error then succeeds' {
            $script:Attempt = 0
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                $script:Attempt++
                if ($script:Attempt -eq 1) {
                    return @{
                        error = @{ code = 'ServiceBusy'; message = 'Service temporarily unavailable, try again later' }
                        value = $null
                    }
                }
                return @{ value = @(@{ AuditDisabled = $false }) }
            }

            $result = Invoke-FunctionalExoRestRequest `
                -CmdletName 'Get-OrganizationConfig' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -BaseDelaySeconds 0

            $result | Should -Not -BeNullOrEmpty
            $script:RestRequestCalls.Count | Should -Be 2
        }
    }

    Context 'Real web exception shapes rethrown by Invoke-FunctionalTestRestRequest' {
        BeforeAll {
            # Invoke-FunctionalTestRestRequest rethrows the original Invoke-WebRequest error, so the status code
            # lives on .Response and the message is the stock .NET text, not "status code N".
            function New-HttpError {
                param([int] $StatusCode, [hashtable] $Headers = @{})
                $HttpError = [System.Exception]::new("The remote server returned an error: ($StatusCode).")
                $HttpError | Add-Member -NotePropertyName Response -NotePropertyValue ([pscustomobject]@{ StatusCode = $StatusCode; Headers = $Headers })
                $HttpError
            }
        }

        It 'retries a timeout and succeeds on the second attempt' {
            $script:Attempt = 0
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                $script:Attempt++
                if ($script:Attempt -eq 1) {
                    throw [System.Net.WebException]::new('The operation has timed out', [System.Net.WebExceptionStatus]::Timeout)
                }
                return @{ value = @(@{ Name = 'Default' }) }
            }

            $result = Invoke-FunctionalExoRestRequest `
                -CmdletName 'Get-SafeAttachmentPolicy' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -BaseDelaySeconds 0

            $result | Should -Not -BeNullOrEmpty
            $script:RestRequestCalls.Count | Should -Be 2
        }

        It 'retries a PS 7 timeout and throws after exhausting retries' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                throw [System.Threading.Tasks.TaskCanceledException]::new('The request was canceled due to the configured HttpClient.Timeout of 100 seconds elapsing.')
            }

            { Invoke-FunctionalExoRestRequest `
                -CmdletName 'Set-AtpPolicyForO365' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -MaxRetries 3 `
                -BaseDelaySeconds 0 } | Should -Throw '*HttpClient.Timeout*'

            $script:RestRequestCalls.Count | Should -Be 3
        }

        It 'retries a real 503 response' {
            $script:Attempt = 0
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                $script:Attempt++
                if ($script:Attempt -eq 1) { throw (New-HttpError -StatusCode 503) }
                return @{ value = @(@{ Name = 'Default' }) }
            }

            $result = Invoke-FunctionalExoRestRequest `
                -CmdletName 'Get-HostedContentFilterPolicy' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -BaseDelaySeconds 0

            $result | Should -Not -BeNullOrEmpty
            $script:RestRequestCalls.Count | Should -Be 2
        }

        It 'waits for the Retry-After value on a real 429 response' {
            $script:Attempt = 0
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                $script:Attempt++
                if ($script:Attempt -eq 1) { throw (New-HttpError -StatusCode 429 -Headers @{ 'Retry-After' = '12' }) }
                return @{ value = @(@{ Name = 'Default' }) }
            }

            Invoke-FunctionalExoRestRequest `
                -CmdletName 'Get-AntiPhishPolicy' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -BaseDelaySeconds 0 | Out-Null

            $script:SleepCalls | Should -Be @(12)
        }

        It 'returns null on a real 404 response for Get-* cmdlets' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                throw (New-HttpError -StatusCode 404)
            }

            $result = Invoke-FunctionalExoRestRequest `
                -CmdletName 'Get-SafeLinksRule' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -BaseDelaySeconds 0

            $result | Should -BeNullOrEmpty
            $script:RestRequestCalls.Count | Should -Be 1
        }

        It 'does not retry a real 403 response' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                throw (New-HttpError -StatusCode 403)
            }

            { Invoke-FunctionalExoRestRequest `
                -CmdletName 'Set-OrganizationConfig' `
                -ApiEndpoint $script:EXOApiEndpoint `
                -AccessToken $script:EXOAccessToken `
                -BaseDelaySeconds 0 } | Should -Throw '*(403)*'

            $script:RestRequestCalls.Count | Should -Be 1
        }
    }

    Context 'Invoke-FunctionalExoCommand wrapper' {
        It 'passes CmdletName and Parameters to Invoke-FunctionalExoRestRequest' {
            Mock Invoke-FunctionalTestRestRequest {
                $script:RestRequestCalls += 1
                # Verify the body contains the expected cmdlet name
                $ParsedBody = $Body | ConvertFrom-Json
                $ParsedBody.CmdletInput.CmdletName | Should -Be 'Get-RemoteDomain'
                return @{ value = @(@{ Name = 'Default' }) }
            }

            $result = Invoke-FunctionalExoCommand -CmdletName 'Get-RemoteDomain'

            $result | Should -Not -BeNullOrEmpty
            $script:RestRequestCalls.Count | Should -Be 1
        }
    }
}
