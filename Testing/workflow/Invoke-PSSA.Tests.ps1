# The purpose of this tset is to verify that PSSA is working.

BeforeDiscovery {
  # Source the function
  . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
  # Invoke PSSA
  Invoke-PSSA
}

Describe "PSSA Check" {
  It "PSSA should be installed" {
    $module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    $module | Should -Not -BeNullOrEmpty
  }
}