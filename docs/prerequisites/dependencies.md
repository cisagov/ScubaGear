# Dependencies

Before [executing](../execution/execution.md) ScubaGear, its dependencies must be installed:

```powershell
# Install the minimum required dependencies
Initialize-SCuBA 
```

> **Note**: ScubaGear utilizes several libraries from Microsoft to read data about their product configurations.  At least one of these libraries is tied to PowerShell 5.  Until Microsoft updates their library, ScubaGear will continue to use PowerShell 5.  As this version is only available on Windows, ScubaGear will only run on Windows.

`Initialize-SCuBA` will install several modules on your system. These modules are listed in [RequiredVersions.ps1](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/RequiredVersions.ps1).  It will also install [OPA](https://www.openpolicyagent.org).

> **Note**: The `Initialize-SCuBA` cmdlet creates a `.scubagear` folder in the users home directory.  This is where it stores OPA and any other related files.

## OPA Installation

Normally, the `Initialize-SCuBA` cmdlet installs OPA.  This can be verified by looking for the OPA executable file in `C:\Users\johndoe\.scubagear\Tools`.  If it failed to do so, or you set a parameter to prevent it from doing so, you can install OPA separately.

Try this cmdlet first:

```powershell
# Download OPA
Install-OPA
```

If that fails, you can manually download the OPA executable.

* Go to the [OPA download site](https://www.openpolicyagent.org/docs/latest/#running-opa).

* In the upper left corner, select a version of OPA that is compatible with ScubaGear.

![version](../images/opa_version.png)

> **Note**: To find the default supported version, go to the [ScubaConfig](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfig.psm1) file, look for the variable `$ScubaDefaults`, and find its parameter `DefaultOPAVersion`.  

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

Once the dependencies have been installed, you are ready to set the [permissions](permissions.md).