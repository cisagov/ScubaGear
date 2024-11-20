# The purpose of this test is to verify that PSSA is working.

# BeforeDiscovery {
#   Mock Write-Host {}
# }

Describe "PSSA Install" {
  It "PSSA should be installed" {
    # Source the function
    . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
    # Invoke PSSA
    $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
    Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
    $module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    $module | Should -Not -BeNullOrEmpty
  }

Describe "PSSA Output"
  It "PSSA should write output" {
    Mock Write-Host {}
    # Source the function
    . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
    # Invoke PSSA
    $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
    Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
    Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -contains "PowerShell scripts" }
  }
}