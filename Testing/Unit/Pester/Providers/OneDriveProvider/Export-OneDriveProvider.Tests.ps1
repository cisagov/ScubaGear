BeforeAll {
    Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportOneDriveProvider.psm1
}

Describe "Export-OneDriveProvider" {
    It "return JSON" {
        InModuleScope ExportOneDriveProvider {
            $json = Export-OneDriveProvider -M365Environment "gcc"
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