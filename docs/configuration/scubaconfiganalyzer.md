# Config Analyzer (`Start-SCuBAConfigAnalyzer`)

The Config Analyzer inspects a Microsoft 365 tenant's Conditional Access and related settings and
tells you **exactly what to change to pass ScubaGear** - including generating a ready-to-use
ScubaGear configuration file that waives justified exclusions (such as break-glass accounts).

It is part of the [ScubaConfigApp module](scubaconfigapp.md) and is launched with:

```powershell
Start-SCuBAConfigAnalyzer
```

> Developers: for how the analyzer's rules stay in sync with the Rego policies, see
> [Config Analyzer schema maintenance](../misc/scubaconfiganalyzer-schema-maintenance.md).

## What it does

For each failing or at-risk control it identifies:

- the **root cause** (missing policy, wrong setting, or a config-waivable exclusion),
- **how to make it pass** - one of: already passing, add exclusions to the ScubaGear config, fix
  the tenant setting, or create a new policy,
- the **excluded users / groups / applications** it detected, resolved to friendly display names,
- a generated **ScubaGear config YAML** block containing those exclusions.

## What it does *not* do

- It does not change your tenant. It only reads settings and produces guidance/config.
- It does not generate policy **omissions** - only exclusions/allow-lists.
- It does not create Conditional Access policies for you (it can show the payload it would use).

## Two ways to run it

| Mode | How | Source of the pass/fail verdict | When to use |
| --- | --- | --- | --- |
| **Offline (analyze a prior run)** | Point it at an existing `ScubaResults_*.json` (`Invoke-ScubaConfigAnalysis`). | ScubaGear's own results - the verdict is authoritative. | After a normal ScubaGear run, to triage failures and auto-build a config with justified exclusions. |
| **Live (scan the tenant now)** | Read Microsoft Graph directly (`Invoke-ScubaTenantScan`) - no ScubaGear run required. | The analyzer's own evaluation of the baseline rules (a predictive check). | A quick pre-check before running ScubaGear, or when you don't have a results file handy. |

> In live mode the verdict is **predictive**: it is computed from the analyzer's copy of the
> baseline rules, not from OPA/Rego. Always confirm with a full ScubaGear run before treating a
> live-mode "pass" as final.

## Primary use cases

### 1. Triage a failed ScubaGear run and generate a config

Run ScubaGear, then open the analyzer against the results. It groups the failures, shows which
ones are waivable via configuration, and emits a `ScubaConfig` YAML with the detected exclusions
(annotated with the display names of the excluded principals) so you can review and keep only the
justified ones.

### 2. Pre-check a tenant before running ScubaGear

Use live mode to see the likely failures and required changes without waiting for a full
assessment. Useful during remediation to quickly gauge whether a change had the intended effect.

### 3. Produce a starter ScubaGear configuration

Use the generated YAML as the starting point for your organization's ScubaGear config file,
adding justifications for each exclusion before committing it.

## Reviewing the output

Every finding tells you the `ConfigAction`:

| ConfigAction | Meaning |
| --- | --- |
| `NONE` | The control already passes. |
| `EXCLUDE` | Adding the detected exclusions to your ScubaGear config will make it pass. The analyzer emits the YAML. |
| `FIX_TENANT` | Configuration cannot make this pass - the tenant setting itself must change (see the remediation steps), or omit the policy in the ScubaConfig App. |
| `REVIEW` / `MANUAL` | Needs manual review (e.g. controls evaluated outside Conditional Access). |

Only exclusions you can **justify** (for example, documented break-glass accounts) should be kept
in the final configuration.
