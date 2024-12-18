# temp placeholder for a real test
Describe "Install AST Check" {
  It "Should be installed" {
    $ToolPath = (Get-Command AzureSignTool).Path
    Write-Warning "The path to AzureSignTool is $ToolPath"
    Test-Path -Path $TooPath | Should -Be -True
  }
}