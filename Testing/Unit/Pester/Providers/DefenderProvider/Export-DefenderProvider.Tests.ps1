BeforeAll {
    Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportDefenderProvider.psm1
    Connect-ExchangeOnline
    Connect-IPPSSession
}

Describe "Export-DefenderProvider" {
    It "return JSON" {
        InModuleScope ExportDefenderProvider {
            $Json = Export-DefenderProvider -M365Environment "gcc"
            $Json = $Json.TrimEnd(",")
            $Json = "{$($Json)}"
            $ValidJson = $true
            try {
                ConvertFrom-Json $Json -ErrorAction Stop
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson| Should -Be $true
        }
    }
}