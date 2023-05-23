$ProviderPath = "../../../../../PowerShell/ScubaGear/Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") -Function Get-ScubaDmarcRecords -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Get-ScubaDmarcRecords" {
        It "TODO return DMARC records" {
            # Get-ScubaDmarcRecords
            $true | Should -Be $true
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}