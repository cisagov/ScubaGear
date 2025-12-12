<#
# Example usage:
[string]$ResourceRoot = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]

# Get the markdown mappings
$markdownMappings = Get-ScubaConfigExclusionMappingsFromMarkdown -BaselineDirectory "..\..\..\baselines"

# Update configuration using markdown mappings
Update-ScubaConfigBaselineWithMarkdown -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines"

# Filter specific products
Update-ScubaConfigBaselineWithMarkdown -ConfigFilePath ".\ScubaBaselines_en-US.tests.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -ProductFilter @("aad", "defender", "exo")

# Update configuration with additional fields
Update-ScubaConfigBaselineWithMarkdown -ConfigFilePath ".\ScubaBaselines_en-US.tests.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -AdditionalFields @('criticality')
#>

function Get-ScubaConfigExclusionMappingsFromMarkdown {
    <#
    .SYNOPSIS
    Extracts exclusion type mappings from hidden markers in baseline markdown files.

    .DESCRIPTION
    This function parses baseline markdown files to extract exclusion type mappings using
    hidden markers in the format <!--ExclusionType: TypeName-->. This approach is simpler
    and more maintainable than parsing Rego files.

    .PARAMETER BaselineDirectory
    The directory containing baseline markdown files. Defaults to the standard ScubaGear baselines directory.

    .PARAMETER GitHubDirectoryUrl
    The URL of the GitHub directory containing baseline policy files.

    .EXAMPLE
    $mappings = Get-ScubaConfigExclusionMappingsFromMarkdown -BaselineDirectory "C:\Path\To\ScubaGear\baselines"
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$BaselineDirectory,

        [Parameter(Mandatory=$false)]
        [string]$GitHubDirectoryUrl
    )

    $exclusionMappings = @{}
    $files = @()

    # Get markdown files from GitHub or local directory
    if ($GitHubDirectoryUrl) {
        # Convert GitHub URL to API URL
        if ($GitHubDirectoryUrl -match '^https://github.com/([^/]+)/([^/]+)/tree/([^/]+)(?:/(.*))?$') {
            $owner = $matches[1]
            $repo = $matches[2]
            $branch = $matches[3]
            $path = if ($matches[4]) { $matches[4] } else { "" }
            $apiUrl = "https://api.github.com/repos/$owner/$repo/contents/$path`?ref=$branch"
        } else {
            throw "Invalid GitHub URL format. Expected format: https://github.com/owner/repo/tree/branch/path"
        }

        # Get list of markdown files in the directory
        $response = Invoke-RestMethod -Uri $apiUrl
        $files = $response | Where-Object { $_.name -like "*.md" }
    } elseif ($BaselineDirectory) {
        $files = Get-ChildItem -Path $BaselineDirectory -Filter *.md
    } else {
        throw "You must provide either -BaselineDirectory or -GitHubDirectoryUrl."
    }

    # Process each markdown file
    foreach ($file in $files) {
        if ($GitHubDirectoryUrl) {
            $content = (Invoke-WebRequest -Uri $file.download_url).Content
            $lines = $content -split "`n"
        } else {
            $lines = Get-Content -Path $file.FullName
        }

        $currentPolicyId = $null

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            # Look for policy ID headers (#### MS.XXX.#.#v#)
            if ($line -match '^####\s+(MS\.[A-Z]+\.[0-9]+\.[0-9]+v[0-9]+)\s*$') {
                $currentPolicyId = $matches[1]
            }

            # Look for hidden exclusion type marker
            if ($currentPolicyId -and $line -match '<!--\s*ExclusionType:\s*(\w+)\s*-->') {
                $exclusionType = $matches[1]
                if (-not $exclusionMappings.ContainsKey($currentPolicyId)) {
                    $exclusionMappings[$currentPolicyId] = $exclusionType
                    Write-Verbose "Found mapping: $currentPolicyId -> $exclusionType (from $($file.Name))"
                }
            }
        }
    }

    return $exclusionMappings
}

function Update-ScubaConfigBaselineWithMarkdown {
    <#
    .SYNOPSIS
    Updates the baseline configuration using exclusion mappings extracted from markdown file markers.

    .DESCRIPTION
    This function uses hidden markers in the baseline markdown files to determine the exclusion types
    used by each policy, providing a simpler approach than parsing Rego files. Also handles version
    increment, debug mode reset, and adds required fields to all baselines.

    .PARAMETER ConfigFilePath
    The path to the configuration file that will be updated.

    .PARAMETER BaselineDirectory
    The local directory containing baseline policy files.

    .PARAMETER GitHubDirectoryUrl
    The URL of the GitHub directory containing baseline policy files.

    .PARAMETER ProductFilter
    An array of product names to filter the policies.

    .PARAMETER AdditionalFields
    An array of additional fields to include in the policy objects. Available fields: criticality, lastModified, implementation, mitreMapping, resources, link.

    .EXAMPLE
    Update-ScubaConfigBaselineWithMarkdown -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigFilePath,

        [Parameter(Mandatory=$false)]
        [string]$BaselineDirectory,

        [Parameter(Mandatory=$false)]
        [string]$GitHubDirectoryUrl,

        [Parameter(Mandatory=$false)]
        [string[]]$ProductFilter = @(),

        [Parameter(Mandatory=$false)]
        [string[]]$AdditionalFields = @("criticality", "lastModified", "implementation", "mitreMapping", "resources", "link")
    )

    # Get the exclusion mappings from markdown file markers
    Write-Output "Analyzing markdown files for exclusion mappings..."
    #if Paramter is BaselineDirectory use that, else use GitHubDirectoryUrl
    if ($BaselineDirectory) {
        $markdownMappings = Get-ScubaConfigExclusionMappingsFromMarkdown -BaselineDirectory $BaselineDirectory
    } else {
        $markdownMappings = Get-ScubaConfigExclusionMappingsFromMarkdown -GitHubDirectoryUrl $GitHubDirectoryUrl
    }

    Write-Output "Found $($markdownMappings.Keys.Count) policy exclusion mappings from markdown files"

    # Load existing configuration or create new one if it doesn't exist
    if (Test-Path $ConfigFilePath) {
        $configContent = Get-Content $ConfigFilePath -Raw | ConvertFrom-Json
        Write-Output "Loaded existing configuration from: $ConfigFilePath"
    } else {
        # Create new configuration structure
        $configContent = [PSCustomObject]@{
            Version = "1.0.0"
            DebugMode = "None"
            baselines = @{}
        }
        Write-Output "Creating new configuration file: $ConfigFilePath"
    }

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
            # Use markdown mapping if available, otherwise default to "none"
            $exclusionField = if ($markdownMappings.ContainsKey($policy.PolicyId)) {
                $markdownMappings[$policy.PolicyId]
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
                exclusionField = $exclusionField
                omissionField = "Omissions"
                annotationField = "Annotations"
            }

            # Add rationale if available (always try to include this)
            if ($policy.Rationale) {
                $policyObj['rationale'] = $policy.Rationale
            }

            # Add additional fields if specified and they exist
            foreach ($field in $AdditionalFields) {
                switch ($field) {
                    "criticality" {
                        if ($policy.Criticality) {
                            $policyObj['criticality'] = $policy.Criticality
                        }
                    }
                    "lastModified" {
                        if ($policy.LastModified) {
                            $policyObj['lastModified'] = $policy.LastModified
                        }
                    }
                    "implementation" {
                        if ($policy.Implementation) {
                            $policyObj['implementation'] = $policy.Implementation
                        }
                    }
                    "mitreMapping" {
                        if ($policy.MITRE_Mapping -and $policy.MITRE_Mapping.Count -gt 0) {
                            $policyObj['mitreMapping'] = $policy.MITRE_Mapping
                        }
                    }
                    "resources" {
                        if ($policy.Resources -and $policy.Resources.Count -gt 0) {
                            $policyObj['resources'] = $policy.Resources
                        }
                    }
                    "link" {
                        if ($policy.Link) {
                            $policyObj['link'] = $policy.Link
                        }
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
            $path = if ($matches[4]) { $matches[4] } else { "" }
            $apiUrl = "https://api.github.com/repos/$owner/$repo/contents/$path`?ref=$branch"
        } else {
            throw "Invalid GitHub URL format. Expected format: https://github.com/owner/repo/tree/branch/path"
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
            $content = (Invoke-WebRequest -Uri $file.download_url).Content
            $lines = $content -split "`n"
        } else {
            $lines = Get-Content -Path $file.FullName
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

            # Detect the start of an implementation instruction section
            if ($line -match '^####\s+(MS\.[A-Z]+\.[0-9]+\.[0-9]+v[0-9]+)\s+Instructions\s*$') {
                if ($inImplementationSection -and $currentImplementationPolicy) {
                    $implementationInstructions[$currentImplementationPolicy] = ($currentImplementationContent -join "`n").Trim()
                }
                $currentImplementationPolicy = $matches[1]
                $inImplementationSection = $true
                $currentImplementationContent = @()
                continue
            }

            # Collect content for implementation instructions
            if ($inImplementationSection) {
                # Check for the end of implementation section (next policy or major section)
                if ($line -match '^####\s+MS\.[A-Z]+\.[0-9]+\.[0-9]+v[0-9]+' -or $line -match '^##\s+\d+\.' -or $line -match '^###\s+') {
                    if ($currentImplementationPolicy) {
                        $implementationInstructions[$currentImplementationPolicy] = ($currentImplementationContent -join "`n").Trim()
                    }
                    $inImplementationSection = $false
                    $currentImplementationPolicy = $null
                    $currentImplementationContent = @()
                }
                else {
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

            if ($line -match '^###\s+Policies\s*$') {
                $inPoliciesSection = $true
                continue
            }

            if ($inPoliciesSection) {
                if ($line -match '^###\s+(?!Policies)' -or $line -match '^##\s+\d+\.') {
                    # End of Policies section - save current policy if exists
                    if ($currentPolicy) {
                        $currentPolicy.Content = ($currentContent -join "`n").Trim()
                        $fullContent = $currentPolicy.Content
                        $policyDetails = Get-ScubaPolicyContent -Content $fullContent
                        $currentPolicy.Criticality = $policyDetails.Criticality
                        $currentPolicy.LastModified = $policyDetails.LastModified
                        $currentPolicy.Rationale = $policyDetails.Rationale
                        $currentPolicy.MITRE_Mapping = $policyDetails.MITRE_Mapping
                        $currentPolicy.Resources = $policyDetails.Resources
                        $policies += $currentPolicy
                        # Reset for next policy
                        $currentPolicy = $null
                        $currentContent = @()
                    }
                    $inPoliciesSection = $false
                    # Continue processing to find next "### Policies" section
                    continue
                }

                if ($line -match $policyHeaderPattern) {
                    if ($currentPolicy) {
                        $currentPolicy.Content = ($currentContent -join "`n").Trim()
                        $fullContent = $currentPolicy.Content
                        $policyDetails = Get-ScubaPolicyContent -Content $fullContent
                        $currentPolicy.Criticality = $policyDetails.Criticality
                        $currentPolicy.LastModified = $policyDetails.LastModified
                        $currentPolicy.Rationale = $policyDetails.Rationale
                        $currentPolicy.MITRE_Mapping = $policyDetails.MITRE_Mapping
                        $currentPolicy.Resources = $policyDetails.Resources
                        $policies += $currentPolicy
                    }
                    $currentPolicy = @{
                        PolicyId = $matches[1]
                        Title = $null
                        Content = $null
                    }
                    $currentContent = @()
                    $expectTitle = $true
                }
                elseif ($expectTitle -and $line.Trim() -ne '') {
                    $currentPolicy.Title = $line.Trim()
                    $expectTitle = $false
                }
                else {
                    $currentContent += $line
                }
            }
        }

        if ($currentPolicy) {
            $currentPolicy.Content = ($currentContent -join "`n").Trim()
            $fullContent = $currentPolicy.Content
            $policyDetails = Get-ScubaPolicyContent -Content $fullContent
            $currentPolicy.Criticality = $policyDetails.Criticality
            $currentPolicy.LastModified = $policyDetails.LastModified
            $currentPolicy.Rationale = $policyDetails.Rationale
            $currentPolicy.MITRE_Mapping = $policyDetails.MITRE_Mapping
            $currentPolicy.Resources = $policyDetails.Resources
            $policies += $currentPolicy
        }

        # Attach implementation instructions to the policies
        foreach ($policy in $policies) {
            if ($implementationInstructions.ContainsKey($policy.PolicyId)) {
                $policy.Implementation = $implementationInstructions[$policy.PolicyId]
            }
        }

        if ($policies.Count -gt 0) {
            $productName = ($file.Name -replace '\.md$', '').ToLower()
            $policiesByProduct[$productName] = $policies
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
                $mitreList += @{ Name = $matches[1]; Url = $matches[2] }
            }
        }
        $result.MITRE_Mapping = $mitreList
    }
    if ($Content -match '(?ms)^### Resources\s*(.+?)(^###|\z)') {
        $resourcesBlock = $matches[1]
        $resources = @()
        foreach ($line in $resourcesBlock -split "`n") {
            if ($line -match '\[([^\]]+)\]\(([^)]+)\)') {
                $resources += @{ Name = $matches[1]; Url = $matches[2] }
            }
        }
        $result.Resources = $resources
    }
    return $result
}



# Export module members
Export-ModuleMember -Function Get-ScubaBaselinePolicy, Get-ScubaConfigExclusionMappingsFromMarkdown, Update-ScubaConfigBaselineWithMarkdown
