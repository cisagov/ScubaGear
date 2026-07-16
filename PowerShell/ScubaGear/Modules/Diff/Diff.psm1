# Diff.psm1
#
# Pure comparison logic for Invoke-SCuBADiff. This module compares two
# ScubaResults.json files and produces a machine-readable DiffResults object and
# an HTML report. It has NO dependency on Connection, Providers, Permissions, or
# anything touching a live tenant session: everything here runs fully offline.
#
# See docs/execution/diff.md for usage and the ADR for design rationale.

# Product abbreviation -> display title used for the HTML report headings and
# summary table. The DiffResults.json keys remain the canonical abbreviations;
# only the report display uses these friendlier names. Products not listed here
# are shown using their raw abbreviation.
$script:ProductDisplayNameMap = @{
    'AAD'            = 'Microsoft Entra ID / Azure Active Directory'
    'Defender'       = 'Microsoft 365 Defender'
    'EXO'            = 'Exchange Online'
    'PowerPlatform'  = 'Microsoft Power Platform'
    'PowerBI'        = 'Microsoft Power BI'
    'SharePoint'     = 'SharePoint Online'
    'Teams'          = 'Microsoft Teams'
    'SecuritySuite'  = 'Security Suite'
}

# Fixed display order for products in the HTML report (summary table and section
# tables). Products not listed here are appended, ordered alphabetically.
$script:ProductOrder = @(
    'AAD'
    'Defender'
    'EXO'
    'PowerBI'
    'PowerPlatform'
    'SharePoint'
    'SecuritySuite'
    'Teams'
)

# Bucket -> row color class used by the HTML report. Keep in sync with the
# transition taxonomy in the ADR / usage doc.
$script:BucketColorMap = [ordered]@{
    'Errored'          = 'red'
    'Regression'       = 'red'
    'WarningEscalated' = 'red'
    'Remediated'       = 'green'
    'WarningResolved'  = 'green'
    'NewWarning'       = 'yellow'
    'OmissionChanged'  = 'yellow'
    'MarkedIncorrect'  = 'grey'
    'IncorrectResolved' = 'green'
    'VersionChanged'   = 'yellow'
    'Other'            = 'yellow'
    'NewlyAutomated'   = 'neutral'
    'NewlyManual'      = 'neutral'
    'New'              = 'neutral'
    'PolicyRemoved'    = 'neutral'
    'Unchanged'        = 'unchanged'
}

# Bucket -> human-friendly label for HTML display. Buckets not listed here are
# displayed using their raw (camelCase) token.
$script:BucketLabelMap = @{
    'PolicyRemoved'     = 'Policy Removed'
    'MarkedIncorrect'   = 'Marked Incorrect (false positive)'
    'IncorrectResolved' = 'Incorrect Result Resolved'
}

function Get-ScubaBaseControlId {
    <#
    .Description
    Strips the trailing per-policy version suffix (v<N> or v<N>.<M>...) from a
    control ID, returning the base ID used for matching between files.
    E.g. "MS.AAD.1.1v1" -> "MS.AAD.1.1"; "MS.AAD.1.1v1.2" -> "MS.AAD.1.1".
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $ControlId
    )
    return ($ControlId -replace '[vV]\d+(?:\.\d+)*$', '')
}

function Get-ScubaControlVersion {
    <#
    .Description
    Returns the trailing version suffix (e.g. "v1", "v12", "v1.2") of a control
    ID, or $null when the ID carries no version suffix.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $ControlId
    )
    if ($ControlId -match '([vV]\d+(?:\.\d+)*)$') {
        return $Matches[1]
    }
    return $null
}

function Get-ScubaControlSortKey {
    <#
    .Description
    Builds a sort key that orders control IDs numerically rather than
    lexicographically, so that e.g. MS.EXO.9.5 precedes MS.EXO.10.1 instead of
    following it. Every run of digits is zero-padded to a fixed width, leaving a
    string whose ordinal comparison matches the intended numeric order.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $ControlId
    )
    if ([string]::IsNullOrEmpty($ControlId)) {
        return ''
    }
    return [regex]::Replace($ControlId, '\d+', { param($m) $m.Value.PadLeft(10, '0') })
}

function Get-ScubaOrderedControlIds {
    <#
    .Description
    Orders control IDs by their numeric segments (see Get-ScubaControlSortKey),
    keeping each product's policy groups in baseline order (1, 2, ... 9, 10, 11)
    in both the JSON output and the HTML report.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]
        $ControlIds
    )
    return @($ControlIds | Sort-Object -Property @{ Expression = { Get-ScubaControlSortKey $_ } })
}

function ConvertTo-ScubaPlainText {
    <#
    .Description
    Strips HTML from a ScubaResults string so it is safe to store in the diff
    record and to compare for equality. In particular the Requirement field
    embeds a <div class='policy-indicators'>...</div> block plus anchor tags;
    those are removed and remaining markup / entities are decoded.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $Text
    )
    if ([string]::IsNullOrEmpty($Text)) {
        return ''
    }
    $clean = $Text
    # Drop the policy-indicators block (and anything after it, which is only ever
    # the closing markup for that block in observed output).
    $clean = $clean -replace "(?s)<div class=['`"]policy-indicators['`"].*$", ''
    # Normalize common structural tags to spaces before stripping the rest.
    $clean = $clean -replace '<br\s*/?>', ' '
    # Strip any remaining HTML tags.
    $clean = $clean -replace '<[^>]+>', ''
    # Decode HTML entities (e.g. &amp; -> &).
    $clean = [System.Net.WebUtility]::HtmlDecode($clean)
    # Collapse runs of whitespace introduced by tag removal.
    $clean = $clean -replace '\s+', ' '
    return $clean.Trim()
}

function ConvertTo-ScubaHtmlEncoded {
    <#
    .Description
    HTML-encodes a string for safe inclusion in the diff report. All
    user-controllable strings must pass through this before being written to HTML.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $Text
    )
    if ([string]::IsNullOrEmpty($Text)) {
        return ''
    }
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Get-ScubaResultCategory {
    <#
    .Description
    Normalizes an open-set Result string into a comparison category. Anything
    unrecognized becomes 'Other' (the literal is preserved elsewhere), so unknown
    Result values never crash the diff.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $Result
    )
    if ([string]::IsNullOrEmpty($Result)) {
        return 'Other'
    }
    switch ($Result.Trim().ToLowerInvariant()) {
        'pass'              { return 'Pass' }
        'fail'              { return 'Fail' }
        'warning'           { return 'Warning' }
        'n/a'               { return 'NA' }
        'omitted'           { return 'Omitted' }
        'error'             { return 'Error' }
        'incorrect result'  { return 'Incorrect' }
        default             { return 'Other' }
    }
}

function Get-ScubaDiffBucket {
    <#
    .Description
    Classifies a single base control ID into exactly one transition bucket,
    honoring the precedence: Errored > VersionChanged > OmissionChanged >
    MarkedIncorrect/IncorrectResolved > specific transitions > Other > Unchanged.
    New/PolicyRemoved are determined by presence and take precedence over
    everything else. PolicyRemoved (base ID present in the before file but absent
    from the after file) aligns with the baselines' removedpolicies.md tracking.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [AllowNull()] [AllowEmptyString()] [string] $BeforeResult,
        [Parameter(Mandatory = $true)] [AllowNull()] [AllowEmptyString()] [string] $AfterResult,
        [Parameter(Mandatory = $true)] [bool] $BeforePresent,
        [Parameter(Mandatory = $true)] [bool] $AfterPresent,
        [Parameter(Mandatory = $true)] [AllowNull()] [AllowEmptyString()] [string] $BeforeVersion,
        [Parameter(Mandatory = $true)] [AllowNull()] [AllowEmptyString()] [string] $AfterVersion
    )

    if (-not $BeforePresent) { return 'New' }
    if (-not $AfterPresent) { return 'PolicyRemoved' }

    $bCat = Get-ScubaResultCategory $BeforeResult
    $aCat = Get-ScubaResultCategory $AfterResult

    # Errored has highest precedence among matched controls.
    if ($bCat -eq 'Error' -or $aCat -eq 'Error') { return 'Errored' }

    # A changed version suffix means the policy's meaning changed; the Result
    # comparison is informational, so this outranks the specific transitions.
    if ($BeforeVersion -ne $AfterVersion) { return 'VersionChanged' }

    # Omission changes (non-identical involving Omitted).
    if ($bCat -eq 'Omitted' -or $aCat -eq 'Omitted') {
        if ($bCat -eq $aCat -and $BeforeResult -eq $AfterResult) { return 'Unchanged' }
        return 'OmissionChanged'
    }

    # False-positive marking changes. A control marked incorrect by the user
    # carries the literal Result "Incorrect result" (category 'Incorrect'). A
    # flip in that marking is its own transition; both-incorrect falls through to
    # the Unchanged check below.
    if ($aCat -eq 'Incorrect' -and $bCat -ne 'Incorrect') { return 'MarkedIncorrect' }
    if ($bCat -eq 'Incorrect' -and $aCat -ne 'Incorrect') { return 'IncorrectResolved' }

    switch ("$bCat->$aCat") {
        'Pass->Fail'      { return 'Regression' }
        'Fail->Pass'      { return 'Remediated' }
        'Warning->Pass'   { return 'WarningResolved' }
        'Warning->Fail'   { return 'WarningEscalated' }
        'Pass->Warning'   { return 'NewWarning' }
        'Fail->Warning'   { return 'NewWarning' }
        'NA->Pass'        { return 'NewlyAutomated' }
        'NA->Fail'        { return 'NewlyAutomated' }
        'NA->Warning'     { return 'NewlyAutomated' }
        'Pass->NA'        { return 'NewlyManual' }
        'Fail->NA'        { return 'NewlyManual' }
        'Warning->NA'     { return 'NewlyManual' }
    }

    # Identical Result and version.
    if ($bCat -eq $aCat -and $BeforeResult -eq $AfterResult) { return 'Unchanged' }

    return 'Other'
}

function Get-ScubaBucketColor {
    <#
    .Description
    Maps a transition bucket to its HTML row color class (red/green/yellow/
    neutral/unchanged). Unknown buckets fall back to yellow.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Bucket
    )
    if ($script:BucketColorMap.Contains($Bucket)) {
        return $script:BucketColorMap[$Bucket]
    }
    return 'yellow'
}

function Get-ScubaBucketLabel {
    <#
    .Description
    Maps a transition bucket to its human-friendly display label for the HTML
    report. Buckets without an explicit label are shown using their raw token.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Bucket
    )
    if ($script:BucketLabelMap.ContainsKey($Bucket)) {
        return $script:BucketLabelMap[$Bucket]
    }
    return $Bucket
}

function Get-ScubaProductDisplayName {
    <#
    .Description
    Maps a product abbreviation to its display title for the HTML report. Products
    without an explicit mapping are shown using their raw abbreviation.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $ProductKey
    )
    if ($script:ProductDisplayNameMap.ContainsKey($ProductKey)) {
        return $script:ProductDisplayNameMap[$ProductKey]
    }
    return $ProductKey
}

function Get-ScubaOrderedProducts {
    <#
    .Description
    Orders a set of product abbreviations by the fixed report display order
    ($script:ProductOrder). Products not in that list are appended alphabetically.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]
        $Products
    )
    return @($Products | Sort-Object -Property `
        @{ Expression = {
                $i = [Array]::IndexOf($script:ProductOrder, $_)
                if ($i -ge 0) { $i } else { [int]::MaxValue }
            } }, `
        @{ Expression = { $_ } })
}

function Get-ScubaRowColorClass {
    <#
    .Description
    Determines the HTML row color for a diff record. Removed policies are greyed
    out to match the manual-check styling; every other row is colored by its
    Result (After) value: Fail/Error -> red, Warning -> yellow, Pass -> green, and
    manual (N/A) / Omitted / anything else -> grey.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]
        $Record
    )
    if ($Record.Bucket -eq 'PolicyRemoved') { return 'grey' }
    switch (Get-ScubaResultCategory $Record.ResultAfter) {
        'Fail'    { return 'red' }
        'Error'   { return 'red' }
        'Warning' { return 'yellow' }
        'Pass'    { return 'green' }
        default   { return 'grey' }
    }
}

function Get-ScubaControlMap {
    <#
    .Description
    Flattens a product's Results (a list of groups, each with Controls) into an
    ordered map keyed by base control ID. Each value carries the fields the diff
    needs. When multiple versions of the same base ID appear in one file, the
    last one wins (an unusual, transition-only edge case).
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]
        $ProductResults
    )
    $map = [ordered]@{}
    if ($null -eq $ProductResults) {
        return $map
    }
    foreach ($group in $ProductResults) {
        foreach ($control in $group.Controls) {
            $fullId = $control.'Control ID'
            if ([string]::IsNullOrEmpty($fullId)) { continue }
            $base = Get-ScubaBaseControlId $fullId
            $map[$base] = [pscustomobject]@{
                FullId         = $fullId
                BaseId         = $base
                Version        = Get-ScubaControlVersion $fullId
                Result         = $control.Result
                # OriginalResult is the tool-computed result before annotation /
                # omission processing; for a control marked incorrect (Result =
                # "Incorrect result") it holds the underlying evaluated result.
                OriginalResult = $control.OriginalResult
                Criticality    = $control.Criticality
                Requirement    = $control.Requirement
                Details        = $control.Details
                GroupName      = $group.GroupName
                GroupNumber    = $group.GroupNumber
            }
        }
    }
    return $map
}

function Get-ScubaAnnotationEntry {
    <#
    .Description
    Safely reads an AnnotatedFailedPolicies entry (keyed by full control ID) from
    a ScubaResults object, returning $null when absent.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [AllowNull()] [object] $Annotations,
        [Parameter(Mandatory = $true)] [string] $ControlId
    )
    if ($null -eq $Annotations) { return $null }
    $prop = $Annotations.PSObject.Properties[$ControlId]
    if ($null -eq $prop) { return $null }
    return $prop.Value
}

function Import-ScubaResultsFile {
    <#
    .Description
    Reads a ScubaResults.json file (BOM-tolerant via Get-Content), parses it, and
    validates the required top-level keys. Throws a user-actionable error on
    malformed input.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "ScubaResults file not found: '$Path'."
    }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    }
    catch {
        throw "Unable to read ScubaResults file '$Path': $($_.Exception.Message)"
    }
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "ScubaResults file '$Path' is empty."
    }
    try {
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "ScubaResults file '$Path' is not valid JSON: $($_.Exception.Message)"
    }
    foreach ($key in @('MetaData', 'Summary', 'Results')) {
        if ($null -eq $obj.PSObject.Properties[$key]) {
            throw "ScubaResults file '$Path' is missing the required top-level key '$key'. Is this a ScubaResults.json file produced by ScubaGear?"
        }
    }
    return $obj
}

function Compare-ScubaResults {
    <#
    .Description
    Pure comparison of two parsed ScubaResults objects. Returns the full
    DiffResults object (SchemaVersion / MetaData / Summary / Diff). Performs
    base-ID matching (per product, matched by name only), transition
    classification, and Fail->Fail annotation comparison.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]
        $Before,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]
        $After,

        [Parameter(Mandatory = $false)]
        [string]
        $ToolVersion = 'unknown'
    )

    $beforeProducts = @($Before.Results.PSObject.Properties.Name)
    $afterProducts = @($After.Results.PSObject.Properties.Name)

    # Each product is compared independently and matched by name only. A product
    # present in only one file has all of its controls reported as New (only in
    # after) or PolicyRemoved (only in before).
    $allProducts = @(@($beforeProducts) + @($afterProducts) | Select-Object -Unique | Sort-Object)

    $beforeAnnot = $Before.AnnotatedFailedPolicies
    $afterAnnot = $After.AnnotatedFailedPolicies

    $diff = [ordered]@{}
    $summary = [ordered]@{}
    $productsOnlyBefore = @()
    $productsOnlyAfter = @()

    foreach ($product in $allProducts) {
        $inBefore = $beforeProducts -contains $product
        $inAfter = $afterProducts -contains $product

        if ($inBefore -and -not $inAfter) { $productsOnlyBefore += $product }
        if ($inAfter -and -not $inBefore) { $productsOnlyAfter += $product }

        if ($inBefore) { $beforeMap = Get-ScubaControlMap $Before.Results.$product } else { $beforeMap = [ordered]@{} }
        if ($inAfter) { $afterMap = Get-ScubaControlMap $After.Results.$product } else { $afterMap = [ordered]@{} }

        $allBase = Get-ScubaOrderedControlIds @(@($beforeMap.Keys) + @($afterMap.Keys) | Select-Object -Unique)

        $records = @()
        $bucketCounts = [ordered]@{}

        foreach ($base in $allBase) {
            $b = $beforeMap[$base]
            $a = $afterMap[$base]
            $bPresent = $null -ne $b
            $aPresent = $null -ne $a

            if ($bPresent) { $bResult = $b.Result; $bVersion = $b.Version } else { $bResult = $null; $bVersion = $null }
            if ($aPresent) { $aResult = $a.Result; $aVersion = $a.Version } else { $aResult = $null; $aVersion = $null }

            $bucket = Get-ScubaDiffBucket -BeforeResult $bResult -AfterResult $aResult `
                -BeforePresent $bPresent -AfterPresent $aPresent `
                -BeforeVersion $bVersion -AfterVersion $aVersion

            if ($aPresent) { $reqSource = $a.Requirement } else { $reqSource = $b.Requirement }
            if ($aPresent) { $groupName = $a.GroupName; $groupNumber = $a.GroupNumber } else { $groupName = $b.GroupName; $groupNumber = $b.GroupNumber }
            if ($aPresent) { $detailsAfter = ConvertTo-ScubaPlainText $a.Details } else { $detailsAfter = $null }

            $record = [ordered]@{
                'Control ID (Before)' = if ($bPresent) { $b.FullId } else { $null }
                'Control ID (After)'  = if ($aPresent) { $a.FullId } else { $null }
                'Requirement'         = ConvertTo-ScubaPlainText $reqSource
                'GroupName'           = $groupName
                'GroupNumber'         = $groupNumber
                'ResultBefore'        = $bResult
                'ResultAfter'         = $aResult
                'Bucket'              = $bucket
                'CriticalityBefore'   = if ($bPresent) { $b.Criticality } else { $null }
                'CriticalityAfter'    = if ($aPresent) { $a.Criticality } else { $null }
                'DetailsAfter'        = $detailsAfter
            }

            # False-positive (marked incorrect) metadata. When either side carries
            # the "Incorrect result" marking, record the marking state and the
            # underlying (tool-computed) result on each side so consumers compare
            # the real result rather than the placeholder.
            $bIncorrect = ($bPresent -and (Get-ScubaResultCategory $bResult) -eq 'Incorrect')
            $aIncorrect = ($aPresent -and (Get-ScubaResultCategory $aResult) -eq 'Incorrect')
            if ($bIncorrect -or $aIncorrect) {
                $record['MarkedIncorrectBefore'] = [bool]$bIncorrect
                $record['MarkedIncorrectAfter'] = [bool]$aIncorrect
                $record['UnderlyingResultBefore'] = if ($bPresent) { $b.OriginalResult } else { $null }
                $record['UnderlyingResultAfter'] = if ($aPresent) { $a.OriginalResult } else { $null }
            }

            # Fail -> Fail annotation comparison (narrow v1 scope).
            if ($bPresent -and $aPresent -and
                (Get-ScubaResultCategory $bResult) -eq 'Fail' -and
                (Get-ScubaResultCategory $aResult) -eq 'Fail') {
                $bEntry = Get-ScubaAnnotationEntry $beforeAnnot $b.FullId
                $aEntry = Get-ScubaAnnotationEntry $afterAnnot $a.FullId
                if ($bEntry) { $bComment = $bEntry.Comment; $bDate = $bEntry.RemediationDate } else { $bComment = $null; $bDate = $null }
                if ($aEntry) { $aComment = $aEntry.Comment; $aDate = $aEntry.RemediationDate } else { $aComment = $null; $aDate = $null }
                $record['AnnotationChanged'] = [bool](($bComment -ne $aComment) -or ($bDate -ne $aDate))
                $record['Comment'] = $aComment
                $record['RemediationDate'] = $aDate
            }

            $records += [pscustomobject]$record

            if (-not $bucketCounts.Contains($bucket)) { $bucketCounts[$bucket] = 0 }
            $bucketCounts[$bucket] += 1
        }

        $diff[$product] = $records
        $summary[$product] = $bucketCounts
    }

    $timestampZulu = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

    $metaData = [ordered]@{
        'Tool'          = 'ScubaGear'
        'ToolVersion'   = $ToolVersion
        'TimestampZulu' = $timestampZulu
        'Before'        = [ordered]@{
            'ReportUUID'    = $Before.MetaData.ReportUUID
            'TimestampZulu' = $Before.MetaData.TimestampZulu
            'ToolVersion'   = $Before.MetaData.ToolVersion
        }
        'After'         = [ordered]@{
            'ReportUUID'    = $After.MetaData.ReportUUID
            'TimestampZulu' = $After.MetaData.TimestampZulu
            'ToolVersion'   = $After.MetaData.ToolVersion
        }
        'ProductsOnlyInBefore' = @($productsOnlyBefore)
        'ProductsOnlyInAfter'  = @($productsOnlyAfter)
    }

    return [ordered]@{
        'SchemaVersion' = '1.0'
        'MetaData'      = $metaData
        'Summary'       = $summary
        'Diff'          = $diff
    }
}

function Get-ScubaDiffFileEncoding {
    <#
    .Description
    Returns the encoding used to write diff output files, matching the repo's
    Get-FileEncoding convention: UTF-8 with BOM on Windows PowerShell 5.1
    (Desktop), UTF-8 without BOM on PowerShell 6+.
    .Functionality
    Internal
    #>
    if ($PSVersionTable.PSVersion -ge '6.0') {
        return 'utf8NoBom'
    }
    return 'utf8'
}

function New-ScubaDiffReport {
    <#
    .Description
    Builds the standalone HTML diff report string from a DiffResults object. The
    report is fully self-contained (inline CSS + JS) and does NOT reuse New-Report
    (which requires live run artifacts). Unchanged rows are emitted but hidden by
    default via a client-side toggle. All user-controllable strings are
    HTML-encoded.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]
        $DiffResults,

        [Parameter(Mandatory = $false)]
        [switch]
        $DarkMode
    )

    $CssPath = Join-Path -Path $PSScriptRoot -ChildPath 'styles\DiffReport.css'
    $JsPath = Join-Path -Path $PSScriptRoot -ChildPath 'scripts\DiffReport.js'
    $Css = Get-Content -LiteralPath $CssPath -Raw
    $Js = Get-Content -LiteralPath $JsPath -Raw

    $meta = $DiffResults.MetaData
    $enc = { param($s) ConvertTo-ScubaHtmlEncoded ([string]$s) }

    # Ordered list of buckets for stable summary columns.
    $bucketOrder = @($script:BucketColorMap.Keys)

    $sb = New-Object System.Text.StringBuilder

    [void]$sb.AppendLine('<div class="report-header">')
    [void]$sb.AppendLine('  <h1>ScubaGear Diff Report</h1>')
    [void]$sb.AppendLine('  <div class="controls-bar">')
    [void]$sb.AppendLine('    <label><input type="checkbox" id="toggle-unchanged"> Show unchanged rows</label>')
    [void]$sb.AppendLine('    <label><input type="checkbox" id="toggle-dark"> Dark Mode</label>')
    [void]$sb.AppendLine('  </div>')
    [void]$sb.AppendLine('</div>')

    # Source metadata cards.
    [void]$sb.AppendLine('<div class="source-summary">')
    foreach ($side in @('Before', 'After')) {
        $s = $meta.$side
        [void]$sb.AppendLine('  <div class="source-card">')
        [void]$sb.AppendLine("    <h3>$side</h3>")
        [void]$sb.AppendLine("    <div>Tool version: $(& $enc $s.ToolVersion)</div>")
        [void]$sb.AppendLine("    <div>Timestamp: $(& $enc $s.TimestampZulu)</div>")
        [void]$sb.AppendLine("    <div class=""uuid"">Report UUID: $(& $enc $s.ReportUUID)</div>")
        [void]$sb.AppendLine('  </div>')
    }
    [void]$sb.AppendLine('</div>')
    [void]$sb.AppendLine("<p>Diff generated $(& $enc $meta.TimestampZulu) by ScubaGear $(& $enc $meta.ToolVersion).</p>")

    if (@($meta.ProductsOnlyInBefore).Count -gt 0) {
        [void]$sb.AppendLine("<p><strong>Products only in Before (all controls Policy Removed):</strong> $(& $enc ((@($meta.ProductsOnlyInBefore)) -join ', '))</p>")
    }
    if (@($meta.ProductsOnlyInAfter).Count -gt 0) {
        [void]$sb.AppendLine("<p><strong>Products only in After (all controls New):</strong> $(& $enc ((@($meta.ProductsOnlyInAfter)) -join ', '))</p>")
    }

    # Legend. Rows are colored by their Result (After) value; removed policies are
    # greyed out like manual checks.
    [void]$sb.AppendLine('<div class="legend">')
    [void]$sb.AppendLine('  <span><span class="swatch diff-red"></span>Fail (Result After)</span>')
    [void]$sb.AppendLine('  <span><span class="swatch diff-yellow"></span>Warning (Result After)</span>')
    [void]$sb.AppendLine('  <span><span class="swatch diff-green"></span>Pass (Result After)</span>')
    [void]$sb.AppendLine('  <span><span class="swatch diff-grey"></span>Manual (N/A) / Omitted / Policy Removed</span>')
    [void]$sb.AppendLine('  <span>Unchanged rows are hidden by default (use the toggle above).</span>')
    [void]$sb.AppendLine('</div>')

    # Per-product summary table.
    $usedBuckets = @()
    foreach ($product in $DiffResults.Summary.Keys) {
        foreach ($k in $DiffResults.Summary.$product.Keys) {
            if ($usedBuckets -notcontains $k) { $usedBuckets += $k }
        }
    }
    $summaryColumns = @($bucketOrder | Where-Object { $usedBuckets -contains $_ })

    [void]$sb.AppendLine('<h2>Summary</h2>')
    [void]$sb.AppendLine('<table class="summary-table">')
    [void]$sb.Append('<tr><th>Product</th>')
    foreach ($col in $summaryColumns) { [void]$sb.Append("<th>$(& $enc $col)</th>") }
    [void]$sb.AppendLine('<th>Total</th></tr>')
    foreach ($product in (Get-ScubaOrderedProducts @($DiffResults.Summary.Keys))) {
        $counts = $DiffResults.Summary.$product
        [void]$sb.Append("<tr><td>$(& $enc (Get-ScubaProductDisplayName $product))</td>")
        $total = 0
        foreach ($col in $summaryColumns) {
            if ($counts.Contains($col)) { $val = $counts[$col] } else { $val = 0 }
            $total += $val
            if ($val -eq 0) { $cls = ' class="count-zero"' } else { $cls = '' }
            [void]$sb.Append("<td$cls>$val</td>")
        }
        [void]$sb.AppendLine("<td>$total</td></tr>")
    }
    [void]$sb.AppendLine('</table>')

    # Per-product transition tables.
    foreach ($product in (Get-ScubaOrderedProducts @($DiffResults.Diff.Keys))) {
        $records = @($DiffResults.Diff.$product)
        [void]$sb.AppendLine("<h2>$(& $enc (Get-ScubaProductDisplayName $product))</h2>")
        [void]$sb.AppendLine('<table class="policy-diff">')
        [void]$sb.AppendLine('<tr><th>Control ID</th><th>Group</th><th>Transition</th><th>Result (Before)</th><th>Result (After)</th><th>Requirement</th><th>Details (After)</th></tr>')
        foreach ($r in $records) {
            $bucket = $r.Bucket
            # Row color follows the Result (After) value (Fail/Error=red,
            # Warning=yellow, Pass=green, manual/removed/other=grey).
            $color = Get-ScubaRowColorClass $r
            $rowClass = "diff-row diff-$color"
            if ($bucket -eq 'Unchanged') { $rowClass += ' diff-unchanged-row' }

            # Control ID display: show a "before -> after" arrow when the IDs differ.
            $beforeId = $r.'Control ID (Before)'
            $afterId = $r.'Control ID (After)'
            if ($beforeId -and $afterId -and ($beforeId -ne $afterId)) {
                $idDisplay = "$(& $enc $beforeId) &rarr; $(& $enc $afterId)"
            }
            elseif ($afterId) { $idDisplay = & $enc $afterId }
            else { $idDisplay = & $enc $beforeId }

            $groupDisplay = & $enc (("$($r.GroupNumber) $($r.GroupName)").Trim())

            # Result cells. For a side marked incorrect (false positive), surface
            # the underlying tool-computed result inline.
            $resultBeforeCell = & $enc $r.ResultBefore
            if ($r.PSObject.Properties['MarkedIncorrectBefore'] -and $r.MarkedIncorrectBefore -and $r.UnderlyingResultBefore) {
                $resultBeforeCell += " <span class=""underlying"">(underlying: $(& $enc $r.UnderlyingResultBefore))</span>"
            }
            $resultAfterCell = & $enc $r.ResultAfter
            if ($r.PSObject.Properties['MarkedIncorrectAfter'] -and $r.MarkedIncorrectAfter -and $r.UnderlyingResultAfter) {
                $resultAfterCell += " <span class=""underlying"">(underlying: $(& $enc $r.UnderlyingResultAfter))</span>"
            }

            [void]$sb.AppendLine("<tr class=""$rowClass"">")
            [void]$sb.AppendLine("  <td>$idDisplay</td>")
            [void]$sb.AppendLine("  <td>$groupDisplay</td>")
            [void]$sb.AppendLine("  <td class=""bucket-label"">$(& $enc (Get-ScubaBucketLabel $bucket))</td>")
            [void]$sb.AppendLine("  <td>$resultBeforeCell</td>")
            [void]$sb.AppendLine("  <td>$resultAfterCell</td>")
            [void]$sb.AppendLine("  <td>$(& $enc $r.Requirement)</td>")
            [void]$sb.AppendLine("  <td>$(& $enc $r.DetailsAfter)</td>")
            [void]$sb.AppendLine('</tr>')
        }
        [void]$sb.AppendLine('</table>')
    }

    $body = $sb.ToString()
    $darkFlag = $DarkMode.IsPresent.ToString().ToLowerInvariant()

    $html = @"
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>ScubaGear Diff Report</title>
<style>
$Css
</style>
</head>
<body>
$body
<script id="dark-mode-flag" type="application/json">$darkFlag</script>
<script>
$Js
</script>
</body>
</html>
"@
    return $html
}

function Invoke-SCuBADiff {
    <#
    .SYNOPSIS
    Compares two ScubaResults.json files and produces a machine-readable diff
    (DiffResults.json) and an HTML report (DiffReport.html) highlighting per-policy
    status transitions.

    .Description
    Invoke-SCuBADiff is an offline, post-hoc analysis command: it takes two
    ScubaResults.json files produced by earlier ScubaGear runs (a "before" and an
    "after") and reports how each policy's result changed between them. It performs
    no authentication and makes no Connect-* calls.

    Controls are matched on their base ID (the Control ID with the trailing version
    suffix removed, e.g. MS.AAD.1.1v1 -> MS.AAD.1.1). When the same base ID appears
    with different version suffixes, the change is classified as VersionChanged and
    the result comparison is treated as informational. Products are matched by name
    only; a product present in only one file has all of its controls reported as
    New or PolicyRemoved.

    The HTML report hides Unchanged rows by default; a client-side toggle reveals
    them. Use -DarkMode to default the report to dark theme.

    .Parameter BeforePath
    Path to the earlier ("before") ScubaResults.json file.

    .Parameter AfterPath
    Path to the later ("after") ScubaResults.json file.

    .Parameter OutPath
    The folder where DiffResults.json and DiffReport.html are written. Created if it
    does not exist. Defaults to the current directory.

    .Parameter OutJsonFileName
    Base name (without extension) of the diff JSON file. Defaults to "DiffResults".

    .Parameter OutReportFileName
    Base name (without extension) of the diff HTML report. Defaults to "DiffReport".

    .Parameter DarkMode
    When present, the HTML report defaults to dark theme.

    .Example
    Invoke-SCuBADiff -BeforePath .\before\ScubaResults.json -AfterPath .\after\ScubaResults.json

    .Example
    Invoke-SCuBADiff -BeforePath q1.json -AfterPath q2.json -OutPath .\diff -DarkMode

    .Functionality
    Public
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $BeforePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AfterPath,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutPath = (Get-Location).ProviderPath,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutJsonFileName = 'DiffResults',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportFileName = 'DiffReport',

        [Parameter(Mandatory = $false)]
        [switch]
        $DarkMode
    )

    $Before = Import-ScubaResultsFile -Path $BeforePath
    $After = Import-ScubaResultsFile -Path $AfterPath

    # Resolve the running module version for the diff MetaData block.
    $ToolVersion = 'unknown'
    try {
        $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\ScubaGear.psd1'
        if (Test-Path -LiteralPath $ManifestPath) {
            $ToolVersion = (Import-PowerShellDataFile -Path $ManifestPath).ModuleVersion
        }
    }
    catch {
        Write-Warning "Could not resolve ScubaGear module version: $($_.Exception.Message)"
    }

    $DiffResults = Compare-ScubaResults -Before $Before -After $After -ToolVersion $ToolVersion

    if (-not (Test-Path -LiteralPath $OutPath)) {
        New-Item -ItemType Directory -Path $OutPath -Force | Out-Null
    }

    $Encoding = Get-ScubaDiffFileEncoding

    # Write DiffResults.json.
    $JsonPath = Join-Path -Path $OutPath -ChildPath "$OutJsonFileName.json"
    $Json = $DiffResults | ConvertTo-Json -Depth 10
    # ConvertTo-Json escapes <, >, and ' as unicode escape sequences; convert them
    # back for readability and parity with the ScubaResults.json convention.
    $Bs = [char]0x5C  # backslash, built from a char code to keep the source literal
    $Json = $Json.Replace("${Bs}u003c", '<').Replace("${Bs}u003e", '>').Replace("${Bs}u0027", "'")
    $Json | Set-Content -Path $JsonPath -Encoding $Encoding -ErrorAction Stop

    # Write DiffReport.html.
    $ReportPath = Join-Path -Path $OutPath -ChildPath "$OutReportFileName.html"
    $Html = New-ScubaDiffReport -DiffResults $DiffResults -DarkMode:$DarkMode
    $Html | Set-Content -Path $ReportPath -Encoding $Encoding -ErrorAction Stop

    Write-Information -MessageData "ScubaGear diff written to:`n  $JsonPath`n  $ReportPath" -InformationAction Continue

    return [PSCustomObject]@{
        JsonPath   = $JsonPath
        ReportPath = $ReportPath
    }
}

Export-ModuleMember -Function @(
    'Invoke-SCuBADiff',
    'Import-ScubaResultsFile',
    'Compare-ScubaResults',
    'New-ScubaDiffReport',
    'Get-ScubaBaseControlId',
    'Get-ScubaControlVersion',
    'Get-ScubaControlSortKey',
    'Get-ScubaOrderedControlIds',
    'ConvertTo-ScubaPlainText',
    'ConvertTo-ScubaHtmlEncoded',
    'Get-ScubaResultCategory',
    'Get-ScubaDiffBucket',
    'Get-ScubaBucketColor',
    'Get-ScubaBucketLabel',
    'Get-ScubaRowColorClass',
    'Get-ScubaProductDisplayName',
    'Get-ScubaOrderedProducts',
    'Get-ScubaControlMap',
    'Get-ScubaAnnotationEntry',
    'Get-ScubaDiffFileEncoding'
)
