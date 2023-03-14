#Requires -Version 5.1
<#
    .SYNOPSIS
        This script installs the required OPA executable used by the
        assessment tool
    .DESCRIPTION
        Installs the OPA executable required to support SCuBAGear.
    .EXAMPLE
        .\OPA.ps1
#>
# Set prefernces for writing messages
$DebugPreference = "Continue"
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

# Set expected version and OutFile path
$ExpectedVersion = "0.42.1"
$InstallUrl= "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/opa_windows_amd64.exe"
$OutFile=(Join-Path (Get-Location).Path $InstallUrl.SubString($InstallUrl.LastIndexOf('/')))
$ExpectedHash ="5D71028FED935DC98B9D69369D42D2C03CE84A7720D61ED777E10AAE7528F399"

# Download files
try {
    Write-Information "Downloading $InstallUrl"
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($InstallUrl, $OutFile)
    Write-Information ""
    Write-Information "`nDownload of `"$OutFile`" finished."
}
catch {
    "An error has occurred: Unable to download OPA executable, try manual install see details in README"
}
$WebClient.Dispose()

# Hash checks
if ((Get-FileHash .\opa_windows_amd64.exe).Hash -eq $ExpectedHash)
    {
    Write-Information "SHA256 verified successful"
    }
else {
    Write-Information "SHA256 verified failed, try re-download or manual install see details in README"
}
# Version checks
Try {
    $InstalledVersion= .\opa_windows_amd64.exe version | Select-Object -First 1
    if ($InstalledVersion -eq "Version: $($ExpectedVersion)")
        {
        Write-Information "`Downloaded OPA version` `"$InstalledVersion`" meets the ScubaGear Requirement"
        }
    else {
        Write-Information "`Downloaded OPA version` `"$InstalledVersion`" does not meet the ScubaGear Requirement of` `"$ExpectedVersion`""
    }
}
catch {
    Write-Information "Unabele to verify the current OPA version: please see details on manually in README"
}

$DebugPreference = "SilientlyContinue"
$InformationPreference = "SilientlyContinue"
$ErrorActionPreference = "Continue"