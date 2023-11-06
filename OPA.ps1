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
    $ExpectedVersion = '0.58.0',

    [Parameter(Mandatory = $false, HelpMessage = 'The file name that the opa executable is to be saved as')]
    [Alias('name')]
    [string]
    $OPAExe  = "opa_windows_amd64.exe"
)

# Constants
$MINVERSION = [version] '0.42.1'
$INSTALLURL = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/$OPAExe"

# Download opa rego exe
function Get-OPAExecutable {
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

    $OutFile=(Join-Path (Get-Location).Path $INSTALLURL.SubString($INSTALLURL.LastIndexOf('/')))

    try {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($INSTALLURL, $OutFile)
        Write-Information -MessageData "Installed the specified version of ${OPAExe} version ${ExpectedVersion}." | Out-Host
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
    $Request = Invoke-WebRequest $INSTALLURL
    $Hash = (Get-FileHash -InputStream $Request.RawContentStream -Algorithm SHA256).Hash

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

    # Hash checks
    # $ExpectedHash ="5D71028FED935DC98B9D69369D42D2C03CE84A7720D61ED777E10AAE7528F399"
    $ExpectedHash = Get-ExeHash
    if ((Get-FileHash .\opa_windows_amd64.exe -Algorithm SHA256 ).Hash -ne $ExpectedHash) {
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
    Get-OPAExecutable -opa $OPAExe -version $ExpectedVersion
    $Result = Confirm-OPAHash -opa $OPAExe -version $ExpectedVersion
    $Result[1] | Out-Host
}

# Set prefernces for writing messages
$DebugPreference = "Continue"
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

if($ExpectedVersion -lt $MINVERSION) {
    throw "Version parameter entered, ${ExpectedVersion}, must be greater than ${MINVERSION}"
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