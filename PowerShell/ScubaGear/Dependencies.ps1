<#
.SYNOPSIS
    Checks ScubaGear and dependency versions for issues that would prevent execution.

.DESCRIPTION
    Runs Test-ScubaGearVersion to identify version issues with ScubaGear or its dependencies.
    If critical version issues are found, recommendations are displayed.

.EXAMPLE
    .\Dependencies.ps1

.NOTES
    Uses Host.UI.WriteErrorLine instead of Write-Warning to avoid duplicate warning
    messages when dependencies.ps1 also issue warnings.

#>

[CmdletBinding()]
param()

try {
    $SupportModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "Modules/Support/Support.psm1"
    Import-Module -Name $SupportModulesPath

    # Run version check with -Quiet to suppress detailed output
    $VersionIssues = Test-ScubaGearVersion -Quiet

    # Extract components
    $DependencyStatus = $VersionIssues | Where-Object { $_.Component -eq "Dependencies" }

    # Categorize issues by severity
    $criticalIssues = @()
    $warnings = @()
    $hasVersionIssues = $false
    $hasMissingModules = $false
    $hasMultipleVersions = $false

    # Parse ModuleFileLocations to categorize issues
    if ($DependencyStatus.ModuleFileLocations) {
        foreach ($moduleInfo in $DependencyStatus.ModuleFileLocations) {
            $hasCritical = $false

            foreach ($location in $moduleInfo.Locations) {
                if ($location -match '\[ABOVE MAX:') {
                    $hasCritical = $true
                    $hasVersionIssues = $true

                    # Extract version and max from location string
                    # Match pattern: "2.34.0 [ABOVE MAX: 2.25.0]" or just "[ABOVE MAX: 2.25.0]"
                    if ($location -match '([\d\.]+)?\s*\[ABOVE MAX:\s*([\d\.]+)\]') {
                        $installedVer = if ($matches[1]) { $matches[1] } else { "unknown" }
                        $maxVer = $matches[2]
                        $criticalIssues += "  - $($moduleInfo.ModuleName) - version $installedVer exceeds maximum ($maxVer)"
                    }
                    else {
                        # Fallback if regex doesn't match
                        $criticalIssues += "  - $($moduleInfo.ModuleName) - version exceeds maximum"
                    }
                    break
                }
                elseif ($location -match '\[BELOW MIN:') {
                    $hasCritical = $true
                    $hasVersionIssues = $true

                    if ($location -match '([\d\.]+)?\s*\[BELOW MIN:\s*([\d\.]+)\]') {
                        $installedVer = if ($matches[1]) { $matches[1] } else { "unknown" }
                        $minVer = $matches[2]
                        $criticalIssues += "  - $($moduleInfo.ModuleName) - version $installedVer below minimum ($minVer)"
                    }
                    else {
                        # Fallback if regex doesn't match
                        $criticalIssues += "  - $($moduleInfo.ModuleName) - version below minimum"
                    }
                    break
                }
            }

            # If no critical issue but multiple versions, add to warnings
            if (-not $hasCritical) {
                $hasMultipleVersions = $true
                $versionCount = $moduleInfo.VersionCount
                $warnings += "  - $($moduleInfo.ModuleName) - $versionCount versions installed (cleanup recommended)"
            }
        }
    }

    # Check for missing modules
    if ($DependencyStatus.MissingModules -and $DependencyStatus.MissingModules.Count -gt 0) {
        $hasMissingModules = $true
        foreach ($module in $DependencyStatus.MissingModules) {
            $criticalIssues += "  - $module - not installed"
        }
    }

    # Determine overall severity and build appropriate message
    $hasCriticalProblems = $hasVersionIssues -or $hasMissingModules
    if ($hasCriticalProblems) {
        # Critical issues - use error message
        $errorMessage = @"
CRITICAL: Dependency issues detected that may prevent ScubaGear from running!

"@

        if ($criticalIssues.Count -gt 0) {
            $errorMessage += @"

Critical Issues:
$($criticalIssues -join "`n")


"@
        }

        if ($hasMultipleVersions -and $warnings.Count -gt 0) {
            $errorMessage += @"
Additional Warnings:
$($warnings -join "`n")


"@
        }

        if ($DependencyStatus.AdminRequired) {
            $errorMessage += @"
Note: Administrator privileges required for some cleanup operations.


"@
        }

        $errorMessage += @"
Action Required:
  Run 'Reset-ScubaGearDependencies' to resolve these issues.

"@
        $Host.UI.WriteErrorLine($errorMessage)
    }
        elseif ($hasMultipleVersions) {
        # Only cleanup needed - use warning
        $warningMessage = @"
WARNING: Module cleanup recommended

Multiple Versions Detected:
$($warnings -join "`n")

"@

        if ($DependencyStatus.AdminRequired) {
            $warningMessage += @"
Note: Administrator privileges required for some cleanup operations.


"@
        }

        $warningMessage += @"
Recommended Action:
  Run 'Reset-ScubaGearDependencies' to clean up multiple versions.

"@
        $Host.UI.WriteErrorLine($warningMessage)
    }
    else {
        # All clear
        Write-Information "All dependency checks passed. ScubaGear is ready to run." -InformationAction Continue
    }
}
catch {
    Write-Error "An error occurred checking version status: $($_.Exception.Message)"
    throw
}