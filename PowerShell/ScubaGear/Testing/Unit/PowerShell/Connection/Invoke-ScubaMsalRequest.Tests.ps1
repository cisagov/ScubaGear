$ModulePath = Join-Path $PSScriptRoot '..\..\..\..\Modules\Connection\ConnectHelpers.psm1'
Import-Module $ModulePath -Force

InModuleScope ConnectHelpers {
    Describe 'Invoke-ScubaMsalRequest' {
        BeforeAll {
            function New-FakeRequest {
                param([scriptblock]$Execute)
                $Request = [pscustomobject]@{}
                $Request | Add-Member ScriptMethod ExecuteAsync $Execute
                return $Request
            }
        }

        It 'returns the result of a completed request' {
            $Request = New-FakeRequest { [System.Threading.Tasks.Task]::FromResult('token') }
            Invoke-ScubaMsalRequest -Request $Request | Should -Be 'token'
        }

        It 'surfaces the original exception of a faulted request' {
            $Request = New-FakeRequest {
                $Faulted = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
                $Faulted.SetException([System.InvalidOperationException]::new('boom'))
                $Faulted.Task
            }
            { Invoke-ScubaMsalRequest -Request $Request } | Should -Throw '*boom*'
        }

        It 'cancels a request that outlives the timeout and reports the timeout' {
            $Request = New-FakeRequest { param($Token) [System.Threading.Tasks.Task]::Delay(-1, $Token) }
            { Invoke-ScubaMsalRequest -Request $Request -TimeoutSeconds 1 } |
                Should -Throw '*did not complete within 1 seconds*'
        }

        It 'cancels the underlying request when the caller is stopped, as Ctrl-C does' {
            # The function is copied into a separate runspace instead of importing the module there.
            # Loading ConnectHelpers (which uses ScubaConfig classes) a second time in one process
            # corrupts the shared class state for the tests that run after this one.
            $FunctionBody = (Get-Command Invoke-ScubaMsalRequest).ScriptBlock.ToString()
            $State = [hashtable]::Synchronized(@{ Token = $null; Started = $false })
            $Runspace = [runspacefactory]::CreateRunspace()
            $Runspace.Open()
            $Runspace.SessionStateProxy.SetVariable('State', $State)
            $Runspace.SessionStateProxy.SetVariable('FunctionBody', $FunctionBody)
            $Shell = [powershell]::Create()
            $Shell.Runspace = $Runspace
            try {
                [void]$Shell.AddScript(@'
Set-Item -Path function:Invoke-ScubaMsalRequest -Value ([scriptblock]::Create($FunctionBody))
$Request = [pscustomobject]@{}
$Request | Add-Member ScriptMethod ExecuteAsync {
    param($Token)
    $State.Token = $Token
    $State.Started = $true
    [System.Threading.Tasks.Task]::Delay(-1, $Token)
}
Invoke-ScubaMsalRequest -Request $Request
'@)
                $Pending = $Shell.BeginInvoke()

                $Deadline = [DateTime]::UtcNow.AddSeconds(30)
                while (-not $State.Started -and [DateTime]::UtcNow -lt $Deadline) { Start-Sleep -Milliseconds 100 }
                $State.Started | Should -BeTrue

                $Shell.BeginStop($null, $null) | Out-Null
                $Pending.AsyncWaitHandle.WaitOne(10000) | Should -BeTrue
                $State.Token.IsCancellationRequested | Should -BeTrue
            }
            finally {
                $Shell.Dispose()
                $Runspace.Dispose()
            }
        }
    }

    Describe 'Test-ScubaMsalRetryableError' {
        BeforeAll {
            function New-MsalFailure {
                param([string]$Code, [int]$StatusCode = 0, [string]$Message = 'failure', [string]$Type = 'Microsoft.Identity.Client.MsalException')
                $Failure = [System.InvalidOperationException]::new($Message)
                $Failure.PSTypeNames.Insert(0, $Type)
                $Failure | Add-Member NoteProperty ErrorCode $Code
                if ($StatusCode) {
                    $Failure | Add-Member NoteProperty StatusCode $StatusCode
                }
                return $Failure
            }
        }

        It 'retries <Scenario>' -TestCases @(
            @{ Scenario = 'a timed-out service call'; Failure = { New-MsalFailure -Code 'request_timeout' } },
            @{ Scenario = 'a temporarily unavailable service'; Failure = { New-MsalFailure -Code 'temporarily_unavailable' } },
            @{ Scenario = 'an HTTP 503 from the service'; Failure = { New-MsalFailure -Code 'x' -StatusCode 503 } },
            @{ Scenario = 'an HTTP 429 from the service'; Failure = { New-MsalFailure -Code 'x' -StatusCode 429 } },
            @{ Scenario = 'a connection failure'; Failure = { [System.Net.WebException]::new('down', [System.Net.WebExceptionStatus]::ConnectFailure) } },
            @{ Scenario = 'a socket error'; Failure = { [System.Net.Sockets.SocketException]::new() } }
        ) {
            Test-ScubaMsalRetryableError -Exception (& $Failure) | Should -BeTrue
        }

        It 'retries a transient failure wrapped by PowerShell' {
            $Wrapped = [System.Management.Automation.MethodInvocationException]::new(
                'wrapper', (New-MsalFailure -Code 'service_not_available'))
            Test-ScubaMsalRetryableError -Exception $Wrapped | Should -BeTrue
        }

        It 'does not retry <Scenario>' -TestCases @(
            @{ Scenario = 'a cancelled sign-in'; Failure = { New-MsalFailure -Code 'authentication_canceled' } },
            @{ Scenario = 'an operation cancelled by timeout or Ctrl-C'; Failure = { [System.OperationCanceledException]::new('cancelled') } },
            @{ Scenario = 'an unusable interactive prompt'; Failure = { New-MsalFailure -Code 'invalid_grant' -Type 'Microsoft.Identity.Client.MsalUiRequiredException' } },
            @{ Scenario = 'a consent failure'; Failure = { New-MsalFailure -Code 'invalid_grant' -StatusCode 400 -Message 'AADSTS65001' } },
            @{ Scenario = 'bad credentials'; Failure = { New-MsalFailure -Code 'invalid_grant' -StatusCode 400 -Message 'AADSTS50126' } },
            @{ Scenario = 'a programming error'; Failure = { [System.InvalidOperationException]::new('bug') } },
            @{ Scenario = 'a stopped pipeline'; Failure = { [System.Management.Automation.PipelineStoppedException]::new() } }
        ) {
            Test-ScubaMsalRetryableError -Exception (& $Failure) | Should -BeFalse
        }

        It 'does not retry a cancellation even when it wraps a transient error' {
            $Cancelled = [System.OperationCanceledException]::new('cancelled', [System.Net.WebException]::new('down', [System.Net.WebExceptionStatus]::ConnectFailure))
            Test-ScubaMsalRetryableError -Exception $Cancelled | Should -BeFalse
        }
    }
}
