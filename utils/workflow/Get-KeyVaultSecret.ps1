#Requires -Version 5.1

<#
.SYNOPSIS
    Shared functions for Azure Key Vault operations
.DESCRIPTION
    Provides reusable functions for parsing Key Vault configuration and
    retrieving secrets, used across multiple ScubaGear workflows.
#>

function Get-KeyVaultInfo {
    <#
    .SYNOPSIS
        Extracts Azure Key Vault information from a JSON configuration string
    .DESCRIPTION
        Parses the Key Vault configuration JSON and returns the KeyVaultUrl
        and CertificateName for code signing
    .PARAMETER KeyVaultInfo
        The JSON string containing key vault configuration
    .EXAMPLE
        $info = Get-KeyVaultInfo -KeyVaultInfo $env:KEY_VAULT_INFO
    .OUTPUTS
        PSObject with KeyVaultUrl and KeyVaultCertificateName properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyVaultInfo
    )

    try {
        Write-Verbose "Parsing Key Vault information..."
        $KeyVaultData = $KeyVaultInfo | ConvertFrom-Json

        if (-not $KeyVaultData.KeyVault) {
            throw "KeyVault property not found in configuration"
        }

        if (-not $KeyVaultData.KeyVault.URL) {
            throw "KeyVault URL not found in configuration"
        }

        if (-not $KeyVaultData.KeyVault.CertificateName) {
            throw "KeyVault CertificateName not found in configuration"
        }

        $Result = [PSCustomObject]@{
            KeyVaultUrl            = $KeyVaultData.KeyVault.URL
            KeyVaultCertificateName = $KeyVaultData.KeyVault.CertificateName
        }

        Write-Verbose "Successfully parsed Key Vault info: URL=$($Result.KeyVaultUrl), Cert=$($Result.KeyVaultCertificateName)"
        return $Result
    }
    catch {
        Write-Error "Failed to parse Key Vault information: $($_.Exception.Message)"
        throw
    }
}

function Get-KeyVaultSecret {
    <#
    .SYNOPSIS
        Retrieves a secret from Azure Key Vault
    .DESCRIPTION
        Uses Azure CLI to retrieve a named secret from the specified Key Vault.
        Requires a prior azure/login or az login session.
    .PARAMETER KeyVaultUrl
        The Azure Key Vault URL
    .PARAMETER SecretName
        The name of the secret to retrieve
    .EXAMPLE
        $value = Get-KeyVaultSecret -KeyVaultUrl "https://my-vault.vault.azure.net/" -SecretName "my-secret"
    .OUTPUTS
        String containing the secret value
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyVaultUrl,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SecretName
    )

    try {
        Write-Verbose "Retrieving secret '$SecretName' from Key Vault..."
        $SecretUri = "$KeyVaultUrl/secrets/$SecretName"
        $Value = az keyvault secret show --id $SecretUri --query value -o tsv
    }
    catch {
        Write-Error "Failed to retrieve Key Vault secret '$SecretName': $($_.Exception.Message)"
        throw
    }

    if (-not $Value) {
        throw "Failed to retrieve secret '$SecretName' from Key Vault"
    }

    Write-Verbose "Successfully retrieved secret '$SecretName'"
    return $Value
}
