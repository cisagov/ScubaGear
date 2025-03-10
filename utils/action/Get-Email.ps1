function Get-Email {
    <#
        .SYNOPSIS
            Extracts the email address from the params.
        .PARAMETER ProductAlias
            The alias used in the parameters secret to denote a given tenant, product, variant combo.
        .PARAMETER Params
            The set of parameters stored as a secret.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        ProductAlias,
        [Parameter(Mandatory = $true)]
        [string]
        Params
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
            # Pass emails to later job for notification.
            # echo emails=$emails >> $env:GITHUB_OUTPUT
            return emails
        break
        }
    }
    return ""
}