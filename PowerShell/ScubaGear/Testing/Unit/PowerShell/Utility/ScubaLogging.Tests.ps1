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
        }
        
        AfterEach {
            # Clean up any logging state after each test
            if ($Script:ScubaLogEnabled) {
                Stop-ScubaLogging
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
                Initialize-ScubaLogging
                
                $Script:ScubaLogEnabled | Should -Be $true
                $Script:ScubaLogLevel | Should -Be "Info"
                $Script:ScubaDeepTracing | Should -Be $false
                $Script:ScubaLogPath | Should -Be $null
            }
            
            It "Should initialize logging with log path" {
                Initialize-ScubaLogging -LogPath $script:TestLogPath
                
                $Script:ScubaLogEnabled | Should -Be $true
                $Script:ScubaLogPath | Should -Match "ScubaGear-DebugLog-\d{8}-\d{6}-\d{3}\.log"
                Test-Path (Split-Path $Script:ScubaLogPath -Parent) | Should -Be $true
            }
            
            It "Should create log directory if it doesn't exist" {
                $testPath = Join-Path $script:TestLogPath "NewDirectory"
                
                Initialize-ScubaLogging -LogPath $testPath
                
                Test-Path $testPath | Should -Be $true
            }
            
            It "Should enable tracing when EnableTracing is specified" {
                Initialize-ScubaLogging -EnableTracing
                
                $Script:ScubaDeepTracing | Should -Be $true
                $Script:ScubaEnhancedTracing | Should -Be $true
            }
            
            It "Should set custom log level" {
                Initialize-ScubaLogging -LogLevel "Debug"
                
                $Script:ScubaLogLevel | Should -Be "Debug"
            }
            
            It "Should handle errors gracefully" {
                # Mock an error condition
                Mock New-Item { throw "Test error" } -ParameterFilter { $ItemType -eq "Directory" }
                
                { Initialize-ScubaLogging -LogPath "C:\InvalidPath\That\DoesNot\Exist" } | Should -Not -Throw
                $Script:ScubaLogEnabled | Should -Be $false
            }
        }

        Context "Write-ScubaLog Function" {
            
            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug"
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
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Warning"
                
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
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug"
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
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug"
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
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug"
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
                Initialize-ScubaLogging -LogPath $script:TestLogPath
                
                Stop-ScubaLogging
                
                $Script:ScubaLogEnabled | Should -Be $false
                $Script:ScubaLogPath | Should -Be $null
                $Script:ScubaDeepTracing | Should -Be $false
            }
            
            It "Should log shutdown message" {
                Initialize-ScubaLogging -LogPath $script:TestLogPath
                
                Stop-ScubaLogging
                
                $logFiles = Get-ChildItem $script:TestLogPath -Filter "*.log"
                $logContent = Get-Content $logFiles[0].FullName -Raw
                $logContent | Should -Match "logging session ending"
            }
            
            It "Should handle errors gracefully when stopping" {
                # Initialize without transcript to avoid Stop-Transcript errors
                Initialize-ScubaLogging
                
                { Stop-ScubaLogging } | Should -Not -Throw
            }
        }

        Context "Enable-ScubaAutoTrace Function" {
            
            BeforeEach {
                Initialize-ScubaLogging -LogPath $script:TestLogPath -LogLevel "Debug"
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
                Initialize-ScubaLogging -LogPath $script:TestLogPath -EnableTracing -LogLevel "Debug"
                
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
                Initialize-ScubaLogging -LogLevel "Info"
                Initialize-ScubaLogging -LogLevel "Debug"
                
                $Script:ScubaLogLevel | Should -Be "Debug"
            }
        }

        Context "Integration Tests" {
            
            BeforeEach {
                # Make sure we start clean for integration tests
                Stop-ScubaLogging
                $Script:ScubaLogPath = $null
                $Script:ScubaLogEnabled = $false
                $Script:ScubaDeepTracing = $false
                $Script:ScubaLogLevel = "Info"
                $Script:ScubaEnhancedTracing = $false
            }
            
            It "Should support full logging workflow" {
                # Initialize with full configuration and Debug level to see all messages
                Initialize-ScubaLogging -LogPath $script:TestLogPath -EnableTracing -LogLevel "Debug" -EnableTranscript
                
                # Verify the initialization worked
                $Script:ScubaLogLevel | Should -Be "Debug"
                $Script:ScubaDeepTracing | Should -Be $true
                
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
                $logFiles = Get-ChildItem $script:TestLogPath -Filter "*.log"
                $logFiles.Count | Should -BeGreaterThan 0
                
                $logContent = Get-Content $logFiles[0].FullName -Raw
                $logContent | Should -Match "Test workflow starting"
                $logContent | Should -Match "ENTER: TestWorkflow"
                $logContent | Should -Match "Inside function"
                $logContent | Should -Match "EXIT: TestWorkflow"
                $logContent | Should -Match "Test workflow completed"
                $logContent | Should -Match "logging session ending"
                
                $result | Should -Be "Success"
            }
        }
    }
}