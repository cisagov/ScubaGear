![ScubaGear Logo](docs/images/SCuBA%20GitHub%20Graphic%20v6-05.png)


[![GitHub Release][github-release-img]][release]
[![PSGallery Release][psgallery-release-img]][psgallery]
[![CI Pipeline][ci-pipeline-img]][ci-pipeline]
[![Functional Tests][functional-test-img]][functional-test]
[![GitHub License][github-license-img]][license]
[![GitHub Downloads][github-downloads-img]][release]
[![PSGallery Downloads][psgallery-downloads-img]][psgallery]
[![GitHub Issues][github-issues-img]][github-issues]

ScubaGear is an assessment tool that verifies that a Microsoft 365 (M365) tenant’s configuration conforms to the policies described in the Secure Cloud Business Applications ([SCuBA](https://cisa.gov/scuba)) Secure Configuration Baseline [documents](/baselines/README.md).

> [!NOTE]
> This documentation can be read using [GitHub Pages](https://cisagov.github.io/ScubaGear).

## Target Audience

ScubaGear is for M365 administrators who want to assess their tenant environments against CISA Secure Configuration Baselines.

## Overview

ScubaGear uses a three-step process:

- **Step One** - PowerShell code queries M365 APIs for various configuration settings.
- **Step Two** - It then calls [Open Policy Agent](https://www.openpolicyagent.org) (OPA) to compare these settings against Rego security policies written per the baseline documents.
- **Step Three** - Finally, it reports the results of the comparison as HTML, JSON, and CSV.

![ScubaGear Assessment Process Diagram](docs/images/scuba-process.png)

## Key Features

### Baseline Security Coverage

SCuBA controls have been [mapped](docs/misc/mappings.md) to both NIST SP 800-53 and the MITRE ATT&CK framework.

  - [Baselines](baselines/README.md)
    - [Microsoft Entra ID](PowerShell/ScubaGear/baselines/aad.md): Identity and access management policies
    - [Defender](PowerShell/ScubaGear/baselines/defender.md): Advanced threat protection settings
    - [Exchange Online](PowerShell/ScubaGear/baselines/exo.md): Email security and compliance configurations
    - [Power BI](PowerShell/ScubaGear/baselines/powerbi.md): Cloud-based data visualization tool security settings
    - [Power Platform](PowerShell/ScubaGear/baselines/powerplatform.md): Low-code application security settings
    - [SharePoint](PowerShell/ScubaGear/baselines/sharepoint.md): Document collaboration and access controls
    - [Teams](PowerShell/ScubaGear/baselines/teams.md): Communication and meeting security policies

  - [Removed Policies](PowerShell/ScubaGear/baselines/removedpolicies.md)

### Scuba Configuration UI

SCuBA now includes a graphical user interface that makes it easier than ever to create and manage your YAML configuration files. This intuitive tool helps reduce the complexity of manual editing and streamlines the configuration process for your organization.
For more information review the [Configuration UI](docs/configuration/scubaconfigapp.md) documentation.

#### UI Key Features:
- Launch with `Start-ScubaConfigApp`
- Step-by-step setup wizard covering all configuration options
- Real-time validation with live YAML preview
- Microsoft Graph integration for user and group selection
- Seamless import/export of existing configuration files

> Ideal for users who prefer a visual interface over command-line tools.

### ScubaGear Output

- **HTML Reports**: Interactive, user-friendly compliance reports. [Sample BaselineReports.html](PowerShell/ScubaGear/Sample-Reports/BaselineReports.html)
- **JSON Output**: Structured results for reporting and parsing. [Sample ScubaResults.json](PowerShell/ScubaGear/Sample-Reports/ScubaResults_0d275954-350e-4a22.json)
- **CSV Export**: Spreadsheet-compatible data for analysis. [Sample ScubaResults.csv](PowerShell/ScubaGear/Sample-Reports/ScubaResults.csv)

## Getting Started

Before launching **ScubaGear**, it's important to ensure your environment is properly configured. This includes having the necessary dependencies and permissions in place.

Please review the [prerequisites](#prerequisites) section to verify that your system meets all requirements. This will help avoid errors during execution and ensure a smooth experience when using ScubaGear.

> [!NOTE]
> After installing ScubaGear in your environment, we recommend using the built-in update functions and features when you need to update to the latest version. See the [Update Guide](docs/installation/update.md) for more information.

### Quick Start Guide

ScubaGear can be run multiple times to properly evaluate baseline settings.

1. **First Run (No Configuration File):**
   Start ScubaGear without a configuration file. This initial run generates a baseline template of your environment's current settings. It does not make changes but helps you understand the default posture.

2. **Subsequent Runs (With Configuration File):**
   After reviewing and editing the generated configuration file, run ScubaGear again with the configuration file as input. This allows ScubaGear to compare your intended settings against the actual environment and elevate discrepancies accordingly.

> [!IMPORTANT]
> ScubaGear has specific prerequisites and relies on defined configuration values to properly evaluate your Microsoft 365 tenant. After your initial assessment run, review the results thoroughly. Address any identified gaps by updating your tenant configuration or documenting risk acceptances in a YAML configuration file using exclusions, annotations, or omissions.
> **Refer to the sections below for detailed guidance.**


This iterative approach ensures ScubaGear is aligned with your environment and that all policy evaluations are based on your customized baseline.

### 1. Install ScubaGear

To install ScubaGear from [PSGallery](https://www.powershellgallery.com/packages/ScubaGear), open a PowerShell 5 terminal on a Windows computer and install the module:

```powershell
# Install ScubaGear
Install-Module -Name ScubaGear
```

### 2. Install Dependencies

```powershell
# Install the minimum required dependencies
Initialize-SCuBA
```

### 3. Verify Installation

```powershell
# Check the version
Invoke-SCuBA -Version
```

### 4. Run Your First Assessment

```powershell
# Assess all products (basic command)
Invoke-SCuBA -ProductNames *
```

### 5. Build YAML configuration file

ScubaGear uses a YAML configuration file to define how your environment should be evaluated. This file serves several important purposes:

- **Customization** – Specify which products, baselines, and rules apply to your environment.
- **Configuration Mapping** – Align ScubaGear’s policies with your tenant’s current settings.
- **Risk Acceptance** – Document intentional deviations from baselines using **exclusions**, **annotations**, or **omissions**.
- **Traceability** – Maintain a clear record of accepted risks and policy decisions for audits or internal reviews.
- **Repeatability** – Run consistent assessments over time or across environments using the same configuration.

> [!IMPORTANT]
> Without a properly defined YAML file, ScubaGear will assume a default configuration that may not reflect your organization’s actual policies or risk posture. **It is required if the usage is for [CISA's Binding Operational Directive (BOD) 25-01 ](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services)**

### Reuse provided sample files

- [View sample configuration files](PowerShell/ScubaGear/Sample-Config-Files)
- [Learn about all configuration options](docs/configuration/configuration.md)

> [!TIP]
> [full_config.yaml](PowerShell/ScubaGear/Sample-Config-Files/full_config.yaml) is included to help you get started. This file should be customized to reflect your tenant’s unique configuration before using it with the ScubaGear module.


### 6. Run ScubaGear with a configuration File

When running `Invoke-SCuBA` for BOD 25-01 submissions:
```powershell
# Run with a configuration file
Invoke-SCuBA -ConfigFilePath "path/to/your/config.yaml" -Organization 'example.onmicrosoft.com'
```

For all other instances:

```powershell
# Run with a configuration file (no-BOD)
Invoke-SCuBA -ConfigFilePath "path/to/your/config.yaml" -SilenceBODWarnings
```

### 7. Update ScubaGear

The following will update ScubaGear.
```powershell
# The following will update ScubaGear to the latest version
Update-ScubaGear
```

The following will baseline all ScubaGear dependencies, please review the [Update Guide](docs/installation/update.md) in detail before running.
```powershell
# The follwing will remove and re-install all ScubaGear dependencies
Reset-ScubaGearDependencies
```

## Table of Contents

### Getting Started

#### Installation

  - [Install from PSGallery](docs/installation/psgallery.md)
  - [Download from GitHub](docs/installation/github.md)
  - [Uninstall](docs/installation/uninstall.md)
  - [Update](docs/installation/update.md)

 #### Prerequisites

  - [Dependencies](docs/prerequisites/dependencies.md)
  - [Required Permissions](docs/prerequisites/permissions.md)
    - [Interactive Permissions](docs/prerequisites/interactive.md)
    - [Non-Interactive Permissions](docs/prerequisites/noninteractive.md)

## Configuration & Usage

- [Configuration UI](docs/scubaconfigapp.md) - **Graphical interface**
- [Configuration File](docs/configuration/configuration.md) - **YAML-based configuration**
- [Parameters Reference](docs/configuration/parameters.md) - **Command-line options**

### Running Assessments

- [Execution Guide](docs/execution/execution.md)
- [Understanding Reports](docs/execution/reports.md)

### Troubleshooting & Support

| Topic | Resource | Notes |
|-------|----------|-------|
| Multiple Tenants | [tenants.md](docs/troubleshooting/tenants.md) | Solutions for organizations managing multiple M365 tenants - covers tenant switching, authentication across environments, and consolidated reporting strategies |
| Product-Specific Issues | | Common issues and solutions for individual M365 products |
| └ Defender | [defender.md](docs/troubleshooting/defender.md) | Resolves Microsoft Defender for Office 365 connection errors, API permission issues, and policy assessment failures specific to threat protection features |
| └ Exchange Online | [exchange.md](docs/troubleshooting/exchange.md) | Fixes Exchange Online PowerShell connectivity problems, mailbox access errors, and transport rule assessment issues |
| └ Power Platform | [power.md](docs/troubleshooting/power.md) | Addresses Power Apps and Power Automate assessment challenges including environment access, DLP policy evaluation, and connector permissions |
| └ Microsoft Graph | [graph.md](docs/troubleshooting/graph.md) | Comprehensive Graph API troubleshooting including authentication failures, insufficient permissions, throttling, and API version compatibility |
| Network & Proxy | [proxy.md](docs/troubleshooting/proxy.md) | Corporate network troubleshooting for firewall configurations, proxy settings, certificate issues, and connectivity problems in restricted environments |
| Cached Execution | [scubacached.md](docs/execution/scubacached.md) | Guide for using Invoke-SCuBACached to run assessments on previously exported data, enabling offline analysis and faster iteration cycles | 

### Automation

- [ScubaConnect](https://github.com/cisagov/ScubaConnect) - ScubaConnect is cloud-native infrastructure, developed by CISA, that automates the execution of assessment tools ScubaGear and ScubaGoggles.

### Additional Resources

- [Assumptions](docs/misc/assumptions.md)
- [Mappings](docs/misc/mappings.md)

## Project License

Unless otherwise noted, this project is distributed under the Creative Commons Zero license. With developer approval, contributions may be submitted with an alternate compatible license. If accepted, those contributions will be listed herein with the appropriate license.

[release]: https://github.com/cisagov/ScubaGear/releases
[license]: https://github.com/cisagov/ScubaGear/blob/main/LICENSE
[psgallery]: https://www.powershellgallery.com/packages/ScubaGear
[github-cicd-workflow]: https://github.com/cisagov/ScubaGear/actions/workflows/run_pipeline.yaml
[github-issues]: https://github.com/cisagov/ScubaGear/issues
[github-license-img]: https://img.shields.io/github/license/cisagov/ScubaGear
[github-release-img]: https://img.shields.io/github/v/release/cisagov/ScubaGear?label=GitHub&logo=github
[psgallery-release-img]: https://img.shields.io/powershellgallery/v/ScubaGear?logo=powershell&label=PSGallery
[ci-pipeline]: https://github.com/cisagov/ScubaGear/actions/workflows/run_pipeline.yaml
[ci-pipeline-img]: https://github.com/cisagov/ScubaGear/actions/workflows/run_pipeline.yaml/badge.svg
[functional-test]: https://github.com/cisagov/ScubaGear/actions/workflows/test_production_function.yaml
[functional-test-img]: https://github.com/cisagov/ScubaGear/actions/workflows/test_production_function.yaml/badge.svg
[github-cicd-workflow-img]: https://img.shields.io/github/actions/workflow/status/cisagov/ScubaGear/run_pipeline.yaml?logo=github
[github-downloads-img]: https://img.shields.io/github/downloads/cisagov/ScubaGear/total?logo=github
[psgallery-downloads-img]: https://img.shields.io/powershellgallery/dt/ScubaGear?logo=powershell
[github-issues-img]: https://img.shields.io/github/issues/cisagov/ScubaGear
