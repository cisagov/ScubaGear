$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportENTRAIDProvider.psm1") -Function 'Get-PrivilegedRole' -Force

InModuleScope ExportENTRAIDProvider {
    BeforeAll {
        Mock -ModuleName ExportENTRAIDProvider Get-MgBetaDirectoryRoleTemplate -MockWith {}
        Mock -ModuleName ExportENTRAIDProvider Get-MgBetaPolicyRoleManagementPolicyAssignment -MockWith {}
        Mock -ModuleName ExportENTRAIDProvider Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance -MockWith {}
        Mock -ModuleName ExportENTRAIDProvider Get-MgBetaPolicyRoleManagementPolicyRule -MockWith {}
    }
    Describe -Tag 'ENTRAIDProvider' -Name "Get-PrivilegedRole" {
        It "With no premimum license, returns a not null PowerShell object" {
            {Get-PrivilegedRole} | Should -Not -BeNullOrEmpty
        }
        It "With premimum license, returns a not null PowerShell object" {
            {Get-PrivilegedRole -TenantHasPremiumLicense} | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module ExportENTRAIDProvider -Force -ErrorAction SilentlyContinue
}