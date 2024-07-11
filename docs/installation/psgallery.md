# Install from PSGallery

Although ScubaGear can be [downloaded from GitHub](github.md), the recommended way to install it is from PSGallery. To install the latest version of ScubaGear, open a PowerShell 5 terminal and run the following commands:

```powershell
# Install ScubaGear
Install-Module -Name ScubaGear
```

> **Note**: PowerShell 5 is required because some of the SharePoint modules are incompatible with PowerShell 7.  This may be fixed in a future version.

To install a specific version of ScubaGear, use the `-RequiredVersion` parameter:

```powershell
# Install ScubaGear 1.2.0
Install-Module -Name ScubaGear `
  -RequiredVersion 1.2.0
```

The set of published versions can be found on [PSGallery](https://www.powershellgallery.com/packages/ScubaGear/).

Once PowerShell is installed, the required [dependencies](../prerequisites/dependencies.md) can be installed.
