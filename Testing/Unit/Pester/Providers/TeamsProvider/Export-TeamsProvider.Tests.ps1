Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportTeamsProvider.psms1

InModuleScope ExportTeamsProvider {
    Describe "Export-TeamsProvider" {
        It "return JSON" {
            $json = Export-TeamsProvider -M365Environment "gcc"
            $json = $json.TrimEnd(",")
            $json = "{$($json)}"
            $ValidJson = $true
            try {
                ConvertFrom-Json $json -ErrorAction Stop
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson | Should -Be $true
        }
    }
}
