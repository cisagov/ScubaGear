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

## Online doc/baseline sources

The viewer is self-contained: both online source URLs live here (no dependency on
`ScubaConfigApp_Control` for these). Only the **raw** GitHub URLs are used.

```json
"configurationSampleMarkdownRawOnlinePath": "https://raw.githubusercontent.com/cisagov/ScubaGear/refs/heads/main/docs/configuration/configuration.md",
"configurationBaselineJsonRawOnlinePath": "https://raw.githubusercontent.com/cisagov/ScubaGear/refs/heads/main/PowerShell/ScubaGear/schemas/ScubaBaselines.json"
```

| Key | Purpose |
| --- | --- |
| `configurationSampleMarkdownRawOnlinePath` | Raw URL to `configuration.md`. Read to populate the per-policy Configuration Example section, and (converted to the `github.com/.../blob/...` form) to resolve the Configurable badge links. Always fetched from the raw source so the samples stay current with `main`. |
| `configurationBaselineJsonRawOnlinePath` | Raw URL to the published `ScubaBaselines.json`. Downloaded into memory only when the viewer is launched with `-Online` (`Show-SCuBABaselinePolicyViewer -Online`), so developers can preview not-yet-published baselines. It is a plain HTTPS download — no Graph/tenant connection. |

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
> baseline source (`ScubaBaselines.json` locally by default, or the online copy from
> `configurationBaselineJsonRawOnlinePath` when the viewer is launched with `-Online`).

The `notes` policy mapping displays the generated policy-level note strings in a
separate Notes section. Implementation blockquotes remain with the instructions.
The viewer accepts both array-valued resources and legacy single resource objects.
Markdown rendering supports nested emphasis in links, inline and fenced code,
soft-wrapped paragraphs, and HTML images with alternative text. Repository-root
image paths are resolved against `configurationBaselineJsonRawOnlinePath`; image
loading failures emit a warning and leave the alternative text visible.

Product appendices come from the top-level `appendices` object in the generated
baseline JSON, not from policy section mappings. Each appendix appears after the
last policy in its product's left-navigation list. Selecting it displays its own
title and markdown body, without policy metadata, badges, or configuration
examples. Appendix text is searchable, but appendices are excluded from
SHALL/SHOULD filters and policy counts. Internal `#appendix-...` links navigate
to the matching appendix for the selected product. Older JSON without appendices
continues to show the policy-only navigation.
