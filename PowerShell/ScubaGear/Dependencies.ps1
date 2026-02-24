<#
.SYNOPSIS
    Checks ScubaGear and dependency versions for issues that would prevent execution.

.DESCRIPTION
    Runs Test-ScubaGearVersion to identify version issues with ScubaGear dependencies.
    Displays detailed information from Test-ScubaGearVersion if issues are found.

.EXAMPLE
    .\Dependencies.ps1
#>

[CmdletBinding()]
param()

try {
    $SupportModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "Modules/Support/Support.psm1"
    Import-Module -Name $SupportModulesPath

    # Run version check and display its output
    $null = Test-ScubaGearVersion
}
catch {
    Write-Error "An error occurred checking version status: $($_.Exception.Message)"
    throw
}