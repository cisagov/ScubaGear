# Script to uninstall Microsoft.Graph modules higher than 2.25.0 and install version 2.25.0
# Run this script in a fresh PowerShell session (not in VS Code)

Write-Information "Step 1: Removing Microsoft.Graph modules from current session..." -InformationAction Continue
Get-Module Microsoft.Graph* | Remove-Module -Force -ErrorAction SilentlyContinue

Write-Information "`nStep 2: Getting list of installed Microsoft.Graph modules..." -InformationAction Continue
$installedModules = Get-InstalledModule -Name Microsoft.Graph* -ErrorAction SilentlyContinue

if ($installedModules) {
    Write-Information "Found $($installedModules.Count) Microsoft.Graph modules installed" -InformationAction Continue
    
    Write-Information "`nStep 3: Uninstalling modules with version greater than 2.25.0..." -InformationAction Continue
    foreach ($module in $installedModules) {
        if ([version]$module.Version -gt [version]"2.25.0") {
            Write-Information "  Uninstalling $($module.Name) version $($module.Version)..." -InformationAction Continue
            try {
                Uninstall-Module -Name $module.Name -RequiredVersion $module.Version -Force -ErrorAction Stop
                Write-Information "    Successfully uninstalled $($module.Name) $($module.Version)" -InformationAction Continue
            }
            catch {
                Write-Warning "    Failed to uninstall $($module.Name) $($module.Version): $_"
            }
        }
        else {
            Write-Verbose "  Skipping $($module.Name) version $($module.Version) (not greater than 2.25.0)"
        }
    }
}
else {
    Write-Information "No Microsoft.Graph modules found" -InformationAction Continue
}

Write-Information "`nStep 4: Installing version 2.25.0 of Microsoft.Graph modules..." -InformationAction Continue
$modulesToInstall = @(
    'Microsoft.Graph.Applications',
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Groups',
    'Microsoft.Graph.Identity.DirectoryManagement',
    'Microsoft.Graph.Identity.SignIns'
)

foreach ($moduleName in $modulesToInstall) {
    Write-Information "  Installing $moduleName version 2.25.0..." -InformationAction Continue
    try {
        Install-Module -Name $moduleName -RequiredVersion 2.25.0 -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
        Write-Information "    Successfully installed $moduleName 2.25.0" -InformationAction Continue
    }
    catch {
        Write-Warning "    Failed to install $moduleName 2.25.0: $_"
    }
}

Write-Information "`nStep 5: Verifying installed versions..." -InformationAction Continue
Get-InstalledModule -Name Microsoft.Graph* | Select-Object Name, Version | Sort-Object Name | Format-Table -AutoSize

Write-Information "`nScript completed!" -InformationAction Continue
