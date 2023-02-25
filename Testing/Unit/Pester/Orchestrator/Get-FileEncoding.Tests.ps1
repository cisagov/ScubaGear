$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Get-FileEncoding' -Force

Describe -Tag 'Orchestrator' -Name 'Get-FileEncoding' {
    InModuleScope Orchestrator {
        It 'Gets utf8 file encoding according to current PS version with no errors' {
            {Get-FileEncoding} | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}