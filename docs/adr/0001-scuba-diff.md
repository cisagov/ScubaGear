# ADR 0001: `Invoke-SCuBADiff` — comparing two ScubaResults files

- **Status:** Accepted
- **Date:** 2026-07-13
- **Deciders:** ScubaGear maintainers

## Context

Operators frequently need to answer "what changed between these two ScubaGear
runs?" — across time on one tenant, across two tenants, or across a ScubaGear
version upgrade. Until now this required manual diffing of `ScubaResults.json`
files or eyeballing two HTML reports side by side. ScubaGoggles (the Google
Workspace sibling tool) already ships a `diff` subcommand; ScubaGear needs a
counterpart that produces a comparable, machine-readable delta plus a human
report.

Several properties of M365 `ScubaResults.json` shape the design:

- Policy IDs carry a per-policy version suffix (`MS.AAD.1.1v1`) that increments
  when the policy's *meaning* changes.
- The `Requirement` field embeds HTML indicator markup.
- `Result` is effectively an open string set (`Pass`, `Fail`, `Warning`, `N/A`,
  plus `Error`/`Omitted` from report post-processing, and potentially new values
  in the future).

## Decision

Add an exported, fully-offline cmdlet `Invoke-SCuBADiff` in a new, dependency-free
`Modules/Diff` module. It reads two `ScubaResults.json` files and emits
`DiffResults.json` (with a top-level `SchemaVersion: "1.0"`), `DiffResults.csv`,
and a self-contained `DiffReport.html`. The `DiffResults.json` top-level shape
(`SchemaVersion`, `MetaData`, `Summary`, `Diff`) is kept parallel to the
ScubaGoggles `diff` output so downstream consumers can process both.

The CSV is a lossy-by-design convenience view: the JSON stays the authoritative,
schema-versioned artifact, while the CSV flattens `Diff` to one row per policy
(product as a leading column) for spreadsheet users, carrying no `MetaData` or
`Summary`. It is derived from the same records as the other two artifacts rather
than from a second comparison pass, so the three cannot disagree.

The two substantive decisions below were the ones with real alternatives.

### 1. Base-ID matching with a `PolicyVersionUpdate` classification (vs. exact full-ID matching)

**Decision:** Match controls on their **base ID** — the Control ID with the
trailing `v<N>` suffix stripped. Same base ID + same version → direct comparison.
Same base ID + different version → a dedicated `PolicyVersionUpdate` classification in
which the before/after result comparison is reported but labeled *informational*,
because the policy's meaning changed between runs. Base ID present in only one
file → `NewPolicy` / `RemovedPolicy`. The `RemovedPolicy` classification (base ID present
in the before file but absent from the after file) is named to align with the
baselines' `removedpolicies.md`, which tracks policies removed from the SCBs.

**Alternative considered — exact full-ID matching:** treating `MS.AAD.1.1v1` and
`MS.AAD.1.1v2` as unrelated IDs. Rejected because it would report every
version-bumped policy as a simultaneous `RemovedPolicy` (`v1`) + `NewPolicy`
(`v2`), drowning the real signal in noise and losing the connection between the
old and new form of the same policy. Base-ID matching preserves the connection
while the `PolicyVersionUpdate` classification honestly signals that the comparison is
not an authoritative pass→fail delta.

The base-ID regex tolerates both `v1` and a hypothetical `v1.2` form, even though
versions are currently expected to increment only by whole numbers.

### 2. Narrow `Fail → Fail` annotation scope (vs. broad annotation diffing)

**Decision:** Compare annotations only for `Fail → Fail` records, and only from
the top-level `AnnotatedFailedPolicies` dictionary, surfacing
`AnnotationChanged` plus the after-file `Comment` and `RemediationDate`.

**Alternative considered — diff annotations across all diffs and both
annotation locations** (`AnnotatedFailedPolicies` *and* the per-control
`Comments` / `ResolutionDate`). Rejected for v1: the per-control fields derive
from the same config input as `AnnotatedFailedPolicies`, so comparing both is
redundant, and annotation changes are only meaningful for policies that remain
failing. Keeping the scope narrow avoids speculative logic and keeps the record
schema small. This can be widened later without breaking the schema.

**Extension — false positives (results marked incorrect).** A separate but
related annotation is the "marked incorrect" flag, which ScubaGear surfaces by
rewriting the control's `Result` to the literal `"Incorrect result"`. Rather than
letting that placeholder fall through to `Other`, the diff recognizes it as its
own category: a result becoming a false positive is `NewIncorrectResult`, a
marking that clears is classified by the result it reveals (`NewPass` / `NewFail` /
`NewWarning`), and a stable marking stays `Unchanged`. For these records the diff also carries
`MarkedIncorrect{Before,After}` and `UnderlyingResult{Before,After}` (from
`OriginalResult`) so consumers compare the real evaluated result, not the
placeholder. This was chosen over treating `"Incorrect result"` as an opaque
`Other` string because false positives moving between runs is exactly the kind of
operator-relevant change the diff exists to surface.

### 3. Defender-only alignment of the Security Suite migration (vs. mapping the whole CSV)

**Decision:** Carry a fixed 13-entry table, embedded in `Diff.psm1` and keyed by
base control ID, that aligns retired Defender policies with the Security Suite
policies that replaced them. A matched before-side control is relocated into the
Security Suite product and compared there. The record is classified by its
**result** like any other pair, with `Migrated` / `MigratedFromId` /
`MigratedFromProduct` fields (and a report badge) marking that the comparison
spans the migration. The `PolicyVersionUpdate` check is skipped for these
records, since the two IDs come from different policy families and their version
suffixes are not comparable. A direct base-ID match always wins over the alias,
so two post-migration runs — or a transitional run carrying both forms — are
compared as-is.

The table is the Defender→SecuritySuite subset of
`mappings\scuba-baseline-policy-migrations.csv`, which is one-to-one. Three
groups of rows are deliberately excluded and fall through to `RemovedPolicy`:
`MS.DEFENDER.1.1v1`–`1.5v1` (each split across several Security Suite policies,
so no single target exists), `MS.DEFENDER.4.5v1` (retired outright), and every
EXO/Teams row.

**Alternative considered — mapping every row in the CSV.** Rejected because the
EXO and Teams rows are many-to-one (five old IDs collapse onto
`MS.SECURITYSUITE.3.1v1` alone), which would force a record shape that either
duplicates the after result across N rows or invents an aggregation rule for
disagreeing before results. Those policies are also manual checks that only ever
produced `N/A`, so the aligned comparison would carry no signal to justify the
complexity. Reporting them as `RemovedPolicy` is both simpler and more honest.

**Alternative considered — a dedicated `PolicyMigration` classification**
(parallel to `PolicyVersionUpdate`). Rejected because it would collapse all 13
into one informational bucket, hiding a genuine `Pass → Fail` across the
migration — exactly the posture change the diff exists to surface. The marker
fields keep both signals.

**Alternative considered — reading the CSV at runtime.** Rejected for v1: it
would add a file dependency and range/`None` parsing to a module the ADR
deliberately keeps self-contained, to express 13 pairs that are reviewable in a
PR diff. The table must be updated by hand if the CSV grows.

## Consequences

- A new `Modules/Diff` module and one new exported function
  (`Invoke-SCuBADiff`); the manifest `FunctionsToExport` is updated by hand, as
  it is for every other exported function.
- The diff report is built from static assets and does **not** reuse
  `New-Report`, which requires live-run artifacts (provider/Rego JSON, parsed
  baselines) that do not exist in a post-hoc context.
- `DiffResults.json` commits to `SchemaVersion: "1.0"` from day one. The
  `Fail → Fail`-only annotation scope is the most likely area to grow; it can
  expand additively.
- Unknown `Result` values are handled as `Other` with both literals preserved,
  so new status strings never crash the diff.
- The Defender→SecuritySuite migration table is a hand-maintained copy of a
  subset of `scuba-baseline-policy-migrations.csv`; a future migration wave needs
  a corresponding edit to `Diff.psm1`. The record fields it adds (`Migrated`,
  `MigratedFromId`, `MigratedFromProduct`) are additive to `SchemaVersion 1.0`.
- A product left with no records once migration has moved its before side
  elsewhere is dropped from the output rather than rendered as an empty section.

## References

- Usage documentation: [docs/execution/diff.md](../execution/diff.md)
- ScubaGoggles `diff` subcommand (schema parity target).
