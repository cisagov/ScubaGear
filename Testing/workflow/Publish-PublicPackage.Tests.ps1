#Requires -Version 5.1

<#
.SYNOPSIS
    Functions for publishing ScubaGear to public packages (PSGallery)
.DESCRIPTION
    This module contains functions extracted from the publish_public_package.yaml workflow
    to make the workflow logic testable and reusable.
#>

function Get-KeyVaultInfo {
    <#
    .SYNOPSIS
        Extracts Azure Key Vault information from environment variable
    .DESCRIPTION
        Parses the KEY_VAULT_INFO environment variable JSON and returns
        the KeyVaultUrl and CertificateName for code signing
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
            KeyVaultUrl = $KeyVaultData.KeyVault.URL
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

function Remove-GitFiles {
    <#
    .SYNOPSIS
        Removes git-related files from the repository
    .DESCRIPTION
        Removes .git* files and directories from the specified root folder
        to clean up the repository for publishing
    .PARAMETER RootFolderPath
        The root folder path to clean
    .EXAMPLE
        Remove-GitFiles -RootFolderPath "repo"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RootFolderPath
    )

    try {
        Write-Verbose "Removing git files from: $RootFolderPath"

        if (-not (Test-Path -Path $RootFolderPath)) {
            throw "Root folder path does not exist: $RootFolderPath"
        }

        # Remove git files and directories
        $GitItems = Get-ChildItem -Path $RootFolderPath -Include ".git*" -Recurse -Force -ErrorAction SilentlyContinue

        if ($GitItems) {
            foreach ($Item in $GitItems) {
                Write-Verbose "Removing: $($Item.FullName)"
                Remove-Item -Path $Item.FullName -Recurse -Force
            }
            Write-Verbose "Successfully removed $($GitItems.Count) git-related items"
        } else {
            Write-Verbose "No git files found to remove"
        }
    }
    catch {
        Write-Error "Failed to remove git files: $($_.Exception.Message)"
        throw
    }
}

function Set-PublishParameters {
    <#
    .SYNOPSIS
        Sets up parameters for publishing to PSGallery
    .DESCRIPTION
        Creates a hashtable of parameters for the Publish-ScubaGearModule function
        based on workflow inputs and configuration
    .PARAMETER AzureKeyVaultUrl
        The Azure Key Vault URL for code signing
    .PARAMETER CertificateName
        The certificate name for code signing
    .PARAMETER ModuleSourcePath
        The source path of the module to publish
    .PARAMETER ApiKey
        The PSGallery API key
    .PARAMETER IsPrerelease
        Whether this is a prerelease version
    .PARAMETER PrereleaseTag
        The prerelease tag if IsPrerelease is true
    .PARAMETER OverrideModuleVersion
        Optional version override
    .EXAMPLE
        $params = Set-PublishParameters -AzureKeyVaultUrl $vaultUrl -CertificateName $certName -ModuleSourcePath $path -ApiKey $key
    .OUTPUTS
        Hashtable containing parameters for Publish-ScubaGearModule
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AzureKeyVaultUrl,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleSourcePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiKey,

        [Parameter(Mandatory = $false)]
        [bool]$IsPrerelease = $false,

        [Parameter(Mandatory = $false)]
        [string]$PrereleaseTag = "",

        [Parameter(Mandatory = $false)]
        [string]$OverrideModuleVersion = ""
    )

    try {
        Write-Verbose "Setting up publish parameters..."

        # Validate module source path exists
        if (-not (Test-Path -Path $ModuleSourcePath -PathType Container)) {
            throw "Module source path does not exist: $ModuleSourcePath"
        }

        # Setup base parameters
        $Parameters = @{
            AzureKeyVaultUrl = $AzureKeyVaultUrl
            CertificateName = $CertificateName
            ModuleSourcePath = $ModuleSourcePath
            GalleryName = 'PSGallery'
            NuGetApiKey = $ApiKey
        }

        # Add prerelease tag if specified
        if ($IsPrerelease -and -not [string]::IsNullOrEmpty($PrereleaseTag)) {
            Write-Verbose "Adding prerelease tag: $PrereleaseTag"
            $Parameters.Add('PrereleaseTag', $PrereleaseTag)
        }

        # Add module version override if specified
        if (-not [string]::IsNullOrEmpty($OverrideModuleVersion)) {
            Write-Verbose "Adding version override: $OverrideModuleVersion"
            $Parameters.Add('OverrideModuleVersion', $OverrideModuleVersion)
        }

        Write-Verbose "Successfully configured publish parameters"
        return $Parameters
    }
    catch {
        Write-Error "Failed to set publish parameters: $($_.Exception.Message)"
        throw
    }
}

function Test-PublishedModule {
    <#
    .SYNOPSIS
        Tests that the module was successfully published to PSGallery
    .DESCRIPTION
        Verifies that the published module can be found in PSGallery with the expected version
    .PARAMETER IsPrerelease
        Whether to check for a prerelease version
    .PARAMETER ModuleVersion
        The expected module version
    .PARAMETER PrereleaseTag
        The prerelease tag if IsPrerelease is true
    .PARAMETER WaitSeconds
        Number of seconds to wait before testing (default: 30)
    .EXAMPLE
        Test-PublishedModule -IsPrerelease $false
        Test-PublishedModule -IsPrerelease $true -ModuleVersion "1.3.0" -PrereleaseTag "alpha1"
    .OUTPUTS
        Boolean indicating whether the module was found
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$IsPrerelease,

        [Parameter(Mandatory = $false)]
        [string]$ModuleVersion = "",

        [Parameter(Mandatory = $false)]
        [string]$PrereleaseTag = "",

        [Parameter(Mandatory = $false)]
        [int]$WaitSeconds = 30
    )

    try {
        Write-Verbose "Testing published module..."

        # Wait for PSGallery to update
        if ($WaitSeconds -gt 0) {
            Write-Verbose "Waiting $WaitSeconds seconds for PSGallery to update..."
            Start-Sleep -Seconds $WaitSeconds
        }

        if ($IsPrerelease) {
            if ([string]::IsNullOrEmpty($ModuleVersion) -or [string]::IsNullOrEmpty($PrereleaseTag)) {
                throw "ModuleVersion and PrereleaseTag are required when IsPrerelease is true"
            }

            $RequiredVersion = "$ModuleVersion-$PrereleaseTag"
            Write-Verbose "Checking for prerelease version: $RequiredVersion"

            $Module = Find-Module -Name ScubaGear -RequiredVersion $RequiredVersion -AllowPrerelease -ErrorAction SilentlyContinue
        } else {
            Write-Verbose "Checking for latest stable version"
            $Module = Find-Module -Name ScubaGear -ErrorAction SilentlyContinue
        }

        if ($Module) {
            Write-Verbose "Successfully found module: $($Module.Name) version $($Module.Version)"
            return $true
        } else {
            Write-Verbose "Module not found in PSGallery"
            return $false
        }
    }
    catch {
        Write-Error "Failed to find published module: $($_.Exception.Message)"
        return $false
    }
}

function Get-PSGalleryApiKey {
    <#
    .SYNOPSIS
        Retrieves the PSGallery API key from Azure Key Vault
    .DESCRIPTION
        Uses Azure CLI to retrieve the ScubaGear PSGallery API key from the specified Key Vault
    .PARAMETER KeyVaultUrl
        The Azure Key Vault URL containing the API key
    .PARAMETER SecretName
        The name of the secret containing the API key (default: ScubaGear-PSGAllery-API-Key)
    .EXAMPLE
        $apiKey = Get-PSGalleryApiKey -KeyVaultUrl $vaultUrl
    .OUTPUTS
        String containing the API key
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyVaultUrl,

        [Parameter(Mandatory = $false)]
        [string]$SecretName = "ScubaGear-PSGAllery-API-Key"
    )

    try {
        Write-Verbose "Retrieving PSGallery API key from Key Vault..."

        $SecretUri = "$KeyVaultUrl/secrets/$SecretName"
        $ApiKey = az keyvault secret show --id $SecretUri --query value -o tsv

        if (-not $ApiKey) {
            throw "Failed to retrieve API key from Key Vault"
        }

        Write-Verbose "Successfully retrieved API key"
        return $ApiKey
    }
    catch {
        Write-Error "Failed to retrieve PSGallery API key: $($_.Exception.Message)"
        throw
    }
}
