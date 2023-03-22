Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1") -Function 'Connect-EXOHelper' -Force

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-EXOHelper' {
        BeforeAll {
            Mock Connect-ExchangeOnline -MockWith {}
        }
        It 'When connecting interactively to commercial endpoint, connects to Exchange Online' {
            {Connect-EXOHelper -M365Environment 'commercial'} | Should -Not -Throw
        }
        It 'When connecting interactively to GCC endpoint, connects to Exchange Online' {
            {Connect-EXOHelper -M365Environment 'gcc'} | Should -Not -Throw
        }
        It 'When connecting interactively to GCC High endpoint, connects to Exchange Online' {
            {Connect-EXOHelper -M365Environment 'gcchigh'} | Should -Not -Throw
        }
        It 'When connecting interactively to DOD endpoint, connects to Exchange Online' {
            {Connect-EXOHelper -M365Environment 'dod'} | Should -Not -Throw
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}