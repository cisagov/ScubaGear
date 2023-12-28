# The purpose of this script is to enable a GitHub Action workflow to
# run the functional tests for all the products.
# NOTE: At the moment it only does this for one product, Sharepoint.  Others
#       will be added.

# The hashtable with the params.
# TODO: For now, this is a hashtable.  Eventually it will need to be an array of hashtables,
#       one for each product/tenant tested.
# The replace and convert commands are used to convert the string (from the GitHub secret) into a hashtable.
$params = $args[0] -replace '@{' -replace '}' -replace ';',"`n" -replace "'" | ConvertFrom-StringData

# The thumbprint of the cert used to access the product.
$thumbprint = $args[1]

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