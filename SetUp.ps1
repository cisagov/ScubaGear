#
# This script installs the required Powershell modules used by the assessment tool.
#

$ModuleList = @(
    "PowerShellGet",
    "MicrosoftTeams",
    "ExchangeOnlineManagement", # includes Defender
    "Microsoft.Online.SharePoint.PowerShell", # includes OneDrive
    "Microsoft.PowerApps.Administration.PowerShell",
    "Microsoft.PowerApps.PowerShell",
    "Microsoft.Graph.Applications", # starting here, modules for AAD
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.DeviceManagement",
    "Microsoft.Graph.DeviceManagement.Administration",
    "Microsoft.Graph.DeviceManagement.Enrolment",
    "Microsoft.Graph.Devices.CorporateManagement",
    "Microsoft.Graph.Groups",
    "Microsoft.Graph.Identity.DirectoryManagement",
    "Microsoft.Graph.Identity.Governance",
    "Microsoft.Graph.Identity.SignIns",
    "Microsoft.Graph.Planner",
    "Microsoft.Graph.Teams",
    "Microsoft.Graph.Users"
    )

foreach($Module in $ModuleList) {
    Install-Module -Name $Module -Force -AllowClobber -Scope CurrentUser -Verbose
}
