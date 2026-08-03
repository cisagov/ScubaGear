# Config Analyzer Schema Maintenance (Rego ↔ JSON)

This guide is for **ScubaGear developers**. It explains how the `Start-SCuBAConfigAnalyzer`
cmdlet's baseline rules relate to the Rego policies, and exactly what a developer must do to
keep the two in sync when a policy implementation changes.

> If you are a user looking for how to *run* the analyzer, see
> [Config Analyzer usage](../configuration/scubaconfiganalyzer.md) instead.

## Why this document exists

The analyzer needs a machine-readable description of "what makes a control pass" so it can
tell a tenant admin *what to change* to pass ScubaGear. Today that description lives in a JSON
schema that is authored **in parallel** with the Rego. Because the same pass conditions are
expressed twice (once in Rego, once in JSON), the two can drift apart if only one is updated.
This document defines the maintenance contract that prevents that drift, and a CI test enforces
the structural half of it automatically.

## The pieces

| File | Role |
| --- | --- |
| `PowerShell/ScubaGear/Rego/<Product>Config.rego` | **Authoritative.** The pass/fail logic ScubaGear actually runs via OPA. |
| `PowerShell/ScubaGear/schemas/ScubaGearResultsBaselineSchema.json` | Per-control validation logic the analyzer reads (`requirements`, `requiredSettings`, `remediationSteps`, `buildInstructions`). **This is the file that must be kept in sync with Rego.** |
| `PowerShell/ScubaGear/Modules/ScubaConfigApp/ScubaConfigAnalyzer/ScubaGearAnalyzerSchema_en-US.json` | Analyzer-only rules (product map, friendly names, Graph operations, CA condition interpretation). Rarely changes for a policy edit. |
| `PowerShell/ScubaGear/Modules/ScubaConfigApp/ScubaConfigAnalyzer/ScubaConfigAnalyzerEngine.psm1` | A generic **interpreter** of the two JSON files. It is not policy-specific and normally does **not** change when a policy changes. |

The engine hard-codes nothing about individual policies. To add or change a control you edit the
JSON, not the `.psm1`.

## Important: drift severity depends on how the analyzer is invoked

The analyzer has two entry points, and they use the JSON very differently. Understanding this
tells you how urgent a given sync gap is.

| Mode | Cmdlet / entry point | Where the pass/fail verdict comes from | Effect of JSON drift |
| --- | --- | --- | --- |
| **Offline** | `Invoke-ScubaConfigAnalysis` (reads an existing `ScubaResults_*.json`) | ScubaGear's own Rego verdict, read straight from the results file (`$control.Result`). | The JSON only drives remediation guidance and exclusion detection. Drift can produce **worse advice**, but it can **never flip the pass/fail verdict** - that always comes from ScubaGear. |
| **Live** | `Invoke-ScubaTenantScan` (reads Microsoft Graph directly, no ScubaGear run) | Derived from the JSON `requirements` via `Get-ScAActionClassification` → `Get-ScAPolicyAnalysis`. | The JSON **is** the pass/fail logic - a re-implementation of the Rego. Drift here **can produce a wrong verdict.** |

Takeaway: the live-scan path is where sync matters most. When you change a Rego policy, treat the
JSON update as required, and pay closest attention to controls that live-scan can evaluate
(`validationLogic.type: conditionalAccessPolicy`).

## How a Rego rule maps to the JSON `requirements`

Each Rego `tests contains { "PolicyId": ... }` block corresponds to exactly one control object
in `ScubaGearResultsBaselineSchema.json` whose `id` equals that `PolicyId`. The conditions in the
Rego rule body map to the JSON `requirements` like this:

| Rego expression | JSON `requirements` path |
| --- | --- |
| `ContainsValue(CAPolicy.Conditions.Users.IncludeUsers, "All")` | `conditions.users.includeUsers: ["All"]` |
| `ContainsValue(CAPolicy.Conditions.Applications.IncludeApplications, "All")` | `conditions.applications.includeApplications: ["All"]` |
| `CAPolicy.State == "enabled"` | `state: "enabled"` |
| `"X" in CAPolicy.Conditions.ClientAppTypes` | `conditions.clientAppTypes: ["X", ...]` |
| `"high" in CAPolicy.Conditions.UserRiskLevels` | `conditions.userRiskLevels: ["high"]` |
| `"block" in CAPolicy.GrantControls.BuiltInControls` | `grantControls.builtInControls: ["block"]` |
| `...FullyExempt(CAPolicy, "MS.AAD.x.yvz")` (exclusion handling) | `exclusionField` + the `exclusionDetectors` rules in `ScubaGearAnalyzerSchema_en-US.json` |

Paths are camelCase in the JSON; the engine navigates them case-insensitively so both raw Graph
(camelCase) and ScubaResults (PascalCase) policy objects work.

## Worked example: editing `MS.AAD.1.1v1` (block legacy authentication)

### 1. The Rego (authoritative)

From `PowerShell/ScubaGear/Rego/AADConfig.rego`:

```rego
LegacyAuthentication contains CAPolicy.DisplayName if {
    some CAPolicy in input.conditional_access_policies

    ### Common checks for conditional access policies
    ContainsValue(CAPolicy.Conditions.Users.IncludeUsers, "All") == true
    ContainsValue(CAPolicy.Conditions.Applications.IncludeApplications, "All") == true
    Count(CAPolicy.Conditions.Users.ExcludeRoles) == 0
    CAPolicy.State == "enabled"
    ###

    ### Conditional access checks specific to this policy
    "other" in CAPolicy.Conditions.ClientAppTypes
    "exchangeActiveSync" in CAPolicy.Conditions.ClientAppTypes
    "block" in CAPolicy.GrantControls.BuiltInControls
    ###

    UserExclusionsFullyExempt(CAPolicy, "MS.AAD.1.1v1") == true
    GroupExclusionsFullyExempt(CAPolicy, "MS.AAD.1.1v1") == true
    AppExclusionsFullyExempt(CAPolicy, "MS.AAD.1.1v1") == true
    GuestUserExclusionsFullyExempt(CAPolicy, "MS.AAD.1.1v1") == true
}
```

### 2. The matching JSON control

From `PowerShell/ScubaGear/schemas/ScubaGearResultsBaselineSchema.json`, the object whose
`id` is `MS.AAD.1.1v1`:

```json
"validationLogic": {
  "type": "conditionalAccessPolicy",
  "requiresPolicy": true,
  "policyMustExist": true,
  "requirements": {
    "state": "enabled",
    "conditions": {
      "users": { "includeUsers": ["All"] },
      "applications": { "includeApplications": ["All"] },
      "clientAppTypes": ["exchangeActiveSync", "other"]
    },
    "grantControls": { "builtInControls": ["block"], "operator": "OR" }
  }
},
"requiredSettings": {
  "state": "enabled",
  "conditions.users.includeUsers": ["All"],
  "conditions.applications.includeApplications": ["All"],
  "conditions.clientAppTypes": ["exchangeActiveSync", "other"],
  "grantControls.builtInControls": ["block"],
  "grantControls.operator": "OR"
}
```

The Rego rule body and the JSON `requirements` describe the same thing. `requiredSettings` is the
flattened, dotted-path form used for display and `buildInstructions.payloadTemplate` is the CA
policy the analyzer would suggest creating.

### 3. Now suppose you change the Rego

Say policy 1.1 is revised to also require a fourth client app type, `"easSupported"`. You edit the
Rego rule to add:

```rego
"easSupported" in CAPolicy.Conditions.ClientAppTypes
```

You **must** make the corresponding JSON edits in the `MS.AAD.1.1v1` object:

1. `validationLogic.requirements.conditions.clientAppTypes` → add `"easSupported"`.
2. `requiredSettings."conditions.clientAppTypes"` → add `"easSupported"`.
3. `buildInstructions.payloadTemplate.conditions.clientAppTypes` → add `"easSupported"` so a
   generated "create this policy" template still passes.
4. `remediationSteps` → update the human step that lists the client apps to select.
5. If the version string changed (e.g. `v1` → `v2`), rename the control `id` **and** confirm the
   Rego `PolicyId` uses the same new id. The CI drift test (below) fails if they disagree.

After those edits, the `MS.AAD.1.1v1` object looks like this (the `+` lines are the additions;
they are not part of the JSON, just markers to show what changed):

```jsonc
{
  "id": "MS.AAD.1.1v1",
  "exclusionField": "CapExclusions",
  "validationLogic": {
    "type": "conditionalAccessPolicy",
    "requiresPolicy": true,
    "policyMustExist": true,
    "requirements": {
      "state": "enabled",
      "conditions": {
        "users": { "includeUsers": ["All"] },
        "applications": { "includeApplications": ["All"] },
        "clientAppTypes": ["exchangeActiveSync", "other", "easSupported"]  // + easSupported
      },
      "grantControls": { "builtInControls": ["block"], "operator": "OR" }
    }
  },
  "requiredSettings": {
    "state": "enabled",
    "conditions.users.includeUsers": ["All"],
    "conditions.applications.includeApplications": ["All"],
    "conditions.clientAppTypes": ["exchangeActiveSync", "other", "easSupported"],  // + easSupported
    "grantControls.builtInControls": ["block"],
    "grantControls.operator": "OR"
  },
  "buildInstructions": {
    "payloadTemplate": {
      "displayName": "ScubaGear: Block Legacy Authentication",
      "state": "enabled",
      "conditions": {
        "users": { "includeUsers": ["All"], "excludeUsers": [], "excludeGroups": [] },
        "applications": { "includeApplications": ["All"] },
        "clientAppTypes": ["exchangeActiveSync", "other", "easSupported"]  // + easSupported
      },
      "grantControls": { "operator": "OR", "builtInControls": ["block"] }
    }
  },
  "remediationSteps": [
    "...",
    "7. Conditions: Client apps -> select 'Exchange ActiveSync clients', 'Other clients', and 'EAS supported'"
  ]
}
```

> The real file is strict JSON (no comments and more fields). The `// + easSupported` markers and
> the `"..."` placeholders above are only to highlight the three arrays you touch and the one
> remediation line you reword. Everything else in the object is unchanged.

Nothing in `ScubaConfigAnalyzerEngine.psm1` needs to change - it reads these fields generically.

## Change checklist (paste into your PR description)

When a Rego policy's pass conditions change, verify each item for the affected control(s):

- [ ] `validationLogic.requirements` updated to match the new Rego conditions.
- [ ] `requiredSettings` (flattened dotted paths) updated to match.
- [ ] `buildInstructions.payloadTemplate` still produces a *passing* policy under the new rule.
- [ ] `remediationSteps` reflect the new required settings in plain English.
- [ ] If the policy `id`/version changed, the JSON `id` and the Rego `PolicyId` match exactly.
- [ ] If exclusion behavior changed, check `exclusionField` and the `exclusionDetectors` in
      `ScubaGearAnalyzerSchema_en-US.json`.
- [ ] `Testing/Unit/PowerShell/ScubaConfigApp/ScubaConfigAnalyzerSchemaSync.Tests.ps1` passes.

## What CI enforces for you

`Testing/Unit/PowerShell/ScubaConfigApp/ScubaConfigAnalyzerSchemaSync.Tests.ps1` runs on every PR
and asserts the **structural** half of the contract:

- Every control `id` in `ScubaGearResultsBaselineSchema.json` exists as a real `PolicyId` in the
  Rego. This catches renamed, removed, or mistyped ids - the most common way the JSON goes stale.
- Control ids are well-formed (`MS.<PRODUCT>.<group>.<item>v<version>`) and unique.
- It also prints an informational coverage list of Rego `PolicyId`s the analyzer does **not** yet
  model (this is expected - the analyzer intentionally covers a subset - so it does not fail CI).

CI cannot detect **semantic** drift (e.g. Rego adds a required `clientAppType` but the JSON keeps
the old list), because it does not execute the Rego. That is what the change checklist above is
for. If you want a stronger guard, add a fixture that runs ScubaGear against sample tenant data
and asserts the analyzer's live-mode verdict matches ScubaGear's verdict for the same input.

## Non–Conditional-Access controls

Some controls use other `validationLogic.type` values (for example `roleAssignmentAnalysis`,
`teamsMeetingPolicy`, `exchangeTransportConfig`, `identityProtectionSetting`,
`authenticationMethodConfiguration`). These map to their product's provider output rather than CA
policies, but the same rule applies: the `requirements`/`requiredSettings` for the control must
match what the corresponding Rego rule checks. Products whose `baselineValidations` array is empty
(e.g. `securitysuite`, `sharepoint`, `powerbi`, `powerplatform`) are placeholders the analyzer does
not evaluate yet; adding controls there is how you extend coverage.
