Import-Module ../../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-EXOHelper' {
        BeforeAll {
            function Connect-IPPSSession {}
            Mock -ModuleName ConnectHelpers Connect-IPPSSession -MockWith {}
        }
        It 'When connecting interactively to commercial endpoint, connects to Security & Compliance' {
            {Connect-DefenderHelper -M365Environment 'commercial'} | Should -Not -Throw
        }
        It 'When connecting interactively to GCC endpoint, connects to Security & Compliance' {
            {Connect-DefenderHelper -M365Environment 'gcc'} | Should -Not -Throw
        }
        It 'When connecting interactively to GCC High endpoint, connects to Security & Compliance' {
            {Connect-DefenderHelper -M365Environment 'gcchigh'} | Should -Not -Throw
        }
        It 'When connecting interactively to DOD endpoint, connects to Security & Compliance' {
            {Connect-DefenderHelper -M365Environment 'dod'} | Should -Not -Throw
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}