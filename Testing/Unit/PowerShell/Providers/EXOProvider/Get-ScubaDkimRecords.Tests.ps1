$ProviderPath = "../../../../../PowerShell/ScubaGear/Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") -Function Get-ScubaDkimRecords -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Get-ScubaDkimRecords" {
        It "TODO handles a domain with DKIM" {
            # Get-ScubaDkimRecords
            $true | Should -Be $true
        }

        It "TODO handles a domain without DKIM" {
            # Get-ScubaDkimRecords
            $true | Should -Be $true

        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}