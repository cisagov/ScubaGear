#
# For Rego testing with a static provider JSON.
# When pure Rego testing it makes sense to export the provider only once.
#
# DO NOT confuse this script with the Rego Unit tests script

#
# The tenant name in the report will display Rego Testing which IS intentional.
# This is so that this test script can be run on any cached provider JSON
#

# Set $true for the first run of this script
# then set this to be $false each subsequent run
$ExportProvider = $true

$LogIn = $true # Set $true to authenticate yourself to a tenant or if you are already authenticated set to $false to avoid reauthentication
$ProductNames = @("aad", "defender", "exo", "onedrive", "powerplatform", "sharepoint", "teams")
$Endpoint = "usgov" # Mandatory parameter if running Power Platform
$OPAPath = "./" # Path to OPA Executable
$OutPath = "./output" # output directory

$RunCachedParams = @{
    'Login' = $Login;
    'ProductNames' = $ProductNames;
    'OPAPath' = $OPAPath;
    'ExportProvider' = $ExportProvider;
    'Endpoint' = $Endpoint;
    'OutPath' = $OutPath;
}

$ManifestPath = Join-Path -Path "./PowerShell" -ChildPath "ScubaGear"
Remove-Module "SCuBA" -ErrorAction "SilentlyContinue" # For dev work
#######
Import-Module $ManifestPath -ErrorAction Stop
Invoke-RunCached @RunCachedParams
