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
`DiffResults.json` (with a top-level `SchemaVersion: "1.0"`) and a self-contained
`DiffReport.html`. The `DiffResults.json` top-level shape (`SchemaVersion`,
`MetaData`, `Summary`, `Diff`) is kept parallel to the ScubaGoggles `diff` output
so downstream consumers can process both.

The two substantive decisions below were the ones with real alternatives.

### 1. Base-ID matching with a `PolicyVersionUpdate` bucket (vs. exact full-ID matching)

**Decision:** Match controls on their **base ID** — the Control ID with the
trailing `v<N>` suffix stripped. Same base ID + same version → direct comparison.
Same base ID + different version → a dedicated `PolicyVersionUpdate` bucket in
which the before/after result comparison is reported but labeled *informational*,
because the policy's meaning changed between runs. Base ID present in only one
file → `NewPolicy` / `RemovedPolicy`. The `RemovedPolicy` bucket (base ID present
in the before file but absent from the after file) is named to align with the
baselines' `removedpolicies.md`, which tracks policies removed from the SCBs.

**Alternative considered — exact full-ID matching:** treating `MS.AAD.1.1v1` and
`MS.AAD.1.1v2` as unrelated IDs. Rejected because it would report every
version-bumped policy as a simultaneous `RemovedPolicy` (`v1`) + `NewPolicy`
(`v2`), drowning the real signal in noise and losing the connection between the
old and new form of the same policy. Base-ID matching preserves the connection
while the `PolicyVersionUpdate` bucket honestly signals that the comparison is
not an authoritative pass→fail delta.

The base-ID regex tolerates both `v1` and a hypothetical `v1.2` form, even though
versions are currently expected to increment only by whole numbers.

### 2. Narrow `Fail → Fail` annotation scope (vs. broad annotation diffing)

**Decision:** Compare annotations only for `Fail → Fail` records, and only from
the top-level `AnnotatedFailedPolicies` dictionary, surfacing
`AnnotationChanged` plus the after-file `Comment` and `RemediationDate`.

**Alternative considered — diff annotations across all transitions and both
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
marking that clears is bucketed by the result it reveals (`NewPass` / `NewFail` /
`NewWarning`), and a stable marking stays `Unchanged`. For these records the diff also carries
`MarkedIncorrect{Before,After}` and `UnderlyingResult{Before,After}` (from
`OriginalResult`) so consumers compare the real evaluated result, not the
placeholder. This was chosen over treating `"Incorrect result"` as an opaque
`Other` string because false positives moving between runs is exactly the kind of
operator-relevant change the diff exists to surface.

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

## References

- Usage documentation: [docs/execution/diff.md](../execution/diff.md)
- ScubaGoggles `diff` subcommand (schema parity target).
