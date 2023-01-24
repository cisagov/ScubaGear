BeforeAll {
    Import-Module ../../../../../PowerShell/ScubaGear/Modules/Providers/ExportTeamsProvider.psm1
    Connect-MicrosoftTeams
}
Describe "Get-TeamsTenantDetail" {
    It "return JSON" {
        InModuleScope ExportTeamsProvider {
            $Json = Get-TeamsTenantDetail -M365Environment "gcc"
            $ValidJson = $true
            try {
                ConvertFrom-Json $Json -ErrorAction Stop;
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson| Should -Be $true
        }
    }
}
