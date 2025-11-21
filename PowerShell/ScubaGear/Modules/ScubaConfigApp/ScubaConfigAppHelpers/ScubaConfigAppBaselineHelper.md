# How to update ScubaGear baselines json from markdown

This guide walks through the recommended process to update Scuba baseline JSON files using both the markdown and the Rego-based baseline tooling.

## Prerequisites

- The `Update-ScubaConfigBaselineWithRego` helper (part of the ScubaConfigApp module) available in the repo (it is in `PowerShell\ScubaGear\Modules\ScubaConfigApp\ScubaConfigAppHelpers`).


## Example Commands

Below are example commands to update Scuba baselines using the `Update-ScubaConfigBaselineWithRego` cmdlet. These commands demonstrate various scenarios, including updating configurations, filtering products, and adding additional fields.

### Import the Module

Before running any commands, ensure the module is imported:

```powershell
[string]$ResourceRoot = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]
Import-Module (Join-Path -Path $ResourceRoot -ChildPath './ScubaConfigAppBaselineHelper.psm1')
```

### Get Rego Mappings

Retrieve the Rego exclusion mappings:

```powershell
Get-ScubaConfigRegoExclusionMappings -RegoDirectory "..\..\Rego"
```

### Update Configuration Using Rego Mappings

Update the configuration file using Rego mappings. There are two ways to pull this data:

A. from the Repo

```powershell
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -RegoDirectory "..\..\Rego"
```

B. From local markdown

```powershell

Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -BaselineDirectory "..\..\baselines" -RegoDirectory "..\..\Rego"
```

#### Update but filter specific products (repo_)

This will only pull baseline from certain products. 

```powershell
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -ProductFilter @("aad", "defender", "exo")
```


```powershell
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -BaselineDirectory "..\..\baselines" -ProductFilter @("aad", "defender", "exo")
```

### Update Configuration with Additional Fields

Include additional fields in the update:

```powershell
Update-ScubaConfigBaselineWithRego -ConfigFilePath ".\ScubaBaselines_en-US.json" -GitHubDirectoryUrl "https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines" -RegoDirectory "..\..\Rego" -AdditionalFields @("criticality")
```