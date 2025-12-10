# ScubaGear Cached Execution

## Overview

`Invoke-SCuBACached` is a specialized version of the main ScubaGear function designed for development and testing workflows. It differs from `Invoke-SCuBA` in two key ways:

### Output Folder Structure

**`Invoke-SCuBA`** creates a timestamped subfolder:

```text
OutPath\
  └── M365BaselineConformance_2025_11_18_14_30_45\
      ├── ProviderSettingsExport.json
      ├── ScubaResults_abc123.json
      └── BaselineReports.html
```

**`Invoke-SCuBACached`** places output files directly in the specified path:

```text
OutPath\
  ├── ProviderSettingsExport.json
  ├── ScubaResults_abc123.json
  └── BaselineReports.html
```

This simplified structure makes iterative development easier—you can run full mode once to export provider data, then repeatedly run in cached mode without adjusting the `OutPath` parameter.

### Execution Modes

`Invoke-SCuBACached` supports two distinct execution modes:

1. **Full mode** (`-ExportProvider $true`, default) - Authenticates, exports provider data, runs Rego analysis, and generates reports (similar to `Invoke-SCuBA` but outputs directly to `OutPath` without creating a timestamped subfolder)
2. **Cached mode** (`-ExportProvider $false`) - Skips data collection and authentication, running analysis only on previously exported provider JSON files

This function is particularly useful for:

- Rego policy development and testing
- Re-running analysis on previously collected data without re-authentication
- Testing different report configurations
- Offline analysis scenarios

## Key Parameters

### All Parameters

`
Invoke-SCuBACached [-ExportProvider <Boolean>] [-ProductNames <String[]>] [-M365Environment <String>] [-OPAPath <String>] [-LogIn <Boolean>] [-Version] [-AppID <String>]
    [-CertificateThumbprint <String>] [-Organization <String>] [-OutPath <String>] [-OutProviderFileName <String>] [-OutRegoFileName <String>] [-OutReportName <String>]
    [-KeepIndividualJSON] [-OutJsonFileName <String>] [-OutCsvFileName <String>] [-OutActionPlanFileName <String>] [-Quiet] [-DarkMode] [-SilenceBODWarnings]
    [-NumberOfUUIDCharactersToTruncate <Int32>] [<CommonParameters>]
`

### ExportProvider

The most important parameter that distinguishes `Invoke-SCuBACached` from `Invoke-SCuBA`:

- **`$true` (default)**: Functions exactly like `Invoke-SCuBA` - authenticates, exports provider data, runs Rego analysis, and generates reports
- **`$false`**: Skips authentication and data export, runs analysis only on existing provider JSON files in the specified output path

### Other Parameters

All other parameters function identically to `Invoke-SCuBA`. See the [parameters documentation](../configuration/parameters.md) for complete details.

## Usage Examples

### Full Mode (Default Behavior)

```powershell
# Runs exactly like Invoke-SCuBA - authenticates and exports fresh data
Invoke-SCuBACached -ProductNames teams, aad -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24"
```

```powershell
# Explicitly set ExportProvider to true (same as default)
Invoke-SCuBACached -ProductNames * -ExportProvider $true -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24"
```

### Cached Mode (Analysis Only)

```powershell
# Run analysis only on previously exported data
Invoke-SCuBACached -ProductNames teams, aad -ExportProvider $false -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24"
```

```powershell
# Generate a new report with different settings using cached data
Invoke-SCuBACached -ProductNames * -ExportProvider $false -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24" -DarkMode -Quiet
```

### Optional Examples

Re-run analysis with different report settings (no authentication). Opens HTML results in darkmode

```powershell
Invoke-SCuBACached -ProductNames * -ExportProvider $false -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24" -DarkMode
```

Generate HTML and CSV report (no authentication). The HTML results will not auto-open when in quiet mode

```powershell
Invoke-SCuBACached -ProductNames * -ExportProvider $false -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24" -Quiet
```

## Cached Mode Requirements

When using `-ExportProvider $false`, the following conditions must be met:

### Required Files

The output directory must contain one of the following:

1. **Individual provider file**: `ProviderSettingsExport.json` (or custom name specified by `-OutProviderFileName`)
2. **Consolidated results file**: `ScubaResults_<guid>.json` file from a previous ScubaGear run

### File Location

Files must be located in the path specified by the `-OutPath` parameter. If no `-OutPath` is specified, ScubaGear will look in the current directory.

> [!TIP]
> ScubaGear results are usually exported in a `<path>\M365BaselineConformance_yyyy_MM_dd_hh_mm_ss` folder format.

### Product Compatibility

The cached data must contain information for the products specified in `-ProductNames`. If the cached data doesn't include a requested product, the analysis will fail for that product.


### Offline Analysis

Transfer files to an offline machine, then run analysis

```powershell
Invoke-SCuBACached -ProductNames teams, aad, exo -ExportProvider $false -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24"
```

### Testing Different Product Combinations

Export all product data once

```powershell
Invoke-SCuBACached -ProductNames * -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24"
```

Run analysis on subset 1

```powershell
Invoke-SCuBACached -ProductNames teams, aad -ExportProvider $false -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24"
```

Run analysis on subset 2

```powershell
Invoke-SCuBACached -ProductNames exo, defender -ExportProvider $false -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24"
```

### Testing Rego on Modified Settings

When testing Rego policies against specific configuration scenarios that can't be replicated in a live tenant, you can modify the exported JSON data and use cached mode to test the policy logic.

#### EXAMPLE 1

For example, when testing AAD authentication policy migration settings

1. Export provider data in full mode:

```powershell
Invoke-SCuBACached -ProductNames aad -OutPath "C:\ScubaResults\AAD_Policy_Test"
```

2. Manually modify the `ScubaResults_<guid>.json` file to inject test scenarios (example):

```json
{
  "conditional_access_policies": [
    {
      "DisplayName": "Test Migration Policy",
      "State": "enabled",
      "Conditions": {
        "Users": {
          "IncludeUsers": ["All"]
        }
      },
      "GrantControls": {
        "BuiltInControls": ["mfa"]
      }
    }
  ]
}
```

3. Run analysis on the modified data:

```powershell
Invoke-SCuBACached -ProductNames aad -ExportProvider $false -OutPath "C:\ScubaResults\AAD_Policy_Test"
```

This approach allows you to test edge cases, policy combinations, or specific configurations that would be difficult or impossible to create in a live Microsoft 365 environment.

#### EXAMPLE 2

Testing if the tenant had the migration complete configured. Newer tenants do not have this option. To test this, you can change the results json to simulate an alternate pass. For exmample change:

```json
"authentication_method_policy":  {
    "AuthenticationMethodConfigurations@odata.context": "https://graph.microsoft.com/beta/$metadata#policies/authenticationMethodsPolicy/authenticationMethodConfigurations%22",
    "PolicyVersion":  "1.5",
    "PolicyMigrationState":  "migrationComplete",
    "DisplayName":  null
}
```

to :

```json
"authentication_method_policy":  {
    "AuthenticationMethodConfigurations@odata.context": "https://graph.microsoft.com/beta/$metadata#policies/authenticationMethodsPolicy/authenticationMethodConfigurations%22",
    "PolicyVersion":  "1.5",
    "PolicyMigrationState":  null,
    "DisplayName":  "Authentication Methods Policy"
}
 ```

```powershell
Invoke-SCuBACached -ProductNames aad -ExportProvider $false -OutPath "C:\ScubaResults\AAD_Policy_Test"
```

## Error Scenarios

### Missing Provider Data

If the required provider JSON file doesn't exist in the specified path:

>[!NOTE]
> This message is pretty lengthy; this is a generic error:

```
...
FileNotFoundException: Could not find provider data file
...
```

**Solution**: Ensure the output directory contains the required `ScubaResults_<guid>.json` file

### Product Mismatch

If the cached data doesn't contain information for the requested products:

> [!NOTE]
> You may see this message repeated for each product not found:

```
WARNING: WARNING: No test results found for Control Id [Control Id]
```

**Solution**: Either:

- Export fresh data that includes the missing products
- Adjust the `-ProductNames` parameter to match available cached data

### Invalid JSON Format

If the cached provider file is corrupted or in an invalid format:

```
ConvertFrom-Json: Invalid JSON format
```

**Solution**: Re-export the provider data using the full mode (`ExportProvider $true`).

### Invalid or incorrect results

If the results are looking incorrect when it generates a html report, this may be due to opa executable missing. Download opa from https://github.com/open-policy-agent/opa/releases

> [!IMPORTANT]
> Make sure the file is named to: `opa_windows_amd64.exe`

**Solution**: Rerun the Invoke-SCuBACached in cache mode with a new OPA path:

```powershell
Invoke-SCuBACached -ProductNames exo, defender -ExportProvider $false -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24" -OPAPath "c:\ScubaResults\opadownload"
```

## Performance Considerations

### Cached Mode Benefits

- **Faster execution**: Skips authentication and data collection (typically 60-90% faster)
- **No network dependencies**: Can run completely offline
- **No credential requirements**: No need for M365 access
- **Consistent data**: Analysis runs on the same dataset for reproducible results

### Full Mode Benefits

- **Fresh data**: Always uses current tenant configuration
- **Complete workflow**: Single command for end-to-end assessment
- **Automatic cleanup**: Handles file management automatically

## Best Practices

### Development and Testing

**Rego Policy Development (Primary Use Case)**

`Invoke-SCuBACached` was originally designed for Rego policy development workflows. Developers can:

- Run full mode once to export provider data
- Modify Rego policies and quickly re-run in cached mode to see changes in the HTML report
- Avoid waiting for lengthy provider data collection on each iteration
- Test policy logic changes rapidly without authentication delays

**Functional Testing and CI/CD Pipelines**

The ScubaGear functional test pipeline makes extensive use of `Invoke-SCuBACached` to:

- Manipulate cached JSON files to test baseline policies that can't be tested safely in live environments
- Simulate specific configuration scenarios (e.g., MFA conditional access policies, risky settings)
- Test edge cases and policy combinations without impacting production tenants
- Validate Rego policy behavior across different configuration states

**General Best Practices**

- Keep a "golden" export for consistent testing across different configurations
- Use descriptive output folder names to organize different test scenarios
- Document any manual JSON modifications made for testing purposes

### Production Use

- Use full mode for official assessments to ensure fresh data
- Consider cached mode for generating multiple report formats from the same assessment
- Document the date/time of the original data export when using cached mode

## Known Issues

- Running the function on the same JSON file will eventually cause a system out of memory error as the file gets larger each time its ran.

## Version Compatibility

The cached mode works with provider data from the same major version of ScubaGear. When upgrading ScubaGear versions:

- **Minor version updates**: Cached data typically remains compatible
- **Major version updates**: May require fresh data export due to schema changes
- **Cross-version analysis**: Not recommended; re-export data with the new version

Check the [release notes](https://github.com/cisagov/ScubaGear/releases) for version-specific compatibility information.
