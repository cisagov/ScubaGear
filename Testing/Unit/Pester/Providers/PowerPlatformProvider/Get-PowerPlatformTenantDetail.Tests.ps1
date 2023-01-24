BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Providers/ExportPowerPlatformProvider.psm1
}

Describe "Get-PowerPlatformTenantDetail" {
    It "return JSON" {
        InModuleScope ExportPowerPlatformProvider {
            $json = Get-PowerPlatformTenantDetail -M365Environment "gcc"
            $ValidJson = $true
            try {
                ConvertFrom-Json $json -ErrorAction Stop;
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson| Should -Be $true
        }
    }
}
