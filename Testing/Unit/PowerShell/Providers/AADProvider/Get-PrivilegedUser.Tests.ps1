$ProviderPath = '../../../../../PowerShell/ScubaGear/Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-PrivilegedUser' -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        function Get-PrivilegedUser {}
        Mock -ModuleName ExportAADProvider Get-PrivilegedUser -MockWith {}
        function Get-MgBetaDirectoryRoleMember {}
        Mock -ModuleName ExportAADProvider Get-MgBetaDirectoryRoleMember -MockWith {}
        function Get-MgBetaUser {}
        Mock -ModuleName ExportAADProvider Get-MgBetaUser -MockWith {}
        function Get-MgBetaGroupMember {}
        Mock -ModuleName ExportAADProvider Get-MgBetaGroupMember -MockWith {}
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