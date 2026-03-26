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
1. INITIALIZATION: Initialize-ScubaLogging sets up the logging system with configurable paths,
   log levels, tracing options, and transcript recording.

2. STRUCTURED LOGGING: Write-ScubaLog provides centralized logging with structured data support,
   automatic console/file output routing, and sensitive data protection.

3. FUNCTION TRACING: Trace-ScubaFunction wraps function calls to automatically log entry/exit,
   parameters, return values, execution timing, and error handling.

4. AUTOMATIC TRACING: Enable-ScubaAutoTrace provides transparent function interception for
   detailed debugging without manual instrumentation.

5. CLEANUP: Stop-ScubaLogging properly shuts down logging, stops transcripts, and resets state.
#>

# Module-level state variables — these drive the behavior of every logging function in this module.
# Initialize-ScubaLogging populates them; Stop-ScubaLogging resets them to these defaults.
# All public functions check $Script:ScubaLogEnabled first and return immediately when it is $false.
# Debug logs are always created by InvokeScuba; transcript logging is optional via -Transcript parameter.
$Script:ScubaLogPath = $null          # Absolute path to the active log file; $null disables file output
$Script:ScubaLogEnabled = $false      # Master on/off switch checked by Write-ScubaLog and Trace-ScubaFunction
$Script:ScubaDeepTracing = $false     # When $true, sets global VerbosePreference/DebugPreference and calls Set-PSDebug
$Script:ScubaLogLevel = "Info"        # Minimum severity threshold; messages below this level are silently dropped
$Script:ScubaEnhancedTracing = $false # Tracks whether Enable-ScubaAutoTrace has been called this session
$Script:ScubaHasErrors = $false       # Tracks if any Error or Warning messages were logged during the session
$Script:ScubaAutoReportEnabled = $true # Enable automatic debug report generation on errors (disable for testing)

function Initialize-ScubaLogging {
    <#
    .SYNOPSIS
    Initialize the ScubaGear logging system

    .DESCRIPTION
    Sets up logging for ScubaGear with configurable output paths,
    transcript recording, and PowerShell debugging features.

    .PARAMETER LogPath
    Directory where log files will be created. If not provided, logging to files is disabled.

    .PARAMETER EnableTracing
    Enable deep function tracing using PowerShell's built-in debugging features.

    .PARAMETER LogLevel
    Minimum log level to capture (Debug, Info, Warning, Error)

    .PARAMETER Transcript
    Enable Start-Transcript for complete console output capture

    .PARAMETER DisableAutoReport
    Disable automatic debug report generation on errors (useful for testing)

    .EXAMPLE
    Initialize-ScubaLogging -LogPath "C:\Logs\ScubaGear" -EnableTracing -Transcript
    #>
    [CmdletBinding()]
    param(
        [string]$LogPath = $null,
        [switch]$EnableTracing,
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$LogLevel = "Info",
        [switch]$Transcript,
        [switch]$DisableAutoReport
    )

    try {
        # Set module-level configuration variables to control logging behavior
        $Script:ScubaLogEnabled = $true
        $Script:ScubaDeepTracing = $EnableTracing
        $Script:ScubaLogLevel = $LogLevel
        $Script:ScubaHasErrors = $false  # Reset error tracking for new session
        $Script:ScubaAutoReportEnabled = -not $DisableAutoReport  # Control automatic report generation

        # Setup log directory and file path with timestamp
        if ($LogPath) {
            # Create the log directory if it doesn't exist
            if (!(Test-Path $LogPath)) {
                New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
            }

            # Create unique timestamped log filename to avoid conflicts
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
            $Script:ScubaLogPath = Join-Path $LogPath "ScubaGear-DebugLog-$timestamp.log"

            # Create initial log entry
            $initMessage = "ScubaGear Logging Initialized - Level: $LogLevel, Tracing: $EnableTracing, Transcript: $Transcript"
            Write-ScubaLog -Message $initMessage -Level "Info" -Source "LoggingSystem"
        }

        # Enable PowerShell debugging if requested - enhanced structured logging
        if ($EnableTracing) {
            # Use enhanced structured logging for detailed troubleshooting without console spam
            $Script:ScubaEnhancedTracing = $true
            # DO NOT set global VerbosePreference or DebugPreference to "Continue"
            # as that causes ALL cmdlet verbose/debug output to appear on console.
            # Instead, all debug/verbose messages go ONLY to the log file.

            # Enable automatic function tracing to capture function entry/exit
            Enable-ScubaAutoTrace

            Write-ScubaLog -Message "Enhanced debug logging enabled - automatic function tracing active" -Level "Info" -Source "LoggingSystem"
        }

        # Start PowerShell transcript if requested to capture all console output
        if ($Transcript -and $LogPath) {
            # When transcript is enabled, use GLOBAL scope for VerbosePreference/DebugPreference
            # so that cmdlets from ALL modules will output verbose/debug to the transcript.
            # We clean this up in Stop-ScubaLogging to avoid polluting the session.
            $Script:ScubaDeepTracing = $true
            $Global:VerbosePreference = "Continue"
            $Global:DebugPreference = "Continue"

            # Create transcript file with same timestamp as main log
            $transcriptPath = Join-Path $LogPath "ScubaGear-Transcript-$timestamp.log"
            # Start transcript to capture all PowerShell console activity
            Start-Transcript -Path $transcriptPath -Append -ErrorAction SilentlyContinue
            Write-ScubaLog -Message "Transcript logging started: $transcriptPath (verbose/debug output enabled globally)" -Level "Info" -Source "LoggingSystem"
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

    # Track if errors or warnings occurred during this session
    if ($Level -in @('Warning', 'Error')) {
        $Script:ScubaHasErrors = $true
    }

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
                # Debug messages only go to console when transcript is enabled (ScubaDeepTracing = true)
                # This allows transcript to capture verbose/debug output while keeping console clean otherwise
                if ($Script:ScubaDeepTracing -and $Script:DebugPreference -eq 'Continue') {
                    Write-Debug $logLine
                }
            }
            "Info" {
                # Info messages are intentionally filtered on the console to avoid drowning normal
                # ScubaGear output in logging noise.  Only high-level phase milestones (e.g. "Starting",
                # "completed") are shown to the user; every Info message still appears in the log file
                # regardless of this filter, so nothing is lost for troubleshooting.
                if ($Message -match "Creating output folder|Starting|completed|authenticated|retrieved") {
                    Write-Output "INFO: $Message"
                }
            }
            "Warning" {
                # Always show warnings to user as they indicate potential issues
                Write-Warning $Message
            }
            "Error" {
                # Use WriteErrorLine instead of Write-Error to avoid terminating execution
                # This preserves error visibility while allowing the finally block to run
                try {
                    $Host.UI.WriteErrorLine("ERROR: $Message")
                }
                catch {
                    # Fallback if WriteErrorLine is not available
                    Write-Warning "ERROR: $Message"
                }
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

    # Set the module-level flag so that Trace-ScubaFunction calls in the Orchestrator know
    # to emit ENTER/EXIT log lines.  PowerShell does not expose a general hook for intercepting
    # arbitrary function calls, so "auto" tracing in this module means the Orchestrator wraps
    # each major call site in Trace-ScubaFunction rather than hooking at the PS engine level.
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
    Clean up logging system

    .DESCRIPTION
    Stops transcript, disables debugging, and cleans up logging resources.
    #>
    [CmdletBinding()]
    param()

    # Shutdown order matters here:
    #   1. Write the final log entry BEFORE disabling logging so it actually appears in the file.
    #   2. Stop the transcript BEFORE resetting state variables so the transcript captures the final entry.
    #   3. Turn off PS debugging BEFORE resetting state so we don't leave verbose/debug preferences
    #      set globally, which would affect any subsequent PowerShell commands in the same session.
    #   4. Reset all state variables last, in the 'finally' block, to guarantee cleanup even on error.
    try {
        if ($Script:ScubaLogEnabled) {
            # Log the end of the logging session for audit trail
            Write-ScubaLog -Message "ScubaGear logging session ending" -Level "Info" -Source "LoggingSystem"

            # Stop PowerShell transcript if it was started during initialization
            try {
                Stop-Transcript -ErrorAction SilentlyContinue
            }
            catch {
                # Transcript may not be running; suppress the error and continue cleanup
                $Script:ScubaDeepTracing = $false
            }

            # Disable PowerShell debugging features if they were enabled.
            # Reset Global preferences to clean up after transcript logging
            if ($Script:ScubaDeepTracing) {
                Set-PSDebug -Off
                $Global:VerbosePreference = "SilentlyContinue"
                $Global:DebugPreference = "SilentlyContinue"
            }

            # Auto-generate debug report if errors or warnings were logged and auto-report is enabled
            if ($Script:ScubaHasErrors -and $Script:ScubaLogPath -and $Script:ScubaAutoReportEnabled) {
                try {
                    $Host.UI.WriteErrorLine("Errors detected! Generating debug report...")
                    $logDir = Split-Path $Script:ScubaLogPath -Parent
                    $reportPath = Join-Path $logDir "ScubaGear-DebugLog-ErrorReport.md"

                    # Generate the debug report
                    $null = Get-ScubaDebugLogReport -DebugLogPath $Script:ScubaLogPath -OutputPath $reportPath

                    $Host.UI.WriteErrorLine("   Debug report saved: $reportPath")
                    $Host.UI.WriteErrorLine("   It is recommended to include this report when opening a GitHub issue.")
                }
                catch {
                    Write-Warning "Failed to generate automatic debug report: $_"
                }
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
        $Script:ScubaHasErrors = $false        # Reset error tracking
        $Script:ScubaAutoReportEnabled = $true # Reset auto-report to default enabled state
    }
}

function Get-ScubaRunDetails {
    <#
    .SYNOPSIS
    Capture ScubaGear runtime diagnostic information

    .DESCRIPTION
    Collects detailed diagnostic information about the current system, PowerShell environment,
    ScubaGear installation, dependency modules, network connectivity, and runtime state.
    All information is logged using Write-ScubaLog for troubleshooting and debugging.

    This function captures:
    - System OS and build information
    - PowerShell version details
    - Current ScubaGear version(s) installed
    - Dependency modules (excluding System32 folder)
    - OPA executable information
    - Network connectivity status
    - Current command invocation details
    - Loaded modules in memory
    - Recent PowerShell errors

    .PARAMETER IncludeLoadedModules
    Include detailed information about all PowerShell modules currently loaded in memory.
    This shows which modules were successfully imported before any potential failure.

    .PARAMETER IncludeErrors
    Include the most recent PowerShell errors from the $Error automatic variable.
    Useful for diagnosing what went wrong during a failed ScubaGear run.

    .EXAMPLE
    Get-ScubaRunDetails
    Collect basic diagnostic information about the current ScubaGear environment.

    .EXAMPLE
    Get-ScubaRunDetails -IncludeLoadedModules -IncludeErrors
    Collect diagnostic information including loaded modules and recent errors.

    .NOTES
    This function replaces the old Debug-SCuBA function with a more focused and
    logging-integrated approach that doesn't just dump module lists but provides
    targeted diagnostic information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeLoadedModules,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeErrors,

        [Parameter(Mandatory = $false)]
        [string]$ConfiguredOPAPath
    )

    try {
        # 1. System OS and Build Information
        Write-ScubaLog -Message "Collecting system OS information..." -Level "Debug" -Source "RunDetails"
        try {
            $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($osInfo) {
                $osData = @{
                    OS = $osInfo.Caption
                    Version = $osInfo.Version
                    Build = $osInfo.BuildNumber
                    Architecture = $osInfo.OSArchitecture
                    InstallDate = $osInfo.InstallDate.ToString()
                    LastBootUpTime = $osInfo.LastBootUpTime.ToString()
                }
                Write-ScubaLog -Message "System OS Information captured" -Level "Info" -Source "RunDetails" -Data $osData
            }
        }
        catch {
            Write-ScubaLog -Message "Failed to retrieve OS information: $($_.Exception.Message)" -Level "Warning" -Source "RunDetails"
        }

        # 2. PowerShell Version Information
        Write-ScubaLog -Message "Collecting PowerShell version information..." -Level "Debug" -Source "RunDetails"
        $psData = @{
            PSVersion = $PSVersionTable.PSVersion.ToString()
            PSEdition = $PSVersionTable.PSEdition
            CLRVersion = if ($PSVersionTable.CLRVersion) { $PSVersionTable.CLRVersion.ToString() } else { "N/A" }
            BuildVersion = if ($PSVersionTable.BuildVersion) { $PSVersionTable.BuildVersion.ToString() } else { "N/A" }
            WSManStackVersion = if ($PSVersionTable.WSManStackVersion) { $PSVersionTable.WSManStackVersion.ToString() } else { "N/A" }
            PSRemotingProtocolVersion = if ($PSVersionTable.PSRemotingProtocolVersion) { $PSVersionTable.PSRemotingProtocolVersion.ToString() } else { "N/A" }
        }
        Write-ScubaLog -Message "PowerShell Version Information captured" -Level "Info" -Source "RunDetails" -Data $psData

        # 3. Current ScubaGear Version(s) Installed
        Write-ScubaLog -Message "Collecting ScubaGear version information..." -Level "Debug" -Source "RunDetails"
        try {
            # First, check for the currently loaded module (will exist since we're running from it)
            $currentScuba = Get-Module ScubaGear | Select-Object -First 1

            # Then check for installed versions (may be empty for GitHub clones not in PSModulePath)
            $scubaModules = Get-Module ScubaGear -ListAvailable -ErrorAction SilentlyContinue

            # Build the data structure - use loaded module info as fallback
            $scubaData = @{}

            # Current loaded version (always available since we're running from ScubaGear)
            if ($currentScuba) {
                $scubaData.CurrentLoadedVersion = $currentScuba.Version.ToString()
                $scubaData.CurrentModulePath = $currentScuba.ModuleBase
            }
            else {
                $scubaData.CurrentLoadedVersion = "Unknown"
                $scubaData.CurrentModulePath = "N/A"
            }

            # Installed versions (may be empty for dev/GitHub installs)
            if ($scubaModules) {
                $scubaData.InstalledVersions = ($scubaModules | ForEach-Object { $_.Version.ToString() }) -join ", "
                $scubaData.InstalledCount = $scubaModules.Count
                $scubaData.AllPaths = ($scubaModules | ForEach-Object { $_.ModuleBase }) -join "; "
            }
            else {
                $scubaData.InstalledVersions = "Not in PSModulePath"
                $scubaData.InstalledCount = 0
                $scubaData.AllPaths = "N/A"
            }

            # Determine install source: Install-Module (PSGallery) always writes PSGetModuleInfo.xml;
            # a GitHub clone or manual copy does not. This is informational only.
            if ($currentScuba) {
                $psGetInfoPath = Join-Path $currentScuba.ModuleBase 'PSGetModuleInfo.xml'
                if (Test-Path $psGetInfoPath) {
                    try {
                        $psGetInfo = Import-Clixml -Path $psGetInfoPath -ErrorAction Stop
                        $scubaData.InstallSource     = 'PowerShell Gallery'
                        $scubaData.GalleryVersion    = if ($psGetInfo.Version)       { $psGetInfo.Version.ToString() }              else { 'N/A' }
                        $scubaData.PublishedDate     = if ($psGetInfo.PublishedDate)  { $psGetInfo.PublishedDate.ToString('yyyy-MM-dd') } else { 'N/A' }
                        $scubaData.InstalledDate     = if ($psGetInfo.InstalledDate)  { $psGetInfo.InstalledDate.ToString('yyyy-MM-dd') } else { 'N/A' }
                        $scubaData.GalleryRepository = if ($psGetInfo.Repository)     { $psGetInfo.Repository }                      else { 'N/A' }
                    }
                    catch {
                        $scubaData.InstallSource = "PowerShell Gallery (metadata unreadable)"
                    }
                }
                else {
                    # No PSGetModuleInfo.xml — module was cloned from GitHub or loaded from a dev folder
                    $scubaData.InstallSource = 'Development / GitHub clone'
                }
            }
            else {
                $scubaData.InstallSource = 'Unknown'
            }

            Write-ScubaLog -Message "ScubaGear Version Information captured" -Level "Info" -Source "RunDetails" -Data $scubaData
        }
        catch {
            Write-ScubaLog -Message "Failed to retrieve ScubaGear version: $($_.Exception.Message)" -Level "Warning" -Source "RunDetails"
        }

        # 4. Dependency Modules (Program Files and User Profile, excluding System32)
        Write-ScubaLog -Message "Collecting PowerShell module information..." -Level "Debug" -Source "RunDetails"
        try {
            $programFilesPath = [Environment]::GetFolderPath('ProgramFiles')
            $userProfilePath = $env:USERPROFILE

            # Get modules from Program Files and User Profile only, excluding System32
            $dependencies = Get-Module -ListAvailable | Where-Object {
                $modulePath = $_.ModuleBase
                ($modulePath -like "$programFilesPath*" -or $modulePath -like "$userProfilePath*") -and
                $modulePath -notlike "*System32*" -and
                $modulePath -notlike "*syswow64*"
            }

            # Group by module name to get unique modules with their versions
            $uniqueModules = $dependencies | Group-Object Name | ForEach-Object {
                $module = $_.Group | Sort-Object Version -Descending | Select-Object -First 1
                "$($module.Name) ($($module.Version))"
            }

            $depData = @{
                TotalModulesFound = $dependencies.Count
                UniqueModules = ($dependencies | Select-Object Name -Unique).Count
                TopModules = ($uniqueModules | Select-Object -First 20) -join "; "
            }
            Write-ScubaLog -Message "PowerShell modules captured (excluding System32)" -Level "Info" -Source "RunDetails" -Data $depData

            # Log ScubaGear dependencies by reading from RequiredVersions.ps1
            $requiredVersionsPath = Join-Path $PSScriptRoot "..\..\RequiredVersions.ps1"
            $knownDependencyNames = @()

            if (Test-Path $requiredVersionsPath) {
                try {
                    $ModuleList = $null
                    . $requiredVersionsPath
                    if ($ModuleList) {
                        $knownDependencyNames = $ModuleList | ForEach-Object { $_['ModuleName'] }
                        Write-ScubaLog -Message "Loaded $($knownDependencyNames.Count) required dependencies from RequiredVersions.ps1" -Level "Debug" -Source "RunDetails"
                    }
                    else {
                        Write-ScubaLog -Message "RequiredVersions.ps1 found but `$ModuleList is empty or null" -Level "Error" -Source "RunDetails"
                    }
                }
                catch {
                    Write-ScubaLog -Message "Failed to read RequiredVersions.ps1: $($_.Exception.Message)" -Level "Error" -Source "RunDetails" -Exception $_.Exception
                }
            }
            else {
                Write-ScubaLog -Message "RequiredVersions.ps1 not found at: $requiredVersionsPath" -Level "Error" -Source "RunDetails"
            }

            # Log each required ScubaGear dependency specifically
            if ($knownDependencyNames.Count -gt 0) {
                foreach ($depName in $knownDependencyNames) {
                    $depModule = $dependencies | Where-Object { $_.Name -eq $depName } | Sort-Object Version -Descending | Select-Object -First 1
                    if ($depModule) {
                        $criticalDepData = @{
                            Module = $depName
                            Version = $depModule.Version.ToString()
                            Path = $depModule.ModuleBase
                        }
                        Write-ScubaLog -Message "Required dependency: $depName" -Level "Debug" -Source "RunDetails" -Data $criticalDepData
                    }
                    else {
                        Write-ScubaLog -Message "Required dependency NOT FOUND: $depName" -Level "Warning" -Source "RunDetails"
                    }
                }
            }
            else {
                Write-ScubaLog -Message "No required dependencies loaded from RequiredVersions.ps1 - cannot verify ScubaGear dependencies" -Level "Error" -Source "RunDetails"
            }
        }
        catch {
            Write-ScubaLog -Message "Failed to retrieve dependency modules: $($_.Exception.Message)" -Level "Warning" -Source "RunDetails"
        }

        # 5. OPA Executable Information
        Write-ScubaLog -Message "Collecting OPA executable information..." -Level "Debug" -Source "RunDetails"
        try {
            $scubaDefaultPath = Join-Path -Path $env:USERPROFILE -ChildPath '.scubagear'
            $scubaTools = Join-Path -Path $scubaDefaultPath -ChildPath 'Tools'

            if (Test-Path $scubaTools) {
                $opaFiles = Get-ChildItem -Path $scubaTools -Filter "opa*" -ErrorAction SilentlyContinue
                if ($opaFiles) {
                    foreach ($opaFile in $opaFiles) {
                        $opaData = @{
                            FileName = $opaFile.Name
                            Path = $opaFile.FullName
                            SizeMB = [math]::Round($opaFile.Length / 1MB, 2)
                            LastModified = $opaFile.LastWriteTime.ToString()
                            Attributes = $opaFile.Attributes.ToString()
                        }

                        # Try to get OPA version by executing it
                        try {
                            $opaVersionOutput = & $opaFile.FullName version 2>&1
                            if ($opaVersionOutput) {
                                $opaData.Version = ($opaVersionOutput | Select-Object -First 1).ToString()
                            }
                        }
                        catch {
                            $opaData.Version = "Unable to determine"
                        }

                        Write-ScubaLog -Message "OPA Executable found: $($opaFile.Name)" -Level "Info" -Source "RunDetails" -Data $opaData
                    }
                }
                else {
                    Write-ScubaLog -Message "No OPA executable found in $scubaTools" -Level "Warning" -Source "RunDetails"
                }
            }
            else {
                Write-ScubaLog -Message "ScubaGear Tools directory not found: $scubaTools" -Level "Warning" -Source "RunDetails"
            }
        }
        catch {
            Write-ScubaLog -Message "Failed to retrieve OPA information: $($_.Exception.Message)" -Level "Warning" -Source "RunDetails"
        }

        # 5b. Configured OPA Path (the path ScubaGear will actually use at runtime)
        # This may be overridden via -OPAPath on the command line or OPAPath in a YAML config file.
        # Checking it here (with access to the resolved ScubaConfig value) is the only reliable way
        # to detect a mismatch before the Rego evaluation fails.
        if ($ConfiguredOPAPath) {
            Write-ScubaLog -Message "Checking configured OPAPath..." -Level "Debug" -Source "RunDetails"
            try {
                # Resolve the configured path: ScubaGear appends the OPA binary name to OPAPath,
                # so check for any opa* file inside the directory (or the path itself if it is a file).
                $configuredData = @{ ConfiguredOPAPath = $ConfiguredOPAPath }

                if (Test-Path $ConfiguredOPAPath -PathType Leaf) {
                    # A full file path was provided
                    $opaItem = Get-Item $ConfiguredOPAPath -ErrorAction Stop
                    $configuredData.FoundAtConfiguredPath = $true
                    $configuredData.ResolvedPath          = $opaItem.FullName
                    $configuredData.SizeMB                = [math]::Round($opaItem.Length / 1MB, 2)
                    # Try to get OPA version by executing it
                    try {
                        $ver = & $opaItem.FullName version 2>&1
                        if ($ver) { $configuredData.Version = ($ver | Select-Object -First 1).ToString() }
                    } catch {
                        $configuredData.Version = "Unable to determine"
                    }
                    Write-ScubaLog -Message "OPA Executable at configured path" -Level "Info" -Source "RunDetails" -Data $configuredData
                }
                elseif (Test-Path $ConfiguredOPAPath -PathType Container) {
                    # A directory was provided — look for any opa* binary inside it
                    $opaFiles = Get-ChildItem -Path $ConfiguredOPAPath -Filter "opa*" -ErrorAction SilentlyContinue
                    if ($opaFiles) {
                        $opaItem = $opaFiles | Select-Object -First 1
                        $configuredData.FoundAtConfiguredPath = $true
                        $configuredData.ResolvedPath          = $opaItem.FullName
                        $configuredData.SizeMB                = [math]::Round($opaItem.Length / 1MB, 2)
                        try {
                            $ver = & $opaItem.FullName version 2>&1
                            if ($ver) { $configuredData.Version = ($ver | Select-Object -First 1).ToString() }
                        } catch {
                            $configuredData.Version = "Unable to determine"
                        }
                        Write-ScubaLog -Message "OPA Executable at configured path" -Level "Info" -Source "RunDetails" -Data $configuredData
                    }
                    else {
                        $configuredData.FoundAtConfiguredPath = $false
                        Write-ScubaLog -Message "OPA Executable NOT found at configured path" -Level "Warning" -Source "RunDetails" -Data $configuredData
                    }
                }
                else {
                    $configuredData.FoundAtConfiguredPath = $false
                    Write-ScubaLog -Message "OPA Executable NOT found at configured path" -Level "Warning" -Source "RunDetails" -Data $configuredData
                }
            }
            catch {
                Write-ScubaLog -Message "Failed to check configured OPAPath: $($_.Exception.Message)" -Level "Warning" -Source "RunDetails"
            }
        }

        # 6. Network Connectivity Status
        Write-ScubaLog -Message "Checking network connectivity..." -Level "Debug" -Source "RunDetails"
        try {
            $connectivityData = @{
                InternetConnected = $false
                DNSResolution = $false
                TestTarget = "www.microsoft.com"
            }

            # Test internet connectivity via HTTPS (port 443) rather than ICMP ping.
            # ICMP is blocked in many corporate environments, causing false "not connected" results.
            try {
                $testConnection = Test-NetConnection -ComputerName $connectivityData.TestTarget -Port 443 -InformationLevel Quiet -ErrorAction Stop -WarningAction SilentlyContinue
                $connectivityData.InternetConnected = $testConnection
            }
            catch {
                $connectivityData.InternetError = $_.Exception.Message
            }

            # Test DNS resolution
            try {
                $dnsTest = Resolve-DnsName $connectivityData.TestTarget -ErrorAction Stop
                $connectivityData.DNSResolution = $null -ne $dnsTest
                if ($dnsTest) {
                    # Resolve-DnsName returns IP4Address for A records and IP6Address for AAAA records;
                    # find the first A record and fall back to IP6Address if none exists
                    $aRecord = $dnsTest | Where-Object { $_.QueryType -eq 'A' } | Select-Object -First 1
                    $connectivityData.DNSResult = if ($aRecord) { $aRecord.IP4Address } else {
                        ($dnsTest | Where-Object { $_.IP6Address } | Select-Object -First 1).IP6Address
                    }
                }
            }
            catch {
                $connectivityData.DNSError = $_.Exception.Message
            }

            # Check for proxy settings
            # GetProxy() requires an absolute URI, so prefix the hostname with https://
            try {
                $proxySettings = [System.Net.WebRequest]::GetSystemWebProxy()
                $testUri       = [uri]"https://$($connectivityData.TestTarget)"
                $proxyUri      = $proxySettings.GetProxy($testUri)
                if ($proxyUri.Host -ne $connectivityData.TestTarget) {
                    $connectivityData.ProxyDetected = $true
                    $connectivityData.ProxyAddress = $proxyUri.ToString()
                }
                else {
                    $connectivityData.ProxyDetected = $false
                }
            }
            catch {
                $connectivityData.ProxyCheckError = $_.Exception.Message
            }

            Write-ScubaLog -Message "Network connectivity status captured" -Level "Info" -Source "RunDetails" -Data $connectivityData
        }
        catch {
            Write-ScubaLog -Message "Failed to check network connectivity: $($_.Exception.Message)" -Level "Warning" -Source "RunDetails"
        }

        # 7. Current Command/Invocation Details
        Write-ScubaLog -Message "Capturing current command invocation..." -Level "Debug" -Source "RunDetails"
        try {
            # Get the call stack to trace how we got here
            $callStack = Get-PSCallStack
            $caller = if ($callStack.Count -gt 1) { $callStack[1] } else { $callStack[0] }

            $invocationData = @{
                CurrentFunction = $MyInvocation.MyCommand.Name
                CalledFrom = $caller.Command
                ScriptName = if ($caller.ScriptName) { $caller.ScriptName } else { "Interactive" }
                ScriptLineNumber = $caller.ScriptLineNumber
                CommandLine = if ($MyInvocation.Line) { $MyInvocation.Line.Trim() } else { "N/A" }
                BoundParameters = if ($MyInvocation.BoundParameters.Count -gt 0) {
                    ($MyInvocation.BoundParameters.Keys | ForEach-Object { "$_=$($MyInvocation.BoundParameters[$_])" }) -join "; "
                } else {
                    "None"
                }
                WorkingDirectory = (Get-Location).Path
            }

            # Try to get the original ScubaGear command if available
            try {
                $history = Get-History -Count 10 -ErrorAction SilentlyContinue
                $scubaCommands = $history | Where-Object { $_.CommandLine -like "*InvokeScuba*" -or $_.CommandLine -like "*ScubaGear*" }
                if ($scubaCommands) {
                    $invocationData.RecentScubaCommands = ($scubaCommands | Select-Object -First 3 | ForEach-Object { $_.CommandLine }) -join " | "
                }
            }
            catch {
                # History not available, skip
                $invocationData.RecentScubaCommands = "N/A"
            }

            Write-ScubaLog -Message "Command invocation details captured" -Level "Info" -Source "RunDetails" -Data $invocationData
        }
        catch {
            Write-ScubaLog -Message "Failed to capture invocation details: $($_.Exception.Message)" -Level "Warning" -Source "RunDetails"
        }

        # 8. Currently Loaded Modules in Memory
        if ($IncludeLoadedModules) {
            Write-ScubaLog -Message "Collecting loaded modules from memory..." -Level "Debug" -Source "RunDetails"
            try {
                $loadedModules = Get-Module

                $loadedSummary = @{
                    TotalLoadedModules = $loadedModules.Count
                    ModuleNames = ($loadedModules | ForEach-Object { $_.Name }) -join ", "
                }
                Write-ScubaLog -Message "Loaded modules summary" -Level "Info" -Source "RunDetails" -Data $loadedSummary

                # Log each loaded module with details
                Write-ScubaLog -Message "Detailed loaded module information:" -Level "Debug" -Source "RunDetails"
                foreach ($module in $loadedModules) {
                    $moduleDetail = @{
                        Name = $module.Name
                        Version = $module.Version.ToString()
                        Path = if ($module.Path) { $module.Path } else { "N/A" }
                        ModuleType = $module.ModuleType.ToString()
                    }
                    Write-ScubaLog -Message "Loaded module: $($module.Name)" -Level "Debug" -Source "RunDetails" -Data $moduleDetail
                }

                # Specifically check for ScubaGear-related modules by reading RequiredVersions.ps1
                $requiredVersionsPath = Join-Path $PSScriptRoot "..\..\RequiredVersions.ps1"
                $knownDependencyNames = @()
                if (Test-Path $requiredVersionsPath) {
                    $ModuleList = $null
                    . $requiredVersionsPath
                    if ($ModuleList) {
                        $knownDependencyNames = $ModuleList | ForEach-Object { $_['ModuleName'] }
                    }
                }
                # Filter loaded modules to find those related to ScubaGear or known dependencies
                $scubaRelatedModules = $loadedModules | Where-Object {
                    $_.Name -like "*Scuba*" -or $_.Name -in $knownDependencyNames
                }

                if ($scubaRelatedModules) {
                    $relatedData = @{
                        Count       = $scubaRelatedModules.Count
                        Modules     = ($scubaRelatedModules | ForEach-Object { "$($_.Name) ($($_.Version))" }) -join "; "
                        # ModulePaths stores Name=Path pairs so the report can add a Path column to the table
                        ModulePaths = ($scubaRelatedModules | ForEach-Object { "$($_.Name)=$($_.ModuleBase)" }) -join "; "
                    }
                    Write-ScubaLog -Message "ScubaGear-related modules currently loaded in memory" -Level "Info" -Source "RunDetails" -Data $relatedData
                }
            }
            catch {
                Write-ScubaLog -Message "Failed to retrieve loaded modules: $($_.Exception.Message)" -Level "Warning" -Source "RunDetails"
            }
        }
        else {
            Write-ScubaLog -Message "Loaded modules collection skipped (use -IncludeLoadedModules to enable)" -Level "Debug" -Source "RunDetails"
        }

        # 9. Recent PowerShell Errors
        if ($IncludeErrors) {
            Write-ScubaLog -Message "Collecting recent PowerShell errors..." -Level "Debug" -Source "RunDetails"
            try {
                $recentErrors = $Error | Select-Object -First 10

                if ($recentErrors.Count -gt 0) {
                    Write-ScubaLog -Message "Found $($recentErrors.Count) recent error(s) in `$Error variable" -Level "Warning" -Source "RunDetails"

                    # Log each error with structured details, including exception message, type, category, target object, and stack trace (truncated
                    foreach ($err in $recentErrors) {
                        $errorData = @{
                            Message = $err.Exception.Message
                            Type = $err.Exception.GetType().Name
                            Category = $err.CategoryInfo.Category.ToString()
                            TargetObject = if ($err.TargetObject) { $err.TargetObject.ToString() } else { "N/A" }
                            FullyQualifiedErrorId = $err.FullyQualifiedErrorId
                            ScriptStackTrace = if ($err.ScriptStackTrace) {
                                # Truncate stack trace if too long
                                $trace = $err.ScriptStackTrace.ToString()
                                if ($trace.Length -gt 500) {
                                    $trace.Substring(0, 500) + "... (truncated)"
                                } else {
                                    $trace
                                }
                            } else {
                                "N/A"
                            }
                        }

                        # Determine error severity for logging
                        $errorLevel = if ($err.Exception -is [System.Management.Automation.MethodInvocationException] -or
                                          $err.Exception -is [System.InvalidOperationException]) {
                            "Error"
                        } else {
                            "Warning"
                        }

                        Write-ScubaLog -Message "PowerShell Error: $($err.Exception.Message)" -Level $errorLevel -Source "RunDetails" -Data $errorData -Exception $err.Exception
                    }
                }
                else {
                    Write-ScubaLog -Message "No recent errors found in `$Error variable" -Level "Info" -Source "RunDetails"
                }
            }
            catch {
                Write-ScubaLog -Message "Failed to retrieve error information: $($_.Exception.Message)" -Level "Warning" -Source "RunDetails"
            }
        }
        else {
            Write-ScubaLog -Message "Error collection skipped (use -IncludeErrors to enable)" -Level "Debug" -Source "RunDetails"
        }

        # 10. Capture module snapshot if IncludeLoadedModules is specified
        if ($IncludeLoadedModules) {
            Update-ScubaModuleSnapshot -SnapshotName "InitialLoad"
        }
    }
    catch {
        Write-ScubaLog -Message "Error during run details collection: $($_.Exception.Message)" -Level "Error" -Source "RunDetails" -Exception $_.Exception
        Write-Error "Failed to collect complete run details. Check logs for partial information."
    }
}

function Update-ScubaModuleSnapshot {
    <#
    .SYNOPSIS
    Capture a snapshot of currently loaded PowerShell modules

    .DESCRIPTION
    Captures which modules are currently loaded in memory and logs them with a timestamp.
    This function reads RequiredVersions.ps1 to identify what modules ScubaGear depends on,
    then captures the current state of those modules without hardcoding any module names.

    Can be called at any point during execution to track module loading progression
    (e.g., before authentication, after authentication, after provider execution).

    .PARAMETER SnapshotName
    Descriptive name for this snapshot (e.g., "PreAuthentication", "PostAuthentication", "PostProviderExecution")

    .EXAMPLE
    Update-ScubaModuleSnapshot -SnapshotName "PostAuthentication"
    Captures which required modules are loaded after authentication completes.

    .NOTES
    Uses the logging system to store snapshots - no global variables needed.
    Module requirements are read dynamically from RequiredVersions.ps1.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SnapshotName
    )

    try {
        Write-ScubaLog -Message "Capturing module snapshot: $SnapshotName" -Level "Debug" -Source "ModuleSnapshot"

        # Read required modules from RequiredVersions.ps1 dynamically
        $requiredVersionsPath = Join-Path $PSScriptRoot "..\..\RequiredVersions.ps1"
        $requiredModuleNames = @()

        if (Test-Path $requiredVersionsPath) {
            try {
                $ModuleList = $null
                . $requiredVersionsPath
                if ($ModuleList -and $ModuleList.Count -gt 0) {
                    $requiredModuleNames = $ModuleList | ForEach-Object { $_['ModuleName'] }
                    Write-ScubaLog -Message "Loaded $($requiredModuleNames.Count) module names from RequiredVersions.ps1" -Level "Debug" -Source "ModuleSnapshot"
                }
                else {
                    Write-ScubaLog -Message "RequiredVersions.ps1 has no module list - cannot identify required modules" -Level "Warning" -Source "ModuleSnapshot"
                    return
                }
            }
            catch {
                Write-ScubaLog -Message "Failed to read RequiredVersions.ps1: $($_.Exception.Message)" -Level "Warning" -Source "ModuleSnapshot"
                return
            }
        }
        else {
            Write-ScubaLog -Message "RequiredVersions.ps1 not found at: $requiredVersionsPath" -Level "Warning" -Source "ModuleSnapshot"
            return
        }

        # Get all currently loaded modules
        # Wrap in @() to ensure it's always an array, even with a single result, so .Count works correctly
        $loadedModules = @(Get-Module | Where-Object { $_.Name -in $requiredModuleNames -or $_.Name -eq 'ScubaGear' })

        if ($loadedModules.Count -gt 0) {
            # Build a structured list of loaded modules
            $moduleData = @{
                SnapshotName = $SnapshotName
                ModuleCount = $loadedModules.Count
                Modules = @()
                ModulePaths = @()
            }

            foreach ($module in $loadedModules) {
                $moduleInfo = "$($module.Name) ($($module.Version))"
                $moduleData.Modules += $moduleInfo
                $moduleData.ModulePaths += "$($module.Name)=$($module.ModuleBase)"
            }

            # Join arrays for logging
            $moduleData.ModuleSummary = $moduleData.Modules -join "; "
            $moduleData.ModulePathsSummary = $moduleData.ModulePaths -join "; "

            Write-ScubaLog -Message "Module snapshot '$SnapshotName' captured: $($loadedModules.Count) module(s)" -Level "Info" -Source "ModuleSnapshot" -Data $moduleData
        }
        else {
            Write-ScubaLog -Message "Module snapshot '$SnapshotName': No required modules loaded yet" -Level "Info" -Source "ModuleSnapshot" -Data @{
                SnapshotName = $SnapshotName
                ModuleCount = 0
            }
        }
    }
    catch {
        Write-ScubaLog -Message "Failed to capture module snapshot '$SnapshotName': $($_.Exception.Message)" -Level "Warning" -Source "ModuleSnapshot" -Exception $_.Exception
    }
}

function Get-ScubaDebugLogReport {
    <#
    .SYNOPSIS
    Parse a ScubaGear debug log file and produce a readable summary report.

    .DESCRIPTION
    Reads a ScubaGear-DebugLog-*.log file (produced by InvokeScuba) and transforms
    the structured log entries into a concise, human-readable Markdown report
    suitable for pasting into a GitHub issue or email.

    The transcript file is intentionally not parsed — only the structured debug log.

    The report includes:
    - Run summary  (command line, start time, products, environment)
    - System environment (OS, PowerShell version)
    - ScubaGear installation details (loaded vs installed version, mismatch warnings)
    - Key ScubaGear-related dependency versions found loaded in memory
    - OPA executable details
    - Network connectivity status
    - Phase timing (authentication, provider execution, Rego evaluation, report creation)
    - All Warning and Error log entries
    - A condensed run timeline showing Info-and-above milestones in chronological order

    .PARAMETER DebugLogPath
    Full path to the ScubaGear-DebugLog-*.log file to parse.

    .PARAMETER OutputPath
    Optional. If provided the Markdown report is also saved to this file path.

    .PARAMETER FromScubaCached
    Optional switch. Determines which orchestrator command was used (Invoke-SCuBA vs Invoke-SCuBACached).

    .PARAMETER PassThru
    Optional switch. When specified, the report is written to the pipeline (displayed on screen).
    Without this switch, the report is only saved to OutputPath if specified, with no console output.

    .EXAMPLE
    Get-ScubaDebugLogReport -LogPath "C:\Scuba\DebugLogs\ScubaGear-DebugLog-20260311-111827-956.log"

    .EXAMPLE
    Get-ScubaDebugLogReport `
        -LogPath   "C:\Scuba\DebugLogs\ScubaGear-DebugLog-20260311-111827-956.log" `
        -OutputPath "C:\Scuba\report.md"

    .EXAMPLE
    Get-ScubaDebugLogReport -LogPath "C:\Scuba\DebugLogs\ScubaGear-DebugLog-20260311-111827-956.log" -FromScubaCached

    .EXAMPLE
    Get-ScubaDebugLogReport -LogPath "C:\Scuba\DebugLogs\ScubaGear-DebugLog-20260311-111827-956.log" -OutputPath "C:\Scuba\report.md" -PassThru

    .FUNCTIONALITY
    Public
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
            if (-not (Test-Path $_ -PathType Leaf)) {
                throw "File not found: $_"
            }
            $fileName = Split-Path $_ -Leaf
            if ($fileName -like "*Transcript*") {
                throw "Invalid log file: This appears to be a transcript log. Please select the DebugLog file (ScubaGear-DebugLog-*.log), not the Transcript file (ScubaGear-Transcript-*.log)."
            }
            if ($fileName -notlike "*DebugLog*") {
                throw "Invalid log file: Expected a ScubaGear debug log file with 'DebugLog' in the name (e.g., ScubaGear-DebugLog-20260311-111827-956.log)."
            }
            $true
        })]
        [string]$DebugLogPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [switch]$FromScubaCached,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )


    if($FromScubaCached){
        $OrchestratorCommand = 'ScubaCached'
    }else{
        $OrchestratorCommand = 'InvokeScuba'
    }
    # -------------------------------------------------------------------------
    # Step 1 — Parse every log line into a structured object.
    #
    # Log line format produced by Write-ScubaLog:
    #   [yyyy-MM-dd HH:mm:ss.fff] [Level  ] [Source              ] Message text
    # Optionally followed by a Data line:
    #       Data: {"key":"value",...}
    # -------------------------------------------------------------------------
    $linePattern = '^\[(.+?)\] \[(.+?)\] \[(.+?)\] (.+)$'
    $dataPattern = '^\s+Data: (.+)$'

    $entries = [System.Collections.Generic.List[PSCustomObject]]::new()
    $current = $null

    foreach ($line in (Get-Content $DebugLogPath -Encoding UTF8)) {
        if ($line -match $linePattern) {
            if ($current) { $entries.Add($current) }
            $current = [PSCustomObject]@{
                Timestamp = $Matches[1].Trim()
                Level     = $Matches[2].Trim()
                Source    = $Matches[3].Trim()
                Message   = $Matches[4].Trim()
                Data      = $null
            }
        }
        elseif ($line -match $dataPattern -and $current) {
            # Attempt to parse the JSON data payload; fall back to raw string on failure
            try   { $current.Data = $Matches[1].Trim() | ConvertFrom-Json }
            catch { $current.Data = $Matches[1].Trim() }
        }
    }
    if ($current) { $entries.Add($current) }

    # -------------------------------------------------------------------------
    # Step 2 — Helper to find the first entry matching a source pattern and
    # a message regex.  Source uses -like so wildcards are supported.
    # -------------------------------------------------------------------------
    function Find-Entry ([string]$SourcePattern, [string]$MessagePattern) {
        $entries | Where-Object {
            $_.Source -like "*$SourcePattern*" -and $_.Message -match $MessagePattern
        } | Select-Object -First 1
    }

    # Small helper: convert milliseconds to a human-readable duration string
    function Format-Ms ([object]$ms) {
        if ($null -eq $ms) { return 'N/A' }
        $ms = [long]$ms
        if ($ms -lt 1000)  { return "$ms ms" }
        $secs = [math]::Round($ms / 1000, 1)
        if ($secs -lt 60)  { return "$secs s" }
        $mins = [math]::Floor($secs / 60)
        $remS = [math]::Round($secs % 60)
        return "${mins}m ${remS}s"
    }

    # Small helper: safely convert a Data object to compact JSON for inline display
    function Get-InlineData ([object]$data) {
        if ($null -eq $data) { return '' }
        try   { return " — ``$($data | ConvertTo-Json -Compress -Depth 3)``" }
        catch { return " — ``$data``" }
    }

    # -------------------------------------------------------------------------
    # Step 3 — Extract key data points from parsed entries
    # -------------------------------------------------------------------------

    # --- Run summary ---
    $initEntry   = Find-Entry $OrchestratorCommand  'ScubaGear logging initialized'
    $invokeEntry = Find-Entry $OrchestratorCommand  'Cmdlet invocation captured'
    $firstEntry  = $entries | Select-Object -First 1

    $runVersion    = if ($initEntry.Data.Version)      { $initEntry.Data.Version }      else { 'Unknown' }
    $runProducts   = if ($initEntry.Data.ProductNames) { $initEntry.Data.ProductNames } else { 'Unknown' }
    $runEnv        = if ($initEntry.Data.Environment)  { $initEntry.Data.Environment }  else { 'Unknown' }
    $runOutputDir  = if ($initEntry.Data.OutputFolder) { $initEntry.Data.OutputFolder } else { 'Unknown' }
    $invokeLine    = if ($invokeEntry.Data.InvocationLine)             { $invokeEntry.Data.InvocationLine }             else { 'Unknown' }
    #$invokeOrg     = if ($invokeEntry.Data.Parameters.Organization)    { $invokeEntry.Data.Parameters.Organization }    else { 'N/A' }
    $runStartTime  = $firstEntry.Timestamp

    # --- OS ---
    # Match "captured" suffix to skip the "Collecting..." entry which has no Data payload
    $osEntry = Find-Entry 'RunDetails' 'System OS Information captured'
    $osName  = if ($osEntry.Data.OS)           { $osEntry.Data.OS }           else { 'Unknown' }
    $osBuild = if ($osEntry.Data.Build)        { $osEntry.Data.Build }        else { '?' }
    $osArch  = if ($osEntry.Data.Architecture) { $osEntry.Data.Architecture } else { '?' }

    # --- PowerShell ---
    $psEntry      = Find-Entry 'RunDetails' 'PowerShell Version Information captured'
    $psVersionStr    = if ($psEntry.Data.PSVersion) { $psEntry.Data.PSVersion } else { 'Unknown' }
    $psEditionStr = if ($psEntry.Data.PSEdition) { $psEntry.Data.PSEdition } else { '?' }
    $clrVersion   = if ($psEntry.Data.CLRVersion -and $psEntry.Data.CLRVersion -ne 'N/A') { $psEntry.Data.CLRVersion } else { 'N/A' }

    # --- ScubaGear version ---
    $scubaVerEntry      = Find-Entry 'RunDetails' 'ScubaGear Version Information captured'
    $scubaLoaded        = if ($scubaVerEntry.Data.CurrentLoadedVersion) { $scubaVerEntry.Data.CurrentLoadedVersion } else { 'Unknown' }
    $scubaInstalled     = if ($scubaVerEntry.Data.InstalledVersions)    { $scubaVerEntry.Data.InstalledVersions }    else { 'Unknown' }
    $scubaLoadedPath    = if ($scubaVerEntry.Data.CurrentModulePath)    { $scubaVerEntry.Data.CurrentModulePath }    else { 'Unknown' }
    $scubaInstalledPath = if ($scubaVerEntry.Data.AllPaths)             { $scubaVerEntry.Data.AllPaths }             else { 'Unknown' }
    $scubaInstallSrc    = if ($scubaVerEntry.Data.InstallSource)        { $scubaVerEntry.Data.InstallSource }        else { 'Unknown' }
    $scubaPubDate       = if ($scubaVerEntry.Data.PublishedDate)        { $scubaVerEntry.Data.PublishedDate }        else { $null }
    $scubaInstDate      = if ($scubaVerEntry.Data.InstalledDate)        { $scubaVerEntry.Data.InstalledDate }        else { $null }
    $scubaGalleryRepo   = if ($scubaVerEntry.Data.GalleryRepository)    { $scubaVerEntry.Data.GalleryRepository }    else { $null }
    $versionMismatch    = ($scubaLoaded -ne 'Unknown' -and $scubaInstalled -ne 'Unknown' -and $scubaLoaded -ne $scubaInstalled)

    # --- OPA ---
    # Default-location discovery: what Get-ScubaRunDetails found in ~/.scubagear/Tools
    $opaEntry   = Find-Entry 'RunDetails' 'OPA Executable found'
    $opaVersion = if ($opaEntry.Data.Version)  { ($opaEntry.Data.Version -replace 'Version:\s*', '').Trim() } else { 'Unknown' }
    $opaPath    = if ($opaEntry.Data.Path)     { $opaEntry.Data.Path }     else { 'Unknown' }
    $opaSize    = if ($opaEntry.Data.SizeMB)   { "$($opaEntry.Data.SizeMB) MB" } else { 'Unknown' }

    # Configured-path check: logged by Get-ScubaRunDetails when called with -ConfiguredOPAPath $ScubaConfig.OPAPath.
    # This reflects the path ScubaGear will actually use at runtime (from -OPAPath param or YAML OPAPath key).
    # Regex matches both "OPA Executable at configured path" and "OPA Executable NOT found at configured path"
    $opaConfiguredEntry = Find-Entry 'RunDetails' 'OPA Executable (NOT found )?at configured path'
    $opaConfiguredPath  = if ($opaConfiguredEntry.Data.ConfiguredOPAPath) { $opaConfiguredEntry.Data.ConfiguredOPAPath } else { $null }
    $opaConfiguredFound = $opaConfiguredEntry -and ($opaConfiguredEntry.Message -notmatch 'NOT found')
    $opaConfiguredResolved = if ($opaConfiguredEntry.Data.ResolvedPath) { $opaConfiguredEntry.Data.ResolvedPath } else { $null }
    $opaConfiguredVersion  = if ($opaConfiguredEntry.Data.Version) { ($opaConfiguredEntry.Data.Version -replace 'Version:\s*', '').Trim() } else { $null }

    # Mismatch: configured path differs from the default-location path
    $opaDiscoveredDir = if ($opaPath -ne 'Unknown') { Split-Path $opaPath -Parent } else { $null }
    $opaPathMismatch  = $opaConfiguredPath -and $opaDiscoveredDir -and
                        ($opaConfiguredPath -ne $opaDiscoveredDir)

    # --- Network ---
    $netEntry    = Find-Entry 'RunDetails' 'Network connectivity status captured'
    $netInternet = if ($netEntry.Data.InternetConnected) { 'Connected' }     else { ':x: NOT connected' }
    $netDns      = if ($netEntry.Data.DNSResolution)     { 'OK' }            else { ':x: FAILED' }
    $netProxy    = if ($netEntry.Data.ProxyDetected)     { "Detected — $($netEntry.Data.ProxyAddress)" } else { 'Not detected' }

    # --- Phase timing ---
    # Provider and Rego timing come from FunctionTrace EXIT entries which log ExecutionTimeMs
    $providerExit = $entries | Where-Object { $_.Source -like '*FunctionTrace*' -and $_.Message -match 'EXIT: Invoke-ProviderList' }   | Select-Object -First 1
    $regoExit     = $entries | Where-Object { $_.Source -like '*FunctionTrace*' -and $_.Message -match 'EXIT: Invoke-RunRego' }         | Select-Object -First 1
    $reportExit   = $entries | Where-Object { $_.Source -like '*FunctionTrace*' -and $_.Message -match 'EXIT: Invoke-ReportCreation' }  | Select-Object -First 1

    # Provider status: Check for provider failure warnings, not just function trace status
    $providerFailedEntry = Find-Entry $OrchestratorCommand 'Some providers failed to execute'
    $providerStatus = if ($providerFailedEntry) {
        $failedList = if ($providerFailedEntry.Data.FailedProducts) { $providerFailedEntry.Data.FailedProducts } else { 'unknown' }
        ":x: Failed ($failedList)"
    } elseif ($providerExit.Data.Status) {
        $providerExit.Data.Status
    } else {
        'N/A'
    }

    # Trace-ScubaFunction marks Invoke-RunRego as "Success" if it returns without throwing,
    # even when it returns a non-empty list of failed products.  Override with the Warning
    # entry logged by the orchestrator after inspecting the return value.
    $regoFailedEntry = Find-Entry $OrchestratorCommand 'Some Rego evaluations failed'
    $regoStatus = if ($regoFailedEntry) {
        $failedList = if ($regoFailedEntry.Data.FailedProducts) { $regoFailedEntry.Data.FailedProducts } else { 'unknown' }
        ":x: Failed ($failedList)"
    } elseif ($regoExit.Data.Status) {
        $regoExit.Data.Status
    } else {
        'N/A'
    }
    $reportStatus   = if ($reportExit.Data.Status)   { $reportExit.Data.Status }   else { 'N/A' }

    # Authentication timing is derived from timestamps because it is not wrapped in Trace-ScubaFunction
    # Authentication succeeds if we reach "Retrieving tenant details" or "Starting provider execution"
    # Authentication fails if we see "All products failed authentication" or "failed authentication" errors
    $authStartEntry = Find-Entry $OrchestratorCommand  'Starting product authentication'
    $authFailedEntry = $entries | Where-Object {
        $_.Source -like '*InvokeScuba*' -and $_.Message -match 'All products failed authentication'
    } | Select-Object -First 1
    $authSuccessEntry   = $entries | Where-Object {
        $_.Source -like '*InvokeScuba*' -and ($_.Message -match 'Retrieving tenant details' -or $_.Message -match 'Starting provider execution')
    } | Select-Object -First 1

    $authMs = $null
    # Use PS 5.1 compatible null-coalescing
    $authEndEntry = if ($authFailedEntry) { $authFailedEntry } else { $authSuccessEntry }
    if ($authStartEntry -and $authEndEntry) {
        try {
            $t1    = [datetime]::ParseExact($authStartEntry.Timestamp, 'yyyy-MM-dd HH:mm:ss.fff', $null)
            $t2    = [datetime]::ParseExact($authEndEntry.Timestamp,   'yyyy-MM-dd HH:mm:ss.fff', $null)
            $authMs = [long]($t2 - $t1).TotalMilliseconds
        } catch {
            $authMs = $null
        }
    }
    $authStatus = if ($authFailedEntry) { ':warning: Failed' } elseif ($authSuccessEntry) { 'Success' } else { 'N/A' }

    # --- Warnings and Errors ---
    $issues = $entries | Where-Object { $_.Level -in @('Warning', 'Error') }

    # --- Condensed run timeline ---
    # Include milestones from the main run flow plus any warnings/errors.
    # Exclude RunDetails info entries (those facts are summarised in the sections above)
    # and pure Debug tracing noise.
    $timeline = $entries | Where-Object {
        ($_.Level -in @('Warning', 'Error')) -or
        (
            $_.Level -eq 'Info' -and
            $_.Source -notlike '*RunDetails*'
        ) -or
        (
            # Include FunctionTrace ENTER/EXIT even at Debug level so timings show in context
            $_.Source -like '*FunctionTrace*' -and $_.Message -match '^(ENTER|EXIT):'
        )
    }

    # -------------------------------------------------------------------------
    # Step 4 — Build the Markdown report
    # -------------------------------------------------------------------------
    $sb = [System.Text.StringBuilder]::new()

    $sb.AppendLine('# ScubaGear Debug Report') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine("> **Log file:** ``$DebugLogPath``") | Out-Null
    $sb.AppendLine("> **Report generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") | Out-Null
    $sb.AppendLine('') | Out-Null

    # --- Run Summary ---
    $sb.AppendLine('## Run Summary') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('| Field | Value |') | Out-Null
    $sb.AppendLine('|-------|-------|') | Out-Null
    $sb.AppendLine("| **Start Time** | $runStartTime |") | Out-Null
    $sb.AppendLine("| **Command** | ``$($invokeLine.Trim())`` |") | Out-Null
    $sb.AppendLine("| **ScubaGear Version (loaded)** | $runVersion |") | Out-Null
    $sb.AppendLine("| **Environment** | $runEnv |") | Out-Null
    #$sb.AppendLine("| **Organization** | $invokeOrg |") | Out-Null
    $sb.AppendLine("| **Products Assessed** | $runProducts |") | Out-Null
    $sb.AppendLine("| **Output Folder** | ``$runOutputDir`` |") | Out-Null
    $sb.AppendLine('') | Out-Null

    # --- System Environment ---
    $sb.AppendLine('## System Environment') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('| Field | Value |') | Out-Null
    $sb.AppendLine('|-------|-------|') | Out-Null
    $sb.AppendLine("| **OS** | $osName |") | Out-Null
    $sb.AppendLine("| **OS Build** | $osBuild ($osArch) |") | Out-Null
    $sb.AppendLine("| **PowerShell Version** | $psVersionStr ($psEditionStr edition) |") | Out-Null
    $sb.AppendLine("| **.NET CLR Version** | $clrVersion |") | Out-Null
    $sb.AppendLine('') | Out-Null

    # --- ScubaGear Installation ---
    $sb.AppendLine('## ScubaGear Installation') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('| Field | Value |') | Out-Null
    $sb.AppendLine('|-------|-------|') | Out-Null
    $sb.AppendLine("| **Loaded Version** | $scubaLoaded |") | Out-Null
    $sb.AppendLine("| **Loaded From** | ``$scubaLoadedPath`` |") | Out-Null
    $sb.AppendLine("| **Installed Version(s)** | $scubaInstalled |") | Out-Null
    $sb.AppendLine("| **Installed Path(s)** | ``$scubaInstalledPath`` |") | Out-Null
    $sb.AppendLine("| **Install Source** | $scubaInstallSrc |") | Out-Null
    if ($scubaPubDate)     { $sb.AppendLine("| **Gallery Published Date** | $scubaPubDate |")     | Out-Null }
    if ($scubaInstDate)    { $sb.AppendLine("| **Gallery Installed Date** | $scubaInstDate |")    | Out-Null }
    if ($scubaGalleryRepo) { $sb.AppendLine("| **Gallery Repository** | $scubaGalleryRepo |")    | Out-Null }
    if ($versionMismatch) {
        $sb.AppendLine('') | Out-Null
        $sb.AppendLine("> :warning: **Version mismatch**: loaded **$scubaLoaded** but installed version is **$scubaInstalled**. Running ScubaGear from a development or non-default path.") | Out-Null
    }
    $sb.AppendLine('') | Out-Null

    # --- Module Loading Progression (Combined Table) ---
    $sb.AppendLine('## Module Loading Progression') | Out-Null
    $sb.AppendLine('') | Out-Null

    # Find all module snapshot entries logged by Update-ScubaModuleSnapshot
    $moduleSnapshots = $entries | Where-Object { $_.Source -eq 'ModuleSnapshot' -and $_.Message -like '*snapshot*captured*' }

    # Process all snapshots together to build a table of modules and their loading progression across snapshots.
    if ($moduleSnapshots -and $moduleSnapshots.Count -gt 0) {
        # Build a unified list of all modules across all snapshots
        $allModules = @()
        $listedModules = @{}  # Track which modules we've already added

        foreach ($snapshot in $moduleSnapshots) {
            $snapshotName = if ($snapshot.Data.SnapshotName) { $snapshot.Data.SnapshotName } else { 'Unknown' }
            $moduleCount = if ($snapshot.Data.ModuleCount) { $snapshot.Data.ModuleCount } else { 0 }

            if ($moduleCount -gt 0 -and $snapshot.Data.Modules -and $snapshot.Data.ModulePathsSummary) {
                # Build path lookup from ModulePathsSummary
                $pathLookup = @{}
                foreach ($pair in ($snapshot.Data.ModulePathsSummary -split '; ')) {
                    if ($pair -match '^(.+?)=(.+)$') {
                        $pathLookup[$Matches[1]] = $Matches[2]
                    }
                }

                # Add each module to the unified list (only if not already listed)
                foreach ($modInfo in $snapshot.Data.Modules) {
                    if ($modInfo -match '^(.+) \((.+)\)$') {
                        $modName = $Matches[1]
                        $modVer = $Matches[2]

                        # Skip if we've already added this module
                        if ($listedModules.ContainsKey($modName)) {
                            continue
                        }

                        # Look up the path for this module from the path lookup; if not found, use '—' to indicate unknown
                        $modPath = if ($pathLookup.ContainsKey($modName)) {
                            $pathLookup[$modName]
                        } else {
                            '—'
                        }

                        # Add to the list with snapshot name, module name, version, and path to object
                        $allModules += [PSCustomObject]@{
                            Snapshot = $snapshotName
                            Module = $modName
                            Version = $modVer
                            Path = $modPath
                        }

                        # Mark this module as listed to avoid duplicates from other snapshots
                        $listedModules[$modName] = $true
                    }
                }
            }
        }

        # populate list of all modules that are in object and build markdown table
        if ($allModules.Count -gt 0) {
            $sb.AppendLine('| Snapshot | Module | Version | Path |') | Out-Null
            $sb.AppendLine('|----------|--------|---------|------|') | Out-Null

            foreach ($mod in $allModules) {
                $sb.AppendLine("| $($mod.Snapshot) | $($mod.Module) | $($mod.Version) | ``$($mod.Path)`` |") | Out-Null
            }
        }
        else {
            $sb.AppendLine('_No modules captured in any snapshots._') | Out-Null
        }
    }
    else {
        # Fallback to old behavior if no snapshots found (legacy logs)
        $sb.AppendLine('_No module snapshots captured. Use Get-ScubaRunDetails with -IncludeLoadedModules to enable module tracking._') | Out-Null
    }
    $sb.AppendLine('') | Out-Null

    # --- OPA ---
    # Show configured path details first since that is what ScubaGear will actually use at runtime, then show the default-location discovery details for comparison.
    #Highlight any mismatches or missing OPA issues.
    $sb.AppendLine('## OPA Executable') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('| Field | Value |') | Out-Null
    $sb.AppendLine('|-------|-------|') | Out-Null
    if ($opaConfiguredPath) {
        # Show the configured path first — it is what actually runs
        $configuredStatus = if ($opaConfiguredFound) { ':white_check_mark: Found' } else { ':x: NOT FOUND' }
        $sb.AppendLine("| **OPAPath (configured)** | ``$opaConfiguredPath`` |") | Out-Null
        $sb.AppendLine("| **OPA at configured path** | $configuredStatus |") | Out-Null
        if ($opaConfiguredResolved -and $opaConfiguredFound) {
            $sb.AppendLine("| **Resolved OPA binary** | ``$opaConfiguredResolved`` |") | Out-Null
        }
        if ($opaConfiguredVersion) {
            $sb.AppendLine("| **Version (configured path)** | $opaConfiguredVersion |") | Out-Null
        }
        $sb.AppendLine("| **Default path (discovered)** | ``$opaPath`` |") | Out-Null
        $sb.AppendLine("| **Version (default path)** | $opaVersion |") | Out-Null
        $sb.AppendLine("| **Size (default path)** | $opaSize |") | Out-Null
    }
    else {
        $sb.AppendLine("| **Version** | $opaVersion |") | Out-Null
        $sb.AppendLine("| **Size** | $opaSize |") | Out-Null
        $sb.AppendLine("| **Path** | ``$opaPath`` |") | Out-Null
    }
    if (-not $opaConfiguredFound -and $opaConfiguredPath) {
        $sb.AppendLine('') | Out-Null
        $sb.AppendLine("> :x: **OPA not found at configured path**: ScubaGear looked for OPA in ``$opaConfiguredPath`` (from your YAML/parameter) but found nothing there. Rego evaluation will fail. OPA is present at ``$opaPath`` (default install location) but that path is not being used.") | Out-Null
    }
    elseif ($opaPathMismatch -and $opaConfiguredFound) {
        $sb.AppendLine('') | Out-Null
        $sb.AppendLine("> :information_source: OPA found at both the configured path (``$opaConfiguredPath``) and the default install location (``$(Split-Path $opaPath -Parent)``). The configured path will be used.") | Out-Null
    }
    $sb.AppendLine('') | Out-Null

    # --- Network ---
    $sb.AppendLine('## Network Connectivity') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('| Check | Result |') | Out-Null
    $sb.AppendLine('|-------|--------|') | Out-Null
    $sb.AppendLine("| **Internet (www.microsoft.com)** | $netInternet |") | Out-Null
    $sb.AppendLine("| **DNS Resolution** | $netDns |") | Out-Null
    $sb.AppendLine("| **Proxy** | $netProxy |") | Out-Null
    $sb.AppendLine('') | Out-Null

    # --- Phase Timing ---
    $sb.AppendLine('## Phase Timing') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('| Phase | Duration | Status |') | Out-Null
    $sb.AppendLine('|-------|----------|--------|') | Out-Null
    $sb.AppendLine("| Authentication | $(Format-Ms $authMs) | $authStatus |") | Out-Null
    $sb.AppendLine("| Provider Execution | $(Format-Ms $providerExit.Data.ExecutionTimeMs) | $providerStatus |") | Out-Null
    $sb.AppendLine("| Rego Evaluation | $(Format-Ms $regoExit.Data.ExecutionTimeMs) | $regoStatus |") | Out-Null
    if ($reportExit) {
        $sb.AppendLine("| Report Creation | $(Format-Ms $reportExit.Data.ExecutionTimeMs) | $reportStatus |") | Out-Null
    }
    $sb.AppendLine('') | Out-Null

    # --- Warnings and Errors ---
    $sb.AppendLine('## Warnings and Errors') | Out-Null
    $sb.AppendLine('') | Out-Null
    if ($issues.Count -gt 0) {
        foreach ($issue in $issues) {
            $icon    = if ($issue.Level -eq 'Error') { ':x:' } else { ':warning:' }
            $dataStr = Get-InlineData $issue.Data
            # Show only the time portion of the timestamp to keep lines compact
            $time    = $issue.Timestamp.Substring(11, 12)
            $sb.AppendLine("- $icon **[$time]** ``[$($issue.Source)]`` $($issue.Message)$dataStr") | Out-Null
        }
    }
    else {
        $sb.AppendLine('_No warnings or errors recorded._') | Out-Null
    }
    $sb.AppendLine('') | Out-Null

    # --- Condensed run timeline ---
    $sb.AppendLine('## Run Timeline') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('```') | Out-Null
    foreach ($e in $timeline) {
        $time = $e.Timestamp.Substring(11, 12)   # HH:mm:ss.fff
        $icon = switch ($e.Level) {
            'Warning' { '[WARN ]' }
            'Error'   { '[ERROR]' }
            default   { '[INFO ]' }
        }
        # For FunctionTrace entries include the execution time inline when available
        $extra = ''
        if ($e.Source -like '*FunctionTrace*' -and $e.Data.ExecutionTimeMs) {
            $extra = "  ($(Format-Ms $e.Data.ExecutionTimeMs))"
        }
        # For main phase entries include a compact summary of any relevant data fields
        elseif ($e.Data -is [PSCustomObject]) {
            # Only pull in a small set of meaningful fields, skip large/verbose ones
            $skip = @('InvocationLine','Parameters','AllPaths','ModuleNames','TopModules',
                      'RecentScubaCommands','BoundParameters','CommandLine','ScriptLineNumber',
                      'CalledFrom','CurrentFunction','ScriptName','WorkingDirectory')
            $parts = foreach ($p in $e.Data.PSObject.Properties) {
                if ($p.Name -notin $skip -and $null -ne $p.Value -and "$($p.Value)" -ne '') {
                    "$($p.Name)=$($p.Value)"
                }
            }
            if ($parts) { $extra = "  | $($parts -join '; ')" }
        }

        $src = "[$($e.Source)]".PadRight(22)
        $sb.AppendLine("$time $icon $src $($e.Message)$extra") | Out-Null
    }
    $sb.AppendLine('```') | Out-Null
    $sb.AppendLine('') | Out-Null

    # --- Comments / Additional Notes ---
    $sb.AppendLine('## Comments / Additional Notes') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('_Use this section to add any additional context, observations, or notes about the issue:_') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('') | Out-Null
    $sb.AppendLine('') | Out-Null

    # -------------------------------------------------------------------------
    # Step 5 — Apply redactions based on schema
    # -------------------------------------------------------------------------
    function Invoke-ScubaLogRedaction {
        param([string]$Text)

        # Locate the schema file relative to this module
        $schemaPath = Join-Path (Split-Path $PSCommandPath -Parent) 'ScubaLoggingRedactions.json'

        if (-not (Test-Path $schemaPath)) {
            Write-ScubaLog -Level Warning -Source 'Get-ScubaDebugLogReport' `
                -Message "Redaction schema not found at: $schemaPath. Skipping redactions."
            return $Text
        }

        try {
            $schema = Get-Content $schemaPath -Raw -Encoding UTF8 | ConvertFrom-Json

            $redactedText = $Text
            $redactionCount = 0

            foreach ($rule in $schema.patterns) {
                if (-not $rule.enabled) { continue }

                try {
                    # Build replacement string: capture group 1 + redactionText + capture group 3
                    # This preserves parameter names and quotes while redacting the value
                    $replacement = "`$1$($schema.redactionText)`$3"

                    $beforeLength = $redactedText.Length
                    $redactedText = $redactedText -replace $rule.pattern, $replacement

                    if ($redactedText.Length -ne $beforeLength) {
                        $redactionCount++
                    }
                }
                catch {
                    Write-ScubaLog -Level Warning -Source 'Get-ScubaDebugLogReport' `
                        -Message "Failed to apply redaction rule '$($rule.name)': $_"
                }
            }

            if ($redactionCount -gt 0) {
                Write-ScubaLog -Level Info -Source 'Get-ScubaDebugLogReport' `
                    -Message "Applied $redactionCount redaction rule(s) to report."
            }

            return $redactedText
        }
        catch {
            Write-ScubaLog -Level Warning -Source 'Get-ScubaDebugLogReport' `
                -Message "Failed to load or parse redaction schema: $_. Skipping redactions."
            return $Text
        }
    }

    # -------------------------------------------------------------------------
    # Step 6 — Emit the report
    # -------------------------------------------------------------------------
    $reportText = $sb.ToString()

    # Apply redactions if schema is available
    $reportText = Invoke-ScubaLogRedaction -Text $reportText

    # Output to pipeline based on context:
    # - If PassThru is specified: always output
    # - If OutputPath is specified without PassThru: don't output (just save to file)
    # - If neither OutputPath nor PassThru is specified: output (default behavior)
    $shouldOutput = $PassThru -or (-not $OutputPath)

    if ($shouldOutput) {
        Write-Output $reportText
    }

    if ($OutputPath) {
        $reportText | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Output "Report saved to: $OutputPath"
    }
}

# Explicitly export only the public API surface of this module.
# Internal helpers (e.g. module-level variables, private utility logic) are not exported.
# Callers in Orchestrator.psm1 use: Initialize-ScubaLogging, Write-ScubaLog, Trace-ScubaFunction,
# Get-ScubaRunDetails, and Stop-ScubaLogging.  The remaining exports (Enable-ScubaAutoTrace,
# Write-ScubaFunctionEntry, Write-ScubaFunctionExit) are available for future instrumentation use.
Export-ModuleMember -Function @(
    'Initialize-ScubaLogging',
    'Write-ScubaLog',
    'Trace-ScubaFunction',
    'Stop-ScubaLogging',
    'Enable-ScubaAutoTrace',
    'Write-ScubaFunctionEntry',
    'Write-ScubaFunctionExit',
    'Get-ScubaRunDetails',
    'Update-ScubaModuleSnapshot',
    'Get-ScubaDebugLogReport'
)