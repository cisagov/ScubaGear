#Requires -RunAsAdministrator

# Run this script to enable basic authentication on your local desktop if you get an error when connecting to Exchange Online.
# See README file Troubleshooting section for details.
#
# This script requires administrative privileges on your local desktop and updates a registry key.
#
$regPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client'
$regKey = 'AllowBasic'

if (Test-Path -LiteralPath $regPath){
    try {
        $allowBasic = Get-ItemPropertyValue -Path $regPath -Name $regKey -ErrorAction Stop
    }
    catch [System.Management.Automation.PSArgumentException]{
        Write-Error -Message "Key, $regKey, was not found"
    }
    catch{
        Write-Error -Message "Unexpected error occured attempting to get registry key, $regKey."
    }

    if ($allowBasic -ne '1'){
        Set-ItemProperty -Path $regPath -Name $regKey -Type DWord -Value '1'
    }
}
else {
    Write-Error -Message "Registry path not found: $regPath"
}

