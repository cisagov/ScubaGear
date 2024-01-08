$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function Remove-Resources

Describe -Tag 'Orchestrator' -Name 'Remove-Resources' {
    InModuleScope Orchestrator {
        It 'Removes all helper modules with no errors' {
            {Remove-Resources} | Should -Not -Throw
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}