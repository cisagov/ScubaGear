using module '..\..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe -Tag 'TeamsRestHelper' -Name 'M365Environment validation' {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../../Modules/Utility/Utility.psm1') -Force
        $HelperPath = '../../../../../Modules/Providers/ProviderHelpers/TeamsRestHelper.psm1'
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Force

        # Utility still validates Environment with its own ValidateSet; strip it so these tests exercise only TeamsRestHelper.
        Mock -ModuleName TeamsRestHelper Get-ScubaGearOAuthScope { 'https://teams.scope.test/.default' } -RemoveParameterValidation Environment
        Mock -ModuleName TeamsRestHelper Get-ScubaGearServiceEndpoint { 'https://teams.endpoint.test' } -RemoveParameterValidation Environment
    }

    Context 'Rejects unsupported environments before any downstream call' {
        It '<Name> rejects <Environment>' -ForEach @(
            @{ Name = 'Get-TeamsScope'; Environment = 'not-an-env' }
            @{ Name = 'Get-TeamsBaseUrl'; Environment = 'not-an-env' }
            @{ Name = 'Get-TeamsUnifiedScope'; Environment = 'not-an-env' }
            @{ Name = 'Get-TeamsUnifiedBaseUrl'; Environment = 'not-an-env' }
            @{ Name = 'Get-TeamsScope'; Environment = '' }
            @{ Name = 'Get-TeamsUnifiedBaseUrl'; Environment = '' }
        ) {
            { & $Name -M365Environment $Environment } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
            Should -Invoke -ModuleName TeamsRestHelper Get-ScubaGearOAuthScope -Times 0 -Exactly
            Should -Invoke -ModuleName TeamsRestHelper Get-ScubaGearServiceEndpoint -Times 0 -Exactly
        }
    }

    Context 'Accepts every schema environment' {
        It 'Accepts <_> for all four helpers' -ForEach @([ScubaConfig]::GetSupportedEnvironments()) {
            Get-TeamsScope -M365Environment $_ | Should -Be 'https://teams.scope.test/.default'
            Get-TeamsBaseUrl -M365Environment $_ | Should -Be 'https://teams.endpoint.test'
            Get-TeamsUnifiedScope -M365Environment $_ | Should -Be 'https://teams.scope.test/.default'
            Get-TeamsUnifiedBaseUrl -M365Environment $_ | Should -Be 'https://teams.endpoint.test'
        }

        It 'Keeps environment matching case-insensitive' {
            Get-TeamsScope -M365Environment 'Commercial' | Should -Be 'https://teams.scope.test/.default'
            Get-TeamsUnifiedBaseUrl -M365Environment 'GCCHIGH' | Should -Be 'https://teams.endpoint.test'
        }
    }

    Context 'Reads supported environments from the schema at call time' {
        It 'Accepts an environment added to the schema in memory and rejects it after restore' {
            # PowerShell caches the parsed helper, so when other test files reload ScubaConfig in the same session,
            # the ValidateScript can bind to an older [ScubaConfig] type than this file or the module scope sees.
            # Mutate the schema of the exact type each ValidateScript resolves.
            $ValidatorTypes = @('Get-TeamsScope', 'Get-TeamsUnifiedBaseUrl') | ForEach-Object {
                $Attribute = (Get-Command $_).Parameters['M365Environment'].Attributes |
                    Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] }
                $Attribute.ScriptBlock.Ast.Find({
                    param($Node) $Node -is [System.Management.Automation.Language.TypeExpressionAst]
                }, $true).TypeName.GetReflectionType()
            } | Select-Object -Unique
            $Schemas = @($ValidatorTypes | ForEach-Object { $_::GetConfigSchema() })
            $OriginalEnvironments = @($Schemas | ForEach-Object { , $_.properties.M365Environment.enum })
            try {
                for ($i = 0; $i -lt $Schemas.Count; $i++) {
                    $Schemas[$i].properties.M365Environment.enum = @($OriginalEnvironments[$i]) + 'testcloud'
                }
                Get-TeamsScope -M365Environment 'testcloud' | Should -Be 'https://teams.scope.test/.default'
                Get-TeamsUnifiedBaseUrl -M365Environment 'testcloud' | Should -Be 'https://teams.endpoint.test'
            }
            finally {
                for ($i = 0; $i -lt $Schemas.Count; $i++) {
                    $Schemas[$i].properties.M365Environment.enum = $OriginalEnvironments[$i]
                }
            }

            $ValidatorTypes | ForEach-Object { $_::GetSupportedEnvironments() | Should -Not -Contain 'testcloud' }
            { Get-TeamsScope -M365Environment 'testcloud' } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
            { Get-TeamsUnifiedBaseUrl -M365Environment 'testcloud' } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }
    }
}

AfterAll {
    Remove-Module TeamsRestHelper -Force -ErrorAction SilentlyContinue
    Remove-Module Utility -Force -ErrorAction SilentlyContinue
}
