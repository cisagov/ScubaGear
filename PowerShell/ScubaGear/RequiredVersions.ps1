[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleList')]
$ModuleList = @(
    @{
        ModuleName = 'MicrosoftTeams'
        ModuleVersion = [version] '4.9.3'
        MaximumVersion = [version] '7.4.0'
        Purpose = 'Microsoft Teams configuration management'
        IsPinned = "False"
    },
    @{
        ModuleName = 'ExchangeOnlineManagement' # includes Defender
        ModuleVersion = [version] '3.2.0'
        MaximumVersion = [version] '3.9.0'
        Purpose = 'Exchange Online and Microsoft Defender management'
        IsPinned = "False"
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
        Purpose = 'SharePoint Online management and automation'
        IsPinned = "True"
    },
    @{
        ModuleName = 'Microsoft.PowerApps.Administration.PowerShell'
        ModuleVersion = [version] '2.0.198'
        MaximumVersion = [version] '2.0.216'
        Purpose = 'Power Platform administrative functions'
        IsPinned = "False"
    },
    @{
        ModuleName = 'Microsoft.PowerApps.PowerShell'
        ModuleVersion = [version] '1.0.0'
        MaximumVersion = [version] '1.0.45'
        Purpose = 'Power Apps development and management'
        IsPinned = "False"
    },
    @{
        ModuleName = 'Microsoft.Graph.Authentication'
        ModuleVersion = [version] '2.0.0'
        MaximumVersion = [version] '2.25.0'
        Purpose = 'Microsoft Graph API authentication'
        IsPinned = "True"
    },
    @{
        ModuleName = 'powershell-yaml'
        ModuleVersion = [version] '0.4.2'
        MaximumVersion = [version] '0.4.12'
        Purpose = 'YAML file processing and configuration management'
        IsPinned = "False"
    }
)



