# The purpose of this test is to verify that Azure Sign Tool is working.

BeforeDiscovery {
  $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Build-SignRelease.ps1' -Resolve
  # Source the function
  . $ScriptPath
  Install-AzureSigningTool
}

Describe "AST Check" {
  It "Dotnet should be installed" {
    $ToolPath = (Get-Command dotnet).Path
    Write-Warning "The path to dotnet is $ToolPath"
    Test-Path -Path $ToolPath | Should -Be $true
  }
  It "AST should be installed" {
    $ToolPath = (Get-Command AzureSignTool).Path
    Write-Warning "The path to AzureSignTool is $ToolPath"
    Test-Path -Path $ToolPath | Should -Be $true
  }
}