class ScubaConfigValidator {
    <#
    .SYNOPSIS
    Validates ScubaGear YAML configuration files against JSON schema
    .DESCRIPTION
    This class provides validation functionality for ScubaGear configuration files,
    ensuring they conform to the defined schema and contain valid values.
    #>

    hidden static [hashtable]$_Cache = @{}

    static [void] Initialize([string]$ModulePath) {
        [ScubaConfigValidator]::_Cache['ModulePath'] = $ModulePath
        [ScubaConfigValidator]::LoadSchema()
        [ScubaConfigValidator]::LoadDefaults()
    }

    hidden static [void] LoadSchema() {
        $ModulePath = [ScubaConfigValidator]::_Cache['ModulePath']
        $SchemaPath = Join-Path -Path $ModulePath -ChildPath "ScubaConfigSchema.json"
        if (-not (Test-Path -Path $SchemaPath)) {
            throw "Schema file not found: $SchemaPath"
        }
        try {
            $SchemaContent = Get-Content -Path $SchemaPath -Raw
            # PowerShell 5.1 compatible JSON parsing
            try {
                # Try with -Depth parameter first (PowerShell Core/7+)
                [ScubaConfigValidator]::_Cache['Schema'] = $SchemaContent | ConvertFrom-Json -Depth 20
            }
            catch {
                # Fall back to without -Depth parameter (PowerShell 5.1)
                [ScubaConfigValidator]::_Cache['Schema'] = $SchemaContent | ConvertFrom-Json
            }
        }
        catch {
            throw "Failed to load configuration schema: $($_.Exception.Message)"
        }
    }

    hidden static [void] LoadDefaults() {
        $ModulePath = [ScubaConfigValidator]::_Cache['ModulePath']
        $DefaultsPath = Join-Path -Path $ModulePath -ChildPath "ScubaConfigDefaults.json"
        if (-not (Test-Path -Path $DefaultsPath)) {
            throw "Defaults file not found: $DefaultsPath"
        }
        try {
            $DefaultsContent = Get-Content -Path $DefaultsPath -Raw
            # PowerShell 5.1 compatible JSON parsing
            try {
                # Try with -Depth parameter first (PowerShell Core/7+)
                [ScubaConfigValidator]::_Cache['Defaults'] = $DefaultsContent | ConvertFrom-Json -Depth 20
            }
            catch {
                # Fall back to without -Depth parameter (PowerShell 5.1)
                [ScubaConfigValidator]::_Cache['Defaults'] = $DefaultsContent | ConvertFrom-Json
            }
        }
        catch {
            throw "Failed to load configuration defaults: $($_.Exception.Message)"
        }
    }

    static [object] GetDefaults() {
        if (-not [ScubaConfigValidator]::_Cache.ContainsKey('Defaults')) {
            throw "Validator not initialized. Call Initialize() first."
        }
        return [ScubaConfigValidator]::_Cache['Defaults']
    }

    static [object] GetSchema() {
        if (-not [ScubaConfigValidator]::_Cache.ContainsKey('Schema')) {
            throw "Validator not initialized. Call Initialize() first."
        }
        return [ScubaConfigValidator]::_Cache['Schema']
    }

    static [ValidationResult] ValidateYamlFile([string]$FilePath) {
        # Add debug information to the result
        $DebugInfo = @("DEBUG: ValidateYamlFile called with: $FilePath")
        $Result = [ValidationResult]::new()
        $Result.IsValid = $false
        $Result.ValidationErrors = @()
        $Result.Warnings = @()

        # Check if file exists
        if (-not (Test-Path -PathType Leaf -Path $FilePath)) {
            $Result.ValidationErrors += "Configuration file not found: $FilePath"
            return $Result
        }

        # Check file extension
        $Extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        $ConfigDefaults = [ScubaConfigValidator]::GetDefaults()
        $SupportedExtensions = $ConfigDefaults.validation.supportedFileExtensions
        if ($Extension -notin $SupportedExtensions) {
            $Result.ValidationErrors += "Unsupported file extension '$Extension'. Supported extensions: $($SupportedExtensions -join ', ')"
            return $Result
        }

        # Check file size
        $FileInfo = Get-Item -Path $FilePath
        $MaxSize = $ConfigDefaults.validation.maxFileSizeBytes
        if ($FileInfo.Length -gt $MaxSize) {
            $Result.ValidationErrors += "File size ($($FileInfo.Length) bytes) exceeds maximum allowed size ($MaxSize bytes)"
            return $Result
        }

        # Parse YAML content
        try {
            $Content = Get-Content -Path $FilePath -Raw
            $YamlObject = $Content | ConvertFrom-Yaml
            $Result.ParsedContent = $YamlObject
        }
        catch {
            $Result.ValidationErrors += "Failed to parse YAML content: $($_.Exception.Message)"
            return $Result
        }

        # Validate against schema
        $DebugInfo += "DEBUG: About to call ValidateAgainstSchema with object type: $($YamlObject.GetType().Name)"
        $SchemaValidation = [ScubaConfigValidator]::ValidateAgainstSchema($YamlObject)
        $DebugInfo += "DEBUG: ValidateAgainstSchema returned with $($SchemaValidation.Errors.Count) errors"
        $Result.ValidationErrors += $SchemaValidation.Errors
        $Result.Warnings += $SchemaValidation.Warnings
        # Add debug info as warnings so we can see what happened
        $Result.Warnings += $DebugInfo

        # Additional business logic validation
        $BusinessValidation = [ScubaConfigValidator]::ValidateBusinessRules($YamlObject)
        $Result.ValidationErrors += $BusinessValidation.Errors
        $Result.Warnings += $BusinessValidation.Warnings

        $Result.IsValid = ($Result.ValidationErrors.Count -eq 0)
        return $Result
    }

    hidden static [PSCustomObject] ValidateAgainstSchema([object]$ConfigObject) {
        $Validation = [PSCustomObject]@{
            Errors = @()
            Warnings = @()
        }

        $Schema = [ScubaConfigValidator]::GetSchema()
        
        # Validate required properties
        if ($Schema -and $Schema.required) {
            # Handle both hashtables and PSCustomObjects with robust key detection
            if ($ConfigObject -is [hashtable]) {
                # For hashtables, use the Keys collection directly
                $ConfigProperties = @($ConfigObject.Keys)
            } elseif ($ConfigObject.PSObject -and $ConfigObject.PSObject.Properties) {
                # For PSCustomObjects, get property names
                $ConfigProperties = @($ConfigObject.PSObject.Properties.Name)
            } else {
                # Fallback: try to get properties using Get-Member
                try {
                    $ConfigProperties = @($ConfigObject | Get-Member -MemberType NoteProperty, Property | Select-Object -ExpandProperty Name)
                } catch {
                    $ConfigProperties = @()
                }
            }
            
            # DEBUG: Add debugging output via warnings
            $Validation.Warnings += "DEBUG - Schema required properties: $($Schema.required -join ', ')"
            $Validation.Warnings += "DEBUG - Config object type: $($ConfigObject.GetType().Name)"
            $Validation.Warnings += "DEBUG - Config properties found: $($ConfigProperties -join ', ')"
            
            foreach ($RequiredProp in $Schema.required) {
                if ($RequiredProp -notin $ConfigProperties) {
                    $Validation.Errors += "Required property '$RequiredProp' is missing"
                    $Validation.Warnings += "DEBUG - Missing property: $RequiredProp"
                } else {
                    $Validation.Warnings += "DEBUG - Found property: $RequiredProp"
                }
            }
        }

        # Validate ProductNames
        if ($ConfigObject.ProductNames -and $Schema.properties -and $Schema.properties.ProductNames) {
            $ValidProducts = $Schema.properties.ProductNames.items.enum
            foreach ($Product in $ConfigObject.ProductNames) {
                if ($Product -notin $ValidProducts) {
                    $Validation.Errors += "Invalid product name '$Product'. Valid products: $($ValidProducts -join ', ')"
                }
            }

            # Handle wildcard
            if ($ConfigObject.ProductNames -contains '*') {
                if ($ConfigObject.ProductNames.Count -gt 1) {
                    $Validation.Warnings += "Wildcard '*' found with other products. All products will be selected."
                }
            }
        }

        # Validate M365Environment
        if ($ConfigObject.M365Environment) {
            $ValidEnvironments = $Schema.properties.M365Environment.enum
            if ($ConfigObject.M365Environment -notin $ValidEnvironments) {
                $Validation.Errors += "Invalid M365Environment '$($ConfigObject.M365Environment)'. Valid environments: $($ValidEnvironments -join ', ')"
            }
        }

        # Validate Organization format
        if ($ConfigObject.Organization) {
            $OrgPattern = $Schema.properties.Organization.pattern
            if ($ConfigObject.Organization -notmatch $OrgPattern) {
                $Validation.Errors += "Organization '$($ConfigObject.Organization)' does not match required format (e.g., example.onmicrosoft.com)"
            }
        }

        # Validate AppId format
        if ($ConfigObject.AppId) {
            $GuidPattern = $Schema.properties.AppId.pattern
            if ($ConfigObject.AppId -notmatch $GuidPattern) {
                $Validation.Errors += "AppId '$($ConfigObject.AppId)' is not a valid GUID format"
            }
        }

        # Validate CertificateThumbprint format
        if ($ConfigObject.CertificateThumbprint) {
            $ThumbprintPattern = $Schema.properties.CertificateThumbprint.pattern
            if ($ConfigObject.CertificateThumbprint -notmatch $ThumbprintPattern) {
                $Validation.Errors += "CertificateThumbprint '$($ConfigObject.CertificateThumbprint)' must be 40 hexadecimal characters"
            }
        }

        return $Validation
    }

    hidden static [PSCustomObject] ValidateBusinessRules([object]$ConfigObject) {
        $Validation = [PSCustomObject]@{
            Errors = @()
            Warnings = @()
        }

        $Defaults = [ScubaConfigValidator]::GetDefaults()

        # Validate policy IDs in OmitPolicy
        if ($ConfigObject.OmitPolicy) {
            $OmitPolicyKeys = if ($ConfigObject.OmitPolicy -is [hashtable]) {
                $ConfigObject.OmitPolicy.Keys
            } else {
                $ConfigObject.OmitPolicy.PSObject.Properties.Name
            }
            foreach ($PolicyId in $OmitPolicyKeys) {
                $PolicyValidation = [ScubaConfigValidator]::ValidatePolicyId($PolicyId, $ConfigObject.ProductNames)
                if (-not $PolicyValidation.IsValid) {
                    $Validation.Errors += $PolicyValidation.Error
                }
            }
        }

        # Validate policy IDs in AnnotatePolicy
        if ($ConfigObject.AnnotatePolicy) {
            $AnnotatePolicyKeys = if ($ConfigObject.AnnotatePolicy -is [hashtable]) {
                $ConfigObject.AnnotatePolicy.Keys
            } else {
                $ConfigObject.AnnotatePolicy.PSObject.Properties.Name
            }
            foreach ($PolicyId in $AnnotatePolicyKeys) {
                $PolicyValidation = [ScubaConfigValidator]::ValidatePolicyId($PolicyId, $ConfigObject.ProductNames)
                if (-not $PolicyValidation.IsValid) {
                    $Validation.Errors += $PolicyValidation.Error
                }
            }
        }

        # Validate exclusions configuration
        if ($ConfigObject.ExclusionsConfig) {
            $ExclusionValidation = [ScubaConfigValidator]::ValidateExclusions($ConfigObject.ExclusionsConfig, $ConfigObject.ProductNames)
            $Validation.Errors += $ExclusionValidation.Errors
            $Validation.Warnings += $ExclusionValidation.Warnings
        }

        # Validate OPA path if specified
        if ($ConfigObject.OPAPath -and $ConfigObject.OPAPath -ne ".") {
            if (-not (Test-Path -Path $ConfigObject.OPAPath)) {
                $Validation.Warnings += "OPA path '$($ConfigObject.OPAPath)' does not exist"
            }
        }

        # Enhanced validation for critical organizational fields
        [ScubaConfigValidator]::ValidateOrganizationalFields($ConfigObject, $Validation)

        # Enhanced validation for ProductNames
        [ScubaConfigValidator]::ValidateProductNames($ConfigObject, $Validation)

        # Enhanced validation for M365Environment
        [ScubaConfigValidator]::ValidateM365Environment($ConfigObject, $Validation)

        return $Validation
    }

    hidden static [PSCustomObject] ValidatePolicyId([string]$PolicyId, [array]$ProductNames) {
        $Result = [PSCustomObject]@{
            IsValid = $false
            Error = ""
        }

        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $PolicyPattern = $Defaults.validation.policyIdPattern

        if ($PolicyId -notmatch $PolicyPattern) {
            $Result.Error = "Policy ID '$PolicyId' does not match expected format. Expected: $($Defaults.validation.policyIdExample)"
            return $Result
        }

        # Extract product from policy ID
        $PolicyParts = $PolicyId -split "\."
        if ($PolicyParts.Length -ge 3) {
            $ProductInPolicy = $PolicyParts[1].ToLower()

            # Handle wildcard in ProductNames
            $EffectiveProducts = $ProductNames
            if ($ProductNames -contains '*') {
                $EffectiveProducts = $Defaults.defaults.AllProductNames
            }

            if ($Defaults.validation.requireProductInPolicy -and $ProductInPolicy -notin $EffectiveProducts) {
                $Result.Error = "Policy '$PolicyId' references product '$ProductInPolicy' which is not in the selected ProductNames: $($EffectiveProducts -join ', ')"
                return $Result
            }
        }

        $Result.IsValid = $true
        return $Result
    }

    hidden static [PSCustomObject] ValidateExclusions([object]$ExclusionsConfig, [array]$ProductNames) {
        $Validation = [PSCustomObject]@{
            Errors = @()
            Warnings = @()
        }

        $Defaults = [ScubaConfigValidator]::GetDefaults()

        # Handle both hashtables and PSCustomObjects with robust key detection
        # Get product names from exclusions config, handling different object types
        if ($ExclusionsConfig -is [hashtable]) {
            $ProductNamesInConfig = @($ExclusionsConfig.Keys)
        } elseif ($ExclusionsConfig.PSObject -and $ExclusionsConfig.PSObject.Properties) {
            $ProductNamesInConfig = @($ExclusionsConfig.PSObject.Properties.Name)
        } else {
            try {
                $ProductNamesInConfig = @($ExclusionsConfig | Get-Member -MemberType NoteProperty, Property | Select-Object -ExpandProperty Name)
            } catch {
                $ProductNamesInConfig = @()
            }
        }

        foreach ($ProductName in $ProductNamesInConfig) {
            # Check if product supports exclusions
            $ProductInfo = $Defaults.products.$ProductName
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
                $EffectiveProducts = $Defaults.defaults.AllProductNames
            }

            if ($ProductName -notin $EffectiveProducts) {
                $Validation.Warnings += "Exclusions configured for '$ProductName' but product is not selected in ProductNames"
            }

            # Validate exclusion types for the product
            $ProductExclusions = $ExclusionsConfig.$ProductName
            # Validate each exclusion type
            $ExclusionTypeKeys = if ($ProductExclusions -is [hashtable]) {
                $ProductExclusions.Keys
            } else {
                $ProductExclusions.PSObject.Properties.Name
            }
            foreach ($ExclusionType in $ExclusionTypeKeys) {
                if ($ExclusionType -notin $ProductInfo.supportedExclusionTypes) {
                    $Validation.Errors += "Product '$ProductName' does not support exclusion type '$ExclusionType'. Supported types: $($ProductInfo.supportedExclusionTypes -join ', ')"
                }
            }
        }

        return $Validation
    }

    # Helper method to safely get keys/properties from objects, filtering out system properties
    static [array] GetObjectKeys([object]$Object) {
        if ($null -eq $Object) {
            return @()
        }

        if ($Object -is [hashtable]) {
            # For hashtables, filter out system properties that might get mixed in
            return $Object.Keys | Where-Object { 
                $_ -is [string] -and 
                $_ -notmatch '^(Count|IsReadOnly|IsFixedSize|IsSynchronized|Keys|Values|SyncRoot|Comparer)$' 
            }
        } elseif ($Object.PSObject -and $Object.PSObject.Properties) {
            # For PSCustomObjects, get property names
            return $Object.PSObject.Properties.Name
        } else {
            # Fallback: try to get properties using Get-Member
            try {
                return ($Object | Get-Member -MemberType NoteProperty, Property | Select-Object -ExpandProperty Name)
            } catch {
                return @()
            }
        }
    }

    # Enhanced validation for organizational fields (Organization, OrgName, OrgUnitName)
    hidden static [void] ValidateOrganizationalFields([object]$ConfigObject, [PSCustomObject]$Validation) {
        # Validate Organization (required and must be valid tenant domain)
        if (-not $ConfigObject.Organization) {
            $Validation.Errors += "Organization is required and must be specified"
        } elseif ($ConfigObject.Organization -notmatch '^[a-zA-Z0-9.-]+\.(onmicrosoft\.com|onmicrosoft\.us)$') {
            $Validation.Errors += "Organization '$($ConfigObject.Organization)' must be a valid Microsoft tenant domain (e.g., 'tenant.onmicrosoft.com')"
        }

        # Validate OrgName (required and must not be empty/whitespace)
        if (-not $ConfigObject.OrgName) {
            $Validation.Errors += "OrgName is required and must be specified"
        } elseif ([string]::IsNullOrWhiteSpace($ConfigObject.OrgName)) {
            $Validation.Errors += "OrgName cannot be empty or contain only whitespace"
        } elseif ($ConfigObject.OrgName.Length -gt 100) {
            $Validation.Errors += "OrgName cannot exceed 100 characters"
        }

        # Validate OrgUnitName (required and must not be empty/whitespace)
        if (-not $ConfigObject.OrgUnitName) {
            $Validation.Errors += "OrgUnitName is required and must be specified"
        } elseif ([string]::IsNullOrWhiteSpace($ConfigObject.OrgUnitName)) {
            $Validation.Errors += "OrgUnitName cannot be empty or contain only whitespace"
        } elseif ($ConfigObject.OrgUnitName.Length -gt 100) {
            $Validation.Errors += "OrgUnitName cannot exceed 100 characters"
        }
    }

    # Enhanced validation for ProductNames
    hidden static [void] ValidateProductNames([object]$ConfigObject, [PSCustomObject]$Validation) {
        if (-not $ConfigObject.ProductNames) {
            $Validation.Errors += "ProductNames is required and must contain at least one product"
            return
        }

        $ValidProducts = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams", "*")
        $ProductList = if ($ConfigObject.ProductNames -is [array]) {
            $ConfigObject.ProductNames
        } else {
            @($ConfigObject.ProductNames)
        }

        if ($ProductList.Count -eq 0) {
            $Validation.Errors += "ProductNames must contain at least one product"
            return
        }

        # Check for invalid product names
        foreach ($Product in $ProductList) {
            if ($Product -notin $ValidProducts) {
                $Validation.Errors += "Invalid product name '$Product'. Valid products: $($ValidProducts -join ', ')"
            }
        }

        # Check for duplicates
        $UniqueProducts = $ProductList | Sort-Object -Unique
        if ($UniqueProducts.Count -ne $ProductList.Count) {
            $Validation.Warnings += "ProductNames contains duplicate entries. Duplicates will be ignored."
        }

        # Special handling for wildcard
        if ($ProductList -contains "*" -and $ProductList.Count -gt 1) {
            $Validation.Warnings += "ProductNames contains wildcard '*' with other products. Wildcard takes precedence."
        }
    }

    # Enhanced validation for M365Environment
    hidden static [void] ValidateM365Environment([object]$ConfigObject, [PSCustomObject]$Validation) {
        $ValidEnvironments = @("commercial", "gcc", "gcchigh", "dod")
        
        if (-not $ConfigObject.M365Environment) {
            $Validation.Errors += "M365Environment is required and must be specified"
            return
        }

        if ($ConfigObject.M365Environment -notin $ValidEnvironments) {
            $Validation.Errors += "Invalid M365Environment '$($ConfigObject.M365Environment)'. Valid environments: $($ValidEnvironments -join ', ')"
        }

        # Environment-specific validation warnings
        switch ($ConfigObject.M365Environment) {
            "gcchigh" {
                $Validation.Warnings += "GCC High environment selected. Ensure you have appropriate access and permissions."
            }
            "dod" {
                $Validation.Warnings += "DoD environment selected. Ensure you have DoD IL5+ clearance and appropriate access."
            }
        }
    }
}

class ValidationResult {
    [bool]$IsValid
    [string[]]$ValidationErrors
    [string[]]$Warnings
    [object]$ParsedContent

    ValidationResult() {
        $this.IsValid = $false
        $this.ValidationErrors = @()
        $this.Warnings = @()
        $this.ParsedContent = $null
    }
}

# Export classes and functions
Export-ModuleMember -Function * -Variable *
