# How to update Scuba baselines (step-by-step)

This guide walks through the recommended process to update Scuba baseline JSON files using the Rego-based baseline tooling, test the results locally, and open a PR with the changes.

> Note: These commands are written for PowerShell (pwsh) on Windows. Adjust paths as needed.

## Prerequisites

- A working checkout of the ScubaGear repository (or the branch you will target).
- pwsh / PowerShell available (version 7+ recommended).
- Git CLI configured with your account.
- The `Update-ScubaConfigBaselineWithRego` helper (part of the ScubaGear modules) available in the repo (it is in `PowerShell\ScubaGear\Modules\ScubaConfigApp`).
- Optional: an editor (VS Code) and access to run Pester tests.

## Overview

1. Create a feature branch for the baseline update.
2. Run the baseline update command to modify the JSON baseline(s).
3. Inspect and verify changes locally.
4. Run unit/functional tests (Pester).
5. Commit and push changes, open a PR.
6. Validate CI results and address feedback.
7. Merge and optionally delete the branch.

---


## Example Commands

Below are example commands to update Scuba baselines using the `Update-ScubaConfigBaselineWithRego` cmdlet. These commands demonstrate various scenarios, including updating configurations, filtering products, and adding additional fields.

### Import the Module

Before running any commands, ensure the module is imported:

```powershell
[string]$ResourceRoot = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]
Import-Module (Join-Path -Path $ResourceRoot -ChildPath './ScubaConfigHelper.psm1')
```

### Get Rego Mappings

Retrieve the Rego exclusion mappings:

```powershell
$regoMappings = Get-ScubaConfigRegoExclusionMappings -RegoDirectory "..\..\Rego"
```

### Update Configuration Using Rego Mappings

Update the configuration file using Rego mappings:

```powershell
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -RegoDirectory "..\..\Rego"
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -BaselineDirectory "..\..\baselines" -RegoDirectory "..\..\Rego"
```

### Filter Specific Products

Filter the update to specific products:

```powershell
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -ProductFilter @("aad", "defender", "exo")
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -BaselineDirectory "..\..\baselines" -ProductFilter @("aad", "defender", "exo")
```

### Update Configuration with Additional Fields

Include additional fields in the update:

```powershell
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -RegoDirectory "..\..\Rego" -AdditionalFields @("criticality")
```