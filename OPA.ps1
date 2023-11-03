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

# Download files
function Get-OPAExecutable {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('opa')]
        [string]$OPAExe
    )

    $InstallUrl = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/$OPAExe"
    $OutFile=(Join-Path (Get-Location).Path $InstallUrl.SubString($InstallUrl.LastIndexOf('/')))

    try {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($InstallUrl, $OutFile)
        Write-Information -MessageData "Installed the latest acceptable version of ${OPAExe} version ${ExpectedVersion}." | Out-Host
    }
    catch {
        $Error[0] | Format-List -Property * -Force | Out-Host
        Write-Error "Unable to download OPA executable. To try manually downloading, see details in README under 'Download the required OPA executable'" | Out-Host
    }
    finally {
        $WebClient.Dispose()
    }
}


function Confirm-OPAExeIsValid {
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
    $ExpectedHash ="5D71028FED935DC98B9D69369D42D2C03CE84A7720D61ED777E10AAE7528F399"
    $Output = ""
    if ((Get-FileHash .\opa_windows_amd64.exe).Hash -ne $ExpectedHash) {
        Write-Information "SHA256 verification failed, retry download or install manually. See README under 'Download the required OPA executable' for instructions." | Out-Host
        return $false
    }

    # Version checks
    Try {
        $OPAArgs = @('version')
        $InstalledVersion= $(& "./$($OPAExe)" @OPAArgs) | Select-Object -First 1
        if ($InstalledVersion -ne "Version: $($ExpectedVersion)") {
            Write-Information "`Downloaded OPA version` `"$InstalledVersion`" does not meet the ScubaGear requirement of` `"$ExpectedVersion`"" | Out-Host
            return $false
        }
    }
    catch {
        $Error[0] | Format-List -Property * -Force | Out-Host
        Write-Error "See details on manual installation in the README under 'Download the required OPA executable'" | Out-Host
        return $false
    }

    $Output += "Downloaded OPA version `"$InstalledVersion`" SHA256 verified successfully`n"
    return $true, $Output
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
    $Result = Confirm-OPAExeIsValid -opa $OPAExe -version $ExpectedVersion
    $Result[1] | Out-Host
}

# Set expected version and OutFile path
$ExpectedVersion = "0.42.1"
$OPAExe = "opa_windows_amd64.exe"

if(Test-Path -Path $OPAExe -PathType Leaf) {
    $Result = Confirm-OPAExeIsValid -opa $OPAExe -version $ExpectedVersion

    if($Result[0]) {
        Write-Debug "${OPAExe}: ${ExpectedVersion} already has latest installed."
    }
    else {
        Install-OPA -opa $OPAExe -version $ExpectedVersion
    }
}
else {
    Install-OPA -opa $OPAExe -version $ExpectedVersion
}

$DebugPreference = "SilientlyContinue"
$InformationPreference = "SilientlyContinue"
$ErrorActionPreference = "Continue"