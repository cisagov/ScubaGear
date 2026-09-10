BeforeAll {
    . (Join-Path $PSScriptRoot '../../utils/workflow/New-ReleaseNotes.ps1')
    $script:CompareArgs = @{
        Owner = 'example'
        Repository = 'release'
        PreviousTag = 'v1.0.0'
        CurrentTag = 'v1.1.0'
        CompareHeadRefInput = 'main'
        RefName = 'main'
    }
}

Describe 'Release-note comparison pagination' {
    BeforeEach {
        $script:TotalCommits = 0
        $script:DuplicatePullRequest = $false
        $script:UnmergedCommit = 0
        $script:FailSecondPage = $false

        Mock Invoke-WebRequest {
            param($Uri)
            $ParsedUri = [uri]$Uri
            if ($ParsedUri.AbsolutePath -eq '/repos/example/release/compare/v1.0.0...main') {
                $Page = 1
                if ($ParsedUri.Query -match '(?:[?&])page=(\d+)') {
                    $Page = [int]$Matches[1]
                }
                if ($Page -eq 2 -and $script:FailSecondPage) {
                    throw 'Second comparison page unavailable'
                }
                # GitHub caps an unpaginated comparison at 250 commits.
                $PageSize = 250
                if ($ParsedUri.Query -match '(?:[?&])per_page=(\d+)') {
                    $PageSize = [int]$Matches[1]
                }
                $First = ($Page - 1) * $PageSize + 1
                $Last = [Math]::Min($Page * $PageSize, $script:TotalCommits)
                $Commits = @(for ($Number = $First; $Number -le $Last; $Number++) {
                    [PSCustomObject]@{ sha = [string]$Number }
                })
                $Headers = @{}
                if ($Last -lt $script:TotalCommits) {
                    $Headers.Link = '<https://api.github.com/repos/example/release/compare/v1.0.0...main?per_page={0}&page={1}>; rel="next"' -f $PageSize, ($Page + 1)
                }
                return [PSCustomObject]@{
                    Content = ConvertTo-Json -Compress -Depth 5 -InputObject @{
                        status = 'ahead'
                        total_commits = $script:TotalCommits
                        commits = $Commits
                    }
                    Headers = $Headers
                }
            }
            if ($ParsedUri.AbsolutePath -match '^/repos/example/release/commits/(\d+)/pulls$') {
                $Number = [int]$Matches[1]
                $MergedAt = '2026-09-01T12:00:00Z'
                if ($Number -eq $script:UnmergedCommit) {
                    $MergedAt = $null
                }
                if ($script:DuplicatePullRequest -and $Number -gt 1) {
                    $Number = 1
                }
                return [PSCustomObject]@{
                    Content = ConvertTo-Json -Compress -InputObject @(
                        [PSCustomObject]@{ number = $Number; merged_at = $MergedAt }
                    )
                    Headers = @{}
                }
            }
            throw "Unexpected API URL: $Uri"
        }
    }

    It 'includes all 301 commits across four comparison pages' {
        $script:TotalCommits = 301
        $Result = Get-MergedPullRequestsForCompare @script:CompareArgs
        $Result.PullRequestsByNumber.Count | Should -Be 301
        $Result.PullRequestsByNumber.Values.number | Should -Contain 301
        $Result.HeadRef | Should -Be 'main'
        $Result.BaseHead | Should -Be 'v1.0.0...main'
        Should -Invoke Invoke-WebRequest -Times 4 -Exactly -ParameterFilter {
            ([uri]$Uri).AbsolutePath -like '*/compare/*'
        }
    }

    It 'handles an empty comparison without querying a null commit' {
        $Result = Get-MergedPullRequestsForCompare @script:CompareArgs
        $Result.PullRequestsByNumber.Count | Should -Be 0
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly -ParameterFilter {
            ([uri]$Uri).AbsolutePath -like '*/commits/*/pulls'
        }
    }

    It 'handles a single commit' {
        $script:TotalCommits = 1
        $Result = Get-MergedPullRequestsForCompare @script:CompareArgs
        $Result.PullRequestsByNumber.Count | Should -Be 1
    }

    It 'stops at an exact page boundary' {
        $script:TotalCommits = 100
        $Result = Get-MergedPullRequestsForCompare @script:CompareArgs
        $Result.PullRequestsByNumber.Count | Should -Be 100
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
            ([uri]$Uri).AbsolutePath -like '*/compare/*'
        }
    }

    It 'deduplicates pull requests associated with multiple pages' {
        $script:TotalCommits = 101
        $script:DuplicatePullRequest = $true
        $Result = Get-MergedPullRequestsForCompare @script:CompareArgs
        $Result.PullRequestsByNumber.Count | Should -Be 1
        Should -Invoke Invoke-WebRequest -Times 101 -Exactly -ParameterFilter {
            ([uri]$Uri).AbsolutePath -like '*/commits/*/pulls'
        }
    }

    It 'excludes unmerged pull requests on later pages' {
        $script:TotalCommits = 101
        $script:UnmergedCommit = 101
        $Result = Get-MergedPullRequestsForCompare @script:CompareArgs
        $Result.PullRequestsByNumber.Count | Should -Be 100
        $Result.PullRequestsByNumber.Values.number | Should -Not -Contain 101
    }

    It 'fails instead of publishing partial notes when a later page fails' {
        $script:TotalCommits = 301
        $script:FailSecondPage = $true
        { Get-MergedPullRequestsForCompare @script:CompareArgs } | Should -Throw '*Second comparison page unavailable*'
    }
}
