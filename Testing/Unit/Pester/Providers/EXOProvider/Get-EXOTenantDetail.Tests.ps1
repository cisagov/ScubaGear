BeforeAll {
    Import-Module ../../../../../ScubaGear/Modules/Providers/ExportEXOProvider.psm1
    Import-Module ExchangeOnlineManagement
    Connect-ExchangeOnline
}

Describe "Get-EXOTenantDetail" {
    It "return JSON" {
        InModuleScope ExportEXOProvider {
            $Json = Get-EXOTenantDetail -M365Environment "gcc"
            $ValidJson = $true
            try {
                ConvertFrom-Json $Json -ErrorAction Stop
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson | Should -Be $true
        }
    }
}