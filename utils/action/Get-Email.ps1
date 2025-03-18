function Get-Email {
    <#
        .SYNOPSIS
            Extracts the email address from the params.
        .PARAMETER ProductAlias
            The alias used in the parameters secret to denote a given tenant, product, variant combo.
        .PARAMETER Params
            The set of parameters (typically stored as a secret) from which the email is extracted.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $ProductAlias,
        [Parameter(Mandatory = $true)]
        [string]
        $Params
    )

    Write-Warning "Getting the email..."

    $products = $Params.split("|")
    foreach ($product in $products)
    {
        [String]$emails = ""
        $attributes = $product.split(",")
        foreach ($attribute in $attributes)
        {
            # Split the key from the value
            $keyAndValue = $attribute.split("=")
            $key = $keyAndValue[0]
            $value = $keyAndValue[1]
            if($key.ToLower() -eq "alias")
            {
                $alias = $value
            }
            elseif($key.ToLower() -eq "emails")
            {
                $emails = $value
            }
        }
        if($alias -eq $ProductAlias)
        {
            return $emails
            break
        }
    }
    return ""
}