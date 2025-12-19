class ScubaConfigValidator {
    <#
    .SYNOPSIS
    ScubaConfigValidator provides validation of ScubaGear configuration files using JSON Schema

    .DESCRIPTION
    ScubaConfigValidator implements a validation system that combines multiple validation checks to ensure configuration correctness and provide user-friendly feedback.

    .EXAMPLE
    # Initialize validator and perform basic file validation
    [ScubaConfigValidator]::Initialize("C:\ScubaGear\Modules\ScubaConfig")
    $Result = [ScubaConfigValidator]::ValidateYamlFile("C:\Config\my-config.yaml")

    .EXAMPLE
    # Validate with debug mode enabled for troubleshooting
    [ScubaConfigValidator]::Initialize($ModulePath)
    $Result = [ScubaConfigValidator]::ValidateYamlFile("config.yaml", $true)  # Enable debug
    $Result.Warnings
    #>

    # Static cache for loaded resources - stores schema, defaults, and module path
    # This prevents repeated file I/O operations during validation
    hidden static [hashtable]$_Cache = @{}

    # Initialize the validator with the module path and load required resources
    # This must be called before any validation operations
    static [void] Initialize([string]$ModulePath) {
        # Store the module path for later use in loading schema and defaults files
        [ScubaConfigValidator]::_Cache['ModulePath'] = $ModulePath
        # Load and cache the JSON schema for validation
        [ScubaConfigValidator]::LoadSchema()
        # Load and cache the default configuration values
        [ScubaConfigValidator]::LoadDefaults()
    }

    # Loads and caches JSON schema file for configuration validation.
    # The schema defines the structure, types, and constraints for valid configurations
    hidden static [void] LoadSchema() {
        # Get the module path from cache (set during Initialize)
        $ModulePath = [ScubaConfigValidator]::_Cache['ModulePath']
        # Construct the full path to the schema file
        $SchemaPath = Join-Path -Path $ModulePath -ChildPath "ScubaConfigSchema.json"

        # Verify the schema file exists before attempting to load it
        if (-not (Test-Path -Path $SchemaPath)) {
            throw "Schema file not found: $SchemaPath"
        }

        try {
            # Read the entire schema file as a single string
            $SchemaContent = Get-Content -Path $SchemaPath -Raw
            # Parse the JSON content and store it in cache for reuse
            [ScubaConfigValidator]::_Cache['Schema'] = $SchemaContent | ConvertFrom-Json
        }
        catch {
            # Provide clear error message if schema loading fails
            throw "Failed to load configuration schema: $($_.Exception.Message)"
        }
    }

    # Loads and caches default configuration values from JSON file.
    hidden static [void] LoadDefaults() {
        $ModulePath = [ScubaConfigValidator]::_Cache['ModulePath']
        $DefaultsPath = Join-Path -Path $ModulePath -ChildPath "ScubaConfigDefaults.json"
        if (-not (Test-Path -Path $DefaultsPath)) {
            throw "Defaults file not found: $DefaultsPath"
        }
        try {
            $DefaultsContent = Get-Content -Path $DefaultsPath -Raw
            # Convert JSON defaults content
            [ScubaConfigValidator]::_Cache['Defaults'] = $DefaultsContent | ConvertFrom-Json
        }
        catch {
            throw "Failed to load configuration defaults: $($_.Exception.Message)"
        }
    }

    # Returns cached configuration defaults object. Throws if validator not initialized.
    static [object] GetDefaults() {
        if (-not [ScubaConfigValidator]::_Cache.ContainsKey('Defaults')) {
            throw "Validator not initialized. Call Initialize() first."
        }
        return [ScubaConfigValidator]::_Cache['Defaults']
    }

    # Returns cached JSON schema object. Throws if validator not initialized.
    static [object] GetSchema() {
        if (-not [ScubaConfigValidator]::_Cache.ContainsKey('Schema')) {
            throw "Validator not initialized. Call Initialize() first."
        }
        return [ScubaConfigValidator]::_Cache['Schema']
    }

    # Validates YAML configuration file with default settings from configuration.
    static [ValidationResult] ValidateYamlFile([string]$FilePath) {
        # Get the default debug mode from configuration
        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $DefaultDebugMode = if ($Defaults.outputSettings -and $Defaults.outputSettings.debugMode) {
            $Defaults.outputSettings.debugMode
        } else {
            $false
        }
        return [ScubaConfigValidator]::ValidateYamlFile($FilePath, $DefaultDebugMode, $false)
    }

    # Validates YAML configuration file with debug mode option (full validation enabled).
    static [ValidationResult] ValidateYamlFile([string]$FilePath, [bool]$DebugMode) {
        return [ScubaConfigValidator]::ValidateYamlFile($FilePath, $DebugMode, $false)
    }

    # Main YAML validation method with debug mode and detailed validation control.
    static [ValidationResult] ValidateYamlFile([string]$FilePath, [bool]$DebugMode, [bool]$SkipDetailedValidation) {
        # Write debug info immediately instead of collecting it
        Write-Debug "ValidateYamlFile called with: $FilePath (DebugMode: $DebugMode, SkipDetailedValidation: $SkipDetailedValidation)"

        $Result = [ValidationResult]::new()
        $Result.IsValid = $false
        $Result.ValidationErrors = @()
        $Result.Warnings = @()

        # First, verify the file actually exists at the specified path
        if (-not (Test-Path -PathType Leaf -Path $FilePath)) {
            if ($DebugMode) {
                Write-Debug "File validation failed: File not found at path '$FilePath'"
            }
            $Result.ValidationErrors += "Configuration file not found: $FilePath"
            return $Result
        }
        if ($DebugMode) {
            $FileInfo = Get-Item -Path $FilePath
            Write-Debug "File found: $FilePath (Size: $($FileInfo.Length) bytes, LastWrite: $($FileInfo.LastWriteTime))"
        }

        # Validate file extension against supported formats (typically .yaml, .yml, .json)
        $Extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        $ConfigDefaults = [ScubaConfigValidator]::GetDefaults()
        $SupportedExtensions = $ConfigDefaults.validation.supportedFileExtensions
        if ($DebugMode) {
            Write-Debug "File extension: '$Extension', Supported: $($SupportedExtensions -join ', ')"
        }
        if ($Extension -notin $SupportedExtensions) {
            if ($DebugMode) {
                Write-Debug "File validation failed: Unsupported extension '$Extension'"
            }
            $Result.ValidationErrors += "Unsupported file extension '$Extension'. Supported extensions: $($SupportedExtensions -join ', ')"
            return $Result
        }

        # Check file size to prevent processing of excessively large files
        $FileInfo = Get-Item -Path $FilePath
        $MaxSize = $ConfigDefaults.validation.maxFileSizeBytes
        if ($DebugMode) {
            Write-Debug "File size check: $($FileInfo.Length) bytes (Max allowed: $MaxSize bytes)"
        }
        if ($FileInfo.Length -gt $MaxSize) {
            if ($DebugMode) {
                Write-Debug "File validation failed: File too large ($($FileInfo.Length) bytes > $MaxSize bytes)"
            }
            $Result.ValidationErrors += "File size ($($FileInfo.Length) bytes) exceeds maximum allowed size ($MaxSize bytes)"
            return $Result
        }

        # Parse YAML content and convert to PowerShell objects
        try {
            if ($DebugMode) {
                Write-Debug "Starting YAML parsing for file: $FilePath"
            }
            # Read the entire file content as a single string
            $Content = Get-Content -Path $FilePath -Raw
            if ($DebugMode) {
                Write-Debug "File content loaded: $($Content.Length) characters"
                $FirstLine = ($Content -split "`r?`n")[0]
                Write-Debug "Content preview (first line): $FirstLine"
            }
            # Convert YAML text to PowerShell objects using ConvertFrom-Yaml
            $YamlObject = $Content | ConvertFrom-Yaml
            if ($DebugMode) {
                Write-Debug "YAML parsing successful: Object type = $($YamlObject.GetType().Name)"
                if ($YamlObject -is [hashtable]) {
                    Write-Debug "Parsed hashtable contains $($YamlObject.Count) top-level properties"
                } elseif ($YamlObject.PSObject) {
                    Write-Debug "Parsed PSCustomObject contains $($YamlObject.PSObject.Properties.Count) properties"
                }
            }
            # Store the parsed content in the result for later use
            $Result.ParsedContent = $YamlObject
        }
        catch {
            if ($DebugMode) {
                Write-Debug "YAML parsing failed: $($_.Exception.Message)"
                Write-Debug "Exception type: $($_.Exception.GetType().Name)"
                Write-Debug "Stack trace: $($_.Exception.StackTrace)"
            }
            # Special handling for duplicate key errors - these should bubble up immediately
            # as they indicate a fundamental YAML syntax error
            if ($_.Exception.Message -like "*Duplicate key*") {
                if ($DebugMode) {
                    Write-Debug "Duplicate key error detected - rethrowing"
                }
                throw
            }
            # For other parsing errors, add to validation errors and return
            $Result.ValidationErrors += "Failed to parse YAML content: $($_.Exception.Message)"
            return $Result
        }

        # If skipping detailed validation, only return parsed content without schema/rules validation
        if ($SkipDetailedValidation) {
            if ($DebugMode) {
                Write-Debug "VALIDATION SUMMARY: Configuration file parsed successfully"
            }
            $Result.IsValid = $true
            return $Result
        }

        # Validate against schema
        Write-Debug "About to call ValidateAgainstSchema with object type: $($YamlObject.GetType().Name)"
        $SchemaValidation = [ScubaConfigValidator]::ValidateAgainstSchema($YamlObject, $DebugMode)
        Write-Debug "ValidateAgainstSchema returned with $($SchemaValidation.Errors.Count) errors"
        $Result.ValidationErrors += $SchemaValidation.Errors
        $Result.Warnings += $SchemaValidation.Warnings

        # Additional Configuration logic validation
        $ConfigurationValidation = [ScubaConfigValidator]::ValidateConfigurationRules($YamlObject, $DebugMode)
        $Result.ValidationErrors += $ConfigurationValidation.Errors
        $Result.Warnings += $ConfigurationValidation.Warnings

        # Show validation summary in debug mode before returning results
        if ($DebugMode) {
            if ($Result.ValidationErrors.Count -eq 0) {
                Write-Debug "VALIDATION SUMMARY: Configuration is valid"
            } else {
                Write-Debug "VALIDATION SUMMARY: Found $($Result.ValidationErrors.Count) invalid configurations"
            }
        }

        $Result.IsValid = ($Result.ValidationErrors.Count -eq 0)
        return $Result
    }

    # Performs JSON Schema Draft-7 validation against configuration objects.
    hidden static [PSCustomObject] ValidateAgainstSchema([object]$ConfigObject, [bool]$DebugMode) {
        $Validation = [PSCustomObject]@{
            Errors = @()
            Warnings = @()
        }

        $Schema = [ScubaConfigValidator]::GetSchema()

        # Get validation settings from defaults
        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $ValidationSettings = $Defaults.validation

        # Validate required properties from defaults configuration
        $RequiredProperties = if ($Defaults.minRequired) { $Defaults.minRequired } else { @() }
        if ($RequiredProperties.Count -gt 0) {
            $ConfigProperties = [ScubaConfigValidator]::GetObjectKeys($ConfigObject)

            if ($DebugMode) {
                Write-Debug "Required properties check: $($RequiredProperties -join ', ')"
                Write-Debug "Found properties: $($ConfigProperties -join ', ')"
            }

            foreach ($RequiredProp in $RequiredProperties) {
                if ($RequiredProp -notin $ConfigProperties) {
                    $Validation.Errors += "Required property '$RequiredProp' is missing"
                }
            }
        }

        # Dynamic schema validation - validate all properties against their schema definitions
        if ($Schema.properties) {
            $ConfigProperties = [ScubaConfigValidator]::GetObjectKeys($ConfigObject)

            foreach ($PropertyName in $ConfigProperties) {
                $PropertyValue = $ConfigObject.$PropertyName
                $PropertySchema = $Schema.properties.$PropertyName

                # Skip validation if disabled in settings
                if ($PropertyName -eq "OmitPolicy" -and $ValidationSettings.validateOmitPolicy -eq $false) {
                    continue
                }
                if ($PropertyName -eq "AnnotatePolicy" -and $ValidationSettings.validateAnnotatePolicy -eq $false) {
                    continue
                }

                if ($PropertySchema -and $null -ne $PropertyValue) {
                    if ($DebugMode) {
                        Write-Debug "Validating property '$PropertyName' with value type: $([ScubaConfigValidator]::GetValueType($PropertyValue))"
                    }
                    # Universal schema validation - handles all property types dynamically
                    [ScubaConfigValidator]::ValidatePropertyAgainstSchema($PropertyValue, $PropertySchema, $Validation, "Property '$PropertyName'")
                }
            }
        }

        # Validate additionalProperties constraint (no unknown properties allowed)
        if ($Schema.additionalProperties -eq $false) {
            $ConfigProperties = [ScubaConfigValidator]::GetObjectKeys($ConfigObject)
            $AllowedProperties = if ($Schema.properties) { @($Schema.properties.PSObject.Properties.Name) } else { @() }
            $InvalidProperties = $ConfigProperties | Where-Object { $_ -notin $AllowedProperties }

            if ($InvalidProperties.Count -gt 0) {
                $Validation.Errors += "Configuration contains properties that are not allowed: $($InvalidProperties -join ', '). Valid properties are: $($AllowedProperties -join ', ')"
            }
        }

        # Validate product exclusions configurations (if enabled)
        if ($ValidationSettings.validateExclusions -ne $false) {
            [ScubaConfigValidator]::ValidateProductExclusions($ConfigObject, $Schema, $Validation)
        }

        return $Validation
    }

    # Performs Configuration logic validation beyond basic schema compliance.
    # This includes path validation and content quality checks that can't be defined in JSON Schema
    hidden static [PSCustomObject] ValidateConfigurationRules([object]$ConfigObject, [bool]$DebugMode) {
        # Initialize validation result container
        $Validation = [PSCustomObject]@{
            Errors = @()
            Warnings = @()
        }

        # Path existence validation (runtime checks that schema can't handle)
        if ($ConfigObject.OPAPath -and $ConfigObject.OPAPath -ne ".") {
            if (-not (Test-Path -Path $ConfigObject.OPAPath)) {
                $Validation.Warnings += "OPA path '$($ConfigObject.OPAPath)' does not exist"
            }
        }

        # Content quality validation (empty string checks)
        if ($ConfigObject.OrgName -and [string]::IsNullOrWhiteSpace($ConfigObject.OrgName)) {
            $Validation.Errors += "OrgName cannot be empty or contain only whitespace"
        }
        if ($ConfigObject.OrgUnitName -and [string]::IsNullOrWhiteSpace($ConfigObject.OrgUnitName)) {
            $Validation.Errors += "OrgUnitName cannot be empty or contain only whitespace"
        }

        # Environment-specific warnings (business logic)
        if ($ConfigObject.M365Environment) {
            switch ($ConfigObject.M365Environment) {
                "gcchigh" {
                    $Validation.Warnings += "GCC High environment selected. Ensure you have appropriate access and permissions."
                }
                "dod" {
                    $Validation.Warnings += "DoD environment selected. Ensure you have DoD IL5+ clearance and appropriate access."
                }
            }
        }

        # Product name warnings (business logic)
        if ($ConfigObject.ProductNames -and ($ConfigObject.ProductNames -contains "*") -and $ConfigObject.ProductNames.Count -gt 1) {
            $Validation.Warnings += "ProductNames contains wildcard '*' with other products. Wildcard takes precedence."
        }

        # Validate product exclusion property casing (business requirement)
        [ScubaConfigValidator]::ValidateProductExclusionCasing($ConfigObject, $Validation)

        return $Validation
    }

    # Validates individual policy ID format and product alignment.
    # Policy IDs must follow a specific pattern (e.g., MS.PRODUCT.1.1v1) and reference valid products
    hidden static [PSCustomObject] ValidatePolicyId([string]$PolicyId, [array]$ProductNames) {
        # Initialize result object with default failure state
        $Result = [PSCustomObject]@{
            IsValid = $false
            Error = ""
        }

        # Get the expected policy ID pattern from configuration
        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $PolicyPattern = $Defaults.validation.policyIdPattern

        # First, validate that the policy ID matches the expected format pattern
        if ($PolicyId -notmatch $PolicyPattern) {
            # Extract product name from malformed ID to provide better error guidance
            $PolicyParts = $PolicyId -split "\."
            $ProductInPolicy = if ($PolicyParts.Length -ge 2 -and $PolicyParts[1]) { $PolicyParts[1] } else { $null }

            # Generate a user-friendly format example based on the pattern
            $ExampleFormat = [ScubaConfigValidator]::ConvertPatternToExample($PolicyPattern, $ProductInPolicy)

            $Result.Error = "Policy ID: '$PolicyId' does not match expected format. Expected format: $ExampleFormat"
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
                $Result.Error = "Policy ID: '$PolicyId' references product '$ProductInPolicy' which is not in the selected ProductNames: $($EffectiveProducts -join ', ')"
                return $Result
            }
        }

        $Result.IsValid = $true
        return $Result
    }

    # Converts regex patterns to user-friendly format examples.
    static [string] ConvertPatternToExample([string]$Pattern, [string]$Product) {
        # For the pattern: ^[Mm][Ss]\.[a-zA-Z]+\.[0-9]+\.[0-9]+[Vv][0-9]+$
        # Generate: MS.PRODUCT.#.#v# or MS.AAD.#.#v# (if product specified)

        if ($Product) {
            return "MS.$($Product.ToUpper()).#.#v#"
        } else {
            return "MS.<PRODUCT>.#.#v#"
        }
    }

    # Validates product-specific exclusion configurations against schema definitions.
    static [void] ValidateProductExclusions([object]$ConfigObject, [object]$Schema, [PSCustomObject]$Validation) {
        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $ProductNames = $Defaults.defaults.AllProductNames

        foreach ($ProductName in $ProductNames) {
            # Check both lowercase and capitalized versions
            $ProductData = $null
            if ($ConfigObject.$ProductName) {
                $ProductData = $ConfigObject.$ProductName
            } else {
                $CapitalizedProductName = $ProductName.Substring(0,1).ToUpper() + $ProductName.Substring(1)
                if ($ConfigObject.$CapitalizedProductName) {
                    $ProductData = $ConfigObject.$CapitalizedProductName
                }
            }

            if ($ProductData) {
                # Validate the exclusions structure for this product using schema
                [ScubaConfigValidator]::ValidateProductExclusionStructure($ProductName, $ProductData, $Schema, $Validation)
            }
        }
    }

    # Validates individual product exclusion structure against its schema definition.
    static [void] ValidateProductExclusionStructure([string]$ProductName, [object]$ProductExclusions, [object]$Schema, [PSCustomObject]$Validation) {
        # Get the schema definition for this product's exclusions
        $ProductSchemaName = $ProductName.Substring(0,1).ToUpper() + $ProductName.Substring(1).ToLower() + "Exclusions"
        $ProductSchema = $Schema.definitions.$ProductSchemaName

        if (-not $ProductSchema) {
            return # No schema definition for this product
        }

        # Get policy IDs from the product exclusions
        $PolicyIds = if ($ProductExclusions -is [hashtable]) {
            @($ProductExclusions.Keys)
        } elseif ($ProductExclusions.PSObject -and $ProductExclusions.PSObject.Properties) {
            @($ProductExclusions.PSObject.Properties.Name)
        } else {
            @()
        }

        foreach ($PolicyId in $PolicyIds) {
            $PolicyExclusions = $ProductExclusions.$PolicyId

            # Validate the policy ID itself against the pattern
            if ($ProductSchema.patternProperties) {
                $PatternMatched = $false
                foreach ($Pattern in $ProductSchema.patternProperties.PSObject.Properties.Name) {
                    if ($PolicyId -cmatch $Pattern) {
                        $PatternMatched = $true
                        break
                    }
                }

                if (-not $PatternMatched) {
                    $CapitalizedProduct = $ProductName.Substring(0,1).ToUpper() + $ProductName.Substring(1).ToLower()
                    $Validation.Errors += "Policy ID: '$PolicyId' under '$CapitalizedProduct' does not match any allowed pattern"
                }
            }

            if ($PolicyExclusions) {
                # Validate against the schema recursively
                [ScubaConfigValidator]::ValidateObjectAgainstSchema($PolicyExclusions, $ProductSchema, $Validation, "Policy ID: '$PolicyId'")
            }
        }
    }

    # Performs recursive schema validation for complex objects.
    static [void] ValidateObjectAgainstSchema([object]$Object, [object]$Schema, [PSCustomObject]$Validation, [string]$Context) {
        if (-not $Schema -or -not $Schema.properties) {
            return
        }

        # Validate each property in the schema
        foreach ($PropertyName in $Schema.properties.PSObject.Properties.Name) {
            $PropertySchema = $Schema.properties.$PropertyName
            $PropertyValue = $Object.$PropertyName

            if ($PropertyValue) {
                [ScubaConfigValidator]::ValidatePropertyAgainstSchema($PropertyValue, $PropertySchema, $Validation, "$Context $PropertyName")
            }
        }
    }

    # Resolves JSON Schema $ref references to actual schema objects.
    static [object] ResolveSchemaReference([object]$Schema, [object]$PropertySchema) {
        if ($PropertySchema.'$ref') {
            $RefPath = $PropertySchema.'$ref'
            if ($RefPath.StartsWith("#/definitions/patterns/")) {
                $PatternName = $RefPath.Replace("#/definitions/patterns/", "")
                if ($Schema.definitions -and $Schema.definitions.patterns -and $Schema.definitions.patterns.$PatternName) {
                    return $Schema.definitions.patterns.$PatternName
                }
            }
        }
        return $PropertySchema
    }

    # Universal schema validation engine - handles any property type dynamically based on schema
    static [void] ValidatePropertyAgainstSchema([object]$Value, [object]$PropertySchema, [PSCustomObject]$Validation, [string]$Context) {
        # Resolve $ref references to actual schema definitions
        if ($PropertySchema.'$ref') {
            $Schema = [ScubaConfigValidator]::GetSchema()
            $PropertySchema = [ScubaConfigValidator]::ResolveSchemaReference($Schema, $PropertySchema)
        }

        # Validate type constraint
        if ($PropertySchema.type) {
            $ExpectedType = $PropertySchema.type
            $ActualType = [ScubaConfigValidator]::GetValueType($Value)
            if ($ActualType -ne $ExpectedType) {
                $Validation.Errors += "$Context expected type '$ExpectedType' but got '$ActualType'"
                return # Skip further validation if type is wrong
            }
        }

        # Validate enum constraint
        if ($PropertySchema.enum -and $null -ne $Value) {
            if ($Value -notin $PropertySchema.enum) {
                $Validation.Errors += "$Context value '$Value' is not valid. Valid values: $($PropertySchema.enum -join ', ')"
            }
        }

        # Validate pattern constraint (for strings)
        if ($PropertySchema.pattern -and $Value) {
            Write-Debug "Pattern validation for $Context`: Value='$Value', Pattern='$($PropertySchema.pattern)'"
            if ($Value -notmatch $PropertySchema.pattern) {
                $ErrorMessage = [ScubaConfigValidator]::GeneratePatternErrorMessage($Value, $PropertySchema.pattern, $Context)
                $Validation.Errors += $ErrorMessage
                Write-Debug "Pattern validation FAILED for $Context"
            } else {
                Write-Debug "Pattern validation PASSED for $Context"
            }
        }

        # Validate string length constraints
        if ($Value -is [string]) {
            if ($PropertySchema.minLength -and $Value.Length -lt $PropertySchema.minLength) {
                $Validation.Errors += "$Context must be at least $($PropertySchema.minLength) characters long, got $($Value.Length)"
            }
            if ($PropertySchema.maxLength -and $Value.Length -gt $PropertySchema.maxLength) {
                $Validation.Errors += "$Context cannot exceed $($PropertySchema.maxLength) characters, got $($Value.Length)"
            }
        }

        # Validate numeric constraints
        if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [float]) {
            if ($null -ne $PropertySchema.minimum -and $Value -lt $PropertySchema.minimum) {
                $Validation.Errors += "$Context value '$Value' is below minimum allowed value $($PropertySchema.minimum)"
            }
            if ($null -ne $PropertySchema.maximum -and $Value -gt $PropertySchema.maximum) {
                $Validation.Errors += "$Context value '$Value' is above maximum allowed value $($PropertySchema.maximum)"
            }
        }

        # Handle array validation
        if ($PropertySchema.type -eq "array") {
            [ScubaConfigValidator]::ValidateArrayProperty($Value, $PropertySchema, $Validation, $Context)
        }
        # Handle object validation
        elseif ($PropertySchema.type -eq "object") {
            [ScubaConfigValidator]::ValidateObjectProperty($Value, $PropertySchema, $Validation, $Context)
        }
    }

    # Dynamic array validation based on schema constraints
    static [void] ValidateArrayProperty([object]$Value, [object]$ArraySchema, [PSCustomObject]$Validation, [string]$Context) {
        $IsArray = $Value -is [array] -or ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string])

        if (-not $IsArray) {
            $ActualType = [ScubaConfigValidator]::GetValueType($Value)
            $Validation.Errors += "$Context must be an array but got $ActualType"
            return
        }

        $ArrayItems = @($Value)

        # Validate array size constraints
        if ($ArraySchema.minItems -and $ArrayItems.Count -lt $ArraySchema.minItems) {
            $Validation.Errors += "$Context must contain at least $($ArraySchema.minItems) items, found $($ArrayItems.Count)"
        }
        if ($ArraySchema.maxItems -and $ArrayItems.Count -gt $ArraySchema.maxItems) {
            $Validation.Errors += "$Context cannot contain more than $($ArraySchema.maxItems) items, found $($ArrayItems.Count)"
        }

        # Validate uniqueness constraint
        if ($ArraySchema.uniqueItems) {
            $Duplicates = $ArrayItems | Group-Object | Where-Object Count -gt 1
            if ($Duplicates) {
                $DuplicateValues = ($Duplicates | ForEach-Object { $_.Name }) -join ', '
                $Validation.Errors += "$Context contains duplicate values: $DuplicateValues"
            }
        }

        # Validate individual array items
        if ($ArraySchema.items) {
            foreach ($Item in $ArrayItems) {
                [ScubaConfigValidator]::ValidateItemAgainstSchema($Item, $ArraySchema.items, $Validation, $Context)
            }
        }
    }

    # Dynamic object validation with patternProperties support
    static [void] ValidateObjectProperty([object]$Value, [object]$ObjectSchema, [PSCustomObject]$Validation, [string]$Context) {
        # Validate required properties
        if ($ObjectSchema.required) {
            foreach ($RequiredProp in $ObjectSchema.required) {
                $HasProperty = if ($Value -is [hashtable]) {
                    $Value.ContainsKey($RequiredProp)
                } else {
                    $null -ne $Value.$RequiredProp
                }
                if (-not $HasProperty) {
                    $Validation.Errors += "$Context is missing required property '$RequiredProp'"
                }
            }
        }

        # Validate object properties
        if ($ObjectSchema.properties) {
            foreach ($PropName in $ObjectSchema.properties.PSObject.Properties.Name) {
                $PropValue = if ($Value -is [hashtable]) { $Value[$PropName] } else { $Value.$PropName }
                if ($null -ne $PropValue) {
                    $PropSchema = $ObjectSchema.properties.$PropName
                    [ScubaConfigValidator]::ValidatePropertyAgainstSchema($PropValue, $PropSchema, $Validation, "$Context.$PropName")
                }
            }
        }

        # Handle patternProperties (for dynamic property names like policy IDs)
        if ($ObjectSchema.patternProperties) {
            $ObjectKeys = [ScubaConfigValidator]::GetObjectKeys($Value)
            foreach ($Key in $ObjectKeys) {
                $KeyValue = if ($Value -is [hashtable]) { $Value[$Key] } else { $Value.$Key }
                $PatternMatched = $false

                foreach ($Pattern in $ObjectSchema.patternProperties.PSObject.Properties.Name) {
                    if ($Key -match $Pattern) {
                        $PatternSchema = $ObjectSchema.patternProperties.$Pattern
                        [ScubaConfigValidator]::ValidateItemAgainstSchema($KeyValue, $PatternSchema, $Validation, "$Context key '$Key'")
                        $PatternMatched = $true

                        # Additional policy ID validation for OmitPolicy/AnnotatePolicy
                        if ($Context -match "OmitPolicy|AnnotatePolicy") {
                            $Defaults = [ScubaConfigValidator]::GetDefaults()
                            $ProductNames = $Defaults.defaults.AllProductNames
                            $PolicyValidation = [ScubaConfigValidator]::ValidatePolicyId($Key, $ProductNames)
                            if (-not $PolicyValidation.IsValid) {
                                $Validation.Errors += $PolicyValidation.Error
                            }
                        }
                        break
                    }
                }

                if (-not $PatternMatched -and $ObjectSchema.additionalProperties -eq $false) {
                    $Validation.Errors += "$Context key '$Key' does not match any allowed pattern"
                }
            }
        }

        # Validate additionalProperties constraint
        if ($ObjectSchema.additionalProperties -eq $false -and $ObjectSchema.properties) {
            $AllowedProps = @($ObjectSchema.properties.PSObject.Properties.Name)
            $ObjectKeys = [ScubaConfigValidator]::GetObjectKeys($Value)
            foreach ($Key in $ObjectKeys) {
                if ($Key -notin $AllowedProps -and -not $ObjectSchema.patternProperties) {
                    $Validation.Errors += "$Context has unexpected property '$Key'"
                }
            }
        }
    }

    # Validates individual items against schema with support for oneOf and complex patterns.
    static [void] ValidateItemAgainstSchema([object]$Item, [object]$ItemSchema, [PSCustomObject]$Validation, [string]$Context) {
        # Handle oneOf validation (for OmitPolicy/AnnotatePolicy flexible formats)
        if ($ItemSchema.oneOf) {
            $OneOfValid = $false
            $OneOfErrors = @()

            foreach ($Option in $ItemSchema.oneOf) {
                $TempValidation = [PSCustomObject]@{ Errors = @() }

                # Handle different types in oneOf options
                if ($Option.type -eq "object") {
                    # For object validation, check type first, then properties
                    $ActualType = [ScubaConfigValidator]::GetValueType($Item)
                    if ($ActualType -eq "object") {
                        # Validate required properties
                        if ($Option.required) {
                            foreach ($RequiredProp in $Option.required) {
                                $HasProperty = if ($Item -is [hashtable]) {
                                    $Item.ContainsKey($RequiredProp)
                                } else {
                                    $null -ne $Item.$RequiredProp
                                }

                                if (-not $HasProperty) {
                                    $TempValidation.Errors += "$Context is missing required property '$RequiredProp'"
                                }
                            }
                        }

                        # Validate properties
                        if ($Option.properties) {
                            foreach ($PropName in $Option.properties.PSObject.Properties.Name) {
                                $PropertyValue = if ($Item -is [hashtable]) {
                                    $Item[$PropName]
                                } else {
                                    $Item.$PropName
                                }

                                if ($null -ne $PropertyValue) {
                                    $PropSchema = $Option.properties.$PropName
                                    [ScubaConfigValidator]::ValidateItemAgainstSchema($PropertyValue, $PropSchema, $TempValidation, "$Context.$PropName")
                                }
                            }
                        }

                        # Check for additionalProperties: false
                        if ($Option.additionalProperties -eq $false) {
                            $AllowedProps = if ($Option.properties) { $Option.properties.PSObject.Properties.Name } else { @() }
                            $ItemProps = [ScubaConfigValidator]::GetObjectKeys($Item)
                            foreach ($ItemProp in $ItemProps) {
                                if ($ItemProp -notin $AllowedProps) {
                                    $TempValidation.Errors += "$Context has unexpected property '$ItemProp'"
                                }
                            }
                        }
                    } else {
                        $TempValidation.Errors += "$Context expected type 'object' but got '$ActualType'"
                    }
                } else {
                    # For non-object types, use standard validation
                    [ScubaConfigValidator]::ValidateItemAgainstSchema($Item, $Option, $TempValidation, $Context)
                }

                if ($TempValidation.Errors.Count -eq 0) {
                    $OneOfValid = $true
                    break
                } else {
                    $OneOfErrors += $TempValidation.Errors
                }
            }

            if (-not $OneOfValid) {
                $Validation.Errors += "$Context does not match any of the allowed formats"
            }
            return
        }

        # Validate pattern if specified
        if ($ItemSchema.pattern -and $Item) {
            if ($Item -notmatch $ItemSchema.pattern) {
                # Generate user-friendly error based on the pattern and context
                $ErrorMessage = [ScubaConfigValidator]::GeneratePatternErrorMessage($Item, $ItemSchema.pattern, $Context)
                $Validation.Errors += $ErrorMessage
            }
        }

        # Validate enum if specified
        if ($ItemSchema.enum -and $null -ne $Item) {
            if ($Item -notin $ItemSchema.enum) {
                $Validation.Errors += "$Context value '$Item' is not valid. Valid values: $($ItemSchema.enum -join ', ')"
            }
        }

        # Validate type
        if ($ItemSchema.type) {
            $ExpectedType = $ItemSchema.type
            $ActualType = [ScubaConfigValidator]::GetValueType($Item)

            if ($ActualType -ne $ExpectedType) {
                $Validation.Errors += "$Context expected type '$ExpectedType' but got '$ActualType'"
            }
        }

        # Validate required properties for objects
        if ($ItemSchema.required -and $Item) {
            foreach ($RequiredProp in $ItemSchema.required) {
                if (-not $Item.$RequiredProp) {
                    $Validation.Errors += "$Context is missing required property '$RequiredProp'"
                }
            }
        }
    }

    # Retrieves human-readable descriptions for regex patterns from schema definitions.
    hidden static [string] GetPatternFriendlyName([string]$Pattern) {
        try {
            $Schema = [ScubaConfigValidator]::GetSchema()
            if ($Schema.definitions -and $Schema.definitions.patterns) {
                foreach ($PatternDef in $Schema.definitions.patterns.PSObject.Properties) {
                    if ($PatternDef.Value.pattern -eq $Pattern -and $PatternDef.Value.friendlyName) {
                        return $PatternDef.Value.friendlyName
                    }
                }
            }
        } catch {
            # Silently fall back to regex if schema lookup fails
            Write-Debug "Failed to lookup friendly name for pattern: $Pattern"
        }
        return $null
    }

    # Generates user-friendly error messages for pattern validation failures.
    static [string] GeneratePatternErrorMessage([string]$Value, [string]$Pattern, [string]$Context) {
        $FriendlyName = [ScubaConfigValidator]::GetPatternFriendlyName($Pattern)
        if ($FriendlyName) {
            return "$Context value '$Value' does not match: $FriendlyName"
        }
        return "$Context value '$Value' does not match required pattern: $Pattern"
    }

    # Determines PowerShell object types in JSON Schema compatible format.
    static [string] GetValueType([object]$Value) {
        if ($null -eq $Value) { return "null" }
        elseif ($Value -is [string]) { return "string" }
        elseif ($Value -is [bool]) { return "boolean" }
        elseif ($Value -is [int] -or $Value -is [long]) { return "integer" }
        elseif ($Value -is [double] -or $Value -is [float]) { return "number" }
        elseif ($Value -is [array]) { return "array" }
        elseif ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) { return "array" }
        elseif ($Value -is [hashtable] -or $Value.PSObject) { return "object" }
        else { return "unknown ($($Value.GetType().Name))" }
    }

    # Safely extracts property names from objects while filtering system properties.
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

    # Validates organizational field content quality and default configurations.
    hidden static [void] ValidateOrganizationalFields([object]$ConfigObject, [PSCustomObject]$Validation) {
        $Schema = [ScubaConfigValidator]::GetSchema()

        # Validate Organization format using schema pattern (only if present - required check handled by JSON Schema)
        if ($ConfigObject.Organization -and $Schema.properties -and $Schema.properties.Organization -and $Schema.properties.Organization.pattern) {
            $OrgPattern = $Schema.properties.Organization.pattern
            if ($ConfigObject.Organization -notmatch $OrgPattern) {
                $Validation.Errors += "Property 'Organization' value '$($ConfigObject.Organization)' is not a valid fully qualified domain name (FQDN)"
            }
        }

        # Validate OrgName content (only if present - required check handled by JSON Schema)
        if ($ConfigObject.OrgName) {
            if ([string]::IsNullOrWhiteSpace($ConfigObject.OrgName)) {
                $Validation.Errors += "OrgName cannot be empty or contain only whitespace"
            }
        }

        # Validate OrgUnitName content (only if present - required check handled by JSON Schema)
        if ($ConfigObject.OrgUnitName) {
            if ([string]::IsNullOrWhiteSpace($ConfigObject.OrgUnitName)) {
                $Validation.Errors += "OrgUnitName cannot be empty or contain only whitespace"
            }
        }
    }

    # Validates ProductNames array for duplicates and wildcard logic.
    hidden static [void] ValidateProductNames([object]$ConfigObject, [PSCustomObject]$Validation) {
        # Only add warnings if ProductNames is present
        if (-not $ConfigObject.ProductNames) {
            return
        }

        $ProductList = if ($ConfigObject.ProductNames -is [array]) {
            $ConfigObject.ProductNames
        } else {
            @($ConfigObject.ProductNames)
        }

        if ($ProductList.Count -eq 0) {
            return  # Empty array error already handled in ValidateAgainstSchema
        }

        # Check for duplicates (warning only, not an error)
        $UniqueProducts = $ProductList | Sort-Object -Unique
        if ($UniqueProducts.Count -ne $ProductList.Count) {
            $Validation.Warnings += "ProductNames contains duplicate entries. Duplicates will be ignored."
        }

        # Special handling for wildcard
        if ($ProductList -contains "*" -and $ProductList.Count -gt 1) {
            $Validation.Warnings += "ProductNames contains wildcard '*' with other products. Wildcard takes precedence."
        }
    }

    # Provides environment-specific validation warnings and guidance.
    hidden static [void] ValidateM365Environment([object]$ConfigObject, [PSCustomObject]$Validation) {
        # Only add warnings if M365Environment is present and valid
        if (-not $ConfigObject.M365Environment) {
            return
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

    # Validates product exclusion property names for correct capitalization.
    hidden static [void] ValidateProductExclusionCasing([object]$ConfigObject, [PSCustomObject]$Validation) {
        $CorrectCasing = @{
            "aad" = "Aad"
            "defender" = "Defender"
            "exo" = "Exo"
            "powerplatform" = "PowerPlatform"
            "sharepoint" = "SharePoint"
            "teams" = "Teams"
        }

        $ConfigKeys = [ScubaConfigValidator]::GetObjectKeys($ConfigObject)

        foreach ($Key in $ConfigKeys) {
            # Check if the key (in lowercase) exists in our correct casing map
            $LowerKey = $Key.ToLower()
            if ($CorrectCasing.ContainsKey($LowerKey)) {
                # Only report error if actual key doesn't match the correct casing
                if ($Key -cne $CorrectCasing[$LowerKey]) {
                    $Validation.Errors += "Property '$Key' should use correct capitalization: '$($CorrectCasing[$LowerKey])'. Product exclusion properties are case-sensitive."
                }
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