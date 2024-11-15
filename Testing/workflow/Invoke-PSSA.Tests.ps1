# The purpose of this tset is to verify that PSSA is working.

BeforeDiscovery {
  # Source the function
  . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
  # Invoke PSSA
  $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
  Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
}

Describe "PSSA Check" {
  It "PSSA should be installed" {
    $module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    $module | Should -Not -BeNullOrEmpty
  }
  It "PSSA should find no results in this file" {
    $ThisTestFile = Get-ChildItem -Path . -Include *.ps1
    $Results = Invoke-ScriptAnalyzer -Path $ThisTestFile
    $Results.Count | Should -BeExactly 0
  }
}