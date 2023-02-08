BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
}

Describe 'Import-Resources' {
    InModuleScope Orchestrator {
        It 'Import-Resources' {
            Import-Resources
            $LASTEXITCODE | Should -Be 0
        }
    }
}