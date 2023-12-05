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

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = 'The version of OPA Rego to be downloaded, must be in "x.x.x" format')]
    [Alias('version')]
    [version]
    $ExpectedVersion = '0.59.0',

    [Parameter(Mandatory = $false, HelpMessage = 'The file name that the opa executable is to be saved as')]
    [Alias('name')]
    [string]
    $OPAExe  = "opa_windows_amd64.exe"
)

# Constants
$ACCEPTABLEVERSIONS = [version] '0.42.1','0.42.2','0.43.1','0.44.0','0.45.0','0.46.3','0.47.4','0.48.0','0.49.2','0.50.2','0.51.0','0.52.0','0.53.1','0.54.0','0.55.0','0.56.0','0.57.1','0.58.0','0.59.0'

# Download opa rego exe
function Get-OPAFile {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('opa')]
        [string]$OPAExe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion
    )

    $InstallUrl = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/opa_windows_amd64.exe"
    $OutFile=(Join-Path (Get-Location).Path $InstallUrl.SubString($InstallUrl.LastIndexOf('/')))

    try {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($InstallUrl, $OutFile)
        Write-Information -MessageData "Installed the specified version of ${OPAExe}: ${ExpectedVersion}." | Out-Host
    }
    catch {
        $Error[0] | Format-List -Property * -Force | Out-Host
        Write-Error "Unable to download OPA executable. To try manually downloading, see details in README under 'Download the required OPA executable'" | Out-Host
    }
    finally {
        $WebClient.Dispose()
    }
}

function Get-ExeHash {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('opa')]
        [string]$OPAExe
    )

    $InstallUrl = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/$OPAExe.sha256"
    $OutFile=(Join-Path (Get-Location).Path $InstallUrl.SubString($InstallUrl.LastIndexOf('/')))

    try {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($InstallUrl, $OutFile)
    }
    catch {
        $Error[0] | Format-List -Property * -Force | Out-Host
        Write-Error "Unable to download OPA SHA256 hash for verification" | Out-Host
    }
    finally {
        $WebClient.Dispose()
    }

    $Hash = ($(Get-Content $OutFile -raw) -split " ")[0]
    Remove-Item $OutFile

    return $Hash
}

function Confirm-OPAHash {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('opa')]
        [string]$OPAExe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion
    )

    if ((Get-FileHash .\$OPAExe -Algorithm SHA256 ).Hash -ne $(Get-ExeHash -opa $OPAExe)) {
        return $false, "SHA256 verification failed, retry download or install manually. See README under 'Download the required OPA executable' for instructions."
    }

    return $true, "Downloaded OPA version `"$ExpectedVersion`" SHA256 verified successfully`n"
}

function Install-OPA {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('opa')]
        [string]$OPAExe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion
    )
    Get-OPAFile -opa $OPAExe -version $ExpectedVersion
    $Result = Confirm-OPAHash -opa $OPAExe -version $ExpectedVersion
    $Result[1] | Out-Host
}

# Set prefernces for writing messages
$DebugPreference = "Continue"
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

if(-not $ACCEPTABLEVERSIONS.Contains($ExpectedVersion)) {
    throw "Version parameter entered, ${ExpectedVersion}, is not in the list of acceptable versions: ${ACCEPTABLEVERSIONS}"
}

if(Test-Path -Path $OPAExe -PathType Leaf) {
    $Result = Confirm-OPAHash -opa $OPAExe -version $ExpectedVersion

    if($Result[0]) {
        Write-Debug "${OPAExe}: ${ExpectedVersion} already has latest installed."
    }
    else {
        Write-Information "SHA256 verification failed, downloading new executable" | Out-Host
        Install-OPA -opa $OPAExe -version $ExpectedVersion
    }
}
else {
    Install-OPA -opa $OPAExe -version $ExpectedVersion
}

$DebugPreference = "SilientlyContinue"
$InformationPreference = "SilientlyContinue"
$ErrorActionPreference = "Continue"