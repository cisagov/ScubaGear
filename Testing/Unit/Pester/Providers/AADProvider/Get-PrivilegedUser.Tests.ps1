Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportAADProvider.psm1 -Function "Get-PrivilegedUser" -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        function Get-PrivilegedUser {}
        Mock -ModuleName ExportAADProvider Get-PrivilegedUser -MockWith {}
        function Get-MgDirectoryRoleMember {}
        Mock -ModuleName ExportAADProvider Get-MgDirectoryRoleMember -MockWith {}
        function Get-MgUser {}
        Mock -ModuleName ExportAADProvider Get-MgUser -MockWith {}
        function Get-MgGroupMember {}
        Mock -ModuleName ExportAADProvider Get-MgGroupMember -MockWith {}
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