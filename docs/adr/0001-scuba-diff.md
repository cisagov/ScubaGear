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
- ScubaGear is mid-flight consolidating the `Defender` product into
  `SecuritySuite`; a diff can span that rename.
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

The three substantive decisions below were the ones with real alternatives.

### 1. Base-ID matching with a `VersionChanged` bucket (vs. exact full-ID matching)

**Decision:** Match controls on their **base ID** — the Control ID with the
trailing `v<N>` suffix stripped. Same base ID + same version → direct comparison.
Same base ID + different version → a dedicated `VersionChanged` bucket in which
the before/after result comparison is reported but labeled *informational*,
because the policy's meaning changed between runs. Base ID present in only one
file → `New` / `PolicyRemoved`. The `PolicyRemoved` bucket (base ID present in
the before file but absent from the after file) is named to align with the
baselines' `removedpolicies.md`, which tracks policies removed from the SCBs.

**Alternative considered — exact full-ID matching:** treating `MS.AAD.1.1v1` and
`MS.AAD.1.1v2` as unrelated IDs. Rejected because it would report every
version-bumped policy as a simultaneous `PolicyRemoved` (`v1`) + `New` (`v2`),
drowning the real signal in noise and losing the connection between the old and
new form of the same policy. Base-ID matching preserves the connection while the
`VersionChanged` bucket honestly signals that the comparison is not an
authoritative pass→fail delta.

The base-ID regex tolerates both `v1` and a hypothetical `v1.2` form, even though
versions are currently expected to increment only by whole numbers.

### 2. Product-alias map for Defender → Security Suite (vs. retire + new)

**Decision:** Maintain an explicit product-alias map (`Defender` ↔
`SecuritySuite`, the only known entry) and **join** the renamed products,
reporting the joined product under its after-file name with `ProductRenamed: true`
on each record. Policy IDs under the renamed product still follow decision 1.

**Alternative considered — treat the rename as retire + new:** report all
`Defender` controls as `PolicyRemoved` and all `SecuritySuite` controls as `New`.
Rejected for the same reason as exact-ID matching: it manufactures a wall of
false churn across a pure rename and hides the actual per-policy transitions. An
explicit, small alias map is easy to audit and extend if future renames occur.

### 3. Narrow `Fail → Fail` annotation scope (vs. broad annotation diffing)

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

## Consequences

- A new `Modules/Diff` module and one new exported function
  (`Invoke-SCuBADiff`); the manifest `FunctionsToExport` is updated by hand, as
  it is for every other exported function.
- The diff report is built from static assets and does **not** reuse
  `New-Report`, which requires live-run artifacts (provider/Rego JSON, parsed
  baselines) that do not exist in a post-hoc context.
- `DiffResults.json` commits to `SchemaVersion: "1.0"` from day one. The
  `Fail → Fail`-only annotation scope and the single-entry alias map are the most
  likely areas to grow; both can expand additively.
- Unknown `Result` values are handled as `Other` with both literals preserved,
  so new status strings never crash the diff.

## References

- Usage documentation: [docs/execution/diff.md](../execution/diff.md)
- ScubaGoggles `diff` subcommand (schema parity target).
