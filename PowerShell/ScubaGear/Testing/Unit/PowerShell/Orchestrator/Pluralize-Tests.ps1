$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Pluralize'

Describe -Tag 'Orchestrator' -Name 'Pluralize' {
    InModuleScope Orchestrator {
        It 'Chooses the plural noun' {
            (Pluralize -SingularNoun "warning" -PluralNoun "warnings" -Count 2) | Should -eq "warnings"
        }
        It 'Chooses the singular noun' {
            (Pluralize -SingularNoun "warning" -PluralNoun "warnings" -Count 1) | Should -eq "warning"
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}