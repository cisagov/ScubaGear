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

# Set expected version and OutFile path
$Expected_version = "0.42.1"
$Install_url= "https://openpolicyagent.org/downloads/v$($Expected_version)/opa_windows_amd64.exe"
$OutFile=(Join-Path $pwd.Path $Install_url.SubString($Install_url.LastIndexOf('/')))

# Download files
Write-Information "Downloading $Install_url`n"
$uri=New-Object "System.Uri" "$Install_url"
$request=[System.Net.HttpWebRequest]::Create($uri)
$request.set_Timeout(5000)
$response=$request.GetResponse()
#$totalLength=[System.Math]::Floor($response.get_ContentLength()/1024)
#$length=$response.get_ContentLength()
$responseStream=$response.GetResponseStream()
$destStream=New-Object -TypeName System.IO.FileStream -ArgumentList $OutFile, Create
$buffer=New-Object byte[] 10KB
$count=$responseStream.Read($buffer,0,$buffer.length)
$downloadedBytes=$count
while ($count -gt 0)
    {
    [System.Console]::CursorLeft=0
#    [System.Console]::Write("Downloaded {0}K of {1}K ({2}%)", [System.Math]::Floor($downloadedBytes/1024), $totalLength, [System.Math]::Round(($downloadedBytes / $length) * 100,0))
    $destStream.Write($buffer, 0, $count)
    $count=$responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes+=$count
    }
Write-Information ""
Write-Information "`nDownload of `"$OutFile`" finished."
$destStream.Flush()
$destStream.Close()
$destStream.Dispose()
$responseStream.Dispose()

# Version checks
$Installed_Version= .\opa_windows_amd64.exe version | Select-Object -First 1
if ($Installed_Version -eq "Version: $($Expected_version)")
    {
    Write-Information "`nDownloaed OPA version` `"$Installed_Version`" meets the ScubaGear Requirement"
    }
else {
    Write-Information "`nDownloaed OPA version` `"$Installed_Version`" does not meet the ScubaGear Requirement of` `"$Expected_version`""
}