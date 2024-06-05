# Uninstall

To uninstall ScubaGear, follow these steps:

* Run the `UninstallModules.ps1` script in the `utils` folder to remove the modules that were installed.

```powershell
# Uninstall modules
.\UninstallModules.ps1
```

* Uninstall ScubaGear itself.

```powershell
# Uninstall ScubaGear
Uninstall-Module -Name ScubaGear 
```

* Uninstall OPA by deleting the `.scubagear` folder in the user's home directory.

```powershell
# Delete .scubagear folder
Remove-Item C:\Users\<username>\.scubagear
```

* If ScubaGear was [downloaded from GitHub](github.md), delete the ScubaGear folder that was extracted from the zip file.
