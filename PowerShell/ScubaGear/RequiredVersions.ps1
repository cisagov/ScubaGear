[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleList')]
$ModuleList = @(
    @{
        ModuleName = 'MicrosoftTeams'
        ModuleVersion = [version] '4.9.3'
        MaximumVersion = [version] '7.3.1'
        Purpose = 'Microsoft Teams configuration management'
    },
    @{
        ModuleName = 'ExchangeOnlineManagement' # includes Defender
        ModuleVersion = [version] '3.2.0'
        MaximumVersion = [version] '3.9.0'
        Purpose = 'Exchange Online and Microsoft Defender management'
    },
    @{
        ModuleName = 'Microsoft.Online.SharePoint.PowerShell' # includes OneDrive
        ModuleVersion = [version] '16.0.0'
        MaximumVersion = [version] '16.0.24810.12000'
        Purpose = 'SharePoint and OneDrive management'
        IsPinned = "True"
    },
    @{
        ModuleName = 'PnP.PowerShell' # alternate for SharePoint PowerShell
        ModuleVersion = [version] '1.12.0'
        MaximumVersion = [version] '1.99.99999'
        IsPinned = "True"
        Purpose = 'SharePoint Online management and automation'
    },
    @{
        ModuleName = 'Microsoft.PowerApps.Administration.PowerShell'
        ModuleVersion = [version] '2.0.198'
        MaximumVersion = [version] '2.0.214'
        Purpose = 'Power Platform administrative functions'
    },
    @{
        ModuleName = 'Microsoft.PowerApps.PowerShell'
        ModuleVersion = [version] '1.0.0'
        MaximumVersion = [version] '1.0.44'
        Purpose = 'Power Apps development and management'
    },
    @{
        ModuleName = 'Microsoft.Graph.Authentication'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.30.0'
        Purpose = 'Microsoft Graph API authentication'
    },
    @{
        ModuleName = 'powershell-yaml'
        ModuleVersion = [version] '0.4.2'
        MaximumVersion = [version] '0.4.12'
        Purpose = 'YAML file processing and configuration management'
    }
)
