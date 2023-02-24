Import-Module ../../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1

InModuleScope ConnectHelpers {
    Describe 'Connect-EXOHelper' {
        BeforeAll {
            function Connect-IPPSSession {}
            Mock -ModuleName ConnectHelpers Connect-IPPSSession -MockWith {}
        }
        It 'When connecting interactively to commercial endpoint connects to Security & Compliance' {
            Connect-DefenderHelper -M365Environment 'commercial'
        }
        It 'When connecting interactively to GCC endpoint connects to Security & Compliance' {
            Connect-DefenderHelper -M365Environment 'gcc'
        }
        It 'When connecting interactively to GCC High endpoint connects to Security & Compliance' {
            Connect-DefenderHelper -M365Environment 'gcchigh'
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}