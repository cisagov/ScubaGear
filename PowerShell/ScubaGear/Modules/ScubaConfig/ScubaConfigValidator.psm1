class ScubaConfigValidator {
    <#
    .SYNOPSIS
    ScubaConfigValidator provides metadata-driven validation of ScubaGear configuration files using JSON Schema

    .DESCRIPTION
    ScubaConfigValidator implements a validation system that combines JSON Schema validation with metadata-driven
    exclusion type checking. The validator reads policyExclusionMappings from schema metadata to automatically
    validate that exclusion types match the policy IDs being configured.

    .EXAMPLE
    # Initialize validator and perform validation
    [ScubaConfigValidator]::Initialize("C:\ScubaGear\Modules\ScubaConfig")
    $Result = [ScubaConfigValidator]::ValidateYamlFile("C:\Config\my-config.yaml")

    .EXAMPLE
    # Get allowed exclusion types for a specific policy
    $AllowedTypes = [ScubaConfigValidator]::GetAllowedExclusionTypesForPolicy("MS.AAD.1.1v1")
    # Returns: @("CapExclusions")
    #>

    # Static cache for loaded resources
    hidden static [hashtable]$_Cache = @{}

    static [void] Initialize([string]$ModulePath) {
        # Store module path for loading schema and defaults
        [ScubaConfigValidator]::_Cache['ModulePath'] = $ModulePath
        [ScubaConfigValidator]::LoadSchema()
        [ScubaConfigValidator]::LoadDefaults()
    }

    # Loads and caches JSON schema file for configuration validation
    hidden static [void] LoadSchema() {
        $ModulePath = [ScubaConfigValidator]::_Cache['ModulePath']
        $SchemaPath = Join-Path -Path $ModulePath -ChildPath "ScubaConfigSchema.json"

        if (-not (Test-Path $SchemaPath)) {
            throw "Schema file not found: $SchemaPath"
        }

        try {
            $SchemaContent = Get-Content -Path $SchemaPath -Raw -ErrorAction Stop
            [ScubaConfigValidator]::_Cache['Schema'] = $SchemaContent | ConvertFrom-Json
        }
        catch {
            throw "Failed to load schema file: $($_.Exception.Message)"
        }
    }

    # Loads and caches default configuration values from JSON file
    hidden static [void] LoadDefaults() {
        $ModulePath = [ScubaConfigValidator]::_Cache['ModulePath']
        $DefaultsPath = Join-Path -Path $ModulePath -ChildPath "ScubaConfigDefaults.json"

        if (-not (Test-Path $DefaultsPath)) {
            throw "Defaults file not found: $DefaultsPath"
        }

        try {
            $DefaultsContent = Get-Content -Path $DefaultsPath -Raw -ErrorAction Stop
            [ScubaConfigValidator]::_Cache['Defaults'] = $DefaultsContent | ConvertFrom-Json
        }
        catch {
            throw "Failed to load defaults file: $($_.Exception.Message)"
        }
    }

    # Returns cached configuration defaults object
    static [object] GetDefaults() {
        if (-not [ScubaConfigValidator]::_Cache.ContainsKey('Defaults')) {
            throw "Validator not initialized. Call Initialize() first."
        }
        return [ScubaConfigValidator]::_Cache['Defaults']
    }

    # Returns cached JSON schema object
    static [object] GetSchema() {
        if (-not [ScubaConfigValidator]::_Cache.ContainsKey('Schema')) {
            throw "Validator not initialized. Call Initialize() first."
        }
        return [ScubaConfigValidator]::_Cache['Schema']
    }

    # Returns policy exclusion mappings from schema metadata
    static [hashtable] GetPolicyExclusionMappings() {
        $Schema = [ScubaConfigValidator]::GetSchema()
        $Mappings = @{}

        if ($Schema.schemaMetadata -and $Schema.schemaMetadata.policyExclusionMappings) {
            foreach ($Property in $Schema.schemaMetadata.policyExclusionMappings.PSObject.Properties) {
                # Skip comment properties
                if ($Property.Name -notlike "_comment*") {
                    $Mappings[$Property.Name] = $Property.Value
                }
            }
        }

        return $Mappings
    }

    # Returns allowed exclusion types for a specific policy ID
    static [array] GetAllowedExclusionTypesForPolicy([string]$PolicyId) {
        $Mappings = [ScubaConfigValidator]::GetPolicyExclusionMappings()

        # Normalize policy ID to uppercase for comparison
        $NormalizedId = $PolicyId.ToUpper()

        # Check for exact match first
        foreach ($Key in $Mappings.Keys) {
            if ($Key.ToUpper() -eq $NormalizedId) {
                return $Mappings[$Key]
            }
        }

        # No mapping found
        return @()
    }

    # Validates YAML configuration file with default settings
    static [ValidationResult] ValidateYamlFile([string]$FilePath) {
        return [ScubaConfigValidator]::ValidateYamlFile($FilePath, $false, $false)
    }

    # Validates YAML configuration file with debug mode option
    static [ValidationResult] ValidateYamlFile([string]$FilePath, [bool]$DebugMode) {
        return [ScubaConfigValidator]::ValidateYamlFile($FilePath, $DebugMode, $false)
    }

    # Main YAML validation method with full control over debug mode and validation scope
    static [ValidationResult] ValidateYamlFile([string]$FilePath, [bool]$DebugMode, [bool]$SkipScubaConfigRules) {
        $Result = [ValidationResult]::new()
        $Result.IsValid = $true

        # Phase 1: File format validation (extension, size, existence)
        $Defaults = [ScubaConfigValidator]::GetDefaults()

        if (-not (Test-Path -PathType Leaf $FilePath)) {
            $Result.IsValid = $false
            $Result.ValidationErrors += "Configuration file not found: $FilePath"
            return $Result
        }

        # Validate file extension
        $FileExtension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        if ($FileExtension -notin $Defaults.validation.supportedFileExtensions) {
            $Result.IsValid = $false
            $Result.ValidationErrors += "Unsupported file extension: $FileExtension. Supported extensions: $($Defaults.validation.supportedFileExtensions -join ', ')"
            return $Result
        }

        # Validate file size
        $FileInfo = Get-Item $FilePath
        if ($FileInfo.Length -gt $Defaults.validation.maxFileSizeBytes) {
            $MaxSizeMB = [math]::Round($Defaults.validation.maxFileSizeBytes / 1MB, 2)
            $FileSizeMB = [math]::Round($FileInfo.Length / 1MB, 2)
            $Result.IsValid = $false
            $Result.ValidationErrors += "Configuration file exceeds maximum size: $FileSizeMB MB (maximum: $MaxSizeMB MB)"
            return $Result
        }

        # Phase 2: Parse YAML/JSON content
        try {
            $FileContent = Get-Content -Path $FilePath -Raw -ErrorAction Stop

            # Determine format and parse
            if ($FileExtension -in @('.yaml', '.yml')) {
                # Parse YAML - uses powershell-yaml module in production, mocked function in tests
                # Tests define global:ConvertFrom-Yaml to avoid module dependency in CI/CD
                try {
                    $ParsedContent = $FileContent | ConvertFrom-Yaml -ErrorAction Stop
                }
                catch {
                    # If ConvertFrom-Yaml doesn't exist, provide helpful error
                    if ($_.Exception.Message -match "ConvertFrom-Yaml.*not recognized") {
                        $Result.IsValid = $false
                        $Result.ValidationErrors += "PowerShell-Yaml module not found. Install with: Install-Module powershell-yaml"
                        return $Result
                    }
                    throw
                }
            }
            else {
                # Parse JSON
                $ParsedContent = $FileContent | ConvertFrom-Json -ErrorAction Stop
            }

            $Result.ParsedContent = $ParsedContent
        }
        catch {
            $Result.IsValid = $false
            $Result.ValidationErrors += "Failed to parse configuration file: $($_.Exception.Message)"
            return $Result
        }

        # Phase 3: Schema validation (skip if deferred validation requested)
        if (-not $SkipScubaConfigRules) {
            $SchemaValidation = [ScubaConfigValidator]::ValidateAgainstSchema($ParsedContent, $DebugMode)
            $Result.ValidationErrors += $SchemaValidation.Errors
            $Result.Warnings += $SchemaValidation.Warnings

            if ($SchemaValidation.Errors.Count -gt 0) {
                $Result.IsValid = $false
            }

            # Phase 4: Scuba configuration rules validation
            $ScubaRulesValidation = [ScubaConfigValidator]::ValidateScubaConfigRules($ParsedContent, $DebugMode)
            $Result.ValidationErrors += $ScubaRulesValidation.Errors
            $Result.Warnings += $ScubaRulesValidation.Warnings

            if ($ScubaRulesValidation.Errors.Count -gt 0) {
                $Result.IsValid = $false
            }
        }

        return $Result
    }

    # Performs JSON Schema Draft-7 validation against configuration objects
    hidden static [PSCustomObject] ValidateAgainstSchema([object]$ConfigObject, [bool]$DebugMode) {
        $Validation = @{
            Errors = [System.Collections.ArrayList]::new()
            Warnings = [System.Collections.ArrayList]::new()
        }

        $Schema = [ScubaConfigValidator]::GetSchema()
        $Defaults = [ScubaConfigValidator]::GetDefaults()

        # Validate required fields
        if ($Defaults.minRequired) {
            foreach ($RequiredField in $Defaults.minRequired) {
                # Handle both hashtables (from ConvertFrom-Yaml) and PSCustomObjects (from ConvertFrom-Json)
                $HasProperty = if ($ConfigObject -is [hashtable]) {
                    $ConfigObject.ContainsKey($RequiredField)
                }
                else {
                    $ConfigObject.PSObject.Properties.Name -contains $RequiredField
                }

                if (-not $HasProperty) {
                    [void]$Validation.Errors.Add("Required property '$RequiredField' is missing.")
                }
            }
        }

        # Validate all properties against schema
        [ScubaConfigValidator]::ValidateAllPropertiesAgainstSchema($ConfigObject, $Schema, $Validation)

        # Validate product exclusions with metadata-driven checks
        [ScubaConfigValidator]::ValidateProductExclusions($ConfigObject, $Schema, $Validation)

        return [PSCustomObject]$Validation
    }

    # Performs Scuba configuration rule validation beyond basic schema compliance
    hidden static [PSCustomObject] ValidateScubaConfigRules([object]$ConfigObject, [bool]$DebugMode) {
        $Validation = @{
            Errors = [System.Collections.ArrayList]::new()
            Warnings = [System.Collections.ArrayList]::new()
        }

        $Schema = [ScubaConfigValidator]::GetSchema()

        # Check for whitespace-only strings that pass schema validation
        # Only check if property has content (length > 0) but is all whitespace
        # This avoids duplicating schema minLength validation
        foreach ($Property in $ConfigObject.PSObject.Properties) {
            if ($Property.Value -is [string] -and $Property.Value.Length -gt 0 -and [string]::IsNullOrWhiteSpace($Property.Value)) {
                [void]$Validation.Errors.Add("Property '$($Property.Name)' cannot be whitespace only."
)
            }
        }

        # Dynamically validate paths marked with testPath in schema definitions
        foreach ($PropertyName in $Schema.properties.PSObject.Properties.Name) {
            if ($ConfigObject.PSObject.Properties.Name -contains $PropertyName) {
                $PropertyValue = $ConfigObject.$PropertyName
                $SchemaProperty = $Schema.properties.$PropertyName

                # Resolve $ref if present
                $ResolvedProperty = [ScubaConfigValidator]::ResolveSchemaReference($Schema, $SchemaProperty)

                # Check if schema indicates this path should be tested
                if ($ResolvedProperty -and $ResolvedProperty.testPath -eq $true -and $PropertyValue -and $PropertyValue -ne ".") {
                    # Only test path existence if it matches the expected pattern (avoid duplicate errors)
                    if ($PropertyValue -match $ResolvedProperty.pattern) {
                        # Expand tilde to home directory for validation
                        $ExpandedPath = $PropertyValue -replace '~', $env:USERPROFILE

                        # Check if path exists - Get-Item resolves short paths (8.3 format) automatically
                        # This handles cases like C:\Users\RUNNER~1\... from $env:TEMP
                        try {
                            [void](Get-Item -LiteralPath $ExpandedPath -ErrorAction Stop)
                            $PathExists = $true
                        } catch {
                            $PathExists = $false
                        }

                        if (-not $PathExists) {
                            $ErrorType = if ($PropertyName -eq 'OPAPath') {
                                "Directory does not exist: $PropertyValue. ScubaGear cannot run without a valid OPA directory."
                            } else {
                                "Directory does not exist: $PropertyValue."
                            }
                            [void]$Validation.Errors.Add("Property '$PropertyName': $ErrorType"
)
                        }
                    }
                }
            }
        }

        # Validate ProductNames duplicates
        if ($ConfigObject.ProductNames) {
            $UniqueProducts = $ConfigObject.ProductNames | Select-Object -Unique
            if ($UniqueProducts.Count -ne $ConfigObject.ProductNames.Count) {
                [void]$Validation.Warnings.Add("ProductNames contains duplicate values. Duplicates will be removed."
)
            }
        }

        # Validate M365Environment warnings for government tenants
        if ($ConfigObject.M365Environment -in @('gcchigh', 'dod')) {
            $EnvName = if ($ConfigObject.M365Environment -eq 'gcchigh') { 'GCC High' } else { 'DoD' }
            [void]$Validation.Warnings.Add("$EnvName environment selected. Ensure you have appropriate security clearance and authorization."
)
        }

        # Check for product exclusions on products that don't support them
        [ScubaConfigValidator]::ValidateUnsupportedProductExclusions($ConfigObject, $Validation)

        return [PSCustomObject]$Validation
    }

    # Validates that products not supporting exclusions don't have exclusion configurations
    hidden static [void] ValidateUnsupportedProductExclusions([object]$ConfigObject, [hashtable]$Validation) {
        $Schema = [ScubaConfigValidator]::GetSchema()

        if (-not $Schema.schemaMetadata -or -not $Schema.schemaMetadata.productCapabilities) {
            return
        }

        $ProductCapabilities = $Schema.schemaMetadata.productCapabilities

        foreach ($ProductProperty in $ProductCapabilities.PSObject.Properties) {
            $ProductName = $ProductProperty.Name
            $Capabilities = $ProductProperty.Value

            # Check if product is configured in the config object
            if ($ConfigObject.PSObject.Properties.Name -contains $ProductName) {
                $ProductConfig = $ConfigObject.$ProductName

                # If product doesn't support exclusions but has configuration
                if (-not $Capabilities.supportsExclusions -and $ProductConfig -and $ProductConfig.PSObject.Properties.Count -gt 0) {
                    [void]$Validation.Warnings.Add("Product '$ProductName' does not support exclusions. Configuration under '$ProductName' will be ignored."
)
                }
            }
        }
    }

    # Dynamically validates all properties against their schema definitions
    static [void] ValidateAllPropertiesAgainstSchema([object]$ConfigObject, [object]$Schema, [hashtable]$Validation) {
        if (-not $Schema.properties) {
            return
        }

        # Load properties to ignore from schema metadata
        $SystemProperties = @()
        if ($Schema.schemaMetadata -and $Schema.schemaMetadata.ignoreProperties) {
            foreach ($Prop in $Schema.schemaMetadata.ignoreProperties) {
                # Skip comment entries
                if ($Prop -notlike "_comment*") {
                    $SystemProperties += $Prop
                }
            }
        }

        # Get properties based on object type
        $Properties = @()
        if ($ConfigObject -is [hashtable]) {
            # For hashtables, iterate over keys
            foreach ($Key in $ConfigObject.Keys) {
                if ($Key -notin $SystemProperties) {
                    $Properties += @{Name = $Key; Value = $ConfigObject[$Key]}
                }
            }
        }
        else {
            # For PSCustomObject, use PSObject.Properties
            foreach ($Property in $ConfigObject.PSObject.Properties) {
                if ($Property.Name -notin $SystemProperties) {
                    $Properties += @{Name = $Property.Name; Value = $Property.Value}
                }
            }
        }

        foreach ($Property in $Properties) {
            $PropertyName = $Property.Name
            $PropertyValue = $Property.Value

            # Skip comment properties
            if ($PropertyName -like "_comment*") {
                continue
            }

            # Check if property is defined in schema (case-sensitive match for JSON Schema compliance)
            $PropertyExists = $false
            foreach ($SchemaPropertyName in $Schema.properties.PSObject.Properties.Name) {
                if ($SchemaPropertyName -ceq $PropertyName) {
                    $PropertyExists = $true
                    $PropertySchema = $Schema.properties.$PropertyName

                    # Validate the property against its schema
                    [ScubaConfigValidator]::ValidatePropertyBySchema(
                        $PropertyValue,
                        $PropertySchema,
                        $Validation,
                        $PropertyName,
                        $PropertyName,
                        $null,
                        $Schema
                    )
                    break
                }
            }

            # Check if property exists in defaults (case-insensitive match for default properties)
            if (-not $PropertyExists) {
                $Defaults = [ScubaConfigValidator]::GetDefaults()
                if ($Defaults.defaults) {
                    foreach ($DefaultProp in $Defaults.defaults.PSObject.Properties.Name) {
                        if ($DefaultProp.ToLower() -eq $PropertyName.ToLower()) {
                            # Found a case-insensitive match - validate using the canonical property name
                            if ($Schema.properties.PSObject.Properties.Name -contains $DefaultProp) {
                                $PropertySchema = $Schema.properties.$DefaultProp
                                [ScubaConfigValidator]::ValidatePropertyBySchema(
                                    $PropertyValue,
                                    $PropertySchema,
                                    $Validation,
                                    $PropertyName,
                                    $PropertyName,
                                    $null,
                                    $Schema
                                )
                                $PropertyExists = $true
                            }
                            break
                        }
                    }
                }
            }

            if (-not $PropertyExists) {
                # Property not in schema - treat as warning (ScubaGear can still run with extra properties)
                [void]$Validation.Warnings.Add("Unknown property '$PropertyName' is not defined in the schema. This will be ignored."
)
            }
        }
    }

    # Comprehensive property validation that detects validation type from schema
    static [void] ValidatePropertyBySchema([object]$PropertyValue, [object]$PropertySchema, [hashtable]$Validation, [string]$Context, [string]$PropertyName, [object]$ValidationSettings, [object]$Schema) {
        Write-Debug "ValidatePropertyBySchema called for PropertyName: $PropertyName, Context: $Context"
        # Handle policy-type properties with complex oneOf validation first
        if ([ScubaConfigValidator]::IsPolicyTypeProperty($PropertyName, $PropertySchema)) {
            Write-Debug "  Recognized as policy property - calling ValidatePropertyAgainstSchema"
            # Use complex validation for policy properties (OmitPolicy, AnnotatePolicy)
            [ScubaConfigValidator]::ValidatePropertyAgainstSchema($PropertyValue, $PropertySchema, $Validation, $Context)
            return
        }
        Write-Debug "  Not a policy property - using standard validation"

        # Resolve $ref if present
        if ($PropertySchema.'$ref') {
            $PropertySchema = [ScubaConfigValidator]::ResolveSchemaReference($Schema, $PropertySchema)
        }

        # Determine validation based on type
        $SchemaType = $PropertySchema.type

        if (-not $SchemaType) {
            # No explicit type - check for enum or pattern
            [ScubaConfigValidator]::ValidateGenericProperty($PropertyValue, $PropertySchema, $Validation, $Context)
            return
        }

        switch ($SchemaType) {
            'array' {
                [ScubaConfigValidator]::ValidateArrayProperty($PropertyValue, $PropertySchema, $Validation, $Context)
            }
            'boolean' {
                [ScubaConfigValidator]::ValidateBooleanProperty($PropertyValue, $Validation, $Context)
            }
            'integer' {
                [ScubaConfigValidator]::ValidateIntegerProperty($PropertyValue, $PropertySchema, $Validation, $Context)
            }
            'number' {
                [ScubaConfigValidator]::ValidateNumberProperty($PropertyValue, $PropertySchema, $Validation, $Context)
            }
            'string' {
                [ScubaConfigValidator]::ValidateStringProperty($PropertyValue, $PropertySchema, $Validation, $Context)
            }
            'object' {
                [ScubaConfigValidator]::ValidateObjectProperty($PropertyValue, $PropertySchema, $Validation, $Context)
            }
        }
    }

    # Validates array properties
    static [void] ValidateArrayProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        if ($Value -isnot [Array] -and $Value -isnot [System.Collections.IList]) {
            [void]$Validation.Errors.Add("Property '$Context': Expected array, got $($Value.GetType().Name)."
)
            return
        }

        # Validate minItems
        if ($Schema.minItems -and $Value.Count -lt $Schema.minItems) {
            [void]$Validation.Errors.Add("Property '$Context': Array must have at least $($Schema.minItems) items, found $($Value.Count)."
)
        }

        # Validate uniqueItems
        if ($Schema.uniqueItems -and ($Value | Select-Object -Unique).Count -ne $Value.Count) {
            [void]$Validation.Errors.Add("Property '$Context': Array items must be unique."
)
        }

        # Validate each item
        if ($Schema.items) {
            for ($i = 0; $i -lt $Value.Count; $i++) {
                $ItemContext = "$Context[$i]"
                [ScubaConfigValidator]::ValidateItemBySchema($Value[$i], $Schema.items, $Validation, $ItemContext)
            }
        }
    }

    # Validates boolean properties
    static [void] ValidateBooleanProperty([object]$Value, [hashtable]$Validation, [string]$Context) {
        if ($Value -isnot [bool]) {
            [void]$Validation.Errors.Add("Property '$Context': Expected boolean, got $($Value.GetType().Name) with value '$Value'."
)
        }
    }

    # Validates integer properties with optional enum
    static [void] ValidateIntegerProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        # Check if value is numeric
        $NumericValue = $null
        if (-not [int]::TryParse($Value, [ref]$NumericValue)) {
            [void]$Validation.Errors.Add("Property '$Context': Expected integer, got '$Value'."
)
            return
        }

        # Validate enum constraint
        if ($Schema.enum -and $Schema.enum -notcontains $NumericValue) {
            [void]$Validation.Errors.Add("Property '$Context': Value '$NumericValue' is not in allowed values: $($Schema.enum -join ', ')."
)
        }
    }

    # Validates number properties
    static [void] ValidateNumberProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        $NumericValue = $null
        if (-not [double]::TryParse($Value, [ref]$NumericValue)) {
            [void]$Validation.Errors.Add("Property '$Context': Expected number, got '$Value'."
)
        }
    }

    # Validates string properties with enum, pattern, length constraints
    static [void] ValidateStringProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        if ($Value -isnot [string]) {
            [void]$Validation.Errors.Add("Property '$Context': Expected string, got $($Value.GetType().Name)."
)
            return
        }

        # Validate minLength
        if ($Schema.minLength -and $Value.Length -lt $Schema.minLength) {
            [void]$Validation.Errors.Add("Property '$Context': String must be at least $($Schema.minLength) characters, found $($Value.Length)."
)
        }

        # Validate maxLength
        if ($Schema.maxLength -and $Value.Length -gt $Schema.maxLength) {
            [void]$Validation.Errors.Add("Property '$Context': String must be at most $($Schema.maxLength) characters, found $($Value.Length)."
)
        }

        # Validate enum
        if ($Schema.enum -and $Schema.enum -notcontains $Value) {
            [void]$Validation.Errors.Add("Property '$Context': Value '$Value' is not in allowed values: $($Schema.enum -join ', ')."
)
        }

        # Validate pattern
        if ($Schema.pattern -and $Value -notmatch $Schema.pattern) {
            $FriendlyName = [ScubaConfigValidator]::GetPatternFriendlyName($Schema.pattern)
            if ($FriendlyName) {
                [void]$Validation.Errors.Add("Property '$Context': Value '$Value' does not match required format: $FriendlyName."
)
            }
            else {
                [void]$Validation.Errors.Add("Property '$Context': Value '$Value' does not match required pattern."
)
            }
        }
    }

    # Validates object properties with additionalProperties support
    static [void] ValidateObjectProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        if ($Value -isnot [PSCustomObject] -and $Value -isnot [hashtable]) {
            [void]$Validation.Errors.Add("Property '$Context': Expected object, got $($Value.GetType().Name)."
)
            return
        }

        # Get the actual properties from the value
        $ValueProperties = @()
        if ($Value -is [hashtable]) {
            $ValueProperties = @($Value.Keys)
        } elseif ($Value -is [PSCustomObject]) {
            $ValueProperties = @($Value.PSObject.Properties.Name)
        }

        # If schema has properties defined, validate each one
        if ($Schema.properties) {
            $AllowedProperties = @($Schema.properties.PSObject.Properties.Name)

            foreach ($PropName in $ValueProperties) {
                # Case-sensitive match for JSON Schema compliance
                $PropertyExists = $false
                foreach ($AllowedProp in $AllowedProperties) {
                    if ($AllowedProp -ceq $PropName) {
                        $PropertyExists = $true
                        # Validate the property value against its schema
                        $PropSchema = $Schema.properties.$PropName
                        $PropValue = if ($Value -is [hashtable]) { $Value[$PropName] } else { $Value.$PropName }
                        [ScubaConfigValidator]::ValidatePropertyBySchema($PropValue, $PropSchema, $Validation, "$Context.$PropName", $PropName, $null, [ScubaConfigValidator]::GetSchema())
                        break
                    }
                }

                # If property not found and additionalProperties is false, report error
                if (-not $PropertyExists -and $Schema.additionalProperties -eq $false) {
                    [void]$Validation.Errors.Add("Property '$Context': Invalid property '$PropName'. Valid properties: $($AllowedProperties -join ', ')."
)
                }
            }
        }
    }

    # Validates properties without explicit type (handles enum, pattern, etc.)
    static [void] ValidateGenericProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        # Check for enum constraint
        if ($Schema.enum) {
            if ($Schema.enum -notcontains $Value) {
                [void]$Validation.Errors.Add("Property '$Context': Value '$Value' is not in allowed values: $($Schema.enum -join ', ')."
)
            }
        }

        # Check for pattern constraint
        if ($Schema.pattern -and $Value -is [string]) {
            if ($Value -notmatch $Schema.pattern) {
                $FriendlyName = [ScubaConfigValidator]::GetPatternFriendlyName($Schema.pattern)
                if ($FriendlyName) {
                    [void]$Validation.Errors.Add("Property '$Context': Value '$Value' does not match required format: $FriendlyName."
)
                }
                else {
                    [void]$Validation.Errors.Add("Property '$Context': Value '$Value' does not match required pattern."
)
                }
            }
        }
    }

    # Validates individual items within arrays
    static [void] ValidateItemBySchema([object]$Item, [object]$ItemSchema, [hashtable]$Validation, [string]$Context) {
        # Resolve $ref if present
        if ($ItemSchema.'$ref') {
            $Schema = [ScubaConfigValidator]::GetSchema()
            $ItemSchema = [ScubaConfigValidator]::ResolveSchemaReference($Schema, $ItemSchema)
        }

        # Determine validation based on type
        if ($ItemSchema.type -eq 'string') {
            [ScubaConfigValidator]::ValidateStringProperty($Item, $ItemSchema, $Validation, $Context)
        }
        elseif ($ItemSchema.type -eq 'object') {
            [ScubaConfigValidator]::ValidateObjectProperty($Item, $ItemSchema, $Validation, $Context)
        }
        elseif ($ItemSchema.enum) {
            if ($ItemSchema.enum -notcontains $Item) {
                [void]$Validation.Errors.Add("Property '$Context': Value '$Item' is not in allowed values: $($ItemSchema.enum -join ', ')."
)
            }
        }
        elseif ($ItemSchema.pattern) {
            if ($Item -notmatch $ItemSchema.pattern) {
                $FriendlyName = [ScubaConfigValidator]::GetPatternFriendlyName($ItemSchema.pattern)
                if ($FriendlyName) {
                    [void]$Validation.Errors.Add("Property '$Context': Value '$Item' does not match required format: $FriendlyName."
)
                }
                else {
                    [void]$Validation.Errors.Add("Property '$Context': Value '$Item' does not match required pattern."
)
                }
            }
        }
    }

    # Validates product-specific exclusion configurations with metadata-driven checks
    static [void] ValidateProductExclusions([object]$ConfigObject, [object]$Schema, [hashtable]$Validation) {
        if (-not $Schema.schemaMetadata -or -not $Schema.schemaMetadata.productCapabilities) {
            return
        }

        # System properties to skip (hashtable/object metadata)
        $SystemProperties = @('IsReadOnly', 'IsFixedSize', 'IsSynchronized', 'Keys', 'Values', 'SyncRoot', 'Count')

        $ProductCapabilities = $Schema.schemaMetadata.productCapabilities

        # Iterate through each product configured
        foreach ($ProductProperty in $ProductCapabilities.PSObject.Properties) {
            $ProductName = $ProductProperty.Name

            # Check if product is configured
            if ($ConfigObject.PSObject.Properties.Name -contains $ProductName) {
                $ProductConfig = $ConfigObject.$ProductName

                if (-not $ProductConfig) {
                    continue
                }

                # Get policy IDs, filtering out system properties
                $PolicyIds = @()
                if ($ProductConfig -is [hashtable]) {
                    foreach ($Key in $ProductConfig.Keys) {
                        if ($Key -notin $SystemProperties) {
                            $PolicyIds += $Key
                        }
                    }
                }
                else {
                    foreach ($Property in $ProductConfig.PSObject.Properties) {
                        if ($Property.Name -notin $SystemProperties) {
                            $PolicyIds += $Property.Name
                        }
                    }
                }

                # Validate each policy ID under the product
                foreach ($PolicyId in $PolicyIds) {
                    $PolicyConfig = $ProductConfig.$PolicyId

                    # Get allowed exclusion types for this policy
                    $AllowedTypes = [ScubaConfigValidator]::GetAllowedExclusionTypesForPolicy($PolicyId)

                    # Get exclusion types, filtering out system properties
                    $ExclusionTypes = @()
                    if ($PolicyConfig -is [hashtable]) {
                        foreach ($Key in $PolicyConfig.Keys) {
                            if ($Key -notin $SystemProperties) {
                                $ExclusionTypes += $Key
                            }
                        }
                    }
                    else {
                        foreach ($Property in $PolicyConfig.PSObject.Properties) {
                            if ($Property.Name -notin $SystemProperties) {
                                $ExclusionTypes += $Property.Name
                            }
                        }
                    }

                    # Check if policy supports any exclusion types first
                    if ($AllowedTypes.Count -eq 0 -and $ExclusionTypes.Count -gt 0) {
                        # Generate error once per policy, not per exclusion type
                        [void]$Validation.Errors.Add("$ProductName exclusion error: Policy ID '$PolicyId' does not have any mapped exclusion types in schema metadata.")
                    }
                    else {
                        # Validate each exclusion type configured
                        foreach ($ExclusionType in $ExclusionTypes) {
                            # Check if this exclusion type is allowed for this policy
                            if ($ExclusionType -notin $AllowedTypes) {
                                [void]$Validation.Errors.Add("$ProductName exclusion error: '$ExclusionType' is not valid for this policy. Policy ID '$PolicyId' supports exclusion types: $($AllowedTypes -join ', ').")
                            }
                        }
                    }
                }
            }
        }
    }

    # Resolves JSON Schema $ref references to actual schema objects
    static [object] ResolveSchemaReference([object]$Schema, [object]$PropertySchema) {
        $RefPath = $PropertySchema.'$ref'

        if (-not $RefPath) {
            return $PropertySchema
        }

        # Parse the reference path (e.g., "#/definitions/patterns/guid")
        if ($RefPath.StartsWith('#/')) {
            $PathParts = $RefPath.Substring(2) -split '/'
            $Current = $Schema

            foreach ($Part in $PathParts) {
                if ($Current.PSObject.Properties.Name -contains $Part) {
                    $Current = $Current.$Part
                }
                else {
                    return $PropertySchema  # Reference not found, return original
                }
            }

            return $Current
        }

        return $PropertySchema
    }

    # Identifies policy-type properties dynamically from schema structure
    static [bool] IsPolicyTypeProperty([string]$PropertyName, [object]$PropertySchema) {
        Write-Debug "IsPolicyTypeProperty called for: $PropertyName"
        # Policy properties are: type "object" + patternProperties + oneOf validation
        if ($PropertySchema.type -ne "object" -or -not $PropertySchema.patternProperties) {
            Write-Debug "  Not a policy property: type=$($PropertySchema.type), has patternProperties=$($null -ne $PropertySchema.patternProperties)"
            return $false
        }

        # Load policy ID pattern from defaults
        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $PolicyIdPattern = $Defaults.validation.policyIdPattern
        Write-Debug "  Checking for policyIdPattern: $PolicyIdPattern"
        foreach ($Pattern in $PropertySchema.patternProperties.PSObject.Properties.Name) {
            Write-Debug "    Checking pattern: $Pattern"
            if ($Pattern -eq $PolicyIdPattern) {
                $PatternSchema = $PropertySchema.patternProperties.$Pattern
                if ($PatternSchema.oneOf) {
                    Write-Debug "  IS a policy property - has oneOf!"
                    return $true
                }
            }
        }
        Write-Debug "  NOT a policy property - no matching pattern with oneOf"
        return $false
    }

    # Validates policy ID format and product consistency
    hidden static [PSCustomObject] ValidatePolicyId([string]$PolicyId, [array]$ProductNames) {
        $Result = [PSCustomObject]@{
            IsValid = $false
            Error = ""
        }

        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $PolicyPattern = $Defaults.validation.policyIdPattern

        if ($PolicyId -notmatch $PolicyPattern) {
            $PolicyParts = $PolicyId -split "\."
            $ProductInPolicy = if ($PolicyParts.Length -ge 2 -and $PolicyParts[1]) { $PolicyParts[1] } else { $null }
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
                $Result.Error = "Policy ID: '$PolicyId' references product '$ProductInPolicy' which is not in ProductNames: $($EffectiveProducts -join ', ')"
                return $Result
            }
        }

        $Result.IsValid = $true
        return $Result
    }

    # Converts policy ID pattern to example format
    static [string] ConvertPatternToExample([string]$Pattern, [string]$Product) {
        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $ConfiguredPattern = $Defaults.validation.policyIdPattern

        if ($Pattern -eq $ConfiguredPattern) {
            if ($Product) {
                return $Defaults.validation.policyIdPatternExampleWithProduct -replace '\{PRODUCT\}', $Product.ToUpper()
            }
            return $Defaults.validation.policyIdPatternExample
        }
        return "Pattern: $Pattern"
    }

    # Builds regex pattern for policy properties (OmitPolicy|AnnotatePolicy)
    static [string] BuildPolicyPropertiesRegex() {
        $Schema = [ScubaConfigValidator]::GetSchema()
        $PolicyProperties = @()

        if ($Schema.properties) {
            foreach ($PropertyName in $Schema.properties.PSObject.Properties.Name) {
                $PropertySchema = $Schema.properties.$PropertyName
                if ([ScubaConfigValidator]::IsPolicyTypeProperty($PropertyName, $PropertySchema)) {
                    $PolicyProperties += $PropertyName
                }
            }
        }

        if ($PolicyProperties.Count -gt 0) {
            return ($PolicyProperties -join '|')
        }
        return ""
    }

    # Validates properties against schema with support for patternProperties and oneOf
    static [void] ValidatePropertyAgainstSchema([object]$Value, [object]$PropertySchema, [hashtable]$Validation, [string]$Context) {
        Write-Debug "ValidatePropertyAgainstSchema called - Context: $Context"

        # Resolve $ref references
        if ($PropertySchema.'$ref') {
            $Schema = [ScubaConfigValidator]::GetSchema()
            $PropertySchema = [ScubaConfigValidator]::ResolveSchemaReference($Schema, $PropertySchema)
        }

        # Handle object with patternProperties (OmitPolicy, AnnotatePolicy)
        if ($PropertySchema.type -eq "object" -and $PropertySchema.patternProperties) {
            Write-Debug "Has patternProperties - entering loop"
            $ObjectKeys = [ScubaConfigValidator]::GetObjectKeys($Value)
            Write-Debug "ObjectKeys count: $($ObjectKeys.Count), Keys: $($ObjectKeys -join ', ')"

            foreach ($Key in $ObjectKeys) {
                Write-Debug "Processing Key: $Key"
                $KeyValue = $Value.$Key
                Write-Debug "KeyValue type: $($KeyValue.GetType().Name), Value: $($KeyValue | ConvertTo-Json -Compress -Depth 2)"
                Write-Debug "Before processing - Validation.Errors type: $($Validation.Errors.GetType().FullName), IsFixedSize: $($Validation.Errors.IsFixedSize)"
                $PatternMatched = $false

                # Check each pattern in patternProperties
                foreach ($Pattern in $PropertySchema.patternProperties.PSObject.Properties.Name) {
                    Write-Debug "Checking pattern: $Pattern"
                    if ($Key -match $Pattern) {
                        Write-Debug "Pattern MATCHED! Calling ValidateItemAgainstSchema"
                        $PatternSchema = $PropertySchema.patternProperties.$Pattern
                        [ScubaConfigValidator]::ValidateItemAgainstSchema($KeyValue, $PatternSchema, $Validation, "${Context}: '$Key'")
                        $PatternMatched = $true

                        # Validate policy ID format
                        $PolicyPattern = [ScubaConfigValidator]::BuildPolicyPropertiesRegex()
                        if ($Context -match $PolicyPattern) {
                            $Defaults = [ScubaConfigValidator]::GetDefaults()
                            $ProductNames = $Defaults.defaults.AllProductNames
                            $PolicyValidation = [ScubaConfigValidator]::ValidatePolicyId($Key, $ProductNames)
                            if (-not $PolicyValidation.IsValid) {
                                try {
                                    Write-Debug "Adding error to Validation.Errors. Type: $($Validation.Errors.GetType().FullName)"
                                    [void]$Validation.Errors.Add($PolicyValidation.Error)
                                } catch {
                                    Write-Debug "ERROR adding to Validation.Errors: $_"
                                    Write-Debug "Validation type: $($Validation.GetType().FullName)"
                                    Write-Debug "Validation.Errors type: $($Validation.Errors.GetType().FullName)"
                                    throw
                                }
                            }
                        }
                        break
                    }
                }

                if (-not $PatternMatched) {
                    try {
                        Write-Debug "Adding pattern error to Validation.Errors"
                        [void]$Validation.Errors.Add("${Context}: '$Key' does not match any allowed pattern")
                    } catch {
                        Write-Debug "ERROR adding pattern error: $_"
                        throw
                    }
                }
            }
        }
    }

    # Validates items against schema with oneOf support
    static [void] ValidateItemAgainstSchema([object]$Item, [object]$ItemSchema, [hashtable]$Validation, [string]$Context) {
        # Handle oneOf validation (for OmitPolicy/AnnotatePolicy flexible formats)
        if ($ItemSchema.oneOf) {
            Write-Debug "ValidateItemAgainstSchema called for Context: $Context"
            Write-Debug "Item type: $($Item.GetType().Name), Item value: $($Item | ConvertTo-Json -Compress -Depth 2)"

            $OneOfValid = $false
            $OneOfErrors = [System.Collections.ArrayList]::new()
            $ActualItemType = [ScubaConfigValidator]::GetValueType($Item)
            $TypeMatchedErrors = $null

            foreach ($Option in $ItemSchema.oneOf) {
                Write-Debug "Checking oneOf option type: $($Option.type)"
                $TempValidation = @{ Errors = [System.Collections.ArrayList]::new() }

                # Handle object validation
                if ($Option.type -eq "object") {
                    $ActualType = [ScubaConfigValidator]::GetValueType($Item)
                    if ($ActualType -eq "object") {
                        # Validate required properties
                        if ($Option.required) {
                            # Get actual keys from hashtable or PSObject
                            $ItemKeys = if ($Item -is [hashtable]) { $Item.Keys } else { $Item.PSObject.Properties.Name }
                            foreach ($RequiredProp in $Option.required) {
                                if (-not ($ItemKeys -contains $RequiredProp)) {
                                    [void]$TempValidation.Errors.Add("${Context}: Missing required property '$RequiredProp'")
                                }
                            }
                        }

                        # Validate properties
                        if ($Option.properties) {
                            $AllowedProps = $Option.properties.PSObject.Properties.Name
                            # Get actual keys from hashtable or PSObject
                            $ItemKeys = if ($Item -is [hashtable]) { $Item.Keys } else { $Item.PSObject.Properties.Name }

                            # Check for invalid properties (additionalProperties: false)
                            if ($Option.additionalProperties -eq $false) {
                                foreach ($ItemProp in $ItemKeys) {
                                    if ($ItemProp -notin $AllowedProps) {
                                        [void]$TempValidation.Errors.Add("${Context}: Invalid property '$ItemProp'. Valid properties: $($AllowedProps -join ', ')")
                                    }
                                }
                            }

                            # Validate each property's value against its schema
                            foreach ($ItemProp in $ItemKeys) {
                                if ($ItemProp -in $AllowedProps) {
                                    $PropValue = $Item.$ItemProp
                                    $PropSchema = $Option.properties.$ItemProp

                                    # Validate type
                                    if ($PropSchema.type) {
                                        $ExpectedType = $PropSchema.type
                                        $ActualType = [ScubaConfigValidator]::GetValueType($PropValue)
                                        if ($ActualType -ne $ExpectedType) {
                                            [void]$TempValidation.Errors.Add("${Context}: Property '$ItemProp' expected type '$ExpectedType', got '$ActualType' with value '$PropValue'")
                                        }
                                    }

                                    # Validate pattern
                                    if ($PropSchema.pattern -and $PropValue) {
                                        if ($PropValue -notmatch $PropSchema.pattern) {
                                            $FriendlyName = if ($PropSchema.friendlyName) { $PropSchema.friendlyName } else { "pattern" }
                                            [void]$TempValidation.Errors.Add("${Context}: Property '$ItemProp' value '$PropValue' does not match required format: $FriendlyName")
                                        }
                                    }

                                    # Validate minLength
                                    if ($PropSchema.minLength -and $PropValue) {
                                        if ($PropValue.Length -lt $PropSchema.minLength) {
                                            [void]$TempValidation.Errors.Add("${Context}: Property '$ItemProp' must be at least $($PropSchema.minLength) characters")
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        [void]$TempValidation.Errors.Add("${Context}: Expected type 'object' but got '$ActualType'")
                    }
                } elseif ($Option.type -eq "array") {
                    $ActualType = [ScubaConfigValidator]::GetValueType($Item)
                    if ($ActualType -ne "array") {
                        [void]$TempValidation.Errors.Add("${Context}: Expected type 'array' but got '$ActualType'")
                    }
                } else {
                    # Standard type validation
                    $ActualType = [ScubaConfigValidator]::GetValueType($Item)
                    if ($Option.type -and $ActualType -ne $Option.type) {
                        [void]$TempValidation.Errors.Add("${Context}: Expected type '$($Option.type)' but got '$ActualType'")
                    }
                }

                Write-Debug "TempValidation.Errors.Count = $($TempValidation.Errors.Count)"
                if ($TempValidation.Errors.Count -gt 0) {
                    Write-Debug "Errors found:"
                    foreach ($Err in $TempValidation.Errors) {
                        Write-Debug "  - $Err"
                    }
                }

                if ($TempValidation.Errors.Count -eq 0) {
                    Write-Debug "OneOf option VALID - breaking"
                    $OneOfValid = $true
                    break
                } else {
                    # If this option's type matches the actual item type, save these errors
                    if ($Option.type -eq $ActualItemType) {
                        $TypeMatchedErrors = $TempValidation.Errors
                    }
                    foreach ($Err in $TempValidation.Errors) {
                        [void]$OneOfErrors.Add($Err)
                    }
                }
            }

            Write-Debug "After oneOf loop - OneOfValid = $OneOfValid, Total errors = $($OneOfErrors.Count)"
            if (-not $OneOfValid) {
                # If we have errors from a type-matched option, only report those
                # Otherwise report all errors from all options
                $ErrorsToReport = if ($TypeMatchedErrors) { $TypeMatchedErrors } else { $OneOfErrors }

                foreach ($ErrorMsg in $ErrorsToReport) {
                    [void]$Validation.Errors.Add($ErrorMsg)
                }
            }
            return
        }

        # Validate pattern
        if ($ItemSchema.pattern -and $Item) {
            if ($Item -notmatch $ItemSchema.pattern) {
                $FriendlyName = [ScubaConfigValidator]::GetPatternFriendlyName($ItemSchema.pattern)
                if ($FriendlyName) {
                    [void]$Validation.Errors.Add("${Context}: Value '$Item' does not match required format: $FriendlyName")
                } else {
                    [void]$Validation.Errors.Add("${Context}: Value '$Item' does not match required pattern")
                }
            }
        }

        # Validate type
        if ($ItemSchema.type) {
            $ExpectedType = $ItemSchema.type
            $ActualType = [ScubaConfigValidator]::GetValueType($Item)
            if ($ActualType -ne $ExpectedType) {
                [void]$Validation.Errors.Add("${Context}: Expected type '$ExpectedType' but got '$ActualType'")
            }
        }

        # Validate required properties
        if ($ItemSchema.required -and $Item) {
            foreach ($RequiredProp in $ItemSchema.required) {
                if (-not ($Item.PSObject.Properties.Name -contains $RequiredProp)) {
                    [void]$Validation.Errors.Add("${Context}: Missing required property '$RequiredProp'")
                }
            }
        }
    }

    # Gets object keys safely from PSCustomObject or hashtable
    static [array] GetObjectKeys([object]$Object) {
        if ($Object -is [hashtable]) {
            return @($Object.Keys)
        } elseif ($Object.PSObject -and $Object.PSObject.Properties) {
            return @($Object.PSObject.Properties.Name)
        }
        return @()
    }

    # Gets value type for validation
    static [string] GetValueType([object]$Value) {
        if ($null -eq $Value) { return "null" }
        if ($Value -is [bool]) { return "boolean" }
        if ($Value -is [int] -or $Value -is [long]) { return "integer" }
        if ($Value -is [double] -or $Value -is [float]) { return "number" }
        if ($Value -is [string]) { return "string" }
        if ($Value -is [array] -or ($Value -is [System.Collections.IList] -and $Value -isnot [string])) { return "array" }
        if ($Value -is [PSCustomObject] -or $Value -is [hashtable]) { return "object" }
        return "unknown"
    }

    # Retrieves human-readable descriptions for regex patterns
    hidden static [string] GetPatternFriendlyName([string]$Pattern) {
        $Schema = [ScubaConfigValidator]::GetSchema()

        if ($Schema.definitions -and $Schema.definitions.patterns) {
            foreach ($PatternProperty in $Schema.definitions.patterns.PSObject.Properties) {
                $PatternDef = $PatternProperty.Value
                if ($PatternDef.pattern -eq $Pattern) {
                    return $PatternDef.friendlyName
                }
            }
        }

        return $null
    }

    # Categorizes validation errors into organized sections for better user experience
    hidden static [array] CategorizeErrors([array]$Errors) {
        $Defaults = [ScubaConfigValidator]::GetDefaults()

        if (-not $Defaults.outputSettings -or -not $Defaults.outputSettings.errorCategories) {
            return $Errors
        }

        $Categories = @{}

        # Initialize categories from array order
        foreach ($CategoryDef in $Defaults.outputSettings.errorCategories) {
            $Categories[$CategoryDef.name] = @()
        }

        # Categorize each error (remove duplicates using trimmed comparison)
        $SeenErrors = @{}
        foreach ($ErrorMessage in $Errors) {
            # Normalize the error message by trimming whitespace for comparison
            $NormalizedError = $ErrorMessage.Trim()

            # Skip if we've already seen this exact error
            if ($SeenErrors.ContainsKey($NormalizedError)) {
                continue
            }
            $SeenErrors[$NormalizedError] = $true

            $Categorized = $false

            foreach ($CategoryDef in $Defaults.outputSettings.errorCategories) {
                # Empty pattern means catch-all (typically "Other errors")
                if ([string]::IsNullOrEmpty($CategoryDef.pattern)) {
                    # This is the catch-all category, skip pattern matching
                    continue
                }

                if ($ErrorMessage -match $CategoryDef.pattern) {
                    $Categories[$CategoryDef.name] += $ErrorMessage
                    $Categorized = $true
                    break
                }
            }

            # If not categorized, add to the last category (catch-all with empty pattern)
            if (-not $Categorized) {
                $LastCategory = $Defaults.outputSettings.errorCategories[-1]
                $Categories[$LastCategory.name] += $ErrorMessage
            }
        }

        # Build output using array order
        $Output = @()

        foreach ($CategoryDef in $Defaults.outputSettings.errorCategories) {
            if ($Categories[$CategoryDef.name].Count -gt 0) {
                $Output += "`n--- $($CategoryDef.name) ---"
                $Output += $Categories[$CategoryDef.name]
            }
        }

        return $Output
    }

}

class ValidationResult {
    [bool]$IsValid
    [array]$ValidationErrors
    [array]$Warnings
    [object]$ParsedContent

    ValidationResult() {
        $this.IsValid = $true
        $this.ValidationErrors = @()
        $this.Warnings = @()
        $this.ParsedContent = $null
    }
}

