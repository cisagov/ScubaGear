$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-RunRego' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-RunRego' {
        BeforeAll {
            function Invoke-Rego {}
            Mock -ModuleName Orchestrator Invoke-Rego
            function Get-FileEncoding {}
            Mock -ModuleName Orchestrator Get-FileEncoding { 'utf8' }

            Mock -CommandName Write-Progress {}
            Mock -CommandName Join-Path { "." }
            Mock -CommandName Set-Content {}
            Mock -CommandName ConvertTo-Json {}
            Mock -CommandName ConvertTo-Csv {}
        }
        Context 'When running the rego on a provider json' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'RunRegoParameters')]
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    OPAPath = "./"
                    OutProviderFileName = "ProviderSettingsExport"
                    OutRegoFileName = "RegoOutput"
                    OutReportName = "BaselineReports"
                    LogIn = $false
                }
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ParentPath')]
                $ParentPath = "./"
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'OutFolderPath')]
                $OutFolderPath = "./"
            }
            It 'Reports progress for <Label>' -ForEach @(
                @{ Label = 'a scalar product'; Products = 'aad'; Total = 1 }
                @{ Label = 'a scalar security suite'; Products = 'securitysuite'; Total = 1 }
                @{ Label = 'a single-element array'; Products = @('aad'); Total = 1 }
                @{ Label = 'multiple products'; Products = @('aad', 'exo'); Total = 2 }
            ) {
                $ScubaConfig.ProductNames = $Products
                Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath
                Should -Invoke Write-Progress -Exactly -Times $Total
                for ($Index = 1; $Index -le $Total; $Index++) {
                    Should -Invoke Write-Progress -Exactly -Times 1 -ParameterFilter {
                        $Status -like "*$Index of $Total *" -and
                        $PercentComplete -eq ($Index * 100 / $Total)
                    }
                }
            }
            It 'With -ProductNames "aad", should not throw' {
                $ScubaConfig.ProductNames = @("aad")
                { Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath } | Should -Not -Throw
            }
            It 'With -ProductNames "securitysuite", should not throw' {
                $ScubaConfig.ProductNames = @("securitysuite")
                { Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath } | Should -Not -Throw
            }
            It 'With -ProductNames "exo", should not throw' {
                $ScubaConfig.ProductNames = @("exo")
                { Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath } | Should -Not -Throw
            }
            It 'With -ProductNames "powerplatform", should not throw' {
                $ScubaConfig.ProductNames = @("powerplatform")
                { Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath } | Should -Not -Throw
            }
            It 'With -ProductNames "sharepoint", should not throw' {
                $ScubaConfig.ProductNames = @("sharepoint")
                { Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath } | Should -Not -Throw
            }
            It 'With -ProductNames "teams", should not throw' {
                $ScubaConfig.ProductNames = @("teams")
                { Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath } | Should -Not -Throw
            }
            It 'With all products, should not throw' {
                $ScubaConfig.ProductNames = @("aad", "securitysuite", "exo", "powerplatform", "sharepoint", "teams")
                { Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath } | Should -Not -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
