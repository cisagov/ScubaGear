$OrchestratorPath = '../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-ProviderList' -Force

InModuleScope Orchestrator {
Describe -Tag 'Orchestrator' -Name 'Invoke-ProviderList' {
    BeforeAll {
        function Export-AADProvider {}
        Mock -ModuleName Orchestrator Export-AADProvider {}
        function Export-EXOProvider {}
        Mock -ModuleName Orchestrator Export-EXOProvider {}
        function Export-DefenderProvider {}
        Mock -ModuleName Orchestrator Export-DefenderProvider {}
        function Export-PowerPlatformProvider {}
        Mock -ModuleName Orchestrator Export-PowerPlatformProvider {}
        function Export-SharePointProvider {}
        Mock -ModuleName Orchestrator Export-SharePointProvider {}
        function Export-TeamsProvider {}
        Mock -ModuleName Orchestrator Export-TeamsProvider {}
        function Get-FileEncoding {}
        Mock -ModuleName Orchestrator Get-FileEncoding {}

        Mock -CommandName Write-Progress {}
        Mock -CommandName Join-Path {"."}
        Mock -CommandName Set-Content {}
        Mock -CommandName Get-TimeZone {}
    }
    Context 'When running the providers on commercial tenants' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ProviderParameters')]
            $ProviderParameters = @{
                OutFolderPath = "./output";
                OutProviderFileName = "ProviderSettingsExport";
                M365Environment = "commercial";
                TenantDetails = '{"DisplayName": "displayName"}';
                ModuleVersion = '1.0';
                BoundParameters = @{};
            }
        }
        It 'With -ProductNames "aad", should not throw' {
            $ProviderParameters += @{
                ProductNames = @("aad")
            }
            {Invoke-ProviderList @ProviderParameters} | Should -Not -Throw
        }
        It 'With -ProductNames "defender", should not throw' {
            $ProviderParameters += @{
                ProductNames = @("defender")
            }
            {Invoke-ProviderList @ProviderParameters} | Should -Not -Throw
        }
        It 'With -ProductNames "exo", should not throw' {
            $ProviderParameters += @{
                ProductNames = @("exo")
            }
            {Invoke-ProviderList @ProviderParameters} | Should -Not -Throw
        }
        It 'With -ProductNames "powerplatform", should not throw' {
            $ProviderParameters += @{
                ProductNames = @("powerplatform")
            }
            {Invoke-ProviderList @ProviderParameters} | Should -Not -Throw
        }
        It 'With -ProductNames "sharepoint", should not throw' {
            $ProviderParameters += @{
                ProductNames = @("sharepoint")
            }
            {Invoke-ProviderList @ProviderParameters} | Should -Not -Throw
        }
        It 'With -ProductNames "teams", should not throw' {
            $ProviderParameters += @{
                ProductNames = @("teams")
            }
            {Invoke-ProviderList @ProviderParameters} | Should -Not -Throw
        }
        It 'With all products, should not throw' {
            $ProviderParameters += @{
                ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
            }
            {Invoke-ProviderList @ProviderParameters} | Should -Not -Throw
        }
    }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}