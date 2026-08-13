<#
.SYNOPSIS
    Analyzer helper: exclusion definitions, config-action, and YAML generation.
.NOTES
    Imported (Import-Module) by Start-SCuBAConfigAnalyzer alongside the other analyzer
    helpers. Shared analyzer state lives on the synchronized $syncHash ($syncHash.ScA*), so
    every helper module reads/writes the same caches (mirrors how ScubaConfigApp shares
    state). Populated at scan time by Import-ScA*.
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

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
    if ($syncHash.ScAConfigurableMap -and $syncHash.ScAConfigurableMap.ContainsKey($ControlId)) {
        $types = @($syncHash.ScAConfigurableMap[$ControlId])
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

function Get-ScAExclusionFieldDefinitions {
    <#
    .SYNOPSIS
    Gets the field definitions for a given exclusion field.
    .DESCRIPTION
    Looks up the exclusion field in the provided exclusion definitions or the global script-scoped definitions.
    #>
    param(
        [string]$ExclusionField,
        [hashtable]$ExclusionDefinitions = @{}
    )

    $schema = $null
    if ($ExclusionDefinitions.ContainsKey($ExclusionField)) {
        $schema = $ExclusionDefinitions[$ExclusionField]
    } elseif ($syncHash.ScAExclusionDefinitions.ContainsKey($ExclusionField)) {
        $schema = $syncHash.ScAExclusionDefinitions[$ExclusionField]
    }

    if ($schema -and $schema.fields) {
        return @($schema.fields)
    }

    return @()
}

function Build-ScAYamlExclusionsBlock {
    <#
    .SYNOPSIS
    Builds a per-control YAML exclusion block for a single product.
    .DESCRIPTION
    Uses the exclusion definition metadata in ScubaConfigAnalyzer_Control_en-US.json to
    decide which YAML keys to emit; the default path is a generic compatibility fallback.
    #>
    param(
        [Parameter(Mandatory)][string]$ProductConfigKey,
        [Parameter(Mandatory)][string]$ControlId,
        [string]$ExclusionField = 'CapExclusions',
        [AllowEmptyString()][string]$Description = "",
        [hashtable]$ExclusionValues = @{},
        [hashtable]$ExclusionDefinitions = @{},
        [hashtable]$DisplayNameLookup = @{}
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("$($ProductConfigKey):")
    if ($Description) { [void]$sb.AppendLine("  # $Description") }
    [void]$sb.AppendLine("  $($ControlId):")
    [void]$sb.AppendLine("    $($ExclusionField):")

    $schema = if ($ExclusionDefinitions.ContainsKey($ExclusionField)) {
        $ExclusionDefinitions[$ExclusionField]
    } elseif ($syncHash.ScAExclusionDefinitions.ContainsKey($ExclusionField)) {
        $syncHash.ScAExclusionDefinitions[$ExclusionField]
    } else {
        $null
    }

    $effectiveShape = if ($schema -and $schema.valueShape) { [string]$schema.valueShape } else { $null }

    # Values come only from the caller-supplied, schema-keyed exclusion map.
    $mergedValues = [ordered]@{}
    foreach ($key in @($ExclusionValues.Keys)) {
        if ($null -ne $ExclusionValues[$key] -and @($ExclusionValues[$key]).Count -gt 0) {
            $mergedValues[$key] = @($ExclusionValues[$key])
        }
    }

    if ($effectiveShape -eq 'list') {
        $listEntries = @()
        if ($schema -and $schema.fieldName) {
            $fieldName = [string]$schema.fieldName
            if ($mergedValues.Contains($fieldName)) { $listEntries = @($mergedValues[$fieldName]) }
        }

        if (@($listEntries).Count -gt 0) {
            foreach ($v in @($listEntries)) { [void]$sb.AppendLine("      - $v") }
        } else {
            [void]$sb.AppendLine("      # Add the approved entries for $ExclusionField here.")
        }
        return $sb.ToString()
    }

    $fieldDefs = Get-ScAExclusionFieldDefinitions -ExclusionField $ExclusionField -ExclusionDefinitions $ExclusionDefinitions
    $didEmit = $false
    foreach ($fieldDef in $fieldDefs) {
        $fieldName = if ($fieldDef.value) { [string]$fieldDef.value } else { [string]$fieldDef.name }
        $fieldList = @()
        if ($mergedValues.Contains($fieldName)) { $fieldList = @($mergedValues[$fieldName]) }
        if (@($fieldList).Count -eq 0) { continue }

        $didEmit = $true
        [void]$sb.AppendLine("      $($fieldName):")
        foreach ($item in @($fieldList)) {
            $key = [string]$item
            $comment = if ($DisplayNameLookup.ContainsKey($key)) { " # $($DisplayNameLookup[$key])" } else { "" }
            [void]$sb.AppendLine("        - $item$comment")
        }
    }

    if (-not $didEmit) {
        $defaultHint = if ($fieldDefs.Count -gt 0) { @($fieldDefs | ForEach-Object { $_.value }) -join '/' } else { $ExclusionField }
        [void]$sb.AppendLine("      # No exclusions detected. Add $defaultHint as needed.")
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
            # If the control failed but no relevant policies were found, the root cause is a missing policy.
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
        if (-not $f.ExclusionField -or $f.ExclusionField -eq 'none') { continue }

        # Schema-keyed exclusion values (works for CA principals AND list allow-lists).
        $vals = [ordered]@{}
        if ($f.DetectedExclusionValues) {
            foreach ($k in @($f.DetectedExclusionValues.Keys)) {
                if (@($f.DetectedExclusionValues[$k]).Count -gt 0) { $vals[$k] = @($f.DetectedExclusionValues[$k]) }
            }
        }
        if ($ExclusionOverrides.ContainsKey($f.ControlId)) {
            $ov = $ExclusionOverrides[$f.ControlId]
            foreach ($k in @($ov.Keys)) { $vals[$k] = @($ov[$k]) }
        }
        if (@($vals.Keys | Where-Object { @($vals[$_]).Count -gt 0 }).Count -eq 0) { continue }

        $selId  = [string]$f.SelectedPolicyId
        $selPol = @($f.AllPolicies | Where-Object { [string]$_.Id -eq $selId }) | Select-Object -First 1
        $caName = if ($selPol) { $selPol.DisplayName } elseif ($f.BestMatch) { $f.BestMatch.DisplayName } else { $null }

        if (-not $byProduct.ContainsKey($f.ProductConfigKey)) { $byProduct[$f.ProductConfigKey] = @() }
        $byProduct[$f.ProductConfigKey] += [pscustomobject]@{
            ControlId       = $f.ControlId
            Requirement     = $f.Requirement
            ExclusionField  = $f.ExclusionField
            CAPolicyName    = $caName
            ExclusionValues = $vals
        }
    }

    if ($byProduct.Keys.Count -eq 0) {
        [void]$sb.AppendLine("# No exclusions were detected. Your tenant did not have excludable findings on the analyzed policies,")
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

            $schema = if ($syncHash.ScAExclusionDefinitions.ContainsKey($entry.ExclusionField)) { $syncHash.ScAExclusionDefinitions[$entry.ExclusionField] } else { $null }
            $shape  = if ($schema -and $schema.valueShape) { [string]$schema.valueShape } else { 'principal' }

            if ($shape -eq 'list') {
                $fieldName = if ($schema -and $schema.fieldName) { [string]$schema.fieldName } else { $entry.ExclusionField }
                $list = if ($entry.ExclusionValues.Contains($fieldName)) { @($entry.ExclusionValues[$fieldName]) } else { @() }
                foreach ($v in @($list)) { [void]$sb.AppendLine("      - $v") }
            } else {
                foreach ($fieldDef in @(Get-ScAExclusionFieldDefinitions -ExclusionField $entry.ExclusionField)) {
                    $fieldName = if ($fieldDef.value) { [string]$fieldDef.value } else { [string]$fieldDef.name }
                    $fieldList = if ($entry.ExclusionValues.Contains($fieldName)) { @($entry.ExclusionValues[$fieldName]) } else { @() }
                    if (@($fieldList).Count -eq 0) { continue }

                    [void]$sb.AppendLine("      $($fieldName):")
                    foreach ($item in @($fieldList)) {
                        $key = [string]$item
                        $comment = if ($DisplayNameLookup.ContainsKey($key)) { " # $($DisplayNameLookup[$key])" } else { "" }
                        [void]$sb.AppendLine("        - $item$comment")
                    }
                }
            }
        }
        [void]$sb.AppendLine("")
    }

    return $sb.ToString()
}

