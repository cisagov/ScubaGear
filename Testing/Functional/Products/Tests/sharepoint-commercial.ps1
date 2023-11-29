# James Garriss
# Nov 2023
# The purpose of this script is to run the functional tests for a product.

# $thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Setup directories
$thisDir = Get-Location
$testScriptDir = Join-Path -Path $thisDir -ChildPath ..

# Setup an array of test containers
$TestContainers = @()
$TestContainers += New-PesterContainer -Path $testScriptDir -Data @{ `
    # Thumbprint = "FD6219CFBF937830616E43DF9C81BCF7D22FE03F"; `
    Thumbprint = $Args[0] # 1st command line argument
    TenantDomain = "y2zj1.onmicrosoft.com"; `
    TenantDisplayName = "y2zj1"; `
    AppId = "db791fde-1ff0-493f-be3d-03d9ba6cb087"; `
    ProductName = "sharepoint"; `
    Variant = "pnp"; `
    M365Environment = "commercial" `
}

# Invoke Pester for each test container.
Invoke-Pester -Container $TestContainers -Output Detailed