# Purpose: Called by ps_dependencies_requiredversionsfile.yaml to update the dependencies.md table with current module versions from RequiredVersions.ps1

param(
    [Parameter(Mandatory = $false)]
    [string]
    $RequiredVersionsPath = './PowerShell/ScubaGear/RequiredVersions.ps1',

    [Parameter(Mandatory = $false)]
    [string]
    $DependenciesPath = './docs/prerequisites/dependencies.md'
)

function Get-ModulePurpose {
    param([string]$ModuleName)

    switch ($ModuleName) {
        'MicrosoftTeams' { return 'Microsoft Teams configuration management' }
        'ExchangeOnlineManagement' { return 'Exchange Online and Defender configuration' }
        'Microsoft.Online.SharePoint.PowerShell' { return 'SharePoint Online and OneDrive configuration' }
        'PnP.PowerShell' { return 'Alternative SharePoint PowerShell module' }
        'Microsoft.PowerApps.Administration.PowerShell' { return 'Power Platform administration' }
        'Microsoft.PowerApps.PowerShell' { return 'Power Platform management' }
        'Microsoft.Graph.Authentication' { return 'Microsoft Graph authentication' }
        'powershell-yaml' { return 'YAML configuration file support' }
        default { return 'PowerShell module dependency' }
    }
}

function Update-DependenciesTable {
    param(
        [string]$RequiredVersionsPath,
        [string]$DependenciesPath
    )

    Write-Output "Updating dependencies table from $RequiredVersionsPath to $DependenciesPath"

    # Read the RequiredVersions.ps1 file to get current module information
    if (-not (Test-Path $RequiredVersionsPath)) {
        throw "RequiredVersions.ps1 file not found at: $RequiredVersionsPath"
    }

    if (-not (Test-Path $DependenciesPath)) {
        throw "Dependencies.md file not found at: $DependenciesPath"
    }

    $RequiredVersionsContent = Get-Content -Path $RequiredVersionsPath -Raw

    # Parse the module list from RequiredVersions.ps1
    $ModuleList = @()
    $lines = $RequiredVersionsContent -split "`n"
    $currentModule = @{}

    foreach ($line in $lines) {
        $line = $line.Trim()

        if ($line -match "ModuleName\s*=\s*'([^']+)'") {
            $currentModule.ModuleName = $matches[1]
        }
        elseif ($line -match "ModuleVersion\s*=\s*\[version\]\s*'([^']+)'") {
            $currentModule.ModuleVersion = $matches[1]
        }
        elseif ($line -match "MaximumVersion\s*=\s*\[version\]\s*'([^']+)'") {
            $currentModule.MaximumVersion = $matches[1]
            $currentModule.Purpose = Get-ModulePurpose -ModuleName $currentModule.ModuleName

            $ModuleList += [PSCustomObject]$currentModule
            $currentModule = @{}
        }
    }

    Write-Output "Found $($ModuleList.Count) modules to update"

    # Read the current dependencies.md file
    $DependenciesContent = Get-Content -Path $DependenciesPath -Raw

    # Update each module row in the existing table
    $updatedCount = 0
    foreach ($module in $ModuleList) {
        # Create the properly formatted table row with consistent spacing
        $ModuleName = $module.ModuleName.PadRight(46)
        $MinVersion = $module.ModuleVersion.PadLeft(15)
        $MaxVersion = $module.MaximumVersion.PadLeft(16)
        $Purpose = $module.Purpose.PadRight(44)

        $NewRow = "| $($ModuleName.Substring(0, [Math]::Min(46, $ModuleName.Length)).TrimEnd()) | $($MinVersion.Substring(0, [Math]::Min(15, $MinVersion.Length)).TrimEnd()) | $($MaxVersion.Substring(0, [Math]::Min(16, $MaxVersion.Length)).TrimEnd()) | $($Purpose.Substring(0, [Math]::Min(44, $Purpose.Length)).TrimEnd()) |"

        # Find and replace the existing row for this module
        $EscapedModuleName = [regex]::Escape($module.ModuleName)
        $ExistingRowPattern = "\|\s*$EscapedModuleName\s*\|\s*[^|]+\|\s*[^|]+\|\s*[^|]+\|"

        if ($DependenciesContent -match $ExistingRowPattern) {
            $DependenciesContent = $DependenciesContent -replace $ExistingRowPattern, $NewRow
            Write-Output "✅ Updated row for module: $($module.ModuleName)"
            $updatedCount++
        } else {
            Write-Warning "❌ Could not find existing row for module: $($module.ModuleName)"
        }
    }

    # Write the updated content back to the file
    Set-Content -Path $DependenciesPath -Value $DependenciesContent -Encoding UTF8

    Write-Output "✅ Successfully updated $updatedCount out of $($ModuleList.Count) modules in dependencies.md"

    return $updatedCount
}

# Main execution
try {
    Update-DependenciesTable -RequiredVersionsPath $RequiredVersionsPath -DependenciesPath $DependenciesPath
    Write-Output "Dependencies table update completed successfully"
    exit 0
}
catch {
    Write-Error "Failed to update dependencies table: $_"
    exit 1
}