$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportENTRAIDProvider.psm1") -Function 'Get-PrivilegedUser' -Force

InModuleScope ExportENTRAIDProvider {
    BeforeAll {
        Mock -ModuleName ExportENTRAIDProvider Get-PrivilegedUser -MockWith {}
        Mock -ModuleName ExportENTRAIDProvider Get-MgBetaDirectoryRoleMember -MockWith {}
        Mock -ModuleName ExportENTRAIDProvider Get-MgBetaUser -MockWith {}
        Mock -ModuleName ExportENTRAIDProvider Get-MgBetaGroupMember -MockWith {}
    }
    Describe -Tag 'ENTRAIDProvider' -Name "Get-PrivilegedUser" {
        It "With no premimum license, returns a not null PowerShell object" {
            {Get-PrivilegedUser} | Should -Not -BeNullOrEmpty
        }
        It "With premimum license, returns a not null PowerShell object" {
            {Get-PrivilegedUser -TenantHasPremiumLicense} | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module ExportENTRAIDProvider -Force -ErrorAction SilentlyContinue
}