$ProviderPath = '../../../../../PowerShell/ScubaGear/Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-PrivilegedRole' -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        Mock -ModuleName ExportAADProvider Get-MgBetaDirectoryRoleTemplate -MockWith {}
        Mock -ModuleName ExportAADProvider Get-MgBetaPolicyRoleManagementPolicyAssignment -MockWith {}
        Mock -ModuleName ExportAADProvider Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance -MockWith {}
        Mock -ModuleName ExportAADProvider Get-MgBetaPolicyRoleManagementPolicyRule -MockWith {}
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