# The purpose of this script is to enable a GitHub Action workflow to
# run the functional tests for all the products.
# NOTE: At the moment it only does this for one product, Sharepoint.  Others
#       will be added.
# To run this script, call it from the root of the repo, like so:
# ./Testing/Functional/Products/Tests/CallProductTests.ps1 <value of thumbprint>

# The thumbprint of the cert used to access the product.
$thumbprint = $args[0]

# Setup directories
$testDataFile = 'Testing/Functional/Products/Tests/TestData/sharepoint-commercial-data.pson'
$testScriptDir = 'Testing/Functional/Products'

# TODO: Eventually this hardcoded file should be replaced by reading all the .pson
#       files in the TestData folder.  Instead of just a hashtable of params, it
#       will be an array of hashtables of params.
$params = Import-PowerShellDataFile $testDataFile

# Add thumbprint to hashtable
# TODO: When the hardcoded file is replaced, this will need to be added to each
#       hashtable in the array.
$params["Thumbprint"] = $thumbprint

# Create an array of test containers
$testContainers = @()
$testContainers += New-PesterContainer -Path $testScriptDir -Data $params

# Invoke Pester for each test container
Invoke-Pester -Container $testContainers -Output Detailed