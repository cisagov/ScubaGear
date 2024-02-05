$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-PrivilegedRole' -Force

InModuleScope ExportAADProvider {
    BeforeAll {
        function Get-MgBetaDirectoryRoleTemplate {throw 'this will be mocked'}
        Mock -ModuleName ExportAADProvider Get-MgBetaDirectoryRoleTemplate {}
        function Get-MgBetaPolicyRoleManagementPolicyAssignment {throw 'this will be mocked'}
        Mock -ModuleName ExportAADProvider Get-MgBetaPolicyRoleManagementPolicyAssignment {}
        function Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance {throw 'this will be mocked'}
        Mock -ModuleName ExportAADProvider Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance {}
        function Get-MgBetaPolicyRoleManagementPolicyRule {throw 'this will be mocked'}
        Mock -ModuleName ExportAADProvider Get-MgBetaPolicyRoleManagementPolicyRule {}
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