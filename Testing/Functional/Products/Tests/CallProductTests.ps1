<#
    .SYNOPSIS
    The purpose of this script is to enable a GitHub Action workflow to run the functional tests for one product.
    .EXAMPLE
    To run this script, call it from the root of the repo, like so: ./Testing/Functional/Products/Tests/CallProductTests.ps1 <params> <thumbprint>
#>

param(
    # The hashtable with the params.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [hashtable]$params,
    # The thumbprint of the cert used to access the product.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$thumbprint
)

$testScriptDir = 'Testing/Functional/Products'

# Add thumbprint to hashtable
$params["Thumbprint"] = $thumbprint

# Create an array of test containers
$testContainers = @()
$testContainers += New-PesterContainer -Path $testScriptDir -Data $params

# Invoke Pester for each test container
Invoke-Pester -Container $testContainers -Output Detailed
