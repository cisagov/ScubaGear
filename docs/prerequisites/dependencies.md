# Dependencies

Before [executing](../execution/execution.md) ScubaGear, its dependencies must be installed:

```powershell
# Install the minimum required dependencies
Initialize-SCuBA
```

> **Note**: ScubaGear utilizes several libraries from Microsoft to read data about their product configurations.  At least one of these libraries is tied to PowerShell 5.  Until Microsoft updates their library, ScubaGear will continue to use PowerShell 5.  As this version is only available on Windows, ScubaGear will only run on Windows.

`Initialize-SCuBA` will install the modules in the [PowerShell Module Dependencies](#powershell-module-dependencies) section on your system. It will also install [OPA](https://www.openpolicyagent.org).

> **Note**: The `Initialize-SCuBA` cmdlet creates a `.scubagear` folder in the users home directory.  This is where it stores OPA and any other related files.

## PowerShell Module Dependencies

The following PowerShell modules are required for ScubaGear to function properly. These modules and their version constraints are defined in [RequiredVersions.ps1](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/RequiredVersions.ps1):

| Module Name                                   | Minimum Version | Maximum Version  | Purpose                                      |
|:---------------------------------------------:|:---------------:|:----------------:|:---------------------------------------------|
| MicrosoftTeams |           4.9.3 |            7.5.0 | Microsoft Teams configuration management |
| ExchangeOnlineManagement |           3.2.0 |            3.9.0 | Exchange Online and Microsoft Defender management |
| Microsoft.Online.SharePoint.PowerShell |          16.0.0 | 16.0.24810.12000 | SharePoint and OneDrive management |
| PnP.PowerShell |          1.12.0 |       1.99.99999 | SharePoint Online management and automation |
| Microsoft.PowerApps.Administration.PowerShell |         2.0.198 |          2.0.216 | Power Platform administrative functions |
| Microsoft.PowerApps.PowerShell |           1.0.0 |           1.0.45 | Power Apps development and management |
| Microsoft.Graph.Authentication |           2.0.0 |           2.25.0 | Microsoft Graph API authentication |
| powershell-yaml |           0.4.2 |           0.4.12 | YAML file processing and configuration management |

> **Note**: The maximum versions are updated to the latest available versions on a scheduled basis.

## OPA Installation

Normally, the `Initialize-SCuBA` cmdlet installs OPA.  This can be verified by looking for the OPA executable file in `C:\Users\johndoe\.scubagear\Tools`.  If it failed to do so, or you set a parameter to prevent it from doing so, you can install OPA separately.

Try this cmdlet first:

```powershell
# Download OPA
Install-OPAforSCuBA
```

If that fails, you can manually download the OPA executable.

* Go to the [OPA download site](https://www.openpolicyagent.org/docs/latest/#running-opa).

* In the upper left corner, select a version of OPA that is compatible with ScubaGear.

![version](../images/opa_version.png)

[![OPA Latest Version](https://img.shields.io/github/v/release/open-policy-agent/opa?label=OPA%20Latest%20Version&color=blue)](https://github.com/open-policy-agent/opa/releases)
[![OPA Tested Version](https://img.shields.io/badge/SCuBA%20OPA%20Tested%20Version-v1.13.1-green)](https://github.com/open-policy-agent/opa/releases/tag/v1.13.1)

> **Note**: You can also find the default supported version in the ScubaGear module: go to the [ScubaConfig](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1) file, look for the variable `$ScubaDefaults`, and find its parameter `DefaultOPAVersion`.

> **Note**: To find older supported versions, go to the [Support](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Modules/Support/Support.psm1) file, and find the constant named `$ACCEPTABLEVERSIONS`.

* Using the navigation menu on the left side, click `Introduction`, then `Running OPA`, and then `Download OPA`.

* On the main portion of the screen, find the paragraph in the blue box that begins with "Windows users can obtain the OPA executable from here" and click the link in "here" to download the executable.

* Locate the downloaded executable file and move it to `C:\Users\johndoe\.scubagear\Tools`, creating the `Tools` folder if it does not already exist.

To verify that OPA is working, use the following command to check the version:

```powershell
# Navigate to the Tools folder.
# Check the OPA version
.\opa_windows_amd64.exe version
```

> **Note**: If ScubaGear is having trouble finding the OPA executable in the `Tools` folder, place the OPA executable in the directory from which you are executing `Invoke-SCuBA`. ScubaGear will also attempt to look in the current executing directory for the OPA executable.

Once the dependencies have been installed, you are ready to set the [permissions](permissions.md).





