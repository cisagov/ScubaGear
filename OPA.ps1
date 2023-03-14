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
$OutFile=(Join-Path $pwd.Path $InstallUrl.SubString($InstallUrl.LastIndexOf('/')))
$ExpectedHash ="5D71028FED935DC98B9D69369D42D2C03CE84A7720D61ED777E10AAE7528F399"

# Download files
try {
    Write-Information "Downloading $InstallUrl`n"
    $Uri=New-Object "System.Uri" "$InstallUrl"
    $Request=[System.Net.HttpWebRequest]::Create($Uri)
    $Request.set_Timeout(5000)
    $Response=$Request.GetResponse()
}
catch {
    "An error has occurred: Unable to reach the download URL"
}
try {
    $ResponseStream=$Response.GetResponseStream()
    $DestStream=New-Object -TypeName System.IO.FileStream -ArgumentList $OutFile, Create
    $Buffer=New-Object byte[] 10KB
    $Count=$ResponseStream.Read($Buffer,0,$Buffer.length)
    $DownloadedBytes=$Count
    while ($Count -gt 0)
        {
        [System.Console]::CursorLeft=0
        $DestStream.Write($Buffer, 0, $Count)
        $Count=$ResponseStream.Read($Buffer,0,$Buffer.length)
        $DownloadedBytes+=$Count
        }
    Write-Information ""
    Write-Information "`nDownload of `"$OutFile`" finished."
}
catch {
    "An error has occurred: Unable to download OPA executable, try manual install see details in README"
}
$DestStream.Flush()
$DestStream.Close()
$DestStream.Dispose()
$ResponseStream.Dispose()

# Hash checks
if ((Get-FileHash .\opa_windows_amd64.exe).Hash -eq $ExpectedHash)
    {
    Write-Information "SHA256 verified successful"
    }
else {
    Write-Information "SHA256 verified failed, try re-download or manual install see details in README "
}
# Version checks
$InstalledVersion= .\opa_windows_amd64.exe version | Select-Object -First 1
if ($InstalledVersion -eq "Version: $($ExpectedVersion)")
    {
    Write-Information "`nDownloaded OPA version` `"$InstalledVersion`" meets the ScubaGear Requirement"
    }
else {
    Write-Information "`nDownloaded OPA version` `"$InstalledVersion`" does not meet the ScubaGear Requirement of` `"$ExpectedVersion`""
}

$DebugPreference = "SilientlyContinue"
$InformationPreference = "SilientlyContinue"
$ErrorActionPreference = "Continue"