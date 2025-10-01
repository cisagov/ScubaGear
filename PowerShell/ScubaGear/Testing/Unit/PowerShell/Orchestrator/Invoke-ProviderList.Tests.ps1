$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-ProviderList' -Force

InModuleScope Orchestrator {
Describe -Tag 'Orchestrator' -Name 'Invoke-ProviderList' {
    BeforeAll {
    function Set-Utf8NoBom {}
    Mock -ModuleName Orchestrator Set-Utf8NoBom {}
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
        Mock -CommandName Set-Utf8NoBom {}
        Mock -CommandName Write-Debug {}
    }
    Context 'When running the providers on commercial tenants' {
        BeforeAll {
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ScubaConfig')]
              $ScubaConfig = [PSCustomObject]@{
                 ProductNames = @('aad')
                 OutProviderFileName = "ProviderSettingsExport"
                 M365Environment = "commercial"
                 OutRegoFileName = "TestResults"
                 OutReportName = "BaselineReports"
                 OPAPath = "."
                 LogIn = $false
              }
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'TenantDetails')]
              $TenantDetails = '{"DisplayName": "displayName"}'
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ModuleVersion')]
              $ModuleVersion = '1.0'
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'OutFolderPath')]
              $OutFolderPath = "./output"
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Guid')]
              $Guid = "00000000-0000-0000-0000-000000000000"
              [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'BoundParameters')]
              $BoundParameters = @{}
        }
        It 'With -ProductNames "aad", should not throw' {
              $ScubaConfig.ProductNames = @("aad")
            { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -BoundParameters $BoundParameters } | Should -Not -Throw
        }
        It 'With -ProductNames "defender", should not throw' {
              $ScubaConfig.ProductNames = @("defender")
            { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -BoundParameters $BoundParameters } | Should -Not -Throw
        }
        It 'With -ProductNames "exo", should not throw' {
              $ScubaConfig.ProductNames = @("exo")
            { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -BoundParameters $BoundParameters } | Should -Not -Throw
        }
        It 'With -ProductNames "powerplatform", should not throw' {
              $ScubaConfig.ProductNames = @("powerplatform")
            { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -BoundParameters $BoundParameters } | Should -Not -Throw
        }
        It 'With -ProductNames "sharepoint", should not throw' {
              $ScubaConfig.ProductNames = @("sharepoint")
            { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -BoundParameters $BoundParameters } | Should -Not -Throw
        }
        It 'With -ProductNames "teams", should not throw' {
              $ScubaConfig.ProductNames = @("teams")
            { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -BoundParameters $BoundParameters } | Should -Not -Throw
        }
        It 'With all products, should not throw' {
              $ScubaConfig.ProductNames = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")
            { Invoke-ProviderList -ScubaConfig $ScubaConfig -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -Guid $Guid -BoundParameters $BoundParameters } | Should -Not -Throw
        }
    }
    }
}

AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
