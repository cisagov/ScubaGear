$ProviderPath = '../../../../../PowerShell/ScubaGear/Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-PrivilegedRole' -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        function Get-MgDirectoryRoleTemplate {}
        Mock -ModuleName ExportAADProvider Get-MgDirectoryRoleTemplate -MockWith {}
        function Get-MgPolicyRoleManagementPolicyAssignment {}
        Mock -ModuleName ExportAADProvider Get-MgPolicyRoleManagementPolicyAssignment -MockWith {}
        function Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance {}
        Mock -ModuleName ExportAADProvider Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -MockWith {}
        function Get-MgPolicyRoleManagementPolicyRule {}
        Mock -ModuleName ExportAADProvider Get-MgPolicyRoleManagementPolicyRule -MockWith {}
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