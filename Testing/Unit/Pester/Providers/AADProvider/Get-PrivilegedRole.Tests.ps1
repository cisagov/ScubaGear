Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportAADProvider.psm1 -Function "Get-PrivilegedRole" -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        function Get-MgOrganization {}
        Mock -ModuleName ExportAADProvider Get-MgOrganization -MockWith {
            return [pscustomobject]@{
                DisplayName = "DisplayName";
                Name = "DomainName";
                Id = "TenantId";
            }
        }
    }
    Describe -Tag 'AADProvider' -Name "Get-PrivilegedRole" {
        It "With no premimum license, returns a not null PowerShell object" {
            {Get-PrivilegedRole} | Should -Not -BeNullOrEmpty
        }
        It "With premimum license, returns a not null PowerShell object" {
            {Get-PrivilegedRole -TenantHasPremiumLicense} | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}