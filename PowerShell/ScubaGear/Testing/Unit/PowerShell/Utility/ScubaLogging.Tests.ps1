using module '..\..\..\..\Modules\Utility\ScubaLogging.psm1'

InModuleScope ScubaLogging {
    Describe "ScubaLogging Module Tests" {

        BeforeAll {
            # Create test directory for logging tests
            $script:TestLogPath = Join-Path $env:TEMP "ScubaLogging-Tests-$(Get-Date -Format 'yyyyMMddHHmmss')"
            if (-not (Test-Path $script:TestLogPath)) {
                New-Item -ItemType Directory -Path $script:TestLogPath -Force | Out-Null
            }
        }

        BeforeEach {
            # Reset module variables before each test
            $Script:ScubaLogPath = $null
            $Script:ScubaLogEnabled = $false
            $Script:ScubaDeepTracing = $false
            $Script:ScubaLogLevel = "Info"
            $Script:ScubaEnhancedTracing = $false
            $Script:ScubaHasErrors = $false
            $Script:ScubaAutoReportEnabled = $false  # Disable auto-report during tests

            # Clean up any existing log files from previous tests to prevent accumulation
            if (Test-Path $script:TestLogPath) {
                Get-ChildItem -Path $script:TestLogPath -Filter "*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }

        AfterEach {
            # Clean up any logging state after each test
            if ($Script:ScubaLogEnabled) {
                Stop-ScubaLogging
            }

            # Additional cleanup: Remove any log files created during the test
            if (Test-Path $script:TestLogPath) {
                Get-ChildItem -Path $script:TestLogPath -Filter "*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }

        AfterAll {
            # Clean up test directory
            if (Test-Path $script:TestLogPath) {
                Remove-Item $script:TestLogPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Context "Initialize-ScubaLogging Function" {

            It "Should initialize logging with minimal parameters" {
                Initialize-ScubaLogging -DisableAutoReport

                $Script:ScubaLogEnabled | Should -Be $true
                $Script:ScubaLogLevel | Should -Be "Info"
                $Script:ScubaDeepTracing | Should -Be $false
                $Script:ScubaLogPath | Should -Be $null
            }

            It "Should initialize logging with log path" {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -DisableAutoReport

                $Script:ScubaLogEnabled | Should -Be $true
                $Script:ScubaLogPath | Should -Match "ScubaGear-DebugLog-\d{8}-\d{6}-\d{3}\.log"
                Test-Path (Split-Path $Script:ScubaLogPath -Parent) | Should -Be $true
            }

            It "Should create log directory if it doesn't exist" {
                $testPath = Join-Path $script:TestLogPath "NewDirectory"

                Initialize-ScubaLogging -LogPath $testPath -DisableAutoReport

                Test-Path $testPath | Should -Be $true
            }

            It "Should enable tracing when EnableTracing is specified" {
                Initialize-ScubaLogging -EnableTracing -DisableAutoReport

                $Script:ScubaDeepTracing | Should -Be $true
                $Script:ScubaEnhancedTracing | Should -Be $true
            }

            It "Should set custom log level" {
                Initialize-ScubaLogging -LogLevel "Debug" -DisableAutoReport

                $Script:ScubaLogLevel | Should -Be "Debug"
            }

            It "Should handle errors gracefully" {
                # Mock an error condition
                Mock New-Item { throw "Test error" } -ParameterFilter { $ItemType -eq "Directory" }

                { Initialize-ScubaLogging -LogPath "C:\InvalidPath\That\DoesNot\Exist" } | Should -Not -Throw
                $Script:ScubaLogEnabled | Should -Be $false
            }

            It "Should set ScubaAutoReportEnabled to false when DisableAutoReport is used" {
                Initialize-ScubaLogging -DisableAutoReport

                $Script:ScubaAutoReportEnabled | Should -Be $false
            }

            It "Should set ScubaAutoReportEnabled to true by default" {
                Initialize-ScubaLogging  # Don't use -DisableAutoReport here - we're testing the default

                $Script:ScubaAutoReportEnabled | Should -Be $true
            }
        }

        Context "Write-ScubaLog Function" {

            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug" -DisableAutoReport
            }

            It "Should write log entry to file when log path is configured" {
                $testMessage = "Test log message"

                Write-ScubaLog -Message $testMessage -Level "Info"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match $testMessage
            }

            It "Should include timestamp in log entry" {
                Write-ScubaLog -Message "Test message" -Level "Info"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]"
            }

            It "Should include log level in log entry" {
                Write-ScubaLog -Message "Test message" -Level "Warning"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "\[Warning\s*\]"
            }

            It "Should include source in log entry" {
                Write-ScubaLog -Message "Test message" -Level "Info" -Source "TestSource"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "\[TestSource\s*\]"
            }

            It "Should log structured data as JSON" {
                $testData = @{ Key1 = "Value1"; Key2 = 123 }

                Write-ScubaLog -Message "Test message" -Data $testData

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "Data:"
                $logContent | Should -Match "Key1.*Value1"
            }

            It "Should log exception details" {
                try {
                    throw "Test exception"
                }
                catch {
                    Write-ScubaLog -Message "Test error" -Level "Error" -Exception $_.Exception
                }

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "Exception:"
                $logContent | Should -Match "Test exception"
            }

            It "Should respect log level filtering" {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Warning" -DisableAutoReport

                Write-ScubaLog -Message "Debug message" -Level "Debug"
                Write-ScubaLog -Message "Info message" -Level "Info"
                Write-ScubaLog -Message "Warning message" -Level "Warning"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Not -Match "Debug message"
                $logContent | Should -Not -Match "Info message"
                $logContent | Should -Match "Warning message"
            }

            It "Should not log when logging is disabled" {
                Stop-ScubaLogging

                Write-ScubaLog -Message "Should not appear" -Level "Info"

                # Should not create any new log files or content
                $Script:ScubaLogEnabled | Should -Be $false
            }
        }

        Context "Trace-ScubaFunction Function" {

            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug" -DisableAutoReport
            }

            It "Should execute script block and return result" {
                $result = Trace-ScubaFunction -FunctionName "TestFunction" -ScriptBlock {
                    return "Test Result"
                }

                $result | Should -Be "Test Result"
            }

            It "Should log function entry and exit" {
                Trace-ScubaFunction -FunctionName "TestFunction" -ScriptBlock {
                    return "Result"
                }

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "ENTER: TestFunction"
                $logContent | Should -Match "EXIT: TestFunction"
            }

            It "Should sanitize sensitive parameters" {
                $params = @{
                    Username = "testuser"
                    Password = "secretpassword"
                    Token = "abc123"
                    SafeValue = "public"
                }

                Trace-ScubaFunction -FunctionName "TestFunction" -Parameters $params -ScriptBlock {
                    return "Result"
                }

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "Username.*testuser"
                $logContent | Should -Match "SafeValue.*public"
                $logContent | Should -Match "\[REDACTED\]"
                $logContent | Should -Not -Match "secretpassword"
                $logContent | Should -Not -Match "abc123"
            }

            It "Should measure execution time" {
                Trace-ScubaFunction -FunctionName "TestFunction" -ScriptBlock {
                    Start-Sleep -Milliseconds 100
                    return "Result"
                }

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "ExecutionTimeMs"
            }

            It "Should handle exceptions properly" {
                {
                    Trace-ScubaFunction -FunctionName "TestFunction" -ScriptBlock {
                        throw "Test exception"
                    }
                } | Should -Throw "Test exception"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "EXIT: TestFunction \(ERROR\)"
                $logContent | Should -Match "Status.*Error"
            }

            It "Should log return values when requested" {
                Trace-ScubaFunction -FunctionName "TestFunction" -LogReturnValue $true -ScriptBlock {
                    return "Simple Result"
                }

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "ReturnValue.*Simple Result"
            }

            It "Should handle array return values" {
                Trace-ScubaFunction -FunctionName "TestFunction" -LogReturnValue $true -ScriptBlock {
                    return @(1, 2, 3, 4, 5)
                }

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "ReturnCount.*5"
            }
        }

        Context "Write-ScubaFunctionEntry Function" {

            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug" -DisableAutoReport
            }

            It "Should log function entry with parameters" {
                $params = @{ Param1 = "Value1"; Param2 = 123 }

                Write-ScubaFunctionEntry -FunctionName "TestFunction" -Parameters $params

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "ENTER: TestFunction"
                $logContent | Should -Match "Param1.*Value1"
            }

            It "Should redact sensitive parameters" {
                $params = @{ Password = "secret"; Username = "user" }

                Write-ScubaFunctionEntry -FunctionName "TestFunction" -Parameters $params

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "\[REDACTED\]"
                $logContent | Should -Not -Match "secret"
            }

            It "Should truncate large strings" {
                $longString = "x" * 300
                $params = @{ LongParam = $longString }

                Write-ScubaFunctionEntry -FunctionName "TestFunction" -Parameters $params

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "truncated"
            }

            It "Should summarize large arrays" {
                $largeArray = 1..20
                $params = @{ ArrayParam = $largeArray }

                Write-ScubaFunctionEntry -FunctionName "TestFunction" -Parameters $params

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "Array\[.*items\]"
            }
        }

        Context "Write-ScubaFunctionExit Function" {

            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug" -DisableAutoReport
            }

            It "Should log successful function exit" {
                Write-ScubaFunctionExit -FunctionName "TestFunction" -ExecutionTimeMs 150

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "EXIT: TestFunction"
                $logContent | Should -Match "ExecutionTimeMs.*150"
                $logContent | Should -Match "Status.*Success"
            }

            It "Should log function exit with result" {
                Write-ScubaFunctionExit -FunctionName "TestFunction" -ExecutionTimeMs 100 -Result "Test Result"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "ResultType.*String"
                $logContent | Should -Match "Result.*Test Result"
            }

            It "Should log function exit with exception" {
                $testException = [System.Exception]::new("Test error")

                Write-ScubaFunctionExit -FunctionName "TestFunction" -ExecutionTimeMs 50 -Exception $testException

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "EXIT: TestFunction \(ERROR\)"
                $logContent | Should -Match "Status.*Error"
                $logContent | Should -Match "ErrorMessage.*Test error"
            }
        }

        Context "Stop-ScubaLogging Function" {

            It "Should clean up logging state" {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -DisableAutoReport

                Stop-ScubaLogging

                $Script:ScubaLogEnabled | Should -Be $false
                $Script:ScubaLogPath | Should -Be $null
                $Script:ScubaDeepTracing | Should -Be $false
            }

            It "Should log shutdown message" {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -DisableAutoReport

                Stop-ScubaLogging

                $logFiles = Get-ChildItem $script:TestLogPath -Filter "*.log"
                $logContent = Get-Content $logFiles[0].FullName -Raw
                $logContent | Should -Match "logging session ending"
            }

            It "Should handle errors gracefully when stopping" {
                # Initialize without transcript to avoid Stop-Transcript errors
                Initialize-ScubaLogging -DisableAutoReport

                { Stop-ScubaLogging } | Should -Not -Throw
            }
        }

        Context "Enable-ScubaAutoTrace Function" {

            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug" -DisableAutoReport
            }

            It "Should enable enhanced tracing" {
                Enable-ScubaAutoTrace

                $Script:ScubaEnhancedTracing | Should -Be $true
            }

            It "Should log activation message" {
                Enable-ScubaAutoTrace

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "Automatic function tracing enabled"
            }

            It "Should do nothing when logging is disabled" {
                Stop-ScubaLogging

                { Enable-ScubaAutoTrace } | Should -Not -Throw
                $Script:ScubaEnhancedTracing | Should -Be $false
            }
        }

        Context "Module State Management" {

            It "Should maintain consistent state across function calls" {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -EnableTracing -LogLevel "Debug" -DisableAutoReport

                $Script:ScubaLogEnabled | Should -Be $true
                $Script:ScubaDeepTracing | Should -Be $true
                $Script:ScubaLogLevel | Should -Be "Debug"
                $Script:ScubaLogPath | Should -Not -Be $null

                Write-ScubaLog -Message "Test message"

                # State should remain consistent after logging
                $Script:ScubaLogEnabled | Should -Be $true
                $Script:ScubaLogLevel | Should -Be "Debug"
            }

            It "Should handle multiple initialization calls" {
                Initialize-ScubaLogging -LogLevel "Info" -DisableAutoReport
                Initialize-ScubaLogging -LogLevel "Debug" -DisableAutoReport

                $Script:ScubaLogLevel | Should -Be "Debug"
            }
        }

        Context "Get-ScubaRunDetails - ConfiguredOPAPath Parameter" {

            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug" -DisableAutoReport
                # Mock slow/network ops so these tests run quickly in isolation
                Mock Get-CimInstance { return $null }
                Mock Test-NetConnection { return $true }
                Mock Resolve-DnsName { return @([PSCustomObject]@{ QueryType = 'A'; IP4Address = '1.2.3.4' }) }
            }

            It "Should log 'OPA Executable at configured path' when ConfiguredOPAPath is a file that exists" {
                $fakeOpa = Join-Path $script:TestLogPath "opa_windows_amd64.exe"
                Set-Content $fakeOpa "fake" -Encoding UTF8

                Get-ScubaRunDetails -ConfiguredOPAPath $fakeOpa

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "OPA Executable at configured path"
                $logContent | Should -Match '"FoundAtConfiguredPath":true'
            }

            It "Should log 'OPA Executable at configured path' when ConfiguredOPAPath is a directory containing an opa binary" {
                $opaDir = Join-Path $script:TestLogPath "opadir-$(Get-Date -Format 'fff')"
                New-Item -ItemType Directory $opaDir -Force | Out-Null
                Set-Content (Join-Path $opaDir "opa_windows_amd64.exe") "fake" -Encoding UTF8

                Get-ScubaRunDetails -ConfiguredOPAPath $opaDir

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "OPA Executable at configured path"
                $logContent | Should -Match '"FoundAtConfiguredPath":true'
            }

            It "Should log Warning 'OPA Executable NOT found at configured path' when directory has no opa binary" {
                $emptyDir = Join-Path $script:TestLogPath "emptydir-$(Get-Date -Format 'fff')"
                New-Item -ItemType Directory $emptyDir -Force | Out-Null

                Get-ScubaRunDetails -ConfiguredOPAPath $emptyDir

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "OPA Executable NOT found at configured path"
                $logContent | Should -Match '\[Warning\s*\].*RunDetails'
                $logContent | Should -Match '"FoundAtConfiguredPath":false'
            }

            It "Should log Warning 'OPA Executable NOT found at configured path' when path does not exist" {
                $nonExistent = Join-Path $script:TestLogPath "doesnotexist\opa.exe"

                Get-ScubaRunDetails -ConfiguredOPAPath $nonExistent

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "OPA Executable NOT found at configured path"
                $logContent | Should -Match '\[Warning\s*\].*RunDetails'
                $logContent | Should -Match '"FoundAtConfiguredPath":false'
            }

            It "Should skip ConfiguredOPAPath check when parameter is not provided" {
                Get-ScubaRunDetails

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Not -Match "OPA Executable at configured path"
                $logContent | Should -Not -Match "OPA Executable NOT found at configured path"
            }
        }

        Context "Get-ScubaRunDetails - Network Connectivity Uses Port 443" {

            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug" -DisableAutoReport
                Mock Get-CimInstance { return $null }
                Mock Resolve-DnsName { return @([PSCustomObject]@{ QueryType = 'A'; IP4Address = '1.2.3.4' }) }
            }

            It "Should call Test-NetConnection with Port 443 not ICMP" {
                Mock Test-NetConnection { return $true }

                Get-ScubaRunDetails

                Should -Invoke Test-NetConnection -ParameterFilter { $Port -eq 443 } -Times 1
            }

            It "Should log InternetConnected true when HTTPS port 443 check succeeds" {
                Mock Test-NetConnection { return $true }

                Get-ScubaRunDetails

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match '"InternetConnected":true'
            }

            It "Should log InternetConnected false and InternetError when HTTPS check throws" {
                Mock Test-NetConnection { throw "Connection refused" }

                Get-ScubaRunDetails

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match '"InternetConnected":false'
                $logContent | Should -Match 'InternetError'
            }
        }

        Context "Get-ScubaDebugLogReport - Rego Failure and OPA Path Parsing" {

            BeforeAll {
                $script:FakeLogPath = 'C:\fake\ScubaGear-DebugLog-test.log'

                # Base log entries satisfying all required Find-Entry lookups in the report generator.
                # No real files are created — Get-Content and Test-Path are mocked per-test.
                $script:BaseLogLines = @(
                    "[2026-01-01 10:00:00.000] [Info   ] [InvokeScuba         ] ScubaGear logging initialized",
                    '    Data: {"Version":"1.7.0","ProductNames":"aad","Environment":"commercial","OutputFolder":"C:\\test","LogFolder":"C:\\test\\DebugLogs"}',
                    "[2026-01-01 10:00:00.001] [Info   ] [RunDetails          ] System OS Information captured",
                    '    Data: {"OS":"Windows","Version":"10.0","Build":"19045","Architecture":"64-bit"}',
                    "[2026-01-01 10:00:00.002] [Info   ] [RunDetails          ] PowerShell Version Information captured",
                    '    Data: {"PSVersion":"7.4.0","PSEdition":"Core","CLRVersion":"8.0.0"}',
                    "[2026-01-01 10:00:00.003] [Info   ] [RunDetails          ] ScubaGear Version Information captured",
                    '    Data: {"CurrentLoadedVersion":"1.7.0","CurrentModulePath":"C:\\Modules","InstalledVersions":"1.7.0","AllPaths":"C:\\Modules","InstallSource":"Local"}',
                    "[2026-01-01 10:00:00.004] [Info   ] [RunDetails          ] OPA Executable found: opa_windows_amd64.exe",
                    '    Data: {"Path":"C:\\Users\\test\\.scubagear\\Tools\\opa_windows_amd64.exe","SizeMB":85.81,"Version":"Version: 1.13.2"}',
                    "[2026-01-01 10:00:00.005] [Info   ] [RunDetails          ] Network connectivity status captured",
                    '    Data: {"InternetConnected":true,"DNSResolution":true,"TestTarget":"www.microsoft.com"}',
                    "[2026-01-01 10:00:00.006] [Info   ] [RunDetails          ] ScubaGear run details collection completed successfully",
                    "[2026-01-01 10:00:00.007] [Info   ] [InvokeScuba         ] Starting product authentication...",
                    '    Data: {"ProductNames":"aad","M365Environment":"commercial","UsesServicePrincipal":false}',
                    "[2026-01-01 10:00:00.009] [Debug  ] [FunctionTrace       ] ENTER: Invoke-RunRego",
                    '    Data: {"ScubaConfig":"[ScubaConfig Object]"}',
                    "[2026-01-01 10:00:00.010] [Debug  ] [FunctionTrace       ] EXIT: Invoke-RunRego",
                    '    Data: {"Status":"Success","ExecutionTimeMs":104}',
                    "[2026-01-01 10:00:00.020] [Info   ] [InvokeScuba         ] ScubaGear DEBUG assessment completed - Check logs in [C:\test\DebugLogs]"
                )

                # Mock Test-Path so the ValidateScript on LogPath passes without a real file on disk
                Mock Test-Path { $true } -ParameterFilter { $Path -eq $script:FakeLogPath }

                # Mock Get-Content to always return $script:TestLines (which tests can modify)
                Mock Get-Content { return $script:TestLines } -ParameterFilter { $Path -eq $script:FakeLogPath }
            }

            BeforeEach {
                # Reset TestLines to base - prevents test pollution
                $script:TestLines = $script:BaseLogLines
            }

            <#
            It "Should show 'Warnings and Errors' section populated when per-product Provider failure is logged" {
                $script:TestLines = $script:BaseLogLines + @(
                    "[2026-01-01 10:00:00.011] [Warning ] [ProviderList        ] Provider export failed: Defender",
                    '    Data: {"Product":"defender","Error":"Timeout connecting to API"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                $report | Should -Match '## Warnings and Errors'
                $report | Should -Not -Match '_No warnings or errors recorded\._'
                $report | Should -Match 'Provider export failed: Defender'
            }
            #>

            It "Should show 'Warnings and Errors' section populated when per-product Rego failure is logged" {
                $script:TestLines = $script:BaseLogLines + @(
                    "[2026-01-01 10:00:00.011] [Warning ] [RunRego             ] Rego evaluation failed: AAD",
                    '    Data: {"Product":"aad","OPAPath":".","Error":"cannot find opa binary"}',
                    "[2026-01-01 10:00:00.012] [Warning ] [InvokeScuba         ] Some Rego evaluations failed",
                    '    Data: {"FailedProducts":"aad"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                $report | Should -Match '## Warnings and Errors'
                $report | Should -Not -Match '_No warnings or errors recorded\._'
                $report | Should -Match 'Rego evaluation failed: AAD'
            }

            It "Should show 'Success' for Rego phase when no failure warning exists" {
                $script:TestLines = $script:BaseLogLines

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                $report | Should -Match '\| Rego Evaluation \|.*Success'
                $report | Should -Not -Match ':x: Failed'
            }



            It "Should show ':x: Failed' for Rego phase when 'Some Rego evaluations failed' Warning is present" {
                $script:TestLines = $script:BaseLogLines + @(
                    "[2026-01-01 10:00:00.011] [Warning ] [InvokeScuba         ] Some Rego evaluations failed",
                    '    Data: {"FailedProducts":"aad"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                $report | Should -Match ':x: Failed'
                $report | Should -Match 'aad'
            }

            It "Should show OPA NOT FOUND warning when configured path entry indicates missing OPA" {
                $script:TestLines = $script:BaseLogLines + @(
                    "[2026-01-01 10:00:00.011] [Warning ] [RunDetails          ] OPA Executable NOT found at configured path",
                    '    Data: {"ConfiguredOPAPath":"C:\\Apps","FoundAtConfiguredPath":false}'
                )


                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                $report | Should -Match 'OPAPath \(configured\)'
                $report | Should -Match 'C:\\Apps'
                $report | Should -Match ':x: NOT FOUND'
            }

            It "Should show OPA found status when configured path entry indicates OPA present" {
                $script:TestLines = $script:BaseLogLines + @(
                    "[2026-01-01 10:00:00.011] [Info   ] [RunDetails          ] OPA Executable at configured path",
                    '    Data: {"ConfiguredOPAPath":"C:\\MyOPA","FoundAtConfiguredPath":true,"ResolvedPath":"C:\\MyOPA\\opa.exe"}'
                )


                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                $report | Should -Match 'OPAPath \(configured\)'
                $report | Should -Match 'C:\\MyOPA'
                $report | Should -Match ':white_check_mark: Found'
            }

            It "Should include per-product report counts in Run Timeline when ReportCreation entries exist" {
                $script:TestLines = $script:BaseLogLines + @(
                    "[2026-01-01 10:00:00.011] [Info   ] [ReportCreation      ] Report created: AAD",
                    '    Data: {"Product":"aad","Passes":42,"Failures":3,"Warnings":1,"Manual":5,"Omits":0,"Errors":0}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # ReportCreation Info entries should appear in the Run Timeline
                $report | Should -Match 'Report created: AAD'
            }

            It "Should include Module Loading Progression table when ModuleSnapshot entries exist" {
                $script:TestLines = $script:BaseLogLines + @(
                    "[2026-01-01 10:00:00.011] [Info   ] [ModuleSnapshot      ] Module snapshot 'InitialLoad' captured: 2 module(s)",
                    '    Data: {"SnapshotName":"InitialLoad","ModuleCount":2,"Modules":["ScubaGear (1.7.1)","powershell-yaml (0.4.7)"],"ModulePaths":["ScubaGear=C:\\Modules\\ScubaGear","powershell-yaml=C:\\Modules\\yaml"],"ModuleSummary":"ScubaGear (1.7.1); powershell-yaml (0.4.7)","ModulePathsSummary":"ScubaGear=C:\\Modules\\ScubaGear; powershell-yaml=C:\\Modules\\yaml"}',
                    "[2026-01-01 10:00:00.012] [Info   ] [ModuleSnapshot      ] Module snapshot 'PostAuthentication' captured: 3 module(s)",
                    '    Data: {"SnapshotName":"PostAuthentication","ModuleCount":3,"Modules":["ScubaGear (1.7.1)","powershell-yaml (0.4.7)","Microsoft.Graph.Authentication (2.25.0)"],"ModulePaths":["ScubaGear=C:\\Modules\\ScubaGear","powershell-yaml=C:\\Modules\\yaml","Microsoft.Graph.Authentication=C:\\Modules\\Graph"],"ModuleSummary":"ScubaGear (1.7.1); powershell-yaml (0.4.7); Microsoft.Graph.Authentication (2.25.0)","ModulePathsSummary":"ScubaGear=C:\\Modules\\ScubaGear; powershell-yaml=C:\\Modules\\yaml; Microsoft.Graph.Authentication=C:\\Modules\\Graph"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                $report | Should -Match '## Module Loading Progression'
                $report | Should -Match '\| Snapshot \| Module \| Version \| Path \|'
                $report | Should -Match 'InitialLoad'
                $report | Should -Match 'PostAuthentication'
                $report | Should -Match 'Microsoft\.Graph\.Authentication'
                $report | Should -Match '2\.25\.0'
            }

            It "Should show unique modules only in Module Loading Progression table" {
                $script:TestLines = $script:BaseLogLines + @(
                    "[2026-01-01 10:00:00.011] [Info   ] [ModuleSnapshot      ] Module snapshot 'InitialLoad' captured: 1 module(s)",
                    '    Data: {"SnapshotName":"InitialLoad","ModuleCount":1,"Modules":["powershell-yaml (0.4.7)"],"ModulePaths":["powershell-yaml=C:\\Modules\\yaml"],"ModuleSummary":"powershell-yaml (0.4.7)","ModulePathsSummary":"powershell-yaml=C:\\Modules\\yaml"}',
                    "[2026-01-01 10:00:00.012] [Info   ] [ModuleSnapshot      ] Module snapshot 'PostAuthentication' captured: 2 module(s)",
                    '    Data: {"SnapshotName":"PostAuthentication","ModuleCount":2,"Modules":["powershell-yaml (0.4.7)","Microsoft.Graph.Authentication (2.25.0)"],"ModulePaths":["powershell-yaml=C:\\Modules\\yaml","Microsoft.Graph.Authentication=C:\\Modules\\Graph"],"ModuleSummary":"powershell-yaml (0.4.7); Microsoft.Graph.Authentication (2.25.0)","ModulePathsSummary":"powershell-yaml=C:\\Modules\\yaml; Microsoft.Graph.Authentication=C:\\Modules\\Graph"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # Extract only the Module Loading Progression section
                if ($report -match '(?s)## Module Loading Progression.*?(##|$)') {
                    $moduleSection = $Matches[0]
                    # powershell-yaml appears in both snapshots but should only be listed once in the table under InitialLoad
                    $yamlMatches = ([regex]::Matches($moduleSection, 'powershell-yaml')).Count
                    $yamlMatches | Should -Be 1
                }
                else {
                    throw "Module Loading Progression section not found in report"
                }
            }

            It "Should include Comments section in markdown report" {
                $script:TestLines = $script:BaseLogLines

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                $report | Should -Match '## Comments / Additional Notes'
                $report | Should -Match 'Use this section to add any additional context'
            }
        }

        Context "Integration Tests" {

            BeforeEach {
                # Make sure we start clean for integration tests
                if ($Script:ScubaLogEnabled) {
                    Stop-ScubaLogging
                }

                # Clean up any existing log files in the test directory
                if (Test-Path $script:TestLogPath) {
                    Get-ChildItem $script:TestLogPath -Filter "*.log" | Remove-Item -Force -ErrorAction SilentlyContinue
                }

                # Reset all module variables to ensure clean state
                $Script:ScubaLogPath = $null
                $Script:ScubaLogEnabled = $false
                $Script:ScubaDeepTracing = $false
                $Script:ScubaLogLevel = "Info"
                $Script:ScubaEnhancedTracing = $false
            }

            It "Should support full logging workflow" {
                # Initialize with full configuration and Debug level to see all messages
                Initialize-ScubaLogging -LogPath $script:TestLogPath -EnableTracing -LogLevel "Debug" -Transcript -DisableAutoReport

                # Verify the initialization worked
                $Script:ScubaLogLevel | Should -Be "Debug"
                $Script:ScubaDeepTracing | Should -Be $true

                # Store the current log file path for verification
                $currentLogFile = $Script:ScubaLogPath
                $currentLogFile | Should -Not -BeNullOrEmpty

                # Perform various logging operations
                Write-ScubaLog -Message "Test workflow starting" -Level "Warning"

                $result = Trace-ScubaFunction -FunctionName "TestWorkflow" -Parameters @{TestParam = "TestValue"} -ScriptBlock {
                    Write-ScubaLog -Message "Inside function" -Level "Debug"
                    return "Success"
                }

                Write-ScubaLog -Message "Test workflow completed" -Level "Warning"

                # Clean up
                Stop-ScubaLogging

                # Verify log file exists and contains expected content
                Test-Path $currentLogFile | Should -Be $true

                $logContent = Get-Content $currentLogFile -Raw
                $logContent | Should -Match "Test workflow starting"
                $logContent | Should -Match "ENTER: TestWorkflow"
                $logContent | Should -Match "Inside function"
                $logContent | Should -Match "EXIT: TestWorkflow"
                $logContent | Should -Match "Test workflow completed"
                $logContent | Should -Match "logging session ending"

                $result | Should -Be "Success"
            }
        }

        Context "Update-ScubaModuleSnapshot Function" {

            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug" -DisableAutoReport

                # Create a temporary RequiredVersions.ps1 file for mocking
                $script:TempRequiredVersionsPath = Join-Path $script:TestLogPath "TempRequiredVersions.ps1"
            }

            AfterEach {
                # Clean up temp file
                if (Test-Path $script:TempRequiredVersionsPath) {
                    Remove-Item $script:TempRequiredVersionsPath -Force
                }
            }

            It "Should capture module snapshot with required modules" {
                # Create temporary RequiredVersions.ps1 with test module list
                Set-Content -Path $script:TempRequiredVersionsPath -Value '$ModuleList = @(@{ModuleName="TestModule1"},@{ModuleName="TestModule2"})'

                # Mock Join-Path to return our temp file path
                Mock Join-Path { return $script:TempRequiredVersionsPath } -ParameterFilter { $ChildPath -eq "..\..\RequiredVersions.ps1" }

                # Mock Get-Module to return test modules
                Mock Get-Module {
                    return @(
                        [PSCustomObject]@{Name="TestModule1"; Version="1.0.0"; ModuleBase="C:\Test\Module1"},
                        [PSCustomObject]@{Name="ScubaGear"; Version="1.7.1"; ModuleBase="C:\Test\ScubaGear"}
                    )
                }

                Update-ScubaModuleSnapshot -SnapshotName "TestSnapshot"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "Module snapshot 'TestSnapshot' captured"
                $logContent | Should -Match "TestModule1"
                $logContent | Should -Match "ModuleSnapshot"
            }

            It "Should handle empty module list gracefully" {
                # Create temporary RequiredVersions.ps1 with empty module list
                Set-Content -Path $script:TempRequiredVersionsPath -Value '$ModuleList = @()'

                # Mock Join-Path to return our temp file path
                Mock Join-Path { return $script:TempRequiredVersionsPath } -ParameterFilter { $ChildPath -eq "..\..\RequiredVersions.ps1" }

                Mock Get-Module { return @() }

                Update-ScubaModuleSnapshot -SnapshotName "EmptySnapshot"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "has no module list"
                $logContent | Should -Match "Warning"
            }

            It "Should handle missing RequiredVersions.ps1 file" {
                # Mock Join-Path to return a non-existent path
                Mock Join-Path { return "C:\NonExistent\RequiredVersions.ps1" } -ParameterFilter { $ChildPath -eq "..\..\RequiredVersions.ps1" }

                Update-ScubaModuleSnapshot -SnapshotName "MissingFile"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match "RequiredVersions.ps1 not found"
                $logContent | Should -Match "Warning"
            }

            It "Should skip when logging is disabled" {
                Stop-ScubaLogging
                $Script:ScubaLogEnabled = $false

                { Update-ScubaModuleSnapshot -SnapshotName "DisabledLogging" } | Should -Not -Throw
            }

            It "Should log module count in snapshot data" {
                # Create temporary RequiredVersions.ps1 with single test module
                Set-Content -Path $script:TempRequiredVersionsPath -Value '$ModuleList = @(@{ModuleName="TestModule"})'

                # Mock Join-Path to return our temp file path
                Mock Join-Path { return $script:TempRequiredVersionsPath } -ParameterFilter { $ChildPath -eq "..\..\RequiredVersions.ps1" }

                Mock Get-Module {
                    return @([PSCustomObject]@{Name="TestModule"; Version="1.0.0"; ModuleBase="C:\Test"})
                }

                Update-ScubaModuleSnapshot -SnapshotName "CountTest"

                $logContent = Get-Content $Script:ScubaLogPath -Raw
                $logContent | Should -Match '"ModuleCount":1'
                $logContent | Should -Match '"SnapshotName":"CountTest"'
            }
        }

        Context "Get-ScubaDebugLogReport - Redaction Patterns" {

            BeforeAll {
                $script:FakeLogPath = 'C:\fake\ScubaGear-DebugLog-redaction-test.log'

                # Mock Test-Path so ValidateScript passes
                Mock Test-Path { $true } -ParameterFilter { $Path -eq $script:FakeLogPath }
                
                # Mock Get-Content to return test log content
                Mock Get-Content { return $script:TestRedactionLines } -ParameterFilter { $Path -eq $script:FakeLogPath }
                
                # Override Get-Content for the redaction schema to return the real file as-is
                Mock Get-Content {
                    # Find module file location to locate redaction JSON
                    $moduleFile = Get-Command Get-ScubaDebugLogReport | Select-Object -ExpandProperty ScriptBlock | Select-Object -ExpandProperty File
                    $modulePath = Split-Path $moduleFile -Parent
                    $actualPath = Join-Path $modulePath 'ScubaLoggingRedactions.json'
                    
                    if (-not (Test-Path $actualPath)) {
                        throw "Redaction file not found at: $actualPath"
                    }
                    
                    # Return actual file content without modification
                    return [System.IO.File]::ReadAllText($actualPath)
                } -ParameterFilter { $Path -like '*ScubaLoggingRedactions.json' }
            }

            BeforeEach {
                # Reset test lines - base structure needed for report generation
                $script:TestRedactionLines = @(
                    "[2026-01-01 10:00:00.000] [Info   ] [InvokeScuba         ] ScubaGear logging initialized",
                    '    Data: {"Version":"1.7.0","ProductNames":"aad","Environment":"commercial","OutputFolder":"C:\\test","LogFolder":"C:\\test\\DebugLogs"}',
                    "[2026-01-01 10:00:00.001] [Info   ] [InvokeScuba         ] Cmdlet invocation captured",
                    '    Data: {"InvocationLine":"Invoke-SCuBA -ProductNames aad -AppId c5158c26-353e-47a2-a1ef-03607d417140 -CertificateThumbprint D0A37EC3BD70417A784020270A5890337AFFFB89 -Organization dtolab.onmicrosoft.com"}',
                    "[2026-01-01 10:00:00.002] [Info   ] [RunDetails          ] System OS Information captured",
                    '    Data: {"OS":"Windows","Version":"10.0","Build":"19045","Architecture":"64-bit"}',
                    "[2026-01-01 10:00:00.003] [Info   ] [RunDetails          ] PowerShell Version Information captured",
                    '    Data: {"PSVersion":"7.4.0","PSEdition":"Core","CLRVersion":"8.0.0"}',
                    "[2026-01-01 10:00:00.004] [Info   ] [RunDetails          ] ScubaGear Version Information captured",
                    '    Data: {"CurrentLoadedVersion":"1.7.0","CurrentModulePath":"C:\\Modules","InstalledVersions":"1.7.0","AllPaths":"C:\\Modules","InstallSource":"Local"}',
                    "[2026-01-01 10:00:00.005] [Info   ] [RunDetails          ] OPA Executable found: opa_windows_amd64.exe",
                    '    Data: {"Path":"C:\\Users\\johndoe\\.scubagear\\Tools\\opa_windows_amd64.exe","SizeMB":85.81,"Version":"Version: 1.13.2"}',
                    "[2026-01-01 10:00:00.006] [Info   ] [RunDetails          ] Network connectivity status captured",
                    '    Data: {"InternetConnected":true,"DNSResolution":true,"TestTarget":"www.microsoft.com"}',
                    "[2026-01-01 10:00:00.007] [Info   ] [InvokeScuba         ] Starting product authentication...",
                    '    Data: {"ProductNames":"aad","M365Environment":"commercial","UsesServicePrincipal":true}'
                )
            }

            It "Should redact AppID in command line parameters" {
                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # Should redact the AppID GUID
                $report | Should -Not -Match 'c5158c26-353e-47a2-a1ef-03607d417140'
                $report | Should -Match '-AppId \[.*REDACTED.*\]'
            }

            It "Should redact CertificateThumbprint in command line" {
                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # Should redact the certificate thumbprint
                $report | Should -Not -Match 'D0A37EC3BD70417A784020270A5890337AFFFB89'
                $report | Should -Match '-CertificateThumbprint \[.*REDACTED.*\]'
            }

            It "Should redact Organization tenant domain in command line" {
                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # Should redact the onmicrosoft.com domain
                $report | Should -Not -Match 'dtolab\.onmicrosoft\.com'
                $report | Should -Match '-Organization \[.*REDACTED.*\]'
            }

            It "Should redact local user path in JSON-escaped format" {
                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # The log has JSON-escaped paths (C:\\Users\\johndoe\\) but the markdown report displays them with single backslashes
                # Should redact the username in the displayed path
                $report | Should -Not -Match 'johndoe'
                $report | Should -Match 'C:\\Users\\\[.*REDACTED.*\]'
            }

            It "Should redact AppID in Azure AD authentication error messages with quotes" {
                $script:TestRedactionLines += @(
                    "[2026-01-01 10:00:00.010] [Error  ] [Connection          ] Authentication failed",
                    '    Data: {"Error":"AADSTS700016: Application with identifier ''c5158c26-353e-47a2-a1ef-03607d417140'' was not found"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # Should redact AppID in error message
                $report | Should -Not -Match "identifier 'c5158c26-353e-47a2-a1ef-03607d417140'"
                $report | Should -Match "identifier '\[.*REDACTED.*\]'"
            }

            It "Should redact AppID in JSON-escaped Unicode quotes" {
                $script:TestRedactionLines += @(
                    "[2026-01-01 10:00:00.011] [Error  ] [Connection          ] Graph API error",
                    '    Data: {"ErrorDetails":"Application with identifier \\u0027c5158c26-353e-47a2-a1ef-03607d417140\\u0027 not authorized"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # Should redact AppID with Unicode quotes
                $report | Should -Not -Match '\\u0027c5158c26-353e-47a2-a1ef-03607d417140\\u0027'
                $report | Should -Match '\\u0027\[.*REDACTED.*\]\\u0027'
            }

            It "Should redact tenant short name in directory error messages" {
                $script:TestRedactionLines += @(
                    "[2026-01-01 10:00:00.011] [Error  ] [Connection          ] Tenant lookup failed",
                    '    Data: {"Error":"Tenant was not found in the directory \\u0027dtolab\\u0027. Check to make sure you have the correct tenant ID"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # Should redact tenant short name in directory context
                $report | Should -Not -Match 'directory \\u0027dtolab\\u0027'
                $report | Should -Match 'directory \\u0027\[.*REDACTED.*\]\\u0027'
            }

            It "Should redact ConfiguredOPAPath with username in JSON data" {
                $script:TestRedactionLines += @(
                    "[2026-01-01 10:00:00.012] [Warning] [RunDetails          ] OPA Executable NOT found at configured path",
                    '    Data: {"FoundAtConfiguredPath":false,"ConfiguredOPAPath":"C:\\Users\\johndoe\\.scubagear\\Tools"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # The markdown report displays paths with single backslashes (display format, not JSON format)
                # Should redact the username
                $report | Should -Not -Match 'johndoe'
                $report | Should -Match 'C:\\Users\\\[.*REDACTED.*\]'
            }

            It "Should preserve non-sensitive UUIDs and paths" {
                $script:TestRedactionLines += @(
                    "[2026-01-01 10:00:00.013] [Info   ] [InvokeScuba         ] Starting provider execution...",
                    '    Data: {"ModuleVersion":"1.7.1","ProductNames":"aad","Guid":"d38604c0-5c0b-4997-b268-c632af060bd3"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # Should preserve non-AppID GUIDs (not in sensitive contexts)
                $report | Should -Match 'd38604c0-5c0b-4997-b268-c632af060bd3'
                
                # Should preserve system paths without usernames
                $report | Should -Match 'C:\\Modules'
            }

            It "Should redact multiple sensitive values in the same report" {
                $script:TestRedactionLines += @(
                    "[2026-01-01 10:00:00.014] [Warning] [ProviderList        ] Provider export failed: AAD",
                    '    Data: {"Error":"Authentication error for app c5158c26-353e-47a2-a1ef-03607d417140 in tenant dtolab.onmicrosoft.com","ConfigPath":"C:\\Users\\johndoe\\.scubagear"}'
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # All sensitive values should be redacted
                $report | Should -Not -Match 'c5158c26-353e-47a2-a1ef-03607d417140'
                $report | Should -Not -Match 'dtolab\.onmicrosoft\.com'
                $report | Should -Not -Match 'johndoe'
                $report | Should -Match '\[.*REDACTED.*\]'
            }

            It "Should redact local user paths in non-JSON format" {
                $script:TestRedactionLines += @(
                    "[2026-01-01 10:00:00.015] [Warning] [RunDetails          ] No OPA executable found in C:\Users\johndoe\.scubagear\Tools"
                )

                $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                # Should redact username from single-backslash path
                $report | Should -Not -Match 'C:\\Users\\johndoe\\'
                $report | Should -Match 'C:\\Users\\\[.*REDACTED.*\]\\'
            }

            It "Should handle reports with no sensitive data gracefully" {
                $script:TestRedactionLines = @(
                    "[2026-01-01 10:00:00.000] [Info   ] [InvokeScuba         ] ScubaGear logging initialized",
                    '    Data: {"Version":"1.7.0","ProductNames":"aad"}',
                    "[2026-01-01 10:00:00.001] [Info   ] [RunDetails          ] System OS Information captured",
                    '    Data: {"OS":"Windows"}',
                    "[2026-01-01 10:00:00.002] [Info   ] [RunDetails          ] PowerShell Version Information captured",
                    '    Data: {"PSVersion":"7.4.0"}',
                    "[2026-01-01 10:00:00.003] [Info   ] [RunDetails          ] ScubaGear Version Information captured",
                    '    Data: {"CurrentLoadedVersion":"1.7.0"}',
                    "[2026-01-01 10:00:00.004] [Info   ] [RunDetails          ] OPA Executable found: opa_windows_amd64.exe",
                    '    Data: {"Version":"Version: 1.13.2"}',
                    "[2026-01-01 10:00:00.005] [Info   ] [RunDetails          ] Network connectivity status captured",
                    '    Data: {"InternetConnected":true}',
                    "[2026-01-01 10:00:00.006] [Info   ] [InvokeScuba         ] Starting product authentication...",
                    '    Data: {"ProductNames":"aad"}'
                )

                { Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath } | Should -Not -Throw
            }

            Context "GUID Blanket Redaction Tests (normally disabled)" {
                BeforeAll {
                    # Override the mock to enable GUID_Blanket pattern for these specific tests
                    Mock Get-Content {
                        $moduleFile = Get-Command Get-ScubaDebugLogReport | Select-Object -ExpandProperty ScriptBlock | Select-Object -ExpandProperty File
                        $modulePath = Split-Path $moduleFile -Parent
                        $actualPath = Join-Path $modulePath 'ScubaLoggingRedactions.json'
                        
                        if (-not (Test-Path $actualPath)) {
                            throw "Redaction file not found at: $actualPath"
                        }
                        
                        # Read and modify to enable GUID_Blanket
                        $content = [System.IO.File]::ReadAllText($actualPath)
                        $schema = $content | ConvertFrom-Json
                        
                        # Enable GUID_Blanket pattern specifically for these tests
                        $guidPattern = $schema.patterns | Where-Object { $_.name -eq 'GUID_Blanket' }
                        if ($guidPattern) {
                            $guidPattern.enabled = $true
                        }
                        
                        return ($schema | ConvertTo-Json -Depth 10)
                    } -ParameterFilter { $Path -like '*ScubaLoggingRedactions.json' }
                }

                It "Should redact any GUID format (blanket redaction for user/group/resource IDs)" {
                    $script:TestRedactionLines += @(
                        "[2026-01-01 10:00:00.016] [Warning] [ProviderList        ] Error running command",
                        '    Data: {"Command":"Get-MgBetaUser","Error":"User with ID a1b2c3d4-e5f6-7890-abcd-ef1234567890 not found","StackTrace":"at line 42"}'
                    )

                    $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                    # Should redact user/group/resource IDs in GUID format
                    $report | Should -Not -Match 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
                    $report | Should -Match 'User with ID \[.*REDACTED.*\] not found'
                }

                It "Should redact multiple GUIDs in error messages from CommandTracker" {
                    $script:TestRedactionLines += @(
                        "[2026-01-01 10:00:00.017] [Warning] [ProviderList        ] Error running command",
                        '    Data: {"Command":"Get-MgBetaGroupMember","Error":"Cannot retrieve members of group 12345678-abcd-1234-abcd-1234567890ab for user 98765432-dcba-4321-dcba-0987654321fe","StackTrace":"at line 99"}'
                    )

                    $report = Get-ScubaDebugLogReport -DebugLogPath $script:FakeLogPath

                    # Should redact both group ID and user ID
                    $report | Should -Not -Match '12345678-abcd-1234-abcd-1234567890ab'
                    $report | Should -Not -Match '98765432-dcba-4321-dcba-0987654321fe'
                    $report | Should -Match 'group \[.*REDACTED.*\] for user \[.*REDACTED.*\]'
                }
            }
        }
    }
}