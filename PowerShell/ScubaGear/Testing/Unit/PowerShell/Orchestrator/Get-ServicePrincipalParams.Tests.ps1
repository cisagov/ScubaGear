$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Get-ServicePrincipalParams'

Describe -Tag 'Orchestrator' -Name 'Get-ServicePrincipalParams' {
    InModuleScope Orchestrator {
        It 'Returns a CertficateThumbprint PSObject with no errors' {
            $BoundParameters = @{
                CertificateThumbprint = 'WPOEALFN425A';
                AppID = '34289UFAHWFALL';
                Organization = 'example.onmicrosoft.com';
            }
            {Get-ServicePrincipalParams -BoundParameters $BoundParameters} | Should -Not -Throw
        }
        It 'Throws an error if no correct Service Principal Params are passed in' {
            $BoundParameters = @{
                a = 'a';
            }
            {Get-ServicePrincipalParams -BoundParameters $BoundParameters} | Should -Throw
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}