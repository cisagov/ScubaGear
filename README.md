<a href="https://github.com/cisagov/ScubaGear/releases" alt="ScubaGear version #">
  <img src="https://img.shields.io/badge/ScubaGear-v1.2.0-%2328B953?labelColor=%23005288" />
</a>
<p>

# ScubaGear

ScubaGear is an assessment tool that verifies that a Microsoft 365 (M365) tenant’s configuration conforms to the policies described in the Secure Cloud Business Applications ([SCuBA](https://cisa.gov/scuba)) Security Configuration Baseline [documents](/baselines/README.md).

> **Note**: This documentation can be read using [GitHub Pages](https://cisagov.github.io/ScubaGear).

## Target Audience

ScubaGear is for M365 administrators who want to assess their tenant environments against CISA Secure Configuration Baselines.

## Overview

ScubaGear uses a three-step process:

- **Step One** - PowerShell code queries M365 APIs for various configuration settings.
- **Step Two** - It then calls [Open Policy Agent](https://www.openpolicyagent.org) (OPA) to compare these settings against Rego security policies written per the baseline documents.
- **Step Three** - Finally, it reports the results of the comparison as HTML, JSON, and CSV.

<img src="docs/images/scuba-process.png" />

## Getting Started

To install ScubaGear from [PSGallery](https://www.powershellgallery.com/packages/ScubaGear), open a PowerShell 5 terminal and install the module:

```powershell
# Install ScubaGear
Install-Module -Name ScubaGear
```

To install its dependencies:

```powershell
# Install the minimum required dependencies
Initialize-SCuBA 
```

To verify that it is installed:

```powershell
# Check the version
Invoke-SCuBA -Version
```

To run ScubaGear:

```powershell
# Assess all products
Invoke-SCuBA -ProductNames *
```

> **Note**:  Successfully running ScubaGear requires certain prerequisites and configuration settings.  To learn more, read through the sections below.

## Table of Contents

The following sections should be read in order.

### Installation

- [Install from PSGallery](docs/installation/psgallery.md)
- [Download from GitHub](docs/installation/github.md)
- [Uninstall](docs/installation/uninstall.md)

### Prerequisites

- [Dependencies](docs/prerequisites/dependencies.md)
- [Required Permissions](docs/prerequisites/permissions.md)
  - [Interactive Permissions](docs/prerequisites/interactive.md)
  - [Non-Interactive Permissions](docs/prerequisites/noninteractive.md)

### Execution

- [Execution](docs/execution/execution.md)
- [Reports](docs/execution/reports.md)

### Configuration

- [Parameters](docs/configuration/parameters.md)
- [Configuration File](docs/configuration/configuration.md)

### Troubleshooting

- [Multiple Tenants](docs/troubleshooting/tenants.md)
- [Defender](docs/troubleshooting/defender.md)
- [Exchange Online](docs/troubleshooting/exchange.md)
- [Power Platform](docs/troubleshooting/power.md)
- [Microsoft Graph](docs/troubleshooting/graph.md)
- [Proxy](docs/troubleshooting/proxy.md)

### Misc

- [Assumptions](docs/misc/assumptions.md)

## Project License

Unless otherwise noted, this project is distributed under the Creative Commons Zero license. With developer approval, contributions may be submitted with an alternate compatible license. If accepted, those contributions will be listed herein with the appropriate license.