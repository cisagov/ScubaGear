#Requires -Version 5.1
<#
    .SYNOPSIS
        This script removes the Powershell modules required by the
        ScubaGear assessment tool.
    .DESCRIPTION
        Uninstalls the modules required to support ScubaGear.  This includes
        module dependencies specific to ScubaGear.  This tool is meant to
        be used to return a system to a state prior to ScubaGear installation.
    .EXAMPLE
        .\UninstallModules.ps1
    .NOTES
        Executing the script with no switches set will remove the latest
        version of the modules already installed.
#>

$ModuleList = @(
    "MicrosoftTeams",
    "ExchangeOnlineManagement", # includes Defender
    "Microsoft.Online.SharePoint.PowerShell",
    "PnP.PowerShell", # for authenticating to SharePoint with an application
    "Microsoft.PowerApps.Administration.PowerShell",
    "Microsoft.PowerApps.PowerShell",
    "Microsoft.Graph.Authentication", # starting here, MS Graph modules for AAD
    "Microsoft.Graph.Beta.Groups",
    "Microsoft.Graph.Beta.Identity.DirectoryManagement",
    "Microsoft.Graph.Beta.Identity.Governance",
    "Microsoft.Graph.Beta.Identity.SignIns",
    "Microsoft.Graph.Beta.Users",
    "powershell-yaml"
    )

$PSGetVersion = (Get-Module -ListAvailable -Name "PowerShellGet") |
                 Sort-Object Version -Descending | Select-Object Version -First 1 |
                 Select-Object Version -ExpandProperty Version

foreach($Module in $ModuleList) {
    if(Get-Module -ListAvailable -Name $Module) {
        $CurrentVersion = (Get-Module -ListAvailable -Name $Module) | Sort-Object Version -Descending | Select-Object Version -First 1
        $SCurrentVersion = $CurrentVersion | Select-Object @{n = 'ModuleVersion'; e = { $_.Version -as [string] } }
        $V = $SCurrentVersion | Select-Object ModuleVersion -ExpandProperty ModuleVersion


        Write-Output "Uninstalling module: ${Module} v${V}"

        # PowerShellGet < 3.0 has issues removing modules installed on OneDrive using Uninstall-Module
        # so check if PSGet >= 3.0 is installed and use Uninstall-PSResource instead which works fine.
        if($PSGetVersion -gt [System.Version]"3.0.0") {
            Uninstall-PSResource -Name $Module -Scope CurrentUser -Version $V
        }
        else {
            Uninstall-Module -Name $Module -RequiredVersion $V -Force
        }
    }
}
