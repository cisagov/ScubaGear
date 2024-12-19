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
    $ToolPath = (Get-Command AzureSignTool).Path
    Write-Warning "The path to AzureSignTool is $ToolPath"
    Test-Path -Path $ToolPath | Should -Be $true
  }
}