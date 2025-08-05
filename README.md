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

> **Note**: This documentation can be read using [GitHub Pages](https://cisagov.github.io/ScubaGear).

## Target Audience

ScubaGear is for M365 administrators who want to assess their tenant environments against CISA Secure Configuration Baselines.

## What's New 🆕

**YAML Configuration UI**: SCuBA now includes a graphical user interface that makes it easier than ever to create and manage your YAML configuration files. This intuitive tool helps reduce the complexity of manual editing and streamlines the configuration process for your organization.

#### 🚀 UI Key Features:
- Launch with `Invoke-SCuBAConfigAppUI`
- Step-by-step setup wizard covering all configuration options
- Real-time validation with live YAML preview
- Microsoft Graph integration for user and group selection
- Seamless import/export of existing configuration files

> Ideal for users who prefer a visual interface over command-line tools.

## Overview

ScubaGear uses a three-step process:

- **Step One** - PowerShell code queries M365 APIs for various configuration settings.
- **Step Two** - It then calls [Open Policy Agent](https://www.openpolicyagent.org) (OPA) to compare these settings against Rego security policies written per the baseline documents.
- **Step Three** - Finally, it reports the results of the comparison as HTML, JSON, and CSV.

![ScubaGear Assessment Process Diagram](docs/images/scuba-process.png)

## Key Features

### 🖥️ Multiple Interfaces

- **Configuration UI**: Graphical interface for easy setup and configuration management
- **Command Line**: PowerShell cmdlets for automation and scripting
- **Configuration Files**: YAML-based configuration for repeatable assessments

### 🔒 Comprehensive Security Coverage

- **Azure Active Directory (AAD)**: Identity and access management policies
- **Microsoft Defender**: Advanced threat protection settings
- **Exchange Online**: Email security and compliance configurations
- **OneDrive**: File sharing and data protection policies
- **Power Platform**: Low-code application security settings
- **SharePoint**: Document collaboration and access controls
- **Microsoft Teams**: Communication and meeting security policies

### 📊 Rich Reporting

- **HTML Reports**: Interactive, user-friendly compliance reports
- **JSON Output**: Machine-readable results for automation
- **CSV Export**: Spreadsheet-compatible data for analysis

### 🎯 CISA SCuBA Alignment

- Based on official [CISA SCuBA baselines](https://cisa.gov/scuba)
- Regularly updated to match the latest security recommendations
- Detailed policy mappings and explanations
  - [Mappings](docs/misc/mappings.md)
  - [Baselines](baselines/README.md)
    - [Microsoft Entra ID](PowerShell/ScubaGear/baselines/aad.md)
    - [Defender](PowerShell/ScubaGear/baselines/defender.md)
    - [Exchange Online](PowerShell/ScubaGear/baselines/exo.md)
    - [Power BI](PowerShell/ScubaGear/baselines/powerbi.md)
    - [Power Platform](PowerShell/ScubaGear/baselines/powerplatform.md)
    - [SharePoint & OneDrive](PowerShell/ScubaGear/baselines/sharepoint.md)
    - [Teams](PowerShell/ScubaGear/baselines/teams.md)
    - [Removed Policies](PowerShell/ScubaGear/baselines/removedpolicies.md)

## Getting Started

Before launching **ScubaGear**, it's important to ensure your environment is properly prepared. This includes having the necessary configurations, permissions, and platform dependencies in place.

Please review the [Prerequisites](#prerequisites) section to verify that your system meets all requirements. This will help avoid errors during execution and ensure a smooth experience when using ScubaGear.


### Quick Start Guide

ScubaGear is designed to be run multiple times to properly evaluate and apply baseline settings.

1. **First Run (No Configuration File):**  
   Start ScubaGear without a configuration file. This initial run generates a baseline template of your environment's current settings. It does not make changes but helps you understand the default posture.

2. **Subsequent Runs (With Configuration File):**  
   After reviewing and editing the generated configuration file, run ScubaGear again with the configuration file as input. This allows ScubaGear to compare your intended settings against the actual environment and elevate discrepancies accordingly.

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

> [!IMPORTANT]
> ScubaGear has specific prerequisites and relies on defined configuration values to properly evaluate your Microsoft 365 tenant. After your initial assessment run, review the results thoroughly. Address any identified gaps by updating your tenant configuration or documenting risk acceptances in a YAML configuration file using exclusions, annotations, or omissions.  
> **Refer to the sections below for detailed guidance.**


### 5. Build YAML configuration file

📄 **Why You Need a YAML Configuration File**

ScubaGear uses a YAML configuration file to define how your environment should be evaluated. This file serves several important purposes:

- ✅ **Customization** – Specify which products, baselines, and rules apply to your environment.
- ⚙️ **Configuration Mapping** – Align ScubaGear’s policies with your tenant’s current settings.
- 🛡 **Risk Acceptance** – Document intentional deviations from baselines using **exclusions**, **annotations**, or **omissions**. 
- 🧾 **Traceability** – Maintain a clear record of accepted risks and policy decisions for audits or internal reviews.
- 🔁 **Repeatability** – Run consistent assessments over time or across environments using the same configuration.

> [!NOTE]
> Without a properly defined YAML file, ScubaGear will assume a default configuration that may not reflect your organization’s actual policies or risk posture.  
> **Refer to the [Baselines](baselines/README.md) to understand what options are configurable.**


### Option 1: Configuration UI (Recommended for New Users)

Use the graphical configuration interface to easily create and manage your settings:

```powershell
# Launch the Configuration UI
Invoke-SCuBAConfigAppUI
```

The Configuration UI provides:

- ✅ **User-friendly interface** for all configuration options
- ✅ **Real-time validation** of YAML layout
- ✅ **YAML preview** before export configurations
- ✅ **Import/Export** existing configurations
- ✅ **Microsoft Graph integration** for user/group selection

📖 **[Learn more about the Configuration UI →](docs/configuration/scubaconfigui.md)**

📖 **[Learn more about Configuration Files →](docs/configuration/configuration.md)**

### Option 2: Reuse provided sample files

- 📄 [View the Sample Configuration](PowerShell/ScubaGear/Sample-Config-Files) →
- 📖 [Learn about all configuration options](docs/configuration/configuration.md) →

> [!TIP]
> A [sample YAML configuration file](PowerShell\ScubaGear\Sample-Config-Files\full_config.yaml) is included to help you get started. This file should be customized to reflect your tenant’s unique configuration before using it with the ScubaGear module. **For easier editing, you can import it into the UI and make further adjustments there.**


### 6: Run Scuba with configuration File

While a YAML configuration file is not strictly required to run ScubaGear, it is strongly recommended—and in practice, essential for any reporting intended for the [CISA's Binding Operational Directive (BOD) 25-01 ](https://www.cisa.gov/news-events/directives/bod-25-01-implementation-guidance-implementing-secure-practices-cloud-services).

```powershell
# Run with a configuration file
Invoke-SCuBA -ConfigFilePath "path/to/your/config.YAML"
```

> the scubamodule supports several paramaters.

## Table of Contents

### 🚀 Getting Started

#### Installation

  - [Install from PSGallery](docs/installation/psgallery.md)
  - [Download from GitHub](docs/installation/github.md)
  - [Uninstall](docs/installation/uninstall.md)

 #### Prerequisites

  - [Dependencies](docs/prerequisites/dependencies.md)
  - [Required Permissions](docs/prerequisites/permissions.md)
    - [Interactive Permissions](docs/prerequisites/interactive.md)
    - [Non-Interactive Permissions](docs/prerequisites/noninteractive.md)

### ⚙️ Configuration & Usage

- [Configuration UI](docs/scubaconfigui.md) - **Graphical interface for easy setup**
- [Configuration File](docs/configuration/configuration.md) - **YAML-based configuration**
- [Parameters Reference](docs/configuration/parameters.md) - **Command-line options**

### 🏃‍♂️ Running Assessments

- [Execution Guide](docs/execution/execution.md)
- [Understanding Reports](docs/execution/reports.md)

### 🔧 Troubleshooting & Support

- [Multiple Tenants](docs/troubleshooting/tenants.md)
- [Product-Specific Issues](docs/troubleshooting/)
  - [Defender](docs/troubleshooting/defender.md)
  - [Exchange Online](docs/troubleshooting/exchange.md)
  - [Power Platform](docs/troubleshooting/power.md)
  - [Microsoft Graph](docs/troubleshooting/graph.md)
- [Network & Proxy](docs/troubleshooting/proxy.md)

### 🤖 Automation

- [ScubaConnect](https://github.com/cisagov/ScubaConnect) - ScubaConnect is cloud-native infrastructure that automates the execution of assessment tools ScubaGear and ScubaGoggles.

### 📚 Additional Resources

- [Assumptions](docs/misc/assumptions.md)
- [Mappings](docs/misc/mappings.md)

## Project License

Unless otherwise noted, this project is distributed under the Creative Commons Zero license. With developer approval, contributions may be submitted with an alternate compatible license. If accepted, those contributions will be listed herein with the appropriate license.

[release]: https://github.com/cisagov/ScubaGear/releases
[license]: https://github.com/cisagov/ScubaGear/blob/main/LICENSE
[psgallery]: https://www.powershellgallery.com/packages/ScubaGear
[github-cicd-workflow]: https://github.com/cisagov/ScubaGear/actions/workflows/run_pipeline.YAML
[github-issues]: https://github.com/cisagov/ScubaGear/issues
[github-license-img]: https://img.shields.io/github/license/cisagov/ScubaGear
[github-release-img]: https://img.shields.io/github/v/release/cisagov/ScubaGear?label=GitHub&logo=github
[psgallery-release-img]: https://img.shields.io/powershellgallery/v/ScubaGear?logo=powershell&label=PSGallery
[ci-pipeline]: https://github.com/cisagov/ScubaGear/actions/workflows/run_pipeline.YAML
[ci-pipeline-img]: https://github.com/cisagov/ScubaGear/actions/workflows/run_pipeline.YAML/badge.svg
[functional-test]: https://github.com/cisagov/ScubaGear/actions/workflows/test_production_function.YAML
[functional-test-img]: https://github.com/cisagov/ScubaGear/actions/workflows/test_production_function.YAML/badge.svg
[github-cicd-workflow-img]: https://img.shields.io/github/actions/workflow/status/cisagov/ScubaGear/run_pipeline.YAML?logo=github
[github-downloads-img]: https://img.shields.io/github/downloads/cisagov/ScubaGear/total?logo=github
[psgallery-downloads-img]: https://img.shields.io/powershellgallery/dt/ScubaGear?logo=powershell
[github-issues-img]: https://img.shields.io/github/issues/cisagov/ScubaGear
