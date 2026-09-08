<#
.SYNOPSIS
    Generates Microsoft 365 tenant governance configuration from analyzer CA policies.
.NOTES
    Imported with the other Scuba Config Analyzer helpers. Conversion is kept separate
    from UI actions so imported and live policy collections use the same implementation.
#>

function Get-ScATenantGovernanceValue {
    param(
        [Parameter(Mandatory)]$InputObject,
        [Parameter(Mandatory)][string]$Path
    )

    $value = $InputObject
    foreach ($part in $Path -split '\.') {
        if ($null -eq $value -or -not ($value.PSObject.Properties.Name -contains $part)) { return $null }
        $value = $value.$part
    }
    return $value
}

function Add-ScATenantGovernanceProperty {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Properties,
        [Parameter(Mandatory)][string]$Name,
        $Value
    )

    if ($null -eq $Value) { return }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) { return }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string] -and @($Value).Count -eq 0) { return }
    $Properties[$Name] = $Value
}

function ConvertTo-ScATenantGovernancePolicy {
    <#
    .SYNOPSIS
    Maps one Conditional Access policy to a tenant governance resource
    (microsoft.entra.conditionalaccesspolicy). Returns $null when the policy has no display name.
    Object ids (users/groups/roles/apps) are translated to display names via -DisplayNameLookup
    because the governance monitor compares those references by name, not by id.
    #>
    param(
        [Parameter(Mandatory)]$Policy,
        [System.Collections.IDictionary]$DisplayNameLookup = @{}
    )

    $displayName = [string](Get-ScATenantGovernanceValue -InputObject $Policy -Path 'DisplayName')
    if ([string]::IsNullOrWhiteSpace($displayName)) { return $null }

    $properties = [ordered]@{ DisplayName = $displayName }
    $propertyMap = [ordered]@{
        Id                                       = 'Id'
        State                                    = 'State'
        IncludeApplications                      = 'Conditions.Applications.IncludeApplications'
        ApplicationsFilter                       = 'Conditions.Applications.ApplicationFilter.Rule'
        ApplicationsFilterMode                   = 'Conditions.Applications.ApplicationFilter.Mode'
        ExcludeApplications                      = 'Conditions.Applications.ExcludeApplications'
        IncludeUserActions                       = 'Conditions.Applications.IncludeUserActions'
        IncludeUsers                             = 'Conditions.Users.IncludeUsers'
        ExcludeUsers                             = 'Conditions.Users.ExcludeUsers'
        IncludeGroups                            = 'Conditions.Users.IncludeGroups'
        ExcludeGroups                            = 'Conditions.Users.ExcludeGroups'
        IncludeRoles                             = 'Conditions.Users.IncludeRoles'
        ExcludeRoles                             = 'Conditions.Users.ExcludeRoles'
        IncludeGuestOrExternalUserTypes          = 'Conditions.Users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes'
        IncludeExternalTenantsMembershipKind     = 'Conditions.Users.IncludeGuestsOrExternalUsers.ExternalTenants.MembershipKind'
        IncludeExternalTenantsMembers            = 'Conditions.Users.IncludeGuestsOrExternalUsers.ExternalTenants.AdditionalProperties.Members'
        ExcludeGuestOrExternalUserTypes          = 'Conditions.Users.ExcludeGuestsOrExternalUsers.GuestOrExternalUserTypes'
        ExcludeExternalTenantsMembershipKind     = 'Conditions.Users.ExcludeGuestsOrExternalUsers.ExternalTenants.MembershipKind'
        ExcludeExternalTenantsMembers            = 'Conditions.Users.ExcludeGuestsOrExternalUsers.ExternalTenants.AdditionalProperties.Members'
        IncludePlatforms                         = 'Conditions.Platforms.IncludePlatforms'
        ExcludePlatforms                         = 'Conditions.Platforms.ExcludePlatforms'
        IncludeLocations                         = 'Conditions.Locations.IncludeLocations'
        ExcludeLocations                         = 'Conditions.Locations.ExcludeLocations'
        DeviceFilterMode                         = 'Conditions.Devices.DeviceFilter.Mode'
        DeviceFilterRule                         = 'Conditions.Devices.DeviceFilter.Rule'
        UserRiskLevels                           = 'Conditions.UserRiskLevels'
        SignInRiskLevels                         = 'Conditions.SignInRiskLevels'
        ClientAppTypes                           = 'Conditions.ClientAppTypes'
        GrantControlOperator                     = 'GrantControls.Operator'
        BuiltInControls                          = 'GrantControls.BuiltInControls'
        ApplicationEnforcedRestrictionsIsEnabled = 'SessionControls.ApplicationEnforcedRestrictions.IsEnabled'
        CloudAppSecurityIsEnabled                = 'SessionControls.CloudAppSecurity.IsEnabled'
        CloudAppSecurityType                     = 'SessionControls.CloudAppSecurity.CloudAppSecurityType'
        SignInFrequencyValue                     = 'SessionControls.SignInFrequency.Value'
        TermsOfUse                               = 'GrantControls.TermsOfUse'
        CustomAuthenticationFactors              = 'GrantControls.CustomAuthenticationFactors'
        SignInFrequencyType                      = 'SessionControls.SignInFrequency.Type'
        SignInFrequencyIsEnabled                 = 'SessionControls.SignInFrequency.IsEnabled'
        SignInFrequencyInterval                  = 'SessionControls.SignInFrequency.FrequencyInterval'
        PersistentBrowserIsEnabled               = 'SessionControls.PersistentBrowser.IsEnabled'
        PersistentBrowserMode                    = 'SessionControls.PersistentBrowser.Mode'
        AuthenticationStrength                   = 'GrantControls.AuthenticationStrength.DisplayName'
        AuthenticationContexts                   = 'Conditions.Applications.IncludeAuthenticationContextClassReferences'
    }

    foreach ($entry in $propertyMap.GetEnumerator()) {
        $value = Get-ScATenantGovernanceValue -InputObject $Policy -Path $entry.Value
        $arrayProperties = @(
            'IncludeApplications', 'ExcludeApplications', 'IncludeUserActions', 'IncludeUsers', 'ExcludeUsers',
            'IncludeGroups', 'ExcludeGroups', 'IncludeRoles', 'ExcludeRoles', 'IncludeGuestOrExternalUserTypes',
            'IncludeExternalTenantsMembers', 'ExcludeGuestOrExternalUserTypes', 'ExcludeExternalTenantsMembers',
            'IncludePlatforms', 'ExcludePlatforms', 'IncludeLocations', 'ExcludeLocations', 'UserRiskLevels',
            'SignInRiskLevels', 'ClientAppTypes', 'BuiltInControls', 'CustomAuthenticationFactors',
            'AuthenticationContexts'
        )
        if ($null -ne $value -and $arrayProperties -contains $entry.Key) { $value = @($value) }
        Add-ScATenantGovernanceProperty -Properties $properties -Name $entry.Key -Value $value
    }

    # AuthenticationStrength maps to the embedded DisplayName above (the monitor compares by
    # name); fall back to the id only when the policy exposes no strength display name.
    if (-not $properties.Contains('AuthenticationStrength')) {
        $authStrengthId = Get-ScATenantGovernanceValue -InputObject $Policy -Path 'GrantControls.AuthenticationStrength.Id'
        Add-ScATenantGovernanceProperty -Properties $properties -Name 'AuthenticationStrength' -Value $authStrengthId
    }

    # The governance monitor represents principals, roles, and apps by DISPLAY NAME, so
    # translate the collected object ids through the resolved lookup. Unresolved ids and
    # non-id literals ('All', 'None', 'GuestsOrExternalUsers', ...) are left unchanged.
    if ($DisplayNameLookup -and $DisplayNameLookup.Count -gt 0) {
        $nameTranslatedFields = @(
            'IncludeUsers', 'ExcludeUsers', 'IncludeGroups', 'ExcludeGroups',
            'IncludeRoles', 'ExcludeRoles', 'IncludeApplications', 'ExcludeApplications',
            'IncludeLocations', 'ExcludeLocations'
        )
        foreach ($field in $nameTranslatedFields) {
            if (-not $properties.Contains($field)) { continue }
            $properties[$field] = @(@($properties[$field]) | ForEach-Object {
                $key = [string]$_
                if ($DisplayNameLookup.Contains($key)) { $DisplayNameLookup[$key] } else { $_ }
            })
        }
    }

    $properties.Ensure = 'Present'

    return [ordered]@{
        displayName = $displayName
        resourceType = 'microsoft.entra.conditionalaccesspolicy'
        properties = $properties
    }
}

function ConvertTo-ScATenantGovernanceJson {
    <#
    .SYNOPSIS
    Builds the tenant governance baseline JSON document from the collected Conditional Access policies.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TenantId', Justification = 'Kept for signature/caller compatibility; the baseline document is tenant-agnostic.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'SchemaUrl', Justification = 'Kept for signature/caller compatibility; the governance API expects the baseline object without a $schema wrapper.')]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ConditionalAccessPolicies,
        [string]$TenantId,
        [string]$DisplayName = 'ScubaGear Entra ID tenant governance baseline',
        [string]$SchemaUrl = 'https://www.schemastore.org/utcm-monitor.json',
        [System.Collections.IDictionary]$DisplayNameLookup = @{},
        [string[]]$IncludePolicyId = @()
    )

    # When policy ids are supplied, scope the document to just those (the analyzer passes the
    # policies it matched to a ScubaGear baseline); otherwise every collected policy is emitted.
    $policies = @($ConditionalAccessPolicies)
    if (@($IncludePolicyId).Count -gt 0) {
        $idSet = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($id in $IncludePolicyId) { if (-not [string]::IsNullOrWhiteSpace([string]$id)) { [void]$idSet.Add([string]$id) } }
        $policies = @($policies | Where-Object { $_ -and $idSet.Contains([string]$_.Id) })
    }

    $resources = @($policies | ForEach-Object { ConvertTo-ScATenantGovernancePolicy -Policy $_ -DisplayNameLookup $DisplayNameLookup } | Where-Object { $null -ne $_ })
    # The tenant governance API expects the baseline object itself (parameters as an array), not a wrapper.
    $document = [ordered]@{
        displayName = $DisplayName
        description = 'Tenant governance baseline generated by the ScubaGear Config Analyzer from collected Entra ID Conditional Access policies.'
        parameters = @()
        resources = $resources
    }
    return ($document | ConvertTo-Json -Depth 30)
}

function Get-ScATenantGovernanceMatchedPolicyId {
    <#
    .SYNOPSIS
    Returns the distinct Conditional Access policy ids the analysis identified as the best
    match for a ScubaGear baseline (one per finding), so the governance monitor JSON can be
    scoped to just the ScubaGear-mapped policies.
    #>
    param([Parameter(Mandatory)][AllowNull()]$Findings)

    $ids = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($finding in @($Findings)) {
        # The single policy ScubaGear identified as implementing (or closest to) this baseline -
        # its best match. Merely-relevant candidates are excluded so the set stays the mapped
        # policies, not every policy that touches a baseline area.
        $matchId = if (-not [string]::IsNullOrWhiteSpace([string]$finding.SelectedPolicyId)) { [string]$finding.SelectedPolicyId }
                   elseif ($finding.BestMatch -and $finding.BestMatch.Id) { [string]$finding.BestMatch.Id }
                   else { $null }
        if ($matchId) { [void]$ids.Add($matchId) }
    }
    return @($ids)
}

function Update-ScubaAnalyzerTenantGovernanceJson {
    <#
    .SYNOPSIS
    Refreshes the Tenant Governance JSON text box from the current analysis; no-op unless generation is enabled.
    The 'ScubaGear baseline policies only' checkbox scopes the output to the analyzer-matched policies.
    #>
    if (-not $syncHash.GenerateTenantGovernanceConfig -or -not $syncHash.TenantGovernanceJson_TextBox -or -not $syncHash.Analysis) { return }
    $displayNameLookup = if ($syncHash.Analysis.DisplayNameLookup -is [System.Collections.IDictionary]) { $syncHash.Analysis.DisplayNameLookup } else { @{} }
    $includePolicyId = @()
    if ($syncHash.TenantGovernanceScubaOnly_CheckBox -and $syncHash.TenantGovernanceScubaOnly_CheckBox.IsChecked) {
        $includePolicyId = @(Get-ScATenantGovernanceMatchedPolicyId -Findings $syncHash.Analysis.Findings)
    }
    $syncHash.TenantGovernanceJson_TextBox.Text = ConvertTo-ScATenantGovernanceJson `
        -ConditionalAccessPolicies @($syncHash.Analysis.ConditionalAccessPolicies) `
        -TenantId ([string]$syncHash.Analysis.MetaData.TenantId) `
        -SchemaUrl ([string]$syncHash.TenantGovernanceSchemaUrl) `
        -DisplayNameLookup $displayNameLookup `
        -IncludePolicyId $includePolicyId
}

function Copy-ScubaAnalyzerTenantGovernanceJson {
    <#
    .SYNOPSIS
    Copies the generated Tenant Governance JSON to the clipboard.
    #>
    try {
        # Rebuild first so Copy always reflects the current 'ScubaGear baseline policies only'
        # selection, even if the checkbox toggle didn't refresh the preview.
        Update-ScubaAnalyzerTenantGovernanceJson
        [System.Windows.Clipboard]::SetText($syncHash.TenantGovernanceJson_TextBox.Text)
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'TenantGovernanceCopied')
    } catch {
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'TenantGovernanceCopyFailed' $_.Exception.Message)
    }
}

function Export-ScubaAnalyzerTenantGovernanceJson {
    <#
    .SYNOPSIS
    Prompts for a path and writes the generated Tenant Governance JSON to a UTF-8 (no BOM) file.
    #>
    try {
        # Rebuild first so the export always reflects the current 'ScubaGear baseline policies
        # only' selection, even if the checkbox toggle didn't refresh the preview.
        Update-ScubaAnalyzerTenantGovernanceJson
        if ([string]::IsNullOrWhiteSpace($syncHash.TenantGovernanceJson_TextBox.Text)) {
            Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'NothingToExport')
            return
        }
        $dialog = New-Object Microsoft.Win32.SaveFileDialog
        $dialog.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
        $dialog.FileName = 'ScubaGear-TenantGovernance.json'
        if ($dialog.ShowDialog() -eq $true) {
            [System.IO.File]::WriteAllText($dialog.FileName, $syncHash.TenantGovernanceJson_TextBox.Text, [System.Text.UTF8Encoding]::new($false))
            Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'TenantGovernanceExported' $dialog.FileName)
        }
    } catch {
        Set-ScubaAnalyzerStatus (Get-ScubaAnalyzerText 'ExportFailed' $_.Exception.Message)
    }
}

Export-ModuleMember -Function @(
    'ConvertTo-ScATenantGovernancePolicy',
    'ConvertTo-ScATenantGovernanceJson',
    'Get-ScATenantGovernanceMatchedPolicyId',
    'Update-ScubaAnalyzerTenantGovernanceJson',
    'Copy-ScubaAnalyzerTenantGovernanceJson',
    'Export-ScubaAnalyzerTenantGovernanceJson'
)
