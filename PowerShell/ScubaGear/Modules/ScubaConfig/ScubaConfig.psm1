using module '.\ScubaConfigValidator.psm1'

class ScubaConfig {
    <#
    .SYNOPSIS
    This singleton class stores Scuba config data loaded from a file.
    .DESCRIPTION
    This class is designed to function as a singleton. The singleton instance
    is cached on the ScubaConfig type itself. In the context of tests, it may be
    important to call `.ResetInstance` before and after tests as needed to
    ensure any preexisting configs are not inadvertantly used for the test,
    or left in place after the test is finished. The singleton will persist
    for the life of the powershell session unless the ScubaConfig module is
    removed. Note that `.LoadConfig` internally calls `.ResetInstance` to avoid
    issues.
    .EXAMPLE
    $Config = [ScubaConfig]::GetInstance()
    [ScubaConfig]::LoadConfig($SomePath)
    #>
    hidden static [ScubaConfig]$_Instance = [ScubaConfig]::new()
    hidden static [Boolean]$_IsLoaded = $false
    hidden static [Boolean]$_ValidatorInitialized = $false
    hidden static [object]$_ConfigDefaults = $null
    hidden static [object]$_ConfigSchema = $null

    static [void] InitializeValidator() {
        if (-not [ScubaConfig]::_ValidatorInitialized) {
            $ModulePath = Split-Path -Parent $PSCommandPath
            [ScubaConfigValidator]::Initialize($ModulePath)
            [ScubaConfig]::_ConfigDefaults = [ScubaConfigValidator]::GetDefaults()
            [ScubaConfig]::_ConfigSchema = [ScubaConfigValidator]::GetSchema()
            [ScubaConfig]::_ValidatorInitialized = $true
        }
    }

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

    static [string]GetOpaVersion() {
        return [ScubaConfig]::ScubaDefault('DefaultOPAVersion')
    }

    [Boolean]LoadConfig([System.IO.FileInfo]$Path){
        if (-Not (Test-Path -PathType Leaf $Path)){
            throw [System.IO.FileNotFoundException]"Failed to load: $Path"
        }

        [ScubaConfig]::ResetInstance()
        [ScubaConfig]::InitializeValidator()

        # Validate the YAML file before loading
        Write-Debug "Validating configuration file: $Path"
        $ValidationResult = [ScubaConfigValidator]::ValidateYamlFile($Path.FullName)

        if (-not $ValidationResult.IsValid) {
            $ErrorMessage = "Configuration validation failed:`n"
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

        # Legacy validation for policy IDs - now handled by validator but kept for backwards compatibility
        if ($this.Configuration.ContainsKey("OmitPolicy")) {
            [ScubaConfig]::ValidatePolicyConfiguration($this.Configuration.OmitPolicy, "omitting", $this.Configuration.ProductNames)
        }

        if ($this.Configuration.ContainsKey("AnnotatePolicy")) {
            [ScubaConfig]::ValidatePolicyConfiguration($this.Configuration.AnnotatePolicy, "annotation", $this.Configuration.ProductNames)
        }

        return [ScubaConfig]::_IsLoaded
    }

    hidden [void]ClearConfiguration(){
        $this.Configuration = $null
    }

    hidden static [hashtable] ConvertPSObjectToHashtable([PSCustomObject]$Object) {
        $Hashtable = @{}
        foreach ($Property in $Object.PSObject.Properties) {
            if ($Property.Value -is [PSCustomObject]) {
                $Hashtable[$Property.Name] = [ScubaConfig]::ConvertPSObjectToHashtable($Property.Value)
            }
            elseif ($Property.Value -is [Array]) {
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

    hidden static [void] ValidatePolicyConfiguration([object]$PolicyConfig, [string]$ActionType, [array]$ProductNames) {
        [ScubaConfig]::InitializeValidator()
        $Defaults = [ScubaConfig]::_ConfigDefaults

        foreach ($Policy in $PolicyConfig.Keys) {
            if (-not ($Policy -match $Defaults.validation.policyIdPattern)) {
                $Warning = "Config file indicates $ActionType $Policy, but $Policy is not a valid control ID. "
                $Warning += "Expected format is '$($Defaults.validation.policyIdExample)'. "
                $Warning += "Control will not be processed."
                Write-Warning $Warning
                Continue
            }

            $Product = ($Policy -Split "\.")[1].ToLower()

            # Handle wildcard in ProductNames
            $EffectiveProducts = $ProductNames
            if ($ProductNames -contains '*') {
                $EffectiveProducts = $Defaults.defaults.AllProductNames
            }

            if (-not ($EffectiveProducts -Contains $Product)) {
                $Warning = "Config file indicates $ActionType $Policy, but $Product is not one of the products "
                $Warning += "specified in the ProductNames parameter. Control will not be processed."
                Write-Warning $Warning
                Continue
            }
        }
    }

    hidden static [hashtable] ConvertPSObjectToHashtable([PSCustomObject]$Object) {
        $Hashtable = @{}
        foreach ($Property in $Object.PSObject.Properties) {
            if ($Property.Value -is [PSCustomObject]) {
                $Hashtable[$Property.Name] = [ScubaConfig]::ConvertPSObjectToHashtable($Property.Value)
            }
            elseif ($Property.Value -is [Array]) {
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

    hidden static [void] ValidatePolicyConfiguration([object]$PolicyConfig, [string]$ActionType, [array]$ProductNames) {
        [ScubaConfig]::InitializeValidator()
        $Defaults = [ScubaConfig]::_ConfigDefaults

        foreach ($Policy in $PolicyConfig.Keys) {
            if (-not ($Policy -match $Defaults.validation.policyIdPattern)) {
                $Warning = "Config file indicates $ActionType $Policy, but $Policy is not a valid control ID. "
                $Warning += "Expected format is '$($Defaults.validation.policyIdExample)'. "
                $Warning += "Control will not be processed."
                Write-Warning $Warning
                Continue
            }

            $Product = ($Policy -Split "\.")[1].ToLower()

            # Handle wildcard in ProductNames
            $EffectiveProducts = $ProductNames
            if ($ProductNames -contains '*') {
                $EffectiveProducts = $Defaults.defaults.AllProductNames
            }

            if (-not ($EffectiveProducts -Contains $Product)) {
                $Warning = "Config file indicates $ActionType $Policy, but $Product is not one of the products "
                $Warning += "specified in the ProductNames parameter. Control will not be processed."
                Write-Warning $Warning
                Continue
            }
        }
    }

    hidden [Guid]$Uuid = [Guid]::NewGuid()
    hidden [hashtable]$Configuration

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
                $this.Configuration.ProductNames = $this.Configuration.ProductNames | Sort-Object -Unique
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

    hidden ScubaConfig(){
    }

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

    static [ScubaConfig]GetInstance(){
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_Instance
    }

    # Additional utility methods for JSON-based configuration
    static [object] GetConfigDefaults() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults
    }

    static [object] GetConfigSchema() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigSchema
    }

    static [ValidationResult] ValidateConfigFile([string]$Path) {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfigValidator]::ValidateYamlFile($Path)
    }

    static [array] GetSupportedProducts() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults.defaults.AllProductNames
    }

    static [array] GetSupportedEnvironments() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults.M365Environment.PSObject.Properties.Name
    }

    static [object] GetProductInfo([string]$ProductName) {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults.products.$ProductName
    }

    static [array] GetPrivilegedRoles() {
        [ScubaConfig]::InitializeValidator()
        return [ScubaConfig]::_ConfigDefaults.privilegedRoles
    }
}
