$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Get-TenantDetail'

InModuleScope Orchestrator {
    BeforeAll {
        function Get-AADTenantDetail {}
        Mock -ModuleName Orchestrator Get-AADTenantDetail {
            '{"DisplayName": "displayName"}'
        }
        function Get-TeamsTenantDetail {}
        Mock -ModuleName Orchestrator Get-TeamsTenantDetail {
            '{"DisplayName": "displayName"}'
        }
        function Get-PowerPlatformTenantDetail {}
        Mock -ModuleName Orchestrator Get-PowerPlatformTenantDetail {
            '{"DisplayName": "displayName"}'
        }
        function Get-EXOTenantDetail {}
        Mock -ModuleName Orchestrator Get-PowerPlatformTenantDetail {
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
        Context 'When connecting to commercial Endpoints' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'M365Environment')]
                $M365Environment = 'commercial'
            }
            It 'With -ProductNames "aad", returns valid JSON' {
                $ProductNames = @('aad')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "exo", returns valid JSON' {
                $ProductNames = @('exo')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "defender", returns valid JSON' {
                $ProductNames = @('defender')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "powerplatform", returns valid JSON' {
                $ProductNames = @('powerplatform')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "sharepoint", returns valid JSON' {
                $ProductNames = @('sharepoint')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "teams", returns valid JSON' {
                $ProductNames = @('teams')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With all products, returns valid JSON' {
                $ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
        }
        Context 'When connecting to GCC Endpoints' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'M365Environment')]
                $M365Environment = 'gcc'
            }
            It 'With -ProductNames "aad", returns valid JSON' {
                $ProductNames = @('aad')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "exo", returns valid JSON' {
                $ProductNames = @('exo')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "defender", returns valid JSON' {
                $ProductNames = @('defender')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "powerplatform", returns valid JSON' {
                $ProductNames = @('powerplatform')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "sharepoint", returns valid JSON' {
                $ProductNames = @('sharepoint')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "teams", returns valid JSON' {
                $ProductNames = @('teams')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With all products, returns valid JSON' {
                $ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
        }
        Context 'When connecting to GCC High Endpoints' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'M365Environment')]
                $M365Environment = 'gcchigh'
            }
            It 'With -ProductNames "aad", returns valid JSON' {
                $ProductNames = @('aad')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "exo", returns valid JSON' {
                $ProductNames = @('exo')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "defender", returns valid JSON' {
                $ProductNames = @('defender')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "powerplatform", returns valid JSON' {
                $ProductNames = @('powerplatform')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "sharepoint", returns valid JSON' {
                $ProductNames = @('sharepoint')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "teams", returns valid JSON' {
                $ProductNames = @('teams')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With all products, returns valid JSON' {
                $ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
        }
        Context 'When connecting to DOD Endpoints' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'M365Environment')]
                $M365Environment = 'dod'
            }
            It 'With -ProductNames "aad", returns valid JSON' {
                $ProductNames = @('aad')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "exo", returns valid JSON' {
                $ProductNames = @('exo')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "defender", returns valid JSON' {
                $ProductNames = @('defender')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "powerplatform", returns valid JSON' {
                $ProductNames = @('powerplatform')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "sharepoint", returns valid JSON' {
                $ProductNames = @('sharepoint')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With -ProductNames "teams", returns valid JSON' {
                $ProductNames = @('teams')
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
            It 'With all products, returns valid JSON' {
                $ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                $Json = Get-TenantDetail -M365Environment $M365Environment -ProductNames $ProductNames
                $ValidJson = Test-SCuBAValidJson -Json $Json | Select-Object -Last 1
                $ValidJson | Should -Be $true
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
