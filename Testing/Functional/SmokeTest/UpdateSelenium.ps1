param (
    $registryRoot        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths",             # root location in registry to check version of currently installed apps
    $chromeRegistryPath  = "$registryRoot\chrome.exe",                                              # direct registry location for Chrome (to check version)
    $webDriversPath      = "C:\Program Files\WindowsPowerShell\Modules\Selenium\3.0.1\assemblies",  # local path for all web drivers (assuming that both are in the same location)
    $chromeDriverPath    = "$($webDriversPath)\chromedriver.exe",                                   # direct Chrome driver path
    $chromeDriverWebsite = "https://chromedriver.chromium.org/downloads",                           # Chrome dooesn't allow to query the version from downloads page; instead available pages can be found here
    $chromeDriverUrlBase = "https://chromedriver.storage.googleapis.com",                           # URL base to ubild direct download link for Chrome driver
    $chromeDriverUrlEnd  = "chromedriver_win32.zip",                                                # Chrome driver download ending (to finish building the URL)
)
function Get-LocalDriverVersion{
    param(
        $pathToDriver                                               # direct path to the driver
    )
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo   # need to pass the switch & catch the output, hence ProcessStartInfo is used

    $processInfo.FileName               = $pathToDriver
    $processInfo.RedirectStandardOutput = $true                     # need to catch the output - the version
    $processInfo.Arguments              = "-v"
    $processInfo.UseShellExecute        = $false                    # hide execution

    $process = New-Object System.Diagnostics.Process

    $process.StartInfo  = $processInfo
    $process.Start()    | Out-Null
    $process.WaitForExit()                                          # run synchronously, we need to wait for result
    $processStOutput    = $process.StandardOutput.ReadToEnd()

    return ($processStOutput -split " ")[1]                     # ... while Chrome on 2nd place
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
$chromeVersion = (Get-Item (Get-ItemProperty $chromeRegistryPath).'(Default)').VersionInfo.ProductVersion
Write-Debug -Message "Chrome driver version(registery):  $chromeVersion"

# check which driver versions are installed
$chromeDriverVersion = Get-LocalDriverVersion -pathToDriver $chromeDriverPath

if (Confirm-NeedForUpdate $chromeVersion $chromeDriverVersion){
    Write-Debug -Message "Need to update chrome driver from $chromeDriverVersion to $chromeVersion"

    # find exact matching version
    $chromeDriverAvailableVersions = (Invoke-RestMethod $chromeDriverWebsite) -split " " | Where-Object {$_ -like "*href=*?path=*"} | ForEach-Object {$_.replace("href=","").replace('"','')}
    $versionLink                   = $chromeDriverAvailableVersions | Where-Object {$_ -like "*$chromeVersion/*"}

    # if cannot find (e.g. it's too new to have a web driver), look for relevant major version
    if (!$versionLink){
        $browserMajorVersion = $chromeVersion.Substring(0, $chromeVersion.IndexOf("."))
        $versionLink         = $chromeDriverAvailableVersions | Where-Object {$_ -like "*$browserMajorVersion.*"}
    }

    # in case of multiple links, take the first only
    if ($versionLink.Count -gt 1){
        $versionLink = $versionLink[0]
    }

    # build tge download URL according to found version and download URL schema
    $version      = ($versionLink -split"=" | Where-Object {$_ -like "*.*.*.*/"}).Replace('/','')
    $downloadLink = "$chromeDriverUrlBase/$version/$chromeDriverUrlEnd"

    # download the file
    Invoke-WebRequest $downloadLink -OutFile "chromeNewDriver.zip"

    # epand archive and replace the old file
    Expand-Archive "chromeNewDriver.zip"              -DestinationPath "chromeNewDriver\"                    -Force
    Move-Item      "chromeNewDriver/chromedriver.exe" -Destination     "$($webDriversPath)\chromedriver.exe" -Force

    # clean-up
    Remove-Item "chromeNewDriver.zip" -Force
    Remove-Item "chromeNewDriver" -Recurse -Force
}
#endregion MAIN SCRIPT