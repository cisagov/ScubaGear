Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1 -Force

Describe 'Remove-Resources' {
    InModuleScope Orchestrator {
        It 'Removes all helper modules with no errors' {
            {Remove-Resources} | Should -Not -Throw
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}