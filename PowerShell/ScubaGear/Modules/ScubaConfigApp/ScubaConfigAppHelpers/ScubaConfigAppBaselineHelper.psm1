<#
# Example usage:
[string]$ResourceRoot = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]

# Get the markdown mappings
$markdownMappings = Get-ScubaConfigExclusionMappingsFromMarkdown -BaselineDirectory "..\..\..\baselines"

# Update configuration using markdown mappings from GitHub
Update-ScubaConfigBaselineWithMarkdown -BaselineFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines"

# Update configuration using local markdown files
Update-ScubaConfigBaselineWithMarkdown -BaselineFilePath ".\ScubaBaselines_en-US.tests.json" -BaselineDirectory "..\..\..\baselines"

# Filter specific products -
Update-ScubaConfigBaselineWithMarkdown -BaselineFilePath ".\ScubaBaselines_en-US.tests.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -ProductFilter @("aad", "defender", "exo")

# Update configuration with additional fields
Update-ScubaConfigBaselineWithMarkdown -BaselineFilePath ".\ScubaBaselines_en-US.tests.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -AdditionalFields @('criticality')
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
            $lines = Get-Content -Path $file.FullName -Encoding UTF8
        }

        # Normalize problematic Unicode characters to standard ASCII equivalents
        for ($j = 0; $j -lt $lines.Count; $j++) {
            $lines[$j] = $lines[$j] -replace [char]0x2019, "'"    # Right single quotation mark to apostrophe
            $lines[$j] = $lines[$j] -replace [char]0x201C, '"'    # Left double quotation mark
            $lines[$j] = $lines[$j] -replace [char]0x201D, '"'    # Right double quotation mark
            $lines[$j] = $lines[$j] -replace [char]0x2013, '-'    # En dash to hyphen
            $lines[$j] = $lines[$j] -replace [char]0x2014, '--'   # Em dash to double hyphen
            $lines[$j] = $lines[$j] -replace 'â€™', "'"           # Fix UTF-8 encoding error
            $lines[$j] = $lines[$j] -replace 'â€œ', '"'           # Fix UTF-8 encoding error
            $lines[$j] = $lines[$j] -replace 'â€\x9d', '"'         # Fix UTF-8 encoding error
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

    .PARAMETER BaselineFilePath
    The path to the configuration file that will be updated.

    .PARAMETER BaselineDirectory
    The local directory containing baseline policy files.

    .PARAMETER GitHubDirectoryUrl
    The URL of the GitHub directory containing baseline policy files.

    .PARAMETER ProductFilter
    An array of product names to filter the policies.

    .PARAMETER AdditionalFields
    An array of additional fields to include in the policy objects. Available fields: criticality, lastModified, implementation, mitreMapping, resources, link, badges.

    .EXAMPLE
    Update-ScubaConfigBaselineWithMarkdown -BaselineFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines"
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$BaselineFilePath = "$env:Temp\ScubaBaselines.json",

        [Parameter(Mandatory=$false)]
        [string]$BaselineDirectory,

        [Parameter(Mandatory=$false)]
        [string]$GitHubDirectoryUrl,

        [Parameter(Mandatory=$false)]
        [string[]]$ProductFilter = @(),

        [Parameter(Mandatory=$false)]
        [string[]]$AdditionalFields = @("criticality", "lastModified", "implementation", "mitreMapping", "resources", "licenseRequirements", "link", "badges")
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

    # Extract common header content from the first baseline markdown file
    Write-Output "Extracting common header content from baseline markdown files..."
    if ($BaselineDirectory) {
        $headerContent = Get-ScubaBaselineHeaderContent -BaselineDirectory $BaselineDirectory
    } else {
        $headerContent = Get-ScubaBaselineHeaderContent -GitHubDirectoryUrl $GitHubDirectoryUrl
    }

    # Create new configuration structure everytime!
    $configContent = [PSCustomObject]@{
        Version = "1.0.0"
        DebugMode = "None"
        baselines = @{}
    }

    # Add header content if extracted successfully
    if ($headerContent) {
        $configContent | Add-Member -NotePropertyName "Introduction" -NotePropertyValue $headerContent.Introduction
        $configContent | Add-Member -NotePropertyName "LicenseCompliance" -NotePropertyValue $headerContent.LicenseCompliance
        $configContent | Add-Member -NotePropertyName "Assumptions" -NotePropertyValue $headerContent.Assumptions
        $configContent | Add-Member -NotePropertyName "KeyTerminology" -NotePropertyValue $headerContent.KeyTerminology
        Write-Output "Added common header content to configuration"
    }

    Write-Output "Creating new configuration file: $BaselineFilePath"


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
                policySection = $policy.PolicySection
                sectionDescription = $policy.SectionDescription
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
                        if ($policy.SectionResources -and $policy.SectionResources.Count -gt 0) {
                            $policyObj['resources'] = $policy.SectionResources
                        }
                    }
                    "licenseRequirements" {
                        if ($policy.SectionLicenseRequirements -and $policy.SectionLicenseRequirements.Count -gt 0) {
                            # Ensure licenseRequirements is always an array
                            if ($policy.SectionLicenseRequirements -is [array]) {
                                $policyObj['licenseRequirements'] = $policy.SectionLicenseRequirements
                            } else {
                                $policyObj['licenseRequirements'] = @($policy.SectionLicenseRequirements)
                            }
                        } else {
                            # Default to "N/A" as a single-item array for consistency
                            $policyObj['licenseRequirements'] = @("N/A")
                        }
                    }
                    "link" {
                        if ($policy.Link) {
                            $policyObj['link'] = $policy.Link
                        }
                    }
                    "badges" {
                        if ($policy.Badges -and $policy.Badges.Count -gt 0) {
                            $policyObj['badges'] = $policy.Badges
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

    # Save the updated configuration with proper character encoding
    $jsonOutput = $configContent | ConvertTo-Json -Depth 10

    # Fix common UTF-8 encoding issues in the JSON output using character codes
    $jsonOutput = $jsonOutput -replace ([char]0x2019), "'"        # Right single quotation mark
    $jsonOutput = $jsonOutput -replace ([char]0x201C), '"'        # Left double quotation mark
    $jsonOutput = $jsonOutput -replace ([char]0x201D), '"'        # Right double quotation mark
    $jsonOutput = $jsonOutput -replace 'â€"', "—"                 # Fix malformed double dash
    $jsonOutput = $jsonOutput -replace 'â€™', "'"                 # Fix malformed apostrophe
    $jsonOutput = $jsonOutput -replace 'â€œ', '"'                 # Fix malformed left quote
    $jsonOutput = $jsonOutput -replace 'â€', '"'                  # Fix malformed right quote

    $jsonOutput | Set-Content $BaselineFilePath -Encoding UTF8

    Write-Output "Successfully updated baselines in configuration file: $BaselineFilePath"
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

function Get-ScubaBaselineHeaderContent {
    <#
    .SYNOPSIS
    Extracts the common header content from the first baseline markdown file.

    .DESCRIPTION
    Extracts content from the introduction section, specifically the last 3 paragraphs
    that start with "The Secure Cloud Business Applications (SCuBA) project...",
    "The CISA SCuBA SCBs...", and "For non-Federal users...".
    Also extracts License Compliance, Assumptions, and Key Terminology sections.

    .PARAMETER BaselineDirectory
    The local directory containing baseline policy files.

    .PARAMETER GitHubDirectoryUrl
    The URL of the GitHub directory containing baseline policy files.
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$BaselineDirectory,

        [Parameter(Mandatory=$false)]
        [string]$GitHubDirectoryUrl
    )

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

    # Use the first markdown file (e.g., aad.md)
    if ($files.Count -eq 0) {
        return $null
    }

    $firstFile = $files[0]
    $content = ""

    if ($GitHubDirectoryUrl) {
        $content = (Invoke-WebRequest -Uri $firstFile.download_url).Content
    } else {
        $content = Get-Content -Path $firstFile.FullName -Raw -Encoding UTF8
    }

    # Normalize problematic Unicode characters in the header content
    $content = $content -replace [char]0x2019, "'"       # Right single quotation mark to apostrophe
    $content = $content -replace [char]0x201C, '\"'       # Left double quotation mark
    $content = $content -replace [char]0x201D, '\"'       # Right double quotation mark
    $content = $content -replace [char]0x2013, '-'       # En dash to hyphen
    $content = $content -replace [char]0x2014, '--'      # Em dash to double hyphen
    $content = $content -replace 'â€™', "'"              # Fix UTF-8 encoding error
    $content = $content -replace 'â€œ', '\"'              # Fix UTF-8 encoding error
    $content = $content -replace 'â€\x9d', '\"'            # Fix UTF-8 encoding error

    $headerContent = @{
        introduction = ""
        licenseCompliance = ""
        assumptions = ""
        keyTerminology = ""
    }

    # Extract introduction content - get only the common SCuBA project description
    if ($content -match '(?s)The Secure Cloud Business Applications \(SCuBA\) project.*?(?=## License Compliance and Copyright)') {
        $introSection = $matches[0].Trim()
        $headerContent.introduction = $introSection
    }

    # Extract License Compliance and Copyright section
    if ($content -match '(?s)## License Compliance and Copyright\s*\n(.*?)(?=\n## |$)') {
        $headerContent.licenseCompliance = $matches[1].Trim()
    }

    # Extract Assumptions section
    if ($content -match '(?s)## Assumptions\s*\n(.*?)(?=\n## |$)') {
        $headerContent.assumptions = $matches[1].Trim()
    }

    # Extract Key Terminology section
    if ($content -match '(?s)## Key Terminology\s*\n(.*?)(?=\n## |$)') {
        $headerContent.keyTerminology = $matches[1].Trim()
    }

    return $headerContent
}


function Get-ScubaBaselinePolicy {
    <#
    .SYNOPSIS
    Retrieves the baseline policy for a specific product using hierarchical section parsing.

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
            $lines = Get-Content -Path $file.FullName -Encoding UTF8
        }

        # Parse hierarchically by sections
        $fullContent = $lines -join "`n"
        $sections = Get-ScubaBaselineSections -Content $fullContent

        $policies = @()

        foreach ($section in $sections) {
            foreach ($policy in $section.Policies) {
                # Add section context to each policy
                $policy.PolicySection = $section.Name
                $policy.SectionDescription = $section.Description
                $policy.SectionResources = $section.Resources
                $policy.SectionLicenseRequirements = $section.LicenseRequirements
                $policies += $policy
            }
        }

        if ($policies.Count -gt 0) {
            $productName = ($file.Name -replace '\.md$', '').ToLower()
            $policiesByProduct[$productName] = $policies
        }
    }

    return $policiesByProduct
}

function Get-ScubaBaselineSections {
    <#
    .SYNOPSIS
    Parses baseline markdown content hierarchically by sections (## level headers)

    .PARAMETER Content
    The full markdown content to parse
    #>
    param([string]$Content)

    $sections = @()
    $lines = $Content -split "`n"

    $currentSection = $null
    $currentSubSection = $null
    $currentPolicy = $null
    $currentContent = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # ## Section headers (e.g., "## 1. Legacy Authentication")
        if ($line -match '^##\s+\d+\.\s*(.+)$') {
            # Save previous section
            if ($currentSection) {
                $sections += $currentSection
            }

            # Start new section
            $currentSection = @{
                Name = $matches[1].Trim()
                Description = ""
                Resources = @()
                LicenseRequirements = @()
                Policies = [System.Collections.ArrayList]::new()
            }
            $currentSubSection = $null
            $currentPolicy = $null
            $currentContent = @()
            continue
        }

        # ### Sub-section headers (Policies, Resources, License Requirements, Implementation)
        if ($line -match '^###\s+(.+)$') {
            $subSectionName = $matches[1].Trim()

            # Save current policy if we were in one
            if ($currentPolicy -and $currentSubSection -eq "Policies" -and $currentSection) {
                $currentPolicy.Content = ($currentContent -join "`n").Trim()
                $policyDetails = Get-ScubaPolicyContent -Content $currentPolicy.Content
                $currentPolicy.Criticality = $policyDetails.Criticality
                $currentPolicy.LastModified = $policyDetails.LastModified
                $currentPolicy.Rationale = $policyDetails.Rationale
                $currentPolicy.MITRE_Mapping = $policyDetails.MITRE_Mapping
                $currentPolicy.Badges = $policyDetails.Badges
                # Extract implementation instructions for this policy
                $currentPolicy.Implementation = Get-ScubaPolicyImplementation -Content $Content -PolicyId $currentPolicy.PolicyId
                $null = $currentSection.Policies.Add($currentPolicy)
                $currentPolicy = $null
                $currentContent = @()
            }

            # Process section-level content based on subsection type
            if ($currentSubSection -eq "Resources") {
                $currentSection.Resources = Get-ScubaSectionContent -Content ($currentContent -join "`n") -ContentType "Resources"
            } elseif ($currentSubSection -eq "License Requirements") {
                $sectionLicenseReq = Get-ScubaSectionContent -Content ($currentContent -join "`n") -ContentType "LicenseRequirements"
                $currentSection.LicenseRequirements = if ($sectionLicenseReq -and $sectionLicenseReq.Count -gt 0) { $sectionLicenseReq } else { @("N/A") }
            }

            $currentSubSection = $subSectionName
            $currentContent = @()
            continue
        }

        # #### Policy headers (e.g., "#### MS.AAD.1.1v1")
        if ($line -match '^####\s+(MS\.[A-Z]+\.[0-9]+\.[0-9]+v[0-9]+)\s*$') {
            # Save previous policy
            if ($currentPolicy -and $currentSection) {
                $currentPolicy.Content = ($currentContent -join "`n").Trim()
                $policyDetails = Get-ScubaPolicyContent -Content $currentPolicy.Content
                $currentPolicy.Criticality = $policyDetails.Criticality
                $currentPolicy.LastModified = $policyDetails.LastModified
                $currentPolicy.Rationale = $policyDetails.Rationale
                $currentPolicy.MITRE_Mapping = $policyDetails.MITRE_Mapping
                $currentPolicy.Badges = $policyDetails.Badges
                # Extract implementation instructions for this policy
                $currentPolicy.Implementation = Get-ScubaPolicyImplementation -Content $Content -PolicyId $currentPolicy.PolicyId
                $null = $currentSection.Policies.Add($currentPolicy)
                $currentContent = @()
            }

            # Start new policy
            $currentPolicy = @{
                PolicyId = $matches[1]
                Title = ""
                Content = ""
            }
            continue
        }

        # Policy title (first non-empty line after policy header)
        if ($currentPolicy -and $currentSubSection -eq "Policies" -and -not $currentPolicy.Title -and $line.Trim() -ne '') {
            $currentPolicy.Title = $line.Trim()
            continue
        }

        # Description content (between ## section header and first ### subsection)
        if ($currentSection -and -not $currentSubSection -and $line.Trim() -ne '') {
            if ($currentSection.Description -eq "") {
                $currentSection.Description = $line.Trim()
            } else {
                $currentSection.Description += " " + $line.Trim()
            }
            continue
        }

        # Collect content for current context
        $currentContent += $line
    }

    # Save final policy and section
    if ($currentPolicy -and $currentSection) {
        $currentPolicy.Content = ($currentContent -join "`n").Trim()
        $policyDetails = Get-ScubaPolicyContent -Content $currentPolicy.Content
        $currentPolicy.Criticality = $policyDetails.Criticality
        $currentPolicy.LastModified = $policyDetails.LastModified
        $currentPolicy.Rationale = $policyDetails.Rationale
        $currentPolicy.MITRE_Mapping = $policyDetails.MITRE_Mapping
        $currentPolicy.Badges = $policyDetails.Badges
        $currentPolicy.Implementation = Get-ScubaPolicyImplementation -Content $Content -PolicyId $currentPolicy.PolicyId
        $null = $currentSection.Policies.Add($currentPolicy)
    }

    # Process final section content
    if ($currentSection) {
        if ($currentSubSection -eq "Resources") {
            $currentSection.Resources = Get-ScubaSectionContent -Content ($currentContent -join "`n") -ContentType "Resources"
        } elseif ($currentSubSection -eq "License Requirements") {
            $sectionLicenseReq = Get-ScubaSectionContent -Content ($currentContent -join "`n") -ContentType "LicenseRequirements"
            $currentSection.LicenseRequirements = if ($sectionLicenseReq -and $sectionLicenseReq.Count -gt 0) { $sectionLicenseReq } else { @("N/A") }
        }
        $sections += $currentSection
    }

    return $sections
}

function Get-ScubaSectionContent {
    <#
    .SYNOPSIS
    Parses section content for Resources or License Requirements
    #>
    param(
        [string]$Content,
        [string]$ContentType
    )

    $result = @()

    if ($ContentType -eq "Resources") {
        # Parse links for Resources
        $linkPattern = '\[([^\]]+)\]\(([^)]+)\)'
        $linkMatches = [regex]::Matches($Content, $linkPattern)

        foreach ($match in $linkMatches) {
            $linkName = $match.Groups[1].Value.Trim()
            $linkUrl = $match.Groups[2].Value.Trim()
            $result += @{ Name = $linkName; Url = $linkUrl }
        }
    }
    elseif ($ContentType -eq "LicenseRequirements") {
        # Parse bullet points for License Requirements - only split on actual bullets
        # Use regex to find lines that start with bullet markers (- at beginning of line, possibly with whitespace)
        $lines = $Content -split "`r?`n"
        $currentBullet = ""

        foreach ($line in $lines) {
            $line = $line.Trim()
            if ($line -match '^-\s*(.*)$') {
                # This is a new bullet point - save previous one if it exists
                if (-not [string]::IsNullOrWhiteSpace($currentBullet)) {
                    $result += $currentBullet.Trim()
                }
                # Start new bullet with the content after the dash
                $currentBullet = $matches[1].Trim()
            } elseif (-not [string]::IsNullOrWhiteSpace($line) -and -not [string]::IsNullOrWhiteSpace($currentBullet)) {
                # This is a continuation of the current bullet point
                $currentBullet += " " + $line
            }
        }

        # Don't forget the last bullet point
        if (-not [string]::IsNullOrWhiteSpace($currentBullet)) {
            $result += $currentBullet.Trim()
        }

        # If no bullets found, ensure we still return an array (even if empty)
        if ($result.Count -eq 0) {
            $result = @()
        }
    }

    return $result
}

function Get-ScubaPolicyImplementation {
    <#
    .SYNOPSIS
    Extracts implementation instructions for a specific policy
    #>
    param(
        [string]$Content,
        [string]$PolicyId
    )

    # Look for implementation section for this policy
    $pattern = "(?ms)^####\s+$PolicyId\s+Instructions\s*\n(.*?)(?=^####|^###|^##|\z)"

    if ($Content -match $pattern) {
        $implementation = $matches[1].Trim()

        # Normalize smart quotes to straight quotes
        $implementation = $implementation -replace [char]0x201C, '"'  # Left double quotation mark
        $implementation = $implementation -replace [char]0x201D, '"'  # Right double quotation mark
        $implementation = $implementation -replace [char]0x2019, "'"  # Right single quotation mark

        # Clean up markdown code blocks - more comprehensive approach
        # First, handle indented code blocks (4+ spaces or 1+ tabs followed by backticks)
        $implementation = $implementation -replace '(?ms)^[ \t]*```[\w]*\r?\n(.*?)\r?\n[ \t]*```[ \t]*$', '$1'

        # Handle regular code blocks at start of line
        $implementation = $implementation -replace '(?ms)^```[\w]*\r?\n(.*?)\r?\n```[ \t]*$', '$1'

        # Handle inline code blocks and remaining artifacts
        $implementation = $implementation -replace '```[\w]*\r?\n?', ''
        $implementation = $implementation -replace '\r?\n?```', ''
        $implementation = $implementation -replace '```', ''

        # Clean up extra whitespace that might remain
        $implementation = $implementation -replace '^\s+', ''
        $implementation = $implementation -replace '\s+$', ''

        return $implementation
    }

    return ""
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
        Badges = @()
        LicenseRequirements = @()
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

    # Parse policy-level license requirements
    if ($Content -match '(?ms)>\s*### License Requirements\s*\n+(?<Block>.*?)(?=\n\s*###|\n\s*\n\s*####|\z)') {
        $licenseBlock = $matches['Block']
        $cleanedBlock = $licenseBlock -replace "`n", " " -replace '\s+', ' '
        $bulletItems = $cleanedBlock -split '-' | Where-Object { $_.Trim() -ne '' }

        foreach ($item in $bulletItems) {
            $item = $item.Trim()
            # Filter out section headers and empty items, but keep N/A
            if ($item -and -not [string]::IsNullOrWhiteSpace($item) -and $item -notmatch '^###\s+') {
                $result.LicenseRequirements += $item
            }
        }
    }

    # Parse badges from shield.io patterns - handle both full URLs and anchor links
    $badgePattern = '\[!\[(?<Title>[^\]]+)\]\((?<ImageUrl>https?://img\.shields\.io/badge/[^)]+)\)\](?:\((?<LinkUrl>[^\)]+)\))?'
    $badgeMatches = [regex]::Matches($Content, $badgePattern)
    $badges = @()
    foreach ($match in $badgeMatches) {
        # Extract color and label from the image URL
        $imageUrl = $match.Groups['ImageUrl'].Value
        $label = ""
        $color = ""

        # Parse badge URL to extract label and color - handle various patterns including double dashes
        if ($imageUrl -match 'https?://img\.shields\.io/badge/(.+)-([A-Fa-f0-9]{3,6})$') {
            $fullLabelPart = $matches[1] -replace '%20', ' '  # Replace URL encoded spaces
            $color = $matches[2]
            # Extract just the readable label (remove underscores and technical formatting)
            $label = $fullLabelPart -replace '_', ' ' -replace '--', '-'
        }

        $linkUrl = $match.Groups['LinkUrl'].Value
        if (-not $linkUrl) { $linkUrl = "" }  # Handle badges without links

        $badges += @{
            title = $match.Groups['Title'].Value -replace '_', ' '
            label = $label
            color = $color
            imageUrl = $imageUrl
            linkUrl = $linkUrl
        }
    }
    $result.Badges = $badges

    return $result
}



# Export module members
Export-ModuleMember -Function Get-ScubaBaselinePolicy, Get-ScubaConfigExclusionMappingsFromMarkdown, Update-ScubaConfigBaselineWithMarkdown, Get-ScubaBaselineSections, Get-ScubaBaselineHeaderContent
