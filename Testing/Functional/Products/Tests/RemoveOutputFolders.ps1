<#
    .SYNOPSIS
    The purpose of this script is to delete all the temp folders created by running ScubaGear.  This is useful when testing ScubaGear manually.
#>

$thisDir = Get-Location

# Find all the folders created by ScubaGear
$folders = @()
$folders = Get-ChildItem $thisDir -recurse `
| Where-Object { $_.name -match "M365*" } `
| Select-Object FullName

# Delete them one at a time
Foreach ($folder in $folders) {
    Write-Output ("Deleting " + $folder)
    Remove-Item -Path $folder.FullName -Force -Recurse
}