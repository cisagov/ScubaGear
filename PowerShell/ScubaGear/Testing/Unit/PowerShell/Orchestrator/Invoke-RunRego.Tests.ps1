$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-RunRego' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-RunRego' {
        BeforeAll {
            function Invoke-Rego {}
            Mock -ModuleName Orchestrator Invoke-Rego
            function Get-FileEncoding {}
            Mock -ModuleName Orchestrator Get-FileEncoding

            Mock -CommandName Write-Progress {}
            Mock -CommandName Join-Path { "." }
            Mock -CommandName Set-Content {}
            Mock -CommandName ConvertTo-Json {}
            Mock -CommandName ConvertTo-Csv {}
        }
        Context 'When running the rego on a provider json' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'RunRegoParameters')]
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'OutFolderPath')]
                $ScubaConfig = [PSCustomObject]@{
                    ProductNames = @('aad')
                    OPAPath = "./"
                    OutProviderFileName = "ProviderSettingsExport"
                    OutRegoFileName = "TestResults"
                    OutReportName = "BaselineReports"
                    LogIn = $false
                }
                $ParentPath = "./"
                $OutFolderPath = "./"
            }
            It 'With -ProductNames "aad", should not throw' {
                $ScubaConfig.ProductNames = @("aad")
                { Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath } | Should -Not -Throw
            }
            It 'With -ProductNames "defender", should not throw' {
                $ScubaConfig.ProductNames = @("defender")
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
                $ScubaConfig.ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                { Invoke-RunRego -ScubaConfig $ScubaConfig -ParentPath $ParentPath -OutFolderPath $OutFolderPath } | Should -Not -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
