[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'moduleVersion')]
# Purpose: Called by ps_dependencies_requiredversionsfile.yaml to update the MaximumVersion sections in the RequiredVersions.ps1 file.
# This script excludes Microsoft.Online.SharePoint.PowerShell from version updates.

# Define modules to exclude from version updates
$ExcludedModules = @(
    'Microsoft.Online.SharePoint.PowerShell'
)

# Read the dependencies.ps1 file content
$dependenciesContent = Get-Content -Path './PowerShell/ScubaGear/RequiredVersions.ps1' -Raw

# Split the content into lines
$lines = $dependenciesContent -split "`n"

$updated = $false
$moduleName = $null
$maxVersion = $null

# Iterate through each line and update the MaximumVersion if necessary
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]

    if ($line -match "ModuleName\s*=\s*'([^']+)'") {
        $moduleName = $matches[1]
    }
    if ($line -match "MaximumVersion\s*=\s*\[version\]\s*'([^']+)'") {
        $maxVersion = $matches[1]

        # Check if this module should be excluded from updates
        if ($moduleName -in $ExcludedModules) {
            Write-Output "Skipping version update for excluded module: $moduleName" -ForegroundColor Yellow
            continue
        }

        try {
            $latestVersion = Find-Module -Name $moduleName | Select-Object -ExpandProperty Version

            if ($null -ne $latestVersion -and $maxVersion -ne $latestVersion) {
                $lines[$i] = $line -replace "MaximumVersion = \[version\] '$maxVersion'", "MaximumVersion = [version] '$latestVersion'"
                Write-Output "Updated $moduleName from version $maxVersion to $latestVersion" -ForegroundColor Green
                $updated = $true
            }
            else {
                Write-Output "No update needed for $moduleName (current: $maxVersion)" -ForegroundColor Gray
            }
        }
        catch {
            Write-Warning "Failed to find latest version for module: $moduleName. Error: $($_.Exception.Message)"
        }
    }
}

if ($updated) {
    # Join the lines back into a single string
    $updatedContent = $lines -join "`n"
    # Write the updated content back to the RequiredVersions.ps1 file
    Set-Content -Path './PowerShell/ScubaGear/RequiredVersions.ps1' -Value $updatedContent
    Write-Output "RequiredVersions.ps1 file has been updated successfully." -ForegroundColor Green
}
else {
    Write-Output "No updates were necessary. All modules are already at the latest version or excluded." -ForegroundColor Cyan
}
