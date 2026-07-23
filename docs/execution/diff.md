# Invoke-SCuBADiff; Comparing two ScubaGearresults.json files

## Overview

`Invoke-SCuBADiff` compares two `ScubaResults.json` files produced by earlier
ScubaGear runs — a **before** file and an **after** file — and reports how each
policy's result changed between them. It is an offline, post-hoc analysis
command: it performs no authentication, makes no `Connect-*` calls, and never
contacts a tenant.

It produces three artifacts:

1. **`DiffResults.json`** — a machine-readable delta describing every policy diff's between ScubaGear runs, carrying a top-level `SchemaVersion` for downstream consumers.
2. **`DiffResults.csv`** — the same delta flattened to one row per policy, for
   spreadsheets and other tabular tooling. See [The CSV](#the-csv).
3. **`DiffReport.html`** — a self-contained HTML report that highlights the
   diffs with color-coded rows and hides unchanged rows behind a toggle.

## Usage

Provide the path to the first (earlier) `ScubaResults.json` and the path to the
second (later) `ScubaResults.json`:

```powershell
Invoke-SCuBADiff -BeforePath "C:\Runs\Q1\ScubaResults_abc123.json" `
                 -AfterPath  "C:\Runs\Q2\ScubaResults_def456.json"
```

By default the three artifacts are written to the current directory as
`DiffResults.json`, `DiffResults.csv`, and `DiffReport.html`. Use `-OutPath` to choose a folder
(it is created if it does not exist) and `-DarkMode` to default the report to a
dark theme:

```powershell
Invoke-SCuBADiff -BeforePath .\before\ScubaResults.json `
                 -AfterPath  .\after\ScubaResults.json `
                 -OutPath    .\diff `
                 -DarkMode
```

### Parameters

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-BeforePath` | Yes | — | Path to the earlier ("before") `ScubaResults.json`. |
| `-AfterPath` | Yes | — | Path to the later ("after") `ScubaResults.json`. |
| `-OutPath` | No | Current directory | Folder to write the three artifacts to. Created if missing. |
| `-OutJsonFileName` | No | `DiffResults` | Base name (no extension) of the diff JSON. |
| `-OutCsvFileName` | No | `DiffResults` | Base name (no extension) of the diff CSV. |
| `-OutReportFileName` | No | `DiffReport` | Base name (no extension) of the diff HTML report. |
| `-DarkMode` | No | Off | Default the HTML report to dark theme. |

The command returns an object with `JsonPath`, `CsvPath`, and `ReportPath`
pointing at the three artifacts.

## How controls are matched

M365 policy IDs carry a per-policy version suffix, e.g. `MS.AAD.1.1v1`. That
suffix increments (`v1` → `v2`) when the *meaning* of the policy changes.
`Invoke-SCuBADiff` matches controls on their **base ID** — the ID with the
trailing version suffix removed (`MS.AAD.1.1v1` → `MS.AAD.1.1`):

- **Same base ID, same version** → the results are compared directly.
- **Same base ID, different version** → the change is classified as
  `PolicyVersionUpdate`. Because the policy's meaning changed between the two
  runs, the before/after result comparison is **informational only**, not an
  authoritative pass/fail delta. Both results are still reported and labeled as
  such.
- **Base ID present in only one file** → `NewPolicy` (only in *after*) or
  `RemovedPolicy` (only in *before*). A base ID present in the before file but
  absent from the after file corresponds to a policy that was removed from the
  baseline — see the baselines'
  [removedpolicies.md](../../PowerShell/ScubaGear/baselines/removedpolicies.md).

  > **Note:** `RemovedPolicy` is inferred purely from presence — a base ID that
  > appears in the before file but not the after file. That usually means the
  > policy was removed from the baseline, but it can also occur when the after
  > run simply did not assess that control or product (for example, comparing two
  > runs with different `-ProductNames`). Cross-reference `removedpolicies.md`
  > when you need to distinguish a genuine baseline removal from a control that
  > was merely not evaluated.

Products are matched by name only. A product present in only one file has all of
its controls reported as `NewPolicy` (only in *after*) or `RemovedPolicy` (only
in *before*).

## Diff Key Terminology

Every base control ID present in either file is assigned exactly one
classification. Classifications are named for the state the control **lands in**, so any
diff that ends in Pass, Fail, or Warning reports as `NewPass`, `NewFail`,
or `NewWarning` — including diffs out of `Omitted`, out of a prior
`Error`, or out of an `Incorrect result` marking.

### Precedence order

A control can match more than one rule at once (for example, its version changed
*and* its result changed). It is assigned to the **first** matching classification in
this order, highest to lowest:

| Rank | Classification | Applies when |
|---|---|---|
| 1 | `NewPolicy` / `RemovedPolicy` | The base ID is present in only one file (presence wins over everything). |
| 2 | `Errored` | The **after** result is `Error` — keyed off the latest run only, so a live error surfaces even under a version bump. |
| 3 | `PolicyVersionUpdate` | The version suffix changed; the before/after result comparison is informational. |
| 4 | `Unchanged` | Result and version are identical (hidden by default). |
| 5 | `NewIncorrectResult` | The after result is newly marked `Incorrect result`. |
| 6 | specific transitions | A recognized result change: `NewFail`, `NewPass`, `NewWarning`, `NewAutomatedCheck`, `NewManualCheck`. |
| 7 | `NewOmission` | A remaining transition into or out of `Omitted` with no landing result. |
| 8 | `Other` | Anything else (both literal values preserved). |

> A control that errored in a *prior* run but not the latest one
> (`Error → Pass / Fail / Warning`) is **not** `Errored`; it is classified by the
> state it lands in, so a resolved error is never reported as a red `Errored` row.

### Transition table

| Before → After | Classification |
|---|---|
| Pass → Fail | `NewFail` |
| Fail → Pass | `NewPass` |
| Warning → Pass | `NewPass` |
| Warning → Fail | `NewFail` |
| Pass/Fail → Warning | `NewWarning` |
| N/A → Pass/Fail/Warning | `NewAutomatedCheck` |
| Pass/Fail/Warning → N/A | `NewManualCheck` |
| any ↔ Omitted (non-identical, not covered below) | `NewOmission` |
| Any → Incorrect result | `NewIncorrectResult` |
| Omitted → Pass / Fail / Warning | `NewPass` / `NewFail` / `NewWarning` |
| Incorrect result → Pass / Fail / Warning | `NewPass` / `NewFail` / `NewWarning` |
| Error → Pass / Fail / Warning (recovered) | `NewPass` / `NewFail` / `NewWarning` |
| Error → N/A (recovered) | `NewManualCheck` |
| MS.PRODUCT.X.XvX → MS.PRODUCT.X.XvX+1 | `PolicyVersionUpdate` |
| No prior policy → New Policy | `NewPolicy` |
| MS.PRODUCT.X.XvX → Null (removed from baseline) | `RemovedPolicy` |
| Any → Error | `Errored` |
| Any → Any (identical result and version) | `Unchanged` (hidden by default) |
| Anything else | `Other` (both literal values preserved) |

The classification appears in the report's **Transition** column. `Result` is treated as
an **open string set**: any value the tool does not recognize (e.g. a future
status) classifies as `Other` with both literal values preserved — it never
crashes the diff.

## Row coloring

Report rows are colored by the **Result (After)** value, so the color reflects
the control's *current* state (not the transition type, which is shown in the
Transition column):

| Result (After) | Row color |
|---|---|
| Fail (or Error) | red |
| Warning | yellow |
| Pass | green |
| N/A (manual) / Omitted / other | grey |
| Removed from baseline (`RemovedPolicy`) | grey (matches manual checks) |

Removed-policy rows are greyed out like manual checks. Policies removed from the
baselines are tracked in
[removedpolicies.md](../../PowerShell/ScubaGear/baselines/removedpolicies.md).

## Annotations (Fail → Fail)

For controls that fail in both runs, `Invoke-SCuBADiff` compares the
`AnnotatedFailedPolicies` entries between the two files and adds three fields to
the record:

- `AnnotationChanged` — `true` if the comment or remediation date differs.
- `Comment` — the after-file comment.
- `RemediationDate` — the after-file anticipated remediation date.

This is intentionally narrow in v1: annotation change detection is only applied
to `Fail → Fail` records, and only the top-level `AnnotatedFailedPolicies` data
is consulted.

## False positives (results marked incorrect)

When an operator marks a policy result as incorrect (a false positive), ScubaGear
rewrites that control's `Result` to the literal `"Incorrect result"`. The diff
recognizes this marking and reports the change in the marking itself:

- A result becoming a false positive is classified `NewIncorrectResult`.
- A false positive being removed is classified by the result it reveals:
  `NewPass`, `NewFail`, or `NewWarning` (and `NewManualCheck` / `NewOmission`
  when the marking clears to N/A or Omitted).
- A stable false-positive marking (marked in both runs) is `Unchanged`.

For any record where either side is marked incorrect, four fields are added:

- `MarkedIncorrectBefore` / `MarkedIncorrectAfter` — whether each side was marked
  a false positive.
- `UnderlyingResultBefore` / `UnderlyingResultAfter` — the tool-computed result
  (`OriginalResult`) on each side, so consumers compare the *real* evaluated
  result rather than the `"Incorrect result"` placeholder.

In the report, the **Transition** column shows the marking change and the
**Result** columns show the underlying result inline (e.g. `Incorrect result
(underlying: Fail)`). `NewIncorrectResult` rows are greyed out; rows where the
marking cleared are colored by the now-visible result (green if passing, red if
still failing).

## The CSV

`DiffResults.csv` is the same data as `DiffResults.json`, flattened to **one row
per policy** for spreadsheets, pivot tables, and other tabular tooling. Unlike
the JSON (keyed by product) and the HTML report (sectioned by product), the CSV
has no nesting, so the product is carried in a leading `Product` column.
Products appear in the same fixed order as the report.

Column names mirror the `DiffResults.json` field names rather than the report's
column titles, so the CSV reads as a flattened view of the JSON:

`Product`, `Control ID (Before)`, `Control ID (After)`, `GroupNumber`,
`GroupName`, `Classification`, `ResultBefore`, `ResultAfter`, `CriticalityBefore`,
`CriticalityAfter`, `Requirement`, `DetailsAfter`, `MarkedIncorrectBefore`,
`MarkedIncorrectAfter`, `UnderlyingResultBefore`, `UnderlyingResultAfter`,
`AnnotationChanged`, `Comment`, `RemediationDate`.

Every row carries every column. The last seven are only meaningful for some
records — the false-positive fields only where a side is marked incorrect, the
annotation fields only for `Fail → Fail` — and are left empty elsewhere, as are
the before/after fields of a `NewPolicy` or `RemovedPolicy` row.

Two differences from the HTML report worth noting:

- **Unchanged rows are included**, not hidden — filter on `Classification` to drop them.
- The `Classification` column carries the raw token (`NewFail`), not the report's
  friendly label ("New Fail").

## The HTML report

- **Unchanged rows are hidden by default.** Use the **"Show unchanged rows"**
  checkbox at the top of the report to reveal them.
- **Per-classification filters live in the summary table.** Every classification in the taxonomy
  has a column — including classifications absent from the current diff — and each column
  header (every classification except `Unchanged`) carries a checkbox. Unchecking a classification
  hides its rows in the per-product tables, dims its column in the summary table,
  and recomputes each product's **Total**. `Unchanged` is filtered separately with
  the **"Show unchanged rows"** toggle above and is always counted in the Total.
- **Dark mode** can be toggled with the **"Dark Mode"** checkbox; `-DarkMode`
  sets its default.
- Rows are color-coded by their Result (After) value (see [Row coloring](#row-coloring)),
  and a per-product summary table shows the count of each classification.
- All policy text is HTML-escaped. The `Requirement` field, which embeds HTML
  indicator markup in `ScubaResults.json`, is stripped to plain text before it
  is stored in `DiffResults.json` / `DiffResults.csv` or rendered.

## Example workflow

```powershell
# 1. Run ScubaGear at two points in time (or on two tenants).
Invoke-SCuBA -ProductNames * -OutPath C:\Runs\Baseline
# ... later ...
Invoke-SCuBA -ProductNames * -OutPath C:\Runs\Current

# 2. Diff the two ScubaResults.json files.
Invoke-SCuBADiff `
    -BeforePath (Get-ChildItem C:\Runs\Baseline -Recurse -Filter ScubaResults_*.json).FullName `
    -AfterPath  (Get-ChildItem C:\Runs\Current  -Recurse -Filter ScubaResults_*.json).FullName `
    -OutPath    C:\Runs\Diff

# 3. Open C:\Runs\Diff\DiffReport.html, and/or consume DiffResults.json
#    (nested, schema-versioned) or DiffResults.csv (one row per policy).
```
