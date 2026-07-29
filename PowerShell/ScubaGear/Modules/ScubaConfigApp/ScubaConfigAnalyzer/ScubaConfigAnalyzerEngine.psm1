<#
.SYNOPSIS
    Analysis engine for the ScubaGear Config Analyzer (Start-SCuBAConfigAnalyzer).

.DESCRIPTION
    Reads a ScubaGear results JSON (produced by Invoke-SCuBA) and compares the raw
    tenant configuration against the ScubaGear baseline requirements described in the
    JSON schemas that ship in PowerShell/ScubaGear/schemas:

      - ScubaGearResultsBaselineSchema.json  (per-control validation logic / requiredSettings)

    plus an analyzer-local ScubaConfigAnalyzer/ScubaGearAnalyzerSchema.json (friendly
    display names for CA requirement paths). The canonical ScubaGear config-file schema
    is not duplicated here - see Modules/ScubaConfig/ScubaConfigSchema.json.

    Nothing about the baselines is hard-coded here: the controls, requirements and
    remediation steps all come from the schema files. The engine emits a structured
    findings object (consumed by the WPF UI) and can build a ready-to-use ScubaGear
    configuration YAML containing the exclusions detected in the tenant.

    This module is intentionally UI-free so the analysis can be unit-tested on its
    own (Invoke-ScubaConfigAnalysis -ResultsPath <file>).

.NOTES
    Ported and adapted from the standalone AnalyzeScubaGearResults tool.
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

# ------------------------------------------------------------------------------------
# Product mapping (schema uses lowercase keys; results + config YAML use other casing)
# ------------------------------------------------------------------------------------
$script:ScAProductMap = @{
    aad            = @{ ResultsKey = 'AAD';            ConfigKey = 'Aad' }
    securitysuite  = @{ ResultsKey = 'SecuritySuite';  ConfigKey = 'SecuritySuite' }
    exo            = @{ ResultsKey = 'EXO';            ConfigKey = 'Exo' }
    powerplatform  = @{ ResultsKey = 'PowerPlatform';  ConfigKey = 'Powerplatform' }
    sharepoint     = @{ ResultsKey = 'SharePoint';     ConfigKey = 'Sharepoint' }
    teams          = @{ ResultsKey = 'Teams';          ConfigKey = 'Teams' }
    powerbi        = @{ ResultsKey = 'PowerBI';        ConfigKey = 'Powerbi' }
}

# Friendly-name lookup populated from the config schema during analysis.
$script:ScAFriendlyNames = $null

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

function Get-ScAExclusionsFromIssues {
    <#
    .SYNOPSIS
    Parses excluded-user/group/application/guest issue strings into an exclusions map
    ({Users,Groups,Applications,GuestUserTypes}) matching the CapExclusions config fields.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [array]$Issues = @()
    )

    $exclusions = @{ Users = @(); Groups = @(); Applications = @(); GuestUserTypes = @() }

    foreach ($issue in $Issues) {
        if ($issue -match "excluded user.*\|DETAILS:User IDs:\s*([^|]+)") {
            $exclusions.Users += ($matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
        if ($issue -match "excluded group.*\|DETAILS:Group IDs:\s*([^|]+)") {
            $exclusions.Groups += ($matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
        if ($issue -match "excluded application.*\|DETAILS:Application IDs:\s*([^|]+)") {
            $exclusions.Applications += ($matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
        if ($issue -match "excluded guest.*\|DETAILS:Guest user types:\s*([^|]+)") {
            $exclusions.GuestUserTypes += ($matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
    }

    $exclusions.Users          = @($exclusions.Users          | Select-Object -Unique)
    $exclusions.Groups         = @($exclusions.Groups         | Select-Object -Unique)
    $exclusions.Applications   = @($exclusions.Applications   | Select-Object -Unique)
    $exclusions.GuestUserTypes = @($exclusions.GuestUserTypes | Select-Object -Unique)
    return $exclusions
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
    #>
    param(
        [Parameter(Mandatory)][string]$ControlId,
        [Parameter(Mandatory)]$Results,
        [Parameter(Mandatory)]$ValidationSchema
    )

    $allPoliciesData = @()

    if (-not ($Results.Raw.PSObject.Properties.Name -contains 'conditional_access_policies')) {
        return @{ AllPolicies = @(); TotalPoliciesFound = 0 }
    }
    if (-not ($ValidationSchema -and $ValidationSchema.validationLogic.type -eq 'conditionalAccessPolicy')) {
        return @{ AllPolicies = @(); TotalPoliciesFound = 0 }
    }

    $caPolicies   = $Results.Raw.conditional_access_policies
    $requirements = $ValidationSchema.validationLogic.requirements
    $matchingPolicies = @($caPolicies | Where-Object { $_.State -eq 'enabled' })

    foreach ($policy in $matchingPolicies) {
        $policyIssues  = @()
        $meetsCriteria = $true
        $excludedCount = 0

        # Validate each requirement dynamically from the schema.
        foreach ($reqProperty in $requirements.PSObject.Properties) {
            $friendlyName = Get-ScAFriendlyName -Path $reqProperty.Name
            $validationResult = Test-ScAPolicyRequirement -Policy $policy -SchemaPath $reqProperty.Name -ExpectedValue $reqProperty.Value -FriendlyName $friendlyName
            if (-not $validationResult.Meets) {
                $meetsCriteria = $false
                foreach ($issue in $validationResult.Issues) { $policyIssues += $issue }
            }
        }

        # Detect exclusions using the schema-declared exclusion paths.
        # Detect config-waivable exclusions. ScubaGear lets you waive excluded users,
        # groups, applications, and guest/external user types via the config file
        # (CapExclusions), so these are WARNINGS the config can satisfy - not setting
        # errors that require changing the policy.
        $supportsCap = ($ValidationSchema.exclusionField -eq 'CapExclusions')

        # Users / groups (and any other principal paths declared by the schema).
        if ($ValidationSchema.buildInstructions.PSObject.Properties.Name -contains 'exclusionHandling') {
            $exclusionConfig = $ValidationSchema.buildInstructions.exclusionHandling
            if ($exclusionConfig -is [array]) {
                foreach ($exclusionPath in $exclusionConfig) {
                    $pascalParts = ($exclusionPath -split '\.') | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1) }
                    $currentValue = $policy
                    foreach ($part in $pascalParts) {
                        if ($currentValue.PSObject.Properties.Name -contains $part) { $currentValue = $currentValue.$part }
                        else { $currentValue = $null; break }
                    }
                    if ($currentValue -and @($currentValue).Count -gt 0) {
                        $excludedCount += @($currentValue).Count
                        $exclusionType = if ($exclusionPath -like '*excludeUsers') { 'user' }
                                         elseif ($exclusionPath -like '*excludeGroups') { 'group' }
                                         elseif ($exclusionPath -like '*excludeRoles') { 'role' }
                                         else { 'item' }
                        $typeTitle = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($exclusionType)
                        $suggestion = if ($exclusionType -eq 'user') { 'If justified (break-glass accounts): Add to CapExclusions in ScubaConfig' } else { 'Review if these exclusions are justified and documented' }
                        $policyIssues += "WARNING: Policy has $(@($currentValue).Count) excluded ${exclusionType}(s)|DETAILS:$typeTitle IDs: $(@($currentValue) -join ', ')|SUGGESTION:$suggestion"
                        $meetsCriteria = $false
                    }
                }
            }
        }

        # Excluded applications - waivable via CapExclusions.Applications, but only where
        # the requirement targets All cloud apps (e.g. not MS.AAD.3.8v1, which uses user actions).
        $requiresAllApps = ($requirements.PSObject.Properties.Name -contains 'conditions') -and
                           ($requirements.conditions.PSObject.Properties.Name -contains 'applications') -and
                           ($requirements.conditions.applications.PSObject.Properties.Name -contains 'includeApplications') -and
                           (@($requirements.conditions.applications.includeApplications) -contains 'All')
        if ($supportsCap -and $requiresAllApps) {
            $exApps = @($policy.Conditions.Applications.ExcludeApplications | Where-Object { $_ })
            if (@($exApps).Count -gt 0) {
                $excludedCount += @($exApps).Count
                $policyIssues += "WARNING: Policy has $(@($exApps).Count) excluded application(s)|DETAILS:Application IDs: $(@($exApps) -join ', ')|SUGGESTION:If justified: Add to CapExclusions Applications in ScubaConfig"
                $meetsCriteria = $false
            }
        }

        # Excluded guest / external user types. ScubaGear now lets these be waived via
        # CapExclusions.GuestUserTypes, so treat them as a config-waivable WARNING where the
        # control supports CapExclusions and targets All users; otherwise it is a setting error.
        $requiresAllUsers = ($requirements.PSObject.Properties.Name -contains 'conditions') -and
                            ($requirements.conditions.PSObject.Properties.Name -contains 'users') -and
                            ($requirements.conditions.users.PSObject.Properties.Name -contains 'includeUsers') -and
                            (@($requirements.conditions.users.includeUsers) -contains 'All')
        if ($requiresAllUsers) {
            $exGuest = $policy.Conditions.Users.ExcludeGuestsOrExternalUsers
            $guestTypes = @()
            if ($exGuest -and $exGuest.GuestOrExternalUserTypes) {
                $g = $exGuest.GuestOrExternalUserTypes
                $guestTypes = if ($g -is [string]) { @($g -split '\s*,\s*' | Where-Object { $_ }) } else { @($g | Where-Object { $_ }) }
            }
            if (@($guestTypes).Count -gt 0) {
                if ($supportsCap) {
                    $excludedCount += @($guestTypes).Count
                    $policyIssues += "WARNING: Policy has $(@($guestTypes).Count) excluded guest/external user type(s)|DETAILS:Guest user types: $(@($guestTypes) -join ', ')|SUGGESTION:If justified: Add to CapExclusions GuestUserTypes in ScubaConfig"
                    $meetsCriteria = $false
                } else {
                    $policyIssues += "ERROR: Policy excludes guest/external user types ($(@($guestTypes) -join ', ')); this control does not support guest exclusions - remove them from the policy."
                    $meetsCriteria = $false
                }
            }
        }

        # Only include policies that are actually relevant to THIS control, using the
        # unique characteristics declared in the requirements.
        $hasRelevantConfig = $false
        if ($requirements.PSObject.Properties.Name -contains 'conditions') {
            if ($requirements.conditions.PSObject.Properties.Name -contains 'clientAppTypes') {
                $requiredTypes = $requirements.conditions.clientAppTypes
                $matchingTypes = 0
                if ($policy.Conditions.ClientAppTypes) {
                    foreach ($type in $requiredTypes) {
                        if ($policy.Conditions.ClientAppTypes -contains $type) { $matchingTypes++ }
                    }
                }
                if ($matchingTypes -eq @($requiredTypes).Count) { $hasRelevantConfig = $true }
            }
            if ($requirements.conditions.PSObject.Properties.Name -contains 'userRiskLevels') {
                if ($policy.Conditions.UserRiskLevels) {
                    foreach ($level in $requirements.conditions.userRiskLevels) {
                        if ($policy.Conditions.UserRiskLevels -contains $level) { $hasRelevantConfig = $true; break }
                    }
                }
            }
            if ($requirements.conditions.PSObject.Properties.Name -contains 'signInRiskLevels') {
                if ($policy.Conditions.SignInRiskLevels) {
                    foreach ($level in $requirements.conditions.signInRiskLevels) {
                        if ($policy.Conditions.SignInRiskLevels -contains $level) { $hasRelevantConfig = $true; break }
                    }
                }
            }
        }
        if (-not $hasRelevantConfig -and $requirements.PSObject.Properties.Name -contains 'grantControls') {
            $gc = $requirements.grantControls
            if ($gc.PSObject.Properties.Name -contains 'anyOf') {
                # Alternatives (e.g. MFA via built-in control OR MFA authentication strength).
                if (Test-ScAGrantControlRelevance -Policy $policy -GrantReq $gc) { $hasRelevantConfig = $true }
            }
            elseif ($gc.PSObject.Properties.Name -contains 'authenticationStrength') {
                if ($policy.GrantControls.AuthenticationStrength.Id -eq $gc.authenticationStrength.id) {
                    $hasRelevantConfig = $true
                }
            }
        }

        # Scope gate: a policy is only usable for a ScubaGear pass if it targets the scope
        # the requirement demands - All users and/or All cloud apps. Persona / admin-scoped
        # policies would need major changes (not config), so they are not candidates.
        # Exclusions (users/groups/apps/guests) do not affect scope membership.
        $inScope = $true
        if ($requirements.PSObject.Properties.Name -contains 'conditions') {
            $reqCond = $requirements.conditions
            if (($reqCond.PSObject.Properties.Name -contains 'users') -and
                ($reqCond.users.PSObject.Properties.Name -contains 'includeUsers') -and
                (@($reqCond.users.includeUsers) -contains 'All') -and
                (@($policy.Conditions.Users.IncludeUsers) -notcontains 'All')) {
                $inScope = $false
            }
            if (($reqCond.PSObject.Properties.Name -contains 'applications') -and
                ($reqCond.applications.PSObject.Properties.Name -contains 'includeApplications') -and
                (@($reqCond.applications.includeApplications) -contains 'All') -and
                (@($policy.Conditions.Applications.IncludeApplications) -notcontains 'All')) {
                $inScope = $false
            }
        }

        if ($hasRelevantConfig -and $inScope) {
            $allPoliciesData += @{
                DisplayName   = $policy.DisplayName
                Id            = $policy.Id
                State         = $policy.State
                MeetsCriteria = $meetsCriteria
                Issues        = $policyIssues
                IssueCount    = @($policyIssues).Count
                SettingIssueCount = @($policyIssues | Where-Object { $_ -notmatch 'Policy has \d+ excluded' }).Count
                ExcludedPrincipalCount = $excludedCount
                DetectedExclusions = (Get-ScAExclusionsFromIssues -Issues $policyIssues)
            }
        }
    }

    return @{ AllPolicies = $allPoliciesData; TotalPoliciesFound = @($allPoliciesData).Count }
}

function Build-ScAYamlExclusionsBlock {
    <#
    .SYNOPSIS
    Builds a per-control YAML exclusion block for a single product.
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
    Optional override for ScubaGearAnalyzerSchema.json (friendly display names).

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
    if (-not $AnalyzerSchemaPath) { $AnalyzerSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearAnalyzerSchema.json' }
    if (-not $ConfigSchemaPath)   { $ConfigSchemaPath   = Resolve-ScAConfigSchemaPath }

    if (-not (Test-Path $BaselineSchemaPath)) { throw "Baseline schema not found: $BaselineSchemaPath" }
    if (-not (Test-Path $AnalyzerSchemaPath)) { throw "Analyzer schema not found: $AnalyzerSchemaPath" }

    # Load the canonical config schema's exclusion mappings so configurability is JSON-driven.
    Import-ScAConfigurableMap -ConfigSchemaPath $ConfigSchemaPath

    $results        = Get-Content $ResultsPath -Raw | ConvertFrom-Json
    $baselineSchema = Get-Content $BaselineSchemaPath -Raw | ConvertFrom-Json
    $analyzerSchema = Get-Content $AnalyzerSchemaPath -Raw | ConvertFrom-Json

    $script:ScAFriendlyNames = if ($analyzerSchema.RequirementFriendlyNames.default) { $analyzerSchema.RequirementFriendlyNames.default } elseif ($analyzerSchema.RequirementFriendlyNames) { $analyzerSchema.RequirementFriendlyNames } else { $null }

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
                    Get-ScAExclusionsFromIssues -Issues @($bestMatch.Issues)
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
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Analysis,
        [hashtable]$ExclusionOverrides = @{},
        [string]$M365Environment = 'commercial',
        [hashtable]$DisplayNameLookup = @{}
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# ScubaGear configuration generated by Start-SCuBAConfigAnalyzer")
    [void]$sb.AppendLine("# Tenant: $($Analysis.MetaData.DisplayName)")
    [void]$sb.AppendLine("# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("# Review every exclusion below - only keep entries that are justified (e.g. break-glass accounts).")
    [void]$sb.AppendLine("")
    if ($Analysis.MetaData.Organization) { [void]$sb.AppendLine("Organization: $($Analysis.MetaData.Organization)") }
    if ($Analysis.MetaData.DisplayName) { [void]$sb.AppendLine("OrgName: $($Analysis.MetaData.DisplayName)") }
    [void]$sb.AppendLine("M365Environment: $M365Environment")
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
    #>
    param([Parameter(Mandatory)]$PolicyAnalysis)

    $policies = @($PolicyAnalysis.AllPolicies)
    if (@($policies).Count -eq 0) {
        return @{ Result = 'Fail'; Action = 'CREATE_POLICY'; RootCause = 'No Conditional Access policy addresses this baseline - create a new one.' }
    }
    $best = @($policies | Sort-Object { $_.SettingIssueCount }, { $_.ExcludedPrincipalCount }, { $_.IssueCount })[0]
    if ($best.MeetsCriteria) {
        return @{ Result = 'Pass'; Action = 'NONE'; RootCause = 'A Conditional Access policy already satisfies this baseline.' }
    }
    $exIssues      = @($best.Issues | Where-Object { $_ -match 'Policy has \d+ excluded' })
    $settingIssues = @($best.Issues | Where-Object { $_ -notmatch 'Policy has \d+ excluded' })
    if (@($settingIssues).Count -eq 0 -and @($exIssues).Count -gt 0) {
        return @{ Result = 'Fail'; Action = 'ADD_EXCLUSIONS'; RootCause = 'The best-matching policy meets this baseline but excludes users/groups/apps/guests. Add them to your config to pass.' }
    }
    return @{ Result = 'Fail'; Action = 'FIX_POLICY'; RootCause = 'The best-matching policy needs configuration changes to pass this baseline.' }
}

# ------------------------------------------------------------------------------------
# Live tenant scan (Microsoft Graph) - schema-driven, no ScubaGear run
# ------------------------------------------------------------------------------------

function Get-ScubaAnalyzerScopes {
    <#
    .SYNOPSIS
    Aggregates the Microsoft Graph delegated scopes a product's controls need, resolved
    from the API catalog (least permissions per cmdlet named in the baseline schema).
    #>
    param(
        [Parameter(Mandatory)][string]$Product,
        [Parameter(Mandatory)]$BaselineSchema,
        [string]$ApiCatalogPath
    )

    $prod = $Product.ToLower()
    $cmdlets = @()
    if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $prod) {
        foreach ($c in $BaselineSchema.baselineValidations.$prod) { if ($c.apiPermissionRef) { $cmdlets += $c.apiPermissionRef } }
    }
    $cmdlets = @($cmdlets | Select-Object -Unique)

    $scopes = New-Object System.Collections.Generic.HashSet[string]
    if ($ApiCatalogPath -and (Test-Path $ApiCatalogPath)) {
        try {
            $catalog = Get-Content $ApiCatalogPath -Raw | ConvertFrom-Json
            foreach ($cmd in $cmdlets) {
                $entry = $catalog | Where-Object { $_.moduleCmdlet -eq $cmd } | Select-Object -First 1
                if ($entry -and $entry.leastPermissions) {
                    foreach ($p in @($entry.leastPermissions)) { if ($p) { [void]$scopes.Add([string]$p) } }
                }
            }
        } catch { }
    }
    # Always include CA policy + directory read (tenant/org details + name resolution).
    [void]$scopes.Add('Policy.Read.All')
    [void]$scopes.Add('Directory.Read.All')
    return @($scopes)
}

function Connect-ScubaAnalyzerGraph {
    <#
    .SYNOPSIS
    Connects to Microsoft Graph for the given environment and scopes. Should be called
    on the UI thread (interactive auth needs the window handle). Returns Get-MgContext.
    #>
    param(
        [Parameter(Mandatory)][string[]]$Scopes,
        [string]$M365Environment = 'commercial'
    )

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    $graphEnv = switch ($M365Environment) {
        'gcchigh' { 'USGov' }
        'dod'     { 'USGovDoD' }
        default   { 'Global' }
    }
    $connectParams = @{ Scopes = $Scopes; Environment = $graphEnv; NoWelcome = $true; ErrorAction = 'Stop' }
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
    Best-effort resolve of display names for users, groups, and applications excluded
    across the given Conditional Access policies, via Microsoft Graph. Returns id -> name,
    used to annotate the generated YAML. Requires an active Graph connection; failures for
    individual ids are ignored (the id is simply left uncommented).
    #>
    param([array]$Policies = @())

    $lookup = @{}
    $guidRe = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

    $userIds = @(); $groupIds = @(); $appIds = @()
    foreach ($p in @($Policies)) {
        $userIds  += @($p.conditions.users.excludeUsers)
        $groupIds += @($p.conditions.users.excludeGroups)
        $appIds   += @($p.conditions.applications.excludeApplications)
    }
    $userIds  = @($userIds  | Where-Object { $_ -match $guidRe } | Select-Object -Unique)
    $groupIds = @($groupIds | Where-Object { $_ -match $guidRe } | Select-Object -Unique)
    $appIds   = @($appIds   | Where-Object { $_ -match $guidRe } | Select-Object -Unique)

    foreach ($id in $userIds) {
        try {
            $o = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/$id" + '?$select=displayName,userPrincipalName') -OutputType PSObject -ErrorAction Stop
            if ($o) { $lookup[$id] = if ($o.displayName) { $o.displayName } else { $o.userPrincipalName } }
        } catch { }
    }
    foreach ($id in $groupIds) {
        try {
            $o = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/$id" + '?$select=displayName') -OutputType PSObject -ErrorAction Stop
            if ($o -and $o.displayName) { $lookup[$id] = $o.displayName }
        } catch { }
    }
    foreach ($id in $appIds) {
        try {
            $o = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/servicePrincipals(appId='$id')" + '?$select=displayName') -OutputType PSObject -ErrorAction Stop
            if ($o -and $o.displayName) { $lookup[$id] = $o.displayName }
        } catch { }
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
        [string]$ApiCatalogPath
    )

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    $data = @{ conditional_access_policies = @(); OrgDisplayName = $null; Organization = $null; TenantId = $null; DisplayNameLookup = @{} }

    # cmdlet -> apiResource map from the catalog (JSON-driven, changeable).
    $resourceMap = @{}
    if ($ApiCatalogPath -and (Test-Path $ApiCatalogPath)) {
        try {
            $catalog = Get-Content $ApiCatalogPath -Raw | ConvertFrom-Json
            foreach ($e in $catalog) { if ($e.moduleCmdlet -and $e.apiResource) { $resourceMap[$e.moduleCmdlet] = $e.apiResource } }
        } catch { }
    }

    $prod = $Product.ToLower()
    $controls = @()
    if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $prod) {
        $controls = @($BaselineSchema.baselineValidations.$prod)
    }

    # Tenant identity.
    try { $ctx = Get-MgContext; if ($ctx) { $data.TenantId = $ctx.TenantId } } catch { }
    try {
        $org = @(Invoke-ScubaGraphGet -Uri '/v1.0/organization')
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
    } catch { }

    # Conditional Access policies: resolve the read resource for the CA cmdlet.
    $caCmdlet = 'Get-MgBetaIdentityConditionalAccessPolicy'
    $usesCa = @($controls | Where-Object { $_.apiPermissionRef -eq $caCmdlet }).Count -gt 0
    if ($usesCa) {
        $uri = $null
        if ($resourceMap.ContainsKey($caCmdlet)) { $uri = $resourceMap[$caCmdlet] }
        if (-not $uri) {
            $caControl = @($controls | Where-Object { $_.apiPermissionRef -eq $caCmdlet -and $_.buildInstructions.apiResourceCreate })[0]
            if ($caControl) { $uri = $caControl.buildInstructions.apiResourceCreate }
        }
        if (-not $uri) { $uri = '/beta/identity/conditionalAccess/policies' }
        $data.conditional_access_policies = @(Invoke-ScubaGraphGet -Uri $uri)
        # Resolve display names for excluded principals/apps so the generated YAML can be annotated.
        try { $data.DisplayNameLookup = Get-ScADisplayNameLookup -Policies $data.conditional_access_policies } catch { }
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

    if (-not $BaselineSchemaPath) { $BaselineSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearResultsBaselineSchema.json' }
    if (-not $AnalyzerSchemaPath) { $AnalyzerSchemaPath = Resolve-ScASchemaPath -FileName 'ScubaGearAnalyzerSchema.json' }
    if (-not $ConfigSchemaPath)   { $ConfigSchemaPath   = Resolve-ScAConfigSchemaPath }
    if (-not (Test-Path $BaselineSchemaPath)) { throw "Baseline schema not found: $BaselineSchemaPath" }
    if (-not (Test-Path $AnalyzerSchemaPath)) { throw "Analyzer schema not found: $AnalyzerSchemaPath" }

    # Load the canonical config schema's exclusion mappings so configurability is JSON-driven.
    Import-ScAConfigurableMap -ConfigSchemaPath $ConfigSchemaPath

    $baselineSchema = Get-Content $BaselineSchemaPath -Raw | ConvertFrom-Json
    $analyzerSchema = Get-Content $AnalyzerSchemaPath -Raw | ConvertFrom-Json
    $script:ScAFriendlyNames = if ($analyzerSchema.RequirementFriendlyNames.default) { $analyzerSchema.RequirementFriendlyNames.default } elseif ($analyzerSchema.RequirementFriendlyNames) { $analyzerSchema.RequirementFriendlyNames } else { $null }

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
            $detectedExclusions = if ($bestMatch) { Get-ScAExclusionsFromIssues -Issues @($bestMatch.Issues) } else { @{ Users = @(); Groups = @(); Applications = @(); GuestUserTypes = @() } }
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
