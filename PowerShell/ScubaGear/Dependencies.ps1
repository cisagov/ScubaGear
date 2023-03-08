#Requires -Version 5.1
<#
    .SYNOPSIS
        This script verifies the required Powershell modules used by the
        assessment tool are installed.
    .DESCRIPTION
        Verifies a supported version of the modules required to support SCuBAGear are installed.
#>

$RequiredModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "RequiredVersions.ps1"
if (Test-Path -Path $RequiredModulesPath){
  . $RequiredModulesPath
}

if (!$ModuleList){
   throw "Required modules list is required."
}

foreach ($Module in $ModuleList) {
    $InstalledModuleVersions = Get-Module -ListAvailable -Name $($Module.ModuleName)
    $FoundAcceptableVersion = $false

    foreach ($ModuleVersion in $InstalledModuleVersions){

        if (($ModuleVersion.Version -ge $Module.ModuleVersion) -and ($ModuleVersion.Version -le $Module.MaximumVersion)){
            $FoundAcceptableVersion = $true
            break;
        }
    }

    if (-not $FoundAcceptableVersion) {
        throw [System.IO.FileNotFoundException] "No acceptable installed version found for module: $($Module.ModuleName)
        Required Min Version: $($Module.ModuleVersion) | Max Version: $($Module.MaximumVersion)
        Run Get-InstalledModule to see a list of currently installed modules
        Run SetUp.ps1 or Install-Module $($Module.ModuleName) -force to install the latest acceptable version of $($Module.ModuleName)"
    }
}




