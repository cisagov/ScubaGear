Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../PowerShell/ScubaGear/Modules/RunRego')

InModuleScope 'RunRego' {
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
                'InputFile' = Join-Path -Path $PSScriptRoot -ChildPath "./RunRegoStubs/ProviderSettingsExport.json";
                'OPAPath'   = Join-Path -Path $PSScriptRoot -ChildPath "../../../../";
            }
        }
        It 'Runs the AAD Rego on a Provider JSON and returns a TestResults object' {
            $Product = 'aad'
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($ArgToProd[$Product])Config.rego";
                'PackageName' = $Product;
            }
            Invoke-Rego @RegoParams | Should -Not -Be $null
        }
        It 'Runs the Defender Rego on a Provider JSON and returns a TestResults object' {
            $Product = 'defender'
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($ArgToProd[$Product])Config.rego";
                'PackageName' = $Product;
            }
            Invoke-Rego @RegoParams | Should -Not -Be $null
        }
        It 'Runs the EXO Rego on a Provider JSON and returns a TestResults object' {
            $Product = 'exo'
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($ArgToProd[$Product])Config.rego";
                'PackageName' = $Product;
            }
            Invoke-Rego @RegoParams | Should -Not -Be $null
        }
        It 'Runs the PowerPlatform Rego on a Provider JSON and returns a TestResults object' {
            $Product = 'powerplatform'
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($ArgToProd[$Product])Config.rego";
                'PackageName' = $Product;
            }
            Invoke-Rego @RegoParams | Should -Not -Be $null
        }
        It 'Runs the SharePoint Rego on a Provider JSON and returns a TestResults object' {
            $Product = 'sharepoint'
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($ArgToProd[$Product])Config.rego";
                'PackageName' = $Product;
            }
            Invoke-Rego @RegoParams | Should -Not -Be $null
        }
        It 'Runs the Teams Rego on a Provider JSON and returns a TestResults object' {
            $Product = 'teams'
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($ArgToProd[$Product])Config.rego";
                'PackageName' = $Product;
            }
            Invoke-Rego @RegoParams | Should -Not -Be $null
        }
    }
}

AfterAll {
    Remove-Module RunRego -ErrorAction SilentlyContinue
}