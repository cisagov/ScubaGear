Import-Module ../../../../PowerShell/ScubaGear/Modules/RunRego

Describe 'Invoke-Rego' {
    It 'Runs the AAD Rego on a Provider JSON and returns a TestResults object' {
        $RegoParams = @{
            'InputFile' = "./RunRegoStubs/ProviderSettingsExport.json";
            'RegoFile' = "../../../../Rego/AADConfig.rego";
            'PackageName' = "aad";
            'OPAPath' = "../../../../";
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the EXO Rego on a Provider JSON and returns a TestResults object' {
        $RegoParams = @{
            'InputFile' = "./RunRegoStubs/ProviderSettingsExport.json";
            'RegoFile' = "../../../../Rego/EXOConfig.rego";
            'PackageName' = "exo";
            'OPAPath' = "../../../../";
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the Defender Rego on a Provider JSON and returns a TestResults object' {
        $RegoParams = @{
            'InputFile' = "./RunRegoStubs/ProviderSettingsExport.json";
            'RegoFile' = "../../../../Rego/DefenderConfig.rego";
            'PackageName' = "defender";
            'OPAPath' = "../../../../";
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the OneDrive Rego on a Provider JSON and returns a TestResults object' {
        $RegoParams = @{
            'InputFile' = "./RunRegoStubs/ProviderSettingsExport.json";
            'RegoFile' = "../../../../Rego/OneDriveConfig.rego";
            'PackageName' = "onedrive";
            'OPAPath' = "../../../../";
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the PowerPlatform Rego on a Provider JSON and returns a TestResults object' {
        $RegoParams = @{
            'InputFile' = "./RunRegoStubs/ProviderSettingsExport.json";
            'RegoFile' = "../../../../Rego/PowerPlatformConfig.rego";
            'PackageName' = "powerplatform";
            'OPAPath' = "../../../../";
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the SharePoint Rego on a Provider JSON and returns a TestResults object' {
        $RegoParams = @{
            'InputFile' = "./RunRegoStubs/ProviderSettingsExport.json";
            'RegoFile' = "../../../../Rego/SharepointConfig.rego";
            'PackageName' = "sharepoint";
            'OPAPath' = "../../../../";
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the Teams Rego on a Provider JSON and returns a TestResults object' {
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
    Remove-Module RunRego -ErrorAction SilentlyContinue
}