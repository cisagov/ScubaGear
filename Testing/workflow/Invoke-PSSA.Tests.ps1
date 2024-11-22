# The purpose of this test is to verify that PSSA is working.

# Suppress PSSA warnings here at the root of the test file.

BeforeAll {
  $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
  # Source the function
  . $ScriptPath
  # Invoke PSSA
  Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
}

Describe "PSSA Check" {
  It "PSSA should be installed" {
    $Module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    $Module | Should -Not -BeNullOrEmpty
  }
}