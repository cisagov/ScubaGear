using module '.\ScubaConfigValidator.psm1'

class ScubaConfig {
    <#
    .SYNOPSIS
    ScubaConfig is a class that provides validation to ScubaGear YAML/JSON configuration files

    .DESCRIPTION
    ScubaConfig implements a singleton configuration management class that manages configuration state throughout the PowerShell session. It integrates tightly with
    ScubaConfigValidator to provide validation using JSON Schema and default rules.

    .EXAMPLE
    # Basic usage - Get singleton instance and load configuration
    using module '.\ScubaConfig.psm1'
    $Config = [ScubaConfig]::GetInstance()
    $Success = $Config.LoadConfig("C:\MyConfig\scuba-config.yaml")
    if ($Success) {
        $ConfigObject = $Config.Configuration
        # Inspect the loaded configuration
        $ConfigObject
    }

    .EXAMPLE
    # Access default values and configuration schema
    $DefaultOPAPath = [ScubaConfig]::ScubaDefault('DefaultOPAPath')
    $AllProducts = [ScubaConfig]::ScubaDefault('AllProductNames')
    $SupportedEnvironments = [ScubaConfig]::GetSupportedEnvironments()
    #>

    # Static properties for singleton instance and cached resources
    # Singleton pattern ensures only one configuration instance exists per PowerShell session
    hidden static [ScubaConfig]$_Instance = [ScubaConfig]::new()
    # Track whether a configuration file has been successfully loaded
    hidden static [Boolean]$_IsLoaded = $false
    # Track whether the validator subsystem has been initialized
    hidden static [Boolean]$_ValidatorInitialized = $false
    # Cached configuration defaults loaded from JSON file
    hidden static [object]$_ConfigDefaults = $null
    # Cached JSON schema used for validation
    hidden static [object]$_ConfigSchema = $null

    # Initializes validator subsystem once per session - loads schema/defaults from JSON files,
    # caches resources in static properties for performance.
    # This is called automatically when needed and uses lazy loading pattern
    static [void] InitializeValidator() {
        # Only initialize if not already done (singleton initialization)
        if (-not [ScubaConfig]::_ValidatorInitialized) {
            # Get the directory containing this module file
            $ModulePath = Split-Path -Parent $PSCommandPath
            # Initialize the validator with the module path
            [ScubaConfigValidator]::Initialize($ModulePath)
            # Cache the loaded defaults and schema for fast access
            [ScubaConfig]::_ConfigDefaults = [ScubaConfigValidator]::GetDefaults()
            [ScubaConfig]::_ConfigSchema = [ScubaConfigValidator]::GetSchema()
            # Mark as initialized to prevent duplicate initialization
            [ScubaConfig]::_ValidatorInitialized = $true
        }
    }

    # Resolves configuration defaults using naming conventions. "Default" prefix maps to defaults section.
    # Special processing: DefaultOPAPath expands ~, DefaultOutPath resolves ., wildcard handling for products.
    # This method provides a unified interface for accessing default values with automatic path resolution
    static [object]ScubaDefault ([string]$Name){
        # Ensure validator is initialized before accessing cached defaults
        [ScubaConfig]::InitializeValidator()

        # Dynamically resolve configuration values based on naming conventions
        # This eliminates the need to maintain static mappings in multiple places
        # and makes the system more maintainable

        # Handle special cases that require path processing or expansion
        if ($Name -eq 'DefaultOPAPath') {
            # Get the raw path from defaults configuration
            $Path = [ScubaConfig]::_ConfigDefaults.defaults.OPAPath
            # Expand tilde (~) to user's home directory if present
            if ($Path -eq "~/.scubagear/Tools") {
                try {
                    # Convert Unix-style path to Windows path in user's profile
                    $ExpandedPath = Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"
                    # Check if expanded path exists, fallback to current directory if not
                    if (Test-Path -LiteralPath $ExpandedPath) {
                        return $ExpandedPath
                    } else {
                        # Fallback to current directory (legacy behavior when OPA not installed)
                        return "."
                    }
                } catch {
                    # Fallback to current directory if home directory expansion fails
                    return "."
                }
            }
            return $Path
        }
        elseif ($Name -eq 'DefaultOutPath') {
            $Path = [ScubaConfig]::_ConfigDefaults.defaults.OutPath
            if ($Path -eq ".") {
                return Get-Location | Select-Object -ExpandProperty ProviderPath
            }
            return $Path
        }
        elseif ($Name -eq 'AllProductNames') {
            return [ScubaConfig]::_ConfigDefaults.defaults.AllProductNames
        }
        elseif ($Name -eq 'DefaultPrivilegedRoles') {
            return [ScubaConfig]::_ConfigDefaults.privilegedRoles
        }
        elseif ($Name.StartsWith('Default')) {
            # For standard "Default" prefixed names, auto-resolve from defaults section
            $ConfigKey = $Name.Substring(7) # Remove 'Default' prefix

            # Check if the property exists in defaults
            if ([ScubaConfig]::_ConfigDefaults.defaults.PSObject.Properties.Name -contains $ConfigKey) {
                return [ScubaConfig]::_ConfigDefaults.defaults.$ConfigKey
            }
            else {
                throw "Unknown default configuration key: $Name. Property '$ConfigKey' not found in defaults section."
            }
        }
        else {
            # If no mapping found, throw error
            throw "Unknown default configuration key: $Name. Available keys: $((Get-Member -InputObject [ScubaConfig]::_ConfigDefaults -MemberType NoteProperty).Name -join ', ')"
        }
    }

    # Returns default OPA version from configuration. Wrapper around ScubaDefault('DefaultOPAVersion').
    static [string]GetOpaVersion() {
        return [ScubaConfig]::ScubaDefault('DefaultOPAVersion')
    }

    static [array]GetCompatibleOpaVersions() {
        [ScubaConfig]::InitializeValidator()

        return [ScubaConfig]::_ConfigDefaults.metadata.compatibleOpaVersions
    }

    static [string] GetOpaExecutable([string]$OperatingSystem) {
        [ScubaConfig]::InitializeValidator()

        if ([string]::IsNullOrWhiteSpace($OperatingSystem)) {
            throw "OperatingSystem parameter cannot be null or whitespace."
        }

        $OPAExecutables = [ScubaConfig]::_ConfigDefaults.defaults.OPAExecutable

        if ($null -eq $OPAExecutables) {
            throw "OPAExecutable default configuration does not exist."
        }

        $validKeys = @($OPAExecutables.PSObject.Properties.Name)
        $requestedKey = $OperatingSystem.Trim().ToLower()
        $matchedKey = $validKeys | Where-Object { $_.ToLower() -eq $requestedKey } | Select-Object -First 1

        if (-not $matchedKey) {
            throw "No OPA executable found for operating system: $OperatingSystem"
        }

        return $OPAExecutables.$matchedKey
    }

    # Loads configuration file with full validation enabled (delegates to main LoadConfig with SkipValidation=false).
    [Boolean]LoadConfig([System.IO.FileInfo]$Path){
        return $this.LoadConfig($Path, $false)
    }

    # Primary config loading method. Resets singleton, validates file format, parses content, applies defaults.
    # SkipValidation=true allows deferred validation after command-line overrides are applied.
    # This method implements a two-phase validation approach for flexibility:
    # Phase 1: Always validate file format (extension, size, YAML syntax)
    # Phase 2: Optionally validate content (schema, Scuba configuration rules) based on SkipValidation parameter
    [Boolean]LoadConfig([System.IO.FileInfo]$Path, [Boolean]$SkipValidation){
        # First, verify the file exists before attempting to load it
        # This provides a clear error message rather than letting file operations fail later
        if (-Not (Test-Path -PathType Leaf $Path)){
            throw [System.IO.FileNotFoundException]"Failed to load: $Path"
        }

        # Reset the singleton to ensure clean state before loading new configuration
        # This prevents contamination from previously loaded configurations in the same session
        [ScubaConfig]::ResetInstance()
        # Ensure the validator subsystem is ready
        [ScubaConfig]::InitializeValidator()

        # Phase 1: Always validate basic file format (extension, size, YAML syntax)
        # This catches fundamental issues early before processing
        Write-Debug "Loading configuration file: $Path"

        # Use the default debug mode from configuration instead of hardcoding false
        # This allows the debug behavior to be controlled via configuration files
        $Defaults = [ScubaConfig]::_ConfigDefaults
        $DefaultDebugMode = if ($Defaults.outputSettings -and $Defaults.outputSettings.debugMode) {
            $Defaults.outputSettings.debugMode
        } else {
            $false
        }
        Write-Debug "Using debug mode: $DefaultDebugMode (from configuration default)"

        # Perform initial validation with Scuba configuration rules skipped (SkipScubaConfigRules=true)
        # This validates file format, extension, size, and YAML parsing but defers content validation
        # Schema and content validation happen later in ValidateConfiguration()
        $ValidationResult = [ScubaConfigValidator]::ValidateYamlFile($Path.FullName, $DefaultDebugMode, $true)

        # Check for file format errors (extension, size, YAML parsing)
        # These are fundamental issues that prevent any further processing
        if (-not $ValidationResult.IsValid) {
            # Build error message with simple bullet list (no categorization for format errors)
            $Plural = if ($ValidationResult.ValidationErrors.Count -ne 1) { 's' } else { '' }
            $ErrorMessage = "Configuration file format validation failed ($($ValidationResult.ValidationErrors.Count) error$Plural):`n"
            foreach ($ErrorMsg in $ValidationResult.ValidationErrors) {
                $ErrorMessage += "  - $ErrorMsg`n"
            }
            throw $ErrorMessage
        }

        # Display warnings if any (file size approaching limits, deprecated formats, etc.)
        # Warnings don't prevent loading but provide important user guidance
        if ($ValidationResult.Warnings.Count -gt 0) {
            foreach ($Warning in $ValidationResult.Warnings) {
                Write-Warning $Warning
            }
        }

        # Use the already parsed content from validation to avoid re-parsing
        # The validator has already converted YAML to PowerShell objects safely
        $this.Configuration = $ValidationResult.ParsedContent

        # IMPORTANT: Validate required fields BEFORE converting to hashtable
        # PSCustomObject preserves case-sensitive property names, hashtable doesn't
        # This ensures minRequired check validates exact property names from YAML
        if (-not $SkipValidation) {
            [ScubaConfig]::ValidateRequiredFields($this.Configuration)
        }

        # Convert to hashtable for compatibility with internal configuration management
        # PSCustomObjects from YAML parsing need to be converted to hashtables for consistent access patterns
        # Note: Hashtables are case-insensitive, which is why we validate BEFORE conversion
        if ($this.Configuration -is [PSCustomObject]) {
            $this.Configuration = [ScubaConfig]::ConvertPSObjectToHashtable($this.Configuration)
        }

        # Apply default values and process special configuration properties
        # This ensures all required properties have values for subsequent processing
        # Handles wildcards, path expansion (including OPAPath fallback to current directory)
        $this.SetParameterDefaults()

        # Perform full content validation AFTER applying defaults
        # This validates the complete configuration with all applied
        # Includes OPA executable existence check which needs the expanded/fallback OPAPath
        if (-not $SkipValidation) {
            # Validate the complete configuration including schema, Scuba configuration rules, and policy references
            $this.ValidateConfiguration()
        }

        # Mark configuration as successfully loaded
        [ScubaConfig]::_IsLoaded = $true

        return [ScubaConfig]::_IsLoaded
    }

    # Validates that required fields are present in configuration BEFORE defaults are applied
    # This prevents minRequired validation from being bypassed by default values
    # Issues warning if any required field is missing (schema-driven from defaults.json minRequired)
    # Takes PSCustomObject to preserve case-sensitive property names (hashtable is case-insensitive)
    static [void] ValidateRequiredFields([PSCustomObject]$ConfigObject) {
        [ScubaConfig]::InitializeValidator()

        $Defaults = [ScubaConfig]::_ConfigDefaults

        if (-not $Defaults.minRequired) {
            return
        }

        $MissingFields = @()
        foreach ($RequiredField in $Defaults.minRequired) {
            # Check if property exists (case-sensitive for exact match)
            # PSCustomObject preserves exact case from YAML, unlike hashtable which is case-insensitive
            $PropertyNames = @($ConfigObject.PSObject.Properties.Name)

            if ($RequiredField -cnotin $PropertyNames) {
                # Also check case-insensitive to provide helpful case mismatch warnings
                $FoundCaseInsensitive = $false
                foreach ($PropName in $PropertyNames) {
                    if ($PropName.ToLower() -eq $RequiredField.ToLower()) {
                        $FoundCaseInsensitive = $true
                        Write-Warning "Required property '$RequiredField' found with incorrect case: '$PropName'. Recommended using exact case: '$RequiredField'."
                        # Case-insensitive match found - don't add to missing fields
                        break
                    }
                }

                if (-not $FoundCaseInsensitive) {
                    $MissingFields += $RequiredField
                }
            }
        }

        if ($MissingFields.Count -gt 0) {
            $Plural = if ($MissingFields.Count -ne 1) { 's' } else { '' }
            $WarningMessage = "Configuration validation warning ($($MissingFields.Count) warning$Plural):`n"
            foreach ($Field in $MissingFields) {
                $WarningMessage += "  - Required property '$Field' is missing.`n"
            }
            $WarningMessage += "`n--- RECOMMENDED ACTION ---`n"
            $WarningMessage += "  - It is recommended to use the new ScubaGear Configuration Editor to build a configuration file.`n"
            $WarningMessage += "  - Run: 'Start-ScubaConfigApp' to launch the configuration application.`n"
            Write-Warning $WarningMessage
        }
    }

    # Validates current configuration state after overrides. Performs schema + Scuba configuration rules + policy validation.
    # Used for deferred validation pattern where config is loaded with SkipValidation=true then validated after overrides.
    # This allows command-line parameters to override config file values before final validation.
    # The method implements a comprehensive validation strategy with multiple phases and detailed error reporting.
    [void]ValidateConfiguration(){

        Write-Debug "Validating final configuration state"

        # Convert internal hashtable representation back to PSCustomObject for validator compatibility
        # The validator expects PSCustomObject format for consistent property access across different PowerShell object types
        # This conversion is necessary because the internal configuration uses hashtables for performance
        $ConfigObject = [PSCustomObject]$this.Configuration

        # Phase 1: Perform JSON Schema validation (structure, types, constraints)
        # This validates against the formal schema definition including data types, patterns, and structural requirements
        # Schema validation catches fundamental issues like wrong data types, missing required fields, invalid formats
        $SchemaValidation = [ScubaConfigValidator]::ValidateAgainstSchema($ConfigObject, $false)

        # Phase 2: Perform Scuba configuration rule validation (paths, content quality, cross-field validation)
        # This layer adds domain-specific validation beyond what JSON Schema can express
        # Scuba configuration rules include file path existence, cross-field dependencies, and ScubaGear-specific requirements
        $ScubaConfigValidation = [ScubaConfigValidator]::ValidateScubaConfigRules($ConfigObject, $false)

        # Collect all warnings from initial validation phases
        # We'll display them later after collecting policy validation warnings too
        $AllWarnings = @()
        # Include pre-validation warnings (e.g., wildcard with other products)
        if ($this.Configuration.ContainsKey('_PreValidationWarnings')) {
            $AllWarnings += $this.Configuration._PreValidationWarnings
        }
        $AllWarnings += $SchemaValidation.Warnings
        $AllWarnings += $ScubaConfigValidation.Warnings

        # Collect all errors from both validation phases (remove duplicates)
        # This provides a comprehensive view of all configuration issues in a single validation run
        $AllErrors = @()
        $AllErrors += $SchemaValidation.Errors
        $AllErrors += $ScubaConfigValidation.Errors
        $AllErrors = $AllErrors | Select-Object -Unique

        # Validate policy-type properties (dynamically discovered from schema)
        # This validates any property that contains policy IDs (like OmitPolicy, AnnotatePolicy)
        # added to the schema will be automatically validated here
        $Schema = [ScubaConfig]::_ConfigSchema
        if ($Schema.properties) {
            foreach ($PropertyName in $Schema.properties.PSObject.Properties.Name) {
                $PropertySchema = $Schema.properties.$PropertyName

                # Check if this is a policy-type property (has patternProperties with policy ID pattern and oneOf)
                if ([ScubaConfigValidator]::IsPolicyTypeProperty($PropertyName, $PropertySchema)) {
                    # Check if this property exists in the configuration
                    if ($this.Configuration.ContainsKey($PropertyName)) {
                        Write-Debug "Validating policy-type property: $PropertyName"

                        # Validate using the generic policy configuration validator
                        $PolicyValidation = [ScubaConfig]::ValidatePolicyConfiguration(
                            $this.Configuration[$PropertyName],
                            $PropertyName,
                            $this.Configuration.ProductNames
                        )

                        $AllWarnings += $PolicyValidation.Warnings
                        $AllErrors += $PolicyValidation.Errors
                    }
                }
            }
        }

        # Remove duplicate warnings (policy validation may overlap with other validations)
        $AllWarnings = $AllWarnings | Select-Object -Unique

        # Display all warnings if any were collected (with categorization and recommended actions)
        if ($AllWarnings.Count -gt 0) {
            $WarningPlural = if ($AllWarnings.Count -ne 1) { 's' } else { '' }
            $WarningMessage = "Configuration validation found $($AllWarnings.Count) warning$WarningPlural`:`n"

            # Categorize warnings using the CategorizeMessages method
            $CategorizedResult = [ScubaConfigValidator]::CategorizeMessages($AllWarnings, 'warning')

            foreach ($Warning in $CategorizedResult.CategorizedMessages) {
                $WarningMessage += "  $Warning`n"
            }

            # Display recommended actions for warnings
            if ($CategorizedResult.ActionMessageRefs.Count -gt 0) {
                $Defaults = [ScubaConfigValidator]::GetDefaults()
                if ($Defaults.outputSettings -and $Defaults.outputSettings.recommendedActionMessages) {
                    $WarningMessage += "`n--- RECOMMENDED ACTION ---`n"
                    foreach ($ActionRef in $CategorizedResult.ActionMessageRefs) {
                        if ($Defaults.outputSettings.recommendedActionMessages.$ActionRef) {
                            $WarningMessage += "  - $($Defaults.outputSettings.recommendedActionMessages.$ActionRef)`n"
                            $WarningMessage += "`n" # Add extra newline between different action message groups for readability
                        }
                    }
                }
            }

            Write-Warning $WarningMessage
        }

        # Remove duplicate errors
        $AllErrors = $AllErrors | Select-Object -Unique

        # If any validation errors were found, throw a comprehensive error message
        # This prevents execution with invalid configuration and provides clear guidance for remediation
        if ($AllErrors.Count -gt 0) {
            # Categorize errors for better organization and get recommended action message refs
            $CategorizationResult = [ScubaConfigValidator]::CategorizeErrors($AllErrors)

            # Build complete error message with categorized errors
            $Plural = if ($AllErrors.Count -ne 1) { 's' } else { '' }
            $ErrorMessage = "Configuration validation failed ($($AllErrors.Count) error$Plural):`n"
            foreach ($ErrorLine in $CategorizationResult.CategorizedErrors) {
                $ErrorMessage += "$ErrorLine`n"
            }

            # Add recommended action messages based on actionMessageRefs from error categorization
            if ($CategorizationResult.ActionMessageRefs.Count -gt 0) {
                $ErrorMessage += "`n--- RECOMMENDED ACTION ---`n"

                # Track if we've added any messages to control spacing
                $MessagesAdded = $false

                # Sort actionMessageRefs to ensure "default" is always last
                $SortedRefs = $CategorizationResult.ActionMessageRefs | Sort-Object -Property @{
                    Expression = { if ($_ -eq 'default') { 1 } else { 0 } }
                }

                # Add recommended action messages in sorted order (unique refs, default last)
                foreach ($Ref in $SortedRefs) {
                    if ([ScubaConfig]::_ConfigDefaults.outputSettings.recommendedActionMessages.$Ref) {
                        # Add blank line between different message groups
                        if ($MessagesAdded) {
                            $ErrorMessage += "`n"
                        }

                        foreach ($Line in [ScubaConfig]::_ConfigDefaults.outputSettings.recommendedActionMessages.$Ref) {
                            $ErrorMessage += "$Line`n"
                        }
                        $MessagesAdded = $true
                    }
                }
            }

            throw $ErrorMessage
        }
    }

    # Clears configuration data from singleton instance. Used by ResetInstance() for clean state.
    hidden [void]ClearConfiguration(){
        $this.Configuration = $null
    }

    # Recursively converts PSCustomObject to hashtable for internal storage compatibility.
    # YAML parsing creates PSCustomObjects, but internal config uses hashtables for performance.
    # This conversion is necessary because:
    # 1. Hashtables provide faster property access than PSCustomObjects
    # 2. Hashtables have more predictable behavior with dynamic property names
    # 3. Legacy ScubaGear code expects hashtable interface for configuration access
    # 4. Hashtables work better with PowerShell's automatic variable expansion
    hidden static [hashtable] ConvertPSObjectToHashtable([PSCustomObject]$Object) {
        $Hashtable = @{}
        # Process each property from the PSCustomObject
        foreach ($Property in $Object.PSObject.Properties) {
            # Recursively convert nested PSCustomObjects to nested hashtables
            # This handles complex configuration structures like exclusion policies
            if ($Property.Value -is [PSCustomObject]) {
                $Hashtable[$Property.Name] = [ScubaConfig]::ConvertPSObjectToHashtable($Property.Value)
            }
            # Handle arrays that might contain PSCustomObjects (like ProductNames with complex structures)
            # Arrays in YAML can contain both simple values and complex objects
            elseif ($Property.Value -is [Array] -or $Property.Value -is [System.Collections.IList]) {
                $Array = @()
                foreach ($Item in $Property.Value) {
                    # Convert any PSCustomObjects within the array to hashtables
                    if ($Item -is [PSCustomObject]) {
                        $Array += [ScubaConfig]::ConvertPSObjectToHashtable($Item)
                    }
                    else {
                        # Keep primitive types (strings, numbers, booleans) as-is
                        $Array += $Item
                    }
                }
                $Hashtable[$Property.Name] = $Array
            }
            else {
                # For primitive types (string, int, bool), copy directly
                # No conversion needed for these basic data types
                $Hashtable[$Property.Name] = $Property.Value
            }
        }
        return $Hashtable
    }

    # Validates policy configuration entries for format compliance, product alignment, and schema compliance.
    # This method ensures that OmitPolicy and AnnotatePolicy sections contain valid policy IDs,
    # reference products selected for scanning, and have properly formatted values per the schema.
    # Policy IDs must follow the format: MS.{PRODUCT}.{GROUP}.{NUMBER}v{VERSION}
    # Returns a PSCustomObject with Errors and Warnings arrays
    hidden static [PSCustomObject] ValidatePolicyConfiguration([object]$PolicyConfig, [string]$ActionType, [array]$ProductNames) {
        [ScubaConfig]::InitializeValidator()
        $Defaults = [ScubaConfig]::_ConfigDefaults
        $Schema = [ScubaConfig]::_ConfigSchema
        $RequireProduct = $Defaults.validation.requireProductInPolicy

        $Result = [PSCustomObject]@{
            Errors = @()
            Warnings = @()
        }

        # Get the schema definition for this action type (OmitPolicy or AnnotatePolicy)
        $PropertySchema = $null
        if ($Schema.properties -and $Schema.properties.$ActionType) {
            $PropertySchema = $Schema.properties.$ActionType
        }

        # Process each policy ID in the configuration section (OmitPolicy or AnnotatePolicy)
        foreach ($Policy in $PolicyConfig.Keys) {
            # Validate policy ID format against the regex pattern from configuration
            # Pattern ensures proper format: MS.{PRODUCT}.{GROUP}.{NUMBER}v{VERSION}
            # Example valid IDs: MS.AAD.1.1v1, MS.DEFENDER.2.3v2, MS.EXO.1.4v1
            if (-not ($Policy -match $Defaults.validation.policyIdPattern)) {
                # Try to extract product from malformed policy ID to provide helpful error message
                # Split on periods to get potential product name for better error guidance
                $PolicyParts = $Policy -split "\."
                $ProductInPolicy = if ($PolicyParts.Length -ge 2 -and $PolicyParts[1]) { $PolicyParts[1] } else { $null }

                # Generate user-friendly format example using the validator's helper method
                # This provides context-specific guidance (e.g., "MS.AAD.#.#v#" if product detected)
                $ExampleFormat = [ScubaConfigValidator]::ConvertPatternToExample($Defaults.validation.policyIdPattern, $ProductInPolicy)

                # Build contextual error message based on the action type
                $Message = "${ActionType}: '$Policy' is not a valid policy ID. Expected format: $ExampleFormat."

                if ($RequireProduct) {
                    $Result.Errors += $Message
                } else {
                    $Result.Warnings += $Message
                }
                continue
            }

            # Extract the product name from the policy ID (second component after splitting on periods)
            # Policy ID format: MS.{PRODUCT}.{GROUP}.{NUMBER}v{VERSION}
            # Convert to lowercase for case-insensitive comparison with ProductNames
            $Product = ($Policy -Split "\.")[1].ToLower()

            # Determine which products are effectively selected for scanning
            # Handle wildcard case where all products are selected
            $EffectiveProducts = $ProductNames
            if ($ProductNames -contains '*') {
                # Expand wildcard to all available products from configuration
                $EffectiveProducts = $Defaults.defaults.AllProductNames
            }

            # Verify that the referenced product is actually going to be scanned
            # Prevents configuration errors where policies are specified for products not being tested
            if (-not ($EffectiveProducts -Contains $Product)) {
                # Build message with proper action prefix and clear explanation
                $Message = "${ActionType}: '$Policy' references product '$Product' which is not in the selected ProductNames: $(($EffectiveProducts -join ', ').ToUpper())."

                if ($RequireProduct) {
                    $Result.Errors += $Message
                } else {
                    $Result.Warnings += $Message
                }
            }

            # Validate the policy value against the schema (Rationale/Expiration or Comment/RemediationDate/IncorrectResult)
            if ($PropertySchema -and $PropertySchema.patternProperties) {
                $PolicyValue = $PolicyConfig[$Policy]

                # Find the matching pattern schema for this policy ID
                $MatchedPatternSchema = $null
                foreach ($Pattern in $PropertySchema.patternProperties.PSObject.Properties.Name) {
                    if ($Policy -match $Pattern) {
                        $MatchedPatternSchema = $PropertySchema.patternProperties.$Pattern
                        break
                    }
                }

                if ($MatchedPatternSchema) {
                    # Create a temporary validation object to collect schema validation errors
                    $SchemaValidation = @{
                        Errors = [System.Collections.ArrayList]::new()
                        Warnings = [System.Collections.ArrayList]::new()
                    }

                    # Validate the value against the pattern schema for this policy ID
                    [ScubaConfigValidator]::ValidateItemAgainstSchema($PolicyValue, $MatchedPatternSchema, $SchemaValidation, "${ActionType}: '$Policy'")

                    # Add schema validation errors/warnings to result based on requireProductInPolicy setting
                    foreach ($ValidationError in $SchemaValidation.Errors) {
                        if ($RequireProduct) {
                            $Result.Errors += $ValidationError
                        } else {
                            $Result.Warnings += $ValidationError
                        }
                    }

                    # Warnings from schema validation should always be warnings
                    foreach ($Warning in $SchemaValidation.Warnings) {
                        $Result.Warnings += $Warning
                    }
                }
            }
        }

        return $Result
    }

    # Internal configuration storage as hashtable
    hidden [hashtable]$Configuration

    # Applies default values and processes special configuration properties (wildcards, path expansion).
    # This method ensures all required properties have values and handles special cases like path resolution.
    # It implements a two-phase approach: 1) Apply defaults for missing properties, 2) Process special cases.
    hidden [void]SetParameterDefaults(){
        Write-Debug "Setting ScubaConfig default values from configuration."

        # Get the defaults section from cached configuration
        # This contains fallback values for all configurable properties
        $Defaults = [ScubaConfig]::_ConfigDefaults.defaults

        # Phase 1: Apply default values for any properties not explicitly set in the configuration file
        # This ensures the configuration is complete even if the YAML file is minimal or missing properties
        # Iterate through all default properties and set any missing values
        foreach ($PropertyName in $Defaults.PSObject.Properties.Name) {
            # Only set default if the property wasn't explicitly provided in the configuration file
            # This respects user's explicit choices while filling in gaps with sensible defaults
            if (-not $this.Configuration.$PropertyName) {
                Write-Debug "Setting default value for '$PropertyName'"
                # Copy the default value from the defaults configuration
                $this.Configuration[$PropertyName] = $Defaults.$PropertyName
            }
        }

        # Phase 2: Special processing for properties that require additional logic beyond simple defaults
        # These properties need custom handling for wildcards, path resolution, or data transformation

        # Special handling for ProductNames (wildcard expansion and uniqueness)
        # ProductNames determines which Microsoft 365 products will be scanned
        if ($this.Configuration.ProductNames) {
            # Check for wildcard with other products before expansion
            # Store warning to display later with validation warnings for consistency
            # This is a common user mistake that can lead to confusion about which products are scanned
            if ($this.Configuration.ProductNames.Contains('*') -and $this.Configuration.ProductNames.Count -gt 1) {
                if (-not $this.Configuration.ContainsKey('_PreValidationWarnings')) {
                    $this.Configuration._PreValidationWarnings = [System.Collections.ArrayList]::new()
                }
                [void]$this.Configuration._PreValidationWarnings.Add("ProductNames contains wildcard '*' with other products. Wildcard takes precedence.")
            }

            # Handle wildcard '*' by expanding to all supported products
            # This provides a convenient way to scan all available Microsoft 365 products
            if ($this.Configuration.ProductNames.Contains('*')) {
                $this.Configuration.ProductNames = [ScubaConfig]::ScubaDefault('AllProductNames')
                Write-Debug "Setting ProductNames to all products because of wildcard"
            } else {
                # Remove duplicates and sort for consistency
                # This handles cases where users accidentally specify the same product multiple times
                Write-Debug "ProductNames provided - ensuring uniqueness."
                $this.Configuration.ProductNames = @($this.Configuration.ProductNames | Sort-Object -Unique)
            }
        }

        # Special handling for OPAPath (expand Unix-style home directory reference)
        # Convert tilde (~) to actual Windows user profile path for cross-platform compatibility
        if ($this.Configuration.OPAPath -eq "~/.scubagear/Tools") {
            try {
                # Build the full path using Windows conventions
                # This allows Unix-style path notation to work on Windows systems
                $ExpandedPath = Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"
                # Check if expanded path exists, fallback to current directory if not (legacy behavior)
                if (Test-Path -LiteralPath $ExpandedPath) {
                    $this.Configuration.OPAPath = $ExpandedPath
                } else {
                    # Fallback to current directory when default OPA path doesn't exist
                    # This matches legacy behavior for systems without OPA installed in the default location
                    $this.Configuration.OPAPath = "."
                }
            } catch {
                # Fallback to current directory if profile path resolution fails
                # This ensures the configuration is still usable even if home directory access fails
                $this.Configuration.OPAPath = "."
            }
        }
        # Note: If OPAPath is explicitly set in config file (not the default), it will be used as-is
        # and validation will fail if OPA executable is not found there (no fallback for explicit paths)

        # Special handling for OutPath (resolve relative current directory reference)
        # Convert '.' to the actual current working directory path for absolute path consistency
        if ($this.Configuration.OutPath -eq ".") {
            # Get the current working directory as an absolute path
            # This ensures output files are written to a predictable location
            $this.Configuration.OutPath = Get-Location | Select-Object -ExpandProperty ProviderPath
        }

        return
    }

    # enforces singleton pattern by preventing direct instantiation.
    hidden ScubaConfig(){
    }

    # Resets singleton to clean state. Primarily used in testing scenarios for isolation.
    static [void]ResetInstance(){
        [ScubaConfig]::_Instance.ClearConfiguration()
        [ScubaConfig]::_IsLoaded = $false
        # Allow reinitialization of the validator when tests call ResetInstance
        [ScubaConfig]::_ValidatorInitialized = $false

        # Always: force cleanup for CI runs
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        return
    }

    # Returns the singleton instance. Initializes validator subsystem on first access.
    static [ScubaConfig]GetInstance(){
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_Instance
    }

    # Returns configuration defaults object loaded from ScubaConfigDefaults.json.
    static [object] GetConfigDefaults() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults
    }

    # Returns JSON Schema object loaded from ScubaConfigSchema.json for configuration validation.
    static [object] GetConfigSchema() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigSchema
    }

    # Validates configuration file without loading it. Returns detailed validation results.
    static [ValidationResult] ValidateConfigFile([string]$Path) {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfigValidator]::ValidateYamlFile($Path)
    }

    # Returns array of all supported product names from defaults configuration.
    static [array] GetSupportedProducts() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults.defaults.AllProductNames
    }

    # Returns array of supported M365 environment names (commercial, gcc, gcchigh, dod).
    static [array] GetSupportedEnvironments() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigSchema.properties.M365Environment.enum
    }

    # Returns configuration information for specified product (baseline file, capabilities, etc.).
    static [object] GetProductInfo([string]$ProductName) {
        [ScubaConfig]::InitializeValidator()
        # Products are not stored in defaults anymore, return a simple object with the product name
        # This maintains backward compatibility for code that expects this method to work
        return @{ name = $ProductName }
    }

    # Returns array of privileged administrative roles for security validation.
    static [array] GetPrivilegedRoles() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults.privilegedRoles
    }
}
