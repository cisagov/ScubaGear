# Removing ScubaGear dependencies with `Remove-ScubaModuleVersion`
To remove some or all installed dependencies for purpose of dependency conflict resolution, or for ensuring current and proper installation, or troubleshooting ScubaGear issues then invoking `Remove-ScubaModuleVersion` is desired. Read the help provided via `Get-Help Remove-ScubaModuleVersion` for usage.

### UninstallModules.ps1 is retired

The script `UninstallModules.ps1` has been removed from ScubaGear. Previously, this script removed the Powershell modules required by the ScubaGear assessment tool.

**Note**: The ScubaGear development team is decrementing dependence on PowerShell SDK modules in favor of direct REST API calls. While a minimal PowerShell SDK module dependency remains in the current release of ScubaGear, prior releases may have had several PowerShell SDK dependencies.

# Uninstall 

To uninstall ScubaGear, follow these steps:

### Uninstall dependencies

Square brackets reflect the example outputs, below numbered.

1. Import the support module via the statement `Import-Module PowerShell/ScubaGear/Modules/Support/Support.psm1`. [1]
2. List installed dependencies using the `Get-ScubaGearDependencyStatus` function. [2] Note that OPA is not a module, and is listed with modules for completeness only.
3. Invoke help via `Get-Help Remove-ScubaModuleVersion`. [3]
4. With exception of OPA, use the `Remove-ScubaModuleVersion` function to remove an installed module, passing the `ModuleName` and `Version` parameters as identified in the output of number 3, above. Note the results returned in the `Removed` and `Warning` properties. [4]
5. Use the `Get-ScubaDependencyStatus` function to verify removal. [5]

### Example outputs ###
1. Import the support module via the statement `Import-Module PowerShell/ScubaGear/Modules/Support/Support.psm1`.
```PowerShell
PS C:\Users\user\github.com\ScubaGear> Import-Module .\PowerShell\ScubaGear\Modules\Support\Support.psm1
```

2. List installed dependencies using the `Get-ScubaGearDependencyStatus` function.
```PowerShell
PS C:\Users\user\github.com\ScubaGear> Get-ScubaGearDependencyStatus

ModuleName                       Installed   Versions HighestVersion  Status     Action
----------                       ---------   -------- --------------  ------     ------
Microsoft.Graph.Authentication   True               1 2.25.0          OK         None
powershell-yaml                  True               1 0.4.12          OK         None
OPA                              True               1 1.20.2          OK         None
ScubaGear                        True               1 1.8.0           OK         None


PS C:\Users\user\github.com\ScubaGear>
```

3. Invoke help via `Get-Help Remove-ScubaModuleVersion`, and familiarize yourself with the purpose and syntax of the `Remove-ScubaModuleVersion` function.
```PowerShell
PS C:\Users\user\github.com\ScubaGear> Get-Help Remove-ScubaModuleVersion

NAME
    Remove-ScubaModuleVersion

SYNOPSIS
    Removes a single installed version of a ScubaGear dependency module.


SYNTAX
    Remove-ScubaModuleVersion [-ModuleName] <String> [-Version] <Version> [<CommonParameters>]


DESCRIPTION
    Uninstalls the specified version with Uninstall-Module and, when that fails (for example
    because the module was not installed via PowerShellGet), falls back to deleting the module
    folder. Returns the outcome rather than writing to the caller''s result object so both the
    update and cleanup paths in Reset-ScubaGearDependencies can share this logic.


RELATED LINKS

REMARKS
    To see the examples, type: "get-help Remove-ScubaModuleVersion -examples".
    For more information, type: "get-help Remove-ScubaModuleVersion -detailed".
    For technical information, type: "get-help Remove-ScubaModuleVersion -full".



PS C:\Users\user\github.com\ScubaGear>
```

4. Use the Remove-ScubaModuleVersion function to remove an installed module, passing the ModuleName and Version parameters.
```PowerShell
PS C:\Users\user\github.com\ScubaGear> Remove-ScubaModuleVersion -ModuleName powershell-yaml -Version 0.4.12

Removed Warning
------- -------
  True


PS C:\Users\user\github.com\ScubaGear>
```

5. Use the `Get-ScubaDependencyStatus` function to verify removal.
```PowerShell
PS C:\Users\user\github.com\ScubaGear> Get-ScubaGearDependencyStatus

ModuleName                       Installed   Versions HighestVersion  Status     Action
----------                       ---------   -------- --------------  ------     ------
Microsoft.Graph.Authentication   True               1 2.25.0          OK         None
powershell-yaml                  False              0                 MISSING    Install
OPA                              True               1 1.20.2          OK         None
ScubaGear                        True               1 1.8.0           OK         None


PS C:\Users\user\github.com\ScubaGear>
```

### Uninstall OPA by deleting the `.scubagear` folder in the user's home directory.

```powershell
# Delete .scubagear folder
Remove-Item C:\Users\johndoe\.scubagear
```

### Uninstall ScubaGear itself.

```powershell
# Uninstall ScubaGear
Uninstall-Module -Name ScubaGear 
```

* If ScubaGear was [downloaded from GitHub](github.md), delete the ScubaGear folder that was extracted from the zip file.
