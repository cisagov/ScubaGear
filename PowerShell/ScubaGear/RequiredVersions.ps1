[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleList')]
$ModuleList = @(
    @{
        ModuleName = 'MicrosoftTeams'
        ModuleVersion = [version] '7.9.0'
        MaximumVersion = [version] '7.9.0'
        Purpose = 'Microsoft Teams configuration management'
        IsPinned = "False"
    },
    @{
        ModuleName = 'Microsoft.Graph.Authentication'
        ModuleVersion = [version] '2.38.1'
        MaximumVersion = [version] '2.38.1'
        Purpose = 'Microsoft Graph API authentication'
        IsPinned = "False"
    },
    @{
        ModuleName = 'powershell-yaml'
        ModuleVersion = [version] '0.4.2'
        MaximumVersion = [version] '0.4.12'
        Purpose = 'YAML file processing and configuration management'
        IsPinned = "False"
    }
)


