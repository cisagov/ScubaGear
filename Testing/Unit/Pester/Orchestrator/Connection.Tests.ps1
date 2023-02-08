BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
}

Describe 'Invoke-Connection' {
    InModuleScope Orchestrator {
        It 'Invoke-Connection' {
            $ProductNames = @("teams")
            $LogIn = $true
            $M365Environment = "gcc"
            Invoke-Connection -LogIn $LogIn -ProductNames $ProductNames -M365Environment $M365Environment
            $LASTEXITCODE | Should -Be 0
        }
    }
}