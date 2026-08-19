<#
.SYNOPSIS
    Analysis engine for the ScubaGear Config Analyzer (Start-SCuBAConfigAnalyzer).
.DESCRIPTION
    UI-free analysis engine. Reads a ScubaResults JSON (offline) or the live tenant
    (Graph + Exchange Online REST) and compares raw configuration against the ScubaGear
    baselines described in the JSON schemas, emitting a structured findings object and a
    ready-to-use ScubaGear configuration YAML.

    This module holds the two public entry points. The analyzer helpers are separate modules
    imported alongside it (Get-ChildItem | Import-Module) by Start-SCuBAConfigAnalyzer; shared
    state lives on the synchronized $syncHash ($syncHash.ScA*), mirroring how ScubaConfigApp
    shares state across its helper modules.

    Entry points:
      Invoke-ScubaConfigAnalysis -ResultsPath <file>   OFFLINE: analyze a ScubaResults JSON.
      Invoke-ScubaTenantScan     -Product <p> ...      LIVE: read the tenant (Graph + EXO REST).
    Get-ScubaAnalyzerConfigYaml turns the findings object into a ScubaGear config file.
.NOTES
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

# The shared analyzer caches live on the synchronized $syncHash ($syncHash.ScA*), initialized
# by Start-SCuBAConfigAnalyzer and populated at scan time by Import-ScAAnalyzerRules /
# Import-ScAConfigurableMap. Every analyzer helper module reads/writes them via $syncHash.

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

    .PARAMETER AnalyzerControlPath
    Optional override for ScubaConfigAnalyzer_Control_en-US.json (friendly display names).

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
        [string]$AnalyzerControlPath,
        [string]$ConfigSchemaPath,
        [switch]$IncludePassing
    )

    if (-not $BaselineSchemaPath) { $BaselineSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearResultsBaselineSchema.json' }
    if (-not $AnalyzerControlPath) { $AnalyzerControlPath = Resolve-ScASchemaPath -FileName 'ScubaConfigAnalyzer_Control_en-US.json' }
    if (-not $ConfigSchemaPath)   { $ConfigSchemaPath   = Resolve-ScAConfigSchemaPath }

    if (-not (Test-Path $BaselineSchemaPath)) { throw "Baseline schema not found: $BaselineSchemaPath" }
    if (-not (Test-Path $AnalyzerControlPath)) { throw "Analyzer schema not found: $AnalyzerControlPath" }

    # Load the canonical config schema's exclusion mappings so configurability is JSON-driven.
    Import-ScAConfigurableMap -ConfigSchemaPath $ConfigSchemaPath

    $results        = Get-Content $ResultsPath -Raw | ConvertFrom-Json
    $baselineSchema = Get-Content $BaselineSchemaPath -Raw | ConvertFrom-Json
    $analyzerSchema = Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json

    # Load analyzer rules (product map, friendly names, CA condition rules) from the schema.
    Import-ScAAnalyzerRules -AnalyzerSchema $analyzerSchema

    $findings = @()
    $summary  = @{ Passes = 0; Failures = 0; Warnings = 0; Errors = 0; Manual = 0 }

    foreach ($prod in $Product) {
        $prodLower = $prod.ToLower()
        if (-not $syncHash.ScAProductMap.ContainsKey($prodLower)) {
            Write-Warning "Unknown product '$prod' - skipping."
            continue
        }
        $resultsKey = $syncHash.ScAProductMap[$prodLower].ResultsKey
        $configKey  = $syncHash.ScAProductMap[$prodLower].ConfigKey

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

        # Process each control in each group for this product.
        foreach ($group in $results.Results.$resultsKey) {
            foreach ($control in $group.Controls) {
                $result = $control.Result
                if (-not $IncludePassing -and $result -eq 'Pass') { continue }

                $controlId       = $control.'Control ID'
                $validationSchema = Get-ScAValidationSchema -ControlId $controlId -BaselineSchema $baselineSchema
                $vtype      = if ($validationSchema) { $validationSchema.validationLogic.type } else { $null }

                # The exclusion type this control supports (config-schema mapping first, then
                # the baseline's own exclusionField) selects the analysis to run.
                $candidateExclusionField = $null
                if ($syncHash.ScAConfigurableMap -and $syncHash.ScAConfigurableMap.ContainsKey($controlId) -and @($syncHash.ScAConfigurableMap[$controlId]).Count -gt 0) {
                    $candidateExclusionField = @($syncHash.ScAConfigurableMap[$controlId])[0]
                } elseif ($validationSchema -and $validationSchema.exclusionField -and $validationSchema.exclusionField -ne 'none') {
                    $candidateExclusionField = [string]$validationSchema.exclusionField
                }

                # Non-CA controls are analyzed via the exclusion type's own analysis section
                # (exclusionDefinitions.<field>.analysis); CA controls keep the CA path.
                $providerAnalysis = if ($vtype -ne 'conditionalAccessPolicy' -and $candidateExclusionField) {
                    Get-ScAProviderAnalysis -ExclusionField $candidateExclusionField -Raw $results.Raw
                } else { $null }

                $policyAnalysis = if ($validationSchema -and $vtype -eq 'conditionalAccessPolicy') {
                    Get-ScAPolicyAnalysis -ControlId $controlId -Results $results -ValidationSchema $validationSchema
                } else {
                    @{ AllPolicies = @(); TotalPoliciesFound = 0 }
                }

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

                $baselineExclusionField = if ($validationSchema -and $validationSchema.exclusionField) { $validationSchema.exclusionField } else { 'none' }
                $remediation    = if ($validationSchema -and $validationSchema.remediationSteps) { @($validationSchema.remediationSteps) } elseif ($validationSchema -and $validationSchema.buildInstructions.configurationSteps) { @($validationSchema.buildInstructions.configurationSteps) } else { @() }
                $requirementTxt = if ($control.Requirement) { $control.Requirement } elseif ($validationSchema) { $validationSchema.name } else { $controlId }
                # Remove any HTML tags from the requirement text for cleaner display.
                $requirementTxt = Remove-ScAHtml $requirementTxt

                # Root cause: provider (non-CA) controls get a data-driven, non-CA message;
                # CA controls use the Conditional Access classifier.
                if ($providerAnalysis) {
                    if ($result -eq 'Pass') {
                        $rootCause = @{ RootCause = 'Compliant'; RequiresAction = 'NONE'; Recommendations = @() }
                    } elseif (@($providerAnalysis.Flagged).Count -gt 0) {
                        $rootCause = @{
                            RootCause      = "$(@($providerAnalysis.Flagged).Count) item(s) flagged: $(@($providerAnalysis.Flagged) -join ', ')"
                            RequiresAction = 'EXCLUDE'
                            Recommendations = @('Review the flagged entries below - add approved ones to the exclusion allow-list; otherwise change the tenant setting (see remediation steps).')
                        }
                    } else {
                        $rootCause = @{ RootCause = 'The tenant setting does not meet this baseline.'; RequiresAction = 'FIX_TENANT'; Recommendations = @() }
                    }
                } else {
                    #Get the root cause and recommendations for this control result, based on the policy analysis.
                    $rootCause = Get-ScARootCause -Control $control -PolicyAnalysis $policyAnalysis
                }

                # Determine the config action (EXCLUDE, FIX_TENANT, etc.) and the effective exclusion field.
                $configInfo = Get-ScAConfigAction -ControlId $controlId -Result $result -RequiresAction $rootCause.RequiresAction -ValidationType $vtype

                # A provider control that surfaced candidate values is config-fixable even when
                # it's a SHOULD (Warning): offer the exclusion allow-list with the detected values.
                if ($providerAnalysis -and $candidateExclusionField -and @($providerAnalysis.Flagged).Count -gt 0 -and $result -ne 'Pass') {
                    $configInfo.Configurable = $true
                    $configInfo.ConfigAction = 'EXCLUDE'
                    if (@($configInfo.ConfigExclusionTypes).Count -eq 0) { $configInfo.ConfigExclusionTypes = @($candidateExclusionField) }
                }

                # The config-schema exclusion type is authoritative for the YAML key (the
                # baseline schema's exclusionField can be stale).
                $effExclusionField = if (@($configInfo.ConfigExclusionTypes).Count -gt 0) { @($configInfo.ConfigExclusionTypes)[0] } elseif ($baselineExclusionField -ne 'none') { $baselineExclusionField } else { $null }

                # For non-CA provider controls the exclusion values come from providerAnalysis;
                # for CA controls they come from the detected policy exclusions.
                $exclusionValues = [ordered]@{}
                if ($providerAnalysis) {
                    foreach ($k in @($providerAnalysis.ExclusionValues.Keys)) { $exclusionValues[$k] = @($providerAnalysis.ExclusionValues[$k]) }
                } else {
                    foreach ($k in @($detectedExclusions.Keys)) {
                        $v = $detectedExclusions[$k]
                        if ($null -ne $v -and @($v).Count -gt 0) { $exclusionValues[$k] = @($v) }
                    }
                }

                # Merge in exclusions already present in the imported config (Raw.scuba_config)
                # so an already-configured control still shows its values (even when it passes).
                if ($effExclusionField) {
                    $configured = Get-ScAConfiguredExclusionValues -Raw $results.Raw -ProductConfigKey $configKey -ControlId $controlId -ExclusionField $effExclusionField
                    foreach ($k in @($configured.Keys)) {
                        $merged = @()
                        if ($exclusionValues.Contains($k)) { $merged += @($exclusionValues[$k]) }
                        $merged += @($configured[$k])
                        $exclusionValues[$k] = @($merged | Select-Object -Unique)
                    }
                }

                $hasExclusionValues = (@($exclusionValues.Keys | Where-Object { @($exclusionValues[$_]).Count -gt 0 }).Count -gt 0)
                # Emit the block when config exclusions apply OR any values exist (detected or
                # already-configured), so passing-with-config controls still show their YAML.
                $yamlBlock = if ($effExclusionField -and ($configInfo.ConfigAction -eq 'EXCLUDE' -or $hasExclusionValues)) {
                    Build-ScAYamlExclusionsBlock -ProductConfigKey $configKey -ControlId $controlId -ExclusionField $effExclusionField `
                        -Description $requirementTxt -ExclusionValues $exclusionValues -ExclusionDefinitions $syncHash.ScAExclusionDefinitions
                } else { "" }

                # Surface the effective exclusion field on the finding so the UI shows the
                # right block instead of 'none' when config exclusions apply.
                $exclusionField = if ($effExclusionField -and ($configInfo.ConfigAction -eq 'EXCLUDE' -or $hasExclusionValues)) { $effExclusionField } else { $baselineExclusionField }

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
                    DetectedExclusionValues = $exclusionValues
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
        ConditionalAccessPolicies = @($results.Raw.conditional_access_policies)
        DisplayNameLookup = @{}
    }
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
        [string]$AnalyzerControlPath,
        [string]$ConfigSchemaPath,
        [hashtable]$TenantData
    )

    # $M365Environment is recorded for context only; the Graph connection that actually uses
    # it is established by the caller (on the UI thread) before this scan runs.
    Write-Verbose "Invoke-ScubaTenantScan: products '$($Product -join ", ")' in environment '$M365Environment'."

    if (-not $BaselineSchemaPath) { $BaselineSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearResultsBaselineSchema.json' }
    if (-not $AnalyzerControlPath) { $AnalyzerControlPath = Resolve-ScASchemaPath -FileName 'ScubaConfigAnalyzer_Control_en-US.json' }
    if (-not $ConfigSchemaPath)   { $ConfigSchemaPath   = Resolve-ScAConfigSchemaPath }
    if (-not (Test-Path $BaselineSchemaPath)) { throw "Baseline schema not found: $BaselineSchemaPath" }
    if (-not (Test-Path $AnalyzerControlPath)) { throw "Analyzer schema not found: $AnalyzerControlPath" }

    # Load the canonical config schema's exclusion mappings so configurability is JSON-driven.
    Import-ScAConfigurableMap -ConfigSchemaPath $ConfigSchemaPath

    $baselineSchema = Get-Content $BaselineSchemaPath -Raw | ConvertFrom-Json
    $analyzerSchema = Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json
    # Load analyzer rules (product map, friendly names, CA condition rules) from the schema.
    Import-ScAAnalyzerRules -AnalyzerSchema $analyzerSchema

    $findings = @()
    $summary  = @{ Passes = 0; Failures = 0; Warnings = 0; Errors = 0; Manual = 0 }
    $orgName  = $null; $tenantId = $null; $organization = $null; $displayNameLookup = @{}; $conditionalAccessPolicies = @()

    foreach ($prod in $Product) {
        $prodLower = $prod.ToLower()
        if (-not $syncHash.ScAProductMap.ContainsKey($prodLower)) { Write-Warning "Unknown product '$prod' - skipping."; continue }
        if (-not ($baselineSchema.baselineValidations.PSObject.Properties.Name -contains $prodLower)) {
            Write-Warning "No baseline validations for '$prodLower' - skipping."; continue
        }
        $configKey = $syncHash.ScAProductMap[$prodLower].ConfigKey

        $data = if ($TenantData) { $TenantData } else { Get-ScubaTenantGraphData -Product $prodLower -BaselineSchema $baselineSchema }
        if (@($data.conditional_access_policies).Count -gt 0) { $conditionalAccessPolicies = @($data.conditional_access_policies) }
        if ($data.OrgDisplayName) { $orgName = $data.OrgDisplayName }
        if ($data.Organization) { $organization = $data.Organization }
        if ($data.TenantId) { $tenantId = $data.TenantId }
        if ($data.DisplayNameLookup) { foreach ($k in @($data.DisplayNameLookup.Keys)) { $displayNameLookup[$k] = $data.DisplayNameLookup[$k] } }

        # Wrap the raw provider data into the shape the analysis functions expect. CA policies
        # feed Get-ScAPolicyAnalysis; other provider keys (e.g. remote_domains) feed
        # Get-ScAProviderAnalysis via Raw.<rawKey>.
        $rawObj = [pscustomobject]@{ conditional_access_policies = @($data.conditional_access_policies) }
        foreach ($k in @($data.Keys)) {
            if ($k -in @('conditional_access_policies','OrgDisplayName','Organization','TenantId','DisplayNameLookup')) { continue }
            Add-Member -InputObject $rawObj -NotePropertyName $k -NotePropertyValue $data[$k] -Force
        }
        $resultsLike = [pscustomobject]@{ Raw = $rawObj }

        foreach ($control in $baselineSchema.baselineValidations.$prodLower) {
            $controlId = $control.id
            $vtype = $control.validationLogic.type

            # The exclusion type selects the analysis (exclusionDefinitions.<field>.analysis).
            $candidateExclusionField = $null
            if ($syncHash.ScAConfigurableMap -and $syncHash.ScAConfigurableMap.ContainsKey($controlId) -and @($syncHash.ScAConfigurableMap[$controlId]).Count -gt 0) {
                $candidateExclusionField = @($syncHash.ScAConfigurableMap[$controlId])[0]
            } elseif ($control.exclusionField -and $control.exclusionField -ne 'none') {
                $candidateExclusionField = [string]$control.exclusionField
            }

            $providerAnalysis = if ($vtype -ne 'conditionalAccessPolicy' -and $candidateExclusionField) {
                Get-ScAProviderAnalysis -ExclusionField $candidateExclusionField -Raw $resultsLike.Raw
            } else { $null }

            if ($vtype -eq 'conditionalAccessPolicy') {
                $policyAnalysis = Get-ScAPolicyAnalysis -ControlId $controlId -Results $resultsLike -ValidationSchema $control
                $cls = Get-ScAActionClassification -PolicyAnalysis $policyAnalysis
                $result = $cls.Result; $requiresAction = $cls.Action; $rootCause = $cls.RootCause
            } elseif ($providerAnalysis) {
                $policyAnalysis = @{ AllPolicies = @(); TotalPoliciesFound = 0 }
                if ($providerAnalysis.ItemCount -eq 0) {
                    # No source data was collected (e.g. the Exchange Online fetch failed or
                    # returned nothing) - do NOT claim Pass; flag it as needing verification.
                    $result = 'Manual'; $requiresAction = 'REVIEW'
                    $rootCause = "Could not collect the data needed to check this baseline (no '$candidateExclusionField' source data). Verify the required module/connection (e.g. Connect-ExchangeOnline) and re-scan."
                } elseif (@($providerAnalysis.Flagged).Count -gt 0) {
                    $result = 'Fail'; $requiresAction = 'EXCLUDE'
                    $rootCause = "$(@($providerAnalysis.Flagged).Count) item(s) flagged: $(@($providerAnalysis.Flagged) -join ', ')"
                } else {
                    $result = 'Pass'; $requiresAction = 'NONE'
                    $rootCause = 'The tenant configuration meets this baseline.'
                }
            } else {
                $policyAnalysis = @{ AllPolicies = @(); TotalPoliciesFound = 0 }
                $result = 'Manual'; $requiresAction = 'REVIEW'
                $rootCause = 'This baseline is configured outside Conditional Access and needs manual review (see steps).'
            }

            $configInfo = Get-ScAConfigAction -ControlId $controlId -Result $result -RequiresAction $requiresAction -ValidationType $vtype

            # A provider control that surfaced candidate values is config-fixable even for a SHOULD.
            if ($providerAnalysis -and $candidateExclusionField -and @($providerAnalysis.Flagged).Count -gt 0 -and $result -ne 'Pass') {
                $configInfo.Configurable = $true
                $configInfo.ConfigAction = 'EXCLUDE'
                if (@($configInfo.ConfigExclusionTypes).Count -eq 0) { $configInfo.ConfigExclusionTypes = @($candidateExclusionField) }
            }

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

            $baselineExclusionField = if ($control.exclusionField) { $control.exclusionField } else { 'none' }
            $remediation    = if ($control.remediationSteps) { @($control.remediationSteps) } elseif ($control.buildInstructions.configurationSteps) { @($control.buildInstructions.configurationSteps) } else { @() }
            $requirementTxt = if ($control.name) { $control.name } else { $controlId }
            $criticality    = if ($requirementTxt -match 'SHALL') { 'Shall' } elseif ($requirementTxt -match 'SHOULD') { 'Should' } else { '' }

            # This tool only emits exclusion/allow-list YAML, and only when config can
            # actually make the control pass (ConfigAction = EXCLUDE). The config-schema
            # exclusion type is authoritative for the YAML key.
            $effExclusionField = if (@($configInfo.ConfigExclusionTypes).Count -gt 0) { @($configInfo.ConfigExclusionTypes)[0] } elseif ($baselineExclusionField -ne 'none') { $baselineExclusionField } else { $null }

            # For provider (non-CA) controls the values come from providerAnalysis; for CA from detected exclusions.
            $exclusionValues = [ordered]@{}
            if ($providerAnalysis) {
                foreach ($k in @($providerAnalysis.ExclusionValues.Keys)) { $exclusionValues[$k] = @($providerAnalysis.ExclusionValues[$k]) }
            } else {
                foreach ($k in @($detectedExclusions.Keys)) {
                    $v = $detectedExclusions[$k]
                    if ($null -ne $v -and @($v).Count -gt 0) { $exclusionValues[$k] = @($v) }
                }
            }
            $hasExclusionValues = (@($exclusionValues.Keys | Where-Object { @($exclusionValues[$_]).Count -gt 0 }).Count -gt 0)

            $yamlBlock = if ($configInfo.ConfigAction -eq 'EXCLUDE' -and $effExclusionField -and $hasExclusionValues) {
                Build-ScAYamlExclusionsBlock -ProductConfigKey $configKey -ControlId $controlId -ExclusionField $effExclusionField `
                    -Description $requirementTxt -ExclusionValues $exclusionValues -ExclusionDefinitions $syncHash.ScAExclusionDefinitions
            } else { "" }

            $exclusionField = if ($configInfo.ConfigAction -eq 'EXCLUDE' -and $effExclusionField) { $effExclusionField } else { $baselineExclusionField }

            $recommendations = @()
            switch ($requiresAction) {
                'ADD_EXCLUSIONS' { $recommendations += "Add the excluded users/groups below to your ScubaGear config so this baseline passes." }
                'EXCLUDE'        { $recommendations += "Review the flagged entries below - add approved ones to the exclusion allow-list; otherwise change the tenant setting." }
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
                Details            = if ($vtype -eq 'conditionalAccessPolicy') { "Live scan of Conditional Access policies (via $($control.apiPermissionRef))." } elseif ($providerAnalysis) { "Live scan via $($control.apiPermissionRef): $($providerAnalysis.ItemCount) item(s) checked, $(@($providerAnalysis.Flagged).Count) flagged." } else { "Validation type '$vtype' - manual review." }
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
                DetectedExclusionValues = $exclusionValues
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
        ConditionalAccessPolicies = @($conditionalAccessPolicies)
        DisplayNameLookup = $displayNameLookup
    }
}

Export-ModuleMember -Function @(
    'Invoke-ScubaConfigAnalysis',
    'Invoke-ScubaTenantScan'
)
