# The purpose of this test is to verify that PSSA is working.

# BeforeDiscovery {
#   # Source the function
#   . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
#   # Invoke PSSA
#   $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
#   Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
# }

Describe "PSSA Check" {
  # It "PSSA should be installed" {
  #   $module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
  #   $module | Should -Not -BeNullOrEmpty
  # }
  It "PSSA should write output" {
    Mock Write-Output {}
    # Source the function
    . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
    # Invoke PSSA
    $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
    Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
    Assert-MockCalled Write-Output  -Scope It -ParameterFilter { $Object -contains "PowerShell scripts" }
  }
}