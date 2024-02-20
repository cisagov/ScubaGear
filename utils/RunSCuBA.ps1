<#
 # For end user modifications.
 # See README for detailed instructions on which parameters to change.
#>

param (
    [switch]
    $Version
)

$LogIn = $true # Set $true to authenticate yourself to a tenant or if you are already authenticated set to $false to avoid reauthentication
$ProductNames = @("entraid", "defender", "exo", "onedrive", "sharepoint", "teams") # The specific products that you want the tool to assess.
$M365Environment = "gcc" # Mandatory parameter if running Power Platform. Valid options are "dod", "prod","preview","tip1", "tip2", "usgov", or "usgovhigh".
$OutPath = "../Reports" # Report output directory path. Leave as-is if you want the Reports folder to be created in the same directory where the script is executed.
$OPAPath = "../" # Path to the OPA Executable. Leave this as-is for most cases.

$SCuBAParams = @{
    'Login' = $Login;
    'ProductNames' = $ProductNames;
    'M365Environment' = $M365Environment;
    'OPAPath' = $OPAPath;
    'OutPath' = $OutPath;
}

$ManifestPath = Join-Path -Path "../PowerShell" -ChildPath "ScubaGear"
#######
Remove-Module "ScubaGear" -ErrorAction "SilentlyContinue"
Import-Module -Name $ManifestPath -ErrorAction "Stop"
if ($Version) {
    Invoke-SCuBA @SCuBAParams -Version
}
else {
    Invoke-SCuBA @SCuBAParams
}
#######
