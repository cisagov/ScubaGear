Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../PowerShell/ScubaGear/Modules/RunRego') -Force

InModuleScope 'RunRego' {
    Describe -Tag 'RunRego' -Name 'Invoke-Rego' {
        BeforeAll {
            #Mock -ModuleName RunRego Invoke-ExternalCmd -ParameterFilter { $LiteranlPath -contains 'opa_windows_amd64.exe'} -MockWith { '[]'}
            $DummyTestResults = @"
            [
                {
                    "RequirementMet":  false
                }
            ]
"@
            Mock -ModuleName RunRego Invoke-ExternalCmd -MockWith { return $DummyTestResults}

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
        It "Runs the <ProductName> Rego on a Provider JSON and returns a TestResults object" -ForEach @(
            @{ProductName = 'aad'},
            @{ProductName = 'defender'},
            @{ProductName = 'exo'},
            @{ProductName = 'powerplatform'},
            @{ProductName = 'sharepoint'},
            @{ProductName = 'teams'}
        ){
            $RegoParams += @{
                'RegoFile'    = Join-Path -Path $PSScriptRoot -ChildPath "../../../../Rego/$($ArgToProd[$ProductName])Config.rego";
                'PackageName' = $ProductName;
            }
            $TestResults = Invoke-Rego @RegoParams
            $TestResults[0].RequirementMet | Should -BeExactly $false
        }
    }
}

AfterAll {
    Remove-Module RunRego -ErrorAction SilentlyContinue
}