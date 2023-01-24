BeforeAll {
    Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportTeamsProvider.psm1
    Connect-MicrosoftTeams
}

Describe "Export-TeamsProvider" {
    It "return JSON" {
        InModuleScope ExportTeamsProvider {
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
            $ValidJson| Should -Be $true
        }
    }
}
