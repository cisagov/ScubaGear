# ScubaGear Update Instructions

ScubaGear releases new versions regularly. This guide provides detailed instructions for updating ScubaGear to the latest version, whether you installed it via PSGallery or from a GitHub release.

## Table of Contents
- [1. Updating ScubaGear](#1-updating-scubagear)
  - [Verify Status](#verify-if-update-is-needed)
  - [Option 1: Updating via PSGallery](#option-1-updating-via-psgallery-recommended)
  - [Option 2: Updating via GitHub Release](#option-2-updating-via-github-release)
- [2. Dependency Updating](#2-dependency-updating)
  - [Removing Old Dependencies](#removing-old-dependencies)
  - [Reset Dependencies](#option-a-reset-all-dependencies)
  - [Install Dependencies](#option-b-installupdate-dependencies-only)
- [3. Support and Resources](#3-support-and-resources)
  - [Troubleshooting](#troubleshooting)
  - [Additional Resources](#additional-resources)

# 1. Updating ScubaGear
There are multiple ways to update ScubaGear, the below two options are the most common. PSGallery is the preferred option.

The current version that should be installed is:<br>
[![ScubaGear Latest Version](https://img.shields.io/github/v/release/cisagov/ScubaGear?label=ScubaGear%20Latest%20Version&color=blue)](https://github.com/cisagov/ScubaGear/releases)

> [!NOTE]
> All options should be run under Windows PowerShell (version 5.1). **Do not attempt to install modules using PowerShell 7.x**.<br>
> Based on where the modules are located you may need to run as Administrator. You will be informed if needed.

## Verify if update is needed

**What this does:**  Checks the status of the ScubaGear module and related dependencies. Results are reported for the ScubaGear module and all related dependencies - see the [Dependency Updating of this page](#2-dependency-updating) for details.

**Prerequisites:**
- Internet connection to check latest versions
- Ability to access PSGallery or GitHub

1. Open PowerShell.
2. Run one of the following commands:
```powershell
# The below will check in PSGallery for the latest ScubaGear version
PS C:\Users\ScubaGear> Test-ScubaGearVersion

# The below will check in the ScubaGear GitHub repo for the latest version
PS C:\Users\ScubaGear> Test-ScubaGearVersion -CheckGitHub
```

> [!NOTE]
> If the `Test-ScubaGearVersion` command is not recognized, ScubaGear may not be installed or the module may not be imported. Try running `Import-Module ScubaGear` first, or refer to the installation guides if ScubaGear is not installed: [PSGallery Installation](psgallery.md) | [GitHub Installation](github.md)

**If you see this error:**
```powershell
PS C:\Users\ScubaGear> Test-ScubaGearVersion
Test-ScubaGearVersion : The term 'Test-ScubaGearVersion' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At line:1 char:1
+ Test-ScubaGearVersion
+ ~~~~~~~~~~~~~~~~~~~~~
   + CategoryInfo          : ObjectNotFound: (test-ScubaGearVersion:String) [], CommandNotFoundException
   + FullyQualifiedErrorId : CommandNotFoundException
```
**Solution:** ScubaGear is not installed or not loaded. Use the installation links above to install ScubaGear first.

3. **Interpret your results** using the table below:

| Status Output | What It Means | Next Action |
|---------------|---------------|-------------|
| Status: **Up to Date**<br>MultipleVersionsInstalled: **False** | System is current | No action needed |
| Status: **Update Available** | Newer version available | Run `Update-ScubaGear` to update |
| Status: **Needs attention**<br>MultipleVersionsInstalled: **True** | Multiple versions installed | Run `Update-ScubaGear` to clean up |

### Example Outputs

**System Current:**
   ```powershell
   PS C:\Users\ScubaGear> Test-ScubaGearVersion

   Component                 : ScubaGear
   CurrentVersion            : 1.6.0
   LatestVersion             : 1.6.0
   Status                    : Up to Date
   MultipleVersionsInstalled : False
   AdminRequired             : False
   Recommendations           : No action needed.
   ```

**Update Available:**
   ```powershell
   PS C:\Users\ScubaGear> Test-ScubaGearVersion

   Component                 : ScubaGear
   CurrentVersion            : 1.5.0
   LatestVersion             : 1.6.0
   Status                    : Update Available
   MultipleVersionsInstalled : False
   AdminRequired             : False
   Recommendations           : Update available: 1.5.0 → 1.6.0, Run 'Update-ScubaGear' to update to latest version.
   ```

**Multiple Versions Installed:**
   ```powershell
   PS C:\Users\ScubaGear> Test-ScubaGearVersion

   Component                 : ScubaGear
   CurrentVersion            : 1.6.0
   LatestVersion             : 1.6.0
   Status                    : Needs attention
   MultipleVersionsInstalled : True
   AdminRequired             : False
   Recommendations           : 2 versions installed. Run 'Update-ScubaGear' to clean up.
   ```

## Option 1: Updating via PSGallery (Recommended)

**What it does:** Removes all existing ScubaGear versions and installs the latest from PSGallery.

**Use this when:**
- You want the most reliable update method
- You have multiple versions installed that need cleanup
- You prefer automated dependency management
- You're updating from any previous version

> [!IMPORTANT]
> Close all PowerShell windows that may have the ScubaGear module loaded to avoid issues.


1. Open PowerShell.
2. Run the following command to update:
   ```powershell
   PS C:\Users\ScubaGear> Update-ScubaGear
   Updating ScubaGear from PSGallery...
   Removing all existing ScubaGear versions...
   Installing latest ScubaGear from PSGallery...
   ScubaGear updated to version 1.6.0
   ```
3. You can verify the above was successful by running the below command.
   ```powershell
   PS C:\Users\ScubaGear> Test-ScubaGearVersion

   Component                 : ScubaGear
   CurrentVersion            : 1.6.0
   LatestVersion             : 1.6.0
   Status                    : Up to Date
   MultipleVersionsInstalled : False
   AdminRequired             : False
   Recommendations           : No action needed.
   ```

## Option 2: Updating via GitHub Release

**What it does:** Downloads and installs the latest ScubaGear release directly from GitHub.

**Use this when:**
- PSGallery is not accessible in your environment
- You need a specific GitHub release version
- You prefer manual download and installation
- Corporate policies require direct GitHub downloads

1. Open PowerShell.
2. Run the following commands to update from GitHub.
    ```powershell
   PS C:\Users\ScubaGear> Update-ScubaGear -Source GitHub
    ```
3. The output should look similar to the below.
   ```powershell
   PS C:\Users\ScubaGear> Update-ScubaGear -Source GitHub
   Updating ScubaGear from GitHub...
   Removing all existing ScubaGear versions...
   Downloading ScubaGear 1.6.0 from GitHub...
   Installing ScubaGear 1.6.0...
   ScubaGear 1.6.0 installed successfully from GitHub
   ```

# 2. Dependency Updating
## Removing Old Dependencies
Removing old modules and ensuring different versions don't exist minimizes potential errors.

> [!NOTE]
> Before running the below it is recommended to close all PowerShell windows and reopen a new PowerShell window. This will ensure that all modules loaded will be removed from memory

## Option A: Reset All Dependencies

**What it does:** Removes and reinstalls all ScubaGear dependencies for a clean baseline.

**Use this when:**
- You have dependency conflicts
- You want to ensure all modules are current and properly installed
- You're troubleshooting ScubaGear issues

> [!IMPORTANT]
> This removes ALL existing dependency modules and reinstalls them. If other applications depend on specific module versions, use Option B instead to avoid breaking them.

> [!NOTE]
> You'll be prompted before any modules are removed.

1. Open PowerShell.
2. Run the following command to remove all ScubaGear dependencies and reinstall.
```powershell
   PS C:\Users\ScubaGear> Reset-ScubaGearDependencies
```

## Option B: Install/Update Dependencies Only

**What it does:** Installs missing dependencies and updates existing ones without removing any modules.

**Use this when:**
- You want to ensure dependencies are current
- Other applications share PowerShell modules with ScubaGear
- You prefer a less aggressive approach to dependency management
- You're doing routine maintenance

1. Open PowerShell.
2. Run the following command to install all ScubaGear dependencies.
   ```powershell
   PS C:\Users\ScubaGear> Initialize-SCuBA -Scope CurrentUser
   ```

# 3. Support and Resources

## Troubleshooting

**What this covers:** Common issues and resolution steps for ScubaGear updates.

**Try these steps:**
- Close out all PowerShell sessions to ensure no modules are loaded
- If you encounter issues after updating, ensure all old dependencies are removed
- Check the [ScubaGear Wiki](https://github.com/cisagov/ScubaGear/wiki) for additional help
- If problems persist, open an issue on the [ScubaGear Issues page](https://github.com/cisagov/ScubaGear/issues)


> [!IMPORTANT]
>  Some environments may not allow the scripts to run as an elevated administrator. Please refer to your organization's guidance on managing PowerShell modules.

## Additional Resources

**Available resources:**
- [ScubaGear Documentation](https://github.com/cisagov/ScubaGear/wiki) - Complete user guides and technical documentation
- [ScubaGear Releases](https://github.com/cisagov/ScubaGear/releases) - Latest versions and release notes
- [ScubaGear Issues](https://github.com/cisagov/ScubaGear/issues) - Report bugs or request features
