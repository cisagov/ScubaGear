Describe -Tag 'EXOProvider' -Name 'Invoke-EXORestMethod' {
    BeforeAll {
        # Imported here rather than at the top of the file. Other test files reload EXORestHelper through
        # CommandTracker during discovery, which drops a top-level import before this file's tests run.
        $HelperPath = '../../../../../Modules/Providers/ProviderHelpers/EXORestHelper.psm1'
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Function Invoke-EXORestMethod -Force

        # Same shapes Invoke-WebRequest throws: an HTTP error carries a .Response, a timeout does not.
        function New-HttpError {
            param(
                [int]$StatusCode,
                [hashtable]$Headers = @{}
            )
            $HttpError = [System.Exception]::new("The remote server returned an error: ($StatusCode).")
            $HttpError | Add-Member -NotePropertyName Response -NotePropertyValue ([pscustomobject]@{ StatusCode = $StatusCode; Headers = $Headers })
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
        $script:SuccessResponse = [pscustomobject]@{ Content = '{"value":[{"Name":"Built-In Protection Policy"}]}' }
    }

    BeforeEach {
        $script:Calls = 0
        $script:Sleeps = @()
        Mock -ModuleName EXORestHelper Write-Warning {}
        Mock -ModuleName EXORestHelper Start-Sleep {
            param([double]$Seconds)
            $script:Sleeps += $Seconds
        }
    }

    It 'Returns the value from a successful call without retrying' {
        Mock -ModuleName EXORestHelper Invoke-WebRequest { $script:Calls++; $script:SuccessResponse }

        (Invoke-EXORestMethod @script:InvokeParams).Name | Should -Be 'Built-In Protection Policy'
        $script:Calls | Should -Be 1
        $script:Sleeps.Count | Should -Be 0
    }

    Context 'Retryable failures' {
        It 'Retries after a <Name> and returns the result from the second try' -ForEach @(
            @{ Name = 'timeout'; ErrorFactory = { New-TimeoutError } }
            @{ Name = 'dropped connection'; ErrorFactory = { [System.IO.IOException]::new('Unable to read data from the transport connection') } }
            @{ Name = '429'; ErrorFactory = { New-HttpError -StatusCode 429 } }
            @{ Name = '500'; ErrorFactory = { New-HttpError -StatusCode 500 } }
            @{ Name = '502'; ErrorFactory = { New-HttpError -StatusCode 502 } }
            @{ Name = '503'; ErrorFactory = { New-HttpError -StatusCode 503 } }
            @{ Name = '504'; ErrorFactory = { New-HttpError -StatusCode 504 } }
        ) {
            $script:FirstError = & $ErrorFactory
            Mock -ModuleName EXORestHelper Invoke-WebRequest {
                $script:Calls++
                if ($script:Calls -eq 1) { throw $script:FirstError }
                $script:SuccessResponse
            }

            (Invoke-EXORestMethod @script:InvokeParams).Name | Should -Be 'Built-In Protection Policy'
            $script:Calls | Should -Be 2
            $script:Sleeps | Should -Be @(5)
        }

        It 'Says it is retrying a timeout so it shows up in the logs' {
            Mock -ModuleName EXORestHelper Invoke-WebRequest {
                $script:Calls++
                if ($script:Calls -eq 1) { throw (New-TimeoutError) }
                $script:SuccessResponse
            }

            Invoke-EXORestMethod @script:InvokeParams | Out-Null

            Should -Invoke -ModuleName EXORestHelper Write-Warning -Times 1 -Exactly -ParameterFilter {
                $Message -match "Get-SafeAttachmentPolicy' did not get a response" -and $Message -match 'attempt 1/3'
            }
        }

        It 'Backs off 5s then 10s and throws the original error after 3 timeouts' {
            Mock -ModuleName EXORestHelper Invoke-WebRequest { $script:Calls++; throw (New-TimeoutError) }

            { Invoke-EXORestMethod @script:InvokeParams } |
                Should -Throw "Exchange Online API call 'Get-SafeAttachmentPolicy' failed: The operation has timed out"
            $script:Calls | Should -Be 3
            $script:Sleeps | Should -Be @(5, 10)
        }

        It 'Waits for the Retry-After value the service sends' {
            Mock -ModuleName EXORestHelper Invoke-WebRequest {
                $script:Calls++
                if ($script:Calls -eq 1) { throw (New-HttpError -StatusCode 429 -Headers @{ 'Retry-After' = '17' }) }
                $script:SuccessResponse
            }

            Invoke-EXORestMethod @script:InvokeParams | Out-Null

            $script:Sleeps | Should -Be @(17)
        }
    }

    Context 'Failures that should not be retried' {
        It 'Throws right away on a <StatusCode>' -ForEach @(
            @{ StatusCode = 400 }
            @{ StatusCode = 401 }
            @{ StatusCode = 403 }
            @{ StatusCode = 404 }
        ) {
            Mock -ModuleName EXORestHelper Invoke-WebRequest { $script:Calls++; throw (New-HttpError -StatusCode $StatusCode) }

            { Invoke-EXORestMethod @script:InvokeParams } | Should -Throw "*($StatusCode)*"
            $script:Calls | Should -Be 1
            $script:Sleeps.Count | Should -Be 0
        }

        It 'Throws right away when the response is not valid JSON' {
            Mock -ModuleName EXORestHelper Invoke-WebRequest { $script:Calls++; [pscustomobject]@{ Content = '<html>not json</html>' } }

            { Invoke-EXORestMethod @script:InvokeParams } | Should -Throw "Exchange Online API call 'Get-SafeAttachmentPolicy' failed:*"
            $script:Calls | Should -Be 1
        }
    }
}

AfterAll {
    Remove-Module EXORestHelper -Force -ErrorAction SilentlyContinue
}
