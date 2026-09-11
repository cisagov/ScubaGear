# Uninstall

The legacy dependency-uninstall script has been retired. Use this guide to remove
ScubaGear and dependencies that you no longer need. To repair an installation
instead, see [Reinstall dependencies](#reinstall-dependencies).

## Identify installed modules

Close PowerShell sessions that have ScubaGear or its dependencies loaded, then
open a new Windows PowerShell session. Save any configuration files and reports
that you want to keep before deleting installation folders.

List the installed ScubaGear versions and their locations:

```powershell
Get-Module -ListAvailable -Name ScubaGear |
    Select-Object Name, Version, ModuleBase
```

For a [GitHub installation](github.md), also check the folder where you extracted
the release or cloned the repository. A module imported directly from that folder
may not appear in `Get-Module -ListAvailable` unless its location is on the module
search path.

The [dependency list](../prerequisites/dependencies.md#powershell-module-dependencies)
and `PowerShell/ScubaGear/RequiredVersions.ps1` in the release you installed identify
its required modules. Newer releases use direct REST API calls for more services,
so some modules required by older releases are no longer needed by ScubaGear.

To find current dependencies and common legacy modules, inspect:

```powershell
Get-Module -ListAvailable -Name 'Microsoft.Graph.*', 'MicrosoftTeams',
    'Microsoft.Online.SharePoint.PowerShell', 'PnP.PowerShell',
    'Microsoft.PowerApps.*', 'ExchangeOnlineManagement', 'powershell-yaml' |
    Select-Object Name, Version, ModuleBase
```

This is a discovery list, not proof that ScubaGear installed a module. Check the
requirements of your older ScubaGear release and any other tools that use these
modules before removing them. For Microsoft Graph, review the individual SDK
modules as well as the authentication module. Do not remove shared modules just
because a newer ScubaGear release no longer requires them.

Common Windows module locations include:

| Scope | Windows PowerShell | PowerShell 7 |
|:------|:-------------------|:-------------|
| Current user | `Documents\WindowsPowerShell\Modules` | `Documents\PowerShell\Modules` |
| All users | `C:\Program Files\WindowsPowerShell\Modules` | `C:\Program Files\PowerShell\Modules` |

The Documents folder may be redirected, including to OneDrive. Inspect the actual
`ModuleBase` values above and the search path in each PowerShell edition you use:

```powershell
$env:PSModulePath -split [IO.Path]::PathSeparator
```

Do not delete the entire module search path or modules bundled with PowerShell.
Removing an all-users installation may require an elevated session.

## Remove selected dependency versions

Use the package manager that installed the module. Review one module and version
at a time; older versions may still be required by another application.

For modules installed with `Install-Module` (PowerShellGet), list the registered
versions. This example uses `powershell-yaml`; substitute the dependency you
identified above:

```powershell
$ModuleName = 'powershell-yaml'
Get-InstalledModule -Name $ModuleName -AllVersions |
    Select-Object Name, Version, InstalledLocation
```

Set the exact version from that output, then preview its removal:

```powershell
$ModuleVersion = '0.4.12' # Replace with the installed version to remove.
Uninstall-Module -Name $ModuleName -RequiredVersion $ModuleVersion -WhatIf
```

After reviewing the preview, repeat the command without `-WhatIf` to uninstall
that version. Repeat for other versions only if they are no longer needed. If
PowerShell reports that another module depends on it, review that dependency
first instead of forcing removal.

For modules installed with `Install-PSResource`, use the corresponding
PSResourceGet commands if they are available in your session:

```powershell
Get-InstalledPSResource -Name $ModuleName -Scope CurrentUser
Uninstall-PSResource -Name $ModuleName -Version $ModuleVersion -Scope CurrentUser -WhatIf
```

Choose `AllUsers` instead if that is where the selected version was installed.
Review the result, then repeat without `-WhatIf`. Do not use both package managers
to remove the same installation.

If a module was copied manually, the package manager may not list it. Close any
sessions using it, confirm its `ModuleBase`, and remove only that module's
installation directory. Do not treat a package-manager error as permission to
delete a broader folder.

## Remove ScubaGear

For a PowerShellGet installation, inspect and preview removal of ScubaGear:

```powershell
Get-InstalledModule -Name ScubaGear -AllVersions |
    Select-Object Name, Version, InstalledLocation
Uninstall-Module -Name ScubaGear -AllVersions -WhatIf
```

After confirming that you want to remove every installed version, repeat the
uninstall command without `-WhatIf`. For a PSResourceGet installation, use the
same per-version procedure described above with `ScubaGear` as the module name.

For a GitHub download, delete the extracted ScubaGear directory after preserving
any reports or configuration files you stored there. If you manually copied the
module into a module search directory, remove that copy too. Removing the module
does not remove independently installed dependencies or OPA.

## Remove OPA and leftover files

The normal Windows OPA executable is
`$env:USERPROFILE\.scubagear\Tools\opa_windows_amd64.exe`.
`Install-OPAforSCuBA` downloads directly into this tools directory. If you supplied
`-ScubaParentDirectory`, check `.scubagear\Tools` under that parent instead; if you
supplied `-OPAExe`, check the filename you selected.

Inspect the default directory and preview removal of only the executable:

```powershell
$ScubaTools = Join-Path -Path $env:USERPROFILE -ChildPath '.scubagear\Tools'
Get-ChildItem -LiteralPath $ScubaTools -Force
$OpaExecutable = Join-Path -Path $ScubaTools -ChildPath 'opa_windows_amd64.exe'
Remove-Item -LiteralPath $OpaExecutable -WhatIf
```

If this copy is no longer needed, repeat the removal command without `-WhatIf`.
Inspect the remaining contents before removing the `.scubagear` directory; do
not assume it contains only OPA or disposable files.

Also check these locations if they were used by your installation:

- **Custom OPA folder:** the [OPAPath](../configuration/parameters.md#opapath)
  supplied in your configuration or command line.
- **Working directory:** a manually downloaded OPA executable may have been
  placed in the directory from which you ran `Invoke-SCuBA`. ScubaGear can fall
  back to that directory when the default tools directory is absent.
- **Download or temporary directory:** check where you saved manual downloads,
  including `$env:TEMP` if you used it. The normal OPA installer does not stage
  the executable there. The GitHub update path uses
  `$env:TEMP\ScubaGear.zip` and `$env:TEMP\ScubaGearExtract` for the ScubaGear
  release; an interrupted update can leave those artifacts behind.

Delete only identified ScubaGear artifacts that are no longer needed. Do not
clear the entire temporary directory, working directory, or a shared OPA
installation. Assessment reports and configuration files may live elsewhere;
keep them unless you intend to delete them separately.

## Verify removal

Open a fresh session and repeat `Get-Module -ListAvailable -Name ScubaGear` and
the inventory commands for the dependency names you removed. Check each
PowerShell edition and user account where you installed the modules. Retained
shared dependencies should still appear.

For the default OPA executable, confirm that this returns `False`:

```powershell
Test-Path -LiteralPath (Join-Path -Path $env:USERPROFILE -ChildPath '.scubagear\Tools\opa_windows_amd64.exe')
```

Check any custom OPA locations and manually copied modules separately. A module
missing from the current search path does not prove that every copy was deleted.

## Reinstall dependencies

If you are keeping ScubaGear and want to repair or reacquire its dependencies,
import ScubaGear and run:

```powershell
Reset-ScubaGearDependencies
```

This command uses the current dependency requirements and checks OPA. It can
install missing dependencies, update versions, and clean up duplicate versions;
it is not an uninstall-only command. If ScubaGear itself was removed, reinstall
it first using [PSGallery](psgallery.md) or [GitHub](github.md). See the
[update guide](update.md) for the available dependency-maintenance options.
