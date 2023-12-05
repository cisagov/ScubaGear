Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1") -Function 'Connect-EXOHelper' -Force

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-EXOHelper' -ForEach @(
        @{Endpoint = 'commercial'}
        @{Endpoint = 'gcc'}
        @{Endpoint = 'gcchigh'}
        @{Endpoint = 'dod'}
    ){
        BeforeAll {
            Mock Connect-ExchangeOnline -MockWith {}
        }
        It 'When connecting interactively to <Endpoint> endpoint, connects to Exchange Online' {
            {Connect-EXOHelper -M365Environment $Endpoint} | Should -Not -Throw
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}