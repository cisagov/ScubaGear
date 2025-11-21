<#
.SYNOPSIS
Helper functions to update ScubaConfigApp baseline configuration using Rego files.

.DESCRIPTION
This module provides functions to parse Rego files for exclusion type mappings
and update the ScubaConfigApp baseline configuration accordingly.

.EXAMPLE

#import module
[string]$ResourceRoot = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]
Import-Module (Join-Path -Path $ResourceRoot -ChildPath './ScubaConfigAppBaselineHelper.psm1')

# Get the REGO mappings
$regoMappings = Get-ScubaConfigRegoExclusionMappings -RegoDirectory "..\..\Rego"

# Update configuration using Rego mappings
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -RegoDirectory "..\..\Rego"
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -BaselineDirectory "..\..\baselines"  -RegoDirectory "..\..\Rego"

# Filter specific products
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -ProductFilter @("aad", "defender", "exo")
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -BaselineDirectory "..\..\baselines" -ProductFilter @("aad", "defender", "exo")

# Update configuration with additional fields
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -RegoDirectory "..\..\Rego" -AdditionalFields @('criticality')
#>

function Get-ScubaConfigRegoExclusionMappings {
    <#
    .SYNOPSIS
    Parses Rego configuration files to extract the actual exclusion type mappings for each policy.

    .DESCRIPTION
    This function analyzes the Rego files in the ScubaGear project to determine which exclusion types
    are actually used by each policy ID. This provides the most accurate mapping compared to text-based
    pattern matching.

    .PARAMETER RegoDirectory
    The directory containing the Rego files. Defaults to the standard ScubaGear Rego directory.

    .EXAMPLE
    $mappings = Get-ScubaConfigRegoExclusionMappings -RegoDirectory "C:\Path\To\ScubaGear\Rego"
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$RegoDirectory = "$PSScriptRoot\..\..\Rego"
    )

    $exclusionMappings = @{}

    # Define the mapping patterns to look for in Rego files
    $patterns = @{
        'UserExclusionsFullyExempt.*["'']([^"'']+)["'']' = 'CapExclusions'
        'GroupExclusionsFullyExempt.*["'']([^"'']+)["'']' = 'CapExclusions'
        'PrivilegedRoleExclusions.*["'']([^"'']+)["'']' = 'RoleExclusions'

        'SensitiveAccountsConfig.*["'']([^"'']+)["'']' = 'SensitiveAccounts'
        'SensitiveAccountsSetting.*["'']([^"'']+)["'']' = 'SensitiveAccounts'
        'ImpersonationProtectionConfig.*["'']([^"'']+)["''].*["'']AgencyDomains["'']' = 'AgencyDomains'
        'ImpersonationProtectionConfig.*["'']([^"'']+)["''].*["'']PartnerDomains["'']' = 'PartnerDomains'
        'ImpersonationProtectionConfig.*["'']([^"'']+)["''].*["'']SensitiveUsers["'']' = 'SensitiveUsers'
        'ImpersonationProtectionConfig.*["'']([^"'']+)["'']' = 'SensitiveUsers'

        'input\.scuba_config\.Exo\[\''([^'']+)\''\]\.AllowedForwardingDomains' = 'AllowedForwardingDomains'

        'input\.scuba_config\.Aad\[\''([^'']+)\''\]\.RoleExclusions' = 'RoleExclusions'
        'input\.scuba_config\.Defender\[\''([^'']+)\''\]\.SensitiveAccounts' = 'SensitiveAccounts'
        'input\.scuba_config\.Defender\[\''([^'']+)\''\]\.SensitiveUsers' = 'SensitiveUsers'
        'input\.scuba_config\.Defender\[\''([^'']+)\''\]\.PartnerDomains' = 'PartnerDomains'
        'input\.scuba_config\.Defender\[\''([^'']+)\''\]\.AgencyDomains' = 'AgencyDomains'
    }


    # Get all Rego files with error handling for permission denied issues
    try {
        $regoFiles = Get-ChildItem -Path $RegoDirectory -Filter "*.rego" -Recurse -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
        # Handle permission denied errors by trying without -Recurse or with limited scope
        Write-Warning "Permission denied accessing some directories. Searching only in immediate subdirectories."
        $regoFiles = @()

        # Get files from the root directory
        $regoFiles += Get-ChildItem -Path $RegoDirectory -Filter "*.rego" -ErrorAction SilentlyContinue

        # Get files from immediate subdirectories only
        $subdirs = Get-ChildItem -Path $RegoDirectory -Directory -ErrorAction SilentlyContinue
        foreach ($subdir in $subdirs) {
            try {
                $regoFiles += Get-ChildItem -Path $subdir.FullName -Filter "*.rego" -Recurse -ErrorAction Stop
            }
            catch {
                # Skip directories we can't access
                Write-Verbose "Skipping directory due to access restrictions: $($subdir.FullName)"
                $regoFiles += Get-ChildItem -Path $subdir.FullName -Filter "*.rego" -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        throw "Failed to access Rego directory '$RegoDirectory': $($_.Exception.Message)"
    }

    foreach ($file in $regoFiles) {
        $content = Get-Content -Path $file.FullName -Raw

        foreach ($pattern in $patterns.Keys) {
            $exclusionData = $patterns[$pattern]

            # Use regex to find matches
            $RegoFileContentMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

            foreach ($regoMatch in $RegoFileContentMatches) {
                if ($regoMatch.Groups.Count -gt 1) {
                    $policyId = $regoMatch.Groups[1].Value

                    # Only add if it looks like a valid policy ID
                    if ($policyId -match '^MS\.[A-Z]+\.[0-9]+\.[0-9]+v[0-9]+$') {
                        $exclusionMappings[$policyId] = $exclusionData
                        Write-Verbose "Found mapping: $policyId -> $exclusionData (from $($file.Name))"
                    }
                }
            }
        }
    }

    # Add some additional patterns by analyzing comments and function names
    foreach ($file in $regoFiles) {
        $content = Get-Content -Path $file.FullName

        $currentPolicyId = $null
        $inPolicySection = $false

        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]

            # Look for policy ID comments
            if ($line -match '#\s*(MS\.[A-Z]+\.[0-9]+\.[0-9]+v[0-9]+)') {
                $currentPolicyId = $matches[1]
                $inPolicySection = $true
                continue
            }

            # Look for end of policy section
            if ($inPolicySection -and $line -match '^#\s*MS\.[A-Z]+\.[0-9]+' -and $line -notmatch $currentPolicyId) {
                $inPolicySection = $false
                $currentPolicyId = $null
                continue
            }

            # If we're in a policy section, look for specific patterns
            if ($inPolicySection -and $currentPolicyId) {
                # Look for specific exclusion patterns within the policy section
                switch -Regex ($line) {
                    'UserExclusionsFullyExempt|GroupExclusionsFullyExempt' {
                        $exclusionMappings[$currentPolicyId] = 'CapExclusions'
                        Write-Verbose "Found CAP mapping: $currentPolicyId -> CapExclusions (from context)"
                    }
                    'PrivilegedRoleExclusions' {
                        $exclusionMappings[$currentPolicyId] = 'RoleExclusions'
                        Write-Verbose "Found RoleExclusions mapping: $currentPolicyId -> RoleExclusions (from context)"
                    }
                    'SensitiveAccountsConfig|SensitiveAccountsSetting' {
                        $exclusionMappings[$currentPolicyId] = 'SensitiveAccounts'
                        Write-Verbose "Found sensitive accounts mapping: $currentPolicyId -> SensitiveAccounts (from context)"
                    }
                    'ImpersonationProtectionConfig.*SensitiveUsers' {
                        $exclusionMappings[$currentPolicyId] = 'SensitiveUsers'
                        Write-Verbose "Found sensitive users mapping: $currentPolicyId -> SensitiveUsers (from context)"
                    }
                    'ImpersonationProtectionConfig.*PartnerDomains' {
                        $exclusionMappings[$currentPolicyId] = 'PartnerDomains'
                        Write-Verbose "Found partner domains mapping: $currentPolicyId -> PartnerDomains (from context)"
                    }
                    'ImpersonationProtectionConfig.*AgencyDomains' {
                        $exclusionMappings[$currentPolicyId] = 'AgencyDomains'
                        Write-Verbose "Found agency domains mapping: $currentPolicyId -> AgencyDomains (from context)"
                    }
                    'AllowedForwardingDomains' {
                        $exclusionMappings[$currentPolicyId] = 'AllowedForwardingDomains'
                        Write-Verbose "Found forwarding domains mapping: $currentPolicyId -> AllowedForwardingDomains (from context)"
                    }
                }
            }
        }
    }

    return $exclusionMappings
}
function Update-ScubaConfigBaselineWithRego {
    <#
    .SYNOPSIS
    Updates the baseline configuration using exclusion mappings extracted from Rego files.

    .DESCRIPTION
    This function uses the Rego files to determine the actual exclusion types used by each policy,
    providing more accurate mappings than text-based pattern matching. Also handles version increment,
    debug mode reset, and adds required fields to all baselines.

    .PARAMETER ConfigFilePath
    The path to the configuration file that will be updated.

    .PARAMETER BaselineDirectory
    The local directory containing baseline policy files.

    .PARAMETER GitHubDirectoryUrl
    The URL of the GitHub directory containing baseline policy files.

    .PARAMETER RegoDirectory
    The directory containing the Rego files. Defaults to the standard ScubaGear Rego directory.

    .PARAMETER ProductFilter
    An array of product names to filter the policies.

    .PARAMETER AdditionalFields
    An array of additional fields to include in the policy objects. Available fields: criticality, lastModified, implementation, mitreMapping, resources, link.

    .EXAMPLE
    Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.tests.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -RegoDirectory ".\Rego"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigFilePath,

        [Parameter(Mandatory=$false)]
        [string]$BaselineDirectory,

        [Parameter(Mandatory=$false)]
        [string]$GitHubDirectoryUrl,

        [Parameter(Mandatory=$false)]
        [string]$RegoDirectory = "$PSScriptRoot\..\..\Rego",

        [Parameter(Mandatory=$false)]
        [string[]]$ProductFilter = @(),

        [Parameter(Mandatory=$false)]
        [string[]]$AdditionalFields = @("criticality", "lastModified", "implementation", "mitreMapping", "resources", "link")
    )

    # Get the exclusion mappings from Rego files
    Write-Output "Analyzing Rego files for exclusion mappings..."
    $regoMappings = Get-ScubaConfigRegoExclusionMappings -RegoDirectory $RegoDirectory

    Write-Output "Found $($regoMappings.Keys.Count) policy exclusion mappings from Rego files"

    # Load existing configuration
    if (-not (Test-Path $ConfigFilePath)) {
        throw "Configuration file not found at: $ConfigFilePath"
    }

    $configContent = Get-Content $ConfigFilePath -Raw | ConvertFrom-Json

    # 1. Update version using current date (year offset from 2025, month, day)
    if ($configContent.Version) {
        $currentVersion = $configContent.Version
        $currentDate = Get-Date

        # Calculate year offset from 2025 (UI development start year)
        $uiStartYear = 2025
        $currentYear = $currentDate.Year
        $yearOffset = $currentYear - $uiStartYear + 1  # +1 so 2025 = 1, 2026 = 2, etc.

        $month = $currentDate.Month       # Current month (1-12)
        $day = $currentDate.Day           # Current day (1-31)
        $dateString = Get-Date -Format "M/d/yyyy"

        $newVersion = "$yearOffset.$month.$day"
        $configContent.Version = "$newVersion [updated $dateString]"
        Write-Output "Updated version from '$currentVersion' to '$($configContent.Version)'"
    }

    # 2. Set DebugMode to "None"
    if ($configContent.DebugMode) {
        $oldDebugMode = $configContent.DebugMode
        $configContent.DebugMode = "None"
        Write-Output "Changed DebugMode from '$oldDebugMode' to 'None'"
    }

    # Get baseline policies
    $baselinePolicies = Get-ScubaBaselinePolicy -BaselineDirectory $BaselineDirectory -GitHubDirectoryUrl $GitHubDirectoryUrl

    # Filter products if specified
    if ($ProductFilter.Count -gt 0) {
        $filteredPolicies = @{}
        foreach ($product in $ProductFilter) {
            if ($baselinePolicies.ContainsKey($product)) {
                $filteredPolicies[$product] = $baselinePolicies[$product]
            }
        }
        $baselinePolicies = $filteredPolicies
    }

    # Create new baselines structure with alphabetical ordering
    $newBaselines = [ordered]@{}
    $mappingStats = @{}

    # Sort products alphabetically for consistent output
    $sortedProducts = $baselinePolicies.Keys | Sort-Object

    foreach ($product in $sortedProducts) {
        $policies = $baselinePolicies[$product]
        $productBaseline = @()

        foreach ($policy in $policies) {
            # Use Rego mapping if available, otherwise default to "none"
            $exclusionField = if ($regoMappings.ContainsKey($policy.PolicyId)) {
                $regoMappings[$policy.PolicyId]
            } else {
                "none"
            }

            # Track mapping statistics
            if (-not $mappingStats.ContainsKey($exclusionField)) {
                $mappingStats[$exclusionField] = 0
            }
            $mappingStats[$exclusionField]++

            # 3. Create policy object with required fields including omissionField and annotationField
            $policyObj = [ordered]@{
                id = $policy.PolicyId
                name = $policy.Title
                rationale = $policy.Rationale
                criticality = $null
                exclusionField = $exclusionField
                omissionField = "Omissions"
                annotationField = "Annotations"
                link = "$GitHubDirectoryUrl/$($product.ToLower()).md#$($policy.PolicyId.replace('.', '').ToLower())"
            }

            # Add additional fields if specified and they exist
            foreach ($field in $AdditionalFields) {
                switch ($field) {
                    "criticality" {
                        if ($policy.Criticality) {
                            $policyObj.criticality = $policy.Criticality
                        }
                    }
                    "lastModified" {
                        if ($policy.LastModified) {
                            $policyObj.lastModified = $policy.LastModified
                        }
                    }
                    "implementation" {
                        if ($policy.Implementation) {
                            $policyObj.implementation = $policy.Implementation
                        }
                    }
                    "mitreMapping" {
                        if ($policy.MITRE_Mapping -and $policy.MITRE_Mapping.Count -gt 0) {
                            $policyObj.mitreMapping = $policy.MITRE_Mapping
                        }
                    }
                    "resources" {
                        if ($policy.Resources -and $policy.Resources.Count -gt 0) {
                            $policyObj.resources = $policy.Resources
                        }
                    }
                    "link" {
                        # Link is always generated, so it's already added above
                        # This case exists for documentation/consistency
                    }
                }
            }

            $productBaseline += $policyObj
        }

        if ($productBaseline.Count -gt 0) {
            $newBaselines[$product] = $productBaseline
        }
    }

    # Update the configuration
    $configContent.baselines = $newBaselines

    # Save the updated configuration
    $jsonOutput = $configContent | ConvertTo-Json -Depth 10
    $jsonOutput | Set-Content $ConfigFilePath -Encoding UTF8

    Write-Output "Successfully updated baselines in configuration file: $ConfigFilePath"
    Write-Output "Updated products: $($newBaselines.Keys -join ', ')"

    # Show exclusion type statistics
    Write-Output "`nExclusion Type Statistics:"
    foreach ($exclusionField in ($mappingStats.Keys | Sort-Object)) {
        Write-Output "  $exclusionField`: $($mappingStats[$exclusionField]) policies"
    }

    # Detailed summary
    foreach ($product in $newBaselines.Keys) {
        $policies = $newBaselines[$product]
        $policyCount = $policies.Count
        $exclusionCounts = $policies | Group-Object exclusionField | ForEach-Object { "$($_.Name): $($_.Count)" }
        Write-Output "  $product`: $policyCount policies ($($exclusionCounts -join ', '))"
    }

    return $newBaselines
}


function Get-ScubaBaselinePolicy {
    <#
    .SYNOPSIS
    Retrieves the baseline policy for a specific product.

    .PARAMETER BaselineDirectory
    Specifies the directory containing baseline policy files.

    .PARAMETER GitHubDirectoryUrl
    Specifies the GitHub directory URL containing baseline policy files.

    .EXAMPLE
     Get-ScubaBaselinePolicy -BaselineDirectory $BaselineDirectory -GitHubDirectoryUrl $GitHubDirectoryUrl
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$BaselineDirectory,

        [Parameter(Mandatory=$false)]
        [string]$GitHubDirectoryUrl
    )



    $policyHeaderPattern = '^####\s+([A-Z0-9\.]+v\d+)\s*$'
    $policiesByProduct = @{}

    $files = @()

    if ($GitHubDirectoryUrl) {
        # Convert GitHub URL to API URL
        if ($GitHubDirectoryUrl -match '^https://github.com/([^/]+)/([^/]+)/tree/([^/]+)(?:/(.*))?$') {
            $owner = $matches[1]
            $repo = $matches[2]
            $branch = $matches[3]
            $path = $matches[4]
            if ($null -ne $path -and $path -ne "") {
                $apiUrl = "https://api.github.com/repos/$owner/$repo/contents/$path`?ref=$branch"
            } else {
                $apiUrl = "https://api.github.com/repos/$owner/$repo/contents`?ref=$branch"
            }
        } else {
            throw "Invalid GitHub directory URL."
        }

        # Get list of markdown files in the directory
        $response = Invoke-RestMethod -Uri $apiUrl
        $files = $response | Where-Object { $_.name -like "*.md" }
    } elseif ($BaselineDirectory) {
        $files = Get-ChildItem -Path $BaselineDirectory -Filter *.md
    } else {
        throw "You must provide either -BaselineDirectory or -GitHubDirectoryUrl."
    }

    foreach ($file in $files) {
        if ($GitHubDirectoryUrl) {
            $rawUrl = $file.download_url
            $content = Invoke-WebRequest -Uri $rawUrl -UseBasicParsing | Select-Object -ExpandProperty Content
            $product = [System.IO.Path]::GetFileNameWithoutExtension($file.name)
            $lines = $content -split "`n"
        } else {
            $product = $file.BaseName
            $lines = Get-Content $file.FullName
        }

        $inPoliciesSection = $false
        $currentPolicy = $null
        $currentContent = @()
        $policies = @()
        $expectTitle = $false
        $implementationInstructions = @{}

        # First, find all Implementation instruction blocks for each policy
        $inImplementationSection = $false
        $currentImplementationPolicy = $null
        $currentImplementationContent = @()

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            # Check if we're in Implementation section
            if ($line -match '^### Implementation\s*$') {
                $inImplementationSection = $true
                continue
            }

            # Stop looking when we hit the next main section
            if ($inImplementationSection -and $line -match '^## ') {
                $inImplementationSection = $false
                if ($currentImplementationPolicy) {
                    $implementationInstructions[$currentImplementationPolicy] = ($currentImplementationContent -join "`n").Trim()
                    $currentImplementationPolicy = $null
                    $currentImplementationContent = @()
                }
                continue
            }

            # If we're in Implementation section, look for policy instruction headers
            if ($inImplementationSection) {
                if ($line -match '####\s+([A-Z0-9\.]+v\d+)\s+Instructions') {
                    if ($currentImplementationPolicy) {
                        $implementationInstructions[$currentImplementationPolicy] = ($currentImplementationContent -join "`n").Trim()
                        $currentImplementationContent = @()
                    }
                    $currentImplementationPolicy = $matches[1]
                    continue
                }
                if ($currentImplementationPolicy) {
                    $currentImplementationContent += $line
                }
            }
        }

        if ($inImplementationSection -and $currentImplementationPolicy) {
            $implementationInstructions[$currentImplementationPolicy] = ($currentImplementationContent -join "`n").Trim()
        }

        # Now parse the policies as before
        $inPoliciesSection = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line.Trim() -match '^### Policies') {
                $inPoliciesSection = $true
                continue
            }
            if ($inPoliciesSection -and ($line.Trim() -match '^## ' -or $line.Trim() -match '^# ')) {
                if ($currentPolicy) {
                    $policyContent = Get-ScubaPolicyContent -Content ($currentContent -join "`n")
                    foreach ($key in $policyContent.Keys) {
                        $currentPolicy[$key] = $policyContent[$key]
                    }
                    $policies += [PSCustomObject]$currentPolicy
                    $currentPolicy = $null
                    $currentContent = @()
                }
                $inPoliciesSection = $false
                $expectTitle = $false
                continue
            }
            if ($inPoliciesSection) {
                if ($line -match $policyHeaderPattern) {
                    if ($currentPolicy) {
                        $policyContent = Get-ScubaPolicyContent -Content ($currentContent -join "`n")
                        foreach ($key in $policyContent.Keys) {
                            $currentPolicy[$key] = $policyContent[$key]
                        }
                        $policies += [PSCustomObject]$currentPolicy
                        $currentContent = @()
                    }
                    $currentPolicy = @{
                        PolicyId = $matches[1]
                        Title    = ""
                        Implementation = ""
                    }
                    $expectTitle = $true
                    continue
                }
                elseif ($expectTitle -and $currentPolicy) {
                    if ($line.Trim() -ne "") {
                        $currentPolicy.Title = $line.Trim()
                        $expectTitle = $false
                    }
                }
                elseif ($currentPolicy) {
                    $currentContent += $line
                }
            }
        }

        if ($currentPolicy) {
            $policyContent = Get-ScubaPolicyContent -Content ($currentContent -join "`n")
            foreach ($key in $policyContent.Keys) {
                $currentPolicy[$key] = $policyContent[$key]
            }
            $policies += [PSCustomObject]$currentPolicy
        }

        # Attach implementation instructions to the policies
        foreach ($policy in $policies) {
            if ($implementationInstructions.ContainsKey($policy.PolicyId)) {
                $policy.Implementation = $implementationInstructions[$policy.PolicyId]
            }
        }

        if ($policies.Count -gt 0) {
            $policiesByProduct[$product] = $policies
        }
    }

    return $policiesByProduct
}

function Get-ScubaPolicyContent {
    <#
    .SYNOPSIS
        Retrieves the content of a specific policy from the markdown documentation

    .PARAMETER Content
        Import markdown content
    #>
    param([string]$Content)
    $result = @{
        Criticality = $null
        LastModified = $null
        Rationale = $null
        MITRE_Mapping = @()
        Resources = @()
    }
    if ($Content -match '<!--Policy:\s*[^;]+;\s*Criticality:\s*([A-Z]+)\s*-->') {
        $result.Criticality = $matches[1]
    }
    if ($Content -match '- _Last modified:_\s*(.+)') {
        $result.LastModified = $matches[1].Trim()
    }
    if ($Content -match '(?s)- _Rationale:_\s*(.+?)(?=\n\s*-|\n\s*\n|\z)') {
        $rationale = $matches[1].Trim()
        $result.Rationale = $rationale -replace '\s+', ' '
    }
    if ($Content -match '(_MITRE ATT&CK TTP Mapping:_[\s\S]+?)(\n\s*\n|###|$)') {
        $mitreBlock = $matches[1]
        $mitreList = @()
        foreach ($line in $mitreBlock -split "`n") {
            if ($line -match '\[([^\]]+)\]\(([^)]+)\)') {
                $mitreList += $line.Trim()
            }
        }
        $result.MITRE_Mapping = $mitreList
    }
    if ($Content -match '(?ms)^### Resources\s*(.+?)(^###|\z)') {
        $resourcesBlock = $matches[1]
        $resources = @()
        foreach ($line in $resourcesBlock -split "`n") {
            if ($line -match '^\s*-\s*\[([^\]]+)\]\(([^)]+)\)') {
                $resources += $line.Trim()
            }
        }
        $result.Resources = $resources
    }
    return $result
}

# export
#Export-ModuleMember -Function Get-ScubaBaselinePolicy, Get-ScubaConfigRegoExclusionMappings, Update-ScubaConfigBaselineWithRego