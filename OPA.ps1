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
$OutFile = (Join-Path (Get-Location).Path $InstallUrl.SubString($InstallUrl.LastIndexOf('/')))
$ExpectedHash = "5D71028FED935DC98B9D69369D42D2C03CE84A7720D61ED777E10AAE7528F399"


function Get-OPAExecutable {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('url')]
        [string]$InstallUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('out')]
        [string]$OutFile
    )

    try {
        Write-Information "Downloading $InstallUrl"
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($InstallUrl, $OutFile)
        Write-Information ""
        Write-Information "`nDownload of `"$OutFile`" finished."
    }
    catch {
        $Error[0] | Format-List -Property * -Force
        Write-Error "An error has occurred: Unable to download OPA executable. To try manually downloading, see details in README under 'Download the required OPA executable'"
    }
    finally {
        $WebClient.Dispose()
    }
}

function Confirm-ValidOPAExecutable {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('hash')]
        [string]$ExpectedHash,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('v')]
        [string]$ExpectedVersion,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('exe')]
        [string]$OPAExe,

        [Parameter(Mandatory = $false)]
        [Alias('exists')]
        [switch]$OPAExists
    )

    $Output ="TASK: Running checks on $OPAExe`n"
    $Warning = $False
    # Hash checks
    if ((Get-FileHash $OPAExe).Hash -eq $ExpectedHash) {
        $Output += "`tSHA256 verified successfully"
    }
    else {
        $Output +=  "`tSHA256 verification failed"
        $Warning = $True
        if($OPAExists){
            return $false, $Output, $Warning
        }
    }

    # Version checks
    Try {
        $OPAArgs = @('version')
        $InstalledVersion = $(& "./$($OPAExe)" @OPAArgs) | Select-Object -First 1
        if ($InstalledVersion -eq "Version: $($ExpectedVersion)") {
            $Output +=  "`n`t`Downloaded OPA` `"$InstalledVersion`" meets the ScubaGear requirement`n"
        }
        else {
            $Output +=  "`n`t`Downloaded OPA` `"$InstalledVersion`" does not meet the ScubaGear requirement of` `"$ExpectedVersion`"`n"
            $Warning = $True
            if($OPAExists){
                return $false, $Output, $Warning
            }
        }
    }
    catch {
        $Error[0] | Format-List -Property * -Force
    }

    $true, $Output, $Warning
}

function Install-OPA {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('url')]
        [string]$InstallUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('out')]
        [string]$OutFile,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('hash')]
        [string]$ExpectedHash,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('v')]
        [string]$ExpectedVersion,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('exe')]
        [string]$OPAExe
    )
    $GetOPAExeParams = @{
        'url' = $InstallUrl;
        'out' = $OutFile
    }
    Get-OPAExecutable @GetOPAExeParams

    $ConfirmOPAValidParams = @{
        'hash' = $ExpectedHash;
        'v' = $ExpectedVersion;
        'exe' = $OPAExe;
    }
    $Results = Confirm-ValidOPAExecutable @ConfirmOPAValidParams
    Write-Information "$($Results[1])"
    if($Results[2]) {
        Write-Error "`tUnable to install correct executable: Retry download or see README under 'Download the required OPA executable' to download manually."
    }
}

# Check if OPA already downloaded
if(Test-Path -Path $OPAExe -PathType Leaf) {
    $ConfirmOPAValidParams = @{
        'hash' = $ExpectedHash;
        'v' = $ExpectedVersion;
        'exe' = $OPAExe;
        'exists' = $True;
    }
    $Results = Confirm-ValidOPAExecutable @ConfirmOPAValidParams
    if($Results[0]) {
        Write-Debug "${OPAExe}: v${ExpectedVersion}, already has latest installed."
    }
    else {
        Write-Information "$($Results[1])"
        $GetOPAParams = @{
            'url' = $InstallUrl;
            'out' = $OutFile
            'hash' = $ExpectedHash;
            'v' = $ExpectedVersion;
            'exe' = $OPAExe;
        }
        Install-OPA @GetOPAParams
    }
}
else {
    $GetOPAParams = @{
        'url' = $InstallUrl;
        'out' = $OutFile
        'hash' = $ExpectedHash;
        'v' = $ExpectedVersion;
        'exe' = $OPAExe;
    }
    Install-OPA @GetOPAParams
}


$DebugPreference = "SilientlyContinue"
$InformationPreference = "SilientlyContinue"
$ErrorActionPreference = "Continue"