$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Get-FileEncoding' -Force

Describe -Tag 'Orchestrator' -Name 'Get-FileEncoding' {
    InModuleScope Orchestrator {
        It 'Gets utf8 file encoding according to current PS version with no errors' {
            $PSVersion = $PSVersionTable.PSVersion
            if ($PSVersion -ge [System.Version]"6.0"){
                Get-FileEncoding | Should -Be 'utf8NoBom'
            }
            else{
                Get-FileEncoding | Should -Be 'utf8'
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}