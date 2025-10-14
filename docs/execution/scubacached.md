# ScubaGear Cached Execution

`Invoke-SCuBACached` is a specialized version of the main ScubaGear function that allows you to run security assessments in two distinct modes:

1. **Full mode** - Works identically to `Invoke-SCuBA` (exports provider data, runs Rego analysis, and generates reports)
2. **Cached mode** - Skips data collection and authentication, running analysis only on previously exported provider JSON files

This function is particularly useful for:

- Re-running analysis on previously collected data
- Testing different report configurations without re-authenticating
- Offline analysis scenarios
- Development and testing workflows

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

When using `ExportProvider $false`, the following conditions must be met:

### Required Files

The output directory must contain one of the following:

1. **Individual provider file**: `ProviderSettingsExport.json` (or custom name specified by `-OutProviderFileName`)
2. **Consolidated results file**: `ScubaResults*.json` file from a previous ScubaGear run

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

**Solution**: Ensure the output directory contains the required `ProviderSettingsExport.json` or `ScubaResults*.json` file.

### Product Mismatch

If the cached data doesn't contain information for the requested products:

> [!NOTE]
> You may see this message repeated for each product not found:

```
WARNING: WARNING: No test results found for Control Id: [Control Id]
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

### Custom Provider File Names

Export with custom provider file name

```powershell
Invoke-SCuBACached -OutProviderFileName "MyCustomExport" -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24"
```

Use cached data with custom provider file name

```powershell
Invoke-SCuBACached -ExportProvider $false -OutProviderFileName "MyCustomExport" -OutPath "C:\ScubaResults\M365BaselineConformance_2025_09_22_10_19_24"
```

## Best Practices

### Development and Testing

- Use cached mode during development to speed up iteration cycles
- Keep a "golden" export for consistent testing across different configurations
- Use descriptive output folder names to organize different test scenarios

### Production Use

- Use full mode for official assessments to ensure fresh data
- Consider cached mode for generating multiple report formats from the same assessment
- Document the date/time of the original data export when using cached mode

### File Organization

```
C:\ScubaAssessments\
├── 2024-01-15_Production\          # Full export folder
│   ├── ProviderSettingsExport.json
│   ├── ScubaResults_abc123.json
│   └── BaselineReports.html
├── 2024-01-15_DarkMode\            # Cached analysis with different theme
│   ├── ProviderSettingsExport.json (copied)
│   ├── ScubaResults_def456.json
│   └── BaselineReports.html
└── 2024-01-15_CSVOnly\             # Cached analysis for CSV export
    ├── ProviderSettingsExport.json (copied)
    └── ScubaResults.csv
```

## Known Issues

- Running the function on the same JSON file will eventually cause a system out of memory error as the file gets larger each time it ran.

## Version Compatibility

The cached mode works with provider data from the same major version of ScubaGear. When upgrading ScubaGear versions:

- **Minor version updates**: Cached data typically remains compatible
- **Major version updates**: May require fresh data export due to schema changes
- **Cross-version analysis**: Not recommended; re-export data with the new version

Check the [release notes](https://github.com/cisagov/ScubaGear/releases) for version-specific compatibility information.
