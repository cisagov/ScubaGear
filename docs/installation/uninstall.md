# Uninstall 

Removing a ScubaGear installation can be helpful for purpose of dependency conflict resolution, or for ensuring current and proper installation, or troubleshooting ScubaGear issues. This guide walks through examples of basic usage of functions provided in the current release of ScubaGear to perform a cleanup.

The following steps can facilitate cleanup of ScubaGear:

1. Identify and uninstall installed module dependencies
2. Identify and uninstall installed OPA dependencies
3. Uninstall ScubaGear itself

Several additional notes can be worth considering:
1. The `Reset-ScubaGearDependencies` function is an alternative to singly uninstalling modules. The function manages ScubaGear dependencies based on version requirements defined in the RequiredVersions.ps1 file and verifies the OPA (Open Policy Agent) executable is installed and up to date.
2. The script `UninstallModules.ps1` has been removed from ScubaGear. Previously, this script removed the Powershell modules required by the ScubaGear assessment tool.
3. The provided steps do not check whether or not another script depends on a module such as the Graph SDK. User and/or admin diligence is recommended.
4. The ScubaGear development team is reducing dependence on PowerShell SDK modules in favor of direct REST API calls. While a minimal PowerShell SDK module dependency remains in the current release of ScubaGear, prior releases had several PowerShell SDK dependencies.

## Preqrequisites

Removal via this guide requires the following conditions:
1. ScubaGear release v2.0.0 or later must be installed, or alternatively it must be imported into the current PowerShell session.
2. The `RequiredVersions.ps1` script from the ScubaGear release that is being cleaned up must be accessible.  `RequiredVersions.ps1` contains the dependencies for a release of ScubaGear.
3. Admin privilege is needed for clean up of modules that were installed for all users.

**Note**: Due to variations in the scope of module installation (i.e., All Users versus Current User), and to related search paths that vary between PowerShell versions, it is recommended to perfom clean up from the same user account(s) by which ScubaGear was installed, and from within the same PowerShell environment in which ScubaGear was installed.

## Identify installed dependencies

List the dependencies that are installed. Manual and automated example methods are provided as follows. For both methods, the older release should be extracted or moved away from the folder where ScubaGear is installed.

### Identifying dependencies manually

The method in this example fetches the installed module names in the `RequiredVersions.ps1` script, and provides the installed module name, version, and installation path (Module Base). Typical installation paths are inside of the user profile path when installed for Current User, and inside of Program Files path when installed for All Users.

```PowerShell
PS C:\Users\user> . C:\Users\user\ScubaGear-1.8.0\PowerShell\ScubaGear\RequiredVersions.ps1
PS C:\Users\user> $ModuleList | ForEach-Object { Get-Module -ListAvailable -Name $_.ModuleName } | Select-Object Name, Version, ModuleBase

> Name                           Version ModuleBase
> ----                           ------- ----------
> MicrosoftTeams                 7.5.0   C:\Users\user\Documents\WindowsPowerShell\Modules\MicrosoftTeams\7.5.0
> ExchangeOnlineManagement       3.9.0   C:\Users\user\Documents\WindowsPowerShell\Modules\ExchangeOnlineManagement\3.9.0
> Microsoft.Graph.Authentication 2.25.0  C:\Users\user\Documents\WindowsPowerShell\Modules\Microsoft.Graph.Authentication\2.25.0
> powershell-yaml                0.4.12  C:\Users\user\Documents\WindowsPowerShell\Modules\powershell-yaml\0.4.12
```

To list all of the modules that remain installed that the logged-in user has access to see, you may want use the `Get-Module -ListAvailable` statement.

### Identifying dependencies automatically

The `Get-ScubaGearDependencyStatus` function checks the status of modules listed in ScubaGear's `RequiredVersions.ps1` script. The function furthermore adds a check for installation of the OPA dependency which is not a PowerShell module, and for installation of ScubaGear itself, and proposes steps to resolve common issues. 

If the path to `RequiredVersions.ps1` is specified then the function will list modules from that particular release of ScubaGear. If the path is not specified then the function lists modules from the currently installed release.

#### Example 1: Dependencies for the installed release

```PowerShell
PS C:\Users\user> Get-ScubaGearDependencyStatus

> Run 'Update-ScubaGear' to update the ScubaGear module itself.
> 
> ModuleName                       Installed   Versions HighestVersion  Status     Action
> ----------                       ---------   -------- --------------  ------     ------
> powershell-yaml                  True               1 0.4.12          OK         None
> OPA                              True               1 1.20.2          OK         None
> ScubaGear                        False              0                 MISSING    Install
```

Optionally, we can also verify that the module's installation folder is gone, as follows:

```PowerShell
Get-ChildItem C:\Users\user\Documents\WindowsPowerShell\Modules\MicrosoftTeams\7.5.0

> Get-ChildItem : Cannot find path 'C:\Users\user\Documents\WindowsPowerShell\Modules\' because it does not exist. 
```

#### Example 2: Dependencies for a prior release

```PowerShell
PS C:\Users\user> Get-ScubaGearDependencyStatus -RequiredModulesPath C:\Users\user\ScubaGear-1.8.0\PowerShell\ScubaGear

> Run 'Update-ScubaGear' to update the ScubaGear module itself.
> 
> ModuleName                       Installed   Versions HighestVersion  Status     Action
> ----------                       ---------   -------- --------------  ------     ------
> MicrosoftTeams                   True               1 7.5.0           OK         None
> ExchangeOnlineManagement         True               1 3.9.0           OK         None
> Microsoft.Graph.Authentication   True               1 2.25.0          OK         None
> powershell-yaml                  True               1 0.4.12          OK         None
> OPA                              True               1 1.20.2          OK         None
> ScubaGear                        False              0                 MISSING    Install
```

### Uninstall module dependencies

Run the `Remove-ScubaModuleVersion` function to remove an installed module, providing the `ModuleName` and `Version` from the identification step. Note the results returned in the `Removed` and `Warning` properties. When the function returns with Removed being True, then removal was performed. Repeat identification performed previously to verify removal of the module.

#### Example: Use the `Remove-ScubaModuleVersion` function to remove an installed module.

In this example we remove the installed MicrosoftTeams module, and verify its removal:

```PowerShell
PS C:\Users\user> Remove-ScubaModuleVersion -ModuleName MicrosoftTeams -Version 7.5.0

> Removed Warning
> ------- -------
>    True
```

```PowerShell
PS C:\Users\user> Get-ScubaGearDependencyStatus -RequiredModulesPath C:\Users\user\ScubaGear-1.8.0\PowerShell\ScubaGear

> Run 'Install-ScubaDependencies' to install missing dependencies.
> Run 'Update-ScubaGear' to update the ScubaGear module itself.
> 
> ModuleName                       Installed   Versions HighestVersion  Status     Action
> ----------                       ---------   -------- --------------  ------     ------
> MicrosoftTeams                   False              0                 MISSING    Install
> ExchangeOnlineManagement         True               1 3.9.0           OK         None
> Microsoft.Graph.Authentication   True               1 2.25.0          OK         None
> powershell-yaml                  True               1 0.4.12          OK         None
> OPA                              True               1 1.20.2          OK         None
> ScubaGear                        False              0                 MISSING    Install
```

## Uninstall OPA by deleting the `.scubagear` folder in the user's home directory

```PowerShell
PS C:\Users\user> Remove-Item -Recurse C:\Users\user\.scubagear
```

## Uninstall ScubaGear itself

```PowerShell
# Uninstall ScubaGear
PS C:\Users\user> Uninstall-Module -Name ScubaGear
```

**Note**: If ScubaGear was [downloaded from GitHub](github.md), delete the ScubaGear folder that was extracted from the zip file.