# ScubaBaselineViewer Control JSON Reference

This document describes `ScubaBaselineViewer_Control_en-US.json`, which drives the app-independent
Baseline Policy Viewer (`Show-SCuBABaselinePolicyViewer`), launched by both ScubaConfigApp and the
Config Analyzer. It lives at the ScubaConfigApp module root, alongside
`ScubaConfigApp_Control_en-US.json` and `ScubaConfigAnalyzer_Control_en-US.json`.

The viewer is app-independent (its helper lives in `ScubaBaselinePolicyViewerHelpers`, its XAML in
`ScubaConfigAppResources`). This small control file holds only the window **chrome** and the
section mappings — the policy body is generated from the baseline markdown/JSON. The viewer
self-resolves this file from the module root; callers no longer pass a control path.

---

## version / _comment

```json
"version": "1.0.0",
"_comment": "Control file for the app-independent ScubaGear Baseline Policy Viewer ..."
```

---

## products

Which products the viewer lists, and their display names. This is the viewer's own copy — it no
longer borrows `showInViewer` from `ScubaConfigApp_Control`.

```json
{ "id": "Aad", "name": "Microsoft Entra ID", "showInViewer": true }
```

| Field | Purpose |
| --- | --- |
| `id` | Product key (matched case-insensitively against the baseline data). |
| `name` | Product display name shown as the group header in the left nav. |
| `showInViewer` | When `false`, the product group is hidden from the viewer. |

---

## policyViewerSettings

Everything the viewer needs to render headers and map baseline JSON fields into the accordion.

| Key | Purpose |
| --- | --- |
| `windowHeader` | `windowTitle`, `headerTitle`, `headerSubtitle` shown in the viewer's title bar and header band. |
| `defaultContentHeaders` | `title` / `description` shown before a policy is selected (the Introduction landing view). |
| `mainMarkdownMappings` | Maps the intro/landing sections (Introduction, Key Terminology, License Compliance, Assumptions) to top-level baseline JSON properties. |
| `policyMarkdownMappings` | Per-policy accordion sections (Rationale, MITRE ATT&CK, Implementation Instructions, License Requirements, Additional Resources, etc.). Each entry defines the `displayName`, source `jsonProperty`, colors, and default expanded state. |

> The baseline **content** (policy text, links, MITRE data) is not in this file — it comes from the
> baseline source (`ScubaBaselines.json` locally, or the online copy when
> `ScubaConfigApp_Control.PullOnlineBaselines` is `true`; the viewer honours that same app toggle).
