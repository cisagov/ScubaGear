# Comparing Two ScubaGear Results (Invoke-SCuBADiff)

## Overview

`Invoke-SCuBADiff` compares two `ScubaResults.json` files produced by earlier
ScubaGear runs — a **before** file and an **after** file — and reports how each
policy's result changed between them. It is an offline, post-hoc analysis
command: it performs no authentication, makes no `Connect-*` calls, and never
contacts a tenant. In that respect it works like cached execution
([`Invoke-SCuBACached`](./scubacached.md)) — you point it at existing JSON on
disk — except that instead of a single output path it takes the two source files
directly.

It produces two artifacts:

1. **`DiffResults.json`** — a machine-readable delta describing every policy's
   transition, carrying a top-level `SchemaVersion` for downstream consumers.
2. **`DiffReport.html`** — a self-contained HTML report that highlights the
   transitions with color-coded rows and hides unchanged rows behind a toggle.

The `DiffResults.json` schema is kept intentionally parallel to the
`scubagoggles diff` (ScubaGoggles / Google Workspace) output so that downstream
tools can process both: both share the top-level `SchemaVersion`, `MetaData`,
`Summary`, and `Diff` shapes.

## Usage

Provide the path to the first (earlier) `ScubaResults.json` and the path to the
second (later) `ScubaResults.json`:

```powershell
Invoke-SCuBADiff -BeforePath "C:\Runs\Q1\ScubaResults_abc123.json" `
                 -AfterPath  "C:\Runs\Q2\ScubaResults_def456.json"
```

By default the two artifacts are written to the current directory as
`DiffResults.json` and `DiffReport.html`. Use `-OutPath` to choose a folder
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
| `-OutPath` | No | Current directory | Folder to write the two artifacts to. Created if missing. |
| `-OutJsonFileName` | No | `DiffResults` | Base name (no extension) of the diff JSON. |
| `-OutReportFileName` | No | `DiffReport` | Base name (no extension) of the diff HTML report. |
| `-DarkMode` | No | Off | Default the HTML report to dark theme. |

The command returns an object with `JsonPath` and `ReportPath` pointing at the
two artifacts.

## How controls are matched

M365 policy IDs carry a per-policy version suffix, e.g. `MS.AAD.1.1v1`. That
suffix increments (`v1` → `v2`) when the *meaning* of the policy changes.
`Invoke-SCuBADiff` matches controls on their **base ID** — the ID with the
trailing version suffix removed (`MS.AAD.1.1v1` → `MS.AAD.1.1`):

- **Same base ID, same version** → the results are compared directly.
- **Same base ID, different version** → the change is bucketed as
  `VersionChanged`. Because the policy's meaning changed between the two runs,
  the before/after result comparison is **informational only**, not an
  authoritative pass/fail delta. Both results are still reported and labeled as
  such.
- **Base ID present in only one file** → `New` (only in *after*) or
  `PolicyRemoved` (only in *before*). A base ID present in the before file but
  absent from the after file corresponds to a policy that was removed from the
  baseline — see the baselines'
  [removedpolicies.md](../../PowerShell/ScubaGear/baselines/removedpolicies.md).

  > **Note:** `PolicyRemoved` is inferred purely from presence — a base ID that
  > appears in the before file but not the after file. That usually means the
  > policy was removed from the baseline, but it can also occur when the after
  > run simply did not assess that control or product (for example, comparing two
  > runs with different `-ProductNames`). Cross-reference `removedpolicies.md`
  > when you need to distinguish a genuine baseline removal from a control that
  > was merely not evaluated.

## The Security Suite consolidation (standalone, not a rename)

ScubaGear is consolidating many `Defender`, `Exchange Online`, and `Teams`
policies into the new `Security Suite` product. `Invoke-SCuBADiff` does **not**
treat this as a product rename or join the products. Products are matched by name
only, so a diff that spans the consolidation reports the old policies (in
`Defender` / `EXO` / `Teams`) as standalone `PolicyRemoved` and the new
`SecuritySuite` policies as standalone `New`.

This is deliberate: the consolidation reworked the policies and their assessments,
so the new `MS.SECURITYSUITE.*` controls are genuinely new policies, not renamed
copies of the old ones. Treating them as standalone keeps the comparison honest
rather than implying a 1:1 equivalence that no longer holds.

## Transition taxonomy

Every base control ID present in either file is classified into exactly one
bucket. Precedence, highest to lowest:
`Errored` > `VersionChanged` > `OmissionChanged` >
`MarkedIncorrect` / `IncorrectResolved` > specific transitions >
`Other` > `Unchanged`. `New` / `PolicyRemoved` are determined by presence.

| Before → After | Bucket |
|---|---|
| Pass → Fail | `Regression` |
| Fail → Pass | `Remediated` |
| Warning → Pass | `WarningResolved` |
| Warning → Fail | `WarningEscalated` |
| Pass/Fail → Warning | `NewWarning` |
| N/A → Pass/Fail/Warning | `NewlyAutomated` |
| Pass/Fail/Warning → N/A | `NewlyManual` |
| any ↔ Omitted (non-identical) | `OmissionChanged` |
| (not incorrect) → Incorrect result | `MarkedIncorrect` |
| Incorrect result → (not incorrect) | `IncorrectResolved` |
| Same base ID, different version | `VersionChanged` |
| Base ID absent → present | `New` |
| Base ID present → absent (removed from baseline) | `PolicyRemoved` |
| any ↔ Error | `Errored` |
| X → X (identical result and version) | `Unchanged` (hidden by default) |
| Anything else | `Other` (both literal values preserved) |

The bucket appears in the report's **Transition** column. `Result` is treated as
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
| Removed from baseline (`PolicyRemoved`) | grey (matches manual checks) |

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

- A result becoming a false positive is bucketed `MarkedIncorrect`.
- A false positive being removed is bucketed `IncorrectResolved`.
- A stable false-positive marking (marked in both runs) is `Unchanged`.

For any record where either side is marked incorrect, four fields are added:

- `MarkedIncorrectBefore` / `MarkedIncorrectAfter` — whether each side was marked
  a false positive.
- `UnderlyingResultBefore` / `UnderlyingResultAfter` — the tool-computed result
  (`OriginalResult`) on each side, so consumers compare the *real* evaluated
  result rather than the `"Incorrect result"` placeholder.

In the report, the **Transition** column shows the marking change and the
**Result** columns show the underlying result inline (e.g. `Incorrect result
(underlying: Fail)`). `MarkedIncorrect` rows are greyed out; `IncorrectResolved`
rows are colored by the now-visible result (green if passing, red if still
failing).

## The HTML report

- **Unchanged rows are hidden by default.** Use the **"Show unchanged rows"**
  checkbox at the top of the report to reveal them.
- **Dark mode** can be toggled with the **"Dark Mode"** checkbox; `-DarkMode`
  sets its default.
- Rows are color-coded by their Result (After) value (see [Row coloring](#row-coloring)),
  and a per-product summary table shows the count of each bucket.
- All policy text is HTML-escaped. The `Requirement` field, which embeds HTML
  indicator markup in `ScubaResults.json`, is stripped to plain text before it
  is stored in `DiffResults.json` or rendered.

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

# 3. Open C:\Runs\Diff\DiffReport.html and/or consume DiffResults.json.
```
