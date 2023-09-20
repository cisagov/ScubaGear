<#
.SYNOPSIS
Installs Chrome Web Driver on local machine

.DESCRIPTION
This script installs the required web driver needed for the current Chrome Browser installed on the machine.

.PARAMETER rootRegistry
The root location in registry to check version of currently installed apps

.PARAMETER chromeRegistryPath
The direct registry location for Chrome (to check version)

.PARAMETER webDriversPath
The local path for all web drivers

.PARAMETER chromeDriverPath
The direct Chrome driver path
#>
param (
    $registryRoot        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths",
    $chromeRegistryPath  = "$registryRoot\chrome.exe",
    $webDriversPath      = "C:\Program Files\WindowsPowerShell\Modules\Selenium\3.0.1\assemblies",
    $chromeDriverPath    = "$($webDriversPath)\chromedriver.exe"
)
function Get-LocalDriverVersion{
    param(
        $PathToDriver                                               # direct path to the driver
    )

    $version = '0.0.0.0'

    if (Test-Path $PathToDriver){
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo   # need to pass the switch & catch the output, hence ProcessStartInfo is used

    $processInfo.FileName               = $pathToDriver
    $processInfo.RedirectStandardOutput = $true                     # need to catch the output - the version
    $processInfo.Arguments              = "-v"
    $processInfo.UseShellExecute        = $false                    # hide execution

    $process = New-Object System.Diagnostics.Process

    $process.StartInfo  = $processInfo
    $process.Start() | Out-Null
    $process.WaitForExit()                                          # run synchronously, we need to wait for result
    $processStOutput    = $process.StandardOutput.ReadToEnd()

    $Version =  ($processStOutput -split " ")[1]
    }

    return $Version
}

function Confirm-NeedForUpdate{
    param(
        $v1,
        $v2
    )
    Write-Debug -Message "v1: $v1; v2: $v2"
    return ([System.Version]$v2).Major -lt ([System.Version]$v1).Major
}

$DebugPreference = 'Continue'
#$DebugPreference = 'SilentlyContinue'

# firstly check which browser versions are installed (from registry)
$chromeVersion = (Get-Item (Get-ItemProperty $chromeRegistryPath).'(Default)').VersionInfo.ProductVersion -as [System.Version]
Write-Debug -Message "Chrome driver version(registery):  $chromeVersion"

# check which driver versions are installed
$localDriverVersion = Get-LocalDriverVersion -pathToDriver $chromeDriverPath

if (Confirm-NeedForUpdate $chromeVersion $localDriverVersion){
    Write-Debug -Message "Need to update chrome driver from $localDriverVersion to $chromeVersion"

    $VersionsUrl = 'https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json'

    $VersionsInfo = (Invoke-RestMethod $VersionsUrl).versions |
        Sort-Object {[System.Version]($_.Version)} -Descending |
        Where-Object {([System.Version]($_.Version)).Major -eq $chromeVersion.Major -and ([System.Version]($_.Version)).Minor -eq $chromeVersion.Minor -and ([System.Version]($_.Version)).Build -le $chromeVersion.Build} |
        Select-Object -First 1
    $Download = $VersionsInfo.Downloads.ChromeDriver |
        Where-Object {$_.Platform -eq 'win64'}
    $DownloadUrl = $Download.Url

    Write-Debug -Message "Dowloading $DownloadUrl"
    $DriverTempPath = Join-Path -Path $PSScriptRoot -ChildPath "chromeNewDriver"

    if (-not (Test-Path -Path $DriverTempPath -PathType Container)){
        New-Item -ItemType Directory -Path $DriverTempPath
    }

    Invoke-WebRequest $DownloadUrl -OutFile "$DriverTempPath\chromeNewDriver.zip"

    Expand-Archive "$DriverTempPath\chromeNewDriver.zip" -DestinationPath $DriverTempPath -Force
    if (Test-Path "$($webDriversPath)\chromedriver.exe") {
        Remove-Item -Path "$($webDriversPath)\chromedriver.exe" -Force
    }
    Move-Item "$DriverTempPath\chromedriver-win64\chromedriver.exe" -Destination  "$($webDriversPath)\chromedriver.exe" -Force

    # clean-up
    Remove-Item "$DriverTempPath\chromeNewDriver.zip" -Force
    Remove-Item $DriverTempPath\ -Recurse -Force
}
#endregion MAIN SCRIPT