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
    [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive", '*', IgnoreCase = $false)]
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

    [Parameter(Mandatory = $true, ParameterSetName = 'Configuration')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if (-Not ($_ | Test-Path)){
            throw "SCuBA configuration file or folder does not exist. $_"
        }
        if (-Not ($_ | Test-Path -PathType Leaf)){
            throw "SCuBA configuration Path argument must be a file."
        }
        return $true
    })]
    [System.IO.FileInfo]
    $ConfigFilePath,

    [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
    [switch]
)

$M365Environment = "gcc"
$OPAPath = "./" # Path to OPA Executable

$CachedParams = @{
    'ExportProvider' = $ExportProvider;
    'Login' = $Login;
    'ProductNames' = $ProductNames;
    'M365Environment' = $M365Environment;
    'OPAPath' = $OPAPath;
    'OutPath' = $OutPath;
    'Quiet' = $Quiet;
}

$RunCachedParams = New-Object -Type PSObject -Property $CachedParams

# Loads and executes parameters from a Configuration file
if ($PSCmdlet.ParameterSetName -eq 'Configuration'){
    if (-Not ([ScubaConfig]::GetInstance().LoadConfig($ConfigFilePath))){
        Write-Error -Message "The config file failed to load: $ConfigFilePath"
    }
    else {
        $RunCachedParams = [ScubaConfig]::GetInstance().Configuration
    }
}

Set-Location $(Split-Path -Path $PSScriptRoot | Split-Path)
$ManifestPath = Join-Path -Path "./PowerShell" -ChildPath "ScubaGear"
Remove-Module "ScubaGear" -ErrorAction "SilentlyContinue" # For dev work
#######
Import-Module $ManifestPath -ErrorAction Stop
Invoke-RunCached @RunCachedParams
