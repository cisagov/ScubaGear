BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
}

Describe 'Invoke-Scuba' {
    InModuleScope Orchestrator {
        It 'Invoke-Scuba: given the product name will validate configuration' {
            #Invoke-Scuba -Login $True -ProductNames @("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedirve") -Endpoint "usgov" -OPAPath "./" -OutPath output #just make sure that this runs completely there isnt really much to test
            $ProductNames = @("teams")
            $M365Environment = "gcc"
            $OPAPath = "../../../../"
            $OutPath = "output"
            Invoke-Scuba -Login $True -ProductNames $ProductNames -M365Environment $M365Environment -OPAPath $OPAPath -OutPath $OutPath #just make sure that this runs completely there isnt really much to test
            $LASTEXITCODE | Should -Be 0
        }
    }
}