$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
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
                $RunRegoParameters = @{
                    OPAPath             = "./"
                    ParentPath          = "./"
                    OutFolderPath       = "./"
                    OutProviderFileName = "ProviderSettingsExport"
                    OutRegoFileName     = "TestResults"
                }
            }
            It 'With -ProductNames "aad", should not throw' {
                $RunRegoParameters += @{
                    ProductNames = @("aad")
                }
                { Invoke-RunRego @RunRegoParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "defender", should not throw' {
                $RunRegoParameters += @{
                    ProductNames = @("defender")
                }
                { Invoke-RunRego @RunRegoParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "exo", should not throw' {
                $RunRegoParameters += @{
                    ProductNames = @("exo")
                }
                { Invoke-RunRego @RunRegoParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "powerplatform", should not throw' {
                $RunRegoParameters += @{
                    ProductNames = @("powerplatform")
                }
                { Invoke-RunRego @RunRegoParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "sharepoint", should not throw' {
                $RunRegoParameters += @{
                    ProductNames = @("sharepoint")
                }
                { Invoke-RunRego @RunRegoParameters } | Should -Not -Throw
            }
            It 'With -ProductNames "teams", should not throw' {
                $RunRegoParameters += @{
                    ProductNames = @("teams")
                }
                { Invoke-RunRego @RunRegoParameters } | Should -Not -Throw
            }
            It 'With all products, should not throw' {
                $RunRegoParameters += @{
                    ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
                }
                { Invoke-RunRego @RunRegoParameters } | Should -Not -Throw
            }
        }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
