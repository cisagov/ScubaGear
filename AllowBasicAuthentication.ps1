#Requires -RunAsAdministrator

<#
    .SYNOPSIS
        Set Registry to allow basic authentication for WinRM Client

    .DESCRIPTION
        Run this script to enable basic authentication on your local desktop if you get an error when connecting to Exchange Online.

    .NOTES
        See README file Troubleshooting section for details.
        This script requires administrative privileges on your local desktop and updates a registry key.
#>

function Test-RegistryKey {
    <#
        .SYNOPSIS
            Test if registry key exists
    #>
    param (
        [parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,
        [parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Key
    )

    try {
        Get-ItemProperty -Path $Path -Name $Key -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

$regPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client'
$regKey = 'AllowBasic'

if (-Not $(Test-Path -LiteralPath $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
    New-ItemProperty -Path $regPath -Name $regKey | Out-Null
} elseif (-Not $(Test-RegistryKey -Path $regPath -Key $regKey)) {
    New-ItemProperty -Path $regPath -Name $regKey | Out-Null
}

try {
    $allowBasic = Get-ItemPropertyValue -Path $regPath -Name $regKey -ErrorAction Stop

    if ($allowBasic -ne '1') {
        Set-ItemProperty -Path $regPath -Name $regKey -Type DWord -Value '1'
    }
}
catch {
    Write-Error -Message "Unexpected error occured attempting to update registry key, $regKey."
}


