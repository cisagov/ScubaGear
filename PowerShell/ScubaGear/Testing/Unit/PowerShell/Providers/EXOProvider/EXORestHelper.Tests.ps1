using module '..\..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe -Tag 'EXORestHelper' -Name 'Invoke-EXORestMethod' {
    BeforeAll {
        # Load Utility first so EXORestHelper reuses this instance and Pester can mock its transport.
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../../Modules/Utility/Utility.psm1') -Force
        $HelperPath = '../../../../../Modules/Providers/ProviderHelpers/EXORestHelper.psm1'
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Force
    }

    It 'Retries a transient connection failure through Invoke-ScubaRestMethod' {
        Mock -ModuleName Utility Start-Sleep {}
        Mock -ModuleName Utility Invoke-RestMethod {
            if ($script:RequestAttempts++ -eq 0) {
                throw 'The underlying connection was closed: A connection that was expected to be kept alive was closed by the server.'
            }

            [pscustomobject]@{
                value = @([pscustomobject]@{ Identity = 'Default' })
            }
        }
        $script:RequestAttempts = 0

        $Result = Invoke-EXORestMethod -CmdletName 'Get-MalwareFilterPolicy' -ApiEndpoint 'https://example.test/InvokeCommand' -AccessToken 'token' -WarningAction SilentlyContinue

        $Result.Identity | Should -Be 'Default'
        Should -Invoke -ModuleName Utility Invoke-RestMethod -Times 2 -Exactly
        Should -Invoke -ModuleName Utility Start-Sleep -Times 1 -Exactly
    }
}

Describe -Tag 'EXORestHelper' -Name 'M365Environment validation' {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../../Modules/Utility/Utility.psm1') -Force
        $HelperPath = '../../../../../Modules/Providers/ProviderHelpers/EXORestHelper.psm1'
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Force

        # Utility still validates Environment with its own ValidateSet; strip it so these tests exercise only EXORestHelper.
        Mock -ModuleName EXORestHelper Get-ScubaGearOAuthScope { 'https://scope.test/.default' } -RemoveParameterValidation Environment
        Mock -ModuleName EXORestHelper Get-ScubaGearServiceEndpoint { 'https://frontdoor.test' } -RemoveParameterValidation Environment
        Mock -ModuleName EXORestHelper Resolve-ScubaFrontDoorEndpoint { 'https://backend.test/InvokeCommand' }

        $script:EndpointParams = @{ TenantId = 'tenant123'; TenantDomain = 'contoso.onmicrosoft.com'; AccessToken = 'tok' }
    }

    Context 'Rejects unsupported environments before any downstream call' {
        It '<Name> rejects <Environment>' -ForEach @(
            @{ Name = 'Get-ExchangeOnlineScope'; Environment = 'not-an-env' }
            @{ Name = 'Get-ComplianceScope'; Environment = 'not-an-env' }
            @{ Name = 'Get-ExchangeOnlineApiEndpoint'; Environment = 'not-an-env' }
            @{ Name = 'Get-ComplianceApiEndpoint'; Environment = 'not-an-env' }
            @{ Name = 'Get-ExchangeOnlineScope'; Environment = '' }
            @{ Name = 'Get-ComplianceApiEndpoint'; Environment = '' }
        ) {
            $Params = @{ M365Environment = $Environment }
            if ($Name -like '*ApiEndpoint') { $Params += $script:EndpointParams }

            { & $Name @Params } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
            Should -Invoke -ModuleName EXORestHelper Get-ScubaGearOAuthScope -Times 0 -Exactly
            Should -Invoke -ModuleName EXORestHelper Get-ScubaGearServiceEndpoint -Times 0 -Exactly
            Should -Invoke -ModuleName EXORestHelper Resolve-ScubaFrontDoorEndpoint -Times 0 -Exactly
        }
    }

    Context 'Accepts every schema environment' {
        It 'Accepts <_> for all four helpers' -ForEach @([ScubaConfig]::GetSupportedEnvironments()) {
            Get-ExchangeOnlineScope -M365Environment $_ | Should -Be 'https://scope.test/.default'
            Get-ComplianceScope -M365Environment $_ | Should -Be 'https://scope.test/.default'
            Get-ExchangeOnlineApiEndpoint @script:EndpointParams -M365Environment $_ | Should -Be 'https://backend.test/InvokeCommand'
            Get-ComplianceApiEndpoint @script:EndpointParams -M365Environment $_ | Should -Be 'https://backend.test/InvokeCommand'
        }

        It 'Keeps environment matching case-insensitive' {
            Get-ExchangeOnlineScope -M365Environment 'Commercial' | Should -Be 'https://scope.test/.default'
            Get-ComplianceApiEndpoint @script:EndpointParams -M365Environment 'GCCHIGH' | Should -Be 'https://backend.test/InvokeCommand'
        }
    }

    Context 'Reads supported environments from the schema at call time' {
        It 'Accepts an environment added to the schema in memory and rejects it after restore' {
            # PowerShell caches the parsed helper, so when other test files reload ScubaConfig in the same session,
            # the ValidateScript can bind to an older [ScubaConfig] type than this file or the module scope sees.
            # Mutate the schema of the exact type each ValidateScript resolves.
            $ValidatorTypes = @('Get-ExchangeOnlineScope', 'Get-ExchangeOnlineApiEndpoint') | ForEach-Object {
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
                Get-ExchangeOnlineScope -M365Environment 'testcloud' | Should -Be 'https://scope.test/.default'
                Get-ExchangeOnlineApiEndpoint @script:EndpointParams -M365Environment 'testcloud' | Should -Be 'https://backend.test/InvokeCommand'
            }
            finally {
                for ($i = 0; $i -lt $Schemas.Count; $i++) {
                    $Schemas[$i].properties.M365Environment.enum = $OriginalEnvironments[$i]
                }
            }

            $ValidatorTypes | ForEach-Object { $_::GetSupportedEnvironments() | Should -Not -Contain 'testcloud' }
            { Get-ExchangeOnlineScope -M365Environment 'testcloud' } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }
    }
}

AfterAll {
    Remove-Module EXORestHelper -Force -ErrorAction SilentlyContinue
    Remove-Module Utility -Force -ErrorAction SilentlyContinue
}
