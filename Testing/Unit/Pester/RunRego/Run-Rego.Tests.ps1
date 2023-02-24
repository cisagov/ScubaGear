Import-Module ../../../../PowerShell/ScubaGear/Modules/RunRego

Describe -Tag 'RunRego' -Name 'Invoke-Rego' {
    BeforeAll {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ArgToProd')]
        $ArgToProd = @{
            teams         = "Teams";
            exo           = "EXO";
            defender      = "Defender";
            aad           = "AAD";
            powerplatform = "PowerPlatform";
            sharepoint    = "SharePoint";
            onedrive      = "OneDrive";
        }
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'RegoParams')]
        $RegoParams = @{
            'InputFile' = "./RunRegoStubs/ProviderSettingsExport.json";
            'OPAPath'   = "../../../../";
        }
    }
    It 'Runs the AAD Rego on a Provider JSON and returns a TestResults object' {
        $Product = 'aad'
        $RegoParams += @{
            'RegoFile'    = "../../../../Rego/$($ArgToProd[$Product])Config.rego";
            'PackageName' = $Product;
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the Defender Rego on a Provider JSON and returns a TestResults object' {
        $Product = 'defender'
        $RegoParams += @{
            'RegoFile'    = "../../../../Rego/$($ArgToProd[$Product])Config.rego";
            'PackageName' = $Product;
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the EXO Rego on a Provider JSON and returns a TestResults object' {
        $Product = 'exo'
        $RegoParams += @{
            'RegoFile'    = "../../../../Rego/$($ArgToProd[$Product])Config.rego";
            'PackageName' = $Product;
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the OneDrive Rego on a Provider JSON and returns a TestResults object' {
        $Product = 'onedrive'
        $RegoParams += @{
            'RegoFile'    = "../../../../Rego/$($ArgToProd[$Product])Config.rego";
            'PackageName' = $Product;
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the PowerPlatform Rego on a Provider JSON and returns a TestResults object' {
        $Product = 'powerplatform'
        $RegoParams += @{
            'RegoFile'    = "../../../../Rego/$($ArgToProd[$Product])Config.rego";
            'PackageName' = $Product;
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the SharePoint Rego on a Provider JSON and returns a TestResults object' {
        $Product = 'sharepoint'
        $RegoParams += @{
            'RegoFile'    = "../../../../Rego/$($ArgToProd[$Product])Config.rego";
            'PackageName' = $Product;
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
    It 'Runs the Teams Rego on a Provider JSON and returns a TestResults object' {
        $Product = 'teams'
        $RegoParams += @{
            'RegoFile'    = "../../../../Rego/$($ArgToProd[$Product])Config.rego";
            'PackageName' = $Product;
        }
        Invoke-Rego @RegoParams | Should -Not -Be $null
    }
}

AfterAll {
    Remove-Module RunRego -ErrorAction SilentlyContinue
}