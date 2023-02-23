Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1 -Force

Describe 'Import-Resources' {
    InModuleScope Orchestrator {
        It 'Imports all helper functions with no errors' {
            {Import-Resources} | Should -Not -Throw
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}