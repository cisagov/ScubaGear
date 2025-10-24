[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'moduleVersion')]
# Purpose: Called by ps_dependencies_requiredversionsfile.yaml to update the MaximumVersion sections in the RequiredVersions.ps1 file.
# This script respects the IsPinned property to exclude modules from version updates.

# Enable Information stream to display Write-Information output
$InformationPreference = 'Continue'

# Read and execute the RequiredVersions.ps1 file to get the module list
$scriptPath = './PowerShell/ScubaGear/RequiredVersions.ps1'
$originalContent = Get-Content -Path $scriptPath -Raw
$originalLines = $originalContent -split "`n"

# Execute the script to get the ModuleList variable
. $scriptPath

$updated = $false
$newLines = $originalLines.Clone()

# First pass: collect module information by scanning complete module blocks
$moduleInfo = @{}
$currentModuleName = $null
$inModuleBlock = $false
$moduleStartIndex = -1

for ($i = 0; $i -lt $newLines.Length; $i++) {
    $line = $newLines[$i]

    # Detect start of module block
    if ($line -match "^\s*@\{") {
        $inModuleBlock = $true
        $moduleStartIndex = $i
        $currentModuleName = $null
    }

    # Detect end of module block
    if ($line -match "^\s*\}") {
        $inModuleBlock = $false
        if ($currentModuleName) {
            $moduleInfo[$currentModuleName].EndIndex = $i
        }
    }

    if ($inModuleBlock) {
        # Track current module name
        if ($line -match "ModuleName\s*=\s*'([^']+)'") {
            $currentModuleName = $matches[1]
            $moduleInfo[$currentModuleName] = @{
                StartIndex = $moduleStartIndex
                EndIndex = -1
                IsPinned = $false
                Purpose = $null
                MaxVersionLineIndex = -1
                MaxVersion = $null
            }
        }

        # Check if current module is pinned
        if ($line -match "IsPinned\s*=\s*[`"']([^`"']+)[`"']" -and $currentModuleName) {
            $moduleInfo[$currentModuleName].IsPinned = $matches[1] -eq "True"
        }

        # Track Purpose field
        if ($line -match "Purpose\s*=\s*'([^']+)'" -and $currentModuleName) {
            $moduleInfo[$currentModuleName].Purpose = $matches[1]
        }

        # Track MaximumVersion line
        if ($line -match "MaximumVersion\s*=\s*\[version\]\s*'([^']+)'" -and $currentModuleName) {
            $moduleInfo[$currentModuleName].MaxVersionLineIndex = $i
            $moduleInfo[$currentModuleName].MaxVersion = $matches[1]
        }
    }
}

# Second pass: update versions for non-pinned modules
foreach ($moduleName in $moduleInfo.Keys) {
    $module = $moduleInfo[$moduleName]

    if ($module.IsPinned) {
        Write-Information "Skipping version update for pinned module: $moduleName" -InformationAction Continue
        continue
    }

    if ($module.MaxVersionLineIndex -ge 0) {
        try {
            $latestVersion = Find-Module -Name $moduleName | Select-Object -ExpandProperty Version

            if ($null -ne $latestVersion -and $module.MaxVersion -ne $latestVersion) {
                $oldLine = $newLines[$module.MaxVersionLineIndex]
                $newLines[$module.MaxVersionLineIndex] = $oldLine -replace "MaximumVersion = \[version\] '$($module.MaxVersion)'", "MaximumVersion = [version] '$latestVersion'"
                Write-Information "Updated $moduleName from version $($module.MaxVersion) to $latestVersion" -InformationAction Continue
                $updated = $true
            }
            else {
                Write-Information "No update needed for $moduleName (current: $($module.MaxVersion))" -InformationAction Continue
            }
        }
        catch {
            Write-Warning "Failed to find latest version for module: $moduleName. Error: $($_.Exception.Message)"
        }
    }
}

if ($updated) {
    # Clean up trailing whitespace from all lines before writing
    for ($i = 0; $i -lt $newLines.Length; $i++) {
        $newLines[$i] = $newLines[$i].TrimEnd()
    }

    # Join the updated lines back into content and write to file
    $newContent = $newLines -join "`n"
    Set-Content -Path $scriptPath -Value $newContent
    Write-Information "RequiredVersions.ps1 file has been updated successfully." -InformationAction Continue
}
else {
    Write-Information "No updates were necessary. All modules are already at the latest version or pinned." -InformationAction Continue
}
