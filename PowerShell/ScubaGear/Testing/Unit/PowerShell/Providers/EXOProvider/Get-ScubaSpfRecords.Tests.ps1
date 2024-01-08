$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") -Function 'Get-ScubaSpfRecords' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Get-ScubaSpfRecords" {
        It "TODO return SPF records" {
            # Get-ScubaSpfRecords
            $true | Should -Be $true
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}