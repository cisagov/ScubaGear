BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Providers/ExportTeamsProvider.psm1
}

Describe 'Get-TenantDetail' {
    InModuleScope Orchestrator {
        It 'Get-TenantDetail' {
            $ProductNames = @("teams")
            $M365Environment = "gcc"
            $output = Get-TenantDetail -ProductNames $ProductNames -M365Environment $M365Environment
            $ValidJson = $true
            try {
                ConvertFrom-Json $output -ErrorAction Stop;
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson| Should -Be $true
        }
    }
}