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
    # Initialize the list of exclusion types for the given control.
    if ($syncHash.ScAConfigurableMap -and $syncHash.ScAConfigurableMap.ContainsKey($ControlId)) {
        $types = @($syncHash.ScAConfigurableMap[$ControlId])
    }
    $configurable = @($types).Count -gt 0

    # Determine if the control is configurable based on the presence of exclusion types.
    if ($Result -eq 'Pass' -or $RequiresAction -eq 'NONE') {
        return @{ Configurable = $configurable; ConfigExclusionTypes = $types; ConfigAction = 'NONE' }
    }

    # If the result is a known failure and the control is configurable, determine the appropriate config action.
    if ($RequiresAction -eq 'CHECK_PERMISSIONS') {
        return @{ Configurable = $configurable; ConfigExclusionTypes = $types; ConfigAction = 'REVIEW' }
    }

    # Determine if the result represents a known failure.
    $knownFailure = ($Result -eq 'Fail' -or $Result -eq 'Error')

    # If the control is not configurable, determine the appropriate action based on the known failure status.
    if (-not $configurable) {
        $act = if ($knownFailure) { 'FIX_TENANT' } else { 'REVIEW' }
        return @{ Configurable = $false; ConfigExclusionTypes = @(); ConfigAction = $act }
    }
    # If the control is configurable but the result is not a known failure, the appropriate action is to review.
    if (-not $knownFailure) {
        return @{ Configurable = $true; ConfigExclusionTypes = $types; ConfigAction = 'REVIEW' }
    }
    # If the control is configurable and the result is a known failure, determine the appropriate action.
    # For CA, only an exclusion problem is config-fixable; wrong or missing policy settings need a tenant change.
    if ($ValidationType -eq 'conditionalAccessPolicy' -and ($RequiresAction -eq 'FIX_POLICY' -or $RequiresAction -eq 'CREATE_POLICY')) {
        return @{ Configurable = $true; ConfigExclusionTypes = $types; ConfigAction = 'FIX_TENANT' }
    }

    # If none of the above conditions are met, the default action for a configurable control with a known failure is to exclude.
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
    # Look up the exclusion field schema in the caller-supplied definitions or the global script-scoped definitions.
    if ($ExclusionDefinitions.ContainsKey($ExclusionField)) {
        $schema = $ExclusionDefinitions[$ExclusionField]
    } elseif ($syncHash.ScAExclusionDefinitions.ContainsKey($ExclusionField)) {
        $schema = $syncHash.ScAExclusionDefinitions[$ExclusionField]
    }

    # If no schema was found, return an empty array as there are no field definitions to provide.
    if ($schema -and $schema.fields) {
        return @($schema.fields)
    }

    # Return an empty array if no field definitions are available.
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

    # Initialize the StringBuilder for constructing the YAML exclusion block.
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("$($ProductConfigKey):")
    if ($Description) { [void]$sb.AppendLine("  # $Description") }
    [void]$sb.AppendLine("  $($ControlId):")
    [void]$sb.AppendLine("    $($ExclusionField):")

    # Look up the exclusion field schema in the caller-supplied definitions or the global script-scoped definitions.
    $schema = if ($ExclusionDefinitions.ContainsKey($ExclusionField)) {
        $ExclusionDefinitions[$ExclusionField]
    } elseif ($syncHash.ScAExclusionDefinitions.ContainsKey($ExclusionField)) {
        $syncHash.ScAExclusionDefinitions[$ExclusionField]
    } else {
        $null
    }

    # Determine the effective shape of the exclusion values based on the schema.
    $effectiveShape = if ($schema -and $schema.valueShape) { [string]$schema.valueShape } else { $null }

    # Values come only from the caller-supplied, schema-keyed exclusion map.
    $mergedValues = [ordered]@{}
    foreach ($key in @($ExclusionValues.Keys)) {
        if ($null -ne $ExclusionValues[$key] -and @($ExclusionValues[$key]).Count -gt 0) {
            # Add the non-null, non-empty exclusion values to the merged values collection.
            $mergedValues[$key] = @($ExclusionValues[$key])
        }
    }

    # If the effective shape is a list, handle it separately to generate the appropriate YAML structure.
    if ($effectiveShape -eq 'list') {
        $listEntries = @()
        if ($schema -and $schema.fieldName) {
            $fieldName = [string]$schema.fieldName
            # Retrieve the list of exclusion values for the specified field name, if any.
            if ($mergedValues.Contains($fieldName)) { $listEntries = @($mergedValues[$fieldName]) }
        }

        # Initialize the list of entries for the YAML block.
        if (@($listEntries).Count -gt 0) {
            foreach ($v in @($listEntries)) { [void]$sb.AppendLine("      - $v") }
        } else {
            [void]$sb.AppendLine("      # Add the approved entries for $ExclusionField here.")
        }

        # Return the constructed YAML block for the list-shaped exclusion field.
        return $sb.ToString()
    }

    # Retrieve the field definitions for the current exclusion field.
    $fieldDefs = Get-ScAExclusionFieldDefinitions -ExclusionField $ExclusionField -ExclusionDefinitions $ExclusionDefinitions
    $didEmit = $false

    # Initialize a flag to track whether any YAML entries have been emitted for the current exclusion field.
    foreach ($fieldDef in $fieldDefs) {
        $fieldName = if ($fieldDef.value) { [string]$fieldDef.value } else { [string]$fieldDef.name }
        $fieldList = @()
        if ($mergedValues.Contains($fieldName)) { $fieldList = @($mergedValues[$fieldName]) }
        if (@($fieldList).Count -eq 0) { continue }

        $didEmit = $true
        # Emit the YAML entry for the current field name.
        [void]$sb.AppendLine("      $($fieldName):")
        # Iterate over each item in the field list and append it to the YAML block with appropriate comments.
        foreach ($item in @($fieldList)) {
            $key = [string]$item
            $comment = if ($DisplayNameLookup.ContainsKey($key)) { " # $($DisplayNameLookup[$key])" } else { "" }
            [void]$sb.AppendLine("        - $item$comment")
        }
    }

    # If no YAML entries were emitted for the current exclusion field, provide a default hint for the user.
    if (-not $didEmit) {
        # Construct a default hint for the user based on the available field definitions.
        $defaultHint = if ($fieldDefs.Count -gt 0) { @($fieldDefs | ForEach-Object { $_.value }) -join '/' } else { $ExclusionField }
        [void]$sb.AppendLine("      # No exclusions detected. Add $defaultHint as needed.")
    }

    # Return the final YAML block for the current exclusion field.
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

    # Initialize variables to store the root cause, required action, and recommendations for the control.
    $rootCause       = ""
    $requiresAction  = ""
    $recommendations = @()
    $policies        = @($PolicyAnalysis.AllPolicies)
    $hasPolicy       = @($policies).Count -gt 0

    # Determine the root cause and required action based on the control's result.
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
    # Aggregate all issues from the policies to check for exclusions.
    foreach ($p in $policies) { $allIssues += $p.Issues }
    # At this point, $allIssues contains all issues from all policies, which will be used to determine if any exclusions are present.
    if ($allIssues -match "excluded user") {
        $recommendations += "Review excluded users - if justified (e.g. break-glass), add their IDs to CapExclusions in your ScubaConfig; otherwise remove them from the policy."
    }
    # Check for excluded users and groups and provide recommendations accordingly.
    if ($allIssues -match "excluded group") {
        $recommendations += "Review excluded groups - if justified, add their IDs to CapExclusions and document the justification."
    }

    # Return the final analysis result, including root cause, required action, and recommendations.
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

    When the analysis came from a results file (Analysis.ImportedConfig, read from
    Raw.scuba_config), the configuration that run used is merged in: its settings,
    OmitPolicy/AnnotatePolicy and product exclusions are kept, and the analyzer's
    exclusions are added to the matching controls.

    .PARAMETER Analysis
    The object returned by Invoke-ScubaConfigAnalysis.

    .PARAMETER ExclusionOverrides
    Optional hashtable keyed by control id -> @{ Users=@(); Groups=@() } used to
    override the detected exclusions (from the editable UI lists).

    .PARAMETER M365Environment
    Value for the M365Environment key (default: the imported config's value, else commercial).

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
        [string]$M365Environment,
        [hashtable]$DisplayNameLookup = @{},
        [string]$AppId,
        [string]$CertificateThumbprint,
        [string]$Organization
    )

    # The configuration the imported results were produced with (Raw.scuba_config), if any.
    # Its settings, omissions, annotations and exclusions are carried into the generated file.
    $imported = if ($Analysis.PSObject.Properties.Name -contains 'ImportedConfig' -and $Analysis.ImportedConfig) { $Analysis.ImportedConfig } else { [ordered]@{} }
    $headerKeys = @('Organization', 'OrgName', 'M365Environment', 'AppID', 'CertificateThumbprint', 'ProductNames')
    $machineKeys = if ($syncHash.ScAMachineSpecificConfigKeys) { @($syncHash.ScAMachineSpecificConfigKeys) } else { @() }
    $productConfigKeys = @($syncHash.ScAProductMap.Values | ForEach-Object { $_.ConfigKey })

    # Initialize the StringBuilder for constructing the YAML configuration output.
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# ScubaGear configuration generated by Start-SCuBAConfigAnalyzer")
    [void]$sb.AppendLine("# Tenant: $($Analysis.MetaData.DisplayName)")
    [void]$sb.AppendLine("# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    if ($imported.Count -gt 0) { [void]$sb.AppendLine("# Includes the settings, omissions, annotations and exclusions from the imported results' configuration.") }
    [void]$sb.AppendLine("# Review every exclusion below - only keep entries that are justified (e.g. break-glass accounts).")
    [void]$sb.AppendLine("")
    # The imported config wins for Organization/OrgName (that is what the user ran with);
    # otherwise fall back to the tenant metadata.
    $org = if ($imported.Contains('Organization')) { $imported['Organization'] } elseif ($Analysis.MetaData.Organization) { $Analysis.MetaData.Organization } elseif ($Organization) { $Organization } else { $null }
    if ($org) { [void]$sb.AppendLine("Organization: $(Format-ScAYamlScalar $org)") }
    $orgName = if ($imported.Contains('OrgName')) { $imported['OrgName'] } elseif ($Analysis.MetaData.DisplayName) { $Analysis.MetaData.DisplayName } else { $null }
    if ($orgName) { [void]$sb.AppendLine("OrgName: $(Format-ScAYamlScalar $orgName)") }
    $environment = if ($M365Environment) { $M365Environment } elseif ($imported.Contains('M365Environment')) { $imported['M365Environment'] } else { 'commercial' }
    [void]$sb.AppendLine("M365Environment: $(Format-ScAYamlScalar $environment)")
    # Include the AppId and CertificateThumbprint in the configuration output if both are provided.
    if ($AppId -and $CertificateThumbprint) {
        # Non-interactive (service principal) authentication for Invoke-SCuBA.
        [void]$sb.AppendLine("AppID: $(Format-ScAYamlScalar $AppId)")
        [void]$sb.AppendLine("CertificateThumbprint: $(Format-ScAYamlScalar $CertificateThumbprint)")
    } else {
        if ($imported.Contains('AppID')) { [void]$sb.AppendLine("AppID: $(Format-ScAYamlScalar $imported['AppID'])") }
        if ($imported.Contains('CertificateThumbprint')) { [void]$sb.AppendLine("CertificateThumbprint: $(Format-ScAYamlScalar $imported['CertificateThumbprint'])") }
    }
    # ProductNames: everything the imported run covered, plus any analyzed product it didn't.
    $productNames = [System.Collections.Generic.List[string]]::new()
    $importedProducts = if ($imported.Contains('ProductNames')) { @($imported['ProductNames']) } else { @() }
    foreach ($p in @($importedProducts) + @($Analysis.Products)) {
        if ($p -and -not ($productNames | Where-Object { $_ -eq [string]$p })) { $productNames.Add([string]$p) }
    }
    [void]$sb.AppendLine("ProductNames:")
    foreach ($p in $productNames) { [void]$sb.AppendLine("  - $(Format-ScAYamlScalar $p)") }

    # Remaining imported top-level settings (e.g. KeepIndividualJSON, OutFolderName), in their original order.
    $machineValues = [ordered]@{}
    $sectionKeys = @()
    foreach ($key in @($imported.Keys)) {
        if ($headerKeys -contains $key) { continue }
        $value = $imported[$key]
        if ($value -is [System.Collections.IDictionary]) { $sectionKeys += $key; continue }
        if ($machineKeys -contains $key) { $machineValues[$key] = $value; continue }
        Add-ScAYamlNode -Builder $sb -Value ([ordered]@{ $key = $value })
    }
    # Paths that only exist on the machine that produced the results stay visible but inactive.
    if ($machineValues.Count -gt 0) {
        [void]$sb.AppendLine("# Paths from the machine that produced the imported results - uncomment and adjust if needed:")
        foreach ($key in @($machineValues.Keys)) {
            $commented = [System.Text.StringBuilder]::new()
            Add-ScAYamlNode -Builder $commented -Value ([ordered]@{ $key = $machineValues[$key] })
            foreach ($line in ($commented.ToString().TrimEnd() -split "`r?`n")) { [void]$sb.AppendLine("# $line") }
        }
    }
    [void]$sb.AppendLine("")

    # Group findings by product config key.
    $byProduct = @{}
    # Iterate through each finding in the analysis to group them by product config key.
    foreach ($f in @($Analysis.Findings)) {
        if (-not $f.ExclusionField -or $f.ExclusionField -eq 'none') { continue }

        # Schema-keyed exclusion values (works for CA principals AND list allow-lists).
        $vals = [ordered]@{}
        # Collect the detected exclusion values for the current finding.
        if ($f.DetectedExclusionValues) {
            foreach ($k in @($f.DetectedExclusionValues.Keys)) {
                if (@($f.DetectedExclusionValues[$k]).Count -gt 0) { $vals[$k] = @($f.DetectedExclusionValues[$k]) }
            }
        }
        # Apply any exclusion overrides for the current finding.
        if ($ExclusionOverrides.ContainsKey($f.ControlId)) {
            $ov = $ExclusionOverrides[$f.ControlId]
            foreach ($k in @($ov.Keys)) { $vals[$k] = @($ov[$k]) }
        }
        # Skip this finding if there are no exclusion values after applying overrides.
        if (@($vals.Keys | Where-Object { @($vals[$_]).Count -gt 0 }).Count -eq 0) { continue }

        # Determine the selected policy and its display name for the current finding.
        $selId  = [string]$f.SelectedPolicyId
        $selPol = @($f.AllPolicies | Where-Object { [string]$_.Id -eq $selId }) | Select-Object -First 1
        $caName = if ($selPol) { $selPol.DisplayName } elseif ($f.BestMatch) { $f.BestMatch.DisplayName } else { $null }

        # Initialize the product config key in the grouping dictionary if it doesn't already exist.
        if (-not $byProduct.ContainsKey($f.ProductConfigKey)) { $byProduct[$f.ProductConfigKey] = @() }
        $byProduct[$f.ProductConfigKey] += [pscustomobject]@{
            ControlId       = $f.ControlId
            Requirement     = $f.Requirement
            ExclusionField  = $f.ExclusionField
            CAPolicyName    = $caName
            ExclusionValues = $vals
        }
    }

    # Imported product sections (Aad, SecuritySuite, Exo, ...) are merged with the analyzer's
    # entries; other imported sections (OmitPolicy, AnnotatePolicy) are written after them.
    $importedProductKeys = @($sectionKeys | Where-Object { $productConfigKeys -contains $_ })
    $otherSectionKeys    = @($sectionKeys | Where-Object { $productConfigKeys -notcontains $_ })

    # If no exclusions were detected or imported for any product, say so.
    if ($byProduct.Keys.Count -eq 0 -and @($importedProductKeys).Count -eq 0) {
        [void]$sb.AppendLine("# No exclusions were detected. Your tenant did not have excludable findings on the analyzed policies,")
        [void]$sb.AppendLine("# or the failing controls require creating/fixing a policy rather than adding exclusions.")
        [void]$sb.AppendLine("")
    }

    # Imported products first (in their original order), then analyzer-only products.
    $productKeys = @($importedProductKeys)
    foreach ($k in ($byProduct.Keys | Sort-Object)) { if ($productKeys -notcontains $k) { $productKeys += $k } }

    foreach ($productKey in $productKeys) {
        $importedControls = if ($imported.Contains($productKey)) { $imported[$productKey] } else { [ordered]@{} }
        $entries = @{}
        foreach ($k in @($byProduct.Keys)) { if ($k -eq $productKey) { foreach ($e in @($byProduct[$k])) { $entries[$e.ControlId] = $e } } }

        $controlIds = @($importedControls.Keys)
        foreach ($id in (@($entries.Keys) | Sort-Object)) { if ($controlIds -notcontains $id) { $controlIds += $id } }

        [void]$sb.AppendLine("$($productKey):")
        foreach ($controlId in $controlIds) {
            $entry = $entries[$controlId]
            $importedFields = $importedControls[$controlId]
            if ($entry) {
                [void]$sb.AppendLine("  # $($entry.Requirement)")
                if ($entry.CAPolicyName) { [void]$sb.AppendLine("  # CA policy: $($entry.CAPolicyName)") }
            }
            if (-not $entry -and $importedFields -isnot [System.Collections.IDictionary]) {
                Add-ScAYamlNode -Builder $sb -Value ([ordered]@{ $controlId = $importedFields }) -Indent 2 -DisplayNameLookup $DisplayNameLookup
                continue
            }
            [void]$sb.AppendLine("  $($controlId):")
            # The analyzer's values for its exclusion field already include what the imported config had.
            if ($entry) { Add-ScAYamlExclusionField -Builder $sb -ExclusionField $entry.ExclusionField -ExclusionValues $entry.ExclusionValues -DisplayNameLookup $DisplayNameLookup }
            if ($importedFields -is [System.Collections.IDictionary]) {
                foreach ($field in @($importedFields.Keys)) {
                    if ($entry -and $field -eq $entry.ExclusionField) { continue }
                    Add-ScAYamlNode -Builder $sb -Value ([ordered]@{ $field = $importedFields[$field] }) -Indent 4 -DisplayNameLookup $DisplayNameLookup
                }
            }
        }
        [void]$sb.AppendLine("")
    }

    foreach ($key in $otherSectionKeys) {
        Add-ScAYamlNode -Builder $sb -Value ([ordered]@{ $key = $imported[$key] }) -DisplayNameLookup $DisplayNameLookup
        [void]$sb.AppendLine("")
    }

    # Return the formatted configuration as a string.
    return $sb.ToString()
}

function Add-ScAYamlExclusionField {
    <#
    .SYNOPSIS
    Appends one control's exclusion field (e.g. CapExclusions) to the full configuration YAML,
    shaped by its exclusion definition (named principal lists or a flat allow-list).
    #>
    param(
        [Parameter(Mandatory)][System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory)][string]$ExclusionField,
        [System.Collections.IDictionary]$ExclusionValues = @{},
        [hashtable]$DisplayNameLookup = @{}
    )

    [void]$Builder.AppendLine("    $($ExclusionField):")

    # Determine the schema and shape for the current exclusion field.
    $schema = if ($syncHash.ScAExclusionDefinitions.ContainsKey($ExclusionField)) { $syncHash.ScAExclusionDefinitions[$ExclusionField] } else { $null }
    $shape  = if ($schema -and $schema.valueShape) { [string]$schema.valueShape } else { 'principal' }

    # Format the exclusion values based on the determined shape.
    if ($shape -eq 'list') {
        $fieldName = if ($schema -and $schema.fieldName) { [string]$schema.fieldName } else { $ExclusionField }
        $list = if ($ExclusionValues.Contains($fieldName)) { @($ExclusionValues[$fieldName]) } else { @() }
        foreach ($v in @($list)) { [void]$Builder.AppendLine("      - $(Format-ScAYamlScalar $v)") }
        return
    }

    foreach ($fieldDef in @(Get-ScAExclusionFieldDefinitions -ExclusionField $ExclusionField)) {
        $fieldName = if ($fieldDef.value) { [string]$fieldDef.value } else { [string]$fieldDef.name }
        $fieldList = if ($ExclusionValues.Contains($fieldName)) { @($ExclusionValues[$fieldName]) } else { @() }
        # Skip this field if there are no exclusion values to display.
        if (@($fieldList).Count -eq 0) { continue }

        [void]$Builder.AppendLine("      $($fieldName):")
        foreach ($item in @($fieldList)) {
            $key = [string]$item
            $comment = if ($DisplayNameLookup.ContainsKey($key)) { " # $($DisplayNameLookup[$key])" } else { "" }
            [void]$Builder.AppendLine("        - $(Format-ScAYamlScalar $item)$comment")
        }
    }
}

