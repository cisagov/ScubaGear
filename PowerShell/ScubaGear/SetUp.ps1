#Requires -Version 5.1
<#
    .SYNOPSIS
        This script installs the required Powershell modules used by the
        assessment tool
    .DESCRIPTION
        Installs the modules required to support SCuBAGear.  If the Force
        switch is set then any existing module will be re-installed even if
        already at latest version. If the SkipUpdate switch is set then any
        existing module will not be updated to th latest version.
    .EXAMPLE
        .\Setup.ps1
    .NOTES
        Executing the script with no switches set will install the latest
        version of a module if not already installed.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = 'Installs a given module and overrides warning messages about module installation conflicts. If a module with the same name already exists on the computer, Force allows for multiple versions to be installed. If there is an existing module with the same name and version, Force overwrites that version')]
    [switch]
    $Force,

    [Parameter(HelpMessage = 'If specified then modules will not be updated to latest version')]
    [switch]
    $SkipUpdate,

    [Parameter(HelpMessage = 'Do not automatically trust the PSGallery repository for module installation')]
    [switch]
    $DoNotAutoTrustRepository,

    [Parameter(HelpMessage = 'Do not download OPA')]
    [switch]
    $NoOPA,

    [Parameter(Mandatory = $false, HelpMessage = 'The version of OPA Rego to be downloaded, must be in "x.x.x" format')]
    [Alias('version')]
    [string]
    $ExpectedVersion = '0.61.0',

    [Parameter(Mandatory = $false, HelpMessage = 'The operating system the program is running on')]
    [ValidateSet('Windows','MacOS','Linux')]
    [Alias('os')]
    [string]
    $OperatingSystem  = "Windows",

    [Parameter(Mandatory = $false, HelpMessage = 'The file name that the opa executable is to be saved as')]
    [Alias('name')]
    [string]
    $OPAExe = "",

    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]
    $ScubaParentDirectory = $env:USERPROFILE
)

# Set preferences for writing messages
$DebugPreference = "Continue"
$InformationPreference = "Continue"

if (-not $DoNotAutoTrustRepository) {
    $Policy = Get-PSRepository -Name "PSGallery" | Select-Object -Property -InstallationPolicy

    if ($($Policy.InstallationPolicy) -ne "Trusted") {
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        Write-Information -MessageData "Setting PSGallery repository to trusted."
    }
}

# Start a stopwatch to time module installation elapsed time
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$RequiredModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "PowerShell\ScubaGear\RequiredVersions.ps1"
if (Test-Path -Path $RequiredModulesPath) {
    . $RequiredModulesPath
}

if ($ModuleList) {
    # Add PowerShellGet to beginning of ModuleList for installing required modules.
    $ModuleList = ,@{
        ModuleName = 'PowerShellGet'
        ModuleVersion = [version] '2.1.0'
        MaximumVersion = [version] '2.99.99999'
    } + $ModuleList
}
else {
    throw "Required modules list is required."
}

foreach ($Module in $ModuleList) {

    $ModuleName = $Module.ModuleName

    if (Get-Module -ListAvailable -Name $ModuleName) {
        $HighestInstalledVersion = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object Version -First 1).Version
        $LatestVersion = [Version](Find-Module -Name $ModuleName -MinimumVersion $Module.ModuleVersion -MaximumVersion $Module.MaximumVersion).Version

        if ($HighestInstalledVersion -ge $LatestVersion) {
            Write-Debug "${ModuleName}: ${HighestInstalledVersion} already has latest installed."

            if ($Force -eq $true) {
                Install-Module -Name $ModuleName `
                    -Force `
                    -AllowClobber `
                    -Scope CurrentUser `
                    -MaximumVersion $Module.MaximumVersion
                Write-Information -MessageData "Re-installing module to latest acceptable version: ${ModuleName}."
            }
        }
        else {
            if ($SkipUpdate -eq $true) {
                Write-Debug "Skipping update for ${ModuleName}: ${HighestInstalledVersion} to newer version ${LatestVersion}."
            }
            else {
                Install-Module -Name $ModuleName `
                    -Force `
                    -AllowClobber `
                    -Scope CurrentUser `
                    -MaximumVersion $Module.MaximumVersion
                $MaxInstalledVersion = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object Version -First 1).Version
                Write-Information -MessageData "${ModuleName}: ${HighestInstalledVersion} updated to version ${MaxInstalledVersion}."
            }
        }
    }
    else {
        Install-Module -Name $ModuleName `
            -AllowClobber `
            -Scope CurrentUser `
            -MaximumVersion $Module.MaximumVersion
            $MaxInstalledVersion = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object Version -First 1).Version
        Write-Information -MessageData "Installed the latest acceptable version of ${ModuleName}: ${MaxInstalledVersion}."
    }
}

if ($NoOPA -eq $true) {
    Write-Debug "Skipping Download for OPA.`n"
}
else {
    try {
        $ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
        . $ScriptDir\OPA.ps1 -name $OPAExe -version $ExpectedVersion -os $OperatingSystem -ScubaParentDirectory $ScubaParentDirectory
    }
    catch {
        $Error[0] | Format-List -Property * -Force | Out-Host
    }
}

# Stop the clock and report total elapsed time
$Stopwatch.stop()

Write-Debug "ScubaGear setup time elapsed: $([math]::Round($stopwatch.Elapsed.TotalSeconds,0)) seconds."

$DebugPreference = "SilentlyContinue"
$InformationPreference = "SilentlyContinue"