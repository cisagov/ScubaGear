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
        ModuleName = 'powershell-yaml'
        ModuleVersion = [version] '0.4.2'
        MaximumVersion = [version] '0.4.12'
        Purpose = 'YAML file processing and configuration management'
        IsPinned = "False"
    }
)


