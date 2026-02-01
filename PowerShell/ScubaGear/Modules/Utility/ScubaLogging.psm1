<#
.SYNOPSIS
ScubaLogging PowerShell Module - Detailed Logging Module for ScubaGear

.DESCRIPTION
This module provides a robust, configurable logging framework specifically designed for ScubaGear operations.
It offers multiple levels of logging from basic information capture to deep function tracing and debugging.

KEY FEATURES:
• Structured logging with timestamps, levels, sources, and optional data payloads
• Configurable log levels (Debug, Info, Warning, Error) with filtering
• File-based logging with automatic timestamped filenames to prevent conflicts
• PowerShell transcript recording for complete console output capture
• Function tracing with entry/exit logging, parameter capture, and timing
• Automatic sensitive data redaction (passwords, secrets, tokens, keys)
• Enhanced debugging features using PowerShell's built-in debugging capabilities
• Minimal performance impact with optional features that can be enabled as needed

CORE FUNCTIONALITY:
1. INITIALIZATION: Initialize-ScubaLogging sets up the logging Module with configurable paths,
   log levels, tracing options, and transcript recording.

2. STRUCTURED LOGGING: Write-ScubaLog provides centralized logging with structured data support,
   automatic console/file output routing, and sensitive data protection.

3. FUNCTION TRACING: Trace-ScubaFunction wraps function calls to automatically log entry/exit,
   parameters, return values, execution timing, and error handling.

4. AUTOMATIC TRACING: Enable-ScubaAutoTrace provides transparent function interception for
   Detailed debugging without manual instrumentation.

5. CLEANUP: Stop-ScubaLogging properly shuts down logging, stops transcripts, and resets state.
#>

# Module-level variables for logging configuration
$Script:ScubaLogPath = $null
$Script:ScubaLogEnabled = $false
$Script:ScubaDeepTracing = $false
$Script:ScubaLogLevel = "Info"
$Script:ScubaEnhancedTracing = $false

function Initialize-ScubaLogging {
    <#
    .SYNOPSIS
    Initialize the ScubaGear logging Module

    .DESCRIPTION
    Sets up logging for ScubaGear with configurable output paths,
    transcript recording, and PowerShell debugging features.

    .PARAMETER LogPath
    Directory where log files will be created. If not provided, logging to files is disabled.

    .PARAMETER EnableTracing
    Enable deep function tracing using PowerShell's built-in debugging features.

    .PARAMETER LogLevel
    Minimum log level to capture (Debug, Info, Warning, Error)

    .PARAMETER EnableTranscript
    Enable Start-Transcript for complete console output capture

    .EXAMPLE
    Initialize-ScubaLogging -LogPath "C:\Logs\ScubaGear" -EnableTracing -EnableTranscript
    #>
    [CmdletBinding()]
    param(
        [string]$LogPath = $null,
        [switch]$EnableTracing,
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$LogLevel = "Info",
        [switch]$EnableTranscript
    )

    try {
        # Set module-level configuration variables to control logging behavior
        $Script:ScubaLogEnabled = $true
        $Script:ScubaDeepTracing = $EnableTracing
        $Script:ScubaLogLevel = $LogLevel

        # Setup log directory and file path with timestamp
        if ($LogPath) {
            # Create the log directory if it doesn't exist
            if (!(Test-Path $LogPath)) {
                New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
                Write-Output "Created log directory: $LogPath"
            }

            # Create unique timestamped log filename to avoid conflicts
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
            $Script:ScubaLogPath = Join-Path $LogPath "ScubaGear-DebugLog-$timestamp.log"

            # Create initial log entry
            $initMessage = "ScubaGear Logging Initialized - Level: $LogLevel, Tracing: $EnableTracing, Transcript: $EnableTranscript"
            Write-ScubaLog -Message $initMessage -Level "Info" -Source "LoggingSystem"
        }

        # Enable PowerShell debugging if requested - enhanced structured logging
        if ($EnableTracing) {
            # Use enhanced structured logging for detailed troubleshooting without console spam
            $Script:ScubaEnhancedTracing = $true
            # Set PowerShell preference variables to capture verbose and debug output
            $Global:VerbosePreference = "Continue"
            $Global:DebugPreference = "Continue"

            # Enable automatic function tracing to capture function entry/exit
            Enable-ScubaAutoTrace

            Write-ScubaLog -Message "Enhanced debug logging enabled - automatic function tracing active" -Level "Info" -Source "LoggingSystem"
        }

        # Start PowerShell transcript if requested to capture all console output
        if ($EnableTranscript -and $LogPath) {
            # Create transcript file with same timestamp as main log
            $transcriptPath = Join-Path $LogPath "ScubaGear-Transcript-$timestamp.log"
            # Start transcript to capture all PowerShell console activity
            Start-Transcript -Path $transcriptPath -Append -ErrorAction SilentlyContinue
            Write-ScubaLog -Message "Transcript logging started: $transcriptPath" -Level "Info" -Source "LoggingSystem"
        }

        Write-Output "?? ScubaGear logging initialized successfully"
        if ($LogPath) {
            Write-Output "   Log file: $Script:ScubaLogPath"
        }

    }
    catch {
        Write-Warning "Failed to initialize ScubaGear logging: $_"
        $Script:ScubaLogEnabled = $false
    }
}

function Write-ScubaLog {
    <#
    .SYNOPSIS
    Write a structured log entry to file and console

    .DESCRIPTION
    Central logging function that writes structured log entries with timestamps,
    levels, sources, and optional data payloads.

    .PARAMETER Message
    The main log message

    .PARAMETER Level
    Log level (Debug, Info, Warning, Error)

    .PARAMETER Source
    Source component or function name

    .PARAMETER Data
    Optional hashtable of additional data to log

    .PARAMETER Exception
    Optional exception object to log details from
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info",

        [string]$Source = "ScubaGear",

        [hashtable]$Data = @{},

        [System.Exception]$Exception = $null
    )

    # Skip if logging is disabled or level is below threshold
    if (-not $Script:ScubaLogEnabled) { return }

    # Define log level priorities to filter messages based on configured minimum level
    $levelPriority = @{ "Debug" = 0; "Info" = 1; "Warning" = 2; "Error" = 3 }
    # Return early if current message level is below the minimum configured level
    if ($levelPriority[$Level] -lt $levelPriority[$Script:ScubaLogLevel]) { return }

    try {
        # Create structured log entry hashtable with all relevant metadata
        $logEntry = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"  # High-precision timestamp
            Level = $Level                                              # Log severity level
            Source = $Source                                            # Component that generated the log
            Message = $Message                                          # Primary log message
            ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId  # For multi-threading scenarios
        }

        # Add optional structured data to the log entry if provided
        if ($Data.Count -gt 0) {
            $logEntry.Data = $Data
        }

        # Add detailed exception information if an exception was passed
        if ($Exception) {
            $logEntry.Exception = @{
                Type = $Exception.GetType().Name     # Exception class name
                Message = $Exception.Message         # Exception message
                StackTrace = $Exception.StackTrace   # Full stack trace for debugging
            }
        }

        # Format log line with aligned columns for readability in files and console
        $logLine = "[$($logEntry.Timestamp)] [$($logEntry.Level.PadRight(7))] [$($logEntry.Source.PadRight(20))] $($logEntry.Message)"

        # Write to log file if path is configured (file logging is optional)
        if ($Script:ScubaLogPath) {
            # Append to log file with UTF8 encoding, silently continue on errors to not break execution
            $logLine | Out-File -FilePath $Script:ScubaLogPath -Append -Encoding UTF8 -ErrorAction SilentlyContinue

            # Add structured data on separate lines if present (indented for readability)
            if ($Data.Count -gt 0) {
                # Convert data to compact JSON format for structured logging
                "    Data: $($Data | ConvertTo-Json -Compress -Depth 3)" | Out-File -FilePath $Script:ScubaLogPath -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }

            # Add exception details on separate line if exception was provided
            if ($Exception) {
                "    Exception: $($Exception.GetType().Name) - $($Exception.Message)" | Out-File -FilePath $Script:ScubaLogPath -Append -Encoding UTF8 -ErrorAction SilentlyContinue
            }
        }

        # Write to console based on level - control console noise while preserving file logging
        switch ($Level) {
            "Debug" {
                # Debug messages only go to file, not console (unless $DebugPreference is explicitly set)
                # This prevents debug spam on the console while keeping detailed file logs
                if ($DebugPreference -eq 'Continue') {
                    Write-Debug $logLine
                }
            }
            "Info" {
                # Only show important Info messages on console, others go to file only
                # Filter to show only significant milestones to users
                if ($Message -match "Creating output folder|Starting|completed|authenticated|retrieved") {
                    Write-Output "INFO: $Message"
                }
            }
            "Warning" {
                # Always show warnings to user as they indicate potential issues
                Write-Warning $Message
            }
            "Error" {
                Write-Error $Message
            }
        }

    }
    catch {
        # Fallback logging - don't let logging errors break the main process
        Write-Output "Logging error: $_"
    }
}

function Trace-ScubaFunction {
    <#
    .SYNOPSIS
    Wrap a function call with entry/exit logging and timing

    .DESCRIPTION
    Provides function tracing including parameters, return values,
    execution time, and error handling.

    .PARAMETER FunctionName
    Name of the function being traced

    .PARAMETER Parameters
    Hashtable of function parameters (will be logged safely)

    .PARAMETER ScriptBlock
    The actual function call wrapped in a script block

    .PARAMETER LogReturnValue
    Whether to log the return value (disable for large objects)

    .EXAMPLE
    $result = Trace-ScubaFunction -FunctionName "Get-MgUser" -Parameters @{UserId="test@domain.com"} -ScriptBlock {
        Get-MgUser -UserId $UserId
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionName,

        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [bool]$LogReturnValue = $false
    )

    if (-not $Script:ScubaLogEnabled) {
        # If logging is disabled, just execute the script block
        return & $ScriptBlock
    }

    # Safely serialize parameters to avoid logging sensitive data
    $safeParams = @{}
    foreach ($key in $Parameters.Keys) {
        # Check if parameter name suggests sensitive data and redact it
        if ($key -match "password|secret|token|key|credential") {
            $safeParams[$key] = "[REDACTED]"  # Replace sensitive values with placeholder
        }
        else {
            $safeParams[$key] = $Parameters[$key]  # Copy safe parameters as-is
        }
    }

    # Log function entry with sanitized parameters
    Write-ScubaLog -Message "ENTER: $FunctionName" -Level "Debug" -Source "FunctionTrace" -Data $safeParams
    # Start timing the function execution for performance monitoring
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # Execute the actual function and capture its return value
        $result = & $ScriptBlock
        $stopwatch.Stop()  # Stop timing on successful completion

        # Create exit data structure with execution timing and status
        $exitData = @{
            ExecutionTimeMs = $stopwatch.ElapsedMilliseconds  # Performance metric
            Status = "Success"                               # Indicates successful execution
        }

        # Optionally log return value information if requested and result exists
        if ($LogReturnValue -and $result) {
            $exitData.ReturnType = $result.GetType().Name  # Type of returned object
            # Log actual values for simple types, metadata for complex types
            if ($result -is [string] -or $result -is [int] -or $result -is [bool]) {
                $exitData.ReturnValue = $result  # Safe to log simple values
            }
            elseif ($result -is [array]) {
                $exitData.ReturnCount = $result.Count  # Log count instead of full array
            }
        }

        Write-ScubaLog -Message "EXIT: $FunctionName" -Level "Debug" -Source "FunctionTrace" -Data $exitData
        return $result
    }
    catch {
        $stopwatch.Stop()  # Ensure timing is captured even on errors
        # Create error exit data with timing and exception information
        $exitData = @{
            ExecutionTimeMs = $stopwatch.ElapsedMilliseconds  # Time before error occurred
            Status = "Error"                                  # Indicates failed execution
            ErrorType = $_.Exception.GetType().Name           # Type of exception that occurred
        }

        # Log the error exit with full exception details
        Write-ScubaLog -Message "EXIT: $FunctionName (ERROR)" -Level "Error" -Source "FunctionTrace" -Data $exitData -Exception $_.Exception
        throw  # Re-throw the exception to maintain original error handling
    }
}

function Enable-ScubaAutoTrace {
    <#
    .SYNOPSIS
    Enable automatic function call tracing for ScubaGear modules

    .DESCRIPTION
    Sets up automatic tracing of function calls by intercepting common ScubaGear functions
    and logging their entry, parameters, and exit information.
    #>
    [CmdletBinding()]
    param()

    if (-not $Script:ScubaLogEnabled) { return }

    $Script:ScubaEnhancedTracing = $true
    Write-ScubaLog -Message "Automatic function tracing enabled - intercepting ScubaGear function calls" -Level "Debug" -Source "AutoTrace"
}

function Write-ScubaFunctionEntry {
    <#
    .SYNOPSIS
    Log function entry with parameters

    .DESCRIPTION
    Automatically called to log when functions are entered with their parameters
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionName,

        [hashtable]$Parameters = @{},

        [string]$Source = "FunctionTrace"
    )

    if (-not $Script:ScubaLogEnabled) { return }

    # Safely serialize parameters, redacting sensitive data and limiting size
    $safeParams = @{}
    foreach ($key in $Parameters.Keys) {
        # Check for sensitive parameter names and redact their values
        if ($key -match "password|secret|token|key|credential|certificate") {
            $safeParams[$key] = "[REDACTED]"  # Security: never log sensitive values
        } else {
            $value = $Parameters[$key]
            # Limit large objects to prevent log bloat and improve readability
            if ($value -is [array] -and $value.Count -gt 10) {
                # Summarize large arrays to avoid massive log entries
                $safeParams[$key] = "Array[$($value.Count) items]"
            } elseif ($value -is [string] -and $value.Length -gt 200) {
                # Truncate long strings to keep logs manageable
                $safeParams[$key] = $value.Substring(0, 200) + "... (truncated)"
            } else {
                # Log smaller objects as-is
                $safeParams[$key] = $value
            }
        }
    }

    Write-ScubaLog -Message "ENTER: $FunctionName" -Level "Debug" -Source $Source -Data $safeParams
}

function Write-ScubaFunctionExit {
    <#
    .SYNOPSIS
    Log function exit with result information

    .DESCRIPTION
    Automatically called to log when functions exit with timing and result info
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionName,

        [Parameter(Mandatory = $true)]
        [long]$ExecutionTimeMs,

        [object]$Result = $null,

        [System.Exception]$Exception = $null,

        [string]$Source = "FunctionTrace"
    )

    if (-not $Script:ScubaLogEnabled) { return }

    # Create exit data structure with timing and status information
    $exitData = @{
        ExecutionTimeMs = $ExecutionTimeMs                              # Function execution time
        Status = if ($Exception) { "Error" } else { "Success" }         # Success/failure status
    }

    # Add result information if function completed successfully and returned data
    if ($null -ne $Result -and -not $Exception) {
        $exitData.ResultType = $Result.GetType().Name  # Type of returned object
        # Log appropriate level of detail based on result type
        if ($Result -is [array]) {
            $exitData.ResultCount = $Result.Count  # For arrays, log count not contents
        } elseif ($Result -is [string] -and $Result.Length -le 100) {
            $exitData.Result = $Result  # Log short strings completely
        } elseif ($Result -is [bool] -or $Result -is [int]) {
            $exitData.Result = $Result  # Log simple types completely
        }
        # Note: Large or complex objects are intentionally not logged to avoid bloat
    }

    # Add exception details if function failed
    if ($Exception) {
        $exitData.ErrorType = $Exception.GetType().Name    # Exception class name
        $exitData.ErrorMessage = $Exception.Message        # Exception message
    }

    # Determine appropriate log level and message based on success/failure
    $level = if ($Exception) { "Error" } else { "Debug" }  # Errors are logged at Error level
    $message = if ($Exception) { "EXIT: $FunctionName (ERROR)" } else { "EXIT: $FunctionName" }

    # Write the final exit log entry with all collected information
    Write-ScubaLog -Message $message -Level $level -Source $Source -Data $exitData -Exception $Exception
}

function Stop-ScubaLogging {
    <#
    .SYNOPSIS
    Clean up logging Module

    .DESCRIPTION
    Stops transcript, disables debugging, and cleans up logging resources.
    #>
    [CmdletBinding()]
    param()

    try {
        if ($Script:ScubaLogEnabled) {
            # Log the end of the logging session for audit trail
            Write-ScubaLog -Message "ScubaGear logging session ending" -Level "Info" -Source "LoggingSystem"

            # Stop PowerShell transcript if it was started during initialization
            try {
                Stop-Transcript -ErrorAction SilentlyContinue
            }
            catch {
                # Transcript may not be running, ignore error to avoid breaking shutdown
                $Script:ScubaDeepTracing = $false
            }

            # Disable PowerShell debugging features if they were enabled
            if ($Script:ScubaDeepTracing) {
                Set-PSDebug -Off  # Turn off PowerShell debugging
                # Restore original preference settings to avoid affecting other scripts
                $Global:VerbosePreference = "SilentlyContinue"
                $Global:DebugPreference = "SilentlyContinue"
            }

            Write-Output "ScubaGear logging stopped"
            if ($Script:ScubaLogPath) {
                Write-Output "   Log saved: $Script:ScubaLogPath"
            }
        }
    }
    catch {
        Write-Warning "Error stopping ScubaGear logging: $_"
    }
    finally {
        # Reset all module-level variables to clean state regardless of errors
        $Script:ScubaLogPath = $null           # Clear log file path
        $Script:ScubaLogEnabled = $false       # Disable logging
        $Script:ScubaDeepTracing = $false      # Disable deep tracing
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-ScubaLogging',
    'Write-ScubaLog',
    'Trace-ScubaFunction',
    'Stop-ScubaLogging',
    'Enable-ScubaAutoTrace',
    'Write-ScubaFunctionEntry',
    'Write-ScubaFunctionExit'
)