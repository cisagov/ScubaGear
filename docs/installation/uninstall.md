```
To-do:
1. Write a note for Reset-ScubaGearGependencies, including syntax if not duplicative.
2. Cleanup: Remove comment line(s). Remove strikethrough line(s).
```

# Resetting ScubaGear dependencies with Reset-ScubaGearDependencies
To remove all installed dependencies for purpose of dependency conflict resolution, or ensuring current and proper installation, or troubleshooting ScubaGear issues then invoking Reset-ScubaGearDependencies is desired. Refer to Dependency Updating in docs / installation / update.md for usage.

### UninstallModules.ps1 is retired

The script UninstallModules.ps1 is no longer used, and has been removed from ScubaGear. Previously, this script removed the Powershell modules required by the ScubaGear assessment tool.


**Note**: The ScubaGear development team is gradually decrementing the dependencies on PowerShell SDK modules in favor of direct REST API calls. While there are very few PowerShell SDK modules required to run the current release of ScubaGear, a prior release may have had multiple additional PowerShell SDK dependencies, including but not limited to (for example) several Microsoft Graph SDK modules.

# Uninstall

To uninstall ScubaGear, follow these steps:

### Uninstall ScubaGear itself.

```powershell
# Uninstall ScubaGear
Uninstall-Module -Name ScubaGear 
```

### Uninstall OPA by deleting the `.scubagear` folder in the user's home directory.

```powershell
# Delete .scubagear folder
Remove-Item C:\Users\johndoe\.scubagear
```

* If ScubaGear was [downloaded from GitHub](github.md), delete the ScubaGear folder that was extracted from the zip file.
