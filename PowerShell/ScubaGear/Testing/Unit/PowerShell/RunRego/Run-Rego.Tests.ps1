Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/RunRego')

InModuleScope 'RunRego' {
    Describe -Tag 'RunRego' -Name 'Invoke-Rego Success' -ForEach @(
        @{Product = 'aad'; Arg = 'AAD'},
        @{Product = 'defender'; Arg = 'Defender'},
        @{Product = 'exo'; Arg = 'EXO'},
        @{Product = 'powerplatform'; Arg = 'PowerPlatform'},
        @{Product = 'sharepoint'; Arg = 'SharePoint'},
        @{Product = 'teams'; Arg = 'Teams'}
    ){
        BeforeAll {
            Mock -ModuleName RunRego Invoke-ExternalCmd {return 0}
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'RegoParams')]
            $RegoParams = @{
                'InputFile' = Join-Path -Path $PSScriptRoot -ChildPath "./RunRegoStubs/ProviderSettingsExport.json";
            }
        }
        It 'Runs the <Arg> Rego on a Provider JSON and returns a TestResults object' {
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($Arg)Config.rego";
                'PackageName' = $Product;
                'OPAPath'   = Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear/Tools";
            }
            Mock -CommandName Test-Path {$true}
            Invoke-Rego @RegoParams | Should -Not -Be $null
        }
        It 'Runs the <Arg> Rego on a Provider JSON and fails due to missing OPA executable' {
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($Arg)Config.rego";
                'PackageName' = $Product;
                'OPAPath'   = 'DoesNotExist'
            }
            {Invoke-Rego @RegoParams} | Should -Throw
        }
    }
}

AfterAll {
    Remove-Module RunRego -ErrorAction SilentlyContinue
}