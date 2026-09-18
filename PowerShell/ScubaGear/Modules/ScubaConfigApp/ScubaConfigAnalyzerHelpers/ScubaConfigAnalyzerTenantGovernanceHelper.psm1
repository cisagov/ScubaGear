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
    # Traverse the path segments to retrieve the nested value from the input object.
    foreach ($part in $Path -split '\.') {
        if ($null -eq $value -or -not ($value.PSObject.Properties.Name -contains $part)) { return $null }
        $value = $value.$part
    }
    # Return the retrieved value, which may be $null if any path segment was missing.
    return $value
}

function Add-ScATenantGovernanceProperty {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Properties,
        [Parameter(Mandatory)][string]$Name,
        $Value
    )

    if ($null -eq $Value) { return }
    # Skip adding the property if the value is null, empty, or whitespace.
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) { return }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string] -and @($Value).Count -eq 0) { return }
    # Add the property to the properties hashtable if it passes the null, empty, or whitespace checks.
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
        [System.Collections.IDictionary]$DisplayNameLookup = @{},
        [System.Collections.IDictionary]$UserPrincipalNameLookup = @{}
    )

    # Retrieve the display name of the policy. If it is null or whitespace, return $null.
    $displayName = [string](Get-ScATenantGovernanceValue -InputObject $Policy -Path 'DisplayName')
    if ([string]::IsNullOrWhiteSpace($displayName)) { return $null }

    # Initialize the properties and property map for the tenant governance resource.
    $properties = [ordered]@{ DisplayName = $displayName }
    # The properties will be populated based on the mappings defined in $propertyMap.
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

    # Iterate over each entry in the property map to populate the properties based on the policy values.
    foreach ($entry in $propertyMap.GetEnumerator()) {
        $value = Get-ScATenantGovernanceValue -InputObject $Policy -Path $entry.Value
        # Ensure that the properties hashtable contains the 'Ensure' key set to 'Present' to indicate the policy is active.
        $arrayProperties = @(
            'IncludeApplications', 'ExcludeApplications', 'IncludeUserActions', 'IncludeUsers', 'ExcludeUsers',
            'IncludeGroups', 'ExcludeGroups', 'IncludeRoles', 'ExcludeRoles', 'IncludeGuestOrExternalUserTypes',
            'IncludeExternalTenantsMembers', 'ExcludeGuestOrExternalUserTypes', 'ExcludeExternalTenantsMembers',
            'IncludePlatforms', 'ExcludePlatforms', 'IncludeLocations', 'ExcludeLocations', 'UserRiskLevels',
            'SignInRiskLevels', 'ClientAppTypes', 'BuiltInControls', 'CustomAuthenticationFactors',
            'AuthenticationContexts'
        )
        # If the policy is active, set the 'Ensure' key to 'Present' in the properties hashtable.
        if ($null -ne $value -and $arrayProperties -contains $entry.Key) { $value = @($value) }
        # Add the property to the properties hashtable, handling array conversion for specific fields.
        Add-ScATenantGovernanceProperty -Properties $properties -Name $entry.Key -Value $value
    }
    # Exclusion field metadata; allows future exclusion types to be emitted without
    # hardcoded field arrays in the YAML builder. Populate the exclusion definitions from the analyzer schema.
    # name); fall back to the id only when the policy exposes no strength display name.
    if (-not $properties.Contains('AuthenticationStrength')) {
        $authStrengthId = Get-ScATenantGovernanceValue -InputObject $Policy -Path 'GrantControls.AuthenticationStrength.Id'
        # If the authentication strength ID is not found, set it to an empty string to avoid null values. 
        Add-ScATenantGovernanceProperty -Properties $properties -Name 'AuthenticationStrength' -Value $authStrengthId
    }

    # The governance monitor represents groups, roles, apps and locations by DISPLAY NAME, but
    # users by USER PRINCIPAL NAME. Translate the collected object ids accordingly; unresolved
    # ids and non-id literals ('All', 'None', 'GuestsOrExternalUsers', ...) are left unchanged.
    if (($DisplayNameLookup -and $DisplayNameLookup.Count -gt 0) -or ($UserPrincipalNameLookup -and $UserPrincipalNameLookup.Count -gt 0)) {
        $userFields = @('IncludeUsers', 'ExcludeUsers')
        # User fields represent the user principal names of the users included or excluded in the policy.
        $nameFields = @(
            'IncludeGroups', 'ExcludeGroups', 'IncludeRoles', 'ExcludeRoles',
            'IncludeApplications', 'ExcludeApplications', 'IncludeLocations', 'ExcludeLocations'
        )
        # Translate the object ids for users, groups, roles, apps, and locations to their display names using the provided lookups.
        foreach ($field in ($userFields + $nameFields)) {
            if (-not $properties.Contains($field)) { continue }
            $isUser = $userFields -contains $field
            $properties[$field] = @(@($properties[$field]) | ForEach-Object {
                $key = [string]$_
                if ($isUser -and $UserPrincipalNameLookup -and $UserPrincipalNameLookup.Contains($key)) { $UserPrincipalNameLookup[$key] }
                elseif ($DisplayNameLookup -and $DisplayNameLookup.Contains($key)) { $DisplayNameLookup[$key] }
                else { $_ }
            })
        }
    }

    # Ensure that the properties hashtable contains the 'Ensure' key set to 'Present' to indicate the policy is active.
    $properties.Ensure = 'Present'

    # Return the final ordered hashtable representing the policy for the tenant governance baseline.
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
        [System.Collections.IDictionary]$UserPrincipalNameLookup = @{},
        [string[]]$IncludePolicyId = @()
    )

    # When policy ids are supplied, scope the document to just those (the analyzer passes the
    # policies it matched to a ScubaGear baseline); otherwise every collected policy is emitted.
    $policies = @($ConditionalAccessPolicies)
    if (@($IncludePolicyId).Count -gt 0) {
        # Create a hash set to store the included policy ids for efficient lookups.
        $idSet = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
        # Populate the hash set with the policy ids to include.
        foreach ($id in $IncludePolicyId) { if (-not [string]::IsNullOrWhiteSpace([string]$id)) { [void]$idSet.Add([string]$id) } }
        # Filter the policies to include only those whose ids are in the hash set.
        $policies = @($policies | Where-Object { $_ -and $idSet.Contains([string]$_.Id) })
    }

    $resources = @($policies | ForEach-Object { ConvertTo-ScATenantGovernancePolicy -Policy $_ -DisplayNameLookup $DisplayNameLookup -UserPrincipalNameLookup $UserPrincipalNameLookup } | Where-Object { $null -ne $_ })
    # The tenant governance API expects the baseline object itself (parameters as an array), not a wrapper.
    $document = [ordered]@{
        displayName = $DisplayName
        description = 'Tenant governance baseline generated by the ScubaGear Config Analyzer from collected Entra ID Conditional Access policies.'
        parameters = @()
        resources = $resources
    }

    # Convert the baseline document to JSON with a depth of 30 to ensure all nested structures are included.
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
        # Add the matched policy id to the set if it exists.
        if ($matchId) { [void]$ids.Add($matchId) }
    }
    # Return the collected policy ids as an array.
    return @($ids)
}

function Update-ScubaAnalyzerTenantGovernanceJson {
    <#
    .SYNOPSIS
    Refreshes the Tenant Governance JSON text box from the current analysis; no-op unless generation is enabled.
    The 'ScubaGear baseline policies only' checkbox scopes the output to the analyzer-matched policies.
    #>
    if (-not $syncHash.GenerateTenantGovernanceConfig -or -not $syncHash.TenantGovernanceJson_TextBox -or -not $syncHash.Analysis) { return }
    
    # Prepare a lookup table for display names, defaulting to an empty dictionary if not available.
    $displayNameLookup = if ($syncHash.Analysis.DisplayNameLookup -is [System.Collections.IDictionary]) { $syncHash.Analysis.DisplayNameLookup } else { @{} }
    # Prepare a lookup table for user principal names, defaulting to an empty dictionary if not available.
    $userUpnLookup = if ($syncHash.Analysis.UserUpnLookup -is [System.Collections.IDictionary]) { $syncHash.Analysis.UserUpnLookup } else { @{} }
    $includePolicyId = @()
    # Determine which policy ids to include based on the 'ScubaGear baseline policies only' checkbox.
    if ($syncHash.TenantGovernanceScubaOnly_CheckBox -and $syncHash.TenantGovernanceScubaOnly_CheckBox.IsChecked) {
        $includePolicyId = @(Get-ScATenantGovernanceMatchedPolicyId -Findings $syncHash.Analysis.Findings)
    }
    # If the 'ScubaGear baseline policies only' checkbox is not checked, include all policy ids by default.
    $syncHash.TenantGovernanceJson_TextBox.Text = ConvertTo-ScATenantGovernanceJson `
        -ConditionalAccessPolicies @($syncHash.Analysis.ConditionalAccessPolicies) `
        -TenantId ([string]$syncHash.Analysis.MetaData.TenantId) `
        -SchemaUrl ([string]$syncHash.TenantGovernanceSchemaUrl) `
        -DisplayNameLookup $displayNameLookup `
        -UserPrincipalNameLookup $userUpnLookup `
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
        # Copy the current Tenant Governance JSON to the clipboard.
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
        # Prompt the user to select a file path for exporting the Tenant Governance JSON.
        $dialog = New-Object Microsoft.Win32.SaveFileDialog
        $dialog.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
        $dialog.FileName = 'ScubaGear-TenantGovernance.json'
        # Set the default file name for the export dialog.
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
