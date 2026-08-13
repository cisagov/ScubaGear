<#
.SYNOPSIS
    Analyzer helper: schema-driven provider analysis (non-CA exclusion detection).
.NOTES
    Imported (Import-Module) by Start-SCuBAConfigAnalyzer alongside the other analyzer
    helpers. Shared analyzer state lives on the synchronized $syncHash ($syncHash.ScA*), so
    every helper module reads/writes the same caches (mirrors how ScubaConfigApp shares
    state). Populated at scan time by Import-ScA*.
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

function Test-ScAFlagCondition {
    <#
    .SYNOPSIS
    Evaluates a schema-declared flagWhen condition against one provider item so detection
    logic lives in the analyzer schema, not the engine. New provider/exclusion types are
    added by editing the schema only - no psm1 change - as long as they use these operators.
    .DESCRIPTION
    Operators (all read the item value at 'path' unless noted):
      equals / notEquals   - scalar compare (JSON true/false/number/string).
      exists               - true = value present & non-empty; false = absent/empty.
      in / notIn           - membership against a schema array.
      greaterThan/lessThan - numeric compare.
      matches              - regex match on the value.
      contains             - value is a member of the item's array (or substring).
    Combinators: allOf (every sub-condition) and anyOf (at least one). Both nest.
    #>
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)]$Condition
    )

    $names = @($Condition.PSObject.Properties.Name)

    if ($names -contains 'allOf') {
        foreach ($sub in @($Condition.allOf)) { if (-not (Test-ScAFlagCondition -Item $Item -Condition $sub)) { return $false } }
        return $true
    }
    if ($names -contains 'anyOf') {
        foreach ($sub in @($Condition.anyOf)) { if (Test-ScAFlagCondition -Item $Item -Condition $sub) { return $true } }
        return $false
    }

    $actual = if ($names -contains 'path') { Get-ScAValueAtPath -Object $Item -Path ([string]$Condition.path) } else { $null }

    foreach ($op in $names) {
        switch ($op) {
            'path'        { }
            'equals'      { if ($actual -ne $Condition.equals) { return $false } }
            'notEquals'   { if ($actual -eq $Condition.notEquals) { return $false } }
            'exists'      { $has = ($null -ne $actual -and [string]$actual -ne ''); if ($has -ne [bool]$Condition.exists) { return $false } }
            'in'          { if (@($Condition.in) -notcontains $actual) { return $false } }
            'notIn'       { if (@($Condition.notIn) -contains $actual) { return $false } }
            'greaterThan' { if (-not ($actual -gt $Condition.greaterThan)) { return $false } }
            'lessThan'    { if (-not ($actual -lt $Condition.lessThan)) { return $false } }
            'matches'     { if ($actual -notmatch [string]$Condition.matches) { return $false } }
            'contains'    { if (@($actual) -notcontains $Condition.contains) { return $false } }
            default       { Write-Verbose "Unknown flagWhen operator '$op' - ignored." }
        }
    }
    return $true
}

function Get-ScAProviderAnalysis {
    <#
    .SYNOPSIS
    Schema-driven analysis for a non-Conditional-Access exclusion type (the sibling of
    Get-ScAPolicyAnalysis). The analysis is defined ON the exclusion type itself, under
    exclusionDefinitions.<field>.analysis, so a control is tied to its detection logic
    purely through the config-schema exclusion mapping - no engine change to add a type.
    Reads the raw provider data (Raw.<rawKey> offline, or the same shape fetched live),
    applies the detectors, and returns the candidate exclusion values.
    .OUTPUTS
    @{ ItemCount; Flagged=@(); ExclusionValues=[ordered]@{ <field> = @(values) }; Issues=@() }
    Returns $null when the exclusion type has no analysis section.
    #>
    param(
        [Parameter(Mandatory)][string]$ExclusionField,
        [Parameter(Mandatory)]$Raw
    )

    if (-not $syncHash.ScAExclusionDefinitions.ContainsKey($ExclusionField)) { return $null }
    $def = $syncHash.ScAExclusionDefinitions[$ExclusionField]
    if (-not $def.analysis) { return $null }
    $an = $def.analysis

    $rawKey = [string]$an.rawKey
    $items  = @()
    if ($Raw -and ($Raw.PSObject.Properties.Name -contains $rawKey)) { $items = @($Raw.$rawKey) }

    $exclusionValues = [ordered]@{}
    $flagged = @()
    $issues  = @()

    foreach ($det in @($an.detectors)) {
        # A detector may target a different field than the exclusion type (rare); default to it.
        $key = if ($det.field) { [string]$det.field } else { $ExclusionField }
        foreach ($item in @($items)) {
            if ($det.flagWhen -and -not (Test-ScAFlagCondition -Item $item -Condition $det.flagWhen)) { continue }

            # valueFrom may resolve to a scalar or an array (e.g. TargetedUsersToProtect).
            $resolved = Get-ScAValueAtPath -Object $item -Path ([string]$det.valueFrom)
            foreach ($value in @($resolved)) {
                if ($null -eq $value -or [string]$value -eq '') { continue }
                if (-not $exclusionValues.Contains($key)) { $exclusionValues[$key] = @() }
                $exclusionValues[$key] += [string]$value
                $flagged += [string]$value

                $lbl = if ($det.issueLabel) { [string]$det.issueLabel } else { 'item' }
                $sug = if ($det.suggestion) { [string]$det.suggestion } else { 'Review whether this exclusion is justified.' }
                $issues += "WARNING: $lbl`: $value|SUGGESTION:$sug"
            }
        }
    }

    foreach ($k in @($exclusionValues.Keys)) { $exclusionValues[$k] = @($exclusionValues[$k] | Select-Object -Unique) }

    return @{
        ItemCount       = @($items).Count
        Flagged         = @($flagged | Select-Object -Unique)
        ExclusionValues = $exclusionValues
        Issues          = $issues
    }
}

function Get-ScAConfiguredExclusionValues {
    <#
    .SYNOPSIS
    Reads the exclusions already present in the imported ScubaResults' applied config
    (Raw.scuba_config.<ProductConfigKey>.<ControlId>.<ExclusionField>) so the analyzer can
    surface what is already configured - not just what it detects from tenant data.
    List-shape fields are a flat array; principal-shape fields are an object of named lists.
    .OUTPUTS
    [ordered]@{ <field> = @(values) } (empty when nothing is configured for the control).
    #>
    param(
        [Parameter(Mandatory)]$Raw,
        [Parameter(Mandatory)][string]$ProductConfigKey,
        [Parameter(Mandatory)][string]$ControlId,
        [Parameter(Mandatory)][string]$ExclusionField
    )

    $out = [ordered]@{}
    if (-not $Raw -or -not ($Raw.PSObject.Properties.Name -contains 'scuba_config')) { return $out }
    $cfg = $Raw.scuba_config
    if (-not $cfg -or -not ($cfg.PSObject.Properties.Name -contains $ProductConfigKey)) { return $out }
    $prod = $cfg.$ProductConfigKey
    if (-not $prod -or -not ($prod.PSObject.Properties.Name -contains $ControlId)) { return $out }
    $ctl = $prod.$ControlId
    if (-not $ctl -or -not ($ctl.PSObject.Properties.Name -contains $ExclusionField)) { return $out }
    $val = $ctl.$ExclusionField

    $schema = if ($syncHash.ScAExclusionDefinitions.ContainsKey($ExclusionField)) { $syncHash.ScAExclusionDefinitions[$ExclusionField] } else { $null }
    $shape  = if ($schema -and $schema.valueShape) { [string]$schema.valueShape } else { 'list' }

    if ($shape -eq 'list') {
        $list = @($val | Where-Object { $_ })
        if (@($list).Count -gt 0) { $out[$ExclusionField] = $list }
    } else {
        foreach ($p in @($val.PSObject.Properties)) {
            $items = @($p.Value | Where-Object { $_ })
            if (@($items).Count -gt 0) { $out[$p.Name] = @($items) }
        }
    }
    return $out
}

