Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/RunRego')

InModuleScope 'RunRego' {
    Describe -Tag 'RunRego' -Name 'Invoke-Rego' -ForEach @(
        @{Product = 'entraid'; Arg = 'ENTRAID'},
        @{Product = 'defender'; Arg = 'Defender'},
        @{Product = 'exo'; Arg = 'EXO'},
        @{Product = 'powerplatform'; Arg = 'PowerPlatform'},
        @{Product = 'sharepoint'; Arg = 'SharePoint'},
        @{Product = 'teams'; Arg = 'Teams'}
    ){
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'RegoParams')]
            $RegoParams = @{
                'InputFile' = Join-Path -Path $PSScriptRoot -ChildPath "./RunRegoStubs/ProviderSettingsExport.json";
                'OPAPath'   = Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear/Tools";
            }
        }
        It 'Runs the <Arg> Rego on a Provider JSON and returns a TestResults object' {
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($Arg)Config.rego";
                'PackageName' = $Product;
            }
            Invoke-Rego @RegoParams | Should -Not -Be $null
        }
    }
}

AfterAll {
    Remove-Module RunRego -ErrorAction SilentlyContinue
}