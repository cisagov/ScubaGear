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
                Get-ScubaResultCategory 'Pass'             | Should -Be 'Pass'
                Get-ScubaResultCategory 'Fail'             | Should -Be 'Fail'
                Get-ScubaResultCategory 'Warning'          | Should -Be 'Warning'
                Get-ScubaResultCategory 'N/A'              | Should -Be 'NA'
                Get-ScubaResultCategory 'Omitted'          | Should -Be 'Omitted'
                Get-ScubaResultCategory 'Error'            | Should -Be 'Error'
                Get-ScubaResultCategory 'Incorrect result' | Should -Be 'Incorrect'
            }
            It 'Classifies unknown results as Other' {
                Get-ScubaResultCategory 'Bug'   | Should -Be 'Other'
                Get-ScubaResultCategory ''      | Should -Be 'Other'
                Get-ScubaResultCategory $null   | Should -Be 'Other'
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
            It 'Displays RemovedPolicy as "Removed Policy"' {
                Get-ScubaBucketLabel 'RemovedPolicy' | Should -Be 'Removed Policy'
            }
            It 'Returns the raw token for buckets without a friendly label' {
                Get-ScubaBucketLabel 'Errored' | Should -Be 'Errored'
            }
            It 'Gives the result-transition buckets friendly labels' {
                Get-ScubaBucketLabel 'NewFail'             | Should -Be 'New Fail'
                Get-ScubaBucketLabel 'NewPass'             | Should -Be 'New Pass'
                Get-ScubaBucketLabel 'PolicyVersionUpdate' | Should -Be 'Policy Version Update'
                Get-ScubaBucketLabel 'NewIncorrectResult'  | Should -Be 'New Incorrect Result (false positive)'
            }
        }

        Context 'Get-ScubaProductDisplayName' {
            $productTitles = @(
                @{ Key = 'AAD';           Title = 'Microsoft Entra ID / Azure Active Directory' }
                @{ Key = 'Defender';      Title = 'Microsoft 365 Defender' }
                @{ Key = 'EXO';           Title = 'Exchange Online' }
                @{ Key = 'PowerPlatform'; Title = 'Microsoft Power Platform' }
                @{ Key = 'PowerBI';       Title = 'Microsoft Power BI' }
                @{ Key = 'SharePoint';    Title = 'SharePoint Online' }
                @{ Key = 'Teams';         Title = 'Microsoft Teams' }
                @{ Key = 'SecuritySuite'; Title = 'Security Suite' }
            )
            It 'Maps <Key> to "<Title>"' -TestCases $productTitles {
                param($Key, $Title)
                Get-ScubaProductDisplayName $Key | Should -Be $Title
            }
            It 'Returns the raw abbreviation for unmapped products' {
                Get-ScubaProductDisplayName 'SomeUnknownProduct' | Should -Be 'SomeUnknownProduct'
            }
        }

        Context 'Get-ScubaOrderedProducts' {
            It 'Orders products by the fixed report order regardless of input order' {
                $ordered = Get-ScubaOrderedProducts @('Teams','SecuritySuite','AAD','SharePoint','PowerPlatform','PowerBI','EXO','Defender')
                $ordered -join ',' | Should -Be 'AAD,Defender,EXO,PowerBI,PowerPlatform,SharePoint,SecuritySuite,Teams'
            }
            It 'Appends unknown products alphabetically after the known ones' {
                $ordered = Get-ScubaOrderedProducts @('Zebra','Teams','AAD','Alpha')
                $ordered -join ',' | Should -Be 'AAD,Teams,Alpha,Zebra'
            }
        }

        Context 'Get-ScubaOrderedControlIds' {
            It 'Orders group numbers numerically, not lexicographically' {
                $ordered = Get-ScubaOrderedControlIds @('MS.EXO.10.1','MS.EXO.1.1','MS.EXO.17.3','MS.EXO.9.5','MS.EXO.2.2')
                $ordered -join ',' | Should -Be 'MS.EXO.1.1,MS.EXO.2.2,MS.EXO.9.5,MS.EXO.10.1,MS.EXO.17.3'
            }
            It 'Orders policy numbers within a group numerically' {
                $ordered = Get-ScubaOrderedControlIds @('MS.AAD.3.10','MS.AAD.3.2','MS.AAD.3.1')
                $ordered -join ',' | Should -Be 'MS.AAD.3.1,MS.AAD.3.2,MS.AAD.3.10'
            }
            It 'Groups IDs by product prefix' {
                $ordered = Get-ScubaOrderedControlIds @('MS.TEAMS.1.1','MS.AAD.10.1','MS.AAD.2.1')
                $ordered -join ',' | Should -Be 'MS.AAD.2.1,MS.AAD.10.1,MS.TEAMS.1.1'
            }
        }

        Context 'Get-ScubaRowColorClass' {
            It 'Greys out removed policies regardless of before result' {
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'RemovedPolicy'; ResultAfter = $null }) | Should -Be 'grey'
            }
            It 'Colors by Result (After): Fail=red, Warning=yellow, Pass=green' {
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'NewFail'; ResultAfter = 'Fail' })       | Should -Be 'red'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'NewWarning'; ResultAfter = 'Warning' }) | Should -Be 'yellow'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'NewPass'; ResultAfter = 'Pass' })       | Should -Be 'green'
            }
            It 'Treats Error as red and manual/omitted/other as grey' {
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'Errored'; ResultAfter = 'Error' })          | Should -Be 'red'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'NewManualCheck'; ResultAfter = 'N/A' })     | Should -Be 'grey'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'NewOmission'; ResultAfter = 'Omitted' })    | Should -Be 'grey'
                Get-ScubaRowColorClass ([pscustomobject]@{ Bucket = 'Other'; ResultAfter = 'Bug' })              | Should -Be 'grey'
            }
        }

        Context 'ConvertTo-ScubaHtmlEncoded' {
            It 'Encodes HTML metacharacters' {
                ConvertTo-ScubaHtmlEncoded '<script>&' | Should -Be '&lt;script&gt;&amp;'
            }
        }

        Context 'Get-ScubaDiffBucket classification' {
            $cases = @(
                @{ B = 'Pass';    A = 'Fail';    Bv = 'v1'; Av = 'v1'; Expected = 'NewFail' }
                @{ B = 'Fail';    A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'NewPass' }
                @{ B = 'Warning'; A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'NewPass' }
                @{ B = 'Warning'; A = 'Fail';    Bv = 'v1'; Av = 'v1'; Expected = 'NewFail' }
                @{ B = 'Pass';    A = 'Warning'; Bv = 'v1'; Av = 'v1'; Expected = 'NewWarning' }
                @{ B = 'Fail';    A = 'Warning'; Bv = 'v1'; Av = 'v1'; Expected = 'NewWarning' }
                @{ B = 'N/A';     A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'NewAutomatedCheck' }
                @{ B = 'N/A';     A = 'Fail';    Bv = 'v1'; Av = 'v1'; Expected = 'NewAutomatedCheck' }
                @{ B = 'N/A';     A = 'Warning'; Bv = 'v1'; Av = 'v1'; Expected = 'NewAutomatedCheck' }
                @{ B = 'Pass';    A = 'N/A';     Bv = 'v1'; Av = 'v1'; Expected = 'NewManualCheck' }
                @{ B = 'Fail';    A = 'N/A';     Bv = 'v1'; Av = 'v1'; Expected = 'NewManualCheck' }
                # An omitted prior result that is evaluated again buckets by the
                # result it lands on, not as an omission change.
                @{ B = 'Omitted'; A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'NewPass' }
                @{ B = 'Omitted'; A = 'Fail';    Bv = 'v1'; Av = 'v1'; Expected = 'NewFail' }
                @{ B = 'Omitted'; A = 'Warning'; Bv = 'v1'; Av = 'v1'; Expected = 'NewWarning' }
                # Omission changes with no landing result stay NewOmission.
                @{ B = 'Pass';    A = 'Omitted'; Bv = 'v1'; Av = 'v1'; Expected = 'NewOmission' }
                @{ B = 'Fail';    A = 'Omitted'; Bv = 'v1'; Av = 'v1'; Expected = 'NewOmission' }
                @{ B = 'Omitted'; A = 'N/A';     Bv = 'v1'; Av = 'v1'; Expected = 'NewOmission' }
                @{ B = 'N/A';     A = 'Omitted'; Bv = 'v1'; Av = 'v1'; Expected = 'NewOmission' }
                @{ B = 'Pass';    A = 'Pass';    Bv = 'v1'; Av = 'v2'; Expected = 'PolicyVersionUpdate' }
                @{ B = 'Pass';    A = 'Error';   Bv = 'v1'; Av = 'v1'; Expected = 'Errored' }
                @{ B = 'Error';   A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'Errored' }
                @{ B = 'Pass';    A = 'Bug';     Bv = 'v1'; Av = 'v1'; Expected = 'Other' }
                @{ B = 'Fail';    A = 'Incorrect result'; Bv = 'v1'; Av = 'v1'; Expected = 'NewIncorrectResult' }
                @{ B = 'Pass';    A = 'Incorrect result'; Bv = 'v1'; Av = 'v1'; Expected = 'NewIncorrectResult' }
                # A cleared incorrect-result marking buckets by the revealed result.
                @{ B = 'Incorrect result'; A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'NewPass' }
                @{ B = 'Incorrect result'; A = 'Fail';    Bv = 'v1'; Av = 'v1'; Expected = 'NewFail' }
                @{ B = 'Incorrect result'; A = 'Warning'; Bv = 'v1'; Av = 'v1'; Expected = 'NewWarning' }
                @{ B = 'Incorrect result'; A = 'N/A';     Bv = 'v1'; Av = 'v1'; Expected = 'NewManualCheck' }
                @{ B = 'Incorrect result'; A = 'Omitted'; Bv = 'v1'; Av = 'v1'; Expected = 'NewOmission' }
                @{ B = 'Incorrect result'; A = 'Incorrect result'; Bv = 'v1'; Av = 'v1'; Expected = 'Unchanged' }
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
                (Get-ScubaDiffBucket -BeforeResult $null -AfterResult 'Pass' -BeforePresent $false -AfterPresent $true -BeforeVersion $null -AfterVersion 'v1') | Should -Be 'NewPolicy'
                (Get-ScubaDiffBucket -BeforeResult 'Pass' -AfterResult $null -BeforePresent $true -AfterPresent $false -BeforeVersion 'v1' -AfterVersion $null) | Should -Be 'RemovedPolicy'
            }
            It 'Prefers Errored over PolicyVersionUpdate (precedence)' {
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
            @{ Base = 'MS.AAD.1.1';  Bucket = 'NewFail' }
            @{ Base = 'MS.AAD.2.1';  Bucket = 'NewPass' }
            @{ Base = 'MS.AAD.3.1';  Bucket = 'NewPass' }
            @{ Base = 'MS.AAD.4.1';  Bucket = 'NewFail' }
            @{ Base = 'MS.AAD.5.1';  Bucket = 'NewWarning' }
            @{ Base = 'MS.AAD.6.1';  Bucket = 'NewAutomatedCheck' }
            @{ Base = 'MS.AAD.7.1';  Bucket = 'NewManualCheck' }
            @{ Base = 'MS.AAD.8.1';  Bucket = 'NewOmission' }
            @{ Base = 'MS.AAD.9.1';  Bucket = 'RemovedPolicy' }
            @{ Base = 'MS.AAD.10.1'; Bucket = 'NewPolicy' }
            @{ Base = 'MS.AAD.11.1'; Bucket = 'Errored' }
            @{ Base = 'MS.AAD.12.1'; Bucket = 'Other' }
            @{ Base = 'MS.AAD.14.1'; Bucket = 'Unchanged' }
        )
        It '<Base> is classified as <Bucket>' -TestCases $expected {
            param($Base, $Bucket)
            $ByBase[$Base].Bucket | Should -Be $Bucket
        }

        It 'Emits records ordered by group and policy number, not lexicographically' {
            $bases = @($DiffA.Diff.AAD | ForEach-Object {
                $id = if ($_.'Control ID (After)') { $_.'Control ID (After)' } else { $_.'Control ID (Before)' }
                Get-ScubaBaseControlId $id
            })
            $bases -join ',' | Should -Be ('MS.AAD.1.1,MS.AAD.2.1,MS.AAD.3.1,MS.AAD.4.1,MS.AAD.5.1,MS.AAD.6.1,' +
                'MS.AAD.7.1,MS.AAD.8.1,MS.AAD.9.1,MS.AAD.10.1,MS.AAD.11.1,MS.AAD.12.1,MS.AAD.13.1,MS.AAD.14.1')
        }

        It 'Preserves both literal Result values for Other' {
            $ByBase['MS.AAD.12.1'].ResultBefore | Should -Be 'Pass'
            $ByBase['MS.AAD.12.1'].ResultAfter  | Should -Be 'Bug'
        }

        It 'Strips embedded HTML from the Requirement field' {
            $ByBase['MS.AAD.1.1'].Requirement | Should -Be 'NewFail control.'
            $ByBase['MS.AAD.1.1'].Requirement | Should -Not -Match 'policy-indicators'
        }

        It 'Omits before-only fields for NewPolicy controls' {
            $ByBase['MS.AAD.10.1'].'Control ID (Before)' | Should -BeNullOrEmpty
            $ByBase['MS.AAD.10.1'].ResultBefore | Should -BeNullOrEmpty
        }

        It 'Omits after-only fields for RemovedPolicy controls' {
            $ByBase['MS.AAD.9.1'].'Control ID (After)' | Should -BeNullOrEmpty
            $ByBase['MS.AAD.9.1'].ResultAfter | Should -BeNullOrEmpty
        }

        It 'Reports every taxonomy bucket in the Summary' {
            foreach ($e in @('NewFail','NewPass','NewWarning','NewAutomatedCheck','NewManualCheck','NewOmission','RemovedPolicy','NewPolicy','Errored','Other','Unchanged')) {
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

    Describe -Tag 'Diff' -Name 'Fixture pair B: products present in only one file (standalone)' {
        BeforeAll {
            $script:FixtureDir = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $Before = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairB-Before.json')
            $After = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairB-After.json')
            $script:DiffB = Compare-ScubaResults -Before $Before -After $After -ToolVersion '9.9.9'
        }
        It 'Treats Defender and SecuritySuite as separate standalone products' {
            @($DiffB.Diff.Keys) | Should -Contain 'Defender'
            @($DiffB.Diff.Keys) | Should -Contain 'SecuritySuite'
        }
        It 'Reports every before-only (Defender) control as RemovedPolicy' {
            $DiffB.MetaData.ProductsOnlyInBefore | Should -Contain 'Defender'
            foreach ($rec in $DiffB.Diff.Defender) {
                $rec.Bucket | Should -Be 'RemovedPolicy'
            }
        }
        It 'Reports every after-only (SecuritySuite) control as NewPolicy' {
            $DiffB.MetaData.ProductsOnlyInAfter | Should -Contain 'SecuritySuite'
            foreach ($rec in $DiffB.Diff.SecuritySuite) {
                $rec.Bucket | Should -Be 'NewPolicy'
            }
        }
        It 'Never emits a ProductRenamed field' {
            foreach ($product in @($DiffB.Diff.Keys)) {
                foreach ($rec in $DiffB.Diff.$product) {
                    $rec.PSObject.Properties['ProductRenamed'] | Should -BeNullOrEmpty
                }
            }
        }
        It 'Strips embedded HTML from the Requirement field' {
            $rec = $DiffB.Diff.SecuritySuite | Where-Object { (Get-ScubaBaseControlId $_.'Control ID (After)') -eq 'MS.SECURITYSUITE.3.1' }
            $rec.Requirement | Should -Be 'Configure A & B properly.'
        }
    }

    Describe -Tag 'Diff' -Name 'Version drift within a product' {
        It 'Classifies a base ID at v1 vs v2 as PolicyVersionUpdate (never NewPolicy/RemovedPolicy)' {
            function New-VerResults {
                param($FullId)
                $obj = @{
                    MetaData = @{ ReportUUID = 'x'; TimestampZulu = 't'; ToolVersion = '1' }
                    Summary = @{ Teams = @{} }
                    AnnotatedFailedPolicies = @{}
                    Results = @{ Teams = @( @{ GroupName = 'G'; GroupNumber = '1'; Controls = @(
                        @{ 'Control ID' = $FullId; Requirement = 'R'; Result = 'Pass'; OriginalResult = 'Pass'; Criticality = 'Shall'; Details = 'd' }
                    ) } ) }
                }
                return $obj | ConvertTo-Json -Depth 10 | ConvertFrom-Json
            }
            $diff = Compare-ScubaResults -Before (New-VerResults 'MS.TEAMS.1.2v1') -After (New-VerResults 'MS.TEAMS.1.2v2')
            $rec = $diff.Diff.Teams[0]
            $rec.Bucket | Should -Be 'PolicyVersionUpdate'
            $rec.'Control ID (Before)' | Should -Be 'MS.TEAMS.1.2v1'
            $rec.'Control ID (After)'  | Should -Be 'MS.TEAMS.1.2v2'
        }
    }

    Describe -Tag 'Diff' -Name 'False-positive (marked incorrect) handling' {
        BeforeAll {
            function New-FpResults {
                param($Result, $OriginalResult)
                $obj = @{
                    MetaData = @{ ReportUUID = 'x'; TimestampZulu = 't'; ToolVersion = '1' }
                    Summary = @{ AAD = @{} }
                    AnnotatedFailedPolicies = @{}
                    Results = @{ AAD = @( @{ GroupName = 'G'; GroupNumber = '1'; Controls = @(
                        @{ 'Control ID' = 'MS.AAD.1.1v1'; Requirement = 'R'; Result = $Result; OriginalResult = $OriginalResult; Criticality = 'Shall'; Details = 'd' }
                    ) } ) }
                }
                return $obj | ConvertTo-Json -Depth 10 | ConvertFrom-Json
            }
        }

        It 'Buckets a newly marked false positive as NewIncorrectResult and records the underlying result' {
            $diff = Compare-ScubaResults -Before (New-FpResults 'Fail' 'Fail') -After (New-FpResults 'Incorrect result' 'Fail')
            $rec = $diff.Diff.AAD[0]
            $rec.Bucket | Should -Be 'NewIncorrectResult'
            $rec.MarkedIncorrectBefore | Should -BeFalse
            $rec.MarkedIncorrectAfter | Should -BeTrue
            $rec.UnderlyingResultAfter | Should -Be 'Fail'
        }

        It 'Buckets a removed false positive by the result it reveals' {
            $diff = Compare-ScubaResults -Before (New-FpResults 'Incorrect result' 'Fail') -After (New-FpResults 'Pass' 'Pass')
            $rec = $diff.Diff.AAD[0]
            $rec.Bucket | Should -Be 'NewPass'
            $rec.UnderlyingResultBefore | Should -Be 'Fail'
            $rec.UnderlyingResultAfter | Should -Be 'Pass'

            $failDiff = Compare-ScubaResults -Before (New-FpResults 'Incorrect result' 'Fail') -After (New-FpResults 'Fail' 'Fail')
            $failDiff.Diff.AAD[0].Bucket | Should -Be 'NewFail'
        }

        It 'Treats a stable false-positive marking as Unchanged' {
            $diff = Compare-ScubaResults -Before (New-FpResults 'Incorrect result' 'Fail') -After (New-FpResults 'Incorrect result' 'Fail')
            $diff.Diff.AAD[0].Bucket | Should -Be 'Unchanged'
        }

        It 'Surfaces the underlying result and transition label in the HTML' {
            $diff = Compare-ScubaResults -Before (New-FpResults 'Fail' 'Fail') -After (New-FpResults 'Incorrect result' 'Fail')
            $html = New-ScubaDiffReport -DiffResults $diff
            $html | Should -Match 'New Incorrect Result \(false positive\)'
            $html | Should -Match 'underlying: Fail'
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
            # MS.AAD.1.1 is Pass->Fail (NewFail), so its row must be red, not
            # colored by the transition bucket.
            $Html | Should -Match 'MS.AAD.1.1v1[\s\S]*?New Fail'
            $Html | Should -Match 'class="diff-row diff-red"'
        }
        It 'Greys out removed-policy rows like manual checks' {
            $Html | Should -Match 'class="diff-row diff-grey[^"]*"'
        }
        It 'Marks unchanged rows with the hide-by-default class' {
            $Html | Should -Match 'diff-unchanged-row'
        }
        It 'Displays the RemovedPolicy bucket as "Removed Policy"' {
            $Html | Should -Match 'Removed Policy'
        }
        It 'Uses the friendly product title for the AAD heading' {
            $Html | Should -Match '<h2>Microsoft Entra ID / Azure Active Directory</h2>'
        }
        It 'Renders product sections in the fixed report order' {
            # Build a diff whose products are supplied in a scrambled order.
            function New-MultiProductSide {
                $products = [ordered]@{}
                foreach ($p in @('Teams','AAD','EXO')) {
                    $products[$p] = @( @{ GroupName = 'G'; GroupNumber = '1'; Controls = @(
                        @{ 'Control ID' = "MS.$p.1.1v1"; Requirement = 'R'; Result = 'Pass'; Criticality = 'Shall'; Details = 'd' }
                    ) } )
                }
                $obj = @{
                    MetaData = @{ ReportUUID = 'x'; TimestampZulu = 't'; ToolVersion = '1' }
                    Summary = @{}
                    AnnotatedFailedPolicies = @{}
                    Results = $products
                }
                return $obj | ConvertTo-Json -Depth 10 | ConvertFrom-Json
            }
            $diff = Compare-ScubaResults -Before (New-MultiProductSide) -After (New-MultiProductSide)
            $multiHtml = New-ScubaDiffReport -DiffResults $diff
            $order = [regex]::Matches($multiHtml, '<h2>([^<]+)</h2>') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -ne 'Summary' }
            ($order -join ',') | Should -Be 'Microsoft Entra ID / Azure Active Directory,Exchange Online,Microsoft Teams'
        }
        It 'HTML-escapes user content and never emits the raw indicator markup' {
            $HtmlB | Should -Match 'Configure A &amp; B properly'
            $HtmlB | Should -Not -Match "policy-indicators"
        }
    }
}

AfterAll {
    Remove-Module Diff -ErrorAction SilentlyContinue
}
