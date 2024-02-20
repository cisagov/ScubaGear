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
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("teams", "exo", "defender", "entraid", "powerplatform", "sharepoint", "onedrive", '*', IgnoreCase = $false)]
    [string[]]
    $ProductNames = '*', # The specific products that you want the tool to assess.

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OutPath = ".\Testing\Functional\Reports", # output directory

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet($true, $false)]
    [boolean]
    $LogIn = $false, # Set $true to authenticate yourself to a tenant or if you are already authenticated set to $false to avoid reauthentication

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet($true, $false)]
    [boolean]
    $ExportProvider = $true,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet($true, $false)]
    [boolean]
    $Quiet = $True # Supress report poping up after run
)

$M365Environment = "gcc"
$OPAPath = "./" # Path to OPA Executable

$RunCachedParams = @{
    'ExportProvider' = $ExportProvider;
    'Login' = $Login;
    'ProductNames' = $ProductNames;
    'M365Environment' = $M365Environment;
    'OPAPath' = $OPAPath;
    'OutPath' = $OutPath;
    'Quiet' = $Quiet;
}

Set-Location $(Split-Path -Path $PSScriptRoot | Split-Path)
$ManifestPath = Join-Path -Path "./PowerShell" -ChildPath "ScubaGear"
Remove-Module "ScubaGear" -ErrorAction "SilentlyContinue" # For dev work
#######
Import-Module $ManifestPath -ErrorAction Stop
Invoke-RunCached @RunCachedParams