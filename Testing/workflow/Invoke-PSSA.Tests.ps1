# The purpose of this test is to verify that PSSA is working.

BeforeDiscovery {
  # Source the function
  . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
  # Invoke PSSA
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  $global:Output = Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath 6>&1
}

Describe "PSSA Invoke" {
  It "PSSA should be installed" {
    # # Source the function
    # . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
    # # Invoke PSSA
    # $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
    # Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
    $Module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    $Module | Should -Not -BeNullOrEmpty
  }
  It "PSSA should write output" {
    # # Source the function
    # . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
    # # Invoke PSSA
    # $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
    # $Output = Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath 6>&1
    $global:Output | Should -Not -BeNullOrEmpty
    # Note: This is a little bit fragile.  It only work as long as one of these two
    # summary statements is the final output.
    $global:Output | Select-Object -Last 1 | Should -BeIn @("Problems were found in the PowerShell scripts.", "No problems were found in the PowerShell scripts.")
  }
}