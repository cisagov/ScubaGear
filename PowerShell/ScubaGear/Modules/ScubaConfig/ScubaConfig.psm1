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
    hidden static [ScubaConfig]$_Instance = [ScubaConfig]::new()
    hidden static [Boolean]$_IsLoaded = $false
    hidden static [Boolean]$_ValidatorInitialized = $false
    hidden static [object]$_ConfigDefaults = $null
    hidden static [object]$_ConfigSchema = $null

    # Initializes validator subsystem once per session - loads schema/defaults from JSON files,
    # caches resources in static properties for performance.
    static [void] InitializeValidator() {
        if (-not [ScubaConfig]::_ValidatorInitialized) {
            $ModulePath = Split-Path -Parent $PSCommandPath
            [ScubaConfigValidator]::Initialize($ModulePath)
            [ScubaConfig]::_ConfigDefaults = [ScubaConfigValidator]::GetDefaults()
            [ScubaConfig]::_ConfigSchema = [ScubaConfigValidator]::GetSchema()
            [ScubaConfig]::_ValidatorInitialized = $true
        }
    }

    # Resolves configuration defaults using naming conventions. "Default" prefix maps to defaults section.
    # Special processing: DefaultOPAPath expands ~, DefaultOutPath resolves ., wildcard handling for products.
    static [object]ScubaDefault ([string]$Name){
        [ScubaConfig]::InitializeValidator()

        # Dynamically resolve configuration values based on naming conventions
        # This eliminates the need to maintain mappings in multiple places

        # Handle special cases that require processing
        if ($Name -eq 'DefaultOPAPath') {
            $Path = [ScubaConfig]::_ConfigDefaults.defaults.OPAPath
            if ($Path -eq "~/.scubagear/Tools") {
                try {
                    return Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"
                } catch {
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
    [Boolean]LoadConfig([System.IO.FileInfo]$Path, [Boolean]$SkipValidation){
        if (-Not (Test-Path -PathType Leaf $Path)){
            throw [System.IO.FileNotFoundException]"Failed to load: $Path"
        }

        [ScubaConfig]::ResetInstance()
        [ScubaConfig]::InitializeValidator()

        # Always validate file format (extension, size, YAML syntax)
        Write-Debug "Loading configuration file: $Path"
        $ValidationResult = [ScubaConfigValidator]::ValidateYamlFile($Path.FullName, $false, $true)

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

    # Validates current configuration state after overrides. Performs schema + default checks + policy validation.
    # Used for deferred validation pattern where config is loaded with SkipValidation=true then validated after overrides.
    [void]ValidateConfiguration(){

        Write-Debug "Validating final configuration state"

        # Convert hashtable back to PSCustomObject for validation
        $ConfigObject = [PSCustomObject]$this.Configuration

        # Perform schema validation
        $SchemaValidation = [ScubaConfigValidator]::ValidateAgainstSchema($ConfigObject, $false)

        # Perform business rule validation
        $BusinessValidation = [ScubaConfigValidator]::ValidateBusinessRules($ConfigObject, $false)

        # Collect all errors
        $AllErrors = @()
        $AllErrors += $SchemaValidation.Errors
        $AllErrors += $BusinessValidation.Errors

        # Display warnings
        foreach ($Warning in $SchemaValidation.Warnings) {
            Write-Warning $Warning
        }
        foreach ($Warning in $BusinessValidation.Warnings) {
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
            $ErrorMessage = "Configuration validation failed:`n"
            foreach ($ValidationError in $AllErrors) {
                $ErrorMessage += "  - $ValidationError`n"
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

                $ErrorMessage = "Config file indicates $ActionType $Policy, but $Policy is not a valid control ID. "
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
                $ErrorMessage = "Config file indicates $ActionType $Policy, but $Product is not one of the products "
                $ErrorMessage += "specified in the ProductNames parameter (not in the selected ProductNames)."
                throw $ErrorMessage
            }
        }
    }

    # Internal configuration storage as hashtable
    hidden [hashtable]$Configuration

    # Applies default values and processes special configuration properties (wildcards, path expansion).
    hidden [void]SetParameterDefaults(){
        Write-Debug "Setting ScubaConfig default values from configuration."

        # Get defaults configuration
        $Defaults = [ScubaConfig]::_ConfigDefaults.defaults

        # Set defaults for any properties not specified in the YAML, using configuration-driven approach
        foreach ($PropertyName in $Defaults.PSObject.Properties.Name) {
            if (-not $this.Configuration.ContainsKey($PropertyName)) {
                Write-Debug "Setting default value for '$PropertyName'"
                $this.Configuration[$PropertyName] = $Defaults.$PropertyName
            }
        }

        # Special handling for ProductNames (wildcard expansion and uniqueness)
        if ($this.Configuration.ProductNames) {
            if ($this.Configuration.ProductNames.Contains('*')) {
                $this.Configuration.ProductNames = [ScubaConfig]::ScubaDefault('AllProductNames')
                Write-Debug "Setting ProductNames to all products because of wildcard"
            } else {
                Write-Debug "ProductNames provided - ensuring uniqueness."
                $this.Configuration.ProductNames = @($this.Configuration.ProductNames | Sort-Object -Unique)
            }
        }

        # Special handling for OPAPath (expand tilde)
        if ($this.Configuration.OPAPath -eq "~/.scubagear/Tools") {
            try {
                $this.Configuration.OPAPath = Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"
            } catch {
                $this.Configuration.OPAPath = "."
            }
        }

        # Special handling for OutPath (resolve current directory)
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
