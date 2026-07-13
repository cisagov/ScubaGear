Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Diff/Diff.psm1') -Force

InModuleScope Diff {
    Describe -Tag 'Diff' -Name 'Diff helper functions' {

        Context 'Get-ScubaBaseControlId' {
            It 'Strips a v1 suffix' {
                Get-ScubaBaseControlId 'MS.AAD.1.1v1' | Should -Be 'MS.AAD.1.1'
            }
            It 'Strips a multi-digit v12 suffix' {
                Get-ScubaBaseControlId 'MS.AAD.1.1v12' | Should -Be 'MS.AAD.1.1'
            }
            It 'Strips a hypothetical v1.2 suffix' {
                Get-ScubaBaseControlId 'MS.AAD.1.1v1.2' | Should -Be 'MS.AAD.1.1'
            }
            It 'Leaves an ID with no version suffix unchanged' {
                Get-ScubaBaseControlId 'MS.AAD.1.1' | Should -Be 'MS.AAD.1.1'
            }
        }

        Context 'Get-ScubaControlVersion' {
            It 'Returns v1' { Get-ScubaControlVersion 'MS.AAD.1.1v1' | Should -Be 'v1' }
            It 'Returns v12' { Get-ScubaControlVersion 'MS.AAD.1.1v12' | Should -Be 'v12' }
            It 'Returns v1.2' { Get-ScubaControlVersion 'MS.AAD.1.1v1.2' | Should -Be 'v1.2' }
            It 'Returns null when absent' { Get-ScubaControlVersion 'MS.AAD.1.1' | Should -BeNullOrEmpty }
        }

        Context 'Get-ScubaResultCategory' {
            It 'Classifies known results' {
                Get-ScubaResultCategory 'Pass'    | Should -Be 'Pass'
                Get-ScubaResultCategory 'Fail'    | Should -Be 'Fail'
                Get-ScubaResultCategory 'Warning' | Should -Be 'Warning'
                Get-ScubaResultCategory 'N/A'     | Should -Be 'NA'
                Get-ScubaResultCategory 'Omitted' | Should -Be 'Omitted'
                Get-ScubaResultCategory 'Error'   | Should -Be 'Error'
            }
            It 'Classifies unknown results as Other' {
                Get-ScubaResultCategory 'Bug'   | Should -Be 'Other'
                Get-ScubaResultCategory ''      | Should -Be 'Other'
                Get-ScubaResultCategory $null   | Should -Be 'Other'
            }
        }

        Context 'Get-ScubaCanonicalProduct' {
            It 'Maps Defender to SecuritySuite' {
                Get-ScubaCanonicalProduct 'Defender' | Should -Be 'SecuritySuite'
            }
            It 'Leaves other products unchanged' {
                Get-ScubaCanonicalProduct 'AAD' | Should -Be 'AAD'
                Get-ScubaCanonicalProduct 'SecuritySuite' | Should -Be 'SecuritySuite'
            }
        }

        Context 'ConvertTo-ScubaPlainText' {
            It 'Removes the policy-indicators block' {
                $out = ConvertTo-ScubaPlainText "Do the thing.<div class='policy-indicators'><a href='x'>Automated</a></div>"
                $out | Should -Be 'Do the thing.'
            }
            It 'Strips remaining tags and decodes entities' {
                $out = ConvertTo-ScubaPlainText 'Set <b>A</b> &amp; B.'
                $out | Should -Be 'Set A & B.'
            }
            It 'Returns empty string for null/empty' {
                ConvertTo-ScubaPlainText $null | Should -Be ''
                ConvertTo-ScubaPlainText ''    | Should -Be ''
            }
        }

        Context 'Get-ScubaBucketLabel' {
            It 'Displays PolicyRemoved as "Policy Removed"' {
                Get-ScubaBucketLabel 'PolicyRemoved' | Should -Be 'Policy Removed'
            }
            It 'Returns the raw token for buckets without a friendly label' {
                Get-ScubaBucketLabel 'Regression' | Should -Be 'Regression'
            }
        }

        Context 'Get-ScubaRowColorClass' {
            It 'Greys out removed policies regardless of before result' {
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'PolicyRemoved'; ResultAfter = $null }) | Should -Be 'grey'
            }
            It 'Colors by Result (After): Fail=red, Warning=yellow, Pass=green' {
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'Regression'; ResultAfter = 'Fail' })    | Should -Be 'red'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'NewWarning'; ResultAfter = 'Warning' }) | Should -Be 'yellow'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'Remediated'; ResultAfter = 'Pass' })    | Should -Be 'green'
            }
            It 'Treats Error as red and manual/omitted/other as grey' {
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'Errored'; ResultAfter = 'Error' })     | Should -Be 'red'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'NewlyManual'; ResultAfter = 'N/A' })   | Should -Be 'grey'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'OmissionChanged'; ResultAfter = 'Omitted' }) | Should -Be 'grey'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'Other'; ResultAfter = 'Bug' })         | Should -Be 'grey'
            }
        }

        Context 'Get-ScubaMarkdownAnchor' {
            It 'Generates GitHub-style anchors for control IDs' {
                Get-ScubaMarkdownAnchor 'MS.EXO.8.1v2' | Should -Be 'msexo81v2'
                Get-ScubaMarkdownAnchor 'MS.AAD.5.4v1' | Should -Be 'msaad54v1'
            }
        }

        Context 'ConvertTo-ScubaHtmlEncoded' {
            It 'Encodes HTML metacharacters' {
                ConvertTo-ScubaHtmlEncoded '<script>&' | Should -Be '&lt;script&gt;&amp;'
            }
        }

        Context 'Get-ScubaDiffBucket classification' {
            $cases = @(
                @{ B = 'Pass';    A = 'Fail';    Bv = 'v1'; Av = 'v1'; Expected = 'Regression' }
                @{ B = 'Fail';    A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'Remediated' }
                @{ B = 'Warning'; A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'WarningResolved' }
                @{ B = 'Warning'; A = 'Fail';    Bv = 'v1'; Av = 'v1'; Expected = 'WarningEscalated' }
                @{ B = 'Pass';    A = 'Warning'; Bv = 'v1'; Av = 'v1'; Expected = 'NewWarning' }
                @{ B = 'Fail';    A = 'Warning'; Bv = 'v1'; Av = 'v1'; Expected = 'NewWarning' }
                @{ B = 'N/A';     A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'NewlyAutomated' }
                @{ B = 'Pass';    A = 'N/A';     Bv = 'v1'; Av = 'v1'; Expected = 'NewlyManual' }
                @{ B = 'Pass';    A = 'Omitted'; Bv = 'v1'; Av = 'v1'; Expected = 'OmissionChanged' }
                @{ B = 'Omitted'; A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'OmissionChanged' }
                @{ B = 'Pass';    A = 'Pass';    Bv = 'v1'; Av = 'v2'; Expected = 'VersionChanged' }
                @{ B = 'Pass';    A = 'Error';   Bv = 'v1'; Av = 'v1'; Expected = 'Errored' }
                @{ B = 'Error';   A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'Errored' }
                @{ B = 'Pass';    A = 'Bug';     Bv = 'v1'; Av = 'v1'; Expected = 'Other' }
                @{ B = 'Pass';    A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'Unchanged' }
                @{ B = 'Fail';    A = 'Fail';    Bv = 'v1'; Av = 'v1'; Expected = 'Unchanged' }
                @{ B = 'Omitted'; A = 'Omitted'; Bv = 'v1'; Av = 'v1'; Expected = 'Unchanged' }
            )
            It 'Classifies <B>-><A> (versions <Bv>/<Av>) as <Expected>' -TestCases $cases {
                param($B, $A, $Bv, $Av, $Expected)
                $bucket = Get-ScubaDiffBucket -BeforeResult $B -AfterResult $A `
                    -BeforePresent $true -AfterPresent $true -BeforeVersion $Bv -AfterVersion $Av
                $bucket | Should -Be $Expected
            }
            It 'Classifies presence-only cases' {
                (Get-ScubaDiffBucket -BeforeResult $null -AfterResult 'Pass' -BeforePresent $false -AfterPresent $true -BeforeVersion $null -AfterVersion 'v1') | Should -Be 'New'
                (Get-ScubaDiffBucket -BeforeResult 'Pass' -AfterResult $null -BeforePresent $true -AfterPresent $false -BeforeVersion 'v1' -AfterVersion $null) | Should -Be 'PolicyRemoved'
            }
            It 'Prefers Errored over VersionChanged (precedence)' {
                (Get-ScubaDiffBucket -BeforeResult 'Error' -AfterResult 'Pass' -BeforePresent $true -AfterPresent $true -BeforeVersion 'v1' -AfterVersion 'v2') | Should -Be 'Errored'
            }
        }
    }

    Describe -Tag 'Diff' -Name 'Import-ScubaResultsFile' {
        BeforeAll {
            $script:FixtureDir = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
        }
        It 'Reads a BOM-encoded ScubaResults file' {
            $obj = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairA-Before.json')
            $obj.MetaData.ReportUUID | Should -Be 'aaaaaaaa-0000-0000-0000-000000000001'
        }
        It 'Throws on a nonexistent path' {
            { Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'does-not-exist.json') } | Should -Throw '*not found*'
        }
        It 'Throws on a file missing a required top-level key' {
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("scuba-diff-bad-" + [guid]::NewGuid() + ".json")
            '{ "MetaData": {}, "Summary": {} }' | Set-Content -Path $tmp
            try {
                { Import-ScubaResultsFile -Path $tmp } | Should -Throw '*Results*'
            }
            finally {
                Remove-Item $tmp -ErrorAction SilentlyContinue
            }
        }
        It 'Throws on invalid JSON' {
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("scuba-diff-bad-" + [guid]::NewGuid() + ".json")
            'not json {{{' | Set-Content -Path $tmp
            try {
                { Import-ScubaResultsFile -Path $tmp } | Should -Throw '*not valid JSON*'
            }
            finally {
                Remove-Item $tmp -ErrorAction SilentlyContinue
            }
        }
    }

    Describe -Tag 'Diff' -Name 'Compare-ScubaResults on fixture pair A' {
        BeforeAll {
            $script:FixtureDir = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $Before = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairA-Before.json')
            $After = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairA-After.json')
            $script:DiffA = Compare-ScubaResults -Before $Before -After $After -ToolVersion '9.9.9'
            $script:ByBase = @{}
            foreach ($rec in $DiffA.Diff.AAD) {
                $id = if ($rec.'Control ID (After)') { $rec.'Control ID (After)' } else { $rec.'Control ID (Before)' }
                $script:ByBase[(Get-ScubaBaseControlId $id)] = $rec
            }
        }

        It 'Sets SchemaVersion 1.0 and MetaData' {
            $DiffA.SchemaVersion | Should -Be '1.0'
            $DiffA.MetaData.Tool | Should -Be 'ScubaGear'
            $DiffA.MetaData.ToolVersion | Should -Be '9.9.9'
            $DiffA.MetaData.Before.ReportUUID | Should -Be 'aaaaaaaa-0000-0000-0000-000000000001'
            $DiffA.MetaData.After.ReportUUID | Should -Be 'aaaaaaaa-0000-0000-0000-000000000002'
        }

        $expected = @(
            @{ Base = 'MS.AAD.1.1';  Bucket = 'Regression' }
            @{ Base = 'MS.AAD.2.1';  Bucket = 'Remediated' }
            @{ Base = 'MS.AAD.3.1';  Bucket = 'WarningResolved' }
            @{ Base = 'MS.AAD.4.1';  Bucket = 'WarningEscalated' }
            @{ Base = 'MS.AAD.5.1';  Bucket = 'NewWarning' }
            @{ Base = 'MS.AAD.6.1';  Bucket = 'NewlyAutomated' }
            @{ Base = 'MS.AAD.7.1';  Bucket = 'NewlyManual' }
            @{ Base = 'MS.AAD.8.1';  Bucket = 'OmissionChanged' }
            @{ Base = 'MS.AAD.9.1';  Bucket = 'PolicyRemoved' }
            @{ Base = 'MS.AAD.10.1'; Bucket = 'New' }
            @{ Base = 'MS.AAD.11.1'; Bucket = 'Errored' }
            @{ Base = 'MS.AAD.12.1'; Bucket = 'Other' }
            @{ Base = 'MS.AAD.14.1'; Bucket = 'Unchanged' }
        )
        It '<Base> is classified as <Bucket>' -TestCases $expected {
            param($Base, $Bucket)
            $ByBase[$Base].Bucket | Should -Be $Bucket
        }

        It 'Preserves both literal Result values for Other' {
            $ByBase['MS.AAD.12.1'].ResultBefore | Should -Be 'Pass'
            $ByBase['MS.AAD.12.1'].ResultAfter  | Should -Be 'Bug'
        }

        It 'Strips embedded HTML from the Requirement field' {
            $ByBase['MS.AAD.1.1'].Requirement | Should -Be 'Regression control.'
            $ByBase['MS.AAD.1.1'].Requirement | Should -Not -Match 'policy-indicators'
        }

        It 'Omits before-only fields for New controls' {
            $ByBase['MS.AAD.10.1'].'Control ID (Before)' | Should -BeNullOrEmpty
            $ByBase['MS.AAD.10.1'].ResultBefore | Should -BeNullOrEmpty
        }

        It 'Omits after-only fields for PolicyRemoved controls' {
            $ByBase['MS.AAD.9.1'].'Control ID (After)' | Should -BeNullOrEmpty
            $ByBase['MS.AAD.9.1'].ResultAfter | Should -BeNullOrEmpty
        }

        It 'Reports every taxonomy bucket in the Summary' {
            foreach ($e in @('Regression','Remediated','WarningResolved','WarningEscalated','NewWarning','NewlyAutomated','NewlyManual','OmissionChanged','PolicyRemoved','New','Errored','Other','Unchanged')) {
                $DiffA.Summary.AAD.Contains($e) | Should -BeTrue -Because "bucket $e should appear in the summary"
            }
        }
    }

    Describe -Tag 'Diff' -Name 'Fail->Fail annotation comparison' {
        BeforeAll {
            function New-FailResults {
                param($Comment, $RemediationDate, $HasAnnotation = $true)
                $annot = if ($HasAnnotation) {
                    @{ 'MS.AAD.1.1v1' = @{ Comment = $Comment; RemediationDate = $RemediationDate; IncorrectResult = $false } }
                } else { @{} }
                $obj = @{
                    MetaData = @{ ReportUUID = 'x'; TimestampZulu = 't'; ToolVersion = '1' }
                    Summary = @{ AAD = @{} }
                    AnnotatedFailedPolicies = $annot
                    Results = @{ AAD = @( @{ GroupName = 'G'; GroupNumber = '1'; Controls = @(
                        @{ 'Control ID' = 'MS.AAD.1.1v1'; Requirement = 'R'; Result = 'Fail'; Criticality = 'Shall'; Details = 'd' }
                    ) } ) }
                }
                return $obj | ConvertTo-Json -Depth 10 | ConvertFrom-Json
            }
        }
        It 'Flags null -> comment as changed' {
            $b = New-FailResults -HasAnnotation $false
            $a = New-FailResults -Comment 'now commented' -RemediationDate '2026-01-01'
            $diff = Compare-ScubaResults -Before $b -After $a
            $rec = $diff.Diff.AAD[0]
            $rec.AnnotationChanged | Should -BeTrue
            $rec.Comment | Should -Be 'now commented'
            $rec.RemediationDate | Should -Be '2026-01-01'
        }
        It 'Flags comment -> different comment as changed' {
            $b = New-FailResults -Comment 'old' -RemediationDate '2026-01-01'
            $a = New-FailResults -Comment 'new' -RemediationDate '2026-01-01'
            $diff = Compare-ScubaResults -Before $b -After $a
            $diff.Diff.AAD[0].AnnotationChanged | Should -BeTrue
        }
        It 'Does not flag identical annotations' {
            $b = New-FailResults -Comment 'same' -RemediationDate '2026-01-01'
            $a = New-FailResults -Comment 'same' -RemediationDate '2026-01-01'
            $diff = Compare-ScubaResults -Before $b -After $a
            $diff.Diff.AAD[0].AnnotationChanged | Should -BeFalse
        }
    }

    Describe -Tag 'Diff' -Name 'Fixture pair B: version + product drift' {
        BeforeAll {
            $script:FixtureDir = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $Before = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairB-Before.json')
            $After = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairB-After.json')
            $script:DiffB = Compare-ScubaResults -Before $Before -After $After -ToolVersion '9.9.9'
        }
        It 'Alias-joins Defender/SecuritySuite under the after-file product name' {
            @($DiffB.Diff.Keys) | Should -Contain 'SecuritySuite'
            @($DiffB.Diff.Keys) | Should -Not -Contain 'Defender'
        }
        It 'Does not report the renamed product as retired or new' {
            $DiffB.MetaData.ProductsOnlyInBefore | Should -BeNullOrEmpty
            $DiffB.MetaData.ProductsOnlyInAfter | Should -BeNullOrEmpty
        }
        It 'Marks alias-joined records with ProductRenamed = true' {
            foreach ($rec in $DiffB.Diff.SecuritySuite) {
                $rec.ProductRenamed | Should -BeTrue
            }
        }
        It 'Classifies a base ID at v1 vs v2 as VersionChanged (never New/PolicyRemoved)' {
            $rec = $DiffB.Diff.SecuritySuite | Where-Object { (Get-ScubaBaseControlId $_.'Control ID (After)') -eq 'MS.DEFENDER.1.1' }
            $rec.Bucket | Should -Be 'VersionChanged'
            $rec.'Control ID (Before)' | Should -Be 'MS.DEFENDER.1.1v1'
            $rec.'Control ID (After)'  | Should -Be 'MS.DEFENDER.1.1v2'
        }
        It 'Strips embedded HTML from the Requirement field' {
            $rec = $DiffB.Diff.SecuritySuite | Where-Object { (Get-ScubaBaseControlId $_.'Control ID (After)') -eq 'MS.DEFENDER.3.1' }
            $rec.Requirement | Should -Be 'Configure A & B properly.'
        }
    }

    Describe -Tag 'Diff' -Name 'New-ScubaDiffReport HTML rendering' {
        BeforeAll {
            $script:FixtureDir = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $Before = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairA-Before.json')
            $After = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairA-After.json')
            $diff = Compare-ScubaResults -Before $Before -After $After -ToolVersion '9.9.9'
            $script:Html = New-ScubaDiffReport -DiffResults $diff
            $BeforeB = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairB-Before.json')
            $AfterB = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairB-After.json')
            $diffB = Compare-ScubaResults -Before $BeforeB -After $AfterB -ToolVersion '9.9.9'
            $script:HtmlB = New-ScubaDiffReport -DiffResults $diffB
        }
        It 'Includes the unchanged-rows toggle markup' {
            $Html | Should -Match 'id="toggle-unchanged"'
        }
        It 'Includes the dark-mode toggle and flag' {
            $Html | Should -Match 'id="toggle-dark"'
            $Html | Should -Match 'id="dark-mode-flag"'
        }
        It 'Defaults dark-mode flag to true when -DarkMode is set' {
            $Before = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairA-Before.json')
            $After = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairA-After.json')
            $diff = Compare-ScubaResults -Before $Before -After $After
            $dark = New-ScubaDiffReport -DiffResults $diff -DarkMode
            $dark | Should -Match '<script id="dark-mode-flag" type="application/json">true</script>'
        }
        It 'Emits a row class for each color state' {
            $Html | Should -Match 'diff-red'
            $Html | Should -Match 'diff-green'
            $Html | Should -Match 'diff-yellow'
            $Html | Should -Match 'diff-grey'
        }
        It 'Colors rows by Result (After): a Fail-after row is red' {
            # MS.AAD.1.1 is Pass->Fail (Regression), so its row must be red, not
            # colored by the transition bucket.
            $Html | Should -Match 'MS.AAD.1.1v1[\s\S]*?Regression'
            $Html | Should -Match 'class="diff-row diff-red"'
        }
        It 'Greys out removed-policy rows like manual checks' {
            $Html | Should -Match 'class="diff-row diff-grey[^"]*"'
        }
        It 'Marks unchanged rows with the hide-by-default class' {
            $Html | Should -Match 'diff-unchanged-row'
        }
        It 'Displays the PolicyRemoved bucket as "Policy Removed"' {
            $Html | Should -Match 'Policy Removed'
        }
        It 'HTML-escapes user content and never emits the raw indicator markup' {
            $HtmlB | Should -Match 'Configure A &amp; B properly'
            $HtmlB | Should -Not -Match "policy-indicators"
        }
    }
    Describe -Tag 'Diff' -Name 'Removed-policy metadata (removedpolicies.md)' {
        It 'Parses removal dates and anchors from the shipped removedpolicies.md' {
            $map = Get-ScubaRemovedPolicyMap
            $map.ContainsKey('MS.EXO.8.1v2') | Should -BeTrue
            $map['MS.EXO.8.1v2'].Date | Should -Be 'April 2026'
            $map['MS.EXO.8.1v2'].Anchor | Should -Be 'msexo81v2'
            $map['MS.AAD.5.4v1'].Date | Should -Be 'March 2025'
        }

        It 'Adds the removal date and a baseline link to a removed-policy Note' {
            function New-RemovedResults {
                param([switch]$IncludeControl)
                $controls = @()
                if ($IncludeControl) {
                    $controls += @{ 'Control ID' = 'MS.EXO.8.1v2'; Requirement = 'A DLP solution SHALL be used.'; Result = 'Pass'; Criticality = 'Shall'; Details = 'd' }
                }
                $obj = @{
                    MetaData = @{ ReportUUID = 'x'; TimestampZulu = 't'; ToolVersion = '1' }
                    Summary = @{ EXO = @{} }
                    AnnotatedFailedPolicies = @{}
                    Results = @{ EXO = @( @{ GroupName = 'DLP'; GroupNumber = '8'; Controls = $controls } ) }
                }
                return $obj | ConvertTo-Json -Depth 10 | ConvertFrom-Json
            }
            $before = New-RemovedResults -IncludeControl
            $after = New-RemovedResults
            $diff = Compare-ScubaResults -Before $before -After $after
            $diff.Diff.EXO[0].Bucket | Should -Be 'PolicyRemoved'
            $html = New-ScubaDiffReport -DiffResults $diff
            $html | Should -Match 'Removed from baseline'
            $html | Should -Match 'last updated: April 2026'
            $html | Should -Match 'removedpolicies\.md#msexo81v2'
        }
    }
}

AfterAll {
    Remove-Module Diff -ErrorAction SilentlyContinue
}
