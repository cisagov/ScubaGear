# The purpose of this test is to verify that PSSA is working.

# Suppress PSSA warnings here at the root of the test file.
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
    Write-Warning "----"
    $global:Warnings | ForEach-Object { Write-Warning $_ } 
    Write-Warning "----"
    # There should be write-warning statements
    $global:Warnings | Should -Not -BeNullOrEmpty
    # Note: This is a little bit fragile.  It only work as long as one of these two
    # summary statements is the final output written.
    $global:Warnings | Select-Object -Last 1 | Should -BeIn @("Problems were found in the PowerShell scripts.", "No problems were found in the PowerShell scripts.")
  }
}


# Describe "PSSA Check" {
#   It "PSSA should write output" {
#     $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
#     $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
#     # Source the function
#     . $ScriptPath
#     # Invoke PSSA, redirecting all Write-Warnings to a variable
#     $Warnings = @()
#     Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath -WarningVariable Warnings 
#     $Module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
#     # The module should be installed
#     $Module | Should -Not -BeNullOrEmpty
#     # There should be write-warning statements
#     $Warnings | Should -Not -BeNullOrEmpty
#     # Note: This is a little bit fragile.  It only work as long as one of these two
#     # summary statements is the final output written.
#     $Warnings | Select-Object -Last 1 | Should -BeIn @("Problems were found in the PowerShell scripts.", "No problems were found in the PowerShell scripts.")
#   }
# }