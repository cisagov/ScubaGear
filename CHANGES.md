# Branch Changes: `2196-dynamically-control-productnames-m365environment`

## Summary

This branch replaces all hardcoded `[ValidateSet]` attributes for `$ProductNames` and `$M365Environment` across the codebase with schema-driven `[ValidateScript]` blocks backed by the `[ScubaConfig]` class. It also centralizes previously hardcoded product-name mappings and infrastructure constants into the schema/defaults configuration files, eliminating duplicate maintenance points.

**22 files changed - 176 insertions, 105 deletions**

---

## Files Changed

> **+/-** follows standard git diff notation: **+** = lines added, **-** = lines removed.

| # | File | +/- | Summary |
|---|------|-----|---------|
| 1 | `PowerShell/ScubaGear/schemas/ScubaConfigSchema.json` | +15 / -1 | Added `reportProductNames` section; added `ignoreProperties` entries for `ScubaGitHubUrl` and `IndividualReportFolderName` |
| 2 | `PowerShell/ScubaGear/schemas/ScubaConfigDefaults.json` | +2 / -0 | Added `ScubaGitHubUrl` and `IndividualReportFolderName` default values |
| 3 | `PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1` | +35 / -0 | Added 5 new static methods: `GetScubaGitHubUrl`, `GetAllValidProductNames`, `GetProductBaselineName`, `GetProductBaselineNames`, `GetDisplayNameFromBaselineName` |
| 4 | `PowerShell/ScubaGear/Modules/Orchestrator.psm1` | +30 / -39 | Removed `$ArgToProd`, `$ProdToFullName`, `$IndividualReportFolderName` module vars; replaced `[ValidateSet]` with `[ValidateScript]` on public functions; removed `[ValidateSet]` from internal helpers |
| 5 | `PowerShell/ScubaGear/Modules/CreateReport/CreateReport.psm1` | +7 / -9 | Added `using module`; replaced `[ValidateSet]` on `$BaselineName`; removed `$FullName` parameter (now derived internally); replaced hardcoded `$ScubaGitHubUrl` in 2 functions |
| 6 | `PowerShell/ScubaGear/Modules/Connection/Connection.psm1` | +8 / -2 | Added `using module`; removed `[ValidateSet]` from `Connect-Tenant`; replaced `[ValidateSet]` with `[ValidateScript]` on `Disconnect-SCuBATenant` |
| 7 | `PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1` | +0 / -4 | Removed `[ValidateSet]` on `$M365Environment` from 4 internal helper functions |
| 8 | `PowerShell/ScubaGear/Modules/Support/ServicePrincipal.psm1` | +27 / -18 | Added `using module`; removed `[ValidateSet]` from 8 internal functions; replaced with `[ValidateScript]` on 5 public-facing functions |
| 9 | `PowerShell/ScubaGear/Modules/Support/Support.psm1` | +6 / -4 | Added `using module`; replaced `[ValidateSet]` with `[ValidateScript]` on public-facing functions |
| 10 | `PowerShell/ScubaGear/Modules/Providers/ExportEXOProvider.psm1` | +0 / -1 | Removed `[ValidateSet]` on `$M365Environment` from internal function |
| 11 | `PowerShell/ScubaGear/Modules/Providers/ExportPowerPlatformProvider.psm1` | +0 / -2 | Removed `[ValidateSet]` on `$M365Environment` from internal functions |
| 12 | `PowerShell/ScubaGear/Modules/Providers/ExportSecuritySuiteProvider.psm1` | +0 / -1 | Removed `[ValidateSet]` on `$M365Environment` from internal function |
| 13 | `PowerShell/ScubaGear/Modules/Providers/ExportTeamsProvider.psm1` | +0 / -1 | Removed `[ValidateSet]` on `$M365Environment` from internal function |
| 14 | `PowerShell/ScubaGear/Modules/ProviderHelpers/PowerBIRestHelper.psm1` | +0 / -2 | Removed `[ValidateSet]` from internal helper functions |
| 15 | `PowerShell/ScubaGear/Modules/ProviderHelpers/PowerPlatformRestHelper.psm1` | +0 / -2 | Removed `[ValidateSet]` from internal helper functions |
| 16 | `PowerShell/ScubaGear/Modules/ScubaConfigApp/ScubaConfigApp.psm1` | +4 / -2 | Added `using module`; replaced `[ValidateSet]` with `[ValidateScript]` on `$M365Environment` in `Start-SCuBAConfigApp` |
| 17 | `PowerShell/ScubaGear/Modules/Utility/Utility.psm1` | +0 / -1 | Removed `[ValidateSet]` on `$M365Environment` from internal utility function |
| 18 | `PowerShell/ScubaGear/ScubaGear.psm1` | +19 / -18 | Updated `using module` declarations; replaced `[ValidateSet]` with `[ValidateScript]` at module entry point |
| 19 | `Testing/Unit/PowerShell/CreateReport/New-Report.Tests.ps1` | +0 / -10 | Removed `$ProdToFullName` hashtable and `FullName` key from `$CreateReportParams` |
| 20 | `Testing/Functional/Products/Products.Tests.ps1` | +3 / -1 | Added `using module`; replaced `[ValidateSet]` with `[ValidateScript]` on `$ProductName` parameter |
| 21 | `Testing/SetupPIMTests.ps1` | +1 / -1 | Updated `ScubaConfigDefaults.json` path to `schemas/` folder |
| 22 | `Testing/workflow/Update-Opa.Tests.ps1` | +1 / -1 | Updated `ScubaConfigDefaults.json` path to `schemas/` folder |

---

## Core Module: ScubaConfig

### `PowerShell/ScubaGear/schemas/ScubaConfigSchema.json`
**+15 / -1**

- Added `"ScubaGitHubUrl"` and `"IndividualReportFolderName"` to the `ignoreProperties` list in `schemaMetadata` (so the validator does not flag them as unknown keys).
- Added a new `schemaMetadata.reportProductNames` section - the single source of truth for the lowercase product ID → PascalCase baseline name → full display name correlation. Replaces the `$ArgToProd` and `$ProdToFullName` module-level hashtables that previously lived in `Orchestrator.psm1`.

```json
"reportProductNames": {
  "aad":           { "baselineName": "AAD",           "displayName": "Azure Entra ID" },
  "exo":           { "baselineName": "EXO",           "displayName": "Exchange Online" },
  "securitysuite": { "baselineName": "SecuritySuite", "displayName": "Security Suite" },
  "powerplatform": { "baselineName": "PowerPlatform", "displayName": "Microsoft Power Platform" },
  "sharepoint":    { "baselineName": "SharePoint",    "displayName": "SharePoint Online" },
  "teams":         { "baselineName": "Teams",         "displayName": "Microsoft Teams" },
  "powerbi":       { "baselineName": "PowerBI",       "displayName": "Microsoft Power BI" }
}
```

---

### `PowerShell/ScubaGear/schemas/ScubaConfigDefaults.json`
**+2 / -0**

- Added `"ScubaGitHubUrl": "https://github.com/cisagov/ScubaGear"` - the GitHub base URL previously hardcoded in `CreateReport.psm1` in two places.
- Added `"IndividualReportFolderName": "IndividualReports"` - the output subfolder name previously hardcoded as a module-level variable in `Orchestrator.psm1`.

> **Note on key naming:** `ScubaDefault('DefaultFoo')` strips `"Default"` and looks up `"Foo"` in the JSON `defaults` section. So the JSON keys do **not** carry the `Default` prefix.

---

### `PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1`
**+35 / -0**

Five new static methods added to the `[ScubaConfig]` class:

| Method | Description |
|--------|-------------|
| `GetScubaGitHubUrl()` | Returns `ScubaGitHubUrl` from defaults. Replaces the hardcoded string in `CreateReport.psm1`. |
| `GetAllValidProductNames()` | Returns the full `ProductNames.items.enum` array from the schema (includes `defender`, `*`, and all canonical names). Used in `[ValidateScript]` blocks throughout the codebase. |
| `GetProductBaselineName(string $ProductName)` | Converts a lowercase product ID (e.g. `"aad"`) to its PascalCase baseline name (`"AAD"`). Replaces `$ArgToProd[$Product]` lookups. |
| `GetProductBaselineNames()` | Returns all PascalCase baseline names. Used in `New-Report`'s `[ValidateScript]`. |
| `GetDisplayNameFromBaselineName(string $BaselineName)` | Converts a PascalCase baseline name (e.g. `"AAD"`) to its full display name (`"Azure Entra ID"`). Replaces `$ProdToFullName[$BaselineName]` lookups. |

---

## Orchestrator

### `PowerShell/ScubaGear/Modules/Orchestrator.psm1`
**+30 / -39**

**Module-level variables removed:**
- `$ArgToProd` hashtable (7 entries) - replaced by `[ScubaConfig]::GetProductBaselineName()`
- `$ProdToFullName` hashtable (7 entries) - replaced by `[ScubaConfig]::GetDisplayNameFromBaselineName()`
- `$IndividualReportFolderName = "IndividualReports"` - replaced by `[ScubaConfig]::ScubaDefault('DefaultIndividualReportFolderName')`

**`[ValidateSet]` → `[ValidateScript]` replacements:**
- `Invoke-SCuBA`: `$ProductNames` and `$M365Environment` parameters
- `Invoke-SCuBACached`: `$ProductNames` and `$M365Environment` parameters

**`[ValidateSet]` removed from internal helpers** (no replacement needed - these are internal and validation at the public boundary is sufficient):
- `ConvertTo-ResultsCsv`: `$ProductNames`
- `Merge-JsonOutput`: `$ProductNames`
- `Get-TenantDetail`: `$ProductNames` and `$M365Environment`
- `Compare-ProductList`: `$ProductNames` (x2) and `$ProductsFailed`

**`$ArgToProd`/`$ProdToFullName` usages replaced** in 6 locations across:
- `Invoke-ProviderList`
- `Invoke-RunRego`
- `ConvertTo-ResultsCsv`
- `Merge-JsonOutput` (display name and abbreviation mapping)
- `Invoke-ReportCreation` (baseline name lookup + display name for link building)

**`$FullName` removed from `$CreateReportParams`** - `New-Report` now derives it internally from `$BaselineName`.

---

## CreateReport

### `PowerShell/ScubaGear/Modules/CreateReport/CreateReport.psm1`
**+7 / -9**

- Added `using module '..\ScubaConfig\ScubaConfig.psm1'` at the top of the file (required for `[ValidateScript]` to resolve `[ScubaConfig]` at parse time).
- `New-Report` - `$BaselineName` parameter:
  - **Removed:** `[ValidateSet("Teams", "EXO", "SecuritySuite", "AAD", "PowerPlatform", "SharePoint", "PowerBI", IgnoreCase = $false)]`
  - **Added:** `[ValidateScript({ $_ -in [ScubaConfig]::GetProductBaselineNames() })]`
- `New-Report` - `$FullName` parameter **removed entirely**. `$FullName` is now derived on the first line of the function body: `$FullName = [ScubaConfig]::GetDisplayNameFromBaselineName($BaselineName)`.
- `New-Report` and `Get-IndicatorHtml` - `$ScubaGitHubUrl = "https://github.com/cisagov/ScubaGear"` replaced with `$ScubaGitHubUrl = [ScubaConfig]::GetScubaGitHubUrl()` in both functions.
- `Import-SecureBaseline` - removed hardcoded `[ValidateSet]` on `$ProductNames` (internal helper; validation at public boundary is sufficient).

---

## Connection

### `PowerShell/ScubaGear/Modules/Connection/Connection.psm1`
**+8 / -2**

- Added `using module '..\ScubaConfig\ScubaConfig.psm1'` at top.
- `Connect-Tenant`: removed `[ValidateSet]` on `$ProductNames` and `$M365Environment`.
- `Disconnect-SCuBATenant`: replaced `[ValidateSet]` on `$ProductNames` with `[ValidateScript]` using `GetAllValidProductNames()`.

### `PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1`
**+0 / -4**

Removed `[ValidateSet("commercial", "gcc", "gcchigh", "dod")]` from `$M365Environment` in four internal helper functions: `Connect-EXOHelper`, `Connect-DefenderHelper`, `Get-MsalAccessToken`, and one other. These are internal helpers - validation at the public boundary is sufficient.

---

## Support

### `PowerShell/ScubaGear/Modules/Support/ServicePrincipal.psm1`
**+27 / -18**

- Added `using module '..\ScubaConfig\ScubaConfig.psm1'` at top.
- **Removed `[ValidateSet]`** from `$M365Environment` in 8 internal functions: `Compare-ScubaGearRole`, `Compare-ScubaGearPermission`, `Set-ScubaGearRole`, `Get-ScubaGearAppRoleID`, `Set-AppRegistrationPermission`, `Connect-PowerPlatformApp`.
- **Replaced `[ValidateSet]` with `[ValidateScript]`** on public-facing functions:
  - `Get-ScubaGearAppPermission`: `$M365Environment` → `GetSupportedEnvironments()`; `$ProductNames` → `GetAllValidProductNames()`
  - `Set-ScubaGearAppPermission`: same replacements
  - `New-ScubaGearServicePrincipal`: same replacements
  - `Get-ScubaGearAppCert`: `$M365Environment` → `GetSupportedEnvironments()`
  - `Remove-ScubaGearAppCert`: `$M365Environment` → `GetSupportedEnvironments()`

### `PowerShell/ScubaGear/Modules/Support/Support.psm1`
**+6 / -4**

- Added `using module` and replaced `[ValidateSet]` with `[ValidateScript]` blocks on `$ProductNames` and/or `$M365Environment` in public-facing support functions.

---

## Providers

### `PowerShell/ScubaGear/Modules/Providers/ExportEXOProvider.psm1` **+0 / -1**
### `PowerShell/ScubaGear/Modules/Providers/ExportPowerPlatformProvider.psm1` **+0 / -2**
### `PowerShell/ScubaGear/Modules/Providers/ExportSecuritySuiteProvider.psm1` **+0 / -1**
### `PowerShell/ScubaGear/Modules/Providers/ExportTeamsProvider.psm1` **+0 / -1**

Removed `[ValidateSet("commercial", "gcc", "gcchigh", "dod")]` from `$M365Environment` in internal provider and tenant-detail functions. These are called only from `Orchestrator.psm1` after the value has already been validated at the public boundary.

### `PowerShell/ScubaGear/Modules/ProviderHelpers/PowerBIRestHelper.psm1` **+0 / -2**
### `PowerShell/ScubaGear/Modules/ProviderHelpers/PowerPlatformRestHelper.psm1` **+0 / -2**

Same pattern - removed `[ValidateSet]` from internal helper functions.

---

## Config App

### `PowerShell/ScubaGear/Modules/ScubaConfigApp/ScubaConfigApp.psm1`
**+4 / -2**

- Added `using module '..\ScubaConfig\ScubaConfig.psm1'` at top.
- `Start-SCuBAConfigApp`: replaced `[ValidateSet('commercial', 'dod', 'gcc', 'gcchigh')]` on `$M365Environment` with `[ValidateScript({ $_ -in [ScubaConfig]::GetSupportedEnvironments() })]`.

---

## Utility

### `PowerShell/ScubaGear/Modules/Utility/Utility.psm1`
**+0 / -1**

Removed `[ValidateSet]` from `$M365Environment` in an internal utility function.

---

## Entry Point

### `PowerShell/ScubaGear/ScubaGear.psm1`
**+19 / -18**

Updated `using module` declarations and `[ValidateSet]` → `[ValidateScript]` replacements in the module entry point, consistent with changes across the rest of the codebase.

---

## Tests

### `Testing/Unit/PowerShell/CreateReport/New-Report.Tests.ps1`
**+0 / -10**

- Removed `$ProdToFullName` hashtable (with its `SuppressMessageAttribute`) from `BeforeAll`.
- Removed `'FullName' = $ProdToFullName[$Product]` from the `$CreateReportParams` hashtable in the `It` block - no longer needed since `New-Report` derives `$FullName` internally.

### `Testing/Functional/Products/Products.Tests.ps1`
**+3 / -1**

- Added `using module '../../../PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1'` at top.
- `$ProductName` parameter: replaced `[ValidateSet(...)]` with `[ValidateScript({ $_ -in ([ScubaConfig]::GetAllValidProductNames() | Where-Object { $_ -ne '*' }) })]`.

### `Testing/SetupPIMTests.ps1`
**+1 / -1**

- Updated hardcoded path for `ScubaConfigDefaults.json` from `Modules/ScubaConfig/` to `schemas/`.

### `Testing/workflow/Update-Opa.Tests.ps1`
**+1 / -1**

- Updated hardcoded path for `ScubaConfigDefaults.json` from `Modules/ScubaConfig/` to `schemas/`.

---

## Design Rationale

| Before | After |
|--------|-------|
| `[ValidateSet]` with hardcoded values duplicated across 17+ files | `[ValidateScript]` reading from schema at parse time - one place to update |
| `$ArgToProd` hashtable in `Orchestrator.psm1` | `[ScubaConfig]::GetProductBaselineName()` reading from `ScubaConfigSchema.json` |
| `$ProdToFullName` hashtable in `Orchestrator.psm1` | `[ScubaConfig]::GetDisplayNameFromBaselineName()` reading from schema |
| `$ScubaGitHubUrl = "https://..."` hardcoded in 2 functions | `[ScubaConfig]::GetScubaGitHubUrl()` reading from `ScubaConfigDefaults.json` |
| `$IndividualReportFolderName = "IndividualReports"` hardcoded at module scope | `[ScubaConfig]::ScubaDefault('DefaultIndividualReportFolderName')` reading from defaults |
| `$FullName` passed as a separate parameter to `New-Report` | Derived inside `New-Report` from `$BaselineName` via `GetDisplayNameFromBaselineName()` |
