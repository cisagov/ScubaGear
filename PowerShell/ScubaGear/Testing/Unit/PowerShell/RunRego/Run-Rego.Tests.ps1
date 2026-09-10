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
            $OpaName = if ($Env:OS -eq "Windows_NT") { "opa_windows_amd64.exe" } else { "opa" }
            Set-Content -LiteralPath (Join-Path $TestDrive $OpaName) -Value "test stub"
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'RegoParams')]
            $RegoParams = @{
                'InputFile' = Join-Path -Path $PSScriptRoot -ChildPath "./RunRegoStubs/ProviderSettingsExport.json";
            }
        }
        It 'Runs the <Arg> Rego on a Provider JSON and returns a Rego output object' {
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($Arg)Config.rego";
                'PackageName' = $Product;
                'OPAPath'   = $TestDrive;
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
            $OpaName = if ($Env:OS -eq "Windows_NT") { "opa_windows_amd64.exe" } else { "opa" }
            Set-Content -LiteralPath (Join-Path $TestDrive $OpaName) -Value "test stub"
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
                'OPAPath'     = $TestDrive
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
InModuleScope 'RunRego' {
    Describe -Tag 'RunRego' -Name 'Invoke-Rego native filesystem paths' {
        BeforeAll {
            $NativeDirectory = Join-Path $TestDrive 'cached reports [test]'
            New-Item -ItemType Directory -Path $NativeDirectory | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $NativeDirectory 'Utils') | Out-Null
            Set-Content -LiteralPath (Join-Path $NativeDirectory 'input.json') -Value '{}'
            Set-Content -LiteralPath (Join-Path $NativeDirectory 'test.rego') -Value 'package test'
            $NativeOpaName = if ($Env:OS -eq 'Windows_NT') { 'opa_windows_amd64.exe' } else { 'opa' }
            Set-Content -LiteralPath (Join-Path $NativeDirectory $NativeOpaName) -Value 'test stub'
            New-PSDrive -Name ScubaCache -PSProvider FileSystem -Root $NativeDirectory | Out-Null
        }
        AfterAll {
            Remove-PSDrive -Name ScubaCache
        }
        BeforeEach {
            Mock Invoke-ExternalCmd { '[[{"result":true}]]' }
        }
        It 'Resolves a relative executable against the PowerShell working directory' {
            Push-Location -LiteralPath $NativeDirectory
            try {
                Invoke-Rego -OPAPath '.' -InputFile './input.json' -RegoFile './test.rego' -PackageName test
                Should -Invoke Invoke-ExternalCmd -Times 1 -Exactly -ParameterFilter {
                    $LiteralPath -eq (Join-Path $NativeDirectory $NativeOpaName)
                }
            }
            finally { Pop-Location }
        }
        It 'Converts PSDrive paths into native paths for OPA and all input files' {
            Invoke-Rego -OPAPath 'ScubaCache:/' -InputFile 'ScubaCache:/input.json' -RegoFile 'ScubaCache:/test.rego' -PackageName test
            Should -Invoke Invoke-ExternalCmd -Times 1 -Exactly -ParameterFilter {
                $LiteralPath -eq (Join-Path $NativeDirectory $NativeOpaName) -and
                $PassThruArgs[3] -eq (Join-Path $NativeDirectory 'input.json') -and
                $PassThruArgs[5] -eq (Join-Path $NativeDirectory 'test.rego') -and
                $PassThruArgs[7] -eq (Join-Path $NativeDirectory 'Utils')
            }
        }
        It 'Resolves the current-directory fallback on a PSDrive' {
            Push-Location ScubaCache:/
            try {
                Invoke-Rego -OPAPath (Join-Path $TestDrive 'missing') -InputFile './input.json' -RegoFile './test.rego' -PackageName test
                Should -Invoke Invoke-ExternalCmd -Times 1 -Exactly -ParameterFilter {
                    $LiteralPath -eq (Join-Path $NativeDirectory $NativeOpaName)
                }
            }
            finally { Pop-Location }
        }
    }
}
