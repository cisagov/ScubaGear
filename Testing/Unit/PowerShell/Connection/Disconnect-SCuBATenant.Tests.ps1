Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/Connection/Connection.psm1") -Function 'Disconnect-SCuBATenant' -Force

InModuleScope Connection {
    Describe -Tag 'Connection' -Name 'Disconnect-SCuBATenant' {
        BeforeAll {
            function Disconnect-MgGraph {}
            Mock -ModuleName Connection Disconnect-MgGraph -MockWith {}
            function Disconnect-ExchangeOnline {}
            Mock -ModuleName Connection Disconnect-ExchangeOnline -MockWith {}
            function Disconnect-SPOService {}
            Mock -ModuleName Connection Disconnect-SPOService -MockWith {}
            function Disconnect-PnPOnline {}
            Mock -ModuleName Connection Disconnect-PnPOnline -MockWith {}
            function Remove-PowerAppsAccount {}
            Mock -ModuleName Connection Remove-PowerAppsAccount -MockWith {}
            function Disconnect-MicrosoftTeams {}
            Mock -ModuleName Connection Disconnect-MicrosoftTeams -MockWith {}
            Mock -CommandName Write-Progress {}
        }
        It 'Disconnects from Microsoft Graph' {
            {Disconnect-SCuBATenant -ProductNames 'aad'} | Should -Not -Throw
        }
        It 'Disconnects from Exchange Online' {
            {Disconnect-SCuBATenant -ProductNames 'exo'} | Should -Not -Throw
        }
        It 'Disconnects from Defender (Exchange Online and Security & Compliance)' {
            {Disconnect-SCuBATenant -ProductNames 'defender'} | Should -Not -Throw
        }
        It 'Disconnects from One Drive (SharePoint Online)' {
            {Disconnect-SCuBATenant -ProductNames 'onedrive'} | Should -Not -Throw
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