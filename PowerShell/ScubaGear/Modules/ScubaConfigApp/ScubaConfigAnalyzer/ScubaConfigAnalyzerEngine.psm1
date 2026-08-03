<#
.SYNOPSIS
    Analysis engine for the ScubaGear Config Analyzer (Start-SCuBAConfigAnalyzer).

.DESCRIPTION
    Reads a ScubaGear results JSON (produced by Invoke-SCuBA) and compares the raw
    tenant configuration against the ScubaGear baseline requirements described in the
    JSON schemas that ship in PowerShell/ScubaGear/schemas:

      - ScubaGearResultsBaselineSchema.json  (per-control validation logic / requiredSettings)

    plus an analyzer-local ScubaConfigAnalyzer/ScubaGearAnalyzerSchema_en-US.json (friendly
    display names for CA requirement paths). The canonical ScubaGear config-file schema
    is not duplicated here - see Modules/ScubaConfig/ScubaConfigSchema.json.

    Nothing about the baselines is hard-coded here: the controls, requirements and
    remediation steps all come from the schema files. The engine emits a structured
    findings object (consumed by the WPF UI) and can build a ready-to-use ScubaGear
    configuration YAML containing the exclusions detected in the tenant.

    This module is intentionally UI-free so the analysis can be unit-tested on its
    own (Invoke-ScubaConfigAnalysis -ResultsPath <file>).

    ----------------------------------------------------------------------------------
    TWO ENTRY POINTS (the public functions the UI calls)
    ----------------------------------------------------------------------------------
      Invoke-ScubaConfigAnalysis -ResultsPath <file>   OFFLINE: analyze an existing
                                                       ScubaResults_*.json on disk.
      Invoke-ScubaTenantScan     -Product <p> ...      LIVE: read the tenant straight
                                                       from Microsoft Graph and analyze
                                                       it (no ScubaGear run needed).
    Both return the SAME findings object (see OUTPUT CONTRACT), so the UI renders either
    identically. Get-ScubaAnalyzerConfigYaml turns that object into a ScubaGear config file.

    ----------------------------------------------------------------------------------
    PIPELINE (how one control becomes a finding)
    ----------------------------------------------------------------------------------
      1. Get-ScAValidationSchema        - look up the baseline rule for the control id.
      2. Get-ScAPolicyAnalysis          - find the CA policies related to the control,
                                          validate each requirement, and DETECT excluded
                                          users/groups/apps (the exclusionDetectors rules).
      3. Get-ScAActionClassification /  - decide how to make it pass: already passing,
         Get-ScAConfigAction              add exclusions to config, fix the policy, or
                                          create a new one.
      4. Build-ScAYamlExclusionsBlock    - emit the exclusions as ScubaGear config YAML
         (per control) / Get-ScubaAnalyzerConfigYaml (whole tenant).

    ----------------------------------------------------------------------------------
    SCHEMA-DRIVEN DESIGN (nothing product/policy specific is hardcoded)
    ----------------------------------------------------------------------------------
      ScubaGearResultsBaselineSchema.json - the controls, their validation logic,
                                            requiredSettings, exclusionField, remediation.
      ScubaGearAnalyzerSchema_en-US.json  - productMap (key -> results/config key), friendly
                                            requirement names, named Graph apiOperations, and
                                            the conditionalAccessAnalysis rules (policyState,
                                            exclusionDetectors, scopeGates, displayNameLookup).
      ScubaGearApiCatalog.json            - cmdlet -> Graph REST resource + least scopes.
      ScubaConfigSchema.json              - which controls are configurable via exclusions.
    The $script:ScA* caches at the top of this file are filled from these at runtime by the
    Import-ScA* functions; everything below is just an interpreter over that JSON.

    ----------------------------------------------------------------------------------
    OUTPUT CONTRACT (what the two entry points return - the UI depends on this shape)
    ----------------------------------------------------------------------------------
      MetaData = @{ DisplayName; Organization; TenantId; ScanDate; ResultsPath }
      Summary  = @{ Passes; Failures; Warnings; Errors; Manual; Total; ComplianceRate }
      Products = @('aad', ...)
      Findings = @( <Finding>, ... )
      DisplayNameLookup = @{ '<object id>' = '<display name>' }

      <Finding> (one per analyzed control):
        ControlId 'MS.AAD.3.1v1'; ProductConfigKey 'Aad'; Requirement '...'; Result
        'Fail'|'Warning'|'Pass'|'Error'|'Manual'; Configurable $true/$false;
        ExclusionField 'CapExclusions'|'none'; ConfigAction 'EXCLUDE'|'FIX_TENANT'|...;
        DetectedExclusions @{ Users; Groups; Applications; GuestUserTypes };
        AllPolicies @( <PolicyCandidate> ); BestMatch <PolicyCandidate>|$null;
        SelectedPolicyId; RootCause; Recommendations; RemediationSteps; YamlBlock; ...

      <PolicyCandidate> (one matching Conditional Access policy):
        Id; DisplayName; State; MeetsCriteria; IssueCount; SettingIssueCount;
        ExcludedPrincipalCount; Issues @( 'WARNING: ...|DETAILS:...|SUGGESTION:...' );
        DetectedExclusions @{ Users; Groups; Applications; GuestUserTypes }

.NOTES
    Ported and adapted from the standalone AnalyzeScubaGearResults tool.
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

# ------------------------------------------------------------------------------------
# Analyzer knowledge caches - populated at runtime from ScubaGearAnalyzerSchema_en-US.json
# (product-key map, named Graph operations, Conditional Access condition rules) and
# ScubaGearApiCatalog.json (API resource paths). Nothing product/condition/API specific
# is hardcoded in this module; see Import-ScAAnalyzerRules / Import-ScAApiCatalog.
# ------------------------------------------------------------------------------------
$script:ScAProductMap    = @{}    # prodLower -> @{ ResultsKey; ConfigKey }
$script:ScAApiOperations = @{}    # operation name -> operation definition (from apiOperations)
$script:ScACaRules       = $null  # conditionalAccessAnalysis rules object
$script:ScAApiCatalog    = @{}    # moduleCmdlet -> ScubaGearApiCatalog.json entry
$script:ScAFriendlyNames = $null  # requirement path -> friendly label

function Resolve-ScASchemaPath {
    <#
    .SYNOPSIS
    Resolves the default location of a schema file inside PowerShell/ScubaGear/schemas.
    #>
    param([Parameter(Mandatory)][string]$FileName)

    # This module lives in Modules/ScubaConfigApp/ScubaConfigAnalyzer, so the schemas
    # folder is three levels up.
    $candidate = Join-Path $PSScriptRoot (Join-Path '..\..\..\schemas' $FileName)
    if (Test-Path $candidate) {
        return (Resolve-Path $candidate).Path
    }
    # Fallback: a copy bundled alongside this module (keeps standalone use working).
    $local = Join-Path $PSScriptRoot $FileName
    if (Test-Path $local) {
        return (Resolve-Path $local).Path
    }
    return $candidate
}

function Resolve-ScAConfigSchemaPath {
    <#
    .SYNOPSIS
    Resolves the canonical ScubaGear config schema (Modules/ScubaConfig/ScubaConfigSchema.json),
    the single source of truth for which policies are configurable via exclusions/allow-lists.
    #>
    # Engine lives in Modules/ScubaConfigApp/ScubaConfigAnalyzer -> config schema is two levels up.
    $candidate = Join-Path $PSScriptRoot '..\..\ScubaConfig\ScubaConfigSchema.json'
    if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }
    return $candidate
}

function Import-ScAConfigurableMap {
    <#
    .SYNOPSIS
    Loads per-policy exclusion mappings + product capabilities from the canonical ScubaGear
    config schema so configurability is JSON-driven (never hardcoded). Populates
    $script:ScAConfigurableMap (control id -> supported exclusion types) and
    $script:ScAProductCapabilities. Safe when the schema is missing (empty maps).
    #>
    param([string]$ConfigSchemaPath)

    $script:ScAConfigurableMap     = @{}
    $script:ScAProductCapabilities = @{}
    if (-not $ConfigSchemaPath -or -not (Test-Path $ConfigSchemaPath)) {
        Write-Verbose "Config schema not found - configurability tagging disabled."
        return
    }
    try {
        $meta = (Get-Content $ConfigSchemaPath -Raw | ConvertFrom-Json).schemaMetadata
        if ($meta.policyExclusionMappings) {
            foreach ($p in $meta.policyExclusionMappings.PSObject.Properties) {
                if ($p.Name -notmatch '^_') { $script:ScAConfigurableMap[$p.Name] = @($p.Value) }
            }
        }
        if ($meta.productCapabilities) {
            foreach ($p in $meta.productCapabilities.PSObject.Properties) {
                $script:ScAProductCapabilities[$p.Name] = $p.Value
            }
        }
    } catch {
        Write-Warning "Failed to read config schema '$ConfigSchemaPath': $($_.Exception.Message)"
    }
}

function Import-ScAAnalyzerRules {
    <#
    .SYNOPSIS
    Loads the analyzer rules from ScubaGearAnalyzerSchema_en-US.json into the module caches so
    the engine is a generic interpreter (product-key map, requirement friendly names,
    named Graph operations, and Conditional Access condition rules are all JSON-driven).
    #>
    param([Parameter(Mandatory)]$AnalyzerSchema)

    # Requirement path -> friendly label (supports a 'default' sub-object or a flat map).
    $script:ScAFriendlyNames =
        if ($AnalyzerSchema.RequirementFriendlyNames.default) { $AnalyzerSchema.RequirementFriendlyNames.default }
        elseif ($AnalyzerSchema.RequirementFriendlyNames)     { $AnalyzerSchema.RequirementFriendlyNames }
        else { $null }

    # Product key map (prodLower -> ResultsKey/ConfigKey).
    $script:ScAProductMap = @{}
    if ($AnalyzerSchema.productMap) {
        foreach ($p in $AnalyzerSchema.productMap.PSObject.Properties) {
            if ($p.Name -match '^_') { continue }
            $script:ScAProductMap[$p.Name.ToLower()] = @{ ResultsKey = [string]$p.Value.resultsKey; ConfigKey = [string]$p.Value.configKey; DisplayName = [string]$p.Value.displayName }
        }
    }
    if ($script:ScAProductMap.Count -eq 0) { Write-Warning "Analyzer schema has no 'productMap' - product result/config keys are unavailable." }

    # Named Graph operations (operation name -> definition; resolved to URLs via the API catalog).
    $script:ScAApiOperations = @{}
    if ($AnalyzerSchema.apiOperations) {
        foreach ($op in $AnalyzerSchema.apiOperations.PSObject.Properties) {
            if ($op.Name -match '^_') { continue }
            $script:ScAApiOperations[$op.Name] = $op.Value
        }
    }

    # Conditional Access interpretation rules.
    $script:ScACaRules = $AnalyzerSchema.conditionalAccessAnalysis
}

function Import-ScAApiCatalog {
    <#
    .SYNOPSIS
    Loads ScubaGearApiCatalog.json (moduleCmdlet -> entry) so API resource paths and
    least permissions come from the catalog, never from hardcoded URLs in this module.
    #>
    param([string]$ApiCatalogPath)

    $script:ScAApiCatalog = @{}
    if (-not $ApiCatalogPath) { $ApiCatalogPath = Resolve-ScASchemaPath -FileName 'ScubaGearApiCatalog.json' }
    if (-not (Test-Path $ApiCatalogPath)) { Write-Warning "API catalog not found: $ApiCatalogPath"; return }
    try {
        $catalog = Get-Content $ApiCatalogPath -Raw | ConvertFrom-Json
        foreach ($e in @($catalog)) { if ($e.moduleCmdlet) { $script:ScAApiCatalog[[string]$e.moduleCmdlet] = $e } }
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

    if (-not $script:ScAApiOperations.ContainsKey($Operation)) { return $null }
    $op = $script:ScAApiOperations[$Operation]
    $cmd = [string]$op.cmdlet
    if (-not $cmd -or -not $script:ScAApiCatalog.ContainsKey($cmd)) { return $null }

    $entry    = $script:ScAApiCatalog[$cmd]
    $resource = [string]$entry.apiResource
    if (-not $resource) { return $null }
    $filter = if ($entry.apiFilter) { [string]$entry.apiFilter } else { '' }
    $select = if ($op.select) { '?$select=' + [string]$op.select } else { '' }
    $kind   = if ($op.resultKind) { [string]$op.resultKind } else { 'collection' }

    switch ($kind) {
        'byId' {
            $base = if ($resource -match '\{id\}') { $resource }
                    elseif ($filter -match '\{id\}') { $resource + $filter }
                    else { $resource.TrimEnd('/') + '/{id}' }
            return ($base -replace '\{id\}', $Id) + $select
        }
        'byAppId' {
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
    foreach ($part in ($Path -split '\.')) {
        if ($null -eq $cur) { return $null }
        $prop = $cur.PSObject.Properties | Where-Object { $_.Name -ieq $part } | Select-Object -First 1
        if (-not $prop) { return $null }
        $cur = $prop.Value
    }
    return $cur
}

function Get-ScAConfigAction {
    <#
    .SYNOPSIS
    Decides how (or whether) the ScubaGear config file can make a control pass, using the
    canonical config schema's exclusion mappings. Returns:
      Configurable         - the policy supports config exclusions/allow-lists.
      ConfigExclusionTypes - the exclusion keys it supports (e.g. CapExclusions).
      ConfigAction         - NONE      : passing, nothing to do.
                             EXCLUDE   : config exclusions/allow-lists can make it pass (this
                                         tool builds that YAML).
                             FIX_TENANT: must change the tenant setting (or omit in the Config
                                         App); config exclusions cannot make it pass.
                             REVIEW    : manual/warning/unknown - no automatic YAML.
    This tool only ever generates exclusion/allow-list YAML; it never writes OmitPolicy or
    AnnotatePolicy - those belong to the ScubaGear Config App.
    #>
    param(
        [Parameter(Mandatory)][string]$ControlId,
        [string]$Result,
        [string]$RequiresAction,
        [string]$ValidationType
    )

    $types = @()
    if ($script:ScAConfigurableMap -and $script:ScAConfigurableMap.ContainsKey($ControlId)) {
        $types = @($script:ScAConfigurableMap[$ControlId])
    }
    $configurable = @($types).Count -gt 0

    if ($Result -eq 'Pass' -or $RequiresAction -eq 'NONE') {
        return @{ Configurable = $configurable; ConfigExclusionTypes = $types; ConfigAction = 'NONE' }
    }
    if ($RequiresAction -eq 'CHECK_PERMISSIONS') {
        return @{ Configurable = $configurable; ConfigExclusionTypes = $types; ConfigAction = 'REVIEW' }
    }

    $knownFailure = ($Result -eq 'Fail' -or $Result -eq 'Error')
    if (-not $configurable) {
        $act = if ($knownFailure) { 'FIX_TENANT' } else { 'REVIEW' }
        return @{ Configurable = $false; ConfigExclusionTypes = @(); ConfigAction = $act }
    }
    if (-not $knownFailure) {
        return @{ Configurable = $true; ConfigExclusionTypes = $types; ConfigAction = 'REVIEW' }
    }
    # Configurable + a known failure. For CA, only an exclusion problem is config-fixable;
    # wrong or missing policy settings need a tenant change.
    if ($ValidationType -eq 'conditionalAccessPolicy' -and ($RequiresAction -eq 'FIX_POLICY' -or $RequiresAction -eq 'CREATE_POLICY')) {
        return @{ Configurable = $true; ConfigExclusionTypes = $types; ConfigAction = 'FIX_TENANT' }
    }
    return @{ Configurable = $true; ConfigExclusionTypes = $types; ConfigAction = 'EXCLUDE' }
}

function Get-ScAFriendlyName {
    <#
    .SYNOPSIS
    Returns a human-readable label for a requirement path (from the config schema).
    #>
    param([Parameter(Mandatory)][string]$Path)

    if ($script:ScAFriendlyNames -and ($script:ScAFriendlyNames.PSObject.Properties.Name -contains $Path)) {
        return $script:ScAFriendlyNames.$Path
    }
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
    $clean = ($Text -split '<div')[0]
    $clean = $clean -replace '<[^>]+>', ''
    $clean = [System.Net.WebUtility]::HtmlDecode($clean)
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

    if (-not $BaselineSchema -or -not $BaselineSchema.baselineValidations) { return $null }

    foreach ($product in $BaselineSchema.baselineValidations.PSObject.Properties.Name) {
        $match = $BaselineSchema.baselineValidations.$product | Where-Object { $_.id -eq $ControlId }
        if ($match) { return $match }
    }
    return $null
}

function Test-ScAPolicyRequirement {
    <#
    .SYNOPSIS
    Recursively validates a single requirement path against a policy object.
    Schema paths use camelCase; the policy JSON uses PascalCase.
    #>
    param(
        [Parameter(Mandatory)]$Policy,
        [Parameter(Mandatory)][string]$SchemaPath,
        [Parameter(Mandatory)]$ExpectedValue,
        [Parameter(Mandatory)][string]$FriendlyName
    )

    $issues = @()

    # Map the camelCase schema path to the PascalCase policy path.
    $pathParts = $SchemaPath -split '\.'
    $actualPath = @()
    foreach ($part in $pathParts) {
        $actualPath += ($part.Substring(0, 1).ToUpper() + $part.Substring(1))
    }

    # Navigate to the target property.
    $currentValue = $Policy
    $currentPath = ""
    foreach ($part in $actualPath) {
        $currentPath = if ($currentPath) { "$currentPath.$part" } else { $part }
        if ($null -eq $currentValue) {
            return @{ Meets = $false; Issues = @("ERROR: Property path is null at: $currentPath") }
        }
        if ($currentValue.PSObject.Properties.Name -contains $part) {
            $currentValue = $currentValue.$part
        } else {
            return @{ Meets = $false; Issues = @("Missing required property: $FriendlyName") }
        }
    }

    $meets = $true

    if ($ExpectedValue -is [array]) {
        if ($null -eq $currentValue) {
            return @{ Meets = $false; Issues = @("ERROR: $FriendlyName is null (expected: $($ExpectedValue -join ', '))") }
        }
        $missing = @()
        foreach ($item in $ExpectedValue) {
            if ($currentValue -notcontains $item) { $missing += $item }
        }
        if (@($missing).Count -gt 0) {
            $meets = $false
            $issues += "ERROR: $FriendlyName missing required value(s): $($missing -join ', ')"
        }
    }
    elseif ($ExpectedValue -is [PSCustomObject] -or $ExpectedValue -is [hashtable]) {
        $reqProps = @($ExpectedValue.PSObject.Properties)

        # 'anyOf' expresses ALTERNATIVES: the requirement is met if ANY listed alternative
        # fully matches. Used where a real policy only ever has one of several equivalent
        # settings - e.g. grantControls satisfied by a built-in MFA control OR an MFA
        # authentication strength (the portal makes you pick one, never both).
        $anyOfProp  = $reqProps | Where-Object { $_.Name -eq 'anyOf' } | Select-Object -First 1
        $otherProps = $reqProps | Where-Object { $_.Name -ne 'anyOf' }

        foreach ($prop in $otherProps) {
            $nestedResult = Test-ScAPolicyRequirement -Policy $Policy -SchemaPath "$SchemaPath.$($prop.Name)" -ExpectedValue $prop.Value -FriendlyName "$FriendlyName > $($prop.Name)"
            if (-not $nestedResult.Meets) {
                $meets = $false
                $issues += $nestedResult.Issues
            }
        }

        if ($anyOfProp) {
            $alternatives = @($anyOfProp.Value)
            $anyMatched = $false
            foreach ($alt in $alternatives) {
                $altResult = Test-ScAPolicyRequirement -Policy $Policy -SchemaPath $SchemaPath -ExpectedValue $alt -FriendlyName $FriendlyName
                if ($altResult.Meets) { $anyMatched = $true; break }
            }
            if (-not $anyMatched) {
                $optionNames = @($alternatives | ForEach-Object {
                    (@($_.PSObject.Properties.Name | ForEach-Object { Get-ScAFriendlyName -Path "$SchemaPath.$_" }) -join ' + ')
                })
                $meets = $false
                $issues += "ERROR: $FriendlyName not met - configure one of: $($optionNames -join ' OR ')"
            }
        }
    }
    else {
        if ($currentValue -ne $ExpectedValue) {
            $meets = $false
            $issues += "ERROR: $FriendlyName`: Expected '$ExpectedValue', Found '$currentValue'"
        }
    }

    return @{ Meets = $meets; Issues = $issues }
}

function Test-ScAPolicyRelevance {
    <#
    .SYNOPSIS
    Returns $true if a policy is RELEVANT to a control (i.e. "about" it), per the
    relevanceSignals rules in the analyzer schema. arrayMatch signals overlap the
    requirement + policy arrays (match all|any); the grantControls signal defers to
    Test-ScAGrantControlRelevance but only via the enabled sub-signals. With no rules the
    policy is considered relevant (nothing to filter on).
    #>
    param($Policy, $Requirements, $Rules)

    if (-not $Rules -or -not $Rules.relevanceSignals -or -not $Rules.relevanceSignals.rules) { return $true }

    foreach ($sig in @($Rules.relevanceSignals.rules)) {
        switch ([string]$sig.kind) {
            'arrayMatch' {
                $reqVal = Get-ScAValueAtPath -Object $Requirements -Path $sig.conditionPath
                if ($null -eq $reqVal) { continue }   # requirement doesn't use this signal
                $reqArr = @($reqVal)
                $polArr = @(Get-ScAValueAtPath -Object $Policy -Path $sig.policyPath)
                if ([string]$sig.match -eq 'all') {
                    if (@($reqArr).Count -gt 0) {
                        $all = $true
                        foreach ($t in $reqArr) { if ($polArr -notcontains $t) { $all = $false; break } }
                        if ($all) { return $true }
                    }
                } else {
                    foreach ($t in $reqArr) { if ($polArr -contains $t) { return $true } }
                }
            }
            'grantControls' {
                $gc = Get-ScAValueAtPath -Object $Requirements -Path $sig.conditionPath
                if (-not $gc) { continue }
                $names = @($gc.PSObject.Properties.Name)
                $use = (($names -contains 'anyOf') -and $sig.useWhenAnyOf) -or
                       (($names -contains 'authenticationStrength') -and $sig.useWhenAuthenticationStrength) -or
                       (($names -contains 'builtInControls') -and $sig.useWhenBuiltInControls)
                if ($use -and (Test-ScAGrantControlRelevance -Policy $Policy -GrantReq $gc)) { return $true }
            }
        }
    }
    return $false
}

function Test-ScAPolicyInScope {
    <#
    .SYNOPSIS
    Returns $true unless a scopeGate disqualifies the policy: a gate applies only when the
    requirement demands requiredValue at conditionPath, in which case the policy must also
    have requiredValue at policyPath (persona/admin-scoped policies are dropped).
    #>
    param($Policy, $Requirements, $Rules)

    if (-not $Rules -or -not $Rules.scopeGates -or -not $Rules.scopeGates.rules) { return $true }

    foreach ($gate in @($Rules.scopeGates.rules)) {
        $reqVal = Get-ScAValueAtPath -Object $Requirements -Path $gate.conditionPath
        if ($null -eq $reqVal) { continue }
        if (@($reqVal) -contains $gate.requiredValue) {
            $polVal = @(Get-ScAValueAtPath -Object $Policy -Path $gate.policyPath)
            if ($polVal -notcontains $gate.requiredValue) { return $false }
        }
    }
    return $true
}

function Test-ScAGrantControlRelevance {
    <#
    .SYNOPSIS
    Returns $true if the policy's grant controls make it RELEVANT to a grantControls
    requirement (or ANY of its anyOf alternatives): a matching authentication-strength id,
    or containing the required built-in control(s). This decides whether a policy is
    "about" this control - not whether it fully complies.
    #>
    param($Policy, $GrantReq)
    if (-not $GrantReq) { return $false }
    if ($GrantReq.PSObject.Properties.Name -contains 'anyOf') {
        foreach ($alt in @($GrantReq.anyOf)) {
            if (Test-ScAGrantControlRelevance -Policy $Policy -GrantReq $alt) { return $true }
        }
        return $false
    }
    if ($GrantReq.PSObject.Properties.Name -contains 'authenticationStrength') {
        $reqId = $GrantReq.authenticationStrength.id
        if ($reqId -and $Policy.GrantControls.AuthenticationStrength.Id -eq $reqId) { return $true }
    }
    if ($GrantReq.PSObject.Properties.Name -contains 'builtInControls') {
        $reqControls = @($GrantReq.builtInControls)
        $polControls = @($Policy.GrantControls.BuiltInControls)
        if (@($reqControls).Count -gt 0 -and @($polControls).Count -gt 0) {
            $allPresent = $true
            foreach ($c in $reqControls) { if ($polControls -notcontains $c) { $allPresent = $false; break } }
            if ($allPresent) { return $true }
        }
    }
    return $false
}

function Get-ScAPolicyAnalysis {
    <#
    .SYNOPSIS
    Analyzes conditional access policies for a control and returns relevant policies
    with their validation issues (including detected exclusions).
    .DESCRIPTION
    For every ENABLED Conditional Access policy that is relevant to this control and in
    scope (both decided by the JSON rules), this:
      1. validates each baseline requirement       -> wrong settings become "setting issues";
      2. runs the exclusionDetectors rules to find  -> excluded principals config CAN waive
         become "exclusion issues"; disallowed ones become "errors";
      3. keeps the policy as a candidate, recording its issues + detected exclusions.
    A candidate with zero issues MeetsCriteria (the control already passes via that policy).
    .OUTPUTS
    @{ AllPolicies = @( <PolicyCandidate> ); TotalPoliciesFound = <int> }  e.g.
      @{ TotalPoliciesFound = 1; AllPolicies = @(@{
           DisplayName='Block legacy auth'; Id='...'; State='enabled';
           MeetsCriteria=$false; IssueCount=1; SettingIssueCount=0; ExcludedPrincipalCount=2;
           Issues=@('WARNING: Policy has 2 excluded user(s)|DETAILS:IDs: a,b|SUGGESTION:...');
           DetectedExclusions=@{ Users=@('a','b'); Groups=@(); Applications=@(); GuestUserTypes=@() } }) }
    #>
    param(
        [Parameter(Mandatory)][string]$ControlId,
        [Parameter(Mandatory)]$Results,
        [Parameter(Mandatory)]$ValidationSchema
    )

    # $ControlId is context for diagnostics; the matching itself is driven by $ValidationSchema.
    Write-Verbose "Get-ScAPolicyAnalysis: analyzing Conditional Access policies for control '$ControlId'."

    $allPoliciesData = @()

    if (-not ($Results.Raw.PSObject.Properties.Name -contains 'conditional_access_policies')) {
        return @{ AllPolicies = @(); TotalPoliciesFound = 0 }
    }
    if (-not ($ValidationSchema -and $ValidationSchema.validationLogic.type -eq 'conditionalAccessPolicy')) {
        return @{ AllPolicies = @(); TotalPoliciesFound = 0 }
    }

    $rules          = $script:ScACaRules
    $caPolicies     = $Results.Raw.conditional_access_policies
    $requirements   = $ValidationSchema.validationLogic.requirements
    $exclusionField = if ($ValidationSchema.exclusionField) { [string]$ValidationSchema.exclusionField } else { 'none' }

    $stateProp  = if ($rules -and $rules.policyStateProperty) { [string]$rules.policyStateProperty } else { 'state' }
    $enabledVal = if ($rules -and $rules.enabledStateValue)   { [string]$rules.enabledStateValue }   else { 'enabled' }
    $matchingPolicies = @($caPolicies | Where-Object { (Get-ScAValueAtPath -Object $_ -Path $stateProp) -eq $enabledVal })

    foreach ($policy in $matchingPolicies) {
        $settingIssues   = @()   # requirement failures + disallowed exclusions (need a tenant change)
        $exclusionIssues = @()   # config-waivable exclusions (add to config to pass)
        $detected        = @{ Users = @(); Groups = @(); Applications = @(); GuestUserTypes = @() }
        $excludedCount   = 0

        # 1. Validate each requirement dynamically from the baseline schema.
        foreach ($reqProperty in $requirements.PSObject.Properties) {
            $friendlyName = Get-ScAFriendlyName -Path $reqProperty.Name
            $validationResult = Test-ScAPolicyRequirement -Policy $policy -SchemaPath $reqProperty.Name -ExpectedValue $reqProperty.Value -FriendlyName $friendlyName
            if (-not $validationResult.Meets) { $settingIssues += $validationResult.Issues }
        }

        # 2. Detect config-waivable exclusions, driven by the exclusionDetectors rules
        #    (which config field, which policy path, and when each detector applies).
        foreach ($det in @($rules.exclusionDetectors.rules)) {
            # A detector may only apply to a specific exclusion field (e.g. CapExclusions).
            $typeSupported = (-not $det.requiresExclusionType) -or ($exclusionField -eq [string]$det.requiresExclusionType)

            # Some detectors only fire when the baseline requires a particular scope
            # (e.g. "all users"): skip this detector when that gate isn't met.
            if ($det.scopeRequirement) {
                $reqScope = Get-ScAValueAtPath -Object $requirements -Path $det.scopeRequirement.conditionPath
                if (@($reqScope) -notcontains $det.scopeRequirement.requiredValue) { continue }
            }

            # Read the excluded values from the policy at the detector's path. valueKind
            # 'csvOrArray' means the field may be a comma-separated string OR an array.
            $raw = Get-ScAValueAtPath -Object $policy -Path $det.policyPath
            $vals = if ([string]$det.valueKind -eq 'csvOrArray') {
                if ($raw -is [string]) { @($raw -split '\s*,\s*' | Where-Object { $_ }) } else { @($raw | Where-Object { $_ }) }
            } else {
                @($raw | Where-Object { $_ })
            }
            if (@($vals).Count -eq 0) { continue }   # nothing excluded here -> next detector

            if ($typeSupported) {
                # Config CAN waive these: record them + emit a WARNING (not a hard failure).
                $excludedCount += @($vals).Count
                if ($det.field -and $detected.ContainsKey([string]$det.field)) { $detected[[string]$det.field] += @($vals) }
                $lbl  = if ($det.issueLabel)  { [string]$det.issueLabel }  else { 'item' }
                $dlbl = if ($det.detailLabel) { [string]$det.detailLabel } else { 'IDs' }
                $sug  = if ($det.suggestion)  { [string]$det.suggestion }  else { 'Review if these exclusions are justified and documented' }
                # Pipe-delimited issue string; Format-ScubaAnalyzerIssues (UI) parses this shape.
                $exclusionIssues += "WARNING: Policy has $(@($vals).Count) excluded ${lbl}(s)|DETAILS:${dlbl}: $(@($vals) -join ', ')|SUGGESTION:$sug"
            }
            elseif ($det.unsupportedIsError) {
                # Config CANNOT waive these (e.g. excluded apps on a policy type with no such
                # config key): emit an ERROR so the control is flagged as needing a tenant fix.
                $msg = if ($det.unsupportedMessage) { ([string]$det.unsupportedMessage) -replace '\{values\}', (@($vals) -join ', ') }
                       else { "Policy has disallowed exclusions: $(@($vals) -join ', ')" }
                $settingIssues += "ERROR: $msg"
            }
        }

        $policyIssues  = @($settingIssues) + @($exclusionIssues)
        $meetsCriteria = (@($policyIssues).Count -eq 0)

        # 3. Keep only policies relevant to THIS control and in the required scope
        #    (both are driven by the relevanceSignals / scopeGates rules).
        $hasRelevantConfig = Test-ScAPolicyRelevance -Policy $policy -Requirements $requirements -Rules $rules
        $inScope           = Test-ScAPolicyInScope   -Policy $policy -Requirements $requirements -Rules $rules

        if ($hasRelevantConfig -and $inScope) {
            $allPoliciesData += @{
                DisplayName   = $policy.DisplayName
                Id            = $policy.Id
                State         = (Get-ScAValueAtPath -Object $policy -Path $stateProp)
                MeetsCriteria = $meetsCriteria
                Issues        = $policyIssues
                IssueCount    = @($policyIssues).Count
                SettingIssueCount = @($settingIssues).Count
                ExcludedPrincipalCount = $excludedCount
                DetectedExclusions = @{
                    Users          = @($detected.Users          | Select-Object -Unique)
                    Groups         = @($detected.Groups         | Select-Object -Unique)
                    Applications   = @($detected.Applications   | Select-Object -Unique)
                    GuestUserTypes = @($detected.GuestUserTypes | Select-Object -Unique)
                }
            }
        }
    }

    return @{ AllPolicies = $allPoliciesData; TotalPoliciesFound = @($allPoliciesData).Count }
}

function Build-ScAYamlExclusionsBlock {
    <#
    .SYNOPSIS
    Builds a per-control YAML exclusion block for a single product.
    .DESCRIPTION
    ValueShape 'principal' emits Users:/Groups:/Applications:/GuestUserTypes: sub-lists
    (Conditional Access + role exclusions); 'list' emits a flat list (e.g. allowed
    forwarding domains). Ids are annotated with '# Friendly Name' when DisplayNameLookup
    has them. This is the engine-side twin of the UI's New-ScubaAnalyzerControlYamlText.
    .EXAMPLE
    # ProductConfigKey 'Aad', ControlId 'MS.AAD.3.1v1', ExcludedUsers @('1111....'):
    #   Aad:
    #     # Legacy authentication SHALL be blocked.
    #     MS.AAD.3.1v1:
    #       CapExclusions:
    #         Users:
    #           - 1111....  # Break Glass 1
    #>
    param(
        [Parameter(Mandatory)][string]$ProductConfigKey,
        [Parameter(Mandatory)][string]$ControlId,
        [string]$ExclusionField = 'CapExclusions',
        [AllowEmptyString()][string]$Description = "",
        [array]$ExcludedUsers = @(),
        [array]$ExcludedGroups = @(),
        [array]$ExcludedApplications = @(),
        [array]$ExcludedGuestUserTypes = @(),
        [array]$Values = @(),
        [ValidateSet('principal','list')][string]$ValueShape = 'principal',
        [hashtable]$DisplayNameLookup = @{}
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("$($ProductConfigKey):")
    if ($Description) { [void]$sb.AppendLine("  # $Description") }
    [void]$sb.AppendLine("  $($ControlId):")
    [void]$sb.AppendLine("    $($ExclusionField):")

    if ($ValueShape -eq 'list') {
        # Flat-list fields (e.g. AllowedForwardingDomains, SensitiveUsers, PartnerDomains).
        if (@($Values).Count -gt 0) {
            foreach ($v in $Values) { [void]$sb.AppendLine("      - $v") }
        } else {
            [void]$sb.AppendLine("      # Add the approved entries for $ExclusionField here.")
        }
        return $sb.ToString()
    }

    if (@($ExcludedUsers).Count -gt 0) {
        [void]$sb.AppendLine("      Users:")
        foreach ($id in $ExcludedUsers) {
            $comment = if ($DisplayNameLookup.ContainsKey($id)) { " # $($DisplayNameLookup[$id])" } else { "" }
            [void]$sb.AppendLine("        - $id$comment")
        }
    }
    if (@($ExcludedGroups).Count -gt 0) {
        [void]$sb.AppendLine("      Groups:")
        foreach ($id in $ExcludedGroups) {
            $comment = if ($DisplayNameLookup.ContainsKey($id)) { " # $($DisplayNameLookup[$id])" } else { "" }
            [void]$sb.AppendLine("        - $id$comment")
        }
    }
    if (@($ExcludedApplications).Count -gt 0) {
        [void]$sb.AppendLine("      Applications:")
        foreach ($app in $ExcludedApplications) {
            $comment = if ($DisplayNameLookup.ContainsKey($app)) { " # $($DisplayNameLookup[$app])" } else { "" }
            [void]$sb.AppendLine("        - $app$comment")
        }
    }
    if (@($ExcludedGuestUserTypes).Count -gt 0) {
        [void]$sb.AppendLine("      GuestUserTypes:")
        foreach ($gt in $ExcludedGuestUserTypes) { [void]$sb.AppendLine("        - $gt") }
    }
    if (@($ExcludedUsers).Count -eq 0 -and @($ExcludedGroups).Count -eq 0 -and @($ExcludedApplications).Count -eq 0 -and @($ExcludedGuestUserTypes).Count -eq 0) {
        [void]$sb.AppendLine("      # No exclusions detected. Add Users/Groups/Applications/GuestUserTypes as needed.")
    }

    return $sb.ToString()
}

function Get-ScARootCause {
    <#
    .SYNOPSIS
    Derives a root cause + recommendations from a control result and its policies.
    #>
    param(
        [Parameter(Mandatory)]$Control,
        [Parameter(Mandatory)]$PolicyAnalysis
    )

    $rootCause       = ""
    $requiresAction  = ""
    $recommendations = @()
    $policies        = @($PolicyAnalysis.AllPolicies)
    $hasPolicy       = @($policies).Count -gt 0

    switch ($Control.Result) {
        "Pass" {
            $rootCause = "Compliant"
            $requiresAction = "NONE"
        }
        "Error" {
            if ($Control.Details -like "*conditional access policy*" -or $Control.Details -like "*Get-MgBeta*ConditionalAccessPolicy*") {
                if ($hasPolicy) {
                    $rootCause = "Policy exists but has configuration issues"
                    $requiresAction = "FIX_POLICY"
                } else {
                    $rootCause = "Conditional Access policy missing"
                    $requiresAction = "CREATE_POLICY"
                    $recommendations += "No matching Conditional Access policy exists for this control - create one from scratch."
                }
            } else {
                $rootCause = "Command execution error"
                $requiresAction = "CHECK_PERMISSIONS"
                $recommendations += "Verify Microsoft Graph permissions and connection."
            }
        }
        "Fail" {
            $cls = Get-ScAActionClassification -PolicyAnalysis $PolicyAnalysis
            $rootCause = $cls.RootCause
            $requiresAction = $cls.Action
            if ($requiresAction -eq 'CREATE_POLICY') {
                $recommendations += "No matching Conditional Access policy exists for this control - create one from scratch."
            }
        }
        "Warning" {
            $rootCause = "Partial compliance / best-practice warning"
            $requiresAction = "REVIEW"
        }
        default {
            $rootCause = "Manual review required"
            $requiresAction = "REVIEW"
        }
    }

    # Exclusion-specific guidance.
    $allIssues = @()
    foreach ($p in $policies) { $allIssues += $p.Issues }
    if ($allIssues -match "excluded user") {
        $recommendations += "Review excluded users - if justified (e.g. break-glass), add their IDs to CapExclusions in your ScubaConfig; otherwise remove them from the policy."
    }
    if ($allIssues -match "excluded group") {
        $recommendations += "Review excluded groups - if justified, add their IDs to CapExclusions and document the justification."
    }

    return @{
        RootCause       = $rootCause
        RequiresAction  = $requiresAction
        Recommendations = $recommendations
    }
}

function Invoke-ScubaConfigAnalysis {
    <#
    .SYNOPSIS
    Analyzes a ScubaGear results JSON against the baseline schemas and returns a
    structured findings object.

    .PARAMETER ResultsPath
    Path to a ScubaResults_*.json file produced by Invoke-SCuBA.

    .PARAMETER Product
    One or more products to analyze (default: aad). Only products present in the
    baseline schema produce validation findings.

    .PARAMETER BaselineSchemaPath
    Optional override for ScubaGearResultsBaselineSchema.json.

    .PARAMETER AnalyzerSchemaPath
    Optional override for ScubaGearAnalyzerSchema_en-US.json (friendly display names).

    .PARAMETER IncludePassing
    Include passing controls in the findings (default: only non-passing controls).

    .EXAMPLE
    Invoke-ScubaConfigAnalysis -ResultsPath .\ScubaResults_xxx.json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateScript({ Test-Path $_ -PathType Leaf })][string]$ResultsPath,
        [string[]]$Product = @('aad'),
        [string]$BaselineSchemaPath,
        [string]$AnalyzerSchemaPath,
        [string]$ConfigSchemaPath,
        [switch]$IncludePassing
    )

    if (-not $BaselineSchemaPath) { $BaselineSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearResultsBaselineSchema.json' }
    if (-not $AnalyzerSchemaPath) { $AnalyzerSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearAnalyzerSchema_en-US.json' }
    if (-not $ConfigSchemaPath)   { $ConfigSchemaPath   = Resolve-ScAConfigSchemaPath }

    if (-not (Test-Path $BaselineSchemaPath)) { throw "Baseline schema not found: $BaselineSchemaPath" }
    if (-not (Test-Path $AnalyzerSchemaPath)) { throw "Analyzer schema not found: $AnalyzerSchemaPath" }

    # Load the canonical config schema's exclusion mappings so configurability is JSON-driven.
    Import-ScAConfigurableMap -ConfigSchemaPath $ConfigSchemaPath

    $results        = Get-Content $ResultsPath -Raw | ConvertFrom-Json
    $baselineSchema = Get-Content $BaselineSchemaPath -Raw | ConvertFrom-Json
    $analyzerSchema = Get-Content $AnalyzerSchemaPath -Raw | ConvertFrom-Json

    # Load analyzer rules (product map, friendly names, CA condition rules) from the schema.
    Import-ScAAnalyzerRules -AnalyzerSchema $analyzerSchema

    $findings = @()
    $summary  = @{ Passes = 0; Failures = 0; Warnings = 0; Errors = 0; Manual = 0 }

    foreach ($prod in $Product) {
        $prodLower = $prod.ToLower()
        if (-not $script:ScAProductMap.ContainsKey($prodLower)) {
            Write-Warning "Unknown product '$prod' - skipping."
            continue
        }
        $resultsKey = $script:ScAProductMap[$prodLower].ResultsKey
        $configKey  = $script:ScAProductMap[$prodLower].ConfigKey

        if (-not ($results.Results.PSObject.Properties.Name -contains $resultsKey)) {
            Write-Verbose "No results found for product '$resultsKey' in $ResultsPath."
            continue
        }

        # Accumulate the product summary if present.
        if ($results.Summary.PSObject.Properties.Name -contains $resultsKey) {
            $ps = $results.Summary.$resultsKey
            $summary.Passes   += [int]$ps.Passes
            $summary.Failures += [int]$ps.Failures
            $summary.Warnings += [int]$ps.Warnings
            $summary.Errors   += [int]$ps.Errors
            $summary.Manual   += [int]$ps.Manual
        }

        foreach ($group in $results.Results.$resultsKey) {
            foreach ($control in $group.Controls) {
                $result = $control.Result
                if (-not $IncludePassing -and $result -eq 'Pass') { continue }

                $controlId       = $control.'Control ID'
                $validationSchema = Get-ScAValidationSchema -ControlId $controlId -BaselineSchema $baselineSchema

                $policyAnalysis = if ($validationSchema) {
                    Get-ScAPolicyAnalysis -ControlId $controlId -Results $results -ValidationSchema $validationSchema
                } else {
                    @{ AllPolicies = @(); TotalPoliciesFound = 0 }
                }

                $rootCause = Get-ScARootCause -Control $control -PolicyAnalysis $policyAnalysis

                # Best-match policy = closest to compliant (fewest policy-setting changes, then fewest waivers).
                $sortedPolicies = @($policyAnalysis.AllPolicies | Sort-Object { $_.SettingIssueCount }, { $_.ExcludedPrincipalCount }, { $_.IssueCount })
                $bestMatch      = if (@($sortedPolicies).Count -gt 0) { $sortedPolicies[0] } else { $null }

                $detectedExclusions = if ($bestMatch) {
                    $bestMatch.DetectedExclusions
                } else {
                    @{ Users = @(); Groups = @(); Applications = @(); GuestUserTypes = @() }
                }

                $missingSettings = @()
                foreach ($p in @($policyAnalysis.AllPolicies)) { $missingSettings += $p.Issues }

                $exclusionField = if ($validationSchema -and $validationSchema.exclusionField) { $validationSchema.exclusionField } else { 'none' }
                $remediation    = if ($validationSchema -and $validationSchema.remediationSteps) { @($validationSchema.remediationSteps) } else { @() }
                $requirementTxt = if ($control.Requirement) { $control.Requirement } elseif ($validationSchema) { $validationSchema.name } else { $controlId }
                $requirementTxt = Remove-ScAHtml $requirementTxt

                $vtype      = if ($validationSchema) { $validationSchema.validationLogic.type } else { $null }
                $configInfo = Get-ScAConfigAction -ControlId $controlId -Result $result -RequiresAction $rootCause.RequiresAction -ValidationType $vtype

                # This tool only emits exclusion/allow-list YAML, and only when config can
                # actually make the control pass (ConfigAction = EXCLUDE). The config-schema
                # exclusion type is authoritative for the YAML key (the baseline schema's
                # exclusionField can be stale).
                $effExclusionField = if (@($configInfo.ConfigExclusionTypes).Count -gt 0) { @($configInfo.ConfigExclusionTypes)[0] } elseif ($exclusionField -ne 'none') { $exclusionField } else { $null }
                $yamlBlock = if ($configInfo.ConfigAction -eq 'EXCLUDE' -and $effExclusionField) {
                    $shape = if ($effExclusionField -in @('CapExclusions','RoleExclusions')) { 'principal' } else { 'list' }
                    Build-ScAYamlExclusionsBlock -ProductConfigKey $configKey -ControlId $controlId -ExclusionField $effExclusionField `
                        -Description $requirementTxt -ExcludedUsers @($detectedExclusions.Users) -ExcludedGroups @($detectedExclusions.Groups) `
                        -ExcludedApplications @($detectedExclusions.Applications) -ExcludedGuestUserTypes @($detectedExclusions.GuestUserTypes) -ValueShape $shape
                } else { "" }

                $recommendations = @($rootCause.Recommendations)
                if ($configInfo.ConfigAction -eq 'FIX_TENANT') {
                    $recommendations += "This control can't be made to pass with ScubaGear configuration. Align the tenant setting (see remediation steps), or omit the policy in the ScubaGear Config App (this analyzer does not generate omissions)."
                }

                $findings += [pscustomobject]@{
                    Product            = $prodLower
                    ProductConfigKey   = $configKey
                    ControlId          = $controlId
                    GroupName          = $group.GroupName
                    GroupNumber        = $group.GroupNumber
                    GroupReferenceURL  = $group.GroupReferenceURL
                    Requirement        = $requirementTxt
                    Result             = $result
                    Criticality        = $control.Criticality
                    Details            = (Remove-ScAHtml $control.Details)
                    RootCause          = $rootCause.RootCause
                    RequiresAction     = $rootCause.RequiresAction
                    Recommendations    = @($recommendations)
                    MissingSettings    = @($missingSettings)
                    ExclusionField     = $exclusionField
                    Configurable       = $configInfo.Configurable
                    ConfigExclusionTypes = @($configInfo.ConfigExclusionTypes)
                    ConfigAction       = $configInfo.ConfigAction
                    RemediationSteps   = $remediation
                    AllPolicies        = @($sortedPolicies)
                    BestMatch          = $bestMatch
                    SelectedPolicyId   = if ($bestMatch) { $bestMatch.Id } else { $null }
                    DetectedExclusions = $detectedExclusions
                    YamlBlock          = $yamlBlock
                    HasValidation      = [bool]$validationSchema
                    BuildInstructions  = if ($validationSchema) { $validationSchema.buildInstructions } else { $null }
                    Category           = if ($validationSchema -and $validationSchema.category) { $validationSchema.category } else { $group.GroupName }
                }
            }
        }
    }

    $total = $summary.Passes + $summary.Failures + $summary.Warnings + $summary.Errors + $summary.Manual
    $complianceRate = if ($total -gt 0) { [math]::Round(($summary.Passes / $total) * 100, 1) } else { 0 }

    $scanDate = ""
    if ($results.MetaData.TimestampZulu) {
        try { $scanDate = ([DateTime]$results.MetaData.TimestampZulu).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss") } catch { $scanDate = "$($results.MetaData.TimestampZulu)" }
    }

    return [pscustomobject]@{
        MetaData = [pscustomobject]@{
            DisplayName  = $results.MetaData.DisplayName
            Organization = $results.MetaData.DomainName
            TenantId     = $results.MetaData.TenantId
            ScanDate     = $scanDate
            ResultsPath  = (Resolve-Path $ResultsPath).Path
        }
        Summary = [pscustomobject]@{
            Passes = $summary.Passes; Failures = $summary.Failures; Warnings = $summary.Warnings
            Errors = $summary.Errors; Manual = $summary.Manual; Total = $total; ComplianceRate = $complianceRate
        }
        Products = @($Product | ForEach-Object { $_.ToLower() })
        Findings = @($findings)
        DisplayNameLookup = @{}
    }
}

function Get-ScubaAnalyzerConfigYaml {
    <#
    .SYNOPSIS
    Builds a ScubaGear configuration YAML from analysis findings, including the
    detected (or edited) exclusions. Only controls that support exclusions and have
    at least one exclusion are emitted under each product.

    .PARAMETER Analysis
    The object returned by Invoke-ScubaConfigAnalysis.

    .PARAMETER ExclusionOverrides
    Optional hashtable keyed by control id -> @{ Users=@(); Groups=@() } used to
    override the detected exclusions (from the editable UI lists).

    .PARAMETER M365Environment
    Value for the M365Environment key (default: commercial).

    .PARAMETER DisplayNameLookup
    Optional map of object id -> display name used to emit friendly-name comments.

    .EXAMPLE
    Get-ScubaAnalyzerConfigYaml -Analysis $a -M365Environment commercial
    # Produces a ready-to-use ScubaGear config, e.g.:
    #   # ScubaGear configuration generated by Start-SCuBAConfigAnalyzer
    #   Organization: contoso.onmicrosoft.com
    #   M365Environment: commercial
    #   ProductNames:
    #     - aad
    #
    #   Aad:
    #     # Legacy authentication SHALL be blocked.
    #     # CA policy: Block legacy auth
    #     MS.AAD.3.1v1:
    #       CapExclusions:
    #         Users:
    #           - 1111....  # Break Glass 1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Analysis,
        [hashtable]$ExclusionOverrides = @{},
        [string]$M365Environment = 'commercial',
        [hashtable]$DisplayNameLookup = @{},
        [string]$AppId,
        [string]$CertificateThumbprint,
        [string]$Organization
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# ScubaGear configuration generated by Start-SCuBAConfigAnalyzer")
    [void]$sb.AppendLine("# Tenant: $($Analysis.MetaData.DisplayName)")
    [void]$sb.AppendLine("# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("# Review every exclusion below - only keep entries that are justified (e.g. break-glass accounts).")
    [void]$sb.AppendLine("")
    $org = if ($Analysis.MetaData.Organization) { $Analysis.MetaData.Organization } elseif ($Organization) { $Organization } else { $null }
    if ($org) { [void]$sb.AppendLine("Organization: $org") }
    if ($Analysis.MetaData.DisplayName) { [void]$sb.AppendLine("OrgName: $($Analysis.MetaData.DisplayName)") }
    [void]$sb.AppendLine("M365Environment: $M365Environment")
    if ($AppId -and $CertificateThumbprint) {
        # Non-interactive (service principal) authentication for Invoke-SCuBA.
        [void]$sb.AppendLine("AppID: $AppId")
        [void]$sb.AppendLine("CertificateThumbprint: $CertificateThumbprint")
    }
    [void]$sb.AppendLine("ProductNames:")
    foreach ($p in @($Analysis.Products)) { [void]$sb.AppendLine("  - $p") }
    [void]$sb.AppendLine("")

    # Group findings by product config key.
    $byProduct = @{}
    foreach ($f in @($Analysis.Findings)) {
        if ($f.ExclusionField -eq 'none') { continue }

        $users  = @($f.DetectedExclusions.Users)
        $groups = @($f.DetectedExclusions.Groups)
        $apps   = @($f.DetectedExclusions.Applications)
        $guests = @($f.DetectedExclusions.GuestUserTypes)
        if ($ExclusionOverrides.ContainsKey($f.ControlId)) {
            $ov = $ExclusionOverrides[$f.ControlId]
            if ($ov.ContainsKey('Users'))          { $users  = @($ov.Users) }
            if ($ov.ContainsKey('Groups'))         { $groups = @($ov.Groups) }
            if ($ov.ContainsKey('Applications'))   { $apps   = @($ov.Applications) }
            if ($ov.ContainsKey('GuestUserTypes')) { $guests = @($ov.GuestUserTypes) }
        }
        if (@($users).Count -eq 0 -and @($groups).Count -eq 0 -and @($apps).Count -eq 0 -and @($guests).Count -eq 0) { continue }

        $selId  = [string]$f.SelectedPolicyId
        $selPol = @($f.AllPolicies | Where-Object { [string]$_.Id -eq $selId }) | Select-Object -First 1
        $caName = if ($selPol) { $selPol.DisplayName } elseif ($f.BestMatch) { $f.BestMatch.DisplayName } else { $null }

        if (-not $byProduct.ContainsKey($f.ProductConfigKey)) { $byProduct[$f.ProductConfigKey] = @() }
        $byProduct[$f.ProductConfigKey] += [pscustomobject]@{
            ControlId      = $f.ControlId
            Requirement    = $f.Requirement
            ExclusionField = $f.ExclusionField
            CAPolicyName   = $caName
            Users          = $users
            Groups         = $groups
            Applications   = $apps
            GuestUserTypes = $guests
        }
    }

    if ($byProduct.Keys.Count -eq 0) {
        [void]$sb.AppendLine("# No exclusions were detected. Your tenant did not have excluded users/groups on the analyzed policies,")
        [void]$sb.AppendLine("# or the failing controls require creating/fixing a policy rather than adding exclusions.")
        return $sb.ToString()
    }

    foreach ($productKey in ($byProduct.Keys | Sort-Object)) {
        [void]$sb.AppendLine("$($productKey):")
        foreach ($entry in ($byProduct[$productKey] | Sort-Object ControlId)) {
            [void]$sb.AppendLine("  # $($entry.Requirement)")
            if ($entry.CAPolicyName) { [void]$sb.AppendLine("  # CA policy: $($entry.CAPolicyName)") }
            [void]$sb.AppendLine("  $($entry.ControlId):")
            [void]$sb.AppendLine("    $($entry.ExclusionField):")
            if (@($entry.Users).Count -gt 0) {
                [void]$sb.AppendLine("      Users:")
                foreach ($id in $entry.Users) {
                    $comment = if ($DisplayNameLookup.ContainsKey($id)) { " # $($DisplayNameLookup[$id])" } else { "" }
                    [void]$sb.AppendLine("        - $id$comment")
                }
            }
            if (@($entry.Groups).Count -gt 0) {
                [void]$sb.AppendLine("      Groups:")
                foreach ($id in $entry.Groups) {
                    $comment = if ($DisplayNameLookup.ContainsKey($id)) { " # $($DisplayNameLookup[$id])" } else { "" }
                    [void]$sb.AppendLine("        - $id$comment")
                }
            }
            if (@($entry.Applications).Count -gt 0) {
                [void]$sb.AppendLine("      Applications:")
                foreach ($app in $entry.Applications) {
                    $comment = if ($DisplayNameLookup.ContainsKey($app)) { " # $($DisplayNameLookup[$app])" } else { "" }
                    [void]$sb.AppendLine("        - $app$comment")
                }
            }
            if (@($entry.GuestUserTypes).Count -gt 0) {
                [void]$sb.AppendLine("      GuestUserTypes:")
                foreach ($gt in $entry.GuestUserTypes) { [void]$sb.AppendLine("        - $gt") }
            }
        }
        [void]$sb.AppendLine("")
    }

    return $sb.ToString()
}

# ------------------------------------------------------------------------------------
# Action classification - how to make a Conditional Access control pass ScubaGear
# ------------------------------------------------------------------------------------

function Get-ScAActionClassification {
    <#
    .SYNOPSIS
    Given the analyzed policies for a CA control, decides how to make it pass:
      NONE           - a policy already satisfies the baseline.
      ADD_EXCLUSIONS - a policy meets the settings but excludes users/groups
                       (fix = add those exclusions to the ScubaGear config).
      FIX_POLICY     - the closest (best-match) policy has the wrong settings.
      CREATE_POLICY  - no relevant policy exists; a new one must be created.
    .OUTPUTS
    @{ Result = 'Pass'|'Fail'; Action = 'NONE'|'ADD_EXCLUSIONS'|'FIX_POLICY'|'CREATE_POLICY';
       RootCause = '<plain-English why>' }
    #>
    param([Parameter(Mandatory)]$PolicyAnalysis)

    $policies = @($PolicyAnalysis.AllPolicies)
    # No relevant policy at all -> the tenant must create one.
    if (@($policies).Count -eq 0) {
        return @{ Result = 'Fail'; Action = 'CREATE_POLICY'; RootCause = 'No Conditional Access policy addresses this baseline - create a new one.' }
    }
    # Best match = fewest setting problems, then fewest excluded principals, then fewest issues.
    $best = @($policies | Sort-Object { $_.SettingIssueCount }, { $_.ExcludedPrincipalCount }, { $_.IssueCount })[0]
    # Zero issues -> the control already passes through this policy.
    if ($best.MeetsCriteria) {
        return @{ Result = 'Pass'; Action = 'NONE'; RootCause = 'A Conditional Access policy already satisfies this baseline.' }
    }
    # Settings are correct but principals are excluded -> config can waive it (add exclusions).
    if ($best.SettingIssueCount -eq 0 -and $best.ExcludedPrincipalCount -gt 0) {
        return @{ Result = 'Fail'; Action = 'ADD_EXCLUSIONS'; RootCause = 'The best-matching policy meets this baseline but excludes users/groups/apps/guests. Add them to your config to pass.' }
    }
    # Otherwise the closest policy has wrong settings -> the tenant must fix the policy.
    return @{ Result = 'Fail'; Action = 'FIX_POLICY'; RootCause = 'The best-matching policy needs configuration changes to pass this baseline.' }
}

# ------------------------------------------------------------------------------------
# Live tenant scan (Microsoft Graph) - schema-driven, no ScubaGear run
# ------------------------------------------------------------------------------------

function Get-ScubaAnalyzerScopes {
    <#
    .SYNOPSIS
    Aggregates the Microsoft Graph delegated scopes a product needs, resolved from the API
    catalog: least permissions for every cmdlet named in the baseline schema (apiPermissionRef)
    plus every cmdlet behind a named analyzer apiOperation (CA read, organization, name
    lookups). Fully JSON-driven - the only hardcoded scope is a Directory.Read.All safety net
    used when the catalog cannot be read at all.
    #>
    param(
        [Parameter(Mandatory)][string]$Product,
        [Parameter(Mandatory)]$BaselineSchema,
        [string]$ApiCatalogPath,
        [string]$AnalyzerSchemaPath
    )

    Import-ScAApiCatalog -ApiCatalogPath $ApiCatalogPath
    if ($AnalyzerSchemaPath -and (Test-Path $AnalyzerSchemaPath)) {
        try { Import-ScAAnalyzerRules -AnalyzerSchema (Get-Content $AnalyzerSchemaPath -Raw | ConvertFrom-Json) } catch { Write-Verbose "Analyzer rules load failed (scopes): $($_.Exception.Message)" }
    }

    $prod = $Product.ToLower()
    $cmdlets = @()
    if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $prod) {
        foreach ($c in $BaselineSchema.baselineValidations.$prod) { if ($c.apiPermissionRef) { $cmdlets += $c.apiPermissionRef } }
    }
    # The named operations (CA read, organization, user/group/SP lookups) need scopes too.
    foreach ($op in $script:ScAApiOperations.Values) { if ($op.cmdlet) { $cmdlets += [string]$op.cmdlet } }
    $cmdlets = @($cmdlets | Select-Object -Unique)

    $scopes = New-Object System.Collections.Generic.HashSet[string]
    foreach ($cmd in $cmdlets) {
        $entry = if ($script:ScAApiCatalog.ContainsKey($cmd)) { $script:ScAApiCatalog[$cmd] } else { $null }
        if ($entry -and $entry.leastPermissions) {
            foreach ($p in @($entry.leastPermissions)) { if ($p) { [void]$scopes.Add([string]$p) } }
        }
    }
    if ($scopes.Count -eq 0) { [void]$scopes.Add('Directory.Read.All') }   # safety net when the catalog is unavailable
    return @($scopes)
}

function Connect-ScubaAnalyzerGraph {
    <#
    .SYNOPSIS
    Connects to Microsoft Graph for the given environment. Interactive (delegated scopes)
    by default; if -AppId + -CertificateThumbprint are supplied it uses non-interactive
    app-only certificate auth (application permissions, so -Scopes is ignored). Should be
    called on the UI thread for the interactive path. Returns Get-MgContext.
    #>
    param(
        [string[]]$Scopes = @(),
        [string]$M365Environment = 'commercial',
        [string]$AppId,
        [string]$CertificateThumbprint,
        [string]$Organization
    )

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    $graphEnv = switch ($M365Environment) {
        'gcchigh' { 'USGov' }
        'dod'     { 'USGovDoD' }
        default   { 'Global' }
    }
    $connectParams = @{ Environment = $graphEnv; NoWelcome = $true; ErrorAction = 'Stop' }
    if ($AppId -and $CertificateThumbprint) {
        # App-only (non-interactive) certificate auth uses application permissions, not
        # delegated scopes, so -Scopes is intentionally not passed.
        $connectParams.ClientId = $AppId
        $connectParams.CertificateThumbprint = $CertificateThumbprint
        if ($Organization) { $connectParams.TenantId = $Organization }
    } else {
        $connectParams.Scopes = $Scopes
    }
    Connect-MgGraph @connectParams | Out-Null
    return (Get-MgContext)
}

function Invoke-ScubaGraphGet {
    <#
    .SYNOPSIS
    GETs a Graph resource with Invoke-MgGraphRequest (raw REST, only needs
    Microsoft.Graph.Authentication) and follows @odata.nextLink paging. Returns the
    collected .value items (or the single object for non-collection resources).
    #>
    param([Parameter(Mandatory)][string]$Uri)

    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType PSObject -ErrorAction Stop
        if ($null -eq $resp) { break }
        if ($resp.PSObject.Properties.Name -contains 'value') {
            $items += @($resp.value)
            $next = if ($resp.PSObject.Properties.Name -contains '@odata.nextLink') { $resp.'@odata.nextLink' } else { $null }
        }
        else {
            $items += $resp
            $next = $null
        }
    }
    return $items
}

function Get-ScADisplayNameLookup {
    <#
    .SYNOPSIS
    Best-effort resolve of display names for excluded principals/apps across the given
    Conditional Access policies. Which policy paths to read and which Graph operation resolves
    each are declared in the analyzer schema's displayNameLookup rules (the actual URLs come
    from the API catalog). Returns id -> name to annotate the generated YAML. Requires an
    active Graph connection; per-id failures are ignored.
    #>
    param([array]$Policies = @())

    $lookup = @{}
    $rules = $script:ScACaRules
    if (-not $rules -or -not $rules.displayNameLookup -or -not $rules.displayNameLookup.rules) { return $lookup }
    $guidRe = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

    foreach ($rule in @($rules.displayNameLookup.rules)) {
        $ids = @()
        foreach ($p in @($Policies)) { $ids += @(Get-ScAValueAtPath -Object $p -Path $rule.policyPath) }
        $ids = @($ids | Where-Object { $_ -match $guidRe } | Select-Object -Unique)
        if (@($ids).Count -eq 0) { continue }

        $op = if ($script:ScAApiOperations.ContainsKey([string]$rule.operation)) { $script:ScAApiOperations[[string]$rule.operation] } else { $null }
        $nameProps = if ($op -and $op.nameProperties) { @($op.nameProperties) } else { @('displayName') }

        foreach ($id in $ids) {
            $uri = Resolve-ScAApiResource -Operation ([string]$rule.operation) -Id $id
            if (-not $uri) { continue }
            try {
                $o = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject -ErrorAction Stop
                if ($o) {
                    foreach ($np in $nameProps) {
                        $val = ($o.PSObject.Properties | Where-Object { $_.Name -ieq [string]$np } | Select-Object -First 1).Value
                        if ($val) { $lookup[$id] = $val; break }
                    }
                }
            } catch { Write-Verbose "Display-name lookup failed for '$id': $($_.Exception.Message)" }
        }
    }
    return $lookup
}

function Get-ScubaTenantGraphData {
    <#
    .SYNOPSIS
    Reads the live tenant configuration a product's controls need using ONLY Microsoft
    Graph authentication + raw Graph API calls (Invoke-MgGraphRequest). The resource
    path is resolved from the JSON (API catalog 'apiResource' for the cmdlet named in
    the baseline schema's apiPermissionRef, falling back to buildInstructions
    .apiResourceCreate) so the schema stays the single source of truth and can change
    without code edits. Requires an existing Graph connection (Connect-ScubaAnalyzerGraph).

    The REST response is camelCase; the validation engine navigates policy properties
    case-insensitively, so no reshaping is needed.
    #>
    param(
        [Parameter(Mandatory)][string]$Product,
        [Parameter(Mandatory)]$BaselineSchema,
        [string]$ApiCatalogPath,
        [string]$AnalyzerSchemaPath
    )

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    # Load the analyzer rules (named operations) + API catalog so every URL below is
    # resolved from ScubaGearApiCatalog.json rather than hardcoded here.
    if ($AnalyzerSchemaPath -and (Test-Path $AnalyzerSchemaPath)) {
        try { Import-ScAAnalyzerRules -AnalyzerSchema (Get-Content $AnalyzerSchemaPath -Raw | ConvertFrom-Json) } catch { Write-Verbose "Analyzer rules load failed (tenant data): $($_.Exception.Message)" }
    }
    Import-ScAApiCatalog -ApiCatalogPath $ApiCatalogPath

    $data = @{ conditional_access_policies = @(); OrgDisplayName = $null; Organization = $null; TenantId = $null; DisplayNameLookup = @{} }

    $prod = $Product.ToLower()
    $controls = @()
    if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $prod) {
        $controls = @($BaselineSchema.baselineValidations.$prod)
    }

    # Tenant identity + organization (resource resolved from the catalog).
    try { $ctx = Get-MgContext; if ($ctx) { $data.TenantId = $ctx.TenantId } } catch { Write-Verbose "Get-MgContext unavailable: $($_.Exception.Message)" }
    try {
        $orgUri = Resolve-ScAApiResource -Operation 'organization'
        if ($orgUri) {
            $org = @(Invoke-ScubaGraphGet -Uri $orgUri)
            if (@($org).Count -gt 0) {
                $data.OrgDisplayName = $org[0].displayName
                # Organization = the tenant's PRIMARY (default) verified domain, so a custom
                # domain set as primary is used. Fall back to the initial onmicrosoft.com
                # domain, then to the first verified domain.
                $domains = @($org[0].verifiedDomains)
                $primary = @($domains | Where-Object { $_.isDefault -eq $true })
                if (@($primary).Count -eq 0) { $primary = @($domains | Where-Object { $_.isInitial -eq $true }) }
                if (@($primary).Count -eq 0) { $primary = $domains }
                if (@($primary).Count -gt 0) { $data.Organization = $primary[0].name }
            }
        }
    } catch { Write-Verbose "Organization lookup failed: $($_.Exception.Message)" }

    # Conditional Access policies: read only when a control uses the CA operation's cmdlet.
    $caOp = if ($script:ScAApiOperations.ContainsKey('conditionalAccessPolicies')) { $script:ScAApiOperations['conditionalAccessPolicies'] } else { $null }
    $caCmdlet = if ($caOp) { [string]$caOp.cmdlet } else { $null }
    $usesCa = $caCmdlet -and (@($controls | Where-Object { $_.apiPermissionRef -eq $caCmdlet }).Count -gt 0)
    if ($usesCa) {
        $uri = Resolve-ScAApiResource -Operation 'conditionalAccessPolicies'
        if (-not $uri) {
            # Fall back to the baseline's own create-resource for the CA cmdlet if the catalog lacks it.
            $caControl = @($controls | Where-Object { $_.apiPermissionRef -eq $caCmdlet -and $_.buildInstructions.apiResourceCreate })[0]
            if ($caControl) { $uri = $caControl.buildInstructions.apiResourceCreate }
        }
        if ($uri) {
            $data.conditional_access_policies = @(Invoke-ScubaGraphGet -Uri $uri)
            # Resolve display names for excluded principals/apps so the generated YAML can be annotated.
            try { $data.DisplayNameLookup = Get-ScADisplayNameLookup -Policies $data.conditional_access_policies } catch { Write-Verbose "Display-name resolution skipped: $($_.Exception.Message)" }
        }
    }

    return $data
}

function Invoke-ScubaTenantScan {
    <#
    .SYNOPSIS
    Scans the live M365 tenant against the ScubaGear baseline schema and returns the
    same findings object the UI consumes - telling the user, per baseline, how to pass
    ScubaGear (fix the best-match policy, add exclusions, or create a new policy).

    .PARAMETER TenantData
    Optional pre-fetched data (used for testing). When omitted, the tenant is queried
    live via Microsoft Graph (a Graph connection must already exist).
    #>
    [CmdletBinding()]
    param(
        [string[]]$Product = @('aad'),
        [string]$M365Environment = 'commercial',
        [string]$BaselineSchemaPath,
        [string]$AnalyzerSchemaPath,
        [string]$ConfigSchemaPath,
        [hashtable]$TenantData
    )

    # $M365Environment is recorded for context only; the Graph connection that actually uses
    # it is established by the caller (on the UI thread) before this scan runs.
    Write-Verbose "Invoke-ScubaTenantScan: products '$($Product -join ", ")' in environment '$M365Environment'."

    if (-not $BaselineSchemaPath) { $BaselineSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearResultsBaselineSchema.json' }
    if (-not $AnalyzerSchemaPath) { $AnalyzerSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearAnalyzerSchema_en-US.json' }
    if (-not $ConfigSchemaPath)   { $ConfigSchemaPath   = Resolve-ScAConfigSchemaPath }
    if (-not (Test-Path $BaselineSchemaPath)) { throw "Baseline schema not found: $BaselineSchemaPath" }
    if (-not (Test-Path $AnalyzerSchemaPath)) { throw "Analyzer schema not found: $AnalyzerSchemaPath" }

    # Load the canonical config schema's exclusion mappings so configurability is JSON-driven.
    Import-ScAConfigurableMap -ConfigSchemaPath $ConfigSchemaPath

    $baselineSchema = Get-Content $BaselineSchemaPath -Raw | ConvertFrom-Json
    $analyzerSchema = Get-Content $AnalyzerSchemaPath -Raw | ConvertFrom-Json
    # Load analyzer rules (product map, friendly names, CA condition rules) from the schema.
    Import-ScAAnalyzerRules -AnalyzerSchema $analyzerSchema

    $findings = @()
    $summary  = @{ Passes = 0; Failures = 0; Warnings = 0; Errors = 0; Manual = 0 }
    $orgName  = $null; $tenantId = $null; $organization = $null; $displayNameLookup = @{}

    foreach ($prod in $Product) {
        $prodLower = $prod.ToLower()
        if (-not $script:ScAProductMap.ContainsKey($prodLower)) { Write-Warning "Unknown product '$prod' - skipping."; continue }
        if (-not ($baselineSchema.baselineValidations.PSObject.Properties.Name -contains $prodLower)) {
            Write-Warning "No baseline validations for '$prodLower' - skipping."; continue
        }
        $configKey = $script:ScAProductMap[$prodLower].ConfigKey

        $data = if ($TenantData) { $TenantData } else { Get-ScubaTenantGraphData -Product $prodLower -BaselineSchema $baselineSchema }
        if ($data.OrgDisplayName) { $orgName = $data.OrgDisplayName }
        if ($data.Organization) { $organization = $data.Organization }
        if ($data.TenantId) { $tenantId = $data.TenantId }
        if ($data.DisplayNameLookup) { foreach ($k in @($data.DisplayNameLookup.Keys)) { $displayNameLookup[$k] = $data.DisplayNameLookup[$k] } }

        # Wrap the raw CA policies into the shape Get-ScAPolicyAnalysis expects.
        $resultsLike = [pscustomobject]@{
            Raw = [pscustomobject]@{ conditional_access_policies = @($data.conditional_access_policies) }
        }

        foreach ($control in $baselineSchema.baselineValidations.$prodLower) {
            $controlId = $control.id
            $vtype = $control.validationLogic.type

            if ($vtype -eq 'conditionalAccessPolicy') {
                $policyAnalysis = Get-ScAPolicyAnalysis -ControlId $controlId -Results $resultsLike -ValidationSchema $control
                $cls = Get-ScAActionClassification -PolicyAnalysis $policyAnalysis
                $result = $cls.Result; $requiresAction = $cls.Action; $rootCause = $cls.RootCause
            } else {
                $policyAnalysis = @{ AllPolicies = @(); TotalPoliciesFound = 0 }
                $result = 'Manual'; $requiresAction = 'REVIEW'
                $rootCause = 'This baseline is configured outside Conditional Access and needs manual review (see steps).'
            }

            $configInfo = Get-ScAConfigAction -ControlId $controlId -Result $result -RequiresAction $requiresAction -ValidationType $vtype

            switch ($result) {
                'Pass'    { $summary.Passes++ }
                'Fail'    { $summary.Failures++ }
                'Warning' { $summary.Warnings++ }
                default   { $summary.Manual++ }
            }

            $sortedPolicies = @($policyAnalysis.AllPolicies | Sort-Object { $_.SettingIssueCount }, { $_.ExcludedPrincipalCount }, { $_.IssueCount })
            $bestMatch      = if (@($sortedPolicies).Count -gt 0) { $sortedPolicies[0] } else { $null }
            $detectedExclusions = if ($bestMatch) { $bestMatch.DetectedExclusions } else { @{ Users = @(); Groups = @(); Applications = @(); GuestUserTypes = @() } }
            $missingSettings = @()
            foreach ($p in @($policyAnalysis.AllPolicies)) { $missingSettings += $p.Issues }

            $exclusionField = if ($control.exclusionField) { $control.exclusionField } else { 'none' }
            $remediation    = if ($control.remediationSteps) { @($control.remediationSteps) } elseif ($control.buildInstructions.configurationSteps) { @($control.buildInstructions.configurationSteps) } else { @() }
            $requirementTxt = if ($control.name) { $control.name } else { $controlId }
            $criticality    = if ($requirementTxt -match 'SHALL') { 'Shall' } elseif ($requirementTxt -match 'SHOULD') { 'Should' } else { '' }

            # This tool only emits exclusion/allow-list YAML, and only when config can
            # actually make the control pass (ConfigAction = EXCLUDE). The config-schema
            # exclusion type is authoritative for the YAML key.
            $effExclusionField = if (@($configInfo.ConfigExclusionTypes).Count -gt 0) { @($configInfo.ConfigExclusionTypes)[0] } elseif ($exclusionField -ne 'none') { $exclusionField } else { $null }
            $yamlBlock = if ($configInfo.ConfigAction -eq 'EXCLUDE' -and $effExclusionField) {
                $shape = if ($effExclusionField -in @('CapExclusions','RoleExclusions')) { 'principal' } else { 'list' }
                Build-ScAYamlExclusionsBlock -ProductConfigKey $configKey -ControlId $controlId -ExclusionField $effExclusionField `
                    -Description $requirementTxt -ExcludedUsers @($detectedExclusions.Users) -ExcludedGroups @($detectedExclusions.Groups) `
                    -ExcludedApplications @($detectedExclusions.Applications) -ExcludedGuestUserTypes @($detectedExclusions.GuestUserTypes) -ValueShape $shape
            } else { "" }

            $recommendations = @()
            switch ($requiresAction) {
                'ADD_EXCLUSIONS' { $recommendations += "Add the excluded users/groups below to your ScubaGear config so this baseline passes." }
                'FIX_POLICY'     { $recommendations += "Update the best-match policy so its settings match the baseline requirement, then re-scan." }
                'CREATE_POLICY'  { $recommendations += "Create a new Conditional Access policy as described below, then re-scan." }
            }
            if ($configInfo.ConfigAction -eq 'FIX_TENANT') {
                $recommendations += "This control can't be made to pass with ScubaGear configuration. Align the tenant setting, or omit the policy in the ScubaGear Config App (this analyzer does not generate omissions)."
            }

            $findings += [pscustomobject]@{
                Product            = $prodLower
                ProductConfigKey   = $configKey
                ControlId          = $controlId
                GroupName          = if ($control.category) { $control.category } else { '' }
                GroupNumber        = ''
                GroupReferenceURL  = ''
                Requirement        = $requirementTxt
                Result             = $result
                Criticality        = $criticality
                Details            = if ($vtype -eq 'conditionalAccessPolicy') { "Live scan of Conditional Access policies (via $($control.apiPermissionRef))." } else { "Validation type '$vtype' - manual review." }
                RootCause          = $rootCause
                RequiresAction     = $requiresAction
                Recommendations    = @($recommendations)
                MissingSettings    = @($missingSettings)
                ExclusionField     = $exclusionField
                Configurable       = $configInfo.Configurable
                ConfigExclusionTypes = @($configInfo.ConfigExclusionTypes)
                ConfigAction       = $configInfo.ConfigAction
                RemediationSteps   = $remediation
                AllPolicies        = @($sortedPolicies)
                BestMatch          = $bestMatch
                SelectedPolicyId   = if ($bestMatch) { $bestMatch.Id } else { $null }
                DetectedExclusions = $detectedExclusions
                YamlBlock          = $yamlBlock
                HasValidation      = $true
                BuildInstructions  = $control.buildInstructions
                Category           = if ($control.category) { $control.category } else { '' }
            }
        }
    }

    $total = $summary.Passes + $summary.Failures + $summary.Warnings + $summary.Errors + $summary.Manual
    $complianceRate = if ($total -gt 0) { [math]::Round(($summary.Passes / $total) * 100, 1) } else { 0 }

    return [pscustomobject]@{
        MetaData = [pscustomobject]@{
            DisplayName  = if ($orgName) { $orgName } elseif ($tenantId) { "Tenant $tenantId" } else { "M365 tenant" }
            Organization = $organization
            TenantId     = $tenantId
            ScanDate     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            ResultsPath  = $null
        }
        Summary = [pscustomobject]@{
            Passes = $summary.Passes; Failures = $summary.Failures; Warnings = $summary.Warnings
            Errors = $summary.Errors; Manual = $summary.Manual; Total = $total; ComplianceRate = $complianceRate
        }
        Products = @($Product | ForEach-Object { $_.ToLower() })
        Findings = @($findings)
        DisplayNameLookup = $displayNameLookup
    }
}

Export-ModuleMember -Function @(
    'Invoke-ScubaConfigAnalysis',
    'Invoke-ScubaTenantScan',
    'Get-ScubaTenantGraphData',
    'Connect-ScubaAnalyzerGraph',
    'Get-ScubaAnalyzerScopes',
    'Get-ScubaAnalyzerConfigYaml'
)
