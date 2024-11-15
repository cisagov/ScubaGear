# The purpose of this tset is to verify that PSSA is working.

# Suppress PSSA warnings here at the root of the test file.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeDiscovery {
  # Arrange to capture the output
  $Output = @()
  $OriginalWriteOutput = $ExecutionContext.SessionState.InvokeCommand.GetCommand('Write-Output', 'All').ScriptBlock
  $ExecutionContext.SessionState.InvokeCommand.SetCommand('Write-Output', { param($Message) $Output += $Message }, 'All')

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
  It "PSSA should write final output" {
    $Output | Should -Contain "Problems were found in the PowerShell scripts." -or $Output | Should -Contain "No problems were found in the PowerShell scripts."
  }
}

# AfterAll {
#   # Cleanup
#   $ExecutionContext.SessionState.InvokeCommand.SetCommand('Write-Output', $OriginalWriteOutput, 'All')
# }