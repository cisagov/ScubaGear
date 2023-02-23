Import-Module ../../../../PowerShell/ScubaGear/Modules/RunRego

Describe 'Invoke-Rego' {
    It 'Runs OPA on Teams rego and returns Test results object' {
        $RegoParams = @{
            'InputFile' = "./RunRegoStubs/ProviderSettingsExport.json";
            'RegoFile' = "../../../../Rego/TeamsConfig.rego";
            'PackageName' = "teams";
            'OPAPath' = "../../../../";
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
}

AfterAll {
    Remove-Module RunRego
}