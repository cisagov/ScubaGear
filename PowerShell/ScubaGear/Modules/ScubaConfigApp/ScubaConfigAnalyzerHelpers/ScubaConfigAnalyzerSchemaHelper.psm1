<#
.SYNOPSIS
    Analyzer helper: schema loading, shared caches, and small path/parse utilities.
.NOTES
    Imported (Import-Module) by Start-SCuBAConfigAnalyzer alongside the other analyzer
    helpers. Shared analyzer state lives on the synchronized $syncHash ($syncHash.ScA*), so
    every helper module reads/writes the same caches (mirrors how ScubaConfigApp shares
    state). Populated at scan time by Import-ScA*.
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

function Resolve-ScASchemaPath {
    <#
    .SYNOPSIS
    Resolves the default location of a schema file inside PowerShell/ScubaGear/schemas.
    #>
    param([Parameter(Mandatory)][string]$FileName)

    # This module lives in Modules/ScubaConfigApp/ScubaConfigAnalyzer, so the schemas
    # folder is three levels up (resolve from the analyzer root, not this helper folder).
    $candidate = Join-Path $syncHash.ScAModuleRoot (Join-Path '..\..\..\schemas' $FileName)
    if (Test-Path $candidate) {
        return (Resolve-Path $candidate).Path
    }
    # Fallback: a copy bundled alongside this module (keeps standalone use working).
    $local = Join-Path $syncHash.ScAModuleRoot $FileName
    if (Test-Path $local) {
        return (Resolve-Path $local).Path
    }

    # Return the candidate path even if it doesn't exist (caller can handle the missing file).
    return $candidate
}

function Resolve-ScAConfigSchemaPath {
    <#
    .SYNOPSIS
    Resolves the canonical ScubaGear config schema (Modules/ScubaConfig/ScubaConfigSchema.json),
    the single source of truth for which policies are configurable via exclusions/allow-lists.
    #>
    # Engine lives in Modules/ScubaConfigApp/ScubaConfigAnalyzer -> config schema is two levels
    # up (resolve from the analyzer root, not this helper folder).
    $candidate = Join-Path $syncHash.ScAModuleRoot '..\..\ScubaConfig\ScubaConfigSchema.json'
    if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }

    # Return the candidate path even if it doesn't exist (caller can handle the missing file).
    return $candidate
}

function Import-ScAConfigurableMap {
    <#
    .SYNOPSIS
    Loads per-policy exclusion mappings + product capabilities from the canonical ScubaGear
    config schema so configurability is JSON-driven (never hardcoded). Populates
    $syncHash.ScAConfigurableMap (control id -> supported exclusion types) and
    $syncHash.ScAProductCapabilities. Safe when the schema is missing (empty maps).
    #>
    param([string]$ConfigSchemaPath)

    $syncHash.ScAConfigurableMap     = @{}
    $syncHash.ScAProductCapabilities = @{}
    # Ensure the config schema path is valid before attempting to import.
    if (-not $ConfigSchemaPath -or -not (Test-Path $ConfigSchemaPath)) {
        Write-Verbose "Config schema not found - configurability tagging disabled."
        return
    }
    try {
        # Read and parse the config schema JSON.
        $meta = (Get-Content $ConfigSchemaPath -Raw | ConvertFrom-Json).schemaMetadata
        if ($meta.policyExclusionMappings) {
            foreach ($p in $meta.policyExclusionMappings.PSObject.Properties) {
                if ($p.Name -notmatch '^_') { $syncHash.ScAConfigurableMap[$p.Name] = @($p.Value) }
            }
        }
        # Read and parse the product capabilities from the config schema JSON.
        if ($meta.productCapabilities) {
            foreach ($p in $meta.productCapabilities.PSObject.Properties) {
                $syncHash.ScAProductCapabilities[$p.Name] = $p.Value
            }
        }
    } catch {
        Write-Warning "Failed to read config schema '$ConfigSchemaPath': $($_.Exception.Message)"
    }
}

function Import-ScAAnalyzerRules {
    <#
    .SYNOPSIS
    Loads the analyzer rules from ScubaConfigAnalyzer_Control_en-US.json into the module caches so
    the engine is a generic interpreter (product-key map, requirement friendly names,
    named Graph operations, and Conditional Access condition rules are all JSON-driven).
    #>
    param([Parameter(Mandatory)]$AnalyzerSchema)

    # Requirement path -> friendly label (supports a 'default' sub-object or a flat map).
    $syncHash.ScAFriendlyNames =
        if ($AnalyzerSchema.RequirementFriendlyNames.default) { $AnalyzerSchema.RequirementFriendlyNames.default }
        elseif ($AnalyzerSchema.RequirementFriendlyNames)     { $AnalyzerSchema.RequirementFriendlyNames }
        else { $null }

    # Product key map (prodLower -> ResultsKey/ConfigKey).
    $syncHash.ScAProductMap = @{}
    if ($AnalyzerSchema.productMap) {
        foreach ($p in $AnalyzerSchema.productMap.PSObject.Properties) {
            if ($p.Name -match '^_') { continue }
            $syncHash.ScAProductMap[$p.Name.ToLower()] = @{ ResultsKey = [string]$p.Value.resultsKey; ConfigKey = [string]$p.Value.configKey; DisplayName = [string]$p.Value.displayName }
        }
    }
    if ($syncHash.ScAProductMap.Count -eq 0) { Write-Warning "Analyzer schema has no 'productMap' - product result/config keys are unavailable." }

    # Named Graph operations (operation name -> definition; resolved to URLs via the API catalog).
    $syncHash.ScAApiOperations = @{}
    if ($AnalyzerSchema.apiOperations) {
        foreach ($op in $AnalyzerSchema.apiOperations.PSObject.Properties) {
            # Skip any internal properties that start with an underscore.
            if ($op.Name -match '^_') { continue }
            $syncHash.ScAApiOperations[$op.Name] = $op.Value
        }
    }

    # Conditional Access interpretation rules.
    $syncHash.ScACaRules = $AnalyzerSchema.conditionalAccessAnalysis

    # Exclusion field metadata; allows future exclusion types to be emitted without
    # hardcoded field arrays in the YAML builder.
    $syncHash.ScAExclusionDefinitions = @{}
    if ($AnalyzerSchema.exclusionDefinitions) {
        foreach ($exclusion in $AnalyzerSchema.exclusionDefinitions.PSObject.Properties) {
            # Skip any internal properties that start with an underscore.
            if ($exclusion.Name -match '^_') { continue }
            $syncHash.ScAExclusionDefinitions[$exclusion.Name] = $exclusion.Value
        }
    }
}

function Import-ScAApiCatalog {
    <#
    .SYNOPSIS
    Loads ScubaGearApiCatalog.json (moduleCmdlet -> entry) so API resource paths and
    least permissions come from the catalog, never from hardcoded URLs in this module.
    #>
    param([string]$ApiCatalogPath)

    $syncHash.ScAApiCatalog = @{}

    # If no API catalog path is provided, resolve the default path relative to the module.
    if (-not $ApiCatalogPath) { $ApiCatalogPath = Resolve-ScASchemaPath -FileName 'ScubaGearApiCatalog.json' }
    if (-not (Test-Path $ApiCatalogPath)) { Write-Warning "API catalog not found: $ApiCatalogPath"; return }
    
    try {
        # Read and parse the API catalog JSON file.
        $catalog = Get-Content $ApiCatalogPath -Raw | ConvertFrom-Json
        foreach ($e in @($catalog)) { if ($e.moduleCmdlet) { $syncHash.ScAApiCatalog[[string]$e.moduleCmdlet] = $e } }
    } catch {
        Write-Warning "Failed to read API catalog '$ApiCatalogPath': $($_.Exception.Message)"
    }
}

function Resolve-ScAApiResource {
    <#
    .SYNOPSIS
    Builds a Graph request URI for a named analyzer operation by resolving its cmdlet to
    an apiResource in ScubaGearApiCatalog.json. resultKind: collection (list) | byId
    (single item, {id} substituted) | byAppId (service principal by appId). Returns $null
    when the operation or catalog entry is unknown (caller falls back gracefully).
    #>
    param([Parameter(Mandatory)][string]$Operation, [string]$Id)

    # Ensure that the API operations and catalog are loaded before attempting to resolve the resource.
    if (-not $syncHash.ScAApiOperations.ContainsKey($Operation)) { return $null }
    $op = $syncHash.ScAApiOperations[$Operation]
    $cmd = [string]$op.cmdlet
    if (-not $cmd -or -not $syncHash.ScAApiCatalog.ContainsKey($cmd)) { return $null }

    # Retrieve the catalog entry for the resolved cmdlet and extract the API resource, filter, and selection parameters.
    $entry    = $syncHash.ScAApiCatalog[$cmd]
    $resource = [string]$entry.apiResource
    if (-not $resource) { return $null }

    # Determine the filter to apply to the API request based on the catalog entry.
    $filter = if ($entry.apiFilter) { [string]$entry.apiFilter } else { '' }
    # Determine the select query parameter to apply to the API request based on the operation definition.
    $select = if ($op.select) { '?$select=' + [string]$op.select } else { '' }
    # Determine the kind of result expected from the API operation (collection, byId, byAppId).
    $kind   = if ($op.resultKind) { [string]$op.resultKind } else { 'collection' }

    # Build the final API request URI based on the kind of result expected.
    # The switch statement below handles different kinds of API request URIs based on the expected result kind.
    switch ($kind) {
        'byId' {
            # For 'byId' results, construct the base URI by substituting the '{id}' placeholder with the provided ID.
            $base = if ($resource -match '\{id\}') { $resource }
                    elseif ($filter -match '\{id\}') { $resource + $filter }
                    else { $resource.TrimEnd('/') + '/{id}' }
            return ($base -replace '\{id\}', $Id) + $select
        }
        'byAppId' {
            # For 'byAppId' results, construct the collection URI by removing the '{id}' placeholder and appending the appId query parameter.
            $collection = ($resource -replace '/\{id\}\s*$', '').TrimEnd('/')
            return "$collection(appId='$Id')" + $select
        }
        default { return $resource + $select }
    }
}

function Get-ScAValueAtPath {
    <#
    .SYNOPSIS
    Navigates a dotted, camelCase path (e.g. conditions.users.excludeUsers) on an object,
    matching property names case-insensitively so both ScubaResults (PascalCase) and raw
    Graph (camelCase) shapes resolve. Returns the value or $null if any segment is missing.
    #>
    param($Object, [Parameter(Mandatory)][string]$Path)

    $cur = $Object
    # Traverse each segment of the dotted path, resolving property names case-insensitively.
    foreach ($part in ($Path -split '\.')) {
        if ($null -eq $cur) { return $null }
        # Attempt to find the property on the current object that matches the current path segment, case-insensitively.
        $prop = $cur.PSObject.Properties | Where-Object { $_.Name -ieq $part } | Select-Object -First 1
        if (-not $prop) { return $null }
        $cur = $prop.Value
    }

    # After traversing all segments, $cur holds the value at the specified path or $null if any segment was missing.
    return $cur
}

function Get-ScAFriendlyName {
    <#
    .SYNOPSIS
    Returns a human-readable label for a requirement path (from the config schema).
    #>
    param([Parameter(Mandatory)][string]$Path)

    # Return the human-readable label for the given requirement path if available; otherwise, return the path itself.
    if ($syncHash.ScAFriendlyNames -and ($syncHash.ScAFriendlyNames.PSObject.Properties.Name -contains $Path)) {
        return $syncHash.ScAFriendlyNames.$Path
    }

    # If no human-readable label is found for the given path, fall back to returning the path itself.
    return $Path
}

function Remove-ScAHtml {
    <#
    .SYNOPSIS
    Strips embedded HTML (e.g. the 'policy-indicators' block ScubaGear results add to the
    Requirement text) and returns clean plain text.
    #>
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $Text }
    # Drop the trailing indicators/markup block, strip any remaining tags, then decode entities.
    # Split the text at the first occurrence of a <div> tag to remove the trailing indicators/markup block.
    $clean = ($Text -split '<div')[0]
    # Remove any remaining HTML tags from the text.
    $clean = $clean -replace '<[^>]+>', ''
    # Decode any HTML entities to get clean plain text.
    $clean = [System.Net.WebUtility]::HtmlDecode($clean)
    # Trim any leading or trailing whitespace from the cleaned text.
    return $clean.Trim()
}

function Get-ScAValidationSchema {
    <#
    .SYNOPSIS
    Finds the baseline validation entry for a control id across all products.
    #>
    param(
        [Parameter(Mandatory)][string]$ControlId,
        [Parameter(Mandatory)]$BaselineSchema
    )

    # Return $null if the baseline schema or its validations are not available.
    if (-not $BaselineSchema -or -not $BaselineSchema.baselineValidations) { return $null }

    # Iterate through each product in the baseline validations to find a matching control id.
    foreach ($product in $BaselineSchema.baselineValidations.PSObject.Properties.Name) {
        # Check each validation entry for the current product to see if it matches the specified control id.
        $match = $BaselineSchema.baselineValidations.$product | Where-Object { $_.id -eq $ControlId }
        if ($match) { return $match }
    }
    # If no matching validation entry is found for any product, return $null.
    return $null
}

