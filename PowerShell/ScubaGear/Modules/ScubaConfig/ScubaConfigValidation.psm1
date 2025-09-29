# ScubaGear Configuration Validation Functions
# Import required modules
Import-Module powershell-yaml -ErrorAction Stop

# Module-level variables for configuration
$script:ConfigDefaults = $null
$script:ConfigSchema = $null
$script:ModulePath = $PSScriptRoot

function Initialize-ScubaConfigValidator {
    <#
    .SYNOPSIS
    Initializes the configuration validator
    #>
    param(
        [string]$ModulePath = $PSScriptRoot
    )

    $script:ModulePath = $ModulePath
    Import-ConfigurationSchema
    Import-ConfigurationDefaults
}

function Import-ConfigurationSchema {
    <#
    .SYNOPSIS
    Loads the JSON schema for configuration validation
    #>
    $SchemaPath = Join-Path -Path $script:ModulePath -ChildPath "ScubaConfigSchema.json"
    if (-not (Test-Path -Path $SchemaPath)) {
        throw "Schema file not found: $SchemaPath"
    }

    try {
        $SchemaContent = Get-Content -Path $SchemaPath -Raw -Encoding UTF8
        $script:ConfigSchema = $SchemaContent | ConvertFrom-Json -Depth 20
        Write-Verbose "Configuration schema loaded successfully"
    }
    catch {
        throw "Failed to load configuration schema: $($_.Exception.Message)"
    }
}

function Import-ConfigurationDefaults {
    <#
    .SYNOPSIS
    Loads the default configuration values
    #>
    $DefaultsPath = Join-Path -Path $script:ModulePath -ChildPath "ScubaConfigDefaults.json"
    if (-not (Test-Path -Path $DefaultsPath)) {
        throw "Defaults file not found: $DefaultsPath"
    }

    try {
        $DefaultsContent = Get-Content -Path $DefaultsPath -Raw -Encoding UTF8
        $script:ConfigDefaults = $DefaultsContent | ConvertFrom-Json -Depth 20
        Write-Verbose "Configuration defaults loaded successfully"
    }
    catch {
        throw "Failed to load configuration defaults: $($_.Exception.Message)"
    }
}

function Get-ScubaConfigDefaults {
    <#
    .SYNOPSIS
    Returns the configuration defaults
    #>
    if ($null -eq $script:ConfigDefaults) {
        Initialize-ScubaConfigValidator
    }
    return $script:ConfigDefaults
}

function Get-ScubaConfigSchema {
    <#
    .SYNOPSIS
    Returns the configuration schema
    #>
    if ($null -eq $script:ConfigSchema) {
        Initialize-ScubaConfigValidator
    }
    return $script:ConfigSchema
}

function Test-ScubaConfigFile {
    <#
    .SYNOPSIS
    Validates a ScubaGear YAML configuration file
    .PARAMETER FilePath
    Path to the YAML configuration file to validate
    .RETURNS
    PSCustomObject with validation results
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Initialize if needed
    if ($null -eq $script:ConfigDefaults -or $null -eq $script:ConfigSchema) {
        Initialize-ScubaConfigValidator
    }

    $Result = [PSCustomObject]@{
        IsValid = $false
        ValidationErrors = @()
        Warnings = @()
        ParsedContent = $null
    }

    # Check if file exists
    if (-not (Test-Path -PathType Leaf -Path $FilePath)) {
        $Result.ValidationErrors += "Configuration file not found: $FilePath"
        return $Result
    }

    # Check file extension
    $Extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $SupportedExtensions = $script:ConfigDefaults.validation.supportedFileExtensions
    if ($Extension -notin $SupportedExtensions) {
        $Result.ValidationErrors += "Unsupported file extension '$Extension'. Supported extensions: $($SupportedExtensions -join ', ')"
        return $Result
    }

    # Check file size
    $FileInfo = Get-Item -Path $FilePath
    $MaxSize = $script:ConfigDefaults.validation.maxFileSizeBytes
    if ($FileInfo.Length -gt $MaxSize) {
        $Result.ValidationErrors += "File size ($($FileInfo.Length) bytes) exceeds maximum allowed size ($MaxSize bytes)"
        return $Result
    }

    # Parse YAML content
    try {
        $Content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $YamlObject = $Content | ConvertFrom-Yaml
        $Result.ParsedContent = $YamlObject
    }
    catch {
        $Result.ValidationErrors += "Failed to parse YAML content: $($_.Exception.Message)"
        return $Result
    }

    # Validate against schema
    $SchemaValidation = Test-ConfigurationAgainstSchema -ConfigObject $YamlObject
    $Result.ValidationErrors += $SchemaValidation.Errors
    $Result.Warnings += $SchemaValidation.Warnings

    # Additional business logic validation
    $BusinessValidation = Test-ConfigurationBusinessRules -ConfigObject $YamlObject
    $Result.ValidationErrors += $BusinessValidation.Errors
    $Result.Warnings += $BusinessValidation.Warnings

    $Result.IsValid = ($Result.ValidationErrors.Count -eq 0)
    return $Result
}

function Test-ConfigurationAgainstSchema {
    <#
    .SYNOPSIS
    Validates configuration object against the JSON schema
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$ConfigObject
    )

    $Validation = [PSCustomObject]@{
        Errors = @()
        Warnings = @()
    }

    # Validate required properties
    if ($script:ConfigSchema.required) {
        foreach ($RequiredProp in $script:ConfigSchema.required) {
            $HasProperty = $false
            if ($ConfigObject -is [hashtable]) {
                $HasProperty = $ConfigObject.ContainsKey($RequiredProp)
            } else {
                $HasProperty = $ConfigObject.PSObject.Properties.Name.Contains($RequiredProp)
            }

            if (-not $HasProperty) {
                $Validation.Errors += "Required property '$RequiredProp' is missing"
            }
        }
    }

    # Validate ProductNames
    $ProductNames = if ($ConfigObject -is [hashtable]) { $ConfigObject['ProductNames'] } else { $ConfigObject.ProductNames }
    if ($ProductNames) {
        $ValidProducts = $script:ConfigSchema.properties.ProductNames.items.enum
        foreach ($Product in $ProductNames) {
            if ($Product -notin $ValidProducts) {
                $Validation.Errors += "Invalid product name '$Product'. Valid products: $($ValidProducts -join ', ')"
            }
        }

        # Handle wildcard
        if ($ProductNames -contains '*') {
            if ($ProductNames.Count -gt 1) {
                $Validation.Warnings += "Wildcard '*' found with other products. All products will be selected."
            }
        }
    }

    # Validate M365Environment
    $M365Environment = if ($ConfigObject -is [hashtable]) { $ConfigObject['M365Environment'] } else { $ConfigObject.M365Environment }
    if ($M365Environment) {
        $ValidEnvironments = $script:ConfigSchema.properties.M365Environment.enum
        if ($M365Environment -notin $ValidEnvironments) {
            $Validation.Errors += "Invalid M365Environment '$M365Environment'. Valid environments: $($ValidEnvironments -join ', ')"
        }
    }

    # Validate Organization format
    $Organization = if ($ConfigObject -is [hashtable]) { $ConfigObject['Organization'] } else { $ConfigObject.Organization }
    if ($Organization) {
        $OrgPattern = $script:ConfigSchema.properties.Organization.pattern
        if ($Organization -notmatch $OrgPattern) {
            $Validation.Errors += "Organization '$Organization' does not match required format (e.g., example.onmicrosoft.com)"
        }
    }

    # Validate AppId format
    $AppId = if ($ConfigObject -is [hashtable]) { $ConfigObject['AppId'] } else { $ConfigObject.AppId }
    if ($AppId) {
        $GuidPattern = $script:ConfigSchema.properties.AppId.pattern
        if ($AppId -notmatch $GuidPattern) {
            $Validation.Errors += "AppId '$AppId' is not a valid GUID format"
        }
    }

    # Validate CertificateThumbprint format
    $CertificateThumbprint = if ($ConfigObject -is [hashtable]) { $ConfigObject['CertificateThumbprint'] } else { $ConfigObject.CertificateThumbprint }
    if ($CertificateThumbprint) {
        $ThumbprintPattern = $script:ConfigSchema.properties.CertificateThumbprint.pattern
        if ($CertificateThumbprint -notmatch $ThumbprintPattern) {
            $Validation.Errors += "CertificateThumbprint '$CertificateThumbprint' must be 40 hexadecimal characters"
        }
    }    return $Validation
}

function Test-ConfigurationBusinessRules {
    <#
    .SYNOPSIS
    Validates configuration object against business rules
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$ConfigObject
    )

    $Validation = [PSCustomObject]@{
        Errors = @()
        Warnings = @()
    }

    # Get values accounting for hashtable vs PSObject
    $OmitPolicy = if ($ConfigObject -is [hashtable]) { $ConfigObject['OmitPolicy'] } else { $ConfigObject.OmitPolicy }
    $AnnotatePolicy = if ($ConfigObject -is [hashtable]) { $ConfigObject['AnnotatePolicy'] } else { $ConfigObject.AnnotatePolicy }
    $ExclusionsConfig = if ($ConfigObject -is [hashtable]) { $ConfigObject['ExclusionsConfig'] } else { $ConfigObject.ExclusionsConfig }
    $ProductNames = if ($ConfigObject -is [hashtable]) { $ConfigObject['ProductNames'] } else { $ConfigObject.ProductNames }
    $OPAPath = if ($ConfigObject -is [hashtable]) { $ConfigObject['OPAPath'] } else { $ConfigObject.OPAPath }

    # Validate policy IDs in OmitPolicy
    if ($OmitPolicy) {
        $PolicyKeys = if ($OmitPolicy -is [hashtable]) { $OmitPolicy.Keys } else { $OmitPolicy.PSObject.Properties.Name }
        foreach ($PolicyId in $PolicyKeys) {
            $PolicyValidation = Test-PolicyId -PolicyId $PolicyId -ProductNames $ProductNames
            if (-not $PolicyValidation.IsValid) {
                $Validation.Errors += $PolicyValidation.Error
            }
        }
    }

    # Validate policy IDs in AnnotatePolicy
    if ($AnnotatePolicy) {
        $PolicyKeys = if ($AnnotatePolicy -is [hashtable]) { $AnnotatePolicy.Keys } else { $AnnotatePolicy.PSObject.Properties.Name }
        foreach ($PolicyId in $PolicyKeys) {
            $PolicyValidation = Test-PolicyId -PolicyId $PolicyId -ProductNames $ProductNames
            if (-not $PolicyValidation.IsValid) {
                $Validation.Errors += $PolicyValidation.Error
            }
        }
    }

    # Validate exclusions configuration
    if ($ExclusionsConfig) {
        $ExclusionValidation = Test-ExclusionsConfiguration -ExclusionsConfig $ExclusionsConfig -ProductNames $ProductNames
        $Validation.Errors += $ExclusionValidation.Errors
        $Validation.Warnings += $ExclusionValidation.Warnings
    }

    # Validate OPA path if specified
    if ($OPAPath -and $OPAPath -ne ".") {
        if (-not (Test-Path -Path $OPAPath)) {
            $Validation.Warnings += "OPA path '$OPAPath' does not exist"
        }
    }

    return $Validation
}function Test-PolicyId {
    <#
    .SYNOPSIS
    Validates a policy ID format and product reference
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyId,

        [Parameter(Mandatory = $false)]
        [array]$ProductNames = @()
    )

    $Result = [PSCustomObject]@{
        IsValid = $false
        Error = ""
    }

    $PolicyPattern = $script:ConfigDefaults.validation.policyIdPattern

    if ($PolicyId -notmatch $PolicyPattern) {
        $Result.Error = "Policy ID '$PolicyId' does not match expected format. Expected: $($script:ConfigDefaults.validation.policyIdExample)"
        return $Result
    }

    # Extract product from policy ID
    $PolicyParts = $PolicyId -split "\."
    if ($PolicyParts.Length -ge 3) {
        $ProductInPolicy = $PolicyParts[1].ToLower()

        # Handle wildcard in ProductNames
        $EffectiveProducts = $ProductNames
        if ($ProductNames -contains '*') {
            $EffectiveProducts = $script:ConfigDefaults.defaults.AllProductNames
        }

        if ($script:ConfigDefaults.validation.requireProductInPolicy -and $ProductInPolicy -notin $EffectiveProducts) {
            $Result.Error = "Policy '$PolicyId' references product '$ProductInPolicy' which is not in the selected ProductNames: $($EffectiveProducts -join ', ')"
            return $Result
        }
    }

    $Result.IsValid = $true
    return $Result
}

function Test-ExclusionsConfiguration {
    <#
    .SYNOPSIS
    Validates exclusions configuration
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$ExclusionsConfig,

        [Parameter(Mandatory = $false)]
        [array]$ProductNames = @()
    )

    $Validation = [PSCustomObject]@{
        Errors = @()
        Warnings = @()
    }

    $ExclusionProductNames = if ($ExclusionsConfig -is [hashtable]) { $ExclusionsConfig.Keys } else { $ExclusionsConfig.PSObject.Properties.Name }

    foreach ($ProductName in $ExclusionProductNames) {
        # Check if product supports exclusions
        $ProductInfo = $script:ConfigDefaults.products.$ProductName
        if (-not $ProductInfo) {
            $Validation.Errors += "Unknown product '$ProductName' in exclusions configuration"
            continue
        }

        if (-not $ProductInfo.supportsExclusions) {
            $Validation.Errors += "Product '$ProductName' does not support exclusions"
            continue
        }

        # Check if product is in selected ProductNames
        $EffectiveProducts = $ProductNames
        if ($ProductNames -contains '*') {
            $EffectiveProducts = $script:ConfigDefaults.defaults.AllProductNames
        }

        if ($ProductName -notin $EffectiveProducts) {
            $Validation.Warnings += "Exclusions configured for '$ProductName' but product is not selected in ProductNames"
        }

        # Validate exclusion types for the product
        $ProductExclusions = if ($ExclusionsConfig -is [hashtable]) { $ExclusionsConfig[$ProductName] } else { $ExclusionsConfig.$ProductName }
        $ExclusionTypes = if ($ProductExclusions -is [hashtable]) { $ProductExclusions.Keys } else { $ProductExclusions.PSObject.Properties.Name }

        foreach ($ExclusionType in $ExclusionTypes) {
            if ($ExclusionType -notin $ProductInfo.supportedExclusionTypes) {
                $Validation.Errors += "Product '$ProductName' does not support exclusion type '$ExclusionType'. Supported types: $($ProductInfo.supportedExclusionTypes -join ', ')"
            }

            # Validate format based on exclusion type and product
            $ExclusionData = if ($ProductExclusions -is [hashtable]) { $ProductExclusions[$ExclusionType] } else { $ProductExclusions.$ExclusionType }
            $FormatValidation = Test-ExclusionFormat -ProductName $ProductName -ExclusionType $ExclusionType -ExclusionData $ExclusionData
            $Validation.Errors += $FormatValidation.Errors
            $Validation.Warnings += $FormatValidation.Warnings
        }
    }

    return $Validation
}

function Test-ExclusionFormat {
    <#
    .SYNOPSIS
    Validates the format of exclusion data based on product and type
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProductName,

        [Parameter(Mandatory = $true)]
        [string]$ExclusionType,

        [Parameter(Mandatory = $true)]
        [object]$ExclusionData
    )

    $Validation = [PSCustomObject]@{
        Errors = @()
        Warnings = @()
    }

    # Define patterns
    $GuidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    $UpnPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

    # Validate AAD exclusions (should use GUIDs)
    if ($ProductName -eq 'aad' -and $ExclusionType -in @('CapExclusions', 'RoleExclusions')) {
        $UserGroups = if ($ExclusionData -is [hashtable]) { $ExclusionData.Keys } else { $ExclusionData.PSObject.Properties.Name }

        foreach ($UserGroup in $UserGroups) {
            if ($UserGroup -in @('Users', 'Groups')) {
                $IdList = if ($ExclusionData -is [hashtable]) { $ExclusionData[$UserGroup] } else { $ExclusionData.$UserGroup }

                if ($IdList -and $IdList -is [array]) {
                    foreach ($Id in $IdList) {
                        if ($Id -notmatch $GuidPattern) {
                            $Validation.Errors += "$ProductName.$ExclusionType.$UserGroup contains invalid GUID format: '$Id'. Expected format: 12345678-1234-1234-1234-123456789abc"
                        }
                    }
                }
            }
        }
    }

    # Validate Defender SensitiveAccounts (should use UPNs for users)
    if ($ProductName -eq 'defender' -and $ExclusionType -eq 'SensitiveAccounts') {
        $AccountTypes = if ($ExclusionData -is [hashtable]) { $ExclusionData.Keys } else { $ExclusionData.PSObject.Properties.Name }

        foreach ($AccountType in $AccountTypes) {
            if ($AccountType -in @('IncludedUsers', 'ExcludedUsers')) {
                $UserList = if ($ExclusionData -is [hashtable]) { $ExclusionData[$AccountType] } else { $ExclusionData.$AccountType }

                if ($UserList -and $UserList -is [array]) {
                    foreach ($User in $UserList) {
                        if ($User -notmatch $UpnPattern) {
                            $Validation.Errors += "$ProductName.$ExclusionType.$AccountType contains invalid UPN format: '$User'. Expected format: user@domain.com"
                        }
                    }
                }
            }
        }
    }

    return $Validation
}

# Export functions
Export-ModuleMember -Function Initialize-ScubaConfigValidator, Get-ScubaConfigDefaults, Get-ScubaConfigSchema, Test-ScubaConfigFile, Test-ConfigurationAgainstSchema, Test-ConfigurationBusinessRules, Test-ExclusionsConfiguration, Test-ExclusionFormat
