# temp placeholder for a real test
Describe "Install AST Check" {
  $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../../utils/workflow/Build-SignRelease.ps1' -Resolve
  # Source the function
  . $ScriptPath
  Install-AzureSigningTool
  It "Should be installed" {
    $ToolPath = (Get-Command AzureSignTool).Path
    Write-Warning "The path to AzureSignTool is $ToolPath"
    Test-Path -Path $TooPath | Should -Be -True
  }
}