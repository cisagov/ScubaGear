# The purpose of this test is to verify that PSSA is working.

# Suppress PSSA warnings here at the root of the test file.
# [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
# param()
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases", "")]
param()

# BeforeDiscovery {
#   # $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
#   $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
#   # Source the function
#   # . $ScriptPath
#   . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
#   # Invoke PSSA, redirecting all Write-Outputs to $Output
#   Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
#   # $Writes = Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath 6>&1
#   # $global:Output = $Writes
# }

Describe "PSSA Check" {
  It "PSSA should write output" {
    $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
    Write-Warning "The repo root path is $RepoRootPath"
    . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
    # $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
    # Write-Warning "The script path is $ScriptPath"
    # . $ScriptPath
    # Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
    # $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
    # # Source the function
    # . $ScriptPath
    # # Invoke PSSA, redirecting all Write-Outputs to $Output
    . $PSScriptRoot/../../utils/workflow/Invoke-PSSA.ps1
    Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
    # $Output = Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath 6>&1
    # Write-Warning $Output
    # $Module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    # $Module | Should -Not -BeNullOrEmpty
    # $Output | Should -Not -BeNullOrEmpty
    # # Note: This is a little bit fragile.  It only work as long as one of these two
    # # summary statements is the final output written.
    # $Output | Select-Object -Last 1 | Should -BeIn @("Problems were found in the PowerShell scripts.", "No problems were found in the PowerShell scripts.")
  }
}