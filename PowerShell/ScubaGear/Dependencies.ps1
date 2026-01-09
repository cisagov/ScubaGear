<#
.SYNOPSIS
    Checks ScubaGear and dependency versions for issues that would prevent execution.

.DESCRIPTION
    Runs Test-ScubaGearVersion to identify version issues with ScubaGear or its dependencies.
    If critical version issues are found, recommendations are displayed.

.EXAMPLE
    .\Get-VersionIssues.ps1

.NOTES
    Uses Host.UI.WriteErrorLine instead of Write-Warning to avoid duplicate warning
    messages when dependencies.ps1 also issue warnings.

#>

[CmdletBinding()]
param()

try {
    $SupportModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "Modules/Support/Support.psm1"
    Import-Module -Name $SupportModulesPath

    # Run version check
    $VersionIssues = Test-ScubaGearVersion

    # Extract components
    $DependencyStatus = $VersionIssues | Where-Object { $_.Component -eq "Dependencies" }

    # Check for version issues
    if ($DependencyStatus.Status -eq "Version Issues") {
        $issueMessage = ($DependencyStatus.Recommendations -split '\.?\s*Run')[0].Trim()

        $errorMessage = @"

CRITICAL: Version issues detected that may prevent ScubaGear from running!

Issues Found:
  $issueMessage

Action Required:
  Run 'Reset-ScubaGearDependencies' to fix these version issues.

"@
        $Host.UI.WriteErrorLine($errorMessage)
    }

    # Check for missing modules
    if ($DependencyStatus.Status -eq "Missing Modules") {
        $missingList = $DependencyStatus.MissingModules | ForEach-Object { "  - $_" }
        $missingListString = $missingList -join "`n"

        $errorMessage = @"

CRITICAL: Missing required dependencies!

Missing Modules:
$missingListString

Action Required:
  $($DependencyStatus.Recommendations)

"@
        $Host.UI.WriteErrorLine($errorMessage)
    }

    # Check for non-critical issues that the user should consider addressing
    if ($DependencyStatus.Status -eq "Needs Cleanup") {
        $warningMessage = @"
Multiple module versions detected.
  This may cause issues with ScubaGear, cleanup is recommended.
  $($DependencyStatus.Recommendations)
"@
        $Host.UI.WriteErrorLine($warningMessage)
    }

    # All clear
    if ($DependencyStatus.Status -eq "Optimal") {
        Write-Information "All module checks passed. ScubaGear is ready to run." -InformationAction Continue
    }
}
catch {
    Write-Error "An error occurred checking version status: $($_.Exception.Message)"
    throw
}