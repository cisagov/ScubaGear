<#
    Script autmating update of Selenium Web Driver for MS Edge and Chrome browsers.
    Created by Wiktor Mrowczynski.
    v.2022.06.22.A
#>
#region INITIALIZATION
param (
    $registryRoot        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths",             # root location in registry to check version of currently installed apps
    $edgeRegistryPath    = "$registryRoot\msedge.exe",                                              # direct registry location for MS Edge (to check version)
    $chromeRegistryPath  = "$registryRoot\chrome.exe",                                              # direct registry location for Chrome (to check version)
    $webDriversPath      = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules\Selenium\3.0.1\assemblies",  # local path for all web drivers (assuming that both are in the same location)
    $edgeDriverPath      = "$($webDriversPath)\msedgedriver.exe",                                   # direct MS Edge driver path
    $chromeDriverPath    = "$($webDriversPath)\chromedriver.exe",                                   # direct Chrome driver path
    $chromeDriverWebsite = "https://chromedriver.chromium.org/downloads",                           # Chrome dooesn't allow to query the version from downloads page; instead available pages can be found here
    $chromeDriverUrlBase = "https://chromedriver.storage.googleapis.com",                           # URL base to ubild direct download link for Chrome driver
    $chromeDriverUrlEnd  = "chromedriver_win32.zip",                                                # Chrome driver download ending (to finish building the URL)
    $edgeDriverWebsite   = "https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/"  # URL to find and download relevant MS Edge Driver version
)
#endregion INITIALIZATION

#region FUNCTIONS
# function checking driver version using the -v switch of each driver
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

    if ($pathToDriver.Contains("msedgedriver")){
        return ($processStOutput -split " ")[3]                     # MS Edge returns version on 4th place in the output (be carefulm in old versions it was on 1st as well)...
    }
    else {
        return ($processStOutput -split " ")[1]                     # ... while Chrome on 2nd place
    }
}

# function evaluating a need for update
function Confirm-NeedForUpdate{
    param(
        $v1,                                                                                 # version 1 to compare
        $v2                                                                                  # version 2 to compare
    )
    Write-Debug -Message "v1: $v1; v2: $v2"
    return $v1.Substring(0, $v1.LastIndexOf(".")) -ne $v2.Substring(0, $v2.LastIndexOf(".")) # return true if update is needed, otherwise false. Ignore last minor version - it's not so important and can be skipped
}
#endregion FUNCTIONS

#region MAIN SCRIPT
$DebugPreference = 'Continue'
#$DebugPreference = 'SilentlyContinue'

# firstly check which browser versions are installed (from registry)
$edgeVersion   = (Get-Item (Get-ItemProperty $edgeRegistryPath).'(Default)').VersionInfo.ProductVersion
$chromeVersion = (Get-Item (Get-ItemProperty $chromeRegistryPath).'(Default)').VersionInfo.ProductVersion
Write-Debug -Message "Edge driver version(registry):  $edgeVersion"
Write-Debug -Message "Chrome driver version(registery):  $chromeVersion"

# check which driver versions are installed
Write-Debug -Message "Edge driver path:  $edgeDriverPath"
Write-Debug -Message "Chrome driver path:  $chromeDriverPath"
Write-Debug -Message "$(Get-ChildItem "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules\Selenium\3.0.1\assemblies")"
$edgeDriverVersion   = Get-LocalDriverVersion -pathToDriver $edgeDriverPath
$chromeDriverVersion = Get-LocalDriverVersion -pathToDriver $chromeDriverPath
Write-Debug -Message "Edge driver version(file system):  $edgeDriverVersion"
Write-Debug -Message "Chrome driver version(file system):  $chromeDriverVersion"

# download new MS Edge driver if neccessary
if (Confirm-NeedForUpdate $edgeVersion $edgeDriverVersion){
    Write-Debug -Message "Need to update edge driver from $edgeVersion to $edgeDriverVersion"

    # find exact matching version
    $edgeDriverAvailableVersions = (Invoke-RestMethod $edgeDriverWebsite) -split " " | Where-Object {$_ -like "*href=*win64*"} | ForEach-Object {$_.replace("href=","").replace('"','')}
    $downloadLink                = $edgeDriverAvailableVersions | Where-Object {$_ -like "*/$edgeVersion/*"}

    # if cannot find (e.g. it's too new to have a web driver), look for relevant major version
    if (!$downloadLink){
        $browserMajorVersion = $edgeVersion.Substring(0, $edgeVersion.IndexOf("."))
        $downloadLink        = $edgeDriverAvailableVersions | Where-Object {$_ -like "*/$browserMajorVersion*"}
    }

    # in case of multiple links, take the first only
    if ($downloadLink.Count -gt 1) {
        $downloadLink = $downloadLink[0]
    }

    # download the file
    Invoke-WebRequest $downloadLink -OutFile "edgeNewDriver.zip"

    # epand archive and replace the old file
    Expand-Archive "edgeNewDriver.zip"              -DestinationPath "edgeNewDriver\"                      -Force
    Move-Item      "edgeNewDriver/msedgedriver.exe" -Destination     "$($webDriversPath)\msedgedriver.exe" -Force

    # clean-up
    Remove-Item "edgeNewDriver.zip" -Force
    Remove-Item "edgeNewDriver"     -Recurse -Force
}

# download new Chrome driver if neccessary
if (Confirm-NeedForUpdate $chromeVersion $chromeDriverVersion){
    Write-Debug -Message "Need to update chrome driver from $chromeVersion to $chromeDriverVersion"

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