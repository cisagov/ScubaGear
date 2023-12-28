# The purpose of this script is to enable a GitHub Action workflow to
# run the functional tests for all the products.
# NOTE: At the moment it only does this for one product, Sharepoint.  Others
#       will be added.
# To run this script, call it from the root of the repo, like so:
# ./Testing/Functional/Products/Tests/CallProductTests.ps1 <params as a hashtable> <value of thumbprint>

# The hashtable with the params.
# TODO: For now, this is a hashtable.  Eventually it will need to be an array of hashtables,
#       one for each product/tenant tested.
$params = $args[0]
Write-Host "Params"
Write-Host $params
Write-Host $params.GetType()

# The thumbprint of the cert used to access the product.
$thumbprint = $args[1]
Write-Host "Thumbprint"
Write-Host $thumbprint
Write-Host $thumbprint.GetType()

# TODO: Remove these and get params from the args.
# $testDataFile = 'Testing/Functional/Products/Tests/TestData/sharepoint-commercial-data.pson'
# $testScriptDir = 'Testing/Functional/Products'
# $params = Import-PowerShellDataFile $testDataFile

# Add thumbprint to hashtable
# TODO: When params becomes an array of hashtables, this will need to be added to each
#       hashtable in the array.
$params["Thumbprint"] = $thumbprint

# Create an array of test containers
$testContainers = @()
$testContainers += New-PesterContainer -Path $testScriptDir -Data $params

# Invoke Pester for each test container
Invoke-Pester -Container $testContainers -Output Detailed