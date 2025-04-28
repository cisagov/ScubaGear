[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleList')]
$ModuleList = @(
    @{
        ModuleName = 'MicrosoftTeams'
        ModuleVersion = [version] '4.9.3'
        MaximumVersion = [version] '7.0.0'
    },
    @{
        ModuleName = 'ExchangeOnlineManagement' # includes Defender
        ModuleVersion = [version] '3.2.0'
        MaximumVersion = [version] '3.7.2'
    },
    @{
        ModuleName = 'Microsoft.Online.SharePoint.PowerShell' # includes OneDrive
        ModuleVersion = [version] '16.0.0'
        MaximumVersion = [version] '16.0.25912.12000'
    },
    @{
        ModuleName = 'PnP.PowerShell' # alternate for SharePoint PowerShell
        ModuleVersion = [version] '1.12.0'
        MaximumVersion = [version] '1.12.0'
    },
    @{
        ModuleName = 'Microsoft.PowerApps.Administration.PowerShell'
        ModuleVersion = [version] '2.0.198'
        MaximumVersion = [version] '2.0.210'
    },
    @{
        ModuleName = 'Microsoft.PowerApps.PowerShell'
        ModuleVersion = [version] '1.0.0'
        MaximumVersion = [version] '1.0.40'
    },
    @{
        ModuleName = 'Microsoft.Graph.Authentication'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.27.0'
    },
    @{
        ModuleName = 'Microsoft.Graph.Beta.Applications'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.27.0'
    },
    @{
        ModuleName = 'Microsoft.Graph.Beta.Users'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.27.0'
    },
    @{
        ModuleName = 'Microsoft.Graph.Beta.Groups'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.27.0'
    },
    @{
        ModuleName = 'Microsoft.Graph.Beta.Identity.DirectoryManagement'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.27.0'
    },
    @{
        ModuleName = 'Microsoft.Graph.Beta.Identity.SignIns'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.27.0'
    },
    @{
        ModuleName = 'Microsoft.Graph.Beta.DirectoryObjects'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.27.0'
    },
    @{
        ModuleName = 'powershell-yaml'
        ModuleVersion = [version] '0.4.2'
        MaximumVersion = [version] '0.4.12'
    }
)
