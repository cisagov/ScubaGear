# ScubaBaselines.json Asset Package Schema

## Overview

The `ScubaBaselines.json` file is a machine-readable asset package derived from the authoritative markdown baseline documentation. It provides structured access to all SCuBA (Secure Cloud Business Applications) security configuration baselines for consumption by tools, scripts, and applications.

**Important**: The markdown baseline files remain the authoritative source. The JSON format is an equivalent representation provided for machine consumption.

## Schema Version

Current Schema Version: **1.0.0**

## File Location

- **Path in Repository**: `PowerShell/ScubaGear/schemas/ScubaBaselines.json`
- **Available in**: 
  - GitHub releases (attached as release asset)
  - PowerShell Gallery package (included in module distribution)
  - Repository baselines directory

## Top-Level Structure

```json
{
  "Version": "string",
  "DebugMode": "string",
  "Introduction": "string",
  "LicenseCompliance": "string",
  "Assumptions": "string",
  "KeyTerminology": "string",
  "baselines": {
    "product": [ /* array of policy objects */ ]
  }
}
```

### Top-Level Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Version` | string | Yes | Version identifier with update date (format: `YearOffset.Month.Day [updated MM/DD/YYYY]`) |
| `DebugMode` | string | Yes | Debug mode setting (typically "None") |
| `Introduction` | string | No | Common SCuBA project introduction text |
| `LicenseCompliance` | string | No | License compliance and copyright information |
| `Assumptions` | string | No | Common assumptions for all baselines |
| `KeyTerminology` | string | No | Key terminology definitions |
| `baselines` | object | Yes | Object containing product-specific baseline arrays |

## Baseline Product Structure

The `baselines` object contains properties for each Microsoft 365 product:

- `aad` - Azure Active Directory (Entra ID)
- `defender` - Microsoft Defender
- `exo` - Exchange Online
- `powerbi` - Power BI
- `powerplatform` - Power Platform
- `sharepoint` - SharePoint Online
- `teams` - Microsoft Teams

Each product property contains an array of policy objects.

## Policy Object Schema

Each policy object represents a single security baseline control:

```json
{
  "id": "MS.AAD.1.1v1",
  "name": "Legacy authentication SHALL be blocked",
  "policySection": "Legacy Authentication",
  "sectionDescription": "Legacy authentication protocols...",
  "exclusionField": "Users",
  "omissionField": "Omissions",
  "annotationField": "Annotations",
  "rationale": "Legacy authentication protocols...",
  "criticality": "SHALL",
  "lastModified": "January 2024",
  "implementation": "Instructions for implementing...",
  "mitreMapping": [
    {
      "Name": "Valid Accounts",
      "Url": "https://attack.mitre.org/techniques/T1078/"
    }
  ],
  "resources": [
    {
      "Name": "Block legacy authentication",
      "Url": "https://learn.microsoft.com/..."
    }
  ],
  "licenseRequirements": ["Azure AD Premium P1"],
  "link": "https://github.com/cisagov/ScubaGear/...",
  "badges": [
    {
      "title": "MS.AAD.1.1v1",
      "label": "Conditional Access Required",
      "color": "1E90FF",
      "imageUrl": "https://img.shields.io/badge/...",
      "linkUrl": "#msaad11v1"
    }
  ]
}
```

### Required Policy Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique policy identifier (format: MS.PRODUCT.#.#v#) |
| `name` | string | Policy name/title |
| `policySection` | string | Section name this policy belongs to |
| `sectionDescription` | string | Description of the containing section |
| `exclusionField` | string | Type of exclusions allowed (e.g., "Users", "Groups", "none") |
| `omissionField` | string | Field name for omissions (typically "Omissions") |
| `annotationField` | string | Field name for annotations (typically "Annotations") |

### Optional Policy Properties

| Property | Type | Description |
|----------|------|-------------|
| `rationale` | string | Rationale explaining why this policy is important |
| `criticality` | string | Criticality level: "SHALL", "SHOULD", "MAY", "3RD PARTY", "NOT-IMPLEMENTED" |
| `lastModified` | string | Last modification date (format varies) |
| `implementation` | string | Implementation instructions |
| `mitreMapping` | array | Array of MITRE ATT&CK technique objects |
| `resources` | array | Array of resource link objects |
| `licenseRequirements` | array | Array of license requirement strings |
| `link` | string | Direct link to policy documentation |
| `badges` | array | Array of badge objects for visual indicators |

### Resource Object

```json
{
  "Name": "Resource name",
  "Url": "https://example.com"
}
```

### MITRE Mapping Object

```json
{
  "Name": "Technique name",
  "Url": "https://attack.mitre.org/techniques/..."
}
```

### Badge Object

```json
{
  "title": "Badge tooltip",
  "label": "Badge label text",
  "color": "Hex color code",
  "imageUrl": "https://img.shields.io/badge/...",
  "linkUrl": "Anchor or full URL"
}
```

## Exclusion Field Types

The `exclusionField` property indicates what type of exclusions are permitted for a policy:

- `Users` - User accounts can be excluded
- `Groups` - Security groups can be excluded
- `Domains` - Domains can be excluded
- `Roles` - Roles can be excluded
- `none` - No exclusions permitted
- *Custom types may exist per product*

## Versioning

The `Version` field uses a date-based scheme:

```
YearOffset.Month.Day [updated MM/DD/YYYY]
```

Example: `2.1.15 [updated 1/15/2026]`

- **YearOffset**: Years since 2025 (UI development start), so 2026 = 2
- **Month**: 1-12
- **Day**: 1-31
- **Update Date**: Human-readable date of generation

## Generation Process

The asset package is automatically generated via GitHub Actions:

1. **Trigger**: PR modifies baseline markdown files
2. **Parse**: Extract structured data from markdown
3. **Generate**: Create versioned JSON with metadata
4. **Validate**: Verify schema compliance
5. **Commit**: Add to PR for review
6. **Release**: Include in GitHub releases and PSGallery

## Validation

Basic validation ensures:

- All required top-level properties present
- All policies have required fields
- Proper JSON structure and encoding
- Exclusion types are valid
- Policy IDs follow correct format

## Usage Examples

### PowerShell

```powershell
# Load the baseline
$baseline = Get-Content "PowerShell/ScubaGear/schemas/ScubaBaselines.json" | ConvertFrom-Json

# Access a specific product
$aadPolicies = $baseline.baselines.aad

# Find policies requiring specific licenses
$p1Policies = $baseline.baselines.aad | Where-Object { 
    $_.licenseRequirements -contains "Azure AD Premium P1" 
}

# Get all SHALL policies
$criticalPolicies = $baseline.baselines.aad | Where-Object { 
    $_.criticality -eq "SHALL" 
}
```

### Python

```python
import json

# Load the baseline
with open('PowerShell/ScubaGear/schemas/ScubaBaselines.json', 'r') as f:
    baseline = json.load(f)

# Get all products
products = baseline['baselines'].keys()

# Find policies by section
defender_policies = [p for p in baseline['baselines']['defender'] 
                     if p['policySection'] == 'Safe Links']
```

### JavaScript/TypeScript

```typescript
import baseline from './PowerShell/ScubaGear/schemas/ScubaBaselines.json';

// Access version
console.log(baseline.Version);

// Filter by criticality
const shallPolicies = Object.values(baseline.baselines)
  .flat()
  .filter(p => p.criticality === 'SHALL');

// Group by exclusion type
const byExclusion = Object.values(baseline.baselines)
  .flat()
  .reduce((acc, p) => {
    acc[p.exclusionField] = acc[p.exclusionField] || [];
    acc[p.exclusionField].push(p);
    return acc;
  }, {});
```

## Maintenance

### Authoritative Source

**The markdown baseline files are the authoritative source.** Any changes to baselines MUST be made in markdown first. The JSON is automatically generated and should never be manually edited.

### Synchronization

The asset package is automatically updated when:
- Baseline markdown files are modified in a PR
- The generation script or workflow is updated

### Schema Evolution

Future schema changes will:
- Maintain backward compatibility where possible
- Update the schema version number
- Provide migration guidance in release notes
- Be documented in this file

## Related Files

- **Generation Script**: `utils/workflow/Generate-ScubaBaseline.ps1`
- **Workflow**: `.github/workflows/build_sign_release.yaml`
- **Schema Helper Module**: `PowerShell/ScubaGear/Modules/Support/ScubaBaselineSchemaHelper.psm1`
- **Source Baselines**: `PowerShell/ScubaGear/baselines/*.md`

## Support

For issues related to:
- **Schema structure**: Open issue in ScubaGear repository
- **Generation failures**: Check GitHub Actions workflow logs
- **Data accuracy**: Verify against source markdown files
- **Missing properties**: Check if optional or missing from markdown

## License

The asset package is subject to the same license as ScubaGear. See LICENSE file in repository root.

---

**Document Version**: 1.0.0  
**Last Updated**: February 2026  
**Maintained By**: CISA SCuBA Team
