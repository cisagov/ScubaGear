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
    [string]
    $ExpectedVersion = '0.42.1',

    [Parameter(Mandatory = $false, HelpMessage = 'The file name that the opa executable is to be saved as')]
    [Alias('name')]
    [string]
    $OPAExe = "",

    [Parameter(Mandatory = $false, HelpMessage = 'The operating system the program is running on')]
    [ValidateSet('Windows','MacOS','Linux')]
    [Alias('os')]
    [string]
    $OperatingSystem  = "Windows",

    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]
    $ScubaParentDirectory = $env:USERPROFILE
)

$ScubaHiddenHome = Join-Path -Path $ScubaParentDirectory -ChildPath '.scubagear'
$ScubaTools = Join-Path -Path $ScubaHiddenHome -ChildPath 'Tools'
New-Item -ItemType Directory -Force -Path $ScubaTools


[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = 'The version of OPA Rego to be downloaded, must be in "x.x.x" format')]
    [Alias('version')]
    [string]
    $ExpectedVersion = '0.59.0',

    [Parameter(Mandatory = $false, HelpMessage = 'The file name that the opa executable is to be saved as')]
    [Alias('name')]
    [string]
    $OPAExe = "",

    [Parameter(Mandatory = $false, HelpMessage = 'The operating system the program is running on')]
    [ValidateSet('Windows','MacOS','Linux')]
    [Alias('os')]
    [string]
    $OperatingSystem  = "Windows"
)

# Constants
$ACCEPTABLEVERSIONS = '0.42.1','0.42.2','0.43.1','0.44.0','0.45.0','0.46.3','0.47.4','0.48.0','0.49.2','0.50.2',
                        '0.51.0','0.52.0','0.53.1','0.54.0','0.55.0','0.56.0','0.57.1','0.58.0','0.59.0'
$FILENAME = @{ Windows = "opa_windows_amd64.exe"; MacOS = "opa_darwin_amd64"; Linux = "opa_linux_amd64_static"}

# Download opa rego exe
function Get-OPAFile {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('out')]
        [string]$OPAExe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('name')]
        [string]$Filename
    )

    $InstallUrl = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/$($Filename)"
    $OutFile=(Join-Path (Get-Location).Path $OPAExe)

    try {
        $Display = "Downloading OPA executable"
        Start-BitsTransfer -Source $InstallUrl -Destination $OutFile -DisplayName $Display -MaxDownloadTime 300
        Write-Information -MessageData "Installed the specified OPA version (${ExpectedVersion}) to ${OPAExe}" | Out-Host
    }
    catch {
        $Error[0] | Format-List -Property * -Force | Out-Host
        throw "Unable to download OPA executable. To try manually downloading, see details in README under 'Download the required OPA executable'" | Out-Host
    }
}

function Get-ExeHash {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('name')]
        [string]$Filename,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion
    )

    $InstallUrl = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/$($Filename).sha256"
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
        [Alias('out')]
        [string]$OPAExe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('name')]
        [string]
        $Filename
    )

    if ((Get-FileHash .\$OPAExe -Algorithm SHA256 ).Hash -ne $(Get-ExeHash -name $Filename -version $ExpectedVersion)) {
        return $false, "SHA256 verification failed, retry download or install manually. See README under 'Download the required OPA executable' for instructions."
    }

    return $true, "Downloaded OPA version ($ExpectedVersion) SHA256 verified successfully`n"
}

function Install-OPA {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('out')]
        [string]$OPAExe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('name')]
        [string]
        $Filename
    )

    Get-OPAFile -out $OPAExe -version $ExpectedVersion -name $Filename
    $Result = Confirm-OPAHash -out $OPAExe -version $ExpectedVersion -name $Filename
    $Result[1] | Out-Host
}

# Set prefernces for writing messages
$DebugPreference = "Continue"
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

if(-not $ACCEPTABLEVERSIONS.Contains($ExpectedVersion)) {
    $AcceptableVersionsString = $ACCETABLEVERSIONS -join "`r`n" | Out-String
    throw "Version parameter entered, ${ExpectedVersion}, is not in the list of acceptable versions. Acceptable versions are:`r`n${AcceptableVersionsString}"
}

$Filename = $FILENAME.$OperatingSystem
if($OPAExe -eq "") {
    $OPAExe = $Filename
}

if(Test-Path -Path $OPAExe -PathType Leaf) {
    $Result = Confirm-OPAHash -out $OPAExe -version $ExpectedVersion -name $Filename

    if($Result[0]) {
        Write-Debug "${OPAExe}: ${ExpectedVersion} already has latest installed."
    }
    else {
        if($OPAExe -eq $Filename) {
            Write-Information "SHA256 verification failed, downloading new executable" | Out-Host
            Install-OPA -out $OPAExe -version $ExpectedVersion -name $Filename
        }
        else {
            Write-Warning "SHA256 verification failed, please confirm file name is correct & remove old file before running script" | Out-Host
        }
    }
}
else {
    Install-OPA -out $OPAExe -version $ExpectedVersion -name $Filename
}

$DebugPreference = "SilentlyContinue"
$InformationPreference = "SilentlyContinue"
$ErrorActionPreference = "Continue"