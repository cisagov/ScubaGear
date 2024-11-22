# The purpose of this test is to verify that PSSA is working.

Describe "PSSA Check" {
  It "PSSA should write output" {
    $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Invoke-PSSA.ps1' -Resolve
    Write-Warning "The ScriptPath is"
    Write-Warning $ScriptPath
    $Content = get-content $ScriptPath
    Write-Warning $Content
    $RepoRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../..' -Resolve
    Write-Warning "The RepoPath is"
    Write-Warning $RepoRootPath
    $Files = Get-ChildItem -Path $RepoRootPath
    Write-Warning $Files

    # Source the function
    # . $FunctionPath
    # Invoke PSSA, redirecting all Write-Outputs to $Output
    # $Output = Invoke-PSSA -DebuggingMode $false -RepoPath $RepoRootPath
    # Write-Warning $Output
    # $Module = Get-Module -ListAvailable -Name 'PSScriptAnalyzer'
    # $Module | Should -Not -BeNullOrEmpty
    # $Output | Should -Not -BeNullOrEmpty
    # # Note: This is a little bit fragile.  It only work as long as one of these two
    # # summary statements is the final output written.
    # $Output | Select-Object -Last 1 | Should -BeIn @("Problems were found in the PowerShell scripts.", "No problems were found in the PowerShell scripts.")
  }
}