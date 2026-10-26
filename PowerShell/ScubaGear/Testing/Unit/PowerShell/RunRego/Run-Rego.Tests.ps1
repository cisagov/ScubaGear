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

    Describe -Tag 'RunRego' -Name 'Invoke-Rego native path handling' {
        BeforeAll {
            Mock -ModuleName RunRego Invoke-ExternalCmd { return 0 }
        }
        It 'Resolves a FileSystem PSDrive and relative paths to native paths before invoking OPA' {
            # A native process cannot launch a PSDrive-qualified or working-directory-relative
            # path, so Invoke-Rego must hand OPA native filesystem paths. Build a self-contained
            # tree (note the space in the folder name), map a FileSystem PSDrive onto it, and run
            # from that drive with relative paths.
            $Root  = Join-Path $TestDrive 'opa root'
            $Utils = Join-Path $Root 'Utils'
            [void][System.IO.Directory]::CreateDirectory($Utils)
            $OpaName = if ("Windows_NT" -eq $Env:OS) { 'opa_windows_amd64.exe' } else { 'opa' }
            Set-Content -LiteralPath (Join-Path $Root $OpaName) -Value 'stub'
            Set-Content -LiteralPath (Join-Path $Root 'input.json') -Value '{}'
            Set-Content -LiteralPath (Join-Path $Root 'Policy.rego') -Value "package aad.tests`n"
            Set-Content -LiteralPath (Join-Path $Utils 'util.rego') -Value "package utils`n"

            New-PSDrive -Name ScubaRunRegoTest -PSProvider FileSystem -Root $Root -Scope Global | Out-Null
            try {
                Push-Location ScubaRunRegoTest:
                try {
                    Invoke-Rego -InputFile './input.json' -RegoFile './Policy.rego' -PackageName 'aad' -OPAPath '.' | Out-Null
                }
                finally { Pop-Location }
            }
            finally { Remove-PSDrive -Name ScubaRunRegoTest -ErrorAction SilentlyContinue }

            # The executable and every path argument reach OPA as native paths, never carrying
            # the PSDrive qualifier that OPA cannot resolve.
            Should -Invoke -ModuleName RunRego -CommandName Invoke-ExternalCmd -Times 1 -Exactly -ParameterFilter {
                ($LiteralPath -eq (Join-Path $Root $OpaName)) -and
                ($LiteralPath -notmatch 'ScubaRunRegoTest:') -and
                (-not (($PassThruArgs -join '|') -match 'ScubaRunRegoTest:')) -and
                (($PassThruArgs -join '|') -match ([regex]::Escape((Join-Path $Root 'input.json'))))
            }
        }
    }

}

AfterAll {
    Remove-Module RunRego -ErrorAction SilentlyContinue
}