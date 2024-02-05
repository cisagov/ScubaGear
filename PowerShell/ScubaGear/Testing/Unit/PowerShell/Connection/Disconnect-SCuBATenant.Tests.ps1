BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'Connection.psm1') -Function 'Disconnect-SCuBATenant' -Force
}

InModuleScope Connection {
    Describe -Tag 'Connection' -Name 'Disconnect-SCuBATenant' {
        BeforeAll {
            Mock -ModuleName Connection Disconnect-MgGraph {}
            Mock -ModuleName Connection Disconnect-ExchangeOnline {}
            Mock Disconnect-SPOService {}
            Mock Remove-PowerAppsAccount {}
            Mock Disconnect-MicrosoftTeams {}
            Mock -CommandName Write-Progress {}
        }
        It 'Disconnects from Microsoft Graph' {
            Disconnect-SCuBATenant -ProductNames 'aad'
            Should -Invoke -ModuleName Connection -CommandName Disconnect-MgGraph -Times 1 -Exactly
        }
        It 'Disconnects from Exchange Online' {
            Disconnect-SCuBATenant -ProductNames 'exo'
            Should -Invoke -ModuleName Connection -CommandName Disconnect-ExchangeOnline -Times 1 -Exactly
        }
        It 'Disconnects from Defender (Exchange Online and Security & Compliance)' {
            {Disconnect-SCuBATenant -ProductNames 'defender'} | Should -Not -Throw
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