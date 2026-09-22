#Requires -Version 5.1

<#
.SYNOPSIS
    Functions for generating ScubaGear GitHub release notes.
.DESCRIPTION
    Extracted from the Build and Draft Release workflow so the notes
    logic can be unit tested and reused without living in YAML.
#>

function Get-GitHubNextPageUrl {
    <#
    .SYNOPSIS
        Returns the next page URL from a GitHub Link response header.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        $LinkHeader
    )

    if ($null -eq $LinkHeader -or [string]::IsNullOrWhiteSpace([string]$LinkHeader)) {
        return $null
    }

    $HeaderValue = $LinkHeader
    if ($LinkHeader -is [System.Array]) {
        $HeaderValue = $LinkHeader -join ','
    }

    foreach ($Part in ([string]$HeaderValue -split ',')) {
        if ($Part -match '<([^>]+)>\s*;\s*rel="next"') {
            return $Matches[1]
        }
    }

    return $null
}

function Invoke-GitHubApi {
    <#
    .SYNOPSIS
        Calls the GitHub REST API and optionally follows pagination.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $Method = 'GET',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory = $false)]
        [hashtable]
        $Query,

        [Parameter(Mandatory = $false)]
        [switch]
        $Paginate
    )

    $ApiRoot = 'https://api.github.com'
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_API_URL)) {
        $ApiRoot = $env:GITHUB_API_URL.TrimEnd('/')
    }

    $UriBuilder = New-Object System.UriBuilder "$ApiRoot/$($Path.TrimStart('/'))"
    if ($Query -and $Query.Count -gt 0) {
        $Pairs = foreach ($Entry in $Query.GetEnumerator()) {
            '{0}={1}' -f [uri]::EscapeDataString([string]$Entry.Key), [uri]::EscapeDataString([string]$Entry.Value)
        }
        $UriBuilder.Query = ($Pairs -join '&')
    }

    $Headers = @{
        Accept     = 'application/vnd.github+json'
        'User-Agent' = 'ScubaGear-New-ReleaseNotes'
    }
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        $Headers['Authorization'] = "Bearer $($env:GITHUB_TOKEN)"
    }

    $Results = @()
    $Uri = $UriBuilder.Uri.AbsoluteUri

    do {
        try {
            $Response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $Headers -UseBasicParsing
        }
        catch {
            $StatusCode = 0
            if ($_.Exception.Response) {
                $StatusCode = [int]$_.Exception.Response.StatusCode
            }
            throw "GitHub API $Method $Path failed with status $StatusCode : $($_.Exception.Message)"
        }

        $Parsed = $null
        if (-not [string]::IsNullOrWhiteSpace($Response.Content)) {
            $Parsed = $Response.Content | ConvertFrom-Json
        }

        if (-not $Paginate) {
            return $Parsed
        }

        if ($null -ne $Parsed) {
            $Results += @($Parsed)
        }

        $Uri = Get-GitHubNextPageUrl -LinkHeader $Response.Headers['Link']
    } while ($Uri)

    return $Results
}

function ConvertFrom-ReleaseTagVersion {
    <#
    .SYNOPSIS
        Parses a v-prefixed or bare major.minor.patch tag into comparable parts.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $TagName
    )

    $Match = [regex]::Match($TagName, '^v?(\d+)\.(\d+)(?:\.(\d+))?$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $Match.Success) {
        return $null
    }

    $Patch = 0
    if ($Match.Groups[3].Success -and -not [string]::IsNullOrWhiteSpace($Match.Groups[3].Value)) {
        $Patch = [int]$Match.Groups[3].Value
    }

    return [PSCustomObject]@{
        Tag   = $TagName
        Parts = @([int]$Match.Groups[1].Value, [int]$Match.Groups[2].Value, $Patch)
    }
}

function Compare-ReleaseTagVersion {
    <#
    .SYNOPSIS
        Compares two parsed release versions. Negative if left is older.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Left,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Right
    )

    for ($Index = 0; $Index -lt 3; $Index++) {
        if ($Left.Parts[$Index] -ne $Right.Parts[$Index]) {
            return ($Left.Parts[$Index] - $Right.Parts[$Index])
        }
    }

    return 0
}

function Get-PreviousReleaseTag {
    <#
    .SYNOPSIS
        Finds the newest published release older than the version being drafted.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Owner,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version
    )

    $CurrentTag = "v$Version"
    $CurrentVersion = ConvertFrom-ReleaseTagVersion -TagName $CurrentTag
    if ($null -eq $CurrentVersion) {
        throw "Unable to parse release version from tag $CurrentTag."
    }

    $Releases = Invoke-GitHubApi `
        -Path "repos/$Owner/$Repository/releases" `
        -Query @{ per_page = '100' } `
        -Paginate

    $PublishedReleases = @()
    foreach ($Release in @($Releases)) {
        if ($Release.draft -or $Release.prerelease) {
            continue
        }
        if ($Release.tag_name.ToLower() -eq $CurrentTag.ToLower()) {
            continue
        }

        $Parsed = ConvertFrom-ReleaseTagVersion -TagName $Release.tag_name
        if ($null -eq $Parsed) {
            continue
        }
        if ((Compare-ReleaseTagVersion -Left $Parsed -Right $CurrentVersion) -ge 0) {
            continue
        }

        $PublishedReleases += [PSCustomObject]@{
            Release = $Release
            Version = $Parsed
        }
    }

    $Sorted = $PublishedReleases | Sort-Object `
        @{ Expression = { $_.Version.Parts[0] }; Descending = $true }, `
        @{ Expression = { $_.Version.Parts[1] }; Descending = $true }, `
        @{ Expression = { $_.Version.Parts[2] }; Descending = $true }

    $PreviousEntry = @($Sorted)[0]
    if ($null -eq $PreviousEntry) {
        throw "Unable to find a published release older than $CurrentTag."
    }

    Write-Warning "Using previous tag $($PreviousEntry.Release.tag_name) (published $($PreviousEntry.Release.published_at)) for release notes."
    return $PreviousEntry.Release.tag_name
}

function Test-DependencyPullRequest {
    <#
    .SYNOPSIS
        Returns true when a pull request is a dependency bump.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $PullRequest
    )

    $DependencyAuthors = @('github-actions[bot]', 'dependabot[bot]')
    if ($DependencyAuthors -contains $PullRequest.user.login) {
        return $true
    }

    return ($PullRequest.title -match '^Bump ')
}

function Get-ReleaseNoteCategory {
    <#
    .SYNOPSIS
        Maps a pull request to a release notes section, or null if excluded.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $PullRequest
    )

    $ExcludedLabels = @(
        'epic',
        'Testing',
        'hands-on-prototyping',
        'blocked',
        'duplicate',
        'wontfix'
    )

    $Names = @($PullRequest.labels | ForEach-Object { $_.name })
    foreach ($Name in $Names) {
        if ($ExcludedLabels -contains $Name) {
            return $null
        }
    }

    if (Test-DependencyPullRequest -PullRequest $PullRequest) {
        return 'Dependencies'
    }
    if ($Names -contains 'baseline-document') {
        return 'Baselines'
    }
    if ($Names -contains 'documentation') {
        return 'Documentation'
    }
    if ($Names -contains 'bug') {
        return 'Bugs Fixed'
    }
    if ($Names -contains 'enhancement') {
        return 'Major Changes'
    }

    return 'Dependencies'
}

function Format-ReleaseNotePullRequest {
    <#
    .SYNOPSIS
        Formats a pull request as a release notes bullet.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $PullRequest
    )

    return "* $($PullRequest.title) by @$($PullRequest.user.login) in #$($PullRequest.number)"
}

function New-GitHubIssuesSearchUrl {
    <#
    .SYNOPSIS
        Builds a GitHub issues search URL for a repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Owner,

        [Parameter(Mandatory = $true)]
        [string]
        $Repository,

        [Parameter(Mandatory = $true)]
        [string]
        $Query
    )

    return "https://github.com/$Owner/$Repository/issues?q=$([uri]::EscapeDataString($Query))"
}

function Format-ReleaseNotesSection {
    <#
    .SYNOPSIS
        Formats a standard (non-baseline, non-dependency) notes section.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Title,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]
        $Items,

        [Parameter(Mandatory = $true)]
        [string]
        $Owner,

        [Parameter(Mandatory = $true)]
        [string]
        $Repository
    )

    $SectionFooters = @{
        'Major Changes' = @{
            LinkLabel = 'enhancements'
            Query     = 'is:issue is:closed label:enhancement -label:baseline-document -label:documentation -label:Testing -label:hands-on-prototyping -label:epic'
        }
        'Bugs Fixed'    = @{
            LinkLabel = 'bug fixes'
            Query     = 'is:issue is:closed label:bug -label:baseline-document -label:Testing -label:documentation -label:epic'
        }
        'Documentation' = @{
            LinkLabel = 'documentation updates'
            Query     = 'state:closed label:documentation'
        }
    }

    $Lines = New-Object System.Collections.Generic.List[string]
    $Lines.Add("## $Title") | Out-Null
    $Lines.Add('') | Out-Null
    foreach ($Item in $Items) {
        $Lines.Add($Item) | Out-Null
    }

    if ($SectionFooters.ContainsKey($Title)) {
        $Footer = $SectionFooters[$Title]
        $IssuesUrl = New-GitHubIssuesSearchUrl -Owner $Owner -Repository $Repository -Query $Footer.Query
        $Lines.Add("* See full list of $($Footer.LinkLabel) [here]($IssuesUrl)") | Out-Null
    }

    return (($Lines -join "`r`n") + "`r`n")
}

function Format-ReleaseNotesBaselinesSection {
    <#
    .SYNOPSIS
        Formats the Baselines section, including BOD 25-01 placeholders.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]
        $BaselineItems,

        [Parameter(Mandatory = $true)]
        [string]
        $Owner,

        [Parameter(Mandatory = $true)]
        [string]
        $Repository
    )

    $BodConfigurationsUrl =
        'https://www.cisa.gov/resources-tools/services/bod-25-01-implementing-secure-practices-cloud-services-required-configurations'
    $BaselineIssuesUrl = New-GitHubIssuesSearchUrl `
        -Owner $Owner `
        -Repository $Repository `
        -Query 'is:issue is:closed label:baseline-document -label:Testing -label:documentation -label:epic'

    $Lines = New-Object System.Collections.Generic.List[string]
    @(
        '## Baselines',
        '',
        '### BOD 25-01 required configuration policy changes',
        '',
        "This section lists baseline policy changes that affect current [BOD 25-01 Required Configurations]($BodConfigurationsUrl).",
        '',
        '#### Additions',
        '',
        'No new required configuration policies added in this release.',
        '',
        '#### Removals',
        '',
        '_Move BOD 25-01 policy removals here before publishing._',
        '',
        '#### Updates',
        '',
        '_Move BOD 25-01 policy version updates here before publishing._',
        '',
        '### Other baseline changes',
        ''
    ) | ForEach-Object { $Lines.Add($_) | Out-Null }

    if ($BaselineItems.Count -gt 0) {
        foreach ($Item in $BaselineItems) {
            $Lines.Add($Item) | Out-Null
        }
    }
    else {
        $Lines.Add('No baseline updates included in this release.') | Out-Null
    }

    $Lines.Add("* See full list of baseline updates [here]($BaselineIssuesUrl)") | Out-Null
    return (($Lines -join "`r`n") + "`r`n")
}

function Format-ReleaseNotesDependenciesSection {
    <#
    .SYNOPSIS
        Formats the Dependencies section of the release notes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]
        $Items,

        [Parameter(Mandatory = $true)]
        [string]
        $Owner,

        [Parameter(Mandatory = $true)]
        [string]
        $Repository
    )

    $DependencyIssuesUrl = New-GitHubIssuesSearchUrl `
        -Owner $Owner `
        -Repository $Repository `
        -Query 'is:pr is:merged (author:app/github-actions OR author:dependabot) sort:updated-desc'

    $Lines = New-Object System.Collections.Generic.List[string]
    $Lines.Add('## Dependencies') | Out-Null
    $Lines.Add('') | Out-Null

    if ($Items.Count -gt 0) {
        foreach ($Item in $Items) {
            $Lines.Add($Item) | Out-Null
        }
    }
    else {
        $Lines.Add('No dependency updates included in this release.') | Out-Null
    }

    $Lines.Add("* See full list of dependency updates [here]($DependencyIssuesUrl)") | Out-Null
    return (($Lines -join "`r`n") + "`r`n")
}

function Get-GitHubTagCommitSha {
    <#
    .SYNOPSIS
        Resolves a tag name to the commit SHA it points at. Returns null if the tag is missing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Owner,

        [Parameter(Mandatory = $true)]
        [string]
        $Repository,

        [Parameter(Mandatory = $true)]
        [string]
        $TagName
    )

    try {
        $Ref = Invoke-GitHubApi -Path "repos/$Owner/$Repository/git/ref/tags/$TagName"
    }
    catch {
        if ("$_" -match 'status 404') {
            return $null
        }
        throw
    }

    if ($Ref.object.type -eq 'commit') {
        return $Ref.object.sha
    }

    $Tag = Invoke-GitHubApi -Path "repos/$Owner/$Repository/git/tags/$($Ref.object.sha)"
    return $Tag.object.sha
}

function Get-ReleaseNotesCompareHeadRef {
    <#
    .SYNOPSIS
        Chooses the compare head: explicit input, existing tag, or the workflow branch.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Owner,

        [Parameter(Mandatory = $true)]
        [string]
        $Repository,

        [Parameter(Mandatory = $true)]
        [string]
        $CurrentTag,

        [Parameter(Mandatory = $false)]
        [string]
        $CompareHeadRefInput,

        [Parameter(Mandatory = $true)]
        [string]
        $RefName
    )

    if (-not [string]::IsNullOrWhiteSpace($CompareHeadRefInput)) {
        return $CompareHeadRefInput.Trim()
    }

    $Sha = Get-GitHubTagCommitSha -Owner $Owner -Repository $Repository -TagName $CurrentTag
    if ($null -ne $Sha) {
        Write-Warning "Tag $CurrentTag already exists; using it as the compare head for release notes."
        return $CurrentTag
    }

    Write-Warning "Tag $CurrentTag does not exist yet (expected before publish). Using branch $RefName as the compare head."
    return $RefName
}

function Get-MergedPullRequestsForCompare {
    <#
    .SYNOPSIS
        Collects merged pull requests associated with commits between two refs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Owner,

        [Parameter(Mandatory = $true)]
        [string]
        $Repository,

        [Parameter(Mandatory = $true)]
        [string]
        $PreviousTag,

        [Parameter(Mandatory = $true)]
        [string]
        $CurrentTag,

        [Parameter(Mandatory = $false)]
        [string]
        $CompareHeadRefInput,

        [Parameter(Mandatory = $true)]
        [string]
        $RefName
    )

    $HeadRef = Get-ReleaseNotesCompareHeadRef `
        -Owner $Owner `
        -Repository $Repository `
        -CurrentTag $CurrentTag `
        -CompareHeadRefInput $CompareHeadRefInput `
        -RefName $RefName
    $BaseHead = "$PreviousTag...$HeadRef"

    $Comparison = Invoke-GitHubApi -Path "repos/$Owner/$Repository/compare/$BaseHead"
    $CommitCount = 0
    if ($Comparison.commits) {
        $CommitCount = @($Comparison.commits).Count
    }
    Write-Warning "Comparing $BaseHead : $CommitCount commits (status: $($Comparison.status))."

    $PullRequestsByNumber = @{}
    foreach ($Commit in @($Comparison.commits)) {
        $Pulls = Invoke-GitHubApi -Path "repos/$Owner/$Repository/commits/$($Commit.sha)/pulls"
        foreach ($PullRequest in @($Pulls)) {
            if ($PullRequest.merged_at) {
                $PullRequestsByNumber[$PullRequest.number] = $PullRequest
            }
        }
    }

    Write-Warning "Found $($PullRequestsByNumber.Count) pull requests associated with commits in $BaseHead."

    return [PSCustomObject]@{
        PullRequestsByNumber = $PullRequestsByNumber
        HeadRef              = $HeadRef
        BaseHead             = $BaseHead
    }
}

function New-ReleaseNotes {
    <#
    .SYNOPSIS
        Builds draft GitHub release notes from merged pull requests since the previous release.
    .PARAMETER Version
        The release version without a leading v (e.g. 1.2.4).
    .PARAMETER Owner
        GitHub repository owner. Defaults to GITHUB_REPOSITORY.
    .PARAMETER Repository
        GitHub repository name. Defaults to GITHUB_REPOSITORY.
    .PARAMETER CompareHeadRef
        Optional compare head (branch or tag). When empty, uses the version tag if it exists, otherwise RefName.
    .PARAMETER RefName
        Branch name to use when the version tag does not exist yet. Defaults to GITHUB_REF_NAME.
    .PARAMETER ServerUrl
        GitHub server URL used in the changelog compare link. Defaults to GITHUB_SERVER_URL.
    .PARAMETER OutputPath
        File to write the notes to. Defaults to release-body.md in the current directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [Parameter(Mandatory = $false)]
        [string]
        $Owner,

        [Parameter(Mandatory = $false)]
        [string]
        $Repository,

        [Parameter(Mandatory = $false)]
        [string]
        $CompareHeadRef,

        [Parameter(Mandatory = $false)]
        [string]
        $RefName,

        [Parameter(Mandatory = $false)]
        [string]
        $ServerUrl,

        [Parameter(Mandatory = $false)]
        [string]
        $OutputPath = 'release-body.md'
    )

    if ([string]::IsNullOrWhiteSpace($Owner) -or [string]::IsNullOrWhiteSpace($Repository)) {
        if ([string]::IsNullOrWhiteSpace($env:GITHUB_REPOSITORY) -or ($env:GITHUB_REPOSITORY -notmatch '/')) {
            throw 'Owner and Repository are required when GITHUB_REPOSITORY is not set.'
        }
        $RepoParts = $env:GITHUB_REPOSITORY -split '/', 2
        if ([string]::IsNullOrWhiteSpace($Owner)) {
            $Owner = $RepoParts[0]
        }
        if ([string]::IsNullOrWhiteSpace($Repository)) {
            $Repository = $RepoParts[1]
        }
    }

    if ([string]::IsNullOrWhiteSpace($RefName)) {
        $RefName = $env:GITHUB_REF_NAME
    }
    if ([string]::IsNullOrWhiteSpace($RefName)) {
        throw 'RefName is required when GITHUB_REF_NAME is not set.'
    }

    if ([string]::IsNullOrWhiteSpace($ServerUrl)) {
        $ServerUrl = $env:GITHUB_SERVER_URL
    }
    if ([string]::IsNullOrWhiteSpace($ServerUrl)) {
        $ServerUrl = 'https://github.com'
    }

    $TagName = "v$Version"
    $PreviousTag = Get-PreviousReleaseTag -Owner $Owner -Repository $Repository -Version $Version
    $CompareResult = Get-MergedPullRequestsForCompare `
        -Owner $Owner `
        -Repository $Repository `
        -PreviousTag $PreviousTag `
        -CurrentTag $TagName `
        -CompareHeadRefInput $CompareHeadRef `
        -RefName $RefName

    $SectionOrder = @(
        'Major Changes',
        'Bugs Fixed',
        'Baselines',
        'Documentation',
        'Dependencies'
    )
    $Grouped = @{}
    foreach ($Title in $SectionOrder) {
        $Grouped[$Title] = New-Object System.Collections.Generic.List[string]
    }

    foreach ($PullRequest in $CompareResult.PullRequestsByNumber.Values) {
        $Section = Get-ReleaseNoteCategory -PullRequest $PullRequest
        if ($Section) {
            $Grouped[$Section].Add((Format-ReleaseNotePullRequest -PullRequest $PullRequest)) | Out-Null
        }
    }

    $Sections = foreach ($Title in $SectionOrder) {
        $IncludeAlways = ($Title -eq 'Baselines') -or ($Title -eq 'Dependencies')
        if (-not $IncludeAlways -and $Grouped[$Title].Count -eq 0) {
            continue
        }

        if ($Title -eq 'Baselines') {
            Format-ReleaseNotesBaselinesSection -BaselineItems @($Grouped['Baselines']) -Owner $Owner -Repository $Repository
        }
        elseif ($Title -eq 'Dependencies') {
            Format-ReleaseNotesDependenciesSection -Items @($Grouped['Dependencies']) -Owner $Owner -Repository $Repository
        }
        else {
            Format-ReleaseNotesSection -Title $Title -Items @($Grouped[$Title]) -Owner $Owner -Repository $Repository
        }
    }

    $CompareUrl = "$ServerUrl/$Owner/$Repository/compare/$($CompareResult.BaseHead)"
    $Body = (($Sections -join "`r`n") + "`r`n**Full Changelog**: $CompareUrl`r`n")

    $FullOutputPath = $OutputPath
    if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
        $FullOutputPath = Join-Path -Path (Get-Location) -ChildPath $OutputPath
    }
    $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($FullOutputPath, $Body, $Utf8NoBom)

    $DependencyCount = $Grouped['Dependencies'].Count
    Write-Warning "Release notes include $($CompareResult.PullRequestsByNumber.Count) pull requests ($DependencyCount in Dependencies)."
    if ($DependencyCount -eq 0) {
        Write-Warning "No dependency pull requests were linked to commits in $($CompareResult.BaseHead). Cherry-picked changes may need to be added manually."
    }

    return $Body
}
