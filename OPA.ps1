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
$OPAExe = "opa_windows_amd64.exe"
$InstallUrl = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/$OPAExe"
$OutFile=(Join-Path (Get-Location).Path $InstallUrl.SubString($InstallUrl.LastIndexOf('/')))
$ExpectedHash ="5D71028FED935DC98B9D69369D42D2C03CE84A7720D61ED777E10AAE7528F399"

# Download files
try {
    $uri = New-Object "System.Uri" "$InstallUrl"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $OutFile, Create
    $buffer = new-object byte[] 15000KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0)
    {
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
        Write-Progress -activity "Downloading file '$($InstallUrl.split('/') | Select-Object -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)
    }
    Write-Progress -activity "Finished downloading file '$($InstallUrl.split('/') | Select-Object -Last 1)'" 
}
catch {
    Write-Error "An error has occurred: Unable to download OPA executable. To try manually downloading, see details in README under 'Download the required OPA executable'"
}
finally {
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
}

# Hash checks
if ((Get-FileHash .\opa_windows_amd64.exe).Hash -eq $ExpectedHash)
    {
    Write-Information "SHA256 verified successfully"
    }
else {
    Write-Information "SHA256 verification failed, retry download or install manually. See README under 'Download the required OPA executable' for instructions."
}
# Version checks
Try {
    $OPAArgs = @('version')
    $InstalledVersion= $(& "./$($OPAExe)" @OPAArgs) | Select-Object -First 1
    if ($InstalledVersion -eq "Version: $($ExpectedVersion)")
        {
        Write-Information "`Downloaded OPA version` `"$InstalledVersion`" meets the ScubaGear requirement"
        }
    else {
        Write-Information "`Downloaded OPA version` `"$InstalledVersion`" does not meet the ScubaGear requirement of` `"$ExpectedVersion`""
    }
}
catch {
    Write-Error "Unable to verify the current OPA version: please see details on manual installation in the README under 'Download the required OPA executable'"
}

$DebugPreference = "SilientlyContinue"
$InformationPreference = "SilientlyContinue"
$ErrorActionPreference = "Continue"
