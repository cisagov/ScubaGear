Import-Module ../../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1

InModuleScope ConnectHelpers {
    Describe 'Connect-EXOHelper' {
        BeforeAll {
            function Connect-ExchangeOnline {}
            Mock -ModuleName ConnectHelpers Connect-ExchangeOnline -MockWith {}
        }
        It 'When connecting interactively to commercial endpoint connects to Exchange Online' {
            Connect-EXOHelper -M365Environment 'commercial'
        }
        It 'When connecting interactively to GCC endpoint connects to Exchange Online' {
            Connect-EXOHelper -M365Environment 'gcc'
        }
        It 'When connecting interactively to GCC High endpoint connects to Exchange Online' {
            Connect-EXOHelper -M365Environment 'gcchigh'
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}