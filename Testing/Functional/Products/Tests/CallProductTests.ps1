<#
    .SYNOPSIS
    The purpose of this script is to enable a GitHub Action workflow to run the functional tests for all the products.
    .EXAMPLE
    To run this script, call it from the root of the repo, like so: ./Testing/Functional/Products/Tests/CallProductTests.ps1 <params> <thumbprint>
    .NOTES
    At the moment this script is only used for one product, Sharepoint.  Others will be added over time.
#>

param(
    # The hashtable with the params.
    # TODO: For now, this is a hashtable.  Eventually it will need to be an array of hashtables,
    #       one for each product/tenant tested.
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
# TODO: When params becomes an array of hashtables, this will need to be added to each
#       hashtable in the array.
$params["Thumbprint"] = $thumbprint

# Create an array of test containers
$testContainers = @()
$testContainers += New-PesterContainer -Path $testScriptDir -Data $params

# Invoke Pester for each test container
Invoke-Pester -Container $testContainers -Output Detailed
