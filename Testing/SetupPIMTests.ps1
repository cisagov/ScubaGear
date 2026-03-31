# This script performs two functions to support PIM testing using live tenant data.
# Part 1 - Update the privileged roles list in ScubaConfigDefaults.json to a temporary new set of low-risk Entra roles.
# Part 2 - Replace "Global Administrator" in AADConfig.rego with a new, temporary low-risk "fake" global admin role. This makes all the Rego policy checks that normally look at global admin to look at the fake global admin role instead.
# The script uses a testing strategy of temporarily referencing a set of low-risk Entra roles that can be safely modified for testing instead of the default high-risk roles like "Global Administrator".

# IMPORTANT: This script will modify your local ScubaConfigDefaults.json and AADConfig.rego files. Please Revert after testing.

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("pass","fail")]
    [string]$TestScenario
)

######################################################### Config constants
$GlobalAdminString = "Global Administrator"

###### PASS test role set
$PassPrivilegedRoles = @(
    "Printer Technician",
    "Dragon Administrator",
    "Edge Administrator",
    "Insights Administrator"
)

$NewPassGlobalAdmin = "Printer Technician"
######

###### FAIL test role set
$FailPrivilegedRoles = @(
    "Printer Administrator",
    "Knowledge Administrator",
    "Virtual Visits Administrator",
    "Places Administrator"
)

$NewFailGlobalAdmin = "Printer Administrator"
######################################################### End Config constants


######################################################### This is where the fun begins

###########################
###### Part 1 - Update the privilegedRoles array in ScubaConfigDefaults.json
$ScriptDirectory = (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$ConfigJsonPath = Join-Path -Path $ScriptDirectory -ChildPath "..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfigDefaults.json" -Resolve

# Read the JSON file
$ConfigJson = Get-Content -Path $ConfigJsonPath | ConvertFrom-Json

# Update the privilegedRoles array with values from the local variable
if ($TestScenario -eq "pass") {
    Write-Output "Configuring PASS scenario in ScubaConfigDefaults.json"
    $ConfigJson.privilegedRoles = $PassPrivilegedRoles
}
else {
    Write-Output "Configuring FAIL scenario in ScubaConfigDefaults.json"
    $ConfigJson.privilegedRoles = $FailPrivilegedRoles
}

# Write the updated JSON back to file
$ConfigJson | ConvertTo-Json -Depth 100 | Set-Content -Path $ConfigJsonPath -Encoding UTF8


###########################
###### Part 2 - Update references to "Global Administrator" to the new fake global admin role in AADConfig.rego
$RegoFilePath = Join-Path -Path $ScriptDirectory -ChildPath "..\PowerShell\ScubaGear\Rego\AADConfig.rego" -Resolve

# Read the rego file
$RegoContent = Get-Content -Path $RegoFilePath -Raw

# Replace all occurrences of "Global Administrator" with the new global admin role
if ($TestScenario -eq "pass") {
    Write-Output "Configuring PASS scenario in Rego"
    $RegoContent = $RegoContent -replace "`"$GlobalAdminString`"", "`"$NewPassGlobalAdmin`""
    $RegoContent = $RegoContent -replace "`"$NewFailGlobalAdmin`"", "`"$NewPassGlobalAdmin`""
}
else {
    Write-Output "Configuring FAIL scenario in Rego"
    $RegoContent = $RegoContent -replace "`"$GlobalAdminString`"", "`"$NewFailGlobalAdmin`""
    $RegoContent = $RegoContent -replace "`"$NewPassGlobalAdmin`"", "`"$NewFailGlobalAdmin`""
}

# Write the updated rego back to file
Set-Content -Path $RegoFilePath -Value $RegoContent -Encoding UTF8

#########################################################