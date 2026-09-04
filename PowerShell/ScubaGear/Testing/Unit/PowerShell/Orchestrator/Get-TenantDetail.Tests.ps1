$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Get-TenantDetail'

InModuleScope Orchestrator {
    BeforeAll {
        function Get-AADTenantDetail {}
        Mock -ModuleName Orchestrator Get-AADTenantDetail {
            '{"DisplayName": "displayName"}'
        }
        function Test-SCuBAValidJson {
            param (
                [string]
                $Json
            )
            $ValidJson = $true
            try {
                ConvertFrom-Json $Json -ErrorAction Stop | Out-Null
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson
        }
    }
    Describe -Tag 'Orchestrator' -Name 'Get-TenantDetail' {
        Context 'Make sure Get-TenantDetail returns valid JSON' {
            It 'Returns valid JSON' {
                $EnvironmentArray = @('commercial', 'gcc', 'gcchigh', 'dod')
                foreach ($M365Environment in $EnvironmentArray) {
                    $Json = Get-TenantDetail -M365Environment $M365Environment
                    $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                    $ValidJson | Should -Be $true
                }
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
