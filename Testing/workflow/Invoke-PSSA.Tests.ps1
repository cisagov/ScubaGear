# The purpose of this test is to verify that PSSA is working.

# Suppress PSSA warnings here at the root of the test file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeDiscovery {
  $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
  # Source the function
  . $ScriptPath
  # Invoke PSSA, redirecting all Write-Outputs to $Output
  $global:Output = Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath 6>&1
}

Describe "PSSA Check" {
  It "PSSA should write output" {
    Write-Warning "placeholder..."
    # $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
    # $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
    # # Source the function
    # . $ScriptPath
    # # Invoke PSSA, redirecting all Write-Outputs to $Output
    # Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
    # $Output = Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath 6>&1
    # Write-Warning $Output
    # $Module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    # $Module | Should -Not -BeNullOrEmpty
    $Output | Should -Not -BeNullOrEmpty
    # # Note: This is a little bit fragile.  It only work as long as one of these two
    # # summary statements is the final output written.
    # $Output | Select-Object -Last 1 | Should -BeIn @("Problems were found in the PowerShell scripts.", "No problems were found in the PowerShell scripts.")
  }
}