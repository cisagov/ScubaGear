#Requires -Version 5.1
<#
    .SYNOPSIS
        This script installs the required Powershell modules used by the
        assessment tool
    .DESCRIPTION
        Installs the modules required to support SCuBAGear.  If the Force
        switch is set then any existing module will be re-installed even if
        already at the latest version. If the SkipUpdate switch is set then any
        existing module will not be updated to the latest version.
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

    [Parameter(HelpMessage = 'Do not automatically trust the PSGallery repository for module installation')]
    [switch]
    $DoNotAutoTrustRepository,

    [Parameter(HelpMessage = 'Do not download OPA')]
    [switch]
    $NoOPA
)

# Set preferences for writing messages
$DebugPreference = 'Continue'
$InformationPreference = 'Continue'

if (-not $DoNotAutoTrustRepository)
{
    $Policy = Get-PSRepository -Name 'PSGallery' | Select-Object -Property -InstallationPolicy

    if ($($Policy.InstallationPolicy) -ne 'Trusted')
    {
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        Write-Information -MessageData 'Setting PSGallery repository to trusted.'
    }
}

# Start a stopwatch to time module installation elapsed time
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$RequiredModulesPath = Join-Path -Path $PSScriptRoot -ChildPath 'PowerShell\ScubaGear\RequiredVersions.ps1'
if (Test-Path -Path $RequiredModulesPath)
{
    . $RequiredModulesPath
}

if ($ModuleList)
{
    # Add PowerShellGet to beginning of ModuleList for installing required modules.
    $ModuleList = , @{
        ModuleName     = 'PowerShellGet'
        ModuleVersion  = [version] '2.1.0'
        MaximumVersion = [version] '2.99.99999'
    } + $ModuleList
}
else
{
    throw 'Required modules list is required.'
}

$AvailableModules = Get-Module -ListAvailable

foreach ($Module in $ModuleList)
{
    $InstalledApprovedModuleVersions = @($AvailableModules | Where-Object -Property Name -EQ $Module.ModuleName | Where-Object { [Version]($_.Version) -le $Module.MaximumVersion -and [Version]($_.Version) -ge $Module.ModuleVersion } | Sort-Object -Property Version -Descending)

    if ($InstalledApprovedModuleVersions.Count -ne 0)
    {
        $HighestApprovedVersion = $InstalledApprovedModuleVersions[0]
        Write-Debug "$($Module.ModuleName):$($HighestApprovedVersion.Version) already has the latest approved module version installed."

        if ($Force -eq $true)
        {
            Write-Debug "Re-installing module $($Module.MaximumVersion) due to '-Force' parameter"

            Install-Module -Name $Module.ModuleName `
                -Force `
                -AllowClobber `
                -Scope CurrentUser `
                -MaximumVersion $Module.MaximumVersion
            Write-Information -MessageData "Re-installing module to the latest acceptable version: $($Module.ModuleName)"
        }
    }
    else
    {
        Install-Module -Name $Module.ModuleName `
            -AllowClobber `
            -Scope CurrentUser `
            -MaximumVersion $Module.MaximumVersion
        Write-Information -MessageData "Installed the the latest acceptable version of $($Module.ModuleName) version $($Module.MaximumVersion)"
    }
}

if ($NoOPA -eq $true)
{
    Write-Debug 'Skipping Download for OPA.'
}
else
{
    $DebugPreference = 'Continue'
    try
    {
        $ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
        . $ScriptDir\OPA.ps1
    }
    catch
    {
        Write-Error 'An error occurred: cannot call OPA download script'
    }
}

# Stop the clock and report total elapsed time
$Stopwatch.stop()

Write-Debug "ScubaGear setup time elapsed:  $([math]::Round($stopwatch.Elapsed.TotalSeconds,0)) seconds."

$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
