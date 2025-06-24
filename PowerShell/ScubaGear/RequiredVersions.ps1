[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleList')]
$ModuleList = @(
    @{
        ModuleName = 'MicrosoftTeams'
        ModuleVersion = [version] '4.9.3'
        MaximumVersion = [version] '6.99.99999'
    },
    @{
        ModuleName = 'ExchangeOnlineManagement' # includes Defender
        ModuleVersion = [version] '3.2.0'
        MaximumVersion = [version] '3.4.99999'
    },
    @{
        ModuleName = 'Microsoft.Online.SharePoint.PowerShell' # includes OneDrive
        ModuleVersion = [version] '16.0.0'
        MaximumVersion = [version] '16.0.24810.12000'
    },
    @{
        ModuleName = 'PnP.PowerShell' # alternate for SharePoint PowerShell
        ModuleVersion = [version] '1.12.0'
        MaximumVersion = [version] '1.99.99999'
    },
    @{
        ModuleName = 'Microsoft.PowerApps.Administration.PowerShell'
        ModuleVersion = [version] '2.0.198'
        MaximumVersion = [version] '2.0.203'
    },
    @{
        ModuleName = 'Microsoft.PowerApps.PowerShell'
        ModuleVersion = [version] '1.0.0'
        MaximumVersion = [version] '1.99.99999'
    },
    @{
        ModuleName = 'Microsoft.Graph.Authentication'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.99.99999'
    },
    @{
        ModuleName = 'Microsoft.Graph.Beta.Applications'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.99.99999'
    },
    @{
        ModuleName = 'Microsoft.Graph.Beta.Identity.DirectoryManagement'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.99.99999'
    },
    @{
        ModuleName = 'Microsoft.Graph.Beta.DirectoryObjects'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.99.99999'
    },
    @{
        ModuleName = 'powershell-yaml'
        ModuleVersion = [version] '0.4.2'
        MaximumVersion = [version] '0.99.99999'
    }
)