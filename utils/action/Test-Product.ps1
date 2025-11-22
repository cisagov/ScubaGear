function Test-Product {
    <#
        .SYNOPSIS
            Runs the Pester tests for a given product.
        .PARAMETER Thumbprint
            The certificate thumbprint to use for authentication.
        .PARAMETER ProductAlias
            The alias used in the parameters secret to denote a given tenant, product, variant combo.
        .PARAMETER TestParams
            The set of parameters (stored as a secret) containing a given environment's alias, tenant domain, etc.            
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Thumbprint,
        [Parameter(Mandatory = $true)]
        [string]
        $ProductAlias,
        [Parameter(Mandatory = $true)]
        [string]
        $TestParams
    )

    Write-Warning "Running tests for product: $ProductAlias"

    $aliasExists = $false
    $products = $TestParams.split("|")
    foreach ($product in $products) {
        [String]$alias = ""
        [String]$domain = ""
        [String]$display = ""
        [String]$appid = ""
        [String]$productname = ""
        [String]$variant = ""
        [String]$m365 = ""
        $paramsAsHashTable = @{}

        $attributes = $product.split(",")
        foreach ($attribute in $attributes) {
            # Split the key from the value
            $keyAndValue = $attribute.split("=")
            $key = $keyAndValue[0]
            $value = $keyAndValue[1]
            if ($key.ToLower() -eq "alias") { $alias = $value }
            elseif ($key.ToLower() -eq "tenantdomain") { $domain = $attribute }
            elseif ($key.ToLower() -eq "tenantdisplayname") { $display = $attribute }
            elseif ($key.ToLower() -eq "appid") { $appid = $attribute }
            elseif ($key.ToLower() -eq "productname") { $productname = $attribute }
            elseif ($key.ToLower() -eq "variant") { $variant = $attribute }
            elseif ($key.ToLower() -eq "m365environment") { $m365 = $attribute }
        }

        if($alias -eq $productAlias) {
            $aliasExists = $true

            # Split out the key and value for each parameter
            $domainKeyAndValue = $domain.split("=")
            $displayKeyAndValue = $display.split("=")
            $appidKeyAndValue = $appid.split("=")
            $productnameKeyAndValue = $productname.split("=")
            $m365KeyAndValue =$m365.split("=")
            $variantKeyAndValue = $variant.split("=")

            # Add both to the hash table
            $paramsAsHashTable.Add($domainKeyAndValue[0], $domainKeyAndValue[1])
            $paramsAsHashTable.Add($displayKeyAndValue[0], $displayKeyAndValue[1])
            $paramsAsHashTable.Add($appidKeyAndValue[0], $appidKeyAndValue[1])
            $paramsAsHashTable.Add($productnameKeyAndValue[0], $productnameKeyAndValue[1])
            $paramsAsHashTable.Add($m365KeyAndValue[0], $m365KeyAndValue[1])

            if($variantKeyAndValue[0] -ne "") {
              $paramsAsHashTable.Add($variantKeyAndValue[0], $variantKeyAndValue[1])
            }

            # Test the product
            ./Testing/Functional/Products/Tests/CallProductTests.ps1 -params $paramsAsHashTable -thumbprint $thumbprint
        }
    }

    if (-not $aliasExists) {
        Write-Error "No test parameters found for alias '$ProductAlias'. Please check that TestParams includes 'alias=$ProductAlias'."
        exit 1
    }
}