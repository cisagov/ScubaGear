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

$SupportModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "Modules/Support/Support.psm1"
Import-Module -Name $SupportModulesPath
Initialize-SCuBA -SkipUpdate -NoOPA

foreach ($Module in $ModuleList) {
    Write-Debug "Evaluating module: $($Module.ModuleName)"
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
        Run Install-Module $($Module.ModuleName) -Force -MaximumVersion $($Module.MaximumVersion) to install the latest acceptable version of $($Module.ModuleName)"
    }
}




