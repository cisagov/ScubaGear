[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'moduleVersion')]
# Purpose: Called by ps_dependencies_requiredversionsfile.yaml to update the MaximumVersion sections in the RequiredVersions.ps1 file.

# Read the dependencies.ps1 file content
$dependenciesContent = Get-Content -Path './PowerShell/ScubaGear/RequiredVersions.ps1' -Raw

# Split the content into lines
$lines = $dependenciesContent -split "`n"

$updated = $false
$moduleName = $null
$moduleVersion = $null
$maxVersion = $null

# Iterate through each line and update the MaximumVersion if necessary
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]

    if ($line -match "ModuleName\s*=\s*'([^']+)'") {
        $moduleName = $matches[1]
    }
    if ($line -match "ModuleVersion\s*=\s*\[version\]\s*'([^']+)'") {
        $moduleVersion = $matches[1]
    }
    if ($line -match "MaximumVersion\s*=\s*\[version\]\s*'([^']+)'") {
        $maxVersion = $matches[1]


        $latestVersion = Find-Module -Name $moduleName | Select-Object -ExpandProperty Version

        if ($latestVersion -ne $null -and $latestVersion -ne $maxVersion) {
            $lines[$i] = $line -replace "MaximumVersion = \[version\] '$maxVersion'", "MaximumVersion = [version] '$latestVersion'"
            $updated = $true
        }
    }
}

if ($updated) {
    # Join the lines back into a single string
    $updatedContent = $lines -join "`n"
    # Write the updated content back to the dependencies.ps1 file
    Set-Content -Path './PowerShell/ScubaGear/RequiredVersions.ps1' -Value $updatedContent
}
