<#
    .SYNOPSIS
    ScubaConfigValidator provides metadata-driven validation of ScubaGear configuration files using JSON Schema

    .DESCRIPTION
    ScubaConfigValidator implements a validation system that combines JSON Schema validation with metadata-driven
    exclusion type checking. The validator reads policyExclusionMappings from schema metadata to automatically
    validate that exclusion types match the policy IDs being configured.

    .EXAMPLE
    # Replace <CONFIG_PATH> with your YAML file path
    using module '.\ScubaConfig.psm1'
    [ScubaConfig]::ResetInstance()
    [ScubaConfig]::GetInstance().LoadConfig('<CONFIG_PATH>')"

    .EXAMPLE

    # Quick Config Validation Test Steps
    # ===================================

    # Step 1: Navigate to ScubaConfig module directory
    $yamlfilePath =  'e:\Work\Scuba\ScubaGearTests\ScubaUIYamlTests\dtolab.onmicrosoft.com.fullexclusion.yaml'

    # Step 2 Navigate to ScubaConfig module directory
    cd 'C:\path\to\ScubaGear\Modules\ScubaConfig'


    # Step 2: Test your YAML file (replace path with your file)
    using module '.\ScubaConfig.psm1'
    try {
        [ScubaConfig]::ResetInstance()
        $config = [ScubaConfig]::GetInstance()
        $result = $config.LoadConfig($yamlfilePath)
        Write-Host 'Configuration is valid!' -ForegroundColor Green
        Write-Host 'OrgName:' $config.Configuration.OrgName
        Write-Host 'ProductNames:' ($config.Configuration.ProductNames -join ', ')
    }catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
#>

class ScubaConfigValidator {


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

    # Detects the current operating system
    hidden static [string] GetOperatingSystem() {
        # PowerShell Core has $IsWindows, $IsLinux, $IsMacOS automatic variables
        # Windows PowerShell 5.1 doesn't have these, so we check if they exist
        # In classes, we must assign variables locally
        $IsLinuxVar = Get-Variable -Name 'IsLinux' -ErrorAction SilentlyContinue
        if ($null -ne $IsLinuxVar -and $IsLinuxVar.Value) {
            return 'Linux'
        }

        $IsMacOSVar = Get-Variable -Name 'IsMacOS' -ErrorAction SilentlyContinue
        if ($null -ne $IsMacOSVar -and $IsMacOSVar.Value) {
            return 'MacOS'
        }

        # Default to Windows (either $IsWindows is true or we're in Windows PowerShell 5.1)
        return 'Windows'
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

        # Note: minRequired validation is handled in ScubaConfig.ValidateRequiredFields()
        # which runs BEFORE defaults are applied to catch truly missing fields
        # This prevents default values from hiding missing required properties

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
                [void]$Validation.Errors.Add("Property '$($Property.Name)' cannot be whitespace only.")
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
                            # Check pathMustExist from the original property definition (not the resolved ref)
                            # This allows schema to control whether non-existence is an error or warning
                            $RequirePathExists = $true  # Default to error if not specified
                            if ($SchemaProperty.PSObject.Properties.Name -contains 'pathMustExist') {
                                $RequirePathExists = $SchemaProperty.pathMustExist
                            }

                            if ($RequirePathExists) {
                                # Path must exist - error
                                [void]$Validation.Errors.Add("Property '$PropertyName': Directory does not exist: $PropertyValue.")
                            } else {
                                # Path will be created - warning
                                [void]$Validation.Warnings.Add("Property '$PropertyName': Directory does not exist: $PropertyValue. The directory will be created when ScubaGear runs.")
                            }
                        }
                    }
                }
            }
        }

        # Validate OPA executable exists
        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $OS = [ScubaConfigValidator]::GetOperatingSystem()
        $OPAExecutableName = $Defaults.defaults.OPAExecutable.$OS

        # Check if user specified a custom OPAPath (from YAML or parameter)
        # We need to check if OPAPath exists AND is different from the default value
        $DefaultOPAPath = $Defaults.defaults.OPAPath
        #$ExpandedDefaultPath = $DefaultOPAPath -replace '~', $env:USERPROFILE
        $ExpandedDefaultPath = (Get-Item -LiteralPath $DefaultOPAPath).FullName  # Get full path to handle short paths from env variables
        $UserSpecifiedPath = $false

        if ($ConfigObject.PSObject.Properties.Name -contains 'OPAPath') {
            # OPAPath exists - check if it's different from default (compare expanded versions)
            $ConfigOPAPath = $ConfigObject.OPAPath
            $ExpandedConfigPath = (Get-Item -LiteralPath $ConfigOPAPath).FullName
            if ($ExpandedConfigPath -ne $ExpandedDefaultPath) {
                $UserSpecifiedPath = $true
            }
        }

        if ($UserSpecifiedPath) {
            # User specified custom path - validate that path only (no fallback)
            $CustomOPAPath = $ConfigObject.OPAPath
            $ExpandedCustomPath = (Get-Item -LiteralPath $CustomOPAPath).FullName
            $CustomOPAExecutablePath = Join-Path -Path $ExpandedCustomPath -ChildPath $OPAExecutableName

            if (-not (Test-Path -LiteralPath $CustomOPAExecutablePath -PathType Leaf)) {
                # Custom path specified but OPA not found - error
                $ErrorMsg = "OPA executable not found: $CustomOPAExecutablePath`n"
                $ErrorMsg += "  Expected executable: $OPAExecutableName`n"
                $ErrorMsg += "  Specified OPAPath: $CustomOPAPath"
                [void]$Validation.Errors.Add($ErrorMsg)
            }
        } else {
            # No custom path specified - use default path with fallback logic
            $DefaultOPAPath = $Defaults.defaults.OPAPath
            $ExpandedDefaultPath = $DefaultOPAPath -replace '~', $env:USERPROFILE
            $DefaultOPAExecutablePath = Join-Path -Path $ExpandedDefaultPath -ChildPath $OPAExecutableName

            # Check if allowOPAFallback is enabled
            $AllowFallback = if ($false -ne $Defaults.validation.allowOPAFallback) {
                $Defaults.validation.allowOPAFallback
            } else {
                $false  # Default to false - OPA is required
            }

            #$AllowFallback = $true

            # Check default location first
            $FoundInDefault = Test-Path -LiteralPath $DefaultOPAExecutablePath -PathType Leaf

            if (-not $FoundInDefault) {
                if ($AllowFallback) {
                    # Default location failed, check fallback
                    $FallbackOPAPath = "."
                    $ExpandedFallbackPath = (Get-Location).Path
                    $FallbackOPAExecutablePath = Join-Path -Path $FallbackOPAPath -ChildPath $OPAExecutableName

                    # Issue warning about checking fallback
                    $WarningMsg = "OPA executable not found: $DefaultOPAExecutablePath, checking fallback location: $ExpandedFallbackPath"
                    [void]$Validation.Warnings.Add($WarningMsg)

                    # Check fallback location
                    $FoundInFallback = Test-Path -LiteralPath $FallbackOPAExecutablePath -PathType Leaf

                    if (-not $FoundInFallback) {
                        # Fallback also failed - error
                        $ErrorMsg = "OPA executable not found in fallback locations:`n"
                        $ErrorMsg += "  Expected executable: $OPAExecutableName`n"
                        $ErrorMsg += "    - Default: $DefaultOPAPath`n"
                        $ErrorMsg += "    - Fallback: $ExpandedFallbackPath"
                        [void]$Validation.Errors.Add($ErrorMsg)
                    }
                } else {
                    # No fallback allowed - error immediately
                    $ErrorMsg = "OPA executable not found in default location: $DefaultOPAExecutablePath`n"
                    $ErrorMsg += "  Expected executable: $OPAExecutableName`n"
                    $ErrorMsg += "  Default location: $DefaultOPAPath"
                    [void]$Validation.Errors.Add($ErrorMsg)
                }
            }
            # If found in default location, validation passes (no error, no warning)
        }

        # Validate ProductNames duplicates
        if ($ConfigObject.ProductNames) {
            $UniqueProducts = $ConfigObject.ProductNames | Select-Object -Unique
            if ($UniqueProducts.Count -ne $ConfigObject.ProductNames.Count) {
                [void]$Validation.Warnings.Add("ProductNames contains duplicate values. Duplicates will be removed.")
            }
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

        # Note: Unknown properties are already validated by ValidatePropertyAgainstSchema()
        # This method focuses solely on validating product exclusion configurations

        foreach ($ProductProperty in $ProductCapabilities.PSObject.Properties) {
            $ProductName = $ProductProperty.Name
            $Capabilities = $ProductProperty.Value

            # Check if product is configured in the config object
            if ($ConfigObject.PSObject.Properties.Name -contains $ProductName) {
                $ProductConfig = $ConfigObject.$ProductName

                # If product doesn't support exclusions but has configuration
                if (-not $Capabilities.supportsExclusions -and $ProductConfig -and $ProductConfig.PSObject.Properties.Count -gt 0) {
                    [void]$Validation.Warnings.Add("Product '$ProductName' does not support exclusions. Configuration under '$ProductName' will be ignored.")
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

            # Check if property is defined in schema
            # Case sensitivity is controlled by schema property 'caseSensitive'
            $PropertyExists = $false
            $MatchedSchemaProperty = $null
            $CaseMismatch = $false

            # First pass: Try exact case match
            foreach ($SchemaPropertyName in $Schema.properties.PSObject.Properties.Name) {
                if ($SchemaPropertyName -ceq $PropertyName) {
                    $PropertyExists = $true
                    $MatchedSchemaProperty = $SchemaPropertyName
                    break
                }
            }

            # Second pass: Try case-insensitive match if exact match not found
            if (-not $PropertyExists) {
                foreach ($SchemaPropertyName in $Schema.properties.PSObject.Properties.Name) {
                    if ($SchemaPropertyName.ToLower() -eq $PropertyName.ToLower()) {
                        $PropertyExists = $true
                        $MatchedSchemaProperty = $SchemaPropertyName
                        $CaseMismatch = $true
                        break
                    }
                }
            }

            # If property found (exact or case-insensitive), validate it
            if ($PropertyExists) {
                $PropertySchema = $Schema.properties.$MatchedSchemaProperty

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

                # Check for case mismatch on case-sensitive properties
                if ($CaseMismatch) {
                    # Get the caseSensitive setting from schema (property-level)
                    $IsCaseSensitive = if ($null -ne $PropertySchema.caseSensitive) {
                        $PropertySchema.caseSensitive
                    } else {
                        $false  # Default to case-insensitive if not specified
                    }

                    if ($IsCaseSensitive) {
                        # This property requires exact case - check global setting for error vs warning
                        $Defaults = [ScubaConfigValidator]::GetDefaults()
                        $ErrorOnCaseMismatch = if ($null -ne $Defaults.validation.errorCaseSensitive) {
                            $Defaults.validation.errorCaseSensitive
                        } else {
                            $false  # Default to warning
                        }

                        $Message = "Property '$PropertyName' has incorrect case. Required case-sensitive name: '$MatchedSchemaProperty'."

                        if ($ErrorOnCaseMismatch) {
                            [void]$Validation.Errors.Add($Message)
                        } else {
                            [void]$Validation.Warnings.Add($Message)
                        }
                    }
                }
            }

            if (-not $PropertyExists) {
                # Property not in schema - treat as warning (ScubaGear can still run with extra properties)
                # Note: Root-level properties are case-insensitive in PowerShell, so typos may still work
                # This warning means the property truly doesn't match any known configuration option
                [void]$Validation.Warnings.Add("Unknown property '$PropertyName' is not defined in the schema. It will be ignored by ScubaGear.")
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
            [void]$Validation.Errors.Add("Property '$Context': Expected array, got $($Value.GetType().Name).")
            return
        }

        # Validate minItems
        if ($Schema.minItems -and $Value.Count -lt $Schema.minItems) {
            [void]$Validation.Errors.Add("Property '$Context': Array must have at least $($Schema.minItems) items, found $($Value.Count).")
        }

        # Validate uniqueItems
        if ($Schema.uniqueItems -and ($Value | Select-Object -Unique).Count -ne $Value.Count) {
            [void]$Validation.Errors.Add("Property '$Context': Array items must be unique.")
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
            [void]$Validation.Errors.Add("Property '$Context': Expected boolean, got $($Value.GetType().Name) with value '$Value'.")
        }
    }

    # Validates integer properties with optional enum
    static [void] ValidateIntegerProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        # Check if value is numeric
        $NumericValue = $null
        if (-not [int]::TryParse($Value, [ref]$NumericValue)) {
            [void]$Validation.Errors.Add("Property '$Context': Expected integer, got '$Value'.")
            return
        }

        # Validate enum constraint
        if ($Schema.enum -and $Schema.enum -notcontains $NumericValue) {
            [void]$Validation.Errors.Add("Property '$Context': Value '$NumericValue' is not in allowed values: $($Schema.enum -join ', ').")
        }
    }

    # Validates number properties
    static [void] ValidateNumberProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        $NumericValue = $null
        if (-not [double]::TryParse($Value, [ref]$NumericValue)) {
            [void]$Validation.Errors.Add("Property '$Context': Expected number, got '$Value'.")
        }
    }

    # Validates string properties with enum, pattern, length constraints
    static [void] ValidateStringProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        if ($Value -isnot [string]) {
            [void]$Validation.Errors.Add("Property '$Context': Expected string, got $($Value.GetType().Name).")
            return
        }

        # Validate minLength
        if ($Schema.minLength -and $Value.Length -lt $Schema.minLength) {
            [void]$Validation.Errors.Add("Property '$Context': String must be at least $($Schema.minLength) characters, found $($Value.Length).")
        }

        # Validate maxLength
        if ($Schema.maxLength -and $Value.Length -gt $Schema.maxLength) {
            [void]$Validation.Errors.Add("Property '$Context': String must be at most $($Schema.maxLength) characters, found $($Value.Length).")
        }

        # Validate enum
        if ($Schema.enum -and $Schema.enum -notcontains $Value) {
            [void]$Validation.Errors.Add("Property '$Context': Value '$Value' is not in allowed values: $($Schema.enum -join ', ').")
        }

        # Validate pattern
        if ($Schema.pattern -and $Value -notmatch $Schema.pattern) {
            $FriendlyName = [ScubaConfigValidator]::GetPatternFriendlyName($Schema.pattern)
            if ($FriendlyName) {
                [void]$Validation.Errors.Add("Property '$Context': Value '$Value' does not match required format: $FriendlyName.")
            }
            else {
                [void]$Validation.Errors.Add("Property '$Context': Value '$Value' does not match required pattern.")
            }
        }
    }

    # Validates object properties with additionalProperties support
    static [void] ValidateObjectProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        if ($Value -isnot [PSCustomObject] -and $Value -isnot [hashtable]) {
            [void]$Validation.Errors.Add("Property '$Context': Expected object, got $($Value.GetType().Name).")
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
                # Check for exact case match first
                $PropertyExists = $false
                $MatchedProp = $null
                $CaseMismatch = $false

                foreach ($AllowedProp in $AllowedProperties) {
                    if ($AllowedProp -ceq $PropName) {
                        $PropertyExists = $true
                        $MatchedProp = $AllowedProp
                        break
                    }
                }

                # Try case-insensitive match if exact match not found
                if (-not $PropertyExists) {
                    foreach ($AllowedProp in $AllowedProperties) {
                        if ($AllowedProp.ToLower() -eq $PropName.ToLower()) {
                            $PropertyExists = $true
                            $MatchedProp = $AllowedProp
                            $CaseMismatch = $true
                            break
                        }
                    }
                }

                if ($PropertyExists) {
                    # Validate the property value against its schema
                    $PropSchema = $Schema.properties.$MatchedProp
                    $PropValue = if ($Value -is [hashtable]) { $Value[$PropName] } else { $Value.$PropName }
                    [ScubaConfigValidator]::ValidatePropertyBySchema($PropValue, $PropSchema, $Validation, "$Context.$PropName", $PropName, $null, [ScubaConfigValidator]::GetSchema())

                    # Check case sensitivity from schema
                    if ($CaseMismatch) {
                        $IsCaseSensitive = if ($null -ne $PropSchema.caseSensitive) { $PropSchema.caseSensitive } else { $false }

                        if ($IsCaseSensitive) {
                            $Defaults = [ScubaConfigValidator]::GetDefaults()
                            $ErrorOnCaseMismatch = if ($null -ne $Defaults.validation.errorCaseSensitive) { $Defaults.validation.errorCaseSensitive } else { $false }

                            $Message = "Property '$Context.$PropName': Incorrect case. Required: '$MatchedProp'. Property names are case-sensitive for this property."

                            if ($ErrorOnCaseMismatch) {
                                [void]$Validation.Errors.Add($Message)
                            } else {
                                [void]$Validation.Warnings.Add($Message)
                            }
                        }
                    }
                } elseif ($Schema.additionalProperties -eq $false) {
                    # Property not found and additional properties not allowed
                    [void]$Validation.Errors.Add("Property '$Context': Invalid property '$PropName'. Valid properties: $($AllowedProperties -join ', ').")
                }
            }
        }
    }

    # Validates properties without explicit type (handles enum, pattern, etc.)
    static [void] ValidateGenericProperty([object]$Value, [object]$Schema, [hashtable]$Validation, [string]$Context) {
        # Check for enum constraint
        if ($Schema.enum) {
            if ($Schema.enum -notcontains $Value) {
                [void]$Validation.Errors.Add("Property '$Context': Value '$Value' is not in allowed values: $($Schema.enum -join ', ').")
            }
        }

        # Check for pattern constraint
        if ($Schema.pattern -and $Value -is [string]) {
            if ($Value -notmatch $Schema.pattern) {
                $FriendlyName = [ScubaConfigValidator]::GetPatternFriendlyName($Schema.pattern)
                if ($FriendlyName) {
                    [void]$Validation.Errors.Add("Property '$Context': Value '$Value' does not match required format: $FriendlyName.")
                }
                else {
                    [void]$Validation.Errors.Add("Property '$Context': Value '$Value' does not match required pattern.")
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
                [void]$Validation.Errors.Add("Property '$Context': Value '$Item' is not in allowed values: $($ItemSchema.enum -join ', ').")
            }
        }
        elseif ($ItemSchema.pattern) {
            if ($Item -notmatch $ItemSchema.pattern) {
                $FriendlyName = [ScubaConfigValidator]::GetPatternFriendlyName($ItemSchema.pattern)
                if ($FriendlyName) {
                    [void]$Validation.Errors.Add("Property '$Context': Value '$Item' does not match required format: $FriendlyName.")
                }
                else {
                    [void]$Validation.Errors.Add("Property '$Context': Value '$Item' does not match required pattern.")
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

                    # Validate policy ID format and product name match
                    # Get effective ProductNames (from config or defaults)
                    $ProductNamesForValidation = if ($ConfigObject.PSObject.Properties.Name -contains 'ProductNames') {
                        $ConfigObject.ProductNames
                    } else {
                        $Defaults = [ScubaConfigValidator]::GetDefaults()
                        $Defaults.defaults.ProductNames
                    }

                    $PolicyValidation = [ScubaConfigValidator]::ValidatePolicyId($PolicyId, $ProductNamesForValidation)
                    $Defaults = [ScubaConfigValidator]::GetDefaults()
                    $RequireProduct = $Defaults.validation.requireProductInPolicy

                    if (-not $PolicyValidation.IsValid) {
                        if ($RequireProduct) {
                            [void]$Validation.Errors.Add("$ProductName exclusion error: $($PolicyValidation.Error)")
                        } else {
                            [void]$Validation.Warnings.Add("$ProductName exclusion warning: $($PolicyValidation.Error)")
                        }
                    } elseif ($PolicyValidation.Warning) {
                        [void]$Validation.Warnings.Add("$ProductName exclusion warning: $($PolicyValidation.Warning)")
                    }

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
                    if ($AllowedTypes.Count -gt 0 -and $ExclusionTypes.Count -gt 0) {
                        foreach ($ExclusionType in $ExclusionTypes) {
                            if ($ExclusionType -notin $AllowedTypes) {
                                $Message = "'$ExclusionType' is not valid for this policy. Policy ID '$PolicyId' supports exclusion types: $($AllowedTypes -join ', ')."
                                if ($RequireProduct) {
                                    [void]$Validation.Errors.Add("$ProductName exclusion error: $Message")
                                } else {
                                    [void]$Validation.Warnings.Add("$ProductName exclusion warning: $Message")
                                }
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
            Warning = ""
        }

        $Defaults = [ScubaConfigValidator]::GetDefaults()
        $PolicyPattern = $Defaults.validation.policyIdPattern

        if ($PolicyId -notmatch $PolicyPattern) {
            $PolicyParts = $PolicyId -split "\."
            $ProductInPolicy = if ($PolicyParts.Length -ge 2 -and $PolicyParts[1]) { $PolicyParts[1] } else { $null }
            $ExampleFormat = [ScubaConfigValidator]::ConvertPatternToExample($PolicyPattern, $ProductInPolicy)
            $Message = "Policy ID: '$PolicyId' does not match expected format. Expected format: $ExampleFormat"

            if ($Defaults.validation.requireProductInPolicy) {
                $Result.Error = $Message
            } else {
                $Result.Warning = $Message
                $Result.IsValid = $true  # Allow it to continue with warning
            }
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

            if ($ProductInPolicy -notin $EffectiveProducts) {
                $Message = "Policy ID: '$PolicyId' references product '$ProductInPolicy' which is not in ProductNames: $($EffectiveProducts -join ', ')"

                if ($Defaults.validation.requireProductInPolicy) {
                    $Result.Error = $Message
                    return $Result
                } else {
                    $Result.Warning = $Message
                    $Result.IsValid = $true  # Allow it to continue with warning
                }
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
                            $RequireProduct = $Defaults.validation.requireProductInPolicy
                            $PolicyValidation = [ScubaConfigValidator]::ValidatePolicyId($Key, $ProductNames)

                            if (-not $PolicyValidation.IsValid) {
                                try {
                                    if ($RequireProduct) {
                                        Write-Debug "Adding error to Validation.Errors. Type: $($Validation.Errors.GetType().FullName)"
                                        [void]$Validation.Errors.Add($PolicyValidation.Error)
                                    } else {
                                        Write-Debug "Adding warning to Validation.Warnings"
                                        [void]$Validation.Warnings.Add($PolicyValidation.Error)
                                    }
                                } catch {
                                    Write-Debug "ERROR adding to Validation collection: $_"
                                    Write-Debug "Validation type: $($Validation.GetType().FullName)"
                                    Write-Debug "Validation.Errors type: $($Validation.Errors.GetType().FullName)"
                                    throw
                                }
                            } elseif ($PolicyValidation.Warning) {
                                try {
                                    Write-Debug "Adding warning to Validation.Warnings"
                                    [void]$Validation.Warnings.Add($PolicyValidation.Warning)
                                } catch {
                                    Write-Debug "ERROR adding to Validation.Warnings: $_"
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
                                    # Check exact case match
                                    $PropExists = $ItemProp -cin $AllowedProps

                                    if (-not $PropExists) {
                                        # Check case-insensitive
                                        $CaseInsensitiveMatch = $null
                                        foreach ($AllowedProp in $AllowedProps) {
                                            if ($AllowedProp.ToLower() -eq $ItemProp.ToLower()) {
                                                $CaseInsensitiveMatch = $AllowedProp
                                                break
                                            }
                                        }

                                        if ($CaseInsensitiveMatch) {
                                            # Found case-insensitive match - check if property is case-sensitive
                                            $PropSchema = $Option.properties.$CaseInsensitiveMatch
                                            $IsCaseSensitive = if ($null -ne $PropSchema.caseSensitive) { $PropSchema.caseSensitive } else { $false }

                                            if ($IsCaseSensitive) {
                                                # Case matters for this property
                                                $Defaults = [ScubaConfigValidator]::GetDefaults()
                                                $ErrorOnCaseMismatch = if ($null -ne $Defaults.validation.errorCaseSensitive) { $Defaults.validation.errorCaseSensitive } else { $false }

                                                $Message = "${Context}: Property '$ItemProp' has incorrect case. Required: '$CaseInsensitiveMatch'. This property is case-sensitive."

                                                if ($ErrorOnCaseMismatch) {
                                                    [void]$TempValidation.Errors.Add($Message)
                                                } else {
                                                    # Warning - but still validate the value
                                                    # Note: This is added to temp validation, not main validation
                                                }
                                            }
                                            # If not case-sensitive, we accept the case-insensitive match
                                        } else {
                                            # Property doesn't exist at all
                                            [void]$TempValidation.Errors.Add("${Context}: Invalid property '$ItemProp'. Valid properties: $($AllowedProps -join ', ')")
                                        }
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
    # Returns PSCustomObject with CategorizedErrors array and ActionMessageRefs array
    # Categorizes messages (errors or warnings) using patterns from configuration
    # Returns categorized messages and action message refs for recommended actions
    hidden static [PSCustomObject] CategorizeMessages([array]$Messages, [string]$CategoryType = 'error') {
        $Defaults = [ScubaConfigValidator]::GetDefaults()

        # Determine which categories to use (errorCategories or warningCategories)
        $CategoryKey = if ($CategoryType -eq 'warning') { 'warningCategories' } else { 'errorCategories' }

        # Fall back to errorCategories if warningCategories doesn't exist
        $CategoriesConfig = if ($Defaults.outputSettings.$CategoryKey) {
            $Defaults.outputSettings.$CategoryKey
        } elseif ($Defaults.outputSettings.errorCategories) {
            $Defaults.outputSettings.errorCategories
        } else {
            $null
        }

        if (-not $Defaults.outputSettings -or -not $CategoriesConfig) {
            return [PSCustomObject]@{
                CategorizedMessages = $Messages
                ActionMessageRefs = @('default')
            }
        }

        $Categories = @{}
        $ActionMessageRefs = [System.Collections.Generic.HashSet[string]]::new()

        # Initialize categories from array order
        foreach ($CategoryDef in $CategoriesConfig) {
            $Categories[$CategoryDef.name] = @()
        }

        # Categorize each message (remove duplicates using trimmed comparison)
        $SeenMessages = @{}
        foreach ($Message in $Messages) {
            # Normalize the message by trimming whitespace for comparison
            $NormalizedMessage = $Message.Trim()

            # Skip if we've already seen this exact message
            if ($SeenMessages.ContainsKey($NormalizedMessage)) {
                continue
            }
            $SeenMessages[$NormalizedMessage] = $true

            $Categorized = $false

            foreach ($CategoryDef in $CategoriesConfig) {
                # Empty pattern means catch-all (typically "Other errors/warnings")
                if ([string]::IsNullOrEmpty($CategoryDef.pattern)) {
                    # This is the catch-all category, skip pattern matching
                    continue
                }

                if ($Message -match $CategoryDef.pattern) {
                    $Categories[$CategoryDef.name] += $Message
                    # Track which action message ref is needed
                    if ($CategoryDef.actionMessageRef) {
                        [void]$ActionMessageRefs.Add($CategoryDef.actionMessageRef)
                    }
                    $Categorized = $true
                    break
                }
            }

            # If not categorized, add to the last category (catch-all with empty pattern)
            if (-not $Categorized) {
                $LastCategory = $CategoriesConfig[-1]
                $Categories[$LastCategory.name] += $Message
                # Track catch-all action message ref
                if ($LastCategory.actionMessageRef) {
                    [void]$ActionMessageRefs.Add($LastCategory.actionMessageRef)
                }
            }
        }

        # Build output using array order
        $Output = @()

        foreach ($CategoryDef in $CategoriesConfig) {
            if ($Categories[$CategoryDef.name].Count -gt 0) {
                $Output += "`n--- $($CategoryDef.name) ---"
                $Output += $Categories[$CategoryDef.name]
            }
        }

        return [PSCustomObject]@{
            CategorizedMessages = $Output
            ActionMessageRefs = @($ActionMessageRefs)
        }
    }

    # Legacy wrapper for backward compatibility
    hidden static [PSCustomObject] CategorizeErrors([array]$Errors) {
        $Result = [ScubaConfigValidator]::CategorizeMessages($Errors, 'error')
        return [PSCustomObject]@{
            CategorizedErrors = $Result.CategorizedMessages
            ActionMessageRefs = $Result.ActionMessageRefs
        }
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

