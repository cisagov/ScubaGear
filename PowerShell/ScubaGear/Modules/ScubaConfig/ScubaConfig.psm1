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
                    return Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"
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

    # Loads configuration file with full validation enabled (delegates to main LoadConfig with SkipValidation=false).
    [Boolean]LoadConfig([System.IO.FileInfo]$Path){
        return $this.LoadConfig($Path, $false)
    }

    # Primary config loading method. Resets singleton, validates file format, parses content, applies defaults.
    # SkipValidation=true allows deferred validation after command-line overrides are applied.
    # This method implements a two-phase validation approach for flexibility
    [Boolean]LoadConfig([System.IO.FileInfo]$Path, [Boolean]$SkipValidation){
        # First, verify the file exists before attempting to load it
        if (-Not (Test-Path -PathType Leaf $Path)){
            throw [System.IO.FileNotFoundException]"Failed to load: $Path"
        }

        # Reset the singleton to ensure clean state before loading new configuration
        [ScubaConfig]::ResetInstance()
        # Ensure the validator subsystem is ready
        [ScubaConfig]::InitializeValidator()

        # Phase 1: Always validate basic file format (extension, size, YAML syntax)
        # This catches fundamental issues early before processing
        Write-Debug "Loading configuration file: $Path"

        # Use the default debug mode from configuration instead of hardcoding false
        $Defaults = [ScubaConfig]::_ConfigDefaults
        $DefaultDebugMode = if ($Defaults.outputSettings -and $Defaults.outputSettings.debugMode) {
            $Defaults.outputSettings.debugMode
        } else {
            $false
        }
        Write-Debug "Using debug mode: $DefaultDebugMode (from configuration default)"

        $ValidationResult = [ScubaConfigValidator]::ValidateYamlFile($Path.FullName, $DefaultDebugMode, $true)

        # Check for file format errors (extension, size, YAML parsing)
        if (-not $ValidationResult.IsValid) {
            $ErrorMessage = "Configuration file format validation failed:`n"
            foreach ($ValidationError in $ValidationResult.ValidationErrors) {
                $ErrorMessage += "  - $ValidationError`n"
            }
            throw $ErrorMessage.TrimEnd()
        }

        # Display warnings if any
        if ($ValidationResult.Warnings.Count -gt 0) {
            foreach ($Warning in $ValidationResult.Warnings) {
                Write-Warning $Warning
            }
        }

        # Use the already parsed content from validation
        $this.Configuration = $ValidationResult.ParsedContent

        # Convert to hashtable for compatibility
        if ($this.Configuration -is [PSCustomObject]) {
            $this.Configuration = [ScubaConfig]::ConvertPSObjectToHashtable($this.Configuration)
        }

        $this.SetParameterDefaults()
        [ScubaConfig]::_IsLoaded = $true

        # Perform full validation if not skipped
        if (-not $SkipValidation) {
            $this.ValidateConfiguration()
        }

        return [ScubaConfig]::_IsLoaded
    }

    # Validates current configuration state after overrides. Performs schema + Configuration rules + policy validation.
    # Used for deferred validation pattern where config is loaded with SkipValidation=true then validated after overrides.
    # This allows command-line parameters to override config file values before final validation
    [void]ValidateConfiguration(){

        Write-Debug "Validating final configuration state"

        # Convert internal hashtable representation back to PSCustomObject for validator compatibility
        # The validator expects PSCustomObject format for consistent property access
        $ConfigObject = [PSCustomObject]$this.Configuration

        # Phase 1: Perform JSON Schema validation (structure, types, constraints)
        $SchemaValidation = [ScubaConfigValidator]::ValidateAgainstSchema($ConfigObject, $false)

        # Phase 2: Perform Configuration rule validation (paths, content quality, cross-field validation)
        $ConfigurationValidation = [ScubaConfigValidator]::ValidateConfigurationRules($ConfigObject, $false)

        # Collect all errors
        $AllErrors = @()
        $AllErrors += $SchemaValidation.Errors
        $AllErrors += $ConfigurationValidation.Errors

        # Display warnings
        foreach ($Warning in $SchemaValidation.Warnings) {
            Write-Warning $Warning
        }
        foreach ($Warning in $ConfigurationValidation.Warnings) {
            Write-Warning $Warning
        }

        # Legacy validation for policy IDs (respect validation flags)
        $Defaults = [ScubaConfig]::_ConfigDefaults

        # Validate OmitPolicy entries if present and validation not disabled
        if ($this.Configuration.ContainsKey("OmitPolicy") -and $Defaults.validation.validateOmitPolicy -ne $false) {
            try {
                [ScubaConfig]::ValidatePolicyConfiguration($this.Configuration.OmitPolicy, "omitting", $this.Configuration.ProductNames)
            }
            catch {
                $AllErrors += $_.Exception.Message
            }
        }

        # Validate AnnotatePolicy entries if present and validation not disabled
        if ($this.Configuration.ContainsKey("AnnotatePolicy") -and $Defaults.validation.validateAnnotatePolicy -ne $false) {
            try {
                [ScubaConfig]::ValidatePolicyConfiguration($this.Configuration.AnnotatePolicy, "annotation", $this.Configuration.ProductNames)
            }
            catch {
                $AllErrors += $_.Exception.Message
            }
        }

        # Throw if any validation errors
        if ($AllErrors.Count -gt 0) {
            # Get output settings from defaults
            $OutputSettings = $Defaults.outputSettings
            $recommendedActionMessage = $OutputSettings.recommendedActionMessage
            $ErrorCategories = $OutputSettings.errorCategories

            # Dynamically categorize errors based on configuration
            $CategorizedErrors = @{}
            $UncategorizedErrors = @()

            # Create a prioritized matching order (most specific patterns first)
            # This ensures more specific patterns match before generic ones
            $MatchingOrder = @()
            foreach ($Category in $ErrorCategories) {
                if ($Category.name -like "*Annotate*" -or $Category.name -like "*Omit*") {
                    $MatchingOrder = @($Category) + $MatchingOrder  # Add to front
                }
                else {
                    $MatchingOrder += $Category  # Add to end
                }
            }

            foreach ($ValidationError in $AllErrors) {
                $Categorized = $false

                # Try to match against each category's pattern in priority order
                foreach ($Category in $MatchingOrder) {
                    $CategoryName = $Category.name
                    $Pattern = $Category.pattern

                    if ($ValidationError -match $Pattern) {
                        # Special handling for "^Policy ID:" pattern to avoid double-categorization
                        if ($Pattern -match "\^Policy ID:") {
                            # Only categorize as Exclusion if not already matched by annotation/omitting
                            $IsAnnotated = $ValidationError -match "^Annotated Policy ID:"
                            $IsOmitted = $ValidationError -match "^Omitted Policy ID:"
                            if (-not $IsAnnotated -and -not $IsOmitted) {
                                if (-not $CategorizedErrors.ContainsKey($CategoryName)) {
                                    $CategorizedErrors[$CategoryName] = @()
                                }
                                $CategorizedErrors[$CategoryName] += $ValidationError
                                $Categorized = $true
                                break
                            }
                        }
                        else {
                            if (-not $CategorizedErrors.ContainsKey($CategoryName)) {
                                $CategorizedErrors[$CategoryName] = @()
                            }
                            $CategorizedErrors[$CategoryName] += $ValidationError
                            $Categorized = $true
                            break
                        }
                    }
                }

                if (-not $Categorized) {
                    $UncategorizedErrors += $ValidationError
                }
            }

            # Build categorized error message using configured order
            $ErrorMessage = "Configuration validation failed:`n"

            # Display errors in the order defined in configuration
            foreach ($Category in $ErrorCategories) {
                $CategoryName = $Category.name
                if ($CategorizedErrors.ContainsKey($CategoryName) -and $CategorizedErrors[$CategoryName].Count -gt 0) {
                    $ErrorMessage += "`n$CategoryName`:`n"
                    foreach ($ErrorMsg in $CategorizedErrors[$CategoryName]) {
                        $ErrorMessage += "  - $ErrorMsg`n"
                    }
                }
            }

            # Add any uncategorized errors
            if ($UncategorizedErrors.Count -gt 0) {
                $ErrorMessage += "`nOther errors:`n"
                foreach ($ErrorMsg in $UncategorizedErrors) {
                    $ErrorMessage += "  - $ErrorMsg`n"
                }
            }

            # Add RECOMMENDED ACTION message if available
            if ($recommendedActionMessage -and $recommendedActionMessage.Count -gt 0) {
                $ErrorMessage += "`nRECOMMENDED ACTION:`n"
                foreach ($Message in $recommendedActionMessage) {
                    $ErrorMessage += "$Message`n"
                }
            }

            throw $ErrorMessage.TrimEnd()
        }
    }

    # Clears configuration data from singleton instance. Used by ResetInstance() for clean state.
    hidden [void]ClearConfiguration(){
        $this.Configuration = $null
    }

    # Recursively converts PSCustomObject to hashtable for internal storage compatibility.
    # YAML parsing creates PSCustomObjects, but internal config uses hashtables for performance.
    hidden static [hashtable] ConvertPSObjectToHashtable([PSCustomObject]$Object) {
        $Hashtable = @{}
        foreach ($Property in $Object.PSObject.Properties) {
            if ($Property.Value -is [PSCustomObject]) {
                $Hashtable[$Property.Name] = [ScubaConfig]::ConvertPSObjectToHashtable($Property.Value)
            }
            elseif ($Property.Value -is [Array] -or $Property.Value -is [System.Collections.IList]) {
                $Array = @()
                foreach ($Item in $Property.Value) {
                    if ($Item -is [PSCustomObject]) {
                        $Array += [ScubaConfig]::ConvertPSObjectToHashtable($Item)
                    }
                    else {
                        $Array += $Item
                    }
                }
                $Hashtable[$Property.Name] = $Array
            }
            else {
                $Hashtable[$Property.Name] = $Property.Value
            }
        }
        return $Hashtable
    }

    # Validates policy configuration entries for format compliance and product alignment.
    hidden static [void] ValidatePolicyConfiguration([object]$PolicyConfig, [string]$ActionType, [array]$ProductNames) {
        [ScubaConfig]::InitializeValidator()
        $Defaults = [ScubaConfig]::_ConfigDefaults

        foreach ($Policy in $PolicyConfig.Keys) {
            if (-not ($Policy -match $Defaults.validation.policyIdPattern)) {
                # Try to extract product from malformed policy ID to give better error message
                $PolicyParts = $Policy -split "\."
                $ProductInPolicy = if ($PolicyParts.Length -ge 2 -and $PolicyParts[1]) { $PolicyParts[1] } else { $null }

                # Generate format example from pattern using the validator's method
                $ExampleFormat = [ScubaConfigValidator]::ConvertPatternToExample($Defaults.validation.policyIdPattern, $ProductInPolicy)

                # Convert action type to past tense for error message prefix
                $ActionPrefix = if ($ActionType -eq "omitting") { "Omitted" } elseif ($ActionType -eq "annotation") { "Annotated" } else { (Get-Culture).TextInfo.ToTitleCase($ActionType) }
                $ErrorMessage = "${ActionPrefix} Policy ID: '$Policy' is not a valid control ID. "
                $ErrorMessage += "Expected format: $ExampleFormat. "
                $ErrorMessage += "Policy ID does not match expected format."
                throw $ErrorMessage
            }

            $Product = ($Policy -Split "\.")[1].ToLower()

            # Handle wildcard in ProductNames
            $EffectiveProducts = $ProductNames
            if ($ProductNames -contains '*') {
                $EffectiveProducts = $Defaults.defaults.AllProductNames
            }

            if (-not ($EffectiveProducts -Contains $Product)) {
                # Convert action type to past tense for error message prefix
                $ActionPrefix = if ($ActionType -eq "omitting") { "Omitted" } elseif ($ActionType -eq "annotation") { "Annotated" } else { (Get-Culture).TextInfo.ToTitleCase($ActionType) }
                $ErrorMessage = "${ActionPrefix} Policy ID: '$Policy' references product '$Product' which is not in the selected ProductNames: $($EffectiveProducts -join ', ')."
                throw $ErrorMessage
            }
        }
    }

    # Internal configuration storage as hashtable
    hidden [hashtable]$Configuration

    # Applies default values and processes special configuration properties (wildcards, path expansion).
    # This method ensures all required properties have values and handles special cases like path resolution
    hidden [void]SetParameterDefaults(){
        Write-Debug "Setting ScubaConfig default values from configuration."

        # Get the defaults section from cached configuration
        $Defaults = [ScubaConfig]::_ConfigDefaults.defaults

        # Iterate through all default properties and set any missing values
        # This ensures the configuration is complete even if the YAML file is minimal
        foreach ($PropertyName in $Defaults.PSObject.Properties.Name) {
            # Only set default if the property wasn't explicitly provided in the configuration file
            if (-not $this.Configuration.ContainsKey($PropertyName)) {
                Write-Debug "Setting default value for '$PropertyName'"
                $this.Configuration[$PropertyName] = $Defaults.$PropertyName
            }
        }

        # Special handling for ProductNames (wildcard expansion and uniqueness)
        # ProductNames determines which Microsoft 365 products will be scanned
        if ($this.Configuration.ProductNames) {
            # Handle wildcard '*' by expanding to all supported products
            if ($this.Configuration.ProductNames.Contains('*')) {
                $this.Configuration.ProductNames = [ScubaConfig]::ScubaDefault('AllProductNames')
                Write-Debug "Setting ProductNames to all products because of wildcard"
            } else {
                # Remove duplicates and sort for consistency
                Write-Debug "ProductNames provided - ensuring uniqueness."
                $this.Configuration.ProductNames = @($this.Configuration.ProductNames | Sort-Object -Unique)
            }
        }

        # Special handling for OPAPath (expand Unix-style home directory reference)
        # Convert tilde (~) to actual Windows user profile path
        if ($this.Configuration.OPAPath -eq "~/.scubagear/Tools") {
            try {
                # Build the full path using Windows conventions
                $this.Configuration.OPAPath = Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"
            } catch {
                # Fallback to current directory if profile path resolution fails
                $this.Configuration.OPAPath = "."
            }
        }

        # Special handling for OutPath (resolve relative current directory reference)
        # Convert '.' to the actual current working directory path
        if ($this.Configuration.OutPath -eq ".") {
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
        return [ScubaConfig]::_ConfigDefaults.M365Environment.PSObject.Properties.Name
    }

    # Returns configuration information for specified product (baseline file, capabilities, etc.).
    static [object] GetProductInfo([string]$ProductName) {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults.products.$ProductName
    }

    # Returns array of privileged administrative roles for security validation.
    static [array] GetPrivilegedRoles() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults.privilegedRoles
    }
}
