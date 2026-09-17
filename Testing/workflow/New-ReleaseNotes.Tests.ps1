# The purpose of these tests is to verify the release notes helpers
# extracted from the Build and Draft Release workflow.

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

BeforeAll {
    . $PSScriptRoot/../../utils/workflow/New-ReleaseNotes.ps1

    function New-TestPullRequest {
        param(
            [int]$Number,
            [string]$Title,
            [string]$Login,
            [string[]]$Labels = @(),
            [string]$MergedAt = '2026-01-01T00:00:00Z'
        )

        $LabelObjects = @($Labels | ForEach-Object { [PSCustomObject]@{ name = $_ } })
        return [PSCustomObject]@{
            number    = $Number
            title     = $Title
            merged_at = $MergedAt
            user      = [PSCustomObject]@{ login = $Login }
            labels    = $LabelObjects
        }
    }
}

Describe 'ConvertFrom-ReleaseTagVersion' {
    It 'parses a v-prefixed patch version' {
        $Parsed = ConvertFrom-ReleaseTagVersion -TagName 'v1.2.3'
        $Parsed.Parts[0] | Should -Be 1
        $Parsed.Parts[1] | Should -Be 2
        $Parsed.Parts[2] | Should -Be 3
    }

    It 'parses a major.minor tag as patch 0' {
        $Parsed = ConvertFrom-ReleaseTagVersion -TagName '2.0'
        $Parsed.Parts | Should -Be @(2, 0, 0)
    }

    It 'returns null for an unparsable tag' {
        ConvertFrom-ReleaseTagVersion -TagName 'nightly' | Should -Be $null
    }
}

Describe 'Compare-ReleaseTagVersion' {
    It 'orders older versions before newer versions' {
        $Left = ConvertFrom-ReleaseTagVersion -TagName 'v1.8.0'
        $Right = ConvertFrom-ReleaseTagVersion -TagName 'v1.9.0'
        (Compare-ReleaseTagVersion -Left $Left -Right $Right) | Should -BeLessThan 0
    }

    It 'treats equal versions as zero' {
        $Left = ConvertFrom-ReleaseTagVersion -TagName 'v1.2.3'
        $Right = ConvertFrom-ReleaseTagVersion -TagName '1.2.3'
        (Compare-ReleaseTagVersion -Left $Left -Right $Right) | Should -Be 0
    }
}

Describe 'Get-GitHubNextPageUrl' {
    It 'returns the next URL from a Link header' {
        $Header = '<https://api.github.com/repos/o/r/releases?page=2>; rel="next", <https://api.github.com/repos/o/r/releases?page=3>; rel="last"'
        Get-GitHubNextPageUrl -LinkHeader $Header | Should -Be 'https://api.github.com/repos/o/r/releases?page=2'
    }

    It 'returns null when there is no next page' {
        Get-GitHubNextPageUrl -LinkHeader '<https://api.github.com/repos/o/r/releases?page=1>; rel="prev"' | Should -Be $null
        Get-GitHubNextPageUrl -LinkHeader $null | Should -Be $null
    }
}

Describe 'Get-ReleaseNoteCategory' {
    It 'excludes pull requests with skipped labels' {
        $Pr = New-TestPullRequest -Number 1 -Title 'WIP' -Login 'alice' -Labels @('Testing')
        Get-ReleaseNoteCategory -PullRequest $Pr | Should -Be $null
    }

    It 'categorizes dependabot pull requests as Dependencies' {
        $Pr = New-TestPullRequest -Number 2 -Title 'Bump actions/checkout' -Login 'dependabot[bot]' -Labels @('enhancement')
        Get-ReleaseNoteCategory -PullRequest $Pr | Should -Be 'Dependencies'
    }

    It 'categorizes enhancement, bug, documentation, and baseline labels' {
        $Enhancement = New-TestPullRequest -Number 3 -Title 'Add feature' -Login 'alice' -Labels @('enhancement')
        $Bug = New-TestPullRequest -Number 4 -Title 'Fix crash' -Login 'bob' -Labels @('bug')
        $Docs = New-TestPullRequest -Number 5 -Title 'Update docs' -Login 'carol' -Labels @('documentation')
        $Baseline = New-TestPullRequest -Number 6 -Title 'Update AAD' -Login 'dave' -Labels @('baseline-document')

        Get-ReleaseNoteCategory -PullRequest $Enhancement | Should -Be 'Major Changes'
        Get-ReleaseNoteCategory -PullRequest $Bug | Should -Be 'Bugs Fixed'
        Get-ReleaseNoteCategory -PullRequest $Docs | Should -Be 'Documentation'
        Get-ReleaseNoteCategory -PullRequest $Baseline | Should -Be 'Baselines'
    }

    It 'defaults unlabeled human pull requests to Dependencies' {
        $Pr = New-TestPullRequest -Number 7 -Title 'Misc change' -Login 'alice'
        Get-ReleaseNoteCategory -PullRequest $Pr | Should -Be 'Dependencies'
    }
}

Describe 'Format-ReleaseNotePullRequest' {
    It 'matches the GitHub-style bullet format' {
        $Pr = New-TestPullRequest -Number 42 -Title 'Fix login' -Login 'alice'
        Format-ReleaseNotePullRequest -PullRequest $Pr | Should -Be '* Fix login by @alice in #42'
    }
}

Describe 'Get-PreviousReleaseTag' {
    It 'returns the newest published release older than the current version' {
        Mock -CommandName Invoke-GitHubApi -MockWith {
            @(
                [PSCustomObject]@{ draft = $true; prerelease = $false; tag_name = 'v1.9.0'; published_at = '2026-03-01' }
                [PSCustomObject]@{ draft = $false; prerelease = $true; tag_name = 'v1.8.1'; published_at = '2026-02-15' }
                [PSCustomObject]@{ draft = $false; prerelease = $false; tag_name = 'v1.8.0'; published_at = '2026-02-01' }
                [PSCustomObject]@{ draft = $false; prerelease = $false; tag_name = 'v1.7.0'; published_at = '2026-01-01' }
            )
        }

        Get-PreviousReleaseTag -Owner 'cisagov' -Repository 'ScubaGear' -Version '1.9.0' | Should -Be 'v1.8.0'
    }

    It 'throws when the version cannot be parsed' {
        { Get-PreviousReleaseTag -Owner 'cisagov' -Repository 'ScubaGear' -Version 'next' } |
            Should -Throw '*Unable to parse release version*'
    }

    It 'throws when no older published release exists' {
        Mock -CommandName Invoke-GitHubApi -MockWith {
            @(
                [PSCustomObject]@{ draft = $false; prerelease = $false; tag_name = 'v2.0.0'; published_at = '2026-01-01' }
            )
        }

        { Get-PreviousReleaseTag -Owner 'cisagov' -Repository 'ScubaGear' -Version '1.0.0' } |
            Should -Throw '*Unable to find a published release older than v1.0.0*'
    }
}

Describe 'Get-ReleaseNotesCompareHeadRef' {
    It 'uses an explicit compare head when provided' {
        Get-ReleaseNotesCompareHeadRef `
            -Owner 'cisagov' `
            -Repository 'ScubaGear' `
            -CurrentTag 'v1.9.0' `
            -CompareHeadRefInput ' release/1.9.0 ' `
            -RefName 'main' | Should -Be 'release/1.9.0'
    }

    It 'uses the version tag when it already exists' {
        Mock -CommandName Invoke-GitHubApi -MockWith {
            [PSCustomObject]@{ object = [PSCustomObject]@{ type = 'commit'; sha = 'abc123' } }
        }

        Get-ReleaseNotesCompareHeadRef `
            -Owner 'cisagov' `
            -Repository 'ScubaGear' `
            -CurrentTag 'v1.9.0' `
            -CompareHeadRefInput '' `
            -RefName 'main' | Should -Be 'v1.9.0'
    }

    It 'falls back to the workflow branch when the tag does not exist' {
        Mock -CommandName Invoke-GitHubApi -MockWith {
            throw 'GitHub API GET repos/cisagov/ScubaGear/git/ref/tags/v1.9.0 failed with status 404 : Not Found'
        }

        Get-ReleaseNotesCompareHeadRef `
            -Owner 'cisagov' `
            -Repository 'ScubaGear' `
            -CurrentTag 'v1.9.0' `
            -CompareHeadRefInput '' `
            -RefName 'main' | Should -Be 'main'
    }
}

Describe 'New-ReleaseNotes' {
    It 'writes categorized notes and always includes Baselines and Dependencies' {
        Mock -CommandName Invoke-GitHubApi -MockWith {
            param($Path)
            if ($Path -match '/releases$') {
                return @(
                    [PSCustomObject]@{ draft = $false; prerelease = $false; tag_name = 'v1.8.0'; published_at = '2026-01-01' }
                )
            }
            if ($Path -match '/git/ref/tags/') {
                throw 'GitHub API GET git/ref failed with status 404 : Not Found'
            }
            if ($Path -match '/compare/') {
                return [PSCustomObject]@{
                    status  = 'ahead'
                    commits = @(
                        [PSCustomObject]@{ sha = 'aaa' },
                        [PSCustomObject]@{ sha = 'bbb' }
                    )
                }
            }
            if ($Path -match '/commits/aaa/pulls') {
                return @(
                    (New-TestPullRequest -Number 10 -Title 'Add MFA check' -Login 'alice' -Labels @('enhancement')),
                    (New-TestPullRequest -Number 11 -Title 'WIP epic' -Login 'alice' -Labels @('epic'))
                )
            }
            if ($Path -match '/commits/bbb/pulls') {
                return @(
                    (New-TestPullRequest -Number 12 -Title 'Bump opa' -Login 'dependabot[bot]')
                )
            }
            throw "Unexpected GitHub API path: $Path"
        }

        $OutputPath = Join-Path -Path $TestDrive -ChildPath 'release-body.md'
        $Body = New-ReleaseNotes `
            -Version '1.9.0' `
            -Owner 'cisagov' `
            -Repository 'ScubaGear' `
            -CompareHeadRef '' `
            -RefName 'main' `
            -ServerUrl 'https://github.com' `
            -OutputPath $OutputPath

        $Body | Should -Match '## Major Changes'
        $Body | Should -Match '\* Add MFA check by @alice in #10'
        $Body | Should -Not -Match 'WIP epic'
        $Body | Should -Match '## Baselines'
        $Body | Should -Match 'No baseline updates included in this release'
        $Body | Should -Match '## Dependencies'
        $Body | Should -Match '\* Bump opa by @dependabot\[bot\] in #12'
        $Body | Should -Match '\*\*Full Changelog\*\*: https://github.com/cisagov/ScubaGear/compare/v1.8.0\.\.\.main'
        $Body | Should -Not -Match '## Bugs Fixed'
        Test-Path -Path $OutputPath | Should -Be $true
        Get-Content -Path $OutputPath -Raw | Should -Be $Body
    }
}
