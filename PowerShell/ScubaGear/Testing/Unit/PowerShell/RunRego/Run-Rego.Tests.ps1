Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/RunRego')

InModuleScope 'RunRego' {
    Describe -Tag 'RunRego' -Name 'Invoke-Rego Success' -ForEach @(
        @{Product = 'aad'; Arg = 'AAD'},
        @{Product = 'securitysuite'; Arg = 'SecuritySuite'},
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
        It 'Runs the <Arg> Rego on a Provider JSON and returns a Rego output object' {
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

    Describe -Tag 'RunRego' -Name 'Invoke-Rego wildcard path handling' {
        BeforeAll {
            Mock -ModuleName RunRego Invoke-ExternalCmd { return 0 }
            Mock -CommandName Test-Path { $true }
        }
        It 'Passes an InputFile path containing square brackets ([]) to OPA literally' {
            # Real bracketed input file so Resolve-Path must handle [] literally (wildcard -Path would resolve to $null)
            $BracketDir = Join-Path $TestDrive '2185test[test]\lab'
            [void][System.IO.Directory]::CreateDirectory($BracketDir)
            $BracketInput = Join-Path $BracketDir 'ProviderSettingsExport.json'
            Copy-Item -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath './RunRegoStubs/ProviderSettingsExport.json') -Destination $BracketInput
            $RegoParams = @{
                'InputFile'   = $BracketInput
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Rego/AADConfig.rego'
                'PackageName' = 'aad'
                'OPAPath'     = Join-Path -Path $env:USERPROFILE -ChildPath '.scubagear/Tools'
            }
            { Invoke-Rego @RegoParams } | Should -Not -Throw
            # The resolved bracketed input path must appear in the OPA arguments (regex-escaped brackets)
            Should -Invoke -ModuleName RunRego -CommandName Invoke-ExternalCmd -ParameterFilter {
                ($PassThruArgs -join '|') -match '2185test\[test\]'
            }
        }
    }
}

AfterAll {
    Remove-Module RunRego -ErrorAction SilentlyContinue
}