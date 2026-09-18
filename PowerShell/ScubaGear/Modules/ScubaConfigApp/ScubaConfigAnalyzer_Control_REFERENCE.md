# ScubaConfigAnalyzer Control JSON Reference

This document describes `ScubaConfigAnalyzer_Control_en-US.json`, which drives
`Start-SCuBAConfigAnalyzer` (the Config Analyzer). It lives at the ScubaConfigApp module root,
alongside `ScubaConfigApp_Control_en-US.json` and `ScubaBaselineViewer_Control_en-US.json`.

Loaded once by `Start-SCuBAConfigAnalyzer` and cached on `$syncHash`. It is JSON/schema-driven —
nothing about the baselines or API operations is hard-coded in the analyzer.

---

## version

```json
"version": "1.8.12"
```

Control-file version, shown in the analyzer window (`v<version>`) when the ScubaGear manifest
version is unavailable.

---

## File location keys

Declared relative to the ScubaConfigApp module folder and resolved at launch. Change a value here
to point the analyzer at a different file.

| Key | Purpose |
| --- | --- |
| `ScubaConfigAppModulePath` | The ScubaConfigApp module, imported so the Analyzer can open the Config App (`Open-ScubaConfigAppFromAnalyzer`). |
| `EXORestHelperPath` | ScubaGear's `EXORestHelper.psm1` — reused for Exchange Online REST (no `ExchangeOnlineManagement` module). |
| `ConnectHelpersPath` | ScubaGear's `ConnectHelpers.psm1` — MSAL token acquisition (`Get-MsalAccessToken`, `Initialize-Msal`). |
| `BaselineSchemaPath` | `ScubaGearResultsBaselineSchema.json` — the validation/results baseline the analyzer checks the tenant against. |
| `ApiCatalogPath` | `ScubaGearApiCatalog.json` — the Graph/EXO API operation catalog. |
| `ConfigSchemaPath` | `ScubaConfigSchema.json` — the canonical config schema (source of truth for which policies are configurable via exclusions, and the `M365Environment` enum). |

> **Not in this file (hardcoded in the launcher):** `AnalyzerControlPath`, `XamlPath`, `ImgPath`,
> `IcoPath`, and the `HelperModulesPath` (`ScubaConfigAnalyzerHelpers`) are foundational — the
> window can't load (or report a bad control file) without them — so they are set directly in
> `Start-SCuBAConfigAnalyzer`, not read from JSON.

---

## Online baseline dev toggle

Mirrors ScubaConfigApp's `PullOnlineBaselines`, but for the analyzer's own schemas.

| Key | Purpose |
| --- | --- |
| `PullOnlineBaselines` | When `true`, the analyzer downloads `BaselineSchemaPath`/`ApiCatalogPath` from the URLs below (to `$env:TEMP`) instead of using the local schemas folder, so developers can test not-yet-published baselines. Defaults to `false` (local). Falls back to local on download failure. |
| `OnlineBaselineSchemaURL` | Raw URL to `ScubaGearResultsBaselineSchema.json`. Used only when `PullOnlineBaselines` is `true`. Edit the branch in the URL as needed. |
| `OnlineApiCatalogURL` | Raw URL to `ScubaGearApiCatalog.json`. Used only when `PullOnlineBaselines` is `true`. |

> This toggle is **independent** of ScubaConfigApp's `PullOnlineBaselines`. The Analyzer validates
> against a different artifact (`ScubaGearResultsBaselineSchema.json`), so it has its own switch.

---

## Localization (i18n)

Applied by the analyzer runspace after the XAML loads. A different `*_<lang>.json` swaps the text;
debug/Activity-Log lines stay English by design.

| Key | Purpose |
| --- | --- |
| `localeWindow` | Window chrome — currently `Title`. |
| `localeContext` | Named-control text keyed by control name, applied by control type (`TextBlock.Text`, `Button.Content`, `CheckBox.Content`, `Label.Content`, `TabItem.Header`, `TextBox.Text`). |
| `localeToolTips` | Named-control tooltips (`<name>` → `.ToolTip`). |
| `localeStatusMessages` | Status-bar / message strings; `{0}` placeholders are filled with `-f`. |

---

## Analysis engine data

Schema-driven inputs the analysis engine reads (cached on `$syncHash.ScA*`). These describe the
baselines and API surface; nothing here is hard-coded in PowerShell.

| Key | Purpose |
| --- | --- |
| `productMap` | Per-product metadata (friendly `displayName`, etc.) keyed by product id. Drives the product list and friendly names. |
| `apiOperations` | Definitions of the Graph/EXO operations the analyzer invokes to read tenant configuration. |
| `exclusionDefinitions` | Per-control definitions of what to collect and how a config exclusion/allow-list makes the control pass. |
| `conditionalAccessAnalysis` | Rules for matching non-compliant AAD controls to the best-fit Conditional Access policy. |
| `RequirementFriendlyNames` | Human-readable names for baseline requirements, used in findings and generated YAML comments. |
