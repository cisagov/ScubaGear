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

    # Resolve default schema paths if not explicitly provided.
    if (-not $BaselineSchemaPath) { $BaselineSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearResultsBaselineSchema.json' }
    if (-not $AnalyzerControlPath) { $AnalyzerControlPath = Resolve-ScASchemaPath -FileName 'ScubaConfigAnalyzer_Control_en-US.json' }
    if (-not $ConfigSchemaPath)   { $ConfigSchemaPath   = Resolve-ScAConfigSchemaPath }

    # Ensure that the resolved schema paths actually exist.
    if (-not (Test-Path $BaselineSchemaPath)) { throw "Baseline schema not found: $BaselineSchemaPath" }
    if (-not (Test-Path $AnalyzerControlPath)) { throw "Analyzer schema not found: $AnalyzerControlPath" }
    if (-not (Test-Path $ConfigSchemaPath)) { throw "Config schema not found: $ConfigSchemaPath" }

    # Load the canonical config schema's exclusion mappings so configurability is JSON-driven.
    Import-ScAConfigurableMap -ConfigSchemaPath $ConfigSchemaPath

    # Load the JSON content from the results, baseline schema, and analyzer control files.
    $results        = Get-Content $ResultsPath -Raw | ConvertFrom-Json
    $baselineSchema = Get-Content $BaselineSchemaPath -Raw | ConvertFrom-Json
    $analyzerSchema = Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json

    # Load analyzer rules (product map, friendly names, CA condition rules) from the schema.
    Import-ScAAnalyzerRules -AnalyzerSchema $analyzerSchema

    # Initialize the findings and summary collections.
    $findings = @()
    $summary  = @{ Passes = 0; Failures = 0; Warnings = 0; Errors = 0; Manual = 0 }

    # Iterate over each specified product and process its results.
    foreach ($prod in $Product) {
        $prodLower = $prod.ToLower()
        if (-not $syncHash.ScAProductMap.ContainsKey($prodLower)) {
            Write-Warning "Unknown product '$prod' - skipping."
            continue
        }
        # Retrieve the result and config keys for the current product.
        $resultsKey = $syncHash.ScAProductMap[$prodLower].ResultsKey
        $configKey  = $syncHash.ScAProductMap[$prodLower].ConfigKey

        # Ensure that the results contain the expected key for this product.
        if (-not ($results.Results.PSObject.Properties.Name -contains $resultsKey)) {
            Write-Verbose "No results found for product '$resultsKey' in $ResultsPath."
            continue
        }

        # Accumulate the product summary if present.
        # This ensures that the overall summary reflects the results for each product individually.
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
                # Skip this control if it doesn't meet the inclusion criteria based on the result and the IncludePassing flag.
                if (-not $IncludePassing -and $result -eq 'Pass') { continue }

                # Extract the control ID and retrieve the corresponding validation schema.
                $controlId       = $control.'Control ID'
                $validationSchema = Get-ScAValidationSchema -ControlId $controlId -BaselineSchema $baselineSchema
                $vtype      = if ($validationSchema) { $validationSchema.validationLogic.type } else { $null }

                # The exclusion type this control supports (config-schema mapping first, then
                # the baseline's own exclusionField) selects the analysis to run.
                $candidateExclusionField = $null
                # Determine the candidate exclusion field for this control, prioritizing the configurable map over the baseline schema.
                if ($syncHash.ScAConfigurableMap -and $syncHash.ScAConfigurableMap.ContainsKey($controlId) -and @($syncHash.ScAConfigurableMap[$controlId]).Count -gt 0) {
                    $candidateExclusionField = @($syncHash.ScAConfigurableMap[$controlId])[0]
                } elseif ($validationSchema -and $validationSchema.exclusionField -and $validationSchema.exclusionField -ne 'none') {
                    $candidateExclusionField = [string]$validationSchema.exclusionField
                }

                # Non-CA controls are analyzed via the exclusion type's own analysis section
                # (exclusionDefinitions.<field>.analysis); CA controls keep the CA path.
                # Retrieve the provider analysis for non-CA controls based on the candidate exclusion field.
                $providerAnalysis = if ($vtype -ne 'conditionalAccessPolicy' -and $candidateExclusionField) {
                    Get-ScAProviderAnalysis -ExclusionField $candidateExclusionField -Raw $results.Raw
                } else { $null }
                
                # Retrieve the policy analysis for CA controls based on the validation schema.
                $policyAnalysis = if ($validationSchema -and $vtype -eq 'conditionalAccessPolicy') {
                    Get-ScAPolicyAnalysis -ControlId $controlId -Results $results -ValidationSchema $validationSchema
                } else {
                    @{ AllPolicies = @(); TotalPoliciesFound = 0 }
                }

                # Best-match policy = closest to compliant (fewest policy-setting changes, then fewest waivers).
                $sortedPolicies = @($policyAnalysis.AllPolicies | Sort-Object { $_.SettingIssueCount }, { $_.ExcludedPrincipalCount }, { $_.IssueCount })
                $bestMatch      = if (@($sortedPolicies).Count -gt 0) { $sortedPolicies[0] } else { $null }
                
                # Determine the detected exclusions based on the best-match policy.
                $detectedExclusions = if ($bestMatch) {
                    $bestMatch.DetectedExclusions
                } else {
                    @{ Users = @(); Groups = @(); Applications = @(); GuestUserTypes = @() }
                }
                
                # Collect all missing settings from the policy analysis for reporting purposes.
                $missingSettings = @()
                foreach ($p in @($policyAnalysis.AllPolicies)) { $missingSettings += $p.Issues }

                # Determine the baseline exclusion field, remediation steps, and requirement text for this control.
                $baselineExclusionField = if ($validationSchema -and $validationSchema.exclusionField) { $validationSchema.exclusionField } else { 'none' }
                $remediation    = if ($validationSchema -and $validationSchema.remediationSteps) { @($validationSchema.remediationSteps) } elseif ($validationSchema -and $validationSchema.buildInstructions.configurationSteps) { @($validationSchema.buildInstructions.configurationSteps) } else { @() }
                $requirementTxt = if ($control.Requirement) { $control.Requirement } elseif ($validationSchema) { $validationSchema.name } else { $controlId }
                
                # Remove any HTML tags from the requirement text for cleaner display.
                $requirementTxt = Remove-ScAHtml $requirementTxt

                # Root cause: provider (non-CA) controls get a data-driven, non-CA message;
                # CA controls use the Conditional Access classifier.
                if ($providerAnalysis) {
                    # If the result is 'Pass', mark the root cause as compliant.
                    # If there are flagged items, mark the root cause accordingly.
                    # Otherwise, mark the root cause as non-compliant.
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
                        # Retrieve the detected exclusion value for this key.
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

                # Determine if there are any effective exclusion values to consider.
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

                # Collect the recommendations for this finding.
                $recommendations = @($rootCause.Recommendations)
                if ($configInfo.ConfigAction -eq 'FIX_TENANT') {
                    $recommendations += "This control can't be made to pass with ScubaGear configuration. Align the tenant setting (see remediation steps), or omit the policy in the ScubaGear Config App (this analyzer does not generate omissions)."
                }

                # Build the finding object with all relevant details.
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

    # Calculate the total number of findings and the compliance rate.
    $total = $summary.Passes + $summary.Failures + $summary.Warnings + $summary.Errors + $summary.Manual
    $complianceRate = if ($total -gt 0) { [math]::Round(($summary.Passes / $total) * 100, 1) } else { 0 }

    # Format the scan date for display.
    $scanDate = ""
    if ($results.MetaData.TimestampZulu) {
        try { $scanDate = ([DateTime]$results.MetaData.TimestampZulu).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss") } catch { $scanDate = "$($results.MetaData.TimestampZulu)" }
    }

    # Return the final scan result as a custom object.
    return [pscustomobject]@{
        MetaData = [pscustomobject]@{
            DisplayName  = $results.MetaData.DisplayName
            Organization = $results.MetaData.DomainName
            TenantId     = $results.MetaData.TenantId
            ScanDate     = $scanDate
            ResultsPath  = (Resolve-Path $ResultsPath).Path
        }
        # Include the summary, findings, and lookups for the scan results.
        Summary = [pscustomobject]@{
            Passes = $summary.Passes; Failures = $summary.Failures; Warnings = $summary.Warnings
            Errors = $summary.Errors; Manual = $summary.Manual; Total = $total; ComplianceRate = $complianceRate
        }
        # List of products included in the scan.
        Products = @($Product | ForEach-Object { $_.ToLower() })
        Findings = @($findings)
        ConditionalAccessPolicies = @($results.Raw.conditional_access_policies)
        DisplayNameLookup = @{}
        UserUpnLookup = @{}
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
    # Initialize the scan by setting up paths, loading schemas, and preparing data structures.
    # $M365Environment is recorded for context only; the Graph connection that actually uses
    # it is established by the caller (on the UI thread) before this scan runs.
    Write-Verbose "Invoke-ScubaTenantScan: products '$($Product -join ", ")' in environment '$M365Environment'."

    # Resolve default paths for schemas if not provided by the caller.
    if (-not $BaselineSchemaPath) { $BaselineSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearResultsBaselineSchema.json' }
    if (-not $AnalyzerControlPath) { $AnalyzerControlPath = Resolve-ScASchemaPath -FileName 'ScubaConfigAnalyzer_Control_en-US.json' }
    if (-not $ConfigSchemaPath)   { $ConfigSchemaPath   = Resolve-ScAConfigSchemaPath }
    # Verify that the resolved schema paths exist.
    if (-not (Test-Path $BaselineSchemaPath)) { throw "Baseline schema not found: $BaselineSchemaPath" }
    if (-not (Test-Path $AnalyzerControlPath)) { throw "Analyzer schema not found: $AnalyzerControlPath" }
    if (-not (Test-Path $ConfigSchemaPath)) { throw "Config schema not found: $ConfigSchemaPath" }

    # Load the canonical config schema's exclusion mappings so configurability is JSON-driven.
    Import-ScAConfigurableMap -ConfigSchemaPath $ConfigSchemaPath

    # Load the baseline and analyzer schemas into memory.
    $baselineSchema = Get-Content $BaselineSchemaPath -Raw | ConvertFrom-Json
    $analyzerSchema = Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json

    # Load analyzer rules (product map, friendly names, CA condition rules) from the schema.
    Import-ScAAnalyzerRules -AnalyzerSchema $analyzerSchema

    # Initialize the findings and summary data structures for the scan.
    $findings = @()
    # Initialize organization and user lookup data structures.
    $summary  = @{ Passes = 0; Failures = 0; Warnings = 0; Errors = 0; Manual = 0 }
    # Initialize variables for organization and tenant information.
    $orgName  = $null; $tenantId = $null; $organization = $null; $displayNameLookup = @{}; $userUpnLookup = @{}; $conditionalAccessPolicies = @()

    # Iterate over each product specified for the scan.
    foreach ($prod in $Product) {
        $prodLower = $prod.ToLower()
        # Skip unknown products or those without baseline validations.
        if (-not $syncHash.ScAProductMap.ContainsKey($prodLower)) { Write-Warning "Unknown product '$prod' - skipping."; continue }
        # Skip products that do not have baseline validations defined.
        if (-not ($baselineSchema.baselineValidations.PSObject.Properties.Name -contains $prodLower)) {
            Write-Warning "No baseline validations for '$prodLower' - skipping."; continue
        }
        # Retrieve the configuration key for the current product from the product map.
        $configKey = $syncHash.ScAProductMap[$prodLower].ConfigKey

        # Retrieve the tenant data, either from the pre-fetched data or by querying the graph.
        $data = if ($TenantData) { $TenantData } else { Get-ScubaTenantGraphData -Product $prodLower -BaselineSchema $baselineSchema }
        # Extract and store relevant tenant information from the retrieved data.
        if (@($data.conditional_access_policies).Count -gt 0) { $conditionalAccessPolicies = @($data.conditional_access_policies) }
        if ($data.OrgDisplayName) { $orgName = $data.OrgDisplayName }
        if ($data.Organization) { $organization = $data.Organization }
        if ($data.TenantId) { $tenantId = $data.TenantId }
        if ($data.DisplayNameLookup) { foreach ($k in @($data.DisplayNameLookup.Keys)) { $displayNameLookup[$k] = $data.DisplayNameLookup[$k] } }
        if ($data.UserUpnLookup) { foreach ($k in @($data.UserUpnLookup.Keys)) { $userUpnLookup[$k] = $data.UserUpnLookup[$k] } }

        # The UI passes pre-fetched tenant data to this worker. Resolve UPNs here too when
        # that payload did not carry them, so Tenant Governance always uses the exact
        # Conditional Access policies the analyzer is evaluating.
        if (@($data.conditional_access_policies).Count -gt 0 -and $userUpnLookup.Count -eq 0) {
            try {
                # Resolve user principal names (UPNs) from the conditional access policies.
                $resolvedUserUpns = Get-ScAUserPrincipalNameLookup -Policies @($data.conditional_access_policies)
                # Update the user UPN lookup with the resolved UPNs.
                foreach ($key in @($resolvedUserUpns.Keys)) { $userUpnLookup[$key] = $resolvedUserUpns[$key] }
            } catch {
                Write-ScAEngineActivity "User UPN resolution during tenant analysis skipped: $($_.Exception.Message)" -Level Warning
            }
        }

        # Wrap the raw provider data into the shape the analysis functions expect. CA policies
        # feed Get-ScAPolicyAnalysis; other provider keys (e.g. remote_domains) feed
        # Get-ScAProviderAnalysis via Raw.<rawKey>.
        $rawObj = [pscustomobject]@{ conditional_access_policies = @($data.conditional_access_policies) }
        # Add all other provider data to the raw object, excluding the keys already handled.
        foreach ($k in @($data.Keys)) {
            if ($k -in @('conditional_access_policies','OrgDisplayName','Organization','TenantId','DisplayNameLookup')) { continue }
            Add-Member -InputObject $rawObj -NotePropertyName $k -NotePropertyValue $data[$k] -Force
        }
        # Wrap the raw object into a results-like object for analysis functions.
        $resultsLike = [pscustomobject]@{ Raw = $rawObj }

        # Iterate over each control in the baseline schema for the current product.
        foreach ($control in $baselineSchema.baselineValidations.$prodLower) {
            $controlId = $control.id
            $vtype = $control.validationLogic.type

            # The exclusion type selects the analysis (exclusionDefinitions.<field>.analysis).
            $candidateExclusionField = $null

            # Determine the candidate exclusion field for the current control.
            if ($syncHash.ScAConfigurableMap -and $syncHash.ScAConfigurableMap.ContainsKey($controlId) -and @($syncHash.ScAConfigurableMap[$controlId]).Count -gt 0) {
                $candidateExclusionField = @($syncHash.ScAConfigurableMap[$controlId])[0]
            } elseif ($control.exclusionField -and $control.exclusionField -ne 'none') {
                $candidateExclusionField = [string]$control.exclusionField
            }

            # Retrieve the provider analysis for the current control based on the candidate exclusion field.
            $providerAnalysis = if ($vtype -ne 'conditionalAccessPolicy' -and $candidateExclusionField) {
                Get-ScAProviderAnalysis -ExclusionField $candidateExclusionField -Raw $resultsLike.Raw
            } else { $null }

            # If no provider analysis was retrieved and the control is not a conditional access policy, flag it for manual review.
            # Handle the analysis based on the type of control (conditional access policy or provider analysis).
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
                    # One or more items were flagged in the provider analysis, indicating a failure.
                    $result = 'Fail'; $requiresAction = 'EXCLUDE'
                    $rootCause = "$(@($providerAnalysis.Flagged).Count) item(s) flagged: $(@($providerAnalysis.Flagged) -join ', ')"
                } else {
                    # No items were flagged in the provider analysis, indicating a pass.
                    $result = 'Pass'; $requiresAction = 'NONE'
                    $rootCause = 'The tenant configuration meets this baseline.'
                }
            } else {
                # The control is not a conditional access policy and no provider analysis is available, so flag it for manual review.
                $policyAnalysis = @{ AllPolicies = @(); TotalPoliciesFound = 0 }
                $result = 'Manual'; $requiresAction = 'REVIEW'
                $rootCause = 'This baseline is configured outside Conditional Access and needs manual review (see steps).'
            }

            # Retrieve the configuration action information for the current control based on the analysis result.
            $configInfo = Get-ScAConfigAction -ControlId $controlId -Result $result -RequiresAction $requiresAction -ValidationType $vtype

            # A provider control that surfaced candidate values is config-fixable even for a SHOULD.
            if ($providerAnalysis -and $candidateExclusionField -and @($providerAnalysis.Flagged).Count -gt 0 -and $result -ne 'Pass') {
                $configInfo.Configurable = $true
                $configInfo.ConfigAction = 'EXCLUDE'
                if (@($configInfo.ConfigExclusionTypes).Count -eq 0) { $configInfo.ConfigExclusionTypes = @($candidateExclusionField) }
            }

            # Update the summary counts based on the analysis result.
            switch ($result) {
                'Pass'    { $summary.Passes++ }
                'Fail'    { $summary.Failures++ }
                'Warning' { $summary.Warnings++ }
                default   { $summary.Manual++ }
            }

            # Sort the policies to determine the best match based on setting issues, excluded principals, and overall issues.
            $sortedPolicies = @($policyAnalysis.AllPolicies | Sort-Object { $_.SettingIssueCount }, { $_.ExcludedPrincipalCount }, { $_.IssueCount })
            $bestMatch      = if (@($sortedPolicies).Count -gt 0) { $sortedPolicies[0] } else { $null }
            # Determine the detected exclusions and missing settings for the best match policy.
            $detectedExclusions = if ($bestMatch) { $bestMatch.DetectedExclusions } else { @{ Users = @(); Groups = @(); Applications = @(); GuestUserTypes = @() } }
            $missingSettings = @()
            # Collect all missing settings from the policy analysis.
            foreach ($p in @($policyAnalysis.AllPolicies)) { $missingSettings += $p.Issues }

            # Determine the baseline exclusion field, remediation steps, requirement text, and criticality for the current control.
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
            # Determine the exclusion values based on provider analysis or detected exclusions.
            if ($providerAnalysis) {
                # Populate the exclusion values from the provider analysis.
                foreach ($k in @($providerAnalysis.ExclusionValues.Keys)) { $exclusionValues[$k] = @($providerAnalysis.ExclusionValues[$k]) }
            } else {
                # Populate the exclusion values from the detected exclusions.
                foreach ($k in @($detectedExclusions.Keys)) {
                    $v = $detectedExclusions[$k]
                    if ($null -ne $v -and @($v).Count -gt 0) { $exclusionValues[$k] = @($v) }
                }
            }
            # Determine if there are any exclusion values present.
            $hasExclusionValues = (@($exclusionValues.Keys | Where-Object { @($exclusionValues[$_]).Count -gt 0 }).Count -gt 0)

            # Build the YAML block for exclusions if applicable.
            $yamlBlock = if ($configInfo.ConfigAction -eq 'EXCLUDE' -and $effExclusionField -and $hasExclusionValues) {
                Build-ScAYamlExclusionsBlock -ProductConfigKey $configKey -ControlId $controlId -ExclusionField $effExclusionField `
                    -Description $requirementTxt -ExclusionValues $exclusionValues -ExclusionDefinitions $syncHash.ScAExclusionDefinitions
            } else { "" }

            # Determine the effective exclusion field based on the configuration action.
            $exclusionField = if ($configInfo.ConfigAction -eq 'EXCLUDE' -and $effExclusionField) { $effExclusionField } else { $baselineExclusionField }

            # Initialize the recommendations array and populate it based on the required action.
            $recommendations = @()
            switch ($requiresAction) {
                'ADD_EXCLUSIONS' { $recommendations += "Add the excluded users/groups below to your ScubaGear config so this baseline passes." }
                'EXCLUDE'        { $recommendations += "Review the flagged entries below - add approved ones to the exclusion allow-list; otherwise change the tenant setting." }
                'FIX_POLICY'     { $recommendations += "Update the best-match policy so its settings match the baseline requirement, then re-scan." }
                'CREATE_POLICY'  { $recommendations += "Create a new Conditional Access policy as described below, then re-scan." }
            }
            # Add additional recommendations if the configuration action requires fixing the tenant setting.
            if ($configInfo.ConfigAction -eq 'FIX_TENANT') {
                $recommendations += "This control can't be made to pass with ScubaGear configuration. Align the tenant setting, or omit the policy in the ScubaGear Config App (this analyzer does not generate omissions)."
            }

            # Append the findings for this control to the overall findings array.
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

    # Calculate the total number of findings and the compliance rate based on the summary.
    $total = $summary.Passes + $summary.Failures + $summary.Warnings + $summary.Errors + $summary.Manual
    $complianceRate = if ($total -gt 0) { [math]::Round(($summary.Passes / $total) * 100, 1) } else { 0 }

    # Return the final scan result as a custom object.
    return [pscustomobject]@{
        MetaData = [pscustomobject]@{
            DisplayName  = if ($orgName) { $orgName } elseif ($tenantId) { "Tenant $tenantId" } else { "M365 tenant" }
            Organization = $organization
            TenantId     = $tenantId
            ScanDate     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            ResultsPath  = $null
        }
        # Include the summary of the scan results.
        Summary = [pscustomobject]@{
            Passes = $summary.Passes; Failures = $summary.Failures; Warnings = $summary.Warnings
            Errors = $summary.Errors; Manual = $summary.Manual; Total = $total; ComplianceRate = $complianceRate
        }
        # Include the detailed findings, conditional access policies, and lookup tables.
        Products = @($Product | ForEach-Object { $_.ToLower() })
        Findings = @($findings)
        ConditionalAccessPolicies = @($conditionalAccessPolicies)
        DisplayNameLookup = $displayNameLookup
        UserUpnLookup = $userUpnLookup
    }
}

Export-ModuleMember -Function @(
    'Invoke-ScubaConfigAnalysis',
    'Invoke-ScubaTenantScan'
)
