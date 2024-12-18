# The purpose of this test is to verify that Azure Sign Tool is working.

BeforeDiscovery {
  $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Build-SignRelease.ps1' -Resolve
  # Source the function
  . $ScriptPath
  Install-AzureSigningTool
}

Describe "AST Check" {
  It "AST should be installed" {
    $Commands = Get-Command AzureSignTool
    Write-Warning "The commands are"
    Write-Warning $Commands
    Write-Warning "The type of commands"
    Write-Warning $Commands.GetType()
    $ToolPath = (Get-Command AzureSignTool).Path
    Write-Warning "The path to AzureSignTool is $ToolPath"
    Test-Path -Path $TooPath | Should -Be -True
  }
}