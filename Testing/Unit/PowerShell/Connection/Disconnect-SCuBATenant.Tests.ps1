Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/Connection/Connection.psm1") -Function 'Disconnect-SCuBATenant' -Force

InModuleScope Connection {
    Describe -Tag 'Connection' -Name 'Disconnect-SCuBATenant' {
        BeforeAll {
            Mock Disconnect-MgGraph -MockWith {}
            Mock Disconnect-ExchangeOnline -MockWith {}
            Mock Disconnect-SPOService -MockWith {}
            Mock Disconnect-PnPOnline -MockWith {}
            Mock Remove-PowerAppsAccount -MockWith {}
            Mock Disconnect-MicrosoftTeams -MockWith {}
            Mock -CommandName Write-Progress {}
        }
        It 'Disconnects from Microsoft Graph' {
            Disconnect-SCuBATenant -ProductNames 'aad'
            Should -Invoke -CommandName Disconnect-MgGraph -Times 1 -Exactly
        }
        It 'Disconnects from Exchange Online' {
            Disconnect-SCuBATenant -ProductNames 'exo'
            Should -Invoke -CommandName Disconnect-ExchangeOnline -Times 1 -Exactly
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