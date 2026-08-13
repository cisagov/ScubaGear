<#
.SYNOPSIS
    Analyzer helper: Conditional Access policy analysis.
.NOTES
    Imported (Import-Module) by Start-SCuBAConfigAnalyzer alongside the other analyzer
    helpers. Shared analyzer state lives on the synchronized $syncHash ($syncHash.ScA*), so
    every helper module reads/writes the same caches (mirrors how ScubaConfigApp shares
    state). Populated at scan time by Import-ScA*.
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

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

    $rules          = $syncHash.ScACaRules
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

