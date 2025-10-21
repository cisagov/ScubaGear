function Install-AzureSignTool {
  <#
    .SYNOPSIS
      Install Azure Signing Tool
  #>

  Write-Warning "Installing AST..."

  dotnet tool install --global AzureSignTool --version 6.0.1
}