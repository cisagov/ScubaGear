$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function Import-Resources

Describe -Tag 'Orchestrator' -Name 'Import-Resources' {
    InModuleScope Orchestrator {
        It 'Imports all helper functions with no errors' {
            {Import-Resources} | Should -Not -Throw
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}