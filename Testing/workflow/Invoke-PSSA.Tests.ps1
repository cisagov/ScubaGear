# The purpose of this test is to verify that PSSA is working.

# Suppress PSSA warnings here at the root of the test file.
# This allows us to run Invoke-PSSA once and use the results for both tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeDiscovery {
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
  $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
  # Source the function
  . $ScriptPath
  # Invoke PSSA, redirecting all Write-Warnings to a variable
  $Warnings = @()
  Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath -WarningVariable Warnings
  $global:Warnings = $Warnings
}

Describe "PSSA Check" {
  It "PSSA should be installed" {
    $Module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    $Module | Should -Not -BeNullOrEmpty
  }
  It "PSSA should write output" {
    # There should be write-warning statements
    $global:Warnings | Should -Not -BeNullOrEmpty
    # Note: This is a little bit fragile.  It only work as long as one of these two
    # summary statements is the final output written by the Invoke function.
    $global:Warnings | Select-Object -Last 1 | Should -BeIn @("Problems were found in the PowerShell scripts.", "No problems were found in the PowerShell scripts.")
  }
}
