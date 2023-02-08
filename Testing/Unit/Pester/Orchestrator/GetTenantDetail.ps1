BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
}

Describe 'GetTenantDetail' {
    InModuleScope Orchestrator {
        It 'GetTenantDetail' {
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