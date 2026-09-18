# Config Analyzer (`Start-SCuBAConfigAnalyzer`)

The Config Analyzer inspects a Microsoft 365 tenant's Conditional Access and related settings and
tells you **exactly what to change to pass ScubaGear** - including generating a ready-to-use
ScubaGear configuration file that waives justified exclusions (such as break-glass accounts).

It is part of the [ScubaConfigApp module](scubaconfigapp.md) and is launched with:

```powershell
Start-SCuBAConfigAnalyzer
```

> Developers: for how the analyzer's rules stay in sync with the Rego policies, see
> [Scuba Config Analyzer for developers](../misc/scubaconfiganalyzer-for-developers.md).

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

## Walkthrough: using the analyzer

### Step 1 - Choose what to analyze

The toolbar across the top controls the scan:

- **Products** - check the products to analyze (only products that support config exclusions are
  listed, e.g. *Microsoft Entra ID (aad)*, *Exchange Online (exo)*, *Security Suite
  (securitysuite)*).
- **Environment** - `commercial`, `gcc`, `gcchigh`, or `dod`. This also sets the
  `M365Environment` value written into the generated YAML.
- **Connect & Scan Tenant** - signs in to Microsoft Graph (and Exchange Online if a selected
  product needs it) and scans the tenant live.
- **Load Results JSON...** - skips the sign-in and analyzes an existing `ScubaResults_*.json`
  from a previous ScubaGear run.

The header shows the tenant, how you are connected, the scan time, and the analyzer version.
While a scan runs, the window switches to the **Activity Log** tab so you can watch progress.

### Step 2 - Read the findings list (left pane)

The summary above the list tells you the shape of the run, for example:

```text
18 controls, 16 need attention
Pass 2 | Fail 10 | Warn 0 | Error 0 | Manual 6 | 11.1% compliant
```

Each row is one baseline control with its ID, its requirement text, and a colored result badge:

| Badge | Meaning |
| --- | --- |
| **Pass** | The control already meets the baseline. |
| **Fail** | The control does not meet the baseline. |
| **Warning** / **Error** | The control could not be fully evaluated (for example, missing permissions). |
| **Manual** | The control is not machine-checkable and must be verified by hand. |

Narrow the list with:

- **Issues only** - hide controls that already pass.
- **Configurable only** - show only controls a ScubaGear config file could make pass with
  exclusions or allow-lists.
- **Search** - filter by control ID or requirement text.

Click a row to open its detail on the right.

### Step 3 - Understand a finding (right pane)

For the selected control you get:

- **Root cause** - a plain-language explanation of why it failed, the underlying ScubaGear
  detail, and the action the analyzer thinks is required (for example `ADD_EXCLUSIONS`,
  `FIX_POLICY`, or `CREATE_POLICY`).
- **Recommendations** - what to do next in one or two sentences.
- **View baseline policy** - opens the ScubaGear baseline text for this control so you can read
  the original requirement.
- **Step-by-step remediation** - the portal steps to fix the tenant, shown when a tenant change
  is required.

### Step 4 - Confirm the matching Conditional Access policy

For Conditional Access controls, **Matching Conditional Access policies** lists every policy that
could satisfy the control. Each card shows the policy name, its state, how many issues it has,
and - when expanded - the users, groups, or applications it excludes.

- The **BEST MATCH** badge marks the policy the analyzer picked automatically.
- The **IN USE** badge marks the policy the generated YAML is currently based on.
- If the analyzer chose the wrong policy, expand another card and click **Use this policy**. The
  exclusions from that policy are used instead, and both the control YAML and the full
  configuration are regenerated immediately.

### Step 5 - Review the generated exclusions

The **Control YAML** box at the bottom of the detail pane shows the exact snippet the analyzer
would add for this one control, with each excluded object ID annotated with its display name:

```yaml
Aad:
  # If phishing-resistant MFA has not been enforced, an alternative MFA method SHALL be enforced for all users
  # CA policy: CA002C-Global-IdentityProtection-AllApps-AnyPlatform-StrongMFA-AllUsers
  MS.AAD.3.2v2:
    CapExclusions:
      Groups:
        - 3acb812b-...  # SG-ADServiceAccounts-Exclude-Users
        - e8525a88-...  # SG-Exclude-BreakGlassAccounts
```

Use **Copy** to take just this snippet. If the control does not support exclusions, the box
explains that instead and points you at the remediation steps.

> Keep only the exclusions you can **justify** - documented break-glass accounts, approved
> service accounts, and so on. Delete the rest and fix the tenant instead.

### Step 6 - Take the configuration

The **Configuration YAML** tab assembles every control's exclusions into one ScubaGear
configuration file. From there you can:

- **Open ScubaConfig App** - launch the [ScubaConfig App](scubaconfigapp.md) with this
  configuration already loaded, so you can add org details, justifications, and omissions.
- **Copy all** - copy the whole file to the clipboard.
- **Export YAML...** - save it as a `.yaml` file (default name `ScubaGearConfig.yaml`) to pass to
  `Invoke-SCuBA -ConfigFilePath`.

The configuration is regenerated whenever you rescan, change the environment, or click **Use this
policy**, so make your selections first and export last.

### Step 7 - Verify with a real ScubaGear run

Re-run ScubaGear with the exported configuration to confirm the results, especially after a live
scan - the analyzer's live verdict is predictive, not authoritative.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| Controls show **Warning** or **Error** | Check the **Activity Log** tab - the scan usually lacked a Graph permission or the Exchange Online connection failed. |
| A control has no **Control YAML** | That control cannot be waived through configuration. Follow the remediation steps, or omit the policy with a justification in the ScubaConfig App. |
| The wrong Conditional Access policy was matched | Expand the correct card and click **Use this policy**. |
| The exported YAML is missing exclusions you expected | Confirm the product is checked in the toolbar and that **Configurable only** is not hiding the control you are looking for. |
