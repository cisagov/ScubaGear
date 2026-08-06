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

        Context 'Get-ScubaClassificationLabel' {
            It 'Displays RemovedPolicy as "Removed Policy"' {
                Get-ScubaClassificationLabel 'RemovedPolicy' | Should -Be 'Removed Policy'
            }
            It 'Returns the raw token for classifications without a friendly label' {
                Get-ScubaClassificationLabel 'Errored' | Should -Be 'Errored'
            }
            It 'Gives the result-diff classifications friendly labels' {
                Get-ScubaClassificationLabel 'NewFail'             | Should -Be 'New Fail'
                Get-ScubaClassificationLabel 'NewPass'             | Should -Be 'New Pass'
                Get-ScubaClassificationLabel 'PolicyVersionUpdate' | Should -Be 'Policy Version Update'
                Get-ScubaClassificationLabel 'NewIncorrectResult'  | Should -Be 'New Incorrect Result (false positive)'
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
                Get-ScubaRowColorClass ([pscustomobject]@{ Classification = 'RemovedPolicy'; ResultAfter = $null }) | Should -Be 'grey'
            }
            It 'Colors by Result (After): Fail=red, Warning=yellow, Pass=green' {
                Get-ScubaRowColorClass ([pscustomobject]@{ Classification = 'NewFail'; ResultAfter = 'Fail' })       | Should -Be 'red'
                Get-ScubaRowColorClass ([pscustomobject]@{ Classification = 'NewWarning'; ResultAfter = 'Warning' }) | Should -Be 'yellow'
                Get-ScubaRowColorClass ([pscustomobject]@{ Classification = 'NewPass'; ResultAfter = 'Pass' })       | Should -Be 'green'
            }
            It 'Treats Error as red and manual/omitted/other as grey' {
                Get-ScubaRowColorClass ([pscustomobject]@{ Classification = 'Errored'; ResultAfter = 'Error' })          | Should -Be 'red'
                Get-ScubaRowColorClass ([pscustomobject]@{ Classification = 'NewManualCheck'; ResultAfter = 'N/A' })     | Should -Be 'grey'
                Get-ScubaRowColorClass ([pscustomobject]@{ Classification = 'NewOmission'; ResultAfter = 'Omitted' })    | Should -Be 'grey'
                Get-ScubaRowColorClass ([pscustomobject]@{ Classification = 'Other'; ResultAfter = 'Bug' })              | Should -Be 'grey'
            }
        }

        Context 'ConvertTo-ScubaHtmlEncoded' {
            It 'Encodes HTML metacharacters' {
                ConvertTo-ScubaHtmlEncoded '<script>&' | Should -Be '&lt;script&gt;&amp;'
            }
        }

        Context 'Get-ScubaDiffClassification classification' {
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
                # An omitted prior result that is evaluated again classifications by the
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
                # Errored keys off the after state only.
                @{ B = 'Pass';    A = 'Error';   Bv = 'v1'; Av = 'v1'; Expected = 'Errored' }
                @{ B = 'Fail';    A = 'Error';   Bv = 'v1'; Av = 'v1'; Expected = 'Errored' }
                @{ B = 'Error';   A = 'Error';   Bv = 'v1'; Av = 'v1'; Expected = 'Errored' }
                # A control that recovered from a prior error classifications by the state
                # it lands on, not as Errored.
                @{ B = 'Error';   A = 'Pass';    Bv = 'v1'; Av = 'v1'; Expected = 'NewPass' }
                @{ B = 'Error';   A = 'Fail';    Bv = 'v1'; Av = 'v1'; Expected = 'NewFail' }
                @{ B = 'Error';   A = 'Warning'; Bv = 'v1'; Av = 'v1'; Expected = 'NewWarning' }
                @{ B = 'Error';   A = 'N/A';     Bv = 'v1'; Av = 'v1'; Expected = 'NewManualCheck' }
                @{ B = 'Error';   A = 'Omitted'; Bv = 'v1'; Av = 'v1'; Expected = 'NewOmission' }
                @{ B = 'Pass';    A = 'Bug';     Bv = 'v1'; Av = 'v1'; Expected = 'Other' }
                @{ B = 'Fail';    A = 'Incorrect result'; Bv = 'v1'; Av = 'v1'; Expected = 'NewIncorrectResult' }
                @{ B = 'Pass';    A = 'Incorrect result'; Bv = 'v1'; Av = 'v1'; Expected = 'NewIncorrectResult' }
                # A cleared incorrect-result marking classifications by the revealed result.
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
                $classification = Get-ScubaDiffClassification -BeforeResult $B -AfterResult $A `
                    -BeforePresent $true -AfterPresent $true -BeforeVersion $Bv -AfterVersion $Av
                $classification | Should -Be $Expected
            }
            It 'Classifies presence-only cases' {
                (Get-ScubaDiffClassification -BeforeResult $null -AfterResult 'Pass' -BeforePresent $false -AfterPresent $true -BeforeVersion $null -AfterVersion 'v1') | Should -Be 'NewPolicy'
                (Get-ScubaDiffClassification -BeforeResult 'Pass' -AfterResult $null -BeforePresent $true -AfterPresent $false -BeforeVersion 'v1' -AfterVersion $null) | Should -Be 'RemovedPolicy'
            }
            It 'Prefers Errored (after-side) over PolicyVersionUpdate (precedence)' {
                (Get-ScubaDiffClassification -BeforeResult 'Pass' -AfterResult 'Error' -BeforePresent $true -AfterPresent $true -BeforeVersion 'v1' -AfterVersion 'v2') | Should -Be 'Errored'
            }
            It 'A recovery from a prior error under a version bump is a PolicyVersionUpdate' {
                (Get-ScubaDiffClassification -BeforeResult 'Error' -AfterResult 'Pass' -BeforePresent $true -AfterPresent $true -BeforeVersion 'v1' -AfterVersion 'v2') | Should -Be 'PolicyVersionUpdate'
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
            @{ Base = 'MS.AAD.1.1';  Classification = 'NewFail' }
            @{ Base = 'MS.AAD.2.1';  Classification = 'NewPass' }
            @{ Base = 'MS.AAD.3.1';  Classification = 'NewPass' }
            @{ Base = 'MS.AAD.4.1';  Classification = 'NewFail' }
            @{ Base = 'MS.AAD.5.1';  Classification = 'NewWarning' }
            @{ Base = 'MS.AAD.6.1';  Classification = 'NewAutomatedCheck' }
            @{ Base = 'MS.AAD.7.1';  Classification = 'NewManualCheck' }
            @{ Base = 'MS.AAD.8.1';  Classification = 'NewOmission' }
            @{ Base = 'MS.AAD.9.1';  Classification = 'RemovedPolicy' }
            @{ Base = 'MS.AAD.10.1'; Classification = 'NewPolicy' }
            @{ Base = 'MS.AAD.11.1'; Classification = 'Errored' }
            @{ Base = 'MS.AAD.12.1'; Classification = 'Other' }
            @{ Base = 'MS.AAD.14.1'; Classification = 'Unchanged' }
        )
        It '<Base> is classified as <Classification>' -TestCases $expected {
            param($Base, $Classification)
            $ByBase[$Base].Classification | Should -Be $Classification
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

        It 'Reports every taxonomy classification in the Summary' {
            foreach ($e in @('NewFail','NewPass','NewWarning','NewAutomatedCheck','NewManualCheck','NewOmission','RemovedPolicy','NewPolicy','Errored','Other','Unchanged')) {
                $DiffA.Summary.AAD.Contains($e) | Should -BeTrue -Because "classification $e should appear in the summary"
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
                $rec.Classification | Should -Be 'RemovedPolicy'
            }
        }
        It 'Reports every after-only (SecuritySuite) control as NewPolicy' {
            $DiffB.MetaData.ProductsOnlyInAfter | Should -Contain 'SecuritySuite'
            foreach ($rec in $DiffB.Diff.SecuritySuite) {
                $rec.Classification | Should -Be 'NewPolicy'
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
            $rec = $DiffB.Diff.SecuritySuite | Where-Object { (Get-ScubaBaseControlId $_.'Control ID (After)') -eq 'MS.SECURITYSUITE.1.3' }
            $rec.Requirement | Should -Be 'Configure A & B properly.'
        }
        It 'Leaves the split MS.DEFENDER.1.x policies unmigrated' {
            # MS.DEFENDER.1.1v1 - 1.5v1 are excluded from the migration map because
            # each was split across several Security Suite policies.
            foreach ($rec in $DiffB.Diff.Defender) {
                $rec.PSObject.Properties['Migrated'] | Should -BeNullOrEmpty
            }
        }
    }

    Describe -Tag 'Diff' -Name 'Fixture pair C: legacy to Security Suite migration' {
        BeforeAll {
            $script:FixtureDir = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $Before = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairC-Before.json')
            $After = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairC-After.json')
            $script:DiffC = Compare-ScubaResults -Before $Before -After $After -ToolVersion '9.9.9'
            $script:GetC = {
                param($BaseId)
                foreach ($product in @($DiffC.Diff.Keys)) {
                    $hit = $DiffC.Diff.$product | Where-Object {
                        (Get-ScubaBaseControlId $_.'Control ID (After)') -eq $BaseId -or
                        (Get-ScubaBaseControlId $_.'Control ID (Before)') -eq $BaseId
                    }
                    if ($hit) { return $hit }
                }
                return $null
            }
        }

        It 'Files a migrated pair under the Security Suite product, not Defender' {
            $rec = & $GetC 'MS.SECURITYSUITE.2.1'
            $rec | Should -Not -BeNullOrEmpty
            @($DiffC.Diff.SecuritySuite | Where-Object { $_.'Control ID (After)' -eq 'MS.SECURITYSUITE.2.1v1' }).Count | Should -Be 1
            @($DiffC.Diff.Defender | Where-Object { $_.'Control ID (Before)' -eq 'MS.DEFENDER.2.1v1' }).Count | Should -Be 0
        }

        It 'Keeps both real IDs on the record' {
            $rec = & $GetC 'MS.SECURITYSUITE.2.1'
            $rec.'Control ID (Before)' | Should -Be 'MS.DEFENDER.2.1v1'
            $rec.'Control ID (After)' | Should -Be 'MS.SECURITYSUITE.2.1v1'
        }

        It 'Classifies a migrated pair by its result, like any other pair' {
            (& $GetC 'MS.SECURITYSUITE.2.1').Classification | Should -Be 'NewFail'   # Pass -> Fail
            (& $GetC 'MS.SECURITYSUITE.1.4').Classification | Should -Be 'Unchanged' # Pass -> Pass
        }

        It 'Does not classify a migrated pair as PolicyVersionUpdate when the version suffixes differ' {
            # MS.DEFENDER.4.1v2 -> MS.SECURITYSUITE.3.1v1: different families, so the
            # suffixes are not comparable and the result diff must win.
            $rec = & $GetC 'MS.SECURITYSUITE.3.1'
            $rec.'Control ID (Before)' | Should -Be 'MS.DEFENDER.4.1v2'
            $rec.Classification | Should -Be 'NewPass'
        }

        It 'Marks migrated records with the migration fields' {
            $rec = & $GetC 'MS.SECURITYSUITE.3.1'
            $rec.Migrated | Should -BeTrue
            $rec.MigratedFromId | Should -Be 'MS.DEFENDER.4.1v2'
            $rec.MigratedFromProduct | Should -Be 'Defender'
        }

        It 'Omits the migration fields from records that were not migrated' {
            (& $GetC 'MS.SECURITYSUITE.6.1').PSObject.Properties['Migrated'] | Should -BeNullOrEmpty
            (& $GetC 'MS.DEFENDER.6.2').PSObject.Properties['Migrated'] | Should -BeNullOrEmpty
        }

        It 'Takes the Requirement, Group, and Details from the Security Suite side' {
            $rec = & $GetC 'MS.SECURITYSUITE.1.4'
            $rec.GroupNumber | Should -Be '1'
            $rec.GroupName | Should -Be 'Threat Protection'
            $rec.DetailsAfter | Should -Be 'Passing after.'
        }

        It 'Reports a split MS.DEFENDER.1.x policy as RemovedPolicy under Defender' {
            $rec = & $GetC 'MS.DEFENDER.1.1'
            $rec.Classification | Should -Be 'RemovedPolicy'
            $rec.PSObject.Properties['Migrated'] | Should -BeNullOrEmpty
        }

        It 'Reports a retired policy (New ID "None") as RemovedPolicy' {
            (& $GetC 'MS.DEFENDER.4.5').Classification | Should -Be 'RemovedPolicy'
        }

        It 'Reports a Security Suite policy with no Defender source as NewPolicy' {
            (& $GetC 'MS.SECURITYSUITE.6.1').Classification | Should -Be 'NewPolicy'
        }

        It 'Still compares a surviving Defender policy normally' {
            (& $GetC 'MS.DEFENDER.6.2').Classification | Should -Be 'Unchanged'
        }

        It 'Counts a migrated record under the Security Suite product summary' {
            $DiffC.Summary.SecuritySuite['NewFail'] | Should -Be 1
            $DiffC.Summary.SecuritySuite['NewPass'] | Should -Be 1
            $DiffC.Summary.SecuritySuite['NewPolicy'] | Should -Be 1
            $DiffC.Summary.Defender['NewFail'] | Should -BeNullOrEmpty
        }
    }

    Describe -Tag 'Diff' -Name 'Policy migration alignment rules' {
        BeforeAll {
            $script:NewSide = {
                param($Product, $Controls)
                # $Controls: array of @{ Id = ...; Result = ... }
                $list = @($Controls | ForEach-Object {
                    [pscustomobject]@{
                        'Control ID'   = $_.Id
                        'Requirement'  = 'Requirement text.'
                        'Result'       = $_.Result
                        'OriginalResult' = $_.Result
                        'Criticality'  = 'Shall'
                        'Details'      = 'Details text.'
                    }
                })
                $results = [pscustomobject]@{}
                $results | Add-Member -NotePropertyName $Product -NotePropertyValue @(
                    [pscustomobject]@{ GroupName = 'Group'; GroupNumber = '1'; Controls = $list }
                )
                return [pscustomobject]@{
                    MetaData = [pscustomobject]@{ ReportUUID = 'x'; TimestampZulu = 'y'; ToolVersion = 'z' }
                    Summary  = [pscustomobject]@{}
                    Results  = $results
                }
            }
        }

        It 'Matches on base ID, so an older version of the retired policy still aligns' {
            # The migration table pins MS.DEFENDER.4.1v2; a before file carrying v1
            # must still align to MS.SECURITYSUITE.3.1v1.
            $b = & $NewSide 'Defender' @(@{ Id = 'MS.DEFENDER.4.1v1'; Result = 'Fail' })
            $a = & $NewSide 'SecuritySuite' @(@{ Id = 'MS.SECURITYSUITE.3.1v1'; Result = 'Pass' })
            $diff = Compare-ScubaResults -Before $b -After $a
            $rec = $diff.Diff.SecuritySuite[0]
            $rec.Migrated | Should -BeTrue
            $rec.MigratedFromId | Should -Be 'MS.DEFENDER.4.1v1'
            $rec.Classification | Should -Be 'NewPass'
        }

        It 'Does not align when the after run has no replacement policy' {
            $b = & $NewSide 'Defender' @(@{ Id = 'MS.DEFENDER.2.1v1'; Result = 'Fail' })
            $a = & $NewSide 'SecuritySuite' @(@{ Id = 'MS.SECURITYSUITE.9.9v1'; Result = 'Pass' })
            $diff = Compare-ScubaResults -Before $b -After $a
            $diff.Diff.Defender[0].Classification | Should -Be 'RemovedPolicy'
            $diff.Diff.Defender[0].PSObject.Properties['Migrated'] | Should -BeNullOrEmpty
        }

        It 'Prefers a direct match when the after run still carries the retired Defender policy' {
            $b = & $NewSide 'Defender' @(@{ Id = 'MS.DEFENDER.2.1v1'; Result = 'Fail' })
            $a = [pscustomobject]@{
                MetaData = [pscustomobject]@{ ReportUUID = 'x'; TimestampZulu = 'y'; ToolVersion = 'z' }
                Summary  = [pscustomobject]@{}
                Results  = [pscustomobject]@{
                    Defender      = @([pscustomobject]@{ GroupName = 'G'; GroupNumber = '1'; Controls = @(
                        [pscustomobject]@{ 'Control ID' = 'MS.DEFENDER.2.1v1'; Requirement = 'r'; Result = 'Pass'; OriginalResult = 'Pass'; Criticality = 'Shall'; Details = 'd' }) })
                    SecuritySuite = @([pscustomobject]@{ GroupName = 'G'; GroupNumber = '1'; Controls = @(
                        [pscustomobject]@{ 'Control ID' = 'MS.SECURITYSUITE.2.1v1'; Requirement = 'r'; Result = 'Fail'; OriginalResult = 'Fail'; Criticality = 'Shall'; Details = 'd' }) })
                }
            }
            $diff = Compare-ScubaResults -Before $b -After $a
            $diff.Diff.Defender[0].Classification | Should -Be 'NewPass'
            $diff.Diff.Defender[0].PSObject.Properties['Migrated'] | Should -BeNullOrEmpty
            $diff.Diff.SecuritySuite[0].Classification | Should -Be 'NewPolicy'
        }

        It 'Prefers a direct match when both runs are already post-migration' {
            $b = & $NewSide 'SecuritySuite' @(@{ Id = 'MS.SECURITYSUITE.2.1v1'; Result = 'Fail' })
            $a = & $NewSide 'SecuritySuite' @(@{ Id = 'MS.SECURITYSUITE.2.1v1'; Result = 'Pass' })
            $diff = Compare-ScubaResults -Before $b -After $a
            $diff.Diff.SecuritySuite[0].Classification | Should -Be 'NewPass'
            $diff.Diff.SecuritySuite[0].PSObject.Properties['Migrated'] | Should -BeNullOrEmpty
        }

        It 'Does not align in reverse (Security Suite before, Defender after)' {
            $b = & $NewSide 'SecuritySuite' @(@{ Id = 'MS.SECURITYSUITE.2.1v1'; Result = 'Pass' })
            $a = & $NewSide 'Defender' @(@{ Id = 'MS.DEFENDER.2.1v1'; Result = 'Fail' })
            $diff = Compare-ScubaResults -Before $b -After $a
            $diff.Diff.SecuritySuite[0].Classification | Should -Be 'RemovedPolicy'
            $diff.Diff.Defender[0].Classification | Should -Be 'NewPolicy'
        }

        It 'Drops a product left with no records once every policy migrated out' {
            $b = & $NewSide 'Defender' @(@{ Id = 'MS.DEFENDER.2.1v1'; Result = 'Pass' })
            $a = & $NewSide 'SecuritySuite' @(@{ Id = 'MS.SECURITYSUITE.2.1v1'; Result = 'Pass' })
            $diff = Compare-ScubaResults -Before $b -After $a
            @($diff.Diff.Keys) | Should -Not -Contain 'Defender'
            @($diff.Diff.Keys) | Should -Contain 'SecuritySuite'
        }

        It 'Aligns a retired EXO policy with its Security Suite replacement' {
            $b = & $NewSide 'EXO' @(@{ Id = 'MS.EXO.15.1v1'; Result = 'Fail' })
            $a = & $NewSide 'SecuritySuite' @(@{ Id = 'MS.SECURITYSUITE.7.1v1'; Result = 'Pass' })
            $diff = Compare-ScubaResults -Before $b -After $a
            $rec = $diff.Diff.SecuritySuite[0]
            $rec.Migrated | Should -BeTrue
            $rec.MigratedFromId | Should -Be 'MS.EXO.15.1v1'
            $rec.MigratedFromProduct | Should -Be 'EXO'
            $rec.'Control ID (After)' | Should -Be 'MS.SECURITYSUITE.7.1v1'
            $rec.Classification | Should -Be 'NewPass'
        }

        It 'Aligns Defender and EXO sources in the same run' {
            $b = [pscustomobject]@{
                MetaData = [pscustomobject]@{ ReportUUID = 'x'; TimestampZulu = 'y'; ToolVersion = 'z' }
                Summary  = [pscustomobject]@{}
                Results  = [pscustomobject]@{
                    Defender = @([pscustomobject]@{ GroupName = 'G'; GroupNumber = '1'; Controls = @(
                        [pscustomobject]@{ 'Control ID' = 'MS.DEFENDER.2.1v1'; Requirement = 'r'; Result = 'Pass'; OriginalResult = 'Pass'; Criticality = 'Should'; Details = 'd' }) })
                    EXO      = @([pscustomobject]@{ GroupName = 'G'; GroupNumber = '1'; Controls = @(
                        [pscustomobject]@{ 'Control ID' = 'MS.EXO.12.1v1'; Requirement = 'r'; Result = 'Pass'; OriginalResult = 'Pass'; Criticality = 'Should'; Details = 'd' }) })
                }
            }
            $a = & $NewSide 'SecuritySuite' @(
                @{ Id = 'MS.SECURITYSUITE.2.1v1'; Result = 'Fail' },
                @{ Id = 'MS.SECURITYSUITE.8.1v1'; Result = 'Fail' }
            )
            $diff = Compare-ScubaResults -Before $b -After $a
            @($diff.Diff.Keys) | Should -Not -Contain 'Defender'
            @($diff.Diff.Keys) | Should -Not -Contain 'EXO'
            $fromDefender = $diff.Diff.SecuritySuite | Where-Object { $_.'Control ID (After)' -eq 'MS.SECURITYSUITE.2.1v1' }
            $fromDefender.MigratedFromProduct | Should -Be 'Defender'
            $fromExo = $diff.Diff.SecuritySuite | Where-Object { $_.'Control ID (After)' -eq 'MS.SECURITYSUITE.8.1v1' }
            $fromExo.MigratedFromProduct | Should -Be 'EXO'
            $fromExo.MigratedFromId | Should -Be 'MS.EXO.12.1v1'
            $diff.Summary.SecuritySuite['NewFail'] | Should -Be 2
        }

        It 'Migrates MS.EXO.14.2v1 onto MS.SECURITYSUITE.6.1 and leaves MS.EXO.14.1v2 removed' {
            # Both CSV rows point at MS.SECURITYSUITE.6.1v1; only 14.2 is in the table.
            $b = & $NewSide 'EXO' @(
                @{ Id = 'MS.EXO.14.1v2'; Result = 'Pass' },
                @{ Id = 'MS.EXO.14.2v1'; Result = 'Pass' }
            )
            $a = & $NewSide 'SecuritySuite' @(@{ Id = 'MS.SECURITYSUITE.6.1v1'; Result = 'Fail' })
            $diff = Compare-ScubaResults -Before $b -After $a
            @($diff.Diff.EXO).Count | Should -Be 1
            $diff.Diff.EXO[0].'Control ID (Before)' | Should -Be 'MS.EXO.14.1v2'
            $diff.Diff.EXO[0].Classification | Should -Be 'RemovedPolicy'
            $ss = $diff.Diff.SecuritySuite[0]
            $ss.MigratedFromId | Should -Be 'MS.EXO.14.2v1'
            $ss.Classification | Should -Be 'NewFail'
        }

        It 'Does not align in reverse (Security Suite before, EXO after)' {
            $b = & $NewSide 'SecuritySuite' @(@{ Id = 'MS.SECURITYSUITE.8.1v1'; Result = 'Pass' })
            $a = & $NewSide 'EXO' @(@{ Id = 'MS.EXO.12.1v1'; Result = 'Fail' })
            $diff = Compare-ScubaResults -Before $b -After $a
            $diff.Diff.SecuritySuite[0].Classification | Should -Be 'RemovedPolicy'
            $diff.Diff.EXO[0].Classification | Should -Be 'NewPolicy'
        }

        It 'Maps every legacy policy to a Security Suite policy one-to-one' {
            $sources = @()
            $targets = @()
            foreach ($product in @($script:PolicyMigrationMap.Keys)) {
                $entries = $script:PolicyMigrationMap[$product]
                $sources += @($entries.Keys)
                $targets += @($entries.Values)
            }
            ($sources | Select-Object -Unique).Count | Should -Be $sources.Count
            ($targets | Select-Object -Unique).Count | Should -Be $targets.Count
            $script:PolicyMigrationMap['Defender'].Count | Should -Be 13
            $script:PolicyMigrationMap['EXO'].Count | Should -Be 7
        }

        It 'Excludes the split and retired Defender policies from the migration map' {
            foreach ($excluded in @('MS.DEFENDER.1.1','MS.DEFENDER.1.2','MS.DEFENDER.1.3','MS.DEFENDER.1.4','MS.DEFENDER.1.5','MS.DEFENDER.4.5')) {
                $script:PolicyMigrationMap['Defender'].Contains($excluded) | Should -BeFalse
            }
        }

        It 'Carries only the EXO 12, 14, and 15 groups, with MS.EXO.14.1 excluded' {
            $script:PolicyMigrationMap['EXO'].Contains('MS.EXO.14.1') | Should -BeFalse
            $script:PolicyMigrationMap['EXO']['MS.EXO.14.2'] | Should -Be 'MS.SECURITYSUITE.6.1'
            foreach ($key in @($script:PolicyMigrationMap['EXO'].Keys)) {
                $key | Should -Match '^MS\.EXO\.(12|14|15)\.\d+$'
            }
        }

        It 'Sources only from Defender and EXO, keying each entry under its own product' {
            @($script:PolicyMigrationMap.Keys).Count | Should -Be 2
            foreach ($product in @('Defender','EXO')) {
                $script:PolicyMigrationMap.Contains($product) | Should -BeTrue
                foreach ($key in @($script:PolicyMigrationMap[$product].Keys)) {
                    $key | Should -BeLike "MS.$($product.ToUpper()).*"
                }
                foreach ($value in @($script:PolicyMigrationMap[$product].Values)) {
                    $value | Should -BeLike 'MS.SECURITYSUITE.*'
                }
            }
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
            $rec.Classification | Should -Be 'PolicyVersionUpdate'
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

        It 'Classifications a newly marked false positive as NewIncorrectResult and records the underlying result' {
            $diff = Compare-ScubaResults -Before (New-FpResults 'Fail' 'Fail') -After (New-FpResults 'Incorrect result' 'Fail')
            $rec = $diff.Diff.AAD[0]
            $rec.Classification | Should -Be 'NewIncorrectResult'
            $rec.MarkedIncorrectBefore | Should -BeFalse
            $rec.MarkedIncorrectAfter | Should -BeTrue
            $rec.UnderlyingResultAfter | Should -Be 'Fail'
        }

        It 'Classifications a removed false positive by the result it reveals' {
            $diff = Compare-ScubaResults -Before (New-FpResults 'Incorrect result' 'Fail') -After (New-FpResults 'Pass' 'Pass')
            $rec = $diff.Diff.AAD[0]
            $rec.Classification | Should -Be 'NewPass'
            $rec.UnderlyingResultBefore | Should -Be 'Fail'
            $rec.UnderlyingResultAfter | Should -Be 'Pass'

            $failDiff = Compare-ScubaResults -Before (New-FpResults 'Incorrect result' 'Fail') -After (New-FpResults 'Fail' 'Fail')
            $failDiff.Diff.AAD[0].Classification | Should -Be 'NewFail'
        }

        It 'Treats a stable false-positive marking as Unchanged' {
            $diff = Compare-ScubaResults -Before (New-FpResults 'Incorrect result' 'Fail') -After (New-FpResults 'Incorrect result' 'Fail')
            $diff.Diff.AAD[0].Classification | Should -Be 'Unchanged'
        }

        It 'Surfaces the underlying result and diff label in the HTML' {
            $diff = Compare-ScubaResults -Before (New-FpResults 'Fail' 'Fail') -After (New-FpResults 'Incorrect result' 'Fail')
            $html = New-ScubaDiffReport -DiffResults $diff
            $html | Should -Match 'New Incorrect Result \(false positive\)'
            $html | Should -Match 'underlying: Fail'
        }
    }

    Describe -Tag 'Diff' -Name 'Invoke-SCuBADiff artifacts' {
        BeforeAll {
            $script:FixtureDir = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $script:OutDir = Join-Path ([System.IO.Path]::GetTempPath()) ("scuba-diff-out-" + [guid]::NewGuid())
            $script:Result = Invoke-SCuBADiff `
                -BeforePath (Join-Path $FixtureDir 'PairA-Before.json') `
                -AfterPath (Join-Path $FixtureDir 'PairA-After.json') `
                -OutPath $OutDir
        }
        AfterAll {
            Remove-Item -LiteralPath $script:OutDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Writes all three artifacts and returns their paths' {
            Test-Path -LiteralPath $Result.JsonPath   | Should -BeTrue
            Test-Path -LiteralPath $Result.CsvPath    | Should -BeTrue
            Test-Path -LiteralPath $Result.ReportPath | Should -BeTrue
        }

        It 'Names the CSV DiffResults.csv by default' {
            Split-Path -Leaf $Result.CsvPath | Should -Be 'DiffResults.csv'
        }

        It 'Honors -OutCsvFileName' {
            $custom = Invoke-SCuBADiff `
                -BeforePath (Join-Path $FixtureDir 'PairA-Before.json') `
                -AfterPath (Join-Path $FixtureDir 'PairA-After.json') `
                -OutPath $OutDir -OutCsvFileName 'MyDelta'
            Split-Path -Leaf $custom.CsvPath | Should -Be 'MyDelta.csv'
            Test-Path -LiteralPath $custom.CsvPath | Should -BeTrue
        }

        It 'Writes a CSV that parses back to one row per control' {
            $rows = @(Import-Csv -LiteralPath $Result.CsvPath)
            $rows.Count | Should -Be 14
            $rows[0].Product | Should -Be 'AAD'
            ($rows | Where-Object { $_.'Control ID (After)' -eq 'MS.AAD.1.1v1' }).Classification | Should -Be 'NewFail'
        }

        It 'Includes unchanged rows in the CSV' {
            $rows = @(Import-Csv -LiteralPath $Result.CsvPath)
            ($rows | Where-Object { $_.Classification -eq 'Unchanged' }).Count | Should -BeGreaterThan 0
        }
    }

    Describe -Tag 'Diff' -Name 'ConvertTo-ScubaDiffCsvRecord' {
        BeforeAll {
            $script:FixtureDir = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $Before = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairA-Before.json')
            $After = Import-ScubaResultsFile -Path (Join-Path $FixtureDir 'PairA-After.json')
            $script:DiffA = Compare-ScubaResults -Before $Before -After $After -ToolVersion '9.9.9'
            $script:RowsA = @(ConvertTo-ScubaDiffCsvRecord -DiffResults $DiffA)
        }

        It 'Emits one row per control record' {
            $RowsA.Count | Should -Be @($DiffA.Diff.AAD).Count
        }

        It 'Carries the product in a leading column' {
            $RowsA[0].PSObject.Properties.Name[0] | Should -Be 'Product'
            $RowsA[0].Product | Should -Be 'AAD'
        }

        It 'Gives every row the same columns, including the optional fields' {
            $expectedColumns = @(
                'Product','Control ID (Before)','Control ID (After)','GroupNumber','GroupName','Classification',
                'ResultBefore','ResultAfter','CriticalityBefore','CriticalityAfter','Requirement','DetailsAfter',
                'MarkedIncorrectBefore','MarkedIncorrectAfter','UnderlyingResultBefore','UnderlyingResultAfter',
                'AnnotationChanged','Comment','RemediationDate',
                'Migrated','MigratedFromId','MigratedFromProduct'
            )
            foreach ($row in $RowsA) {
                ($row.PSObject.Properties.Name -join ',') | Should -Be ($expectedColumns -join ',')
            }
        }

        It 'Flattens the diff classification and both results' {
            $row = $RowsA | Where-Object { $_.'Control ID (After)' -eq 'MS.AAD.1.1v1' }
            $row.Classification | Should -Be 'NewFail'
            $row.ResultBefore | Should -Be 'Pass'
            $row.ResultAfter | Should -Be 'Fail'
        }

        It 'Carries the annotation fields for a Fail->Fail record' {
            $row = $RowsA | Where-Object { $_.'Control ID (After)' -eq 'MS.AAD.13.1v1' }
            $row.AnnotationChanged | Should -BeTrue
            $row.Comment | Should -Be 'Escalated to vendor'
            $row.RemediationDate | Should -Be '2026-09-01'
        }

        It 'Leaves the optional fields empty for records that do not carry them' {
            $row = $RowsA | Where-Object { $_.'Control ID (After)' -eq 'MS.AAD.1.1v1' }
            $row.MarkedIncorrectBefore | Should -BeNullOrEmpty
            $row.UnderlyingResultAfter | Should -BeNullOrEmpty
            $row.Comment | Should -BeNullOrEmpty
        }

        It 'Orders products by the fixed report order' {
            $FixtureDirB = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $diffB = Compare-ScubaResults `
                -Before (Import-ScubaResultsFile -Path (Join-Path $FixtureDirB 'PairB-Before.json')) `
                -After (Import-ScubaResultsFile -Path (Join-Path $FixtureDirB 'PairB-After.json'))
            $products = @(ConvertTo-ScubaDiffCsvRecord -DiffResults $diffB | ForEach-Object { $_.Product } | Select-Object -Unique)
            $products -join ',' | Should -Be 'Defender,SecuritySuite'
        }

        It 'Carries the migration fields for a migrated record and leaves them empty otherwise' {
            $FixtureDirC = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $diffC = Compare-ScubaResults `
                -Before (Import-ScubaResultsFile -Path (Join-Path $FixtureDirC 'PairC-Before.json')) `
                -After (Import-ScubaResultsFile -Path (Join-Path $FixtureDirC 'PairC-After.json'))
            $rowsC = @(ConvertTo-ScubaDiffCsvRecord -DiffResults $diffC)

            $migrated = $rowsC | Where-Object { $_.'Control ID (After)' -eq 'MS.SECURITYSUITE.3.1v1' }
            $migrated.Product | Should -Be 'SecuritySuite'
            $migrated.Migrated | Should -BeTrue
            $migrated.MigratedFromId | Should -Be 'MS.DEFENDER.4.1v2'
            $migrated.MigratedFromProduct | Should -Be 'Defender'

            $notMigrated = $rowsC | Where-Object { $_.'Control ID (After)' -eq 'MS.SECURITYSUITE.6.1v1' }
            $notMigrated.Migrated | Should -BeNullOrEmpty
            $notMigrated.MigratedFromId | Should -BeNullOrEmpty
        }

        It 'Round-trips through ConvertTo-Csv with every column preserved' {
            $csv = $RowsA | ConvertTo-Csv -NoTypeInformation
            $parsed = @($csv | ConvertFrom-Csv)
            $parsed.Count | Should -Be $RowsA.Count
            $parsed[0].PSObject.Properties.Name | Should -Contain 'UnderlyingResultAfter'
            ($parsed | Where-Object { $_.'Control ID (After)' -eq 'MS.AAD.1.1v1' }).Classification | Should -Be 'NewFail'
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
        It 'Emits a summary-header filter checkbox for a classification present in the diff' {
            # PairA has NewFail records, so its column must carry a filter toggle.
            $Html | Should -Match 'class="classification-toggle" data-classification="NewFail"'
        }
        It 'Emits a filter checkbox for every taxonomy classification, even ones absent from the diff' {
            # PairA has no PolicyVersionUpdate or NewIncorrectResult records, yet the
            # filter for each must still be present.
            $Html | Should -Match 'class="classification-toggle" data-classification="PolicyVersionUpdate"'
            $Html | Should -Match 'class="classification-toggle" data-classification="NewIncorrectResult"'
        }
        It 'Includes the uncheck-all filters button' {
            $Html | Should -Match 'id="toggle-all-filters"'
            $Html | Should -Match 'Uncheck all filters'
        }
        It 'Does not put a filter checkbox on the Unchanged column' {
            # Unchanged stays governed by the "Show unchanged rows" toggle.
            $Html | Should -Not -Match 'class="classification-toggle" data-classification="Unchanged"'
        }
        It 'Tags product rows and summary count cells with their classification for filtering' {
            $Html | Should -Match '<tr class="diff-row diff-red" data-classification="NewFail">'
            $Html | Should -Match '<td class="count[^"]*" data-classification="NewFail" data-count="\d+">'
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
            # colored by the diff classification.
            $Html | Should -Match 'MS.AAD.1.1v1[\s\S]*?New Fail'
            $Html | Should -Match 'class="diff-row diff-red"'
        }
        It 'Greys out removed-policy rows like manual checks' {
            $Html | Should -Match 'class="diff-row diff-grey[^"]*"'
        }
        It 'Marks unchanged rows with the hide-by-default class' {
            $Html | Should -Match 'diff-unchanged-row'
        }
        It 'Displays the RemovedPolicy classification as "Removed Policy"' {
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
        It 'Badges a migrated row and shows both control IDs' {
            $FixtureDirC = Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures'
            $diffC = Compare-ScubaResults `
                -Before (Import-ScubaResultsFile -Path (Join-Path $FixtureDirC 'PairC-Before.json')) `
                -After (Import-ScubaResultsFile -Path (Join-Path $FixtureDirC 'PairC-After.json'))
            $htmlC = New-ScubaDiffReport -DiffResults $diffC
            $htmlC | Should -Match 'MS\.DEFENDER\.4\.1v2 &rarr; MS\.SECURITYSUITE\.3\.1v1 <span class="migrated-badge"'
            $htmlC | Should -Match 'data-migrated="true"'
            # A migrated row is classified by result, so it keeps a normal
            # classification and stays reachable by the existing filters.
            $htmlC | Should -Match 'data-classification="NewPass"'
        }
    }
}

AfterAll {
    Remove-Module Diff -ErrorAction SilentlyContinue
}
