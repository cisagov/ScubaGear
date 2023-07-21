$registryRoot        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
$chromeRegistryPath  = "$registryRoot\chrome.exe"
$chromeVersion = (Get-Item (Get-ItemProperty $chromeRegistryPath).'(Default)').VersionInfo.ProductVersion
$chromeVersion


$VersionsUrl = 'https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json'

$Versions = (Invoke-RestMethod $VersionsUrl).versions | Sort-Object -Property Version -Descending
$Versions
