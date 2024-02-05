$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-PrivilegedUser' -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        function Get-PrivilegedUser {throw 'this will be mocked'}
        Mock -ModuleName ExportAADProvider Get-PrivilegedUser {}
        function Get-MgBetaDirectoryRoleMember {throw 'this will be mocked'}
        Mock -ModuleName ExportAADProvider Get-MgBetaDirectoryRoleMember {}
        function Get-MgBetaUser {throw 'this will be mocked'}
        Mock -ModuleName ExportAADProvider Get-MgBetaUser {}
        function Get-MgBetaGroupMember {throw 'this will be mocked'}
        Mock -ModuleName ExportAADProvider Get-MgBetaGroupMember {}
    }
    Describe -Tag 'AADProvider' -Name "Get-PrivilegedUser" {
        It "With no premimum license, returns a not null PowerShell object" {
            {Get-PrivilegedUser} | Should -Not -BeNullOrEmpty
        }
        It "With premimum license, returns a not null PowerShell object" {
            {Get-PrivilegedUser -TenantHasPremiumLicense} | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}