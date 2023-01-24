BeforeAll {
    Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportSharePointProvider.psm1
}

Describe "Export-SharePointProvider" {
    It "return JSON" {
        InModuleScope ExportSharePointProvider {
            $json = Export-SharePointProvider -M365Environment "gcc"
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