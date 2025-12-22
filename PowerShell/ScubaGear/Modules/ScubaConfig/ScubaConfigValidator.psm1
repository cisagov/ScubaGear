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

    # Static cache for loaded resources
    hidden static [hashtable]$_Cache = @{}

    static [void] Initialize([string]$ModulePath) {
        [ScubaConfigValidator]::_Cache['ModulePath'] = $ModulePath
        [ScubaConfigValidator]::LoadSchema()
        [ScubaConfigValidator]::LoadDefaults()
    }

    # Loads and caches JSON schema file for configuration validation.
    hidden static [void] LoadSchema() {
        $ModulePath = [ScubaConfigValidator]::_Cache['ModulePath']
        $SchemaPath = Join-Path -Path $ModulePath -ChildPath "ScubaConfigSchema.json"
        if (-not (Test-Path -Path $SchemaPath)) {
            throw "Schema file not found: $SchemaPath"
        }
        try {
            $SchemaContent = Get-Content -Path $SchemaPath -Raw
            # Convert JSON schema content
            [ScubaConfigValidator]::_Cache['Schema'] = $SchemaContent | ConvertFrom-Json
        }
        catch {
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

    # Validates YAML configuration file with default settings (no debug, full validation).
    static [ValidationResult] ValidateYamlFile([string]$FilePath) {
        return [ScubaConfigValidator]::ValidateYamlFile($FilePath, $false, $false)
    }

    # Validates YAML configuration file with debug mode option (full validation enabled).
    static [ValidationResult] ValidateYamlFile([string]$FilePath, [bool]$DebugMode) {
        return [ScubaConfigValidator]::ValidateYamlFile($FilePath, $DebugMode, $false)
    }

    # Main YAML validation method with full control over debug mode and default configurations validation.
    static [ValidationResult] ValidateYamlFile([string]$FilePath, [bool]$DebugMode, [bool]$SkipBusinessRules) {
        # Add debug information to the result
        $DebugInfo = @("DEBUG: ValidateYamlFile called with: $FilePath (SkipBusinessRules: $SkipBusinessRules)")
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
            # Check if this is a duplicate key error - if so, rethrow it
            if ($_.Exception.Message -like "*Duplicate key*") {
                throw
            }
            $Result.ValidationErrors += "Failed to parse YAML content: $($_.Exception.Message)"
            return $Result
        }

        # If skipping default configurations, only return parsed content without validation
        if ($SkipBusinessRules) {
            $Result.IsValid = $true
            return $Result
        }

        # Validate against schema
        $DebugInfo += "DEBUG: About to call ValidateAgainstSchema with object type: $($YamlObject.GetType().Name)"
        $SchemaValidation = [ScubaConfigValidator]::ValidateAgainstSchema($YamlObject, $DebugMode)
        $DebugInfo += "DEBUG: ValidateAgainstSchema returned with $($SchemaValidation.Errors.Count) errors"
        $Result.ValidationErrors += $SchemaValidation.Errors
        $Result.Warnings += $SchemaValidation.Warnings

        # Add debug info as warnings only in debug mode
        if ($DebugMode) {
            $Result.Warnings += $DebugInfo
        }

        # Additional business logic validation
        $BusinessValidation = [ScubaConfigValidator]::ValidateBusinessRules($YamlObject, $DebugMode)
        $Result.ValidationErrors += $BusinessValidation.Errors
        $Result.Warnings += $BusinessValidation.Warnings

        # Categorize and organize errors into sections
        $Result.ValidationErrors = [ScubaConfigValidator]::CategorizeErrors($Result.ValidationErrors)

        $Result.IsValid = ($Result.ValidationErrors.Count -eq 0)
        return $Result
    }

    # Categorizes validation errors into organized sections for better user experience
    # This method transforms a flat list of error messages into grouped sections based on error types,
    # making it easier for users to understand and address different categories of configuration issues.
    hidden static [array] CategorizeErrors([array]$Errors) {
        $Defaults = [ScubaConfigValidator]::GetDefaults()

        # Get error categorization rules and display order from the configuration file
        # This allows the categorization logic to be data-driven rather than hardcoded
        # Categories are defined in ScubaConfigDefaults.json with regex patterns and display names
        $ErrorCategories = if ($Defaults.outputSettings -and $Defaults.outputSettings.errorCategories) {
            $Defaults.outputSettings.errorCategories
        } else {
            @()  # Fallback to empty if not configured
        }

        # Initialize collections for each configured error category
        # This dynamic approach allows new categories to be added via configuration without code changes
        $CategoryErrors = @{}
        foreach ($Category in $ErrorCategories) {
            # Create empty array for each category name (e.g., "Property errors", "Exclusion Policy errors")
            $CategoryErrors[$Category.name] = @()
        }
        # Always include "Other errors" as a catchall for unmatched error messages
        $CategoryErrors["Other errors"] = @()  # Always have "Other errors" as fallback

        # Process each error message and assign it to the appropriate category
        # Uses regex patterns from configuration to match error types
        foreach ($ErrorMsg in $Errors) {
            $Categorized = $false

            # Check error message against each configured category pattern
            # Patterns are regex expressions that identify error types (e.g., "^Property '.*' " for property errors)
            foreach ($Category in $ErrorCategories) {
                if ($ErrorMsg -match $Category.pattern) {
                    # Add error to the matching category and stop processing (first match wins)
                    $CategoryErrors[$Category.name] += $ErrorMsg
                    $Categorized = $true
                    break  # Stop after first match
                }
            }

            # If no pattern matched, put error in the "Other errors" catchall category
            # This ensures no error messages are lost even if categorization patterns are incomplete
            if (-not $Categorized) {
                $CategoryErrors["Other errors"] += $ErrorMsg
            }
        }

        # Build organized output using the display order specified in configuration
        # This controls the sequence in which error categories appear to the user
        $OrganizedErrors = @()
        foreach ($CategoryName in $Defaults.outputSettings.errorCategoryDisplayOrder) {
            # Only include categories that have actual errors to avoid empty sections
            if ($CategoryErrors.ContainsKey($CategoryName) -and $CategoryErrors[$CategoryName].Count -gt 0) {
                # Add category header (e.g., "Property errors:")
                $OrganizedErrors += "`n$CategoryName`:"
                # Add each error message with indentation for readability
                foreach ($ErrorMsg in $CategoryErrors[$CategoryName]) {
                    $OrganizedErrors += "  - $ErrorMsg"
                }
            }
        }

        # Add any categories not explicitly listed in display order (safety net)
        # This handles cases where new categories are added but display order isn't updated
        foreach ($CategoryName in $CategoryErrors.Keys) {
            if ($CategoryName -notin $Defaults.outputSettings.errorCategoryDisplayOrder -and $CategoryErrors[$CategoryName].Count -gt 0) {
                $OrganizedErrors += "`n$CategoryName`:"
                foreach ($ErrorMsg in $CategoryErrors[$CategoryName]) {
                    $OrganizedErrors += "  - $ErrorMsg"
                }
            }
        }

        return $OrganizedErrors
    }

    # Performs JSON Schema Draft-7 validation against configuration objects.
    hidden static [PSCustomObject] ValidateAgainstSchema([object]$ConfigObject, [bool]$DebugMode) {
        $Validation = [PSCustomObject]@{
            Errors = @()
            Warnings = @()
        }

        $Schema = [ScubaConfigValidator]::GetSchema()

        # Get required properties from defaults configuration (minRequired section)
        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $RequiredProperties = if ($Defaults.minRequired) { $Defaults.minRequired } else { @() }

        if ($RequiredProperties.Count -gt 0) {
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

            # Add debugging output only in debug mode
            if ($DebugMode) {
                $Validation.Warnings += "DEBUG - Required properties from config: $($RequiredProperties -join ', ')"
                $Validation.Warnings += "DEBUG - Config object type: $($ConfigObject.GetType().Name)"
                $Validation.Warnings += "DEBUG - Config properties found: $($ConfigProperties -join ', ')"
            }

            foreach ($RequiredProp in $RequiredProperties) {
                if ($RequiredProp -notin $ConfigProperties) {
                    $Validation.Errors += "Required property '$RequiredProp' is missing"
                    if ($DebugMode) {
                        $Validation.Warnings += "DEBUG - Missing property: $RequiredProp"
                    }
                } else {
                    if ($DebugMode) {
                        $Validation.Warnings += "DEBUG - Found property: $RequiredProp"
                    }
                }
            }
        }

        # Validate ProductNames - schema-driven validation
        if ($Schema.properties -and $Schema.properties.ProductNames) {
            $ProductNamesSchema = $Schema.properties.ProductNames

            # Check if ProductNames exists and handle null/empty cases
            if (-not $ConfigObject.ProductNames) {
                $Validation.Errors += "Property 'ProductNames' is required but missing or null"
            } elseif ($ConfigObject.ProductNames -is [array] -and $ConfigObject.ProductNames.Count -eq 0) {
                # Check minItems constraint from schema
                if ($ProductNamesSchema.minItems -and $ProductNamesSchema.minItems -gt 0) {
                    $Validation.Errors += "Property 'ProductNames' cannot be empty - at least $($ProductNamesSchema.minItems) product(s) must be specified"
                }
            } else {
                # Validate array constraints
                if ($ProductNamesSchema.minItems -and $ConfigObject.ProductNames.Count -lt $ProductNamesSchema.minItems) {
                    $Validation.Errors += "Property 'ProductNames' must contain at least $($ProductNamesSchema.minItems) product(s), found $($ConfigObject.ProductNames.Count)"
                }

                if ($ProductNamesSchema.maxItems -and $ConfigObject.ProductNames.Count -gt $ProductNamesSchema.maxItems) {
                    $Validation.Errors += "Property 'ProductNames' cannot contain more than $($ProductNamesSchema.maxItems) product(s), found $($ConfigObject.ProductNames.Count)"
                }

                # Validate individual product values
                if ($ProductNamesSchema.items -and $ProductNamesSchema.items.enum) {
                    $ValidProducts = $ProductNamesSchema.items.enum
                    foreach ($Product in $ConfigObject.ProductNames) {
                        if ($Product -notin $ValidProducts) {
                            $Validation.Errors += "Property 'ProductNames' contains invalid value '$Product'. Valid values: $($ValidProducts -join ', ')"
                        }
                    }
                }

                # Check uniqueItems constraint
                if ($ProductNamesSchema.uniqueItems -and ($ConfigObject.ProductNames | Group-Object | Where-Object Count -gt 1)) {
                    $Duplicates = ($ConfigObject.ProductNames | Group-Object | Where-Object Count -gt 1).Name
                    $Validation.Errors += "Property 'ProductNames' contains duplicate values: $($Duplicates -join ', ')"
                }

                # Handle wildcard behavior (warning only)
                if ($ConfigObject.ProductNames -contains '*') {
                    if ($ConfigObject.ProductNames.Count -gt 1) {
                        $Validation.Warnings += "Wildcard '*' found with other products. All products will be selected."
                    }
                }
            }
        }

        # Validate M365Environment
        if ($ConfigObject.M365Environment) {
            $ValidEnvironments = $Schema.properties.M365Environment.enum
            if ($ConfigObject.M365Environment -notin $ValidEnvironments) {
                $Validation.Errors += "Property 'M365Environment' value '$($ConfigObject.M365Environment)' is not valid. Valid environments: $($ValidEnvironments -join ', ')"
            }
        }

        # Validate Organization format
        if ($ConfigObject.Organization -and $Schema.properties -and $Schema.properties.Organization) {
            $OrgPattern = $Schema.properties.Organization.pattern
            if ($OrgPattern -and $ConfigObject.Organization -notmatch $OrgPattern) {
                $Validation.Errors += "Property 'Organization' value '$($ConfigObject.Organization)' is not a valid fully qualified domain name (FQDN)"
            }
        }

        # Validate additionalProperties constraint (enforce "additionalProperties": false)
        if ($Schema.additionalProperties -eq $false) {
            # Get all properties from the config object
            $ConfigProperties = if ($ConfigObject -is [hashtable]) {
                @($ConfigObject.Keys)
            } elseif ($ConfigObject.PSObject -and $ConfigObject.PSObject.Properties) {
                @($ConfigObject.PSObject.Properties.Name)
            } else {
                try {
                    @($ConfigObject | Get-Member -MemberType NoteProperty, Property | Select-Object -ExpandProperty Name)
                } catch {
                    @()
                }
            }

            # Get all allowed properties from schema
            $AllowedProperties = if ($Schema.properties) {
                @($Schema.properties.PSObject.Properties.Name)
            } else {
                @()
            }

            # Find properties in config that are not in schema
            $InvalidProperties = $ConfigProperties | Where-Object { $_ -notin $AllowedProperties }

            if ($InvalidProperties.Count -gt 0) {
                $Validation.Errors += "Configuration contains properties that are not allowed: $($InvalidProperties -join ', '). Valid properties are: $($AllowedProperties -join ', ')"
            }
        }

        # Get validation settings from defaults
        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $ValidationSettings = $Defaults.validation

        # Validate product exclusions configurations (if enabled)
        if ($ValidationSettings.validateExclusions -ne $false) {
            [ScubaConfigValidator]::ValidateProductExclusions($ConfigObject, $Schema, $Validation)
        }

        # Generic validation of all properties against schema
        if ($Schema.properties) {
            # Get config properties
            $ConfigProperties = [ScubaConfigValidator]::GetObjectKeys($ConfigObject)

            foreach ($PropertyName in $ConfigProperties) {
                $PropertyValue = $ConfigObject.$PropertyName
                $PropertySchema = $Schema.properties.$PropertyName

                # Skip validation for OmitPolicy and AnnotatePolicy if disabled
                if ($PropertyName -eq "OmitPolicy" -and $ValidationSettings.validateOmitPolicy -eq $false) {
                    continue
                }
                if ($PropertyName -eq "AnnotatePolicy" -and $ValidationSettings.validateAnnotatePolicy -eq $false) {
                    continue
                }

                if ($PropertySchema -and $PropertyValue) {
                    # Validate this property against its schema
                    [ScubaConfigValidator]::ValidatePropertyAgainstSchema($PropertyValue, $PropertySchema, $Validation, "Property '$PropertyName'")
                }
            }
        }

        return $Validation
    }

    # Performs business logic validation beyond basic schema compliance.
    hidden static [PSCustomObject] ValidateBusinessRules([object]$ConfigObject, [bool]$DebugMode) {
        $Validation = [PSCustomObject]@{
            Errors = @()
            Warnings = @()
        }

        # Validate OPA path if specified
        if ($ConfigObject.OPAPath -and $ConfigObject.OPAPath -ne ".") {
            if (-not (Test-Path -Path $ConfigObject.OPAPath)) {
                $Validation.Warnings += "OPA path '$($ConfigObject.OPAPath)' does not exist"
            }
        }

        # Enhanced validation for critical organizational fields (content quality only)
        [ScubaConfigValidator]::ValidateOrganizationalFields($ConfigObject, $Validation)

        # Enhanced validation for ProductNames (content quality only)
        [ScubaConfigValidator]::ValidateProductNames($ConfigObject, $Validation)

        # Enhanced validation for M365Environment (content quality only)
        [ScubaConfigValidator]::ValidateM365Environment($ConfigObject, $Validation)

        # Validate product exclusion property casing (business requirement)
        [ScubaConfigValidator]::ValidateProductExclusionCasing($ConfigObject, $Validation)

        # Check for exclusion configurations on products that don't support them
        [ScubaConfigValidator]::ValidateUnsupportedExclusions($ConfigObject, $Validation)

        # Check for invalid exclusion types on products that support exclusions
        [ScubaConfigValidator]::ValidateUnsupportedExclusionTypes($ConfigObject, $Validation)

        return $Validation
    }

    # Validates individual policy ID format and product alignment.
    hidden static [PSCustomObject] ValidatePolicyId([string]$PolicyId, [array]$ProductNames) {
        $Result = [PSCustomObject]@{
            IsValid = $false
            Error = ""
        }

        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $PolicyPattern = $Defaults.validation.policyIdPattern

        if ($PolicyId -notmatch $PolicyPattern) {
            # Try to extract product from malformed policy ID to give better error message
            $PolicyParts = $PolicyId -split "\."
            $ProductInPolicy = if ($PolicyParts.Length -ge 2 -and $PolicyParts[1]) { $PolicyParts[1] } else { $null }

            # Generate format example from pattern
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
    # JSON Schema allows referencing reusable definitions using $ref, which keeps the schema DRY and maintainable.
    # This method follows $ref pointers to return the actual validation schema object.
    static [object] ResolveSchemaReference([object]$Schema, [object]$PropertySchema) {
        # Check if this property schema uses a $ref reference instead of inline definition
        # $ref allows reusing common patterns like GUID formats, domain patterns, etc.
        if ($PropertySchema.'$ref') {
            $RefPath = $PropertySchema.'$ref'
            # Currently only supports pattern references in the format "#/definitions/patterns/patternName"
            # This handles cases like Organization: { "$ref": "#/definitions/patterns/orgDomain" }
            # where orgDomain defines the FQDN validation pattern and friendly error message
            if ($RefPath.StartsWith("#/definitions/patterns/")) {
                # Extract the pattern name from the reference path
                # Example: "#/definitions/patterns/orgDomain" -> "orgDomain"
                $PatternName = $RefPath.Replace("#/definitions/patterns/", "")
                # Navigate to the actual pattern definition in the schema
                # This returns the full pattern object including "pattern", "friendlyName", etc.
                if ($Schema.definitions -and $Schema.definitions.patterns -and $Schema.definitions.patterns.$PatternName) {
                    return $Schema.definitions.patterns.$PatternName
                }
            }
        }
        # If no $ref or reference couldn't be resolved, return the original property schema
        # This allows the calling code to work with both direct definitions and $ref patterns transparently
        return $PropertySchema
    }

    # Validates individual properties against their schema definitions.
    static [void] ValidatePropertyAgainstSchema([object]$Value, [object]$PropertySchema, [PSCustomObject]$Validation, [string]$Context) {
        # Resolve $ref references to actual schema definitions
        if ($PropertySchema.'$ref') {
            $Schema = [ScubaConfigValidator]::GetSchema()
            $PropertySchema = [ScubaConfigValidator]::ResolveSchemaReference($Schema, $PropertySchema)
        }

        # Handle array validation
        if ($PropertySchema.type -eq "array" -and $PropertySchema.items) {
            $IsArray = $Value -is [array] -or ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string])

            if ($IsArray) {
                foreach ($Item in $Value) {
                    [ScubaConfigValidator]::ValidateItemAgainstSchema($Item, $PropertySchema.items, $Validation, $Context)
                }
            } else {
                $ActualType = [ScubaConfigValidator]::GetValueType($Value)
                $Validation.Errors += "$Context must be an array but got $ActualType"
            }
        }
        # Handle object validation
        elseif ($PropertySchema.type -eq "object") {
            [ScubaConfigValidator]::ValidateObjectAgainstSchema($Value, $PropertySchema, $Validation, $Context)

            # Handle patternProperties validation (for OmitPolicy, AnnotatePolicy, etc.)
            if ($PropertySchema.patternProperties) {
                $ObjectKeys = [ScubaConfigValidator]::GetObjectKeys($Value)
                foreach ($Key in $ObjectKeys) {
                    $KeyValue = $Value.$Key
                    $PatternMatched = $false

                    # Check each pattern in patternProperties
                    foreach ($Pattern in $PropertySchema.patternProperties.PSObject.Properties.Name) {
                        if ($Key -match $Pattern) {
                            $PatternSchema = $PropertySchema.patternProperties.$Pattern
                            [ScubaConfigValidator]::ValidateItemAgainstSchema($KeyValue, $PatternSchema, $Validation, "$Context key '$Key'")
                            $PatternMatched = $true

                            # Additional validation for policy IDs (OmitPolicy/AnnotatePolicy)
                            if ($Context -match "OmitPolicy|AnnotatePolicy") {
                                $Defaults = [ScubaConfigValidator]::GetDefaults()
                                $ProductNames = $Defaults.defaults.AllProductNames
                                $PolicyValidation = [ScubaConfigValidator]::ValidatePolicyId($Key, $ProductNames)
                                if (-not $PolicyValidation.IsValid) {
                                    $Validation.Errors += $PolicyValidation.Error
                                }
                            }
                            break  # Stop after first matching pattern
                        }
                    }

                    # If no pattern matched, report error
                    if (-not $PatternMatched) {
                        $Validation.Errors += "$Context key '$Key' does not match any allowed pattern"
                    }
                }
            }
        }
        # Handle other types
        else {
            [ScubaConfigValidator]::ValidateItemAgainstSchema($Value, $PropertySchema, $Validation, $Context)
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

                        # Check for additionalProperties: false and provide specific error messages
                        if ($Option.additionalProperties -eq $false) {
                            $AllowedProps = if ($Option.properties) { $Option.properties.PSObject.Properties.Name } else { @() }
                            $ItemProps = [ScubaConfigValidator]::GetObjectKeys($Item)
                            foreach ($ItemProp in $ItemProps) {
                                if ($ItemProp -notin $AllowedProps) {
                                    # Schema-driven validation - if property not in schema, it's invalid
                                    if ($Context -like "*AnnotatePolicy*" -or $Context -like "*OmitPolicy*") {
                                        $TempValidation.Errors += "$Context has invalid property '$ItemProp'. Valid properties: $($AllowedProps -join ', ')"
                                    } else {
                                        $TempValidation.Errors += "$Context has unexpected property '$ItemProp'"
                                    }
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
                # For AnnotatePolicy and OmitPolicy, provide more specific error messages
                if ($Context -like "*AnnotatePolicy*" -or $Context -like "*OmitPolicy*") {
                    # Add the specific errors instead of generic "does not match any allowed formats"
                    foreach ($Error in $OneOfErrors) {
                        $Validation.Errors += $Error
                    }
                } else {
                    $Validation.Errors += "$Context does not match any of the allowed formats"
                }
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
        elseif ($Value -is [hashtable] -or $Value.PSObject) { return "object" }
        elseif ($Value -is [array]) { return "array" }
        elseif ($Value -is [System.Collections.IEnumerable]) { return "array" }
        else { return "unknown ($($Value.GetType().Name))" }
    }

    # Safely extracts property names from objects while filtering system properties.
    # This method handles the complexity of PowerShell object types (hashtables vs PSCustomObjects)
    # and filters out system properties that aren't actual configuration data.
    static [array] GetObjectKeys([object]$Object) {
        # Handle null objects gracefully to prevent downstream errors
        if ($null -eq $Object) {
            return @()
        }

        # Hashtables store configuration data differently than PSCustomObjects
        # Need different approaches to extract just the user-defined property names
        if ($Object -is [hashtable]) {
            # For hashtables, the Keys collection contains both user keys and system properties
            # Filter out PowerShell system properties that can get mixed in during processing
            # These system properties (Count, IsReadOnly, etc.) aren't configuration data
            return $Object.Keys | Where-Object {
                $_ -is [string] -and
                $_ -notmatch '^(Count|IsReadOnly|IsFixedSize|IsSynchronized|Keys|Values|SyncRoot|Comparer)$'
            }
        } elseif ($Object.PSObject -and $Object.PSObject.Properties) {
            # For PSCustomObjects (created from ConvertFrom-Json or ConvertFrom-Yaml),
            # the PSObject.Properties collection contains the actual data properties
            # This is the most reliable way to get property names from deserialized objects
            return $Object.PSObject.Properties.Name
        } else {
            # Fallback method using Get-Member for other object types
            # This handles edge cases where objects don't fit the common patterns above
            # Targets NoteProperty and Property types which represent data properties
            try {
                return ($Object | Get-Member -MemberType NoteProperty, Property | Select-Object -ExpandProperty Name)
            } catch {
                # Return empty array if Get-Member fails rather than throwing an exception
                # This prevents validation from crashing on unexpected object types
                return @()
            }
        }
    }

    # Validates organizational field content quality using schema definitions.
    # This method provides a completely schema-driven approach to validate string properties,
    # eliminating hardcoded field names and automatically applying validation rules based on schema constraints.
    hidden static [void] ValidateOrganizationalFields([object]$ConfigObject, [PSCustomObject]$Validation) {
        $Schema = [ScubaConfigValidator]::GetSchema()

        # Schema-driven validation - automatically validate all string properties with constraints
        # This approach ensures that any new string property added to the schema will automatically
        # get validated without requiring code changes in this PowerShell module
        if ($Schema.properties) {
            # Get all property names from the configuration object (handles both hashtables and PSCustomObjects)
            # This is used for performance optimization - we only validate properties that actually exist
            $ConfigKeys = [ScubaConfigValidator]::GetObjectKeys($ConfigObject)

            # Iterate through every property defined in the JSON schema to check for validation rules
            # This loop processes ALL schema properties, not just the ones currently in the config
            foreach ($PropertyName in $Schema.properties.PSObject.Properties.Name) {
                $PropertySchema = $Schema.properties.$PropertyName

                # Resolve JSON Schema $ref references to get the actual validation constraints
                # $ref patterns like "#/definitions/patterns/orgDomain" need to be resolved to their actual schema objects
                # This allows the schema to be cleaner by reusing common patterns like GUID formats, domain patterns, etc.
                if ($PropertySchema.'$ref') {
                    $PropertySchema = [ScubaConfigValidator]::ResolveSchemaReference($Schema, $PropertySchema)
                }

                # Only process string properties that actually exist in the configuration
                # This optimization prevents unnecessary processing of schema properties not present in the config
                # We specifically target string types since other types (arrays, objects, booleans) have different validation needs
                if ($PropertySchema.type -eq "string" -and $PropertyName -in $ConfigKeys) {
                    $PropertyValue = $ConfigObject.$PropertyName

                    # Enhanced validation for string properties that have minLength constraints in the schema
                    # The JSON schema minLength constraint catches empty strings, but PowerShell's [string]::IsNullOrWhiteSpace
                    # provides more comprehensive validation for whitespace-only values (spaces, tabs, newlines, etc.)
                    # This business logic layer adds value beyond what JSON schema alone can provide
                    if ($PropertySchema.minLength -and $PropertySchema.minLength -gt 0) {
                        # Check for whitespace-only values that would pass JSON schema minLength but are effectively empty
                        # null check prevents PowerShell errors, IsNullOrWhiteSpace handles edge cases like "   " or "\t\n"
                        if ($null -ne $PropertyValue -and [string]::IsNullOrWhiteSpace($PropertyValue)) {
                            $Validation.Errors += "Property '$PropertyName' cannot be empty or contain only whitespace"
                        }
                    }
                }
            }
        }
    }

    # Validates product exclusion property names for correct capitalization.
    # This method ensures Rego policy compatibility by enforcing case-sensitive product names.
    # Rego policies expect specific capitalization (e.g., "Aad" not "aad" or "AAD") for exclusion processing.
    hidden static [void] ValidateProductExclusionCasing([object]$ConfigObject, [PSCustomObject]$Validation) {
        $Defaults = [ScubaConfigValidator]::GetDefaults()

        # Get products that support exclusions from the configuration defaults
        # If products configuration is missing, skip validation entirely to prevent errors
        if (-not ($Defaults.products)) {
            return
        }

        # Build a lookup map of correct capitalization for products that support exclusions
        # Key: lowercase product name, Value: proper capitalization (e.g., "aad" -> "Aad")
        # This map only includes products where supportsExclusions is true to avoid false positives
        $CorrectCasing = @{}
        foreach ($ProductKey in $Defaults.products.PSObject.Properties.Name) {
            $Product = $Defaults.products.$ProductKey
            # Only validate products that actually support exclusions (aad, exo, defender)
            # Products like teams/sharepoint don't support exclusions, so their casing is irrelevant
            if ($Product.supportsExclusions -eq $true) {
                # Generate proper capitalization: first letter uppercase, rest lowercase ("aad" -> "Aad")
                $CorrectCasing[$ProductKey.ToLower()] = $ProductKey.Substring(0,1).ToUpper() + $ProductKey.Substring(1).ToLower()
            }
        }

        # Get all top-level property names from the configuration object
        $ConfigKeys = [ScubaConfigValidator]::GetObjectKeys($ConfigObject)

        # Check each configuration property to see if it's a product with incorrect capitalization
        foreach ($Key in $ConfigKeys) {
            # Convert to lowercase for case-insensitive lookup in our correct casing map
            $LowerKey = $Key.ToLower()
            # Only process keys that correspond to products supporting exclusions
            if ($CorrectCasing.ContainsKey($LowerKey)) {
                # Use case-sensitive comparison (-cne) to detect capitalization mismatches
                # This catches cases like "aad" vs "Aad" or "AAD" vs "Aad"
                if ($Key -cne $CorrectCasing[$LowerKey]) {
                    $Validation.Errors += "Property '$Key' should use correct capitalization: '$($CorrectCasing[$LowerKey])'. Product exclusion properties are case-sensitive."
                }
            }
        }
    }

    # Validates that exclusion configurations are not set for products that don't support them.
    # This method helps users clean up unnecessary configuration sections that have no functional effect.
    # Products like Teams and SharePoint don't support exclusions, so any exclusion config is ignored during scanning.
    hidden static [void] ValidateUnsupportedExclusions([object]$ConfigObject, [PSCustomObject]$Validation) {
        $Defaults = [ScubaConfigValidator]::GetDefaults()

        # Get products that don't support exclusions from the configuration defaults
        # Early return if products configuration is missing to prevent processing errors
        if (-not ($Defaults.products)) {
            return
        }

        # Build a lookup map of products that don't support exclusions
        # This identifies configuration sections that users might have mistakenly added
        # Key: lowercase product name, Value: proper capitalization for user-friendly messages
        $UnsupportedProducts = @{}
        foreach ($ProductKey in $Defaults.products.PSObject.Properties.Name) {
            $Product = $Defaults.products.$ProductKey
            # Only flag products explicitly marked as not supporting exclusions
            # Products with supportsExclusions: false include teams, sharepoint, powerplatform
            if ($Product.supportsExclusions -eq $false) {
                # Store both the lowercase key (for case-insensitive matching) and proper capitalization (for user messages)
                # This handles cases where users write "teams", "TEAMS", "Teams", etc.
                $UnsupportedProducts[$ProductKey.ToLower()] = $ProductKey.Substring(0,1).ToUpper() + $ProductKey.Substring(1).ToLower()
            }
        }

        # Get all top-level property names from the configuration object
        $ConfigKeys = [ScubaConfigValidator]::GetObjectKeys($ConfigObject)

        # Check if users have configured exclusions for products that don't support them
        foreach ($Key in $ConfigKeys) {
            $LowerKey = $Key.ToLower()
            # Match against products that don't support exclusions (case-insensitive)
            if ($UnsupportedProducts.ContainsKey($LowerKey)) {
                # Generate warning (not error) since this doesn't break functionality, just creates unused config
                # Suggest removal to keep configuration clean and avoid user confusion
                $Validation.Warnings += "Product '$Key' does not support exclusions. Consider removing this section as it has no effect on ScubaGear scanning."
            }
        }
    }

    # Validates that exclusion types are supported by the product.
    # Each product supports different exclusion types (e.g., Aad supports CapExclusions and RoleExclusions,
    # while Defender supports SensitiveAccounts). This method ensures users don't use invalid exclusion types.
    hidden static [void] ValidateUnsupportedExclusionTypes([object]$ConfigObject, [PSCustomObject]$Validation) {
        $Defaults = [ScubaConfigValidator]::GetDefaults()

        # Get products that support exclusions from the configuration defaults
        # Early exit if configuration is missing to prevent downstream errors
        if (-not ($Defaults.products)) {
            return
        }

        # Build a map of supported exclusion types for each product that supports exclusions
        # Key: properly capitalized product name ("Aad", "Exo", "Defender")
        # Value: array of supported exclusion types for that product
        # Example: "Aad" -> ["CapExclusions", "RoleExclusions"]
        $SupportedTypes = @{}
        foreach ($ProductKey in $Defaults.products.PSObject.Properties.Name) {
            $Product = $Defaults.products.$ProductKey
            # Only process products that actually support exclusions
            if ($Product.supportsExclusions -eq $true) {
                # Use proper capitalization for the key ("Aad", "Exo", "Defender")
                # This matches the expected casing in YAML configuration files
                $ProperName = $ProductKey.Substring(0,1).ToUpper() + $ProductKey.Substring(1).ToLower()
                # Store the array of supported exclusion types for this product
                # This comes from the "supportedExclusionTypes" array in the defaults configuration
                $SupportedTypes[$ProperName] = $Product.supportedExclusionTypes
            }
        }

        # Get all top-level property names from the configuration object
        $ConfigKeys = [ScubaConfigValidator]::GetObjectKeys($ConfigObject)

        # Process each product configuration section that supports exclusions
        foreach ($Key in $ConfigKeys) {
            # Only validate products that we know support exclusions
            if ($SupportedTypes.ContainsKey($Key)) {
                $ProductExclusions = $ConfigObject.$Key
                $AllowedTypes = $SupportedTypes[$Key]

                # Get all policy IDs configured under this product
                # Policy IDs are the keys under each product section (e.g., "MS.AAD.1.1v1")
                $PolicyIds = [ScubaConfigValidator]::GetObjectKeys($ProductExclusions)

                # Validate exclusion types for each policy ID
                foreach ($PolicyId in $PolicyIds) {
                    $PolicyExclusions = $ProductExclusions.$PolicyId
                    # Skip empty or null policy exclusion sections
                    if ($PolicyExclusions) {
                        # Get the exclusion type keys under this policy ID
                        # These are the immediate children like "CapExclusions", "RoleExclusions", "SensitiveAccounts", etc.
                        $ExclusionTypes = [ScubaConfigValidator]::GetObjectKeys($PolicyExclusions)

                        # Check each exclusion type against the list of supported types for this product
                        foreach ($ExclusionType in $ExclusionTypes) {
                            # Schema-driven validation - if exclusion type not in allowed list, it's invalid
                            if ($ExclusionType -notin $AllowedTypes) {
                                $Validation.Errors += "Policy ID: '$PolicyId' under '$Key' has invalid property '$ExclusionType'. Supported properties: $($AllowedTypes -join ', ')"
                            }
                        }
                    }
                }
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