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
    $Module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    $Module | Should -Not -BeNullOrEmpty
  }
}

Describe "PSSA Output" {
  It "PSSA should write output" {
    # Source the function
    . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
    # Invoke PSSA
    $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..' -Resolve
    $Output = Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath 6>&1
    $Output | Should -Contain "Problems were found in the PowerShell scripts.|No problems were found in the PowerShell scripts."
  }
}