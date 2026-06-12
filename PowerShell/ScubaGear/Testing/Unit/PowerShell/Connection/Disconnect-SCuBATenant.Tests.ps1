BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'Connection.psm1') -Function 'Disconnect-SCuBATenant' -Force
}

InModuleScope Connection {
    Describe -Tag 'Connection' -Name 'Disconnect-SCuBATenant' {
        BeforeAll {
            function Disconnect-MgGraph {throw 'this will be mocked'}
            Mock -ModuleName Connection Disconnect-MgGraph {}
            # EXO now uses REST API - no ExchangeOnline module disconnect needed
            # SharePoint uses REST API - no SPO module disconnect needed
            function Remove-PowerAppsAccount {throw 'this will be mocked'}
            Mock  -ModuleName Connection Remove-PowerAppsAccount {}
            function Disconnect-MicrosoftTeams {throw 'this will be mocked'}
            Mock  -ModuleName Connection Disconnect-MicrosoftTeams {}
            Mock -CommandName Write-Progress {}
        }
        It 'Disconnects from Microsoft Graph' {
            Disconnect-SCuBATenant -ProductNames 'aad'
            Should -Invoke -ModuleName Connection -CommandName Disconnect-MgGraph -Times 1 -Exactly
        }
        It 'Disconnects from Exchange Online' {
            # EXO uses REST API with on-demand token - no persistent connection to disconnect
            {Disconnect-SCuBATenant -ProductNames 'exo'} | Should -Not -Throw
        }
        It 'Disconnects from Security Suite (Exchange Online and Security & Compliance)' {
            {Disconnect-SCuBATenant -ProductNames 'securitysuite'} | Should -Not -Throw
        }
        It 'Disconnects from Power Platform' {
            {Disconnect-SCuBATenant -ProductNames 'powerplatform'} | Should -Not -Throw
        }
        It 'Disconnects from SharePoint Online' {
            {Disconnect-SCuBATenant -ProductNames 'sharepoint'} | Should -Not -Throw
        }
        It 'Disconnects from Microsoft Teams' {
            {Disconnect-SCuBATenant -ProductNames 'sharepoint'} | Should -Not -Throw
        }
        It 'Disconnects from all products' {
            {Disconnect-SCuBATenant} | Should -Not -Throw
        }
    }
}

AfterAll {
    Remove-Module Connection -ErrorAction SilentlyContinue
}