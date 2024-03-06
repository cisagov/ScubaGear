#Requires -Version 5.1
<#
    .SYNOPSIS
        This script verifies the required Powershell modules used by the
        assessment tool are installed.
    .PARAMETER Force
    This will cause all required dependencies to be installed and updated to latest.
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

$MissingModules = @()

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
        $MissingModules += $Module
    }
}

if ($MissingModules.Count -gt 0){
    # Set preferences for writing messages
    $PreferenceStack = New-Object -TypeName System.Collections.Stack
    $PreferenceStack.Push($WarningPreference)
    $WarningPreference = "Continue"

    Write-Warning "
    The required supporting PowerShell modules are not installed with a supported version.
    Run Initialize-SCuBA to install all required dependencies.
    See Get-Help Initialize-SCuBA for more help."

    Write-Debug "The following modules are not installed:"
    foreach ($Module in $MissingModules){
        Write-Debug "`t$($Module.ModuleName)"
    }

    $WarningPreference = $PreferenceStack.Pop()
}

