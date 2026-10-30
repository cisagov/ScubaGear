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
    $flagged  = @()
    $blocking = @()
    $issues   = @()

    foreach ($det in @($an.detectors)) {
        # A detector may target a different field than the exclusion type (rare); default to it.
        $key = if ($det.field) { [string]$det.field } else { $ExclusionField }
        foreach ($item in @($items)) {
            if ($det.flagWhen -and -not (Test-ScAFlagCondition -Item $item -Condition $det.flagWhen)) { continue }

            # valueFrom may resolve to a scalar or an array (e.g. TargetedUsersToProtect).
            $resolved = Get-ScAValueAtPath -Object $item -Path ([string]$det.valueFrom)
            foreach ($value in @($resolved)) {
                if ($null -eq $value -or [string]$value -eq '') { continue }

                # A nonExcludable detector finds a problem the config file cannot waive (for
                # example the default remote domain). It fails the control and needs a tenant
                # change, but it is never offered as an exclusion value.
                if ($det.nonExcludable) {
                    $blocking += [string]$value
                    $blockLbl = if ($det.issueLabel) { [string]$det.issueLabel } else { 'item' }
                    $blockSug = if ($det.suggestion) { [string]$det.suggestion } else { 'Change the tenant setting; this cannot be allow-listed in the ScubaGear config.' }
                    $issues += "ERROR: $blockLbl`: $value|SUGGESTION:$blockSug"
                    continue
                }

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
        Blocking        = @($blocking | Select-Object -Unique)
        ExclusionValues = $exclusionValues
        Issues          = $issues
    }
}

function Get-ScAProviderRootCause {
    <#
    .SYNOPSIS
    Derives the root cause, required action and recommendations for a failing provider
    (non-CA) control from its Get-ScAProviderAnalysis result.
    .DESCRIPTION
    Flagged values can be waived with config exclusions. Blocking values (from detectors
    marked nonExcludable, e.g. the default remote domain) cannot - they need a tenant change.
    When only blocking values exist the control needs no exclusions at all.
    #>
    param([Parameter(Mandatory)]$ProviderAnalysis)

    $flagged  = @($ProviderAnalysis.Flagged)
    $blocking = @($ProviderAnalysis.Blocking)

    if ($blocking.Count -gt 0 -and $flagged.Count -gt 0) {
        return @{
            RootCause       = "$($blocking.Count) item(s) must be fixed in the tenant and cannot be allow-listed: $($blocking -join ', '). $($flagged.Count) other item(s) flagged that can be allow-listed: $($flagged -join ', ')"
            RequiresAction  = 'EXCLUDE'
            Recommendations = @(
                'Fix the tenant setting for the items that cannot be allow-listed (see remediation steps); the control still fails until they are fixed.',
                'Review the other flagged entries below - add approved ones to the exclusion allow-list; otherwise change the tenant setting.'
            )
        }
    }
    if ($blocking.Count -gt 0) {
        return @{
            RootCause       = "$($blocking.Count) item(s) must be fixed in the tenant and cannot be allow-listed in the ScubaGear config: $($blocking -join ', ')"
            RequiresAction  = 'FIX_TENANT'
            Recommendations = @('No exclusions are needed for this control. Fix the tenant setting (see remediation steps), then re-scan.')
        }
    }
    if ($ProviderAnalysis -is [System.Collections.IDictionary] -and $ProviderAnalysis.Contains('RootCause') -and $ProviderAnalysis['RootCause']) {
        $action = if ($ProviderAnalysis.Contains('RequiresAction') -and $ProviderAnalysis['RequiresAction']) { [string]$ProviderAnalysis['RequiresAction'] } else { 'FIX_TENANT' }
        return @{
            RootCause       = [string]$ProviderAnalysis['RootCause']
            RequiresAction  = $action
            Recommendations = @($ProviderAnalysis['Recommendations'] | Where-Object { $_ })
        }
    }
    if ($flagged.Count -gt 0) {
        return @{
            RootCause       = "$($flagged.Count) item(s) flagged: $($flagged -join ', ')"
            RequiresAction  = 'EXCLUDE'
            Recommendations = @('Review the flagged entries below - add approved ones to the exclusion allow-list; otherwise change the tenant setting (see remediation steps).')
        }
    }
    return @{ RootCause = 'The tenant setting does not meet this baseline.'; RequiresAction = 'FIX_TENANT'; Recommendations = @() }
}

function Get-ScANonCaRootCause {
    <#
    .SYNOPSIS
    Root cause for a control that is not a Conditional Access policy and has no provider analysis.
    #>
    param(
        [string]$Result,
        [string]$ValidationType,
        $ValidationSchema
    )

    if ($Result -eq 'Pass') {
        return @{ RootCause = 'Compliant'; RequiresAction = 'NONE'; Recommendations = @() }
    }

    # A failed data-collection command is not evidence the tenant is noncompliant.
    # This matches the non-Conditional-Access branch of Get-ScARootCause.
    if ($Result -eq 'Error') {
        return @{
            RootCause       = 'Command execution error'
            RequiresAction  = 'CHECK_PERMISSIONS'
            Recommendations = @('Verify Microsoft Graph permissions and connection.')
        }
    }

    # ScubaGear exports N/A for unimplemented checks and Omitted when a policy is omitted.
    # Neither is a failure, so they keep the previous manual-review classification.
    if ($Result -eq 'N/A' -or $Result -eq 'Omitted') {
        return @{
            RootCause       = 'Manual review required'
            RequiresAction  = 'REVIEW'
            Recommendations = @()
        }
    }

    $recs = @()
    if ($ValidationSchema -and $ValidationSchema.remediationContent.recommendations) {
        $recs = @($ValidationSchema.remediationContent.recommendations)
    }

    # Only a recorded Fail is a tenant fix. Warning, Manual, and any other status stay a review.
    $action = if ($Result -eq 'Fail') { 'FIX_TENANT' } else { 'REVIEW' }

    if ($ValidationType -eq 'roleAssignmentAnalysis') {
        return @{
            RootCause       = 'This baseline covers privileged role assignments, not Conditional Access. Follow the remediation steps; creating a Conditional Access policy will not satisfy it.'
            RequiresAction  = $action
            Recommendations = $recs
        }
    }

    if ($action -eq 'REVIEW') {
        return @{
            RootCause       = 'This baseline is configured outside Conditional Access and needs manual review (see steps).'
            RequiresAction  = 'REVIEW'
            Recommendations = $recs
        }
    }

    return @{
        RootCause       = 'This baseline is configured outside Conditional Access. Follow the remediation steps; a Conditional Access policy will not satisfy it.'
        RequiresAction  = 'FIX_TENANT'
        Recommendations = $recs
    }
}

function Test-ScAMember {
    <#
    .SYNOPSIS
    True when a PSCustomObject or hashtable has the named member.
    #>
    param($Object, [string]$Name)
    if ($null -eq $Object -or [string]::IsNullOrWhiteSpace($Name)) { return $false }
    if ($Object -is [System.Collections.IDictionary]) { return [bool]$Object.Contains($Name) }
    return [bool]($Object.PSObject.Properties.Name -contains $Name)
}

function Get-ScADictionaryEntries {
    <#
    .SYNOPSIS
    Returns name/value pairs for a hashtable or a PSCustomObject.
    #>
    param($Object)
    if ($null -eq $Object) { return @() }
    if ($Object -is [System.Collections.IDictionary]) {
        return @($Object.Keys | ForEach-Object { [pscustomobject]@{ Name = [string]$_; Value = $Object[$_] } })
    }
    return @($Object.PSObject.Properties | ForEach-Object { [pscustomobject]@{ Name = [string]$_.Name; Value = $_.Value } })
}

function Get-ScAPrivilegedRoleAssignmentAnalysis {
    <#
    .SYNOPSIS
    Finds permanent active assignments on highly privileged roles for MS.AAD.7.4v1.
    .DESCRIPTION
    ScubaGear stores these on Raw.privileged_roles. A permanent assignment is one
    whose EndDateTime is JSON null, the same test as Rego (x.EndDateTime == null).
    A missing property is undefined in Rego and is not a match. A blank string is
    not null either. Principals found in
    privileged_users are RoleExclusions users. Privileged service principals are listed
    there too, because RoleExclusions has no separate service-principal list. Every other
    principal is reported as a group.

    PIM for Groups enrollment is recorded as role rules with RuleSourceType "PIM Group",
    and those rules carry a display name rather than the group object id. A group is
    therefore not treated as enrolled unless the caller can match it; the recommendations
    say when verification is still required.
    Returns $null when the results have no privileged_roles property.
    #>
    param([Parameter(Mandatory)]$Raw)

    if (-not (Test-ScAMember $Raw 'privileged_roles')) { return $null }
    $privilegedRoles = if ($Raw -is [System.Collections.IDictionary]) { $Raw['privileged_roles'] } else { $Raw.privileged_roles }

    $hasAssignmentData = $false
    foreach ($role in @($privilegedRoles)) {
        if (Test-ScAMember $role 'Assignments') { $hasAssignmentData = $true; break }
    }
    if (@($privilegedRoles).Count -gt 0 -and -not $hasAssignmentData) {
        # Roles were listed, but assignments were not collected (for example, no Entra ID P2).
        return @{
            ItemCount = 0; Flagged = @(); Blocking = @(); ExclusionValues = [ordered]@{}; Issues = @()
            RootCause = ''; RequiresAction = 'REVIEW'; Recommendations = @()
        }
    }

    $userIds = @()
    $userNames = @{}
    $privilegedUsers = if ($Raw -is [System.Collections.IDictionary]) { $Raw['privileged_users'] } else { $Raw.privileged_users }
    if ((Test-ScAMember $Raw 'privileged_users') -and $privilegedUsers) {
        foreach ($p in @(Get-ScADictionaryEntries $privilegedUsers)) {
            $userIds += [string]$p.Name
            if ($p.Value -and $p.Value.DisplayName) { $userNames[[string]$p.Name] = [string]$p.Value.DisplayName }
        }
    }
    $spIds = @()
    $spNames = @{}
    $privilegedServicePrincipals = if ($Raw -is [System.Collections.IDictionary]) { $Raw['privileged_service_principals'] } else { $Raw.privileged_service_principals }
    if ((Test-ScAMember $Raw 'privileged_service_principals') -and $privilegedServicePrincipals) {
        foreach ($p in @(Get-ScADictionaryEntries $privilegedServicePrincipals)) {
            $spIds += [string]$p.Name
            if ($p.Value -and $p.Value.DisplayName) { $spNames[[string]$p.Name] = [string]$p.Value.DisplayName }
        }
    }

    $users = [System.Collections.Generic.List[string]]::new()
    $groups = [System.Collections.Generic.List[string]]::new()
    $servicePrincipals = [System.Collections.Generic.List[string]]::new()
    $roleNames = [System.Collections.Generic.List[string]]::new()
    $pimGroupNotes = [System.Collections.Generic.List[string]]::new()

    foreach ($role in @($privilegedRoles)) {
        if (-not $role) { continue }
        $roleName = if ($role.DisplayName) { [string]$role.DisplayName } else { 'privileged role' }
        $pimSources = @()
        $rules = if (Test-ScAMember $role 'Rules') { $role.Rules } else { $null }
        if ($rules) {
            $pimSources = @($rules | Where-Object { $_.RuleSourceType -eq 'PIM Group' -and $_.RuleSource } | ForEach-Object { [string]$_.RuleSource } | Select-Object -Unique)
        }
        $roleHasPermanent = $false
        foreach ($assignment in @($role.Assignments)) {
            if (-not $assignment) { continue }
            # Rego: x.EndDateTime == null. Missing is undefined, and "" == null is false.
            if (-not (Test-ScAMember $assignment 'EndDateTime')) { continue }
            if ($null -ne $assignment.EndDateTime) { continue }
            $id = if ($assignment.PrincipalId) { [string]$assignment.PrincipalId } else { '' }
            if ([string]::IsNullOrWhiteSpace($id)) { continue }
            $roleHasPermanent = $true
            if ($userIds -contains $id) {
                if (-not $users.Contains($id)) { $users.Add($id) }
            } elseif ($spIds -contains $id) {
                if (-not $servicePrincipals.Contains($id)) { $servicePrincipals.Add($id) }
            } elseif (-not $groups.Contains($id)) {
                $groups.Add($id)
            }
        }
        if ($roleHasPermanent -and -not $roleNames.Contains($roleName)) { $roleNames.Add($roleName) }
        if ($pimSources.Count -gt 0) {
            $note = "$roleName`: $($pimSources -join ', ')"
            if (-not $pimGroupNotes.Contains($note)) { $pimGroupNotes.Add($note) }
        }
    }

    foreach ($id in @($servicePrincipals)) {
        if (-not $users.Contains($id)) { $users.Add($id) }
    }

    $exclusionValues = [ordered]@{}
    if ($users.Count -gt 0) { $exclusionValues['Users'] = @($users.ToArray()) }
    if ($groups.Count -gt 0) { $exclusionValues['Groups'] = @($groups.ToArray()) }
    $flaggedIds = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $users) { $flaggedIds.Add($id) }
    foreach ($id in $groups) { $flaggedIds.Add($id) }
    $flagged = @($flaggedIds.ToArray())

    $recs = @(
        'Replace unjustified permanent active assignments with eligible or time-limited assignments in Privileged Identity Management (PIM) or an alternative privileged access management (PAM) system.',
        'Emergency access accounts, and service accounts that cannot perform role activation, may keep a permanent active assignment. Add only those object ids under RoleExclusions.',
        'A group enrolled in PIM for Groups may keep a permanent active role assignment, because activation is managed through PIM for Groups. Do not assume every group qualifies.'
    )
    if ($groups.Count -gt 0 -and $pimGroupNotes.Count -gt 0) {
        $recs += "These results show PIM for Groups configuration on $($pimGroupNotes -join '; '). Confirm each group below is one of those enrolled groups before excluding it or recreating its assignment."
    } elseif ($groups.Count -gt 0) {
        $recs += 'Permanent group assignments were found, and these results do not show PIM for Groups enrollment for them. Verify enrollment before treating a group as an exception.'
    }
    if ($servicePrincipals.Count -gt 0) {
        $named = @($servicePrincipals | ForEach-Object { if ($spNames.ContainsKey($_)) { "$($spNames[$_]) ($_)" } else { $_ } })
        $recs += "Service principals with a permanent active assignment are listed under RoleExclusions Users, because that is the list ScubaGear checks: $($named -join ', '). Keep one only when it is an approved service account."
    }

    $root = if ($flagged.Count -gt 0) {
        "$($flagged.Count) principal(s) have a permanent active assignment on $($roleNames -join ', '). This control covers privileged role assignments, not Conditional Access."
    } else {
        'No permanent active privileged role assignments were found. If this control failed, confirm the Entra ID P2 license or the alternative PAM system. This is not a Conditional Access control.'
    }

    return @{
        ItemCount       = @($privilegedRoles).Count
        Flagged         = @($flagged | Select-Object -Unique)
        Blocking        = @()
        ExclusionValues = $exclusionValues
        Issues          = @()
        RootCause       = $root
        RequiresAction  = 'FIX_TENANT'
        Recommendations = $recs
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

    # Initialize the output hashtable for configured exclusion values.
    # This function navigates the nested structure of the imported ScubaResults to extract
    # the values already configured for a specific exclusion field within a control.
    $out = [ordered]@{}
    # Return an empty ordered hashtable if any of the required nested structures are missing.
    if (-not $Raw -or -not ($Raw.PSObject.Properties.Name -contains 'scuba_config')) { return $out }
    $cfg = $Raw.scuba_config
    # Return an empty ordered hashtable if the product configuration key is missing.
    if (-not $cfg -or -not ($cfg.PSObject.Properties.Name -contains $ProductConfigKey)) { return $out }
    $prod = $cfg.$ProductConfigKey
    # Return an empty ordered hashtable if the control ID is missing.
    if (-not $prod -or -not ($prod.PSObject.Properties.Name -contains $ControlId)) { return $out }
    $ctl = $prod.$ControlId
    # Return an empty ordered hashtable if the exclusion field is missing.
    if (-not $ctl -or -not ($ctl.PSObject.Properties.Name -contains $ExclusionField)) { return $out }
    $val = $ctl.$ExclusionField

    # Determine the shape of the exclusion field (list or principal) based on the schema definitions.
    $schema = if ($syncHash.ScAExclusionDefinitions.ContainsKey($ExclusionField)) { $syncHash.ScAExclusionDefinitions[$ExclusionField] } else { $null }
    $shape  = if ($schema -and $schema.valueShape) { [string]$schema.valueShape } else { 'list' }

    # Extract the configured exclusion values based on the determined shape.
    # For list-shaped fields, the values are stored directly in an array.
    if ($shape -eq 'list') {
        $list = @($val | Where-Object { $_ })
        # Only add the list to the output if it contains one or more values.
        if (@($list).Count -gt 0) { $out[$ExclusionField] = $list }
    } else {
        # For principal-shaped fields, the values are stored as named lists within an object.
        foreach ($p in @($val.PSObject.Properties)) {
            $items = @($p.Value | Where-Object { $_ })
            if (@($items).Count -gt 0) { $out[$p.Name] = @($items) }
        }
    }

    # Return the configured exclusion values for the specified field.
    return $out
}

