using module '..\..\PowerShell\ScubaGear\Modules\ScubaConfig\ScubaConfig.psm1'

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
[CmdletBinding(DefaultParameterSetName='Default')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive", '*', IgnoreCase = $false)]
    [string[]]
    $ProductNames = '*', # The specific products that you want the tool to assess.

    [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
    [ValidateNotNullOrEmpty()]
    [string]
    $OutPath = ".\Testing\Functional\Reports", # output directory

    [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet($true, $false)]
    [boolean]
    $LogIn = $false, # Set $true to authenticate yourself to a tenant or if you are already authenticated set to $false to avoid reauthentication

    [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet($true, $false)]
    [boolean]
    $ExportProvider = $true,

    [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet($true, $false)]
    [boolean]
    $Quiet = $True, # Supress report poping up after run

    [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
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
    $ConfigFilePath
)

$M365Environment = "gcc"
$OPAPath = (Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools")# Path to OPA Executable

if ($PSCmdlet.ParameterSetName -eq 'Default'){
    $RunCachedParams = @{
        'ExportProvider' = $ExportProvider;
        'Login' = $Login;
        'ProductNames' = $ProductNames;
        'M365Environment' = $M365Environment;
        'OPAPath' = $OPAPath;
        'OutPath' = $OutPath;
        'Quiet' = $Quiet;
    }
}

# Loads and executes parameters from a Configuration file
if ($PSCmdlet.ParameterSetName -eq 'Configuration'){
    if (-Not ([ScubaConfig]::GetInstance().LoadConfig($ConfigFilePath))){
        Write-Error -Message "The config file failed to load: $ConfigFilePath"
    }
    else {
        $ScubaConfig = [ScubaConfig]::GetInstance().Configuration
    }

    $RunCachedParams = @{
        'ExportProvider' = $ExportProvider;
        'Login' = $ScubaConfig.Login;
        'ProductNames' = $ScubaConfig.ProductNames;
        'M365Environment' = $ScubaConfig.M365Environment;
        'OPAPath' = $ScubaConfig.OPAPath;
        'OutPath' = $ScubaConfig.OutPath;
        'Quiet' = $Quiet;
    }
}

Set-Location $(Split-Path -Path $PSScriptRoot | Split-Path)
$ManifestPath = Join-Path -Path "./PowerShell" -ChildPath "ScubaGear"
Remove-Module "ScubaGear" -ErrorAction "SilentlyContinue" # For dev work
#######
Import-Module $ManifestPath -ErrorAction Stop
Invoke-RunCached @RunCachedParams
