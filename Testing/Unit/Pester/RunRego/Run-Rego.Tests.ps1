BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/RunRego
}

Describe 'Invoke-Rego' {
    It 'Takes 4 parameters and returns test results based on json and rego file' {
        $RegoParams = @{
            'InputFile' = "./ProviderSettingsExport.json";
            'RegoFile' = "../Rego/TeamsConfig.rego";
            'PackageName' = "teams";
            'OPAPath' = "../";
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
}

