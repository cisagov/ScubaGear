# Transitioning from Defender to the Security Suite Baseline

Recent versions of ScubaGear consolidate the Microsoft Defender baseline (and several Exchange Online and Microsoft Teams policies) into a new **Security Suite** baseline. As part of this change:

- The **`defender`** product has been **renamed to `securitysuite`**.
- Many `MS.DEFENDER.*`, `MS.EXO.*`, and `MS.TEAMS.*` policies were **decoupled and migrated** into new `MS.SECURITYSUITE.*` policies. Some old policies map to a single combined Security Suite policy, some were split across several new policies, and a few were removed entirely.

If you have existing configuration files that reference `defender` or any of the migrated policy IDs, you must update them to use the Security Suite product name and the new policy IDs.

> [!TIP]
> The easiest way to build or update a configuration file is with the **[Configuration UI](scubaconfigapp.md)** (`Start-ScubaConfigApp`). The UI validates policy IDs and product names for you and helps avoid manual mistakes.

## The policy migration mapping file

The authoritative list of what changed is the migration mapping file included in the repository:

[`PowerShell/ScubaGear/mappings/scuba-baseline-policy-migrations.csv`](../../PowerShell/ScubaGear/mappings/scuba-baseline-policy-migrations.csv)

Each row describes how an old policy maps to the Security Suite baseline:

| Column | Description |
| --- | --- |
| `Old ID` | The deprecated policy ID (for example, `MS.DEFENDER.1.1v1` or `MS.EXO.9.1v2`). |
| `Old Description` | The text of the deprecated policy. |
| `New ID` | The replacement policy ID (for example, `MS.SECURITYSUITE.1.1v1`). A value of `None` means the policy was removed and is no longer assessed. A range (for example, `MS.SECURITYSUITE.1.1v1 - MS.SECURITYSUITE.1.4v1`) means the old policy was split across several new policies. |
| `Shall or Should` | Whether the policy is a `SHALL` or `SHOULD`. |
| `Removal Rationale` | Why the policy changed or was removed (`N/A` when it simply moved). |

Refer to this file whenever you need to find the new ID for a specific old policy.

### High-level summary of the migration

- **`MS.DEFENDER.*` policies** are now covered by `MS.SECURITYSUITE.*` policies (preset/EOP protection, impersonation protection, safe attachments, DLP, alerts, and audit logging).
- **`MS.EXO.8` – `MS.EXO.17` policies** (DLP, attachment filtering, malware scanning, impersonation, anti-spam, safe links, alerts, and audit logging) were moved into the Security Suite baseline.
- **`MS.TEAMS.6` – `MS.TEAMS.8` policies** (DLP and malware scanning for Teams) were moved into the Security Suite baseline.
- A small number of `SHOULD` policies that could not be assessed by ScubaGear were **removed** (`New ID` = `None`).

## Steps to update a YAML configuration file

Follow these steps to migrate an existing configuration file. The same steps apply to JSON configuration files.

### 1. Update `ProductNames`

Replace `defender` with `securitysuite`.

**Before:**

```yaml
ProductNames:
  - aad
  - defender
  - exo
```

**After:**

```yaml
ProductNames:
  - aad
  - securitysuite
  - exo
```

> [!NOTE]
> For backwards compatibility, if you run ScubaGear with `defender` in `ProductNames`, ScubaGear will automatically substitute `securitysuite` and emit a warning. Updating the configuration file removes the warning and reflects the current product name.

### 2. Rename the product exclusion section

If your configuration file has a top-level `Defender:` section for exclusions, rename it to `SecuritySuite:` and update the policy IDs inside it (see step 3).

**Before:**

```yaml
Defender:
  MS.DEFENDER.2.1v1:
    SensitiveUsers:
      - jdoe@example.com
```

**After:**

```yaml
SecuritySuite:
  MS.SECURITYSUITE.2.1v1:
    SensitiveUsers:
      - jdoe@example.com
```

### 3. Update migrated policy IDs in exclusions, annotations, and omissions

Look up each old policy ID in [`scuba-baseline-policy-migrations.csv`](../../PowerShell/ScubaGear/mappings/scuba-baseline-policy-migrations.csv) and replace it with the corresponding `New ID` under `AnnotatePolicy`, `OmitPolicy`, and any product exclusion section.

**Before:**

```yaml
OmitPolicy:
  MS.DEFENDER.2.1v1:
    Rationale: "We use a third-party phishing protection solution instead of Defender."
  MS.EXO.9.1v2:
    Rationale: "Handled by our third-party mail gateway."
```

**After:**

```yaml
OmitPolicy:
  MS.SECURITYSUITE.2.1v1:
    Rationale: "We use a third-party phishing protection solution instead of Defender."
  MS.SECURITYSUITE.1.1v1:
    Rationale: "Handled by our third-party mail gateway."
```

> [!IMPORTANT]
> Some old policies were split into a **range** of new policies (for example, `MS.DEFENDER.1.1v1` maps to `MS.SECURITYSUITE.1.1v1 - MS.SECURITYSUITE.1.4v1`). Review the range and choose the specific new policy ID(s) that apply to your exclusion, annotation, or omission.

### 4. Remove any policies marked as removed

If the `New ID` for an old policy is `None`, the policy has been removed and is no longer assessed by ScubaGear. Delete any exclusions, annotations, or omissions that reference it.

### 5. Validate the updated configuration

Re-run ScubaGear (or the configuration validator) against your updated file to confirm there are no remaining Defender migration warnings. See [Validator warnings](#validator-warnings) below.

## Validator warnings

When ScubaGear loads a configuration file, the built-in configuration validator checks for deprecated Defender usage and prints warnings to the console. You will see a `Defender migration warning` for each of the following situations:

- **Deprecated product name** - `ProductNames` still contains `defender`. ScubaGear runs `securitysuite` in its place and recommends updating the configuration.
- **Deprecated `Defender` section** - the configuration still contains a top-level `Defender:` section. Move the settings under `SecuritySuite:`.
- **Migrated policy ID** - a policy ID referenced in the configuration (in an exclusion, annotation, or omission) has been migrated. The warning names the new `MS.SECURITYSUITE.*` policy ID to use.
- **Removed policy ID** - a policy ID referenced in the configuration has been removed and should be deleted.

Example console output:

```text
WARNING: Configuration validation found 2 warnings:
  Defender migration warning: The product name 'defender' is deprecated and has been renamed to 'securitysuite'. ScubaGear will run 'securitysuite' in its place. Update ProductNames to use 'securitysuite'. See docs\configuration\defender-to-securitysuite-transition.md and mappings\scuba-baseline-policy-migrations.csv for the full list of migrated policies.
  Defender migration warning: Policy ID 'MS.DEFENDER.2.1v1' has been migrated to 'MS.SECURITYSUITE.2.1v1'. Update your configuration to use the new policy ID. See docs\configuration\defender-to-securitysuite-transition.md and mappings\scuba-baseline-policy-migrations.csv for the full list of migrated policies.

--- RECOMMENDED ACTION ---
  - The Defender product has been renamed to 'securitysuite' and many Defender, Exchange Online, and Teams policies were migrated into the MS.SECURITYSUITE.* baseline.
  - Update your configuration file: replace 'defender' with 'securitysuite' in ProductNames and update migrated policy IDs to their new MS.SECURITYSUITE.* equivalents.
  - Refer to the documentation [docs\configuration\defender-to-securitysuite-transition.md] and the mapping file [mappings\scuba-baseline-policy-migrations.csv] for the complete list of migrated policies.
```

These warnings do not stop ScubaGear from running, but resolving them ensures your configuration reflects the current baseline and that your exclusions, annotations, and omissions are applied to the correct policies.

## Related documentation

- [ScubaGear Configuration File](configuration.md)
- [Configuration UI](scubaconfigapp.md)
- [Parameters](parameters.md)
- [Security Suite baseline](../../PowerShell/ScubaGear/baselines/securitysuite.md)
