# Script to uninstall Microsoft.Graph modules higher than 2.25.0 and install version 2.25.0
# Run this script in a fresh PowerShell session (not in VS Code)

Write-Host "Step 1: Removing Microsoft.Graph modules from current session..." -ForegroundColor Cyan
Get-Module Microsoft.Graph* | Remove-Module -Force -ErrorAction SilentlyContinue

Write-Host "`nStep 2: Getting list of installed Microsoft.Graph modules..." -ForegroundColor Cyan
$installedModules = Get-InstalledModule -Name Microsoft.Graph* -ErrorAction SilentlyContinue

if ($installedModules) {
    Write-Host "Found $($installedModules.Count) Microsoft.Graph modules installed" -ForegroundColor Yellow
    
    Write-Host "`nStep 3: Uninstalling modules with version greater than 2.25.0..." -ForegroundColor Cyan
    foreach ($module in $installedModules) {
        if ([version]$module.Version -gt [version]"2.25.0") {
            Write-Host "  Uninstalling $($module.Name) version $($module.Version)..." -ForegroundColor Yellow
            try {
                Uninstall-Module -Name $module.Name -RequiredVersion $module.Version -Force -ErrorAction Stop
                Write-Host "    Successfully uninstalled $($module.Name) $($module.Version)" -ForegroundColor Green
            }
            catch {
                Write-Warning "    Failed to uninstall $($module.Name) $($module.Version): $_"
            }
        }
        else {
            Write-Host "  Skipping $($module.Name) version $($module.Version) (not greater than 2.25.0)" -ForegroundColor Gray
        }
    }
}
else {
    Write-Host "No Microsoft.Graph modules found" -ForegroundColor Yellow
}

Write-Host "`nStep 4: Installing version 2.25.0 of Microsoft.Graph modules..." -ForegroundColor Cyan
$modulesToInstall = @(
    'Microsoft.Graph.Applications',
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Groups',
    'Microsoft.Graph.Identity.DirectoryManagement',
    'Microsoft.Graph.Identity.SignIns'
)

foreach ($moduleName in $modulesToInstall) {
    Write-Host "  Installing $moduleName version 2.25.0..." -ForegroundColor Yellow
    try {
        Install-Module -Name $moduleName -RequiredVersion 2.25.0 -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
        Write-Host "    Successfully installed $moduleName 2.25.0" -ForegroundColor Green
    }
    catch {
        Write-Warning "    Failed to install $moduleName 2.25.0: $_"
    }
}

Write-Host "`nStep 5: Verifying installed versions..." -ForegroundColor Cyan
Get-InstalledModule -Name Microsoft.Graph* | Select-Object Name, Version | Sort-Object Name | Format-Table -AutoSize

Write-Host "`nScript completed!" -ForegroundColor Green
