$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function Remove-Resources

Describe -Tag 'Orchestrator' -Name 'Remove-Resources' {
    InModuleScope Orchestrator {
        It 'Removes all helper modules with no errors' {
            {Remove-Resources} | Should -Not -Throw
        }

        It 'Removes CommandTracker so providers do not retain stale logging references' {
            $CommandTrackerPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Providers/ProviderHelpers/CommandTracker.psm1'
            Import-Module $CommandTrackerPath -Force
            Get-Module -Name 'CommandTracker' | Should -Not -BeNullOrEmpty

            Remove-Resources

            Get-Module -Name 'CommandTracker' | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
