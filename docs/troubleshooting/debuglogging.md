# Debug Logging

ScubaGear includes a debug logging module (`ScubaLogging`) that captures structured diagnostic information during every run. It writes timestamped log entries to a `DebugLogs` subfolder inside the output folder. Optionally, you can also enable PowerShell transcript logging to capture all console output.

## Overview

Debug logging is **always enabled** and captures:

- Run invocation details (command line, parameters, products assessed, environment)
- System and PowerShell environment information
- ScubaGear version and dependency module details
- OPA executable information
- Network connectivity checks
- Phase timing for authentication, provider execution, Rego evaluation, and report creation
- Function entry and exit trace with execution durations
- All warnings and errors encountered during the run

## Enabling Transcript Logging

Debug logs are created automatically. To also enable PowerShell transcript logging, pass the `-Transcript` switch to `Invoke-SCuBA`:

> IMPORTANT: Transcript logging is meant for developers and to troubleshoot the module. It does not redact sensitive information and can be fairly large in size

```powershell
Invoke-SCuBA -ProductNames * -Transcript
```

```powershell
Invoke-SCuBA -ProductNames aad, teams -M365Environment gcchigh -Transcript
```

ScubaGear prints the log folder path at the start of the run:

```text
ScubaGear logging enabled
Log folder: C:\ScubaResults\M365BaselineConformance_2026_03_11_11_18_27\DebugLogs
```

> [!NOTE]
> Debug logging and function tracing capture detailed execution information. All debug and verbose output is written only to the log file to avoid console spam. Tracing may increase run time slightly.

## Output Files

A `DebugLogs` subfolder is created inside the timestamped output folder:

```text
M365BaselineConformance_2026_03_11_11_18_27\
  └── DebugLogs\
      ├── ScubaGear-DebugLog-20260311-111827-956.log
      └── ScubaGear-Transcript-20260311-111827-956.log  (only if -Transcript was used)
```

### Debug Log

`ScubaGear-DebugLog-*.log` contains structured log entries in the following format:

```text
[yyyy-MM-dd HH:mm:ss.fff] [Level  ] [Source              ] Message text
    Data: {"key":"value",...}
```

Each entry includes a high-precision timestamp, a severity level (`Debug`, `Info`, `Warning`, or `Error`), the source component, and the message. Entries with structured data payloads include an indented `Data:` line with a compact JSON object.

### Transcript Log

`ScubaGear-Transcript-*.log` captures all PowerShell console output during the run using `Start-Transcript`. It is more verbose than the debug log and includes all output written to the PowerShell host, including verbose and debug streams. Review the transcript when the debug log alone does not contain enough detail to diagnose an issue.

## Generating a Debug Report

A markdown formatted report is generated automatically if ScubaLogging detects errors. If there are no errors, the file is not created, however you can run the command below to create one

`Get-ScubaDebugLogReport` parses a debug log file and produces a Markdown summary suitable for sharing in a GitHub issue or support request.

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-DebugLogPath` | Yes | Full path to the `ScubaGear-DebugLog-*.log` file to parse |
| `-OutputPath` | No | If provided, the Markdown report is saved to this file path. When specified without `-PassThru`, the report is not displayed on screen |
| `-FromScubaCached` | No | Pass this switch when the log was produced by `Invoke-SCuBACached`. It tells the report parser to match log entries against the `ScubaCached` source header instead of the default `Invoke-SCuBA` source header. Without it, the run summary and phase timing sections will be empty for cached runs |
| `-PassThru` | No | When specified, the report is written to the pipeline (displayed on screen). Use this with `-OutputPath` to both save the report and display it on screen |

### Usage Examples

Print the report to the console:

```powershell
Get-ScubaDebugLogReport -DebugLogPath "C:\ScubaResults\M365BaselineConformance_2026_03_11_11_18_27\DebugLogs\ScubaGear-DebugLog-20260311-111827-956.log"
```

Save the report to a file **without** displaying it in terminal:

```powershell
Get-ScubaDebugLogReport `
    -DebugLogPath "C:\ScubaResults\M365BaselineConformance_2026_03_11_11_18_27\DebugLogs\ScubaGear-DebugLog-20260311-111827-956.log" `
    -OutputPath   "C:\ScubaResults\M365BaselineConformance_2026_03_11_11_18_27\DebugLogs\ScubaGearDebugReport.md"
```

Save the report to a file and display it in terminal:

```powershell
Get-ScubaDebugLogReport `
    -DebugLogPath "C:\ScubaResults\M365BaselineConformance_2026_03_11_11_18_27\DebugLogs\ScubaGear-DebugLog-20260311-111827-956.log" `
    -OutputPath   "C:\ScubaResults\M365BaselineConformance_2026_03_11_11_18_27\DebugLogs\ScubaGearDebugReport.md" `
    -PassThru
```

Generate a report from a log produced by `Invoke-SCuBACached`:

```powershell
Get-ScubaDebugLogReport `
    -DebugLogPath    "C:\ScubaResults\M365BaselineConformance_2026_03_11_11_18_27\DebugLogs\ScubaGear-DebugLog-20260311-111827-956.log" `
    -OutputPath      "C:\ScubaResults\M365BaselineConformance_2026_03_11_11_18_27\DebugLogs\ScubaGearDebugReport.md" `
    -FromScubaCached
```

### Report Contents

The generated report includes the following sections:

| Section | Contents |
|---------|----------|
| Run Summary | Start time, command line, ScubaGear version, environment, products assessed, output folder |
| System Environment | OS name and build, PowerShell version and edition, .NET CLR version |
| ScubaGear Installation | Loaded version and path, installed versions and paths, version mismatch warning if applicable |
| Module Loading Progression | Unified table showing when each required module was loaded (e.g., InitialLoad, PostAuthentication) with module names, versions, and paths |
| OPA Executable | Version, path, and file size |
| Network Connectivity | Internet connectivity, DNS resolution, proxy detection |
| Phase Timing | Duration and status for authentication, provider execution, Rego evaluation, and report creation |
| Warnings and Errors | All `Warning` and `Error` level entries with timestamps and source components |
| Run Timeline | Condensed chronological view of `Info` and above milestones plus function trace entries |
| Comments / Additional Notes | Blank section for users to add context, observations, or notes when sharing the report |

> [!TIP]
> The transcript file is not parsed by `Get-ScubaDebugLogReport`. Open `ScubaGear-Transcript-*.log` directly when you need the full console output from the run.

## Log Level Reference

The debug log captures entries at four levels:

| Level | Description |
|-------|-------------|
| `Debug` | Function entry and exit, parameter values, detailed execution trace |
| `Info` | Phase milestones, configuration details, connectivity results |
| `Warning` | Non-fatal issues that may affect results |
| `Error` | Failures that caused a phase or the run to fail |

> [!NOTE]
> `Debug` level entries are written to the log file but are not displayed on the console. `Info` level entries are selectively shown on the console for high-level milestones only. All levels are captured in the log file regardless of console output.

## Sensitive Data Handling

The logging module automatically redacts parameter values whose names match common sensitive patterns (`password`, `secret`, `token`, `key`, `credential`, `certificate`). These values are replaced with `[REDACTED]` in the log file and are never written to disk.
