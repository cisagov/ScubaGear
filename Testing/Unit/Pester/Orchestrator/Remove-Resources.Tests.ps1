BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
}

Describe 'Remove-Resources' {
    InModuleScope Orchestrator {
        It 'Remove-Resources' {
            Remove-Resources
            $LASTEXITCODE | Should -Be 0
        }
    }
}