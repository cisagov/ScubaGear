BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Providers/ExportPowerPlatformProvider.psm1  
}

Describe "Export-PowerPlatformProvider" {
    It "return JSON" {
        InModuleScope ExportPowerPlatformProvider {
            $json = Export-PowerPlatformProvider
            $json = $json.TrimEnd(",")
            $json = "{$($json)}"
            $ValidJson = $true
            try {
                ConvertFrom-Json $json -ErrorAction Stop
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson| Should -Be $true
        }
    }
}
