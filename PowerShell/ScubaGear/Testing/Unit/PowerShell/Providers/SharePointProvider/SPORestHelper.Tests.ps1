using module '..\..\..\..\..\Modules\ScubaConfig\ScubaConfig.psm1'

Describe -Tag 'SPORestHelper' -Name 'M365Environment validation' {
    BeforeAll {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../../Modules/Utility/Utility.psm1') -Force
        $HelperPath = '../../../../../Modules/Providers/ProviderHelpers/SPORestHelper.psm1'
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Force

        # Utility still validates Environment with its own ValidateSet; strip it so these tests exercise only SPORestHelper.
        Mock -ModuleName SPORestHelper Get-ScubaGearOAuthScope { 'https://contoso-admin.sharepoint.com/.default' } -RemoveParameterValidation Environment
        Mock -ModuleName SPORestHelper Get-ScubaGearServiceEndpoint { 'https://contoso-admin.sharepoint.com' } -RemoveParameterValidation Environment

        $script:DomainParams = @{ InitialDomainPrefix = 'contoso' }
    }

    Context 'Rejects unsupported environments before any downstream call' {
        It '<Name> rejects <Environment>' -ForEach @(
            @{ Name = 'Get-SPOScope'; Environment = 'not-an-env' }
            @{ Name = 'Get-SPOAdminUrl'; Environment = 'not-an-env' }
            @{ Name = 'Get-SPOScope'; Environment = '' }
            @{ Name = 'Get-SPOAdminUrl'; Environment = '' }
        ) {
            $Params = @{ M365Environment = $Environment } + $script:DomainParams

            { & $Name @Params } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
            Should -Invoke -ModuleName SPORestHelper Get-ScubaGearOAuthScope -Times 0 -Exactly
            Should -Invoke -ModuleName SPORestHelper Get-ScubaGearServiceEndpoint -Times 0 -Exactly
        }
    }

    Context 'Accepts every schema environment' {
        It 'Accepts <_> for both helpers' -ForEach @([ScubaConfig]::GetSupportedEnvironments()) {
            Get-SPOScope -M365Environment $_ @script:DomainParams | Should -Be 'https://contoso-admin.sharepoint.com/.default'
            Get-SPOAdminUrl -M365Environment $_ @script:DomainParams | Should -Be 'https://contoso-admin.sharepoint.com'
        }

        It 'Keeps environment matching case-insensitive' {
            Get-SPOScope -M365Environment 'Commercial' @script:DomainParams | Should -Be 'https://contoso-admin.sharepoint.com/.default'
            Get-SPOAdminUrl -M365Environment 'GCCHIGH' @script:DomainParams | Should -Be 'https://contoso-admin.sharepoint.com'
        }
    }

    Context 'Reads supported environments from the schema at call time' {
        It 'Accepts an environment added to the schema in memory and rejects it after restore' {
            # PowerShell caches the parsed helper, so when other test files reload ScubaConfig in the same session,
            # the ValidateScript can bind to an older [ScubaConfig] type than this file or the module scope sees.
            # Mutate the schema of the exact type each ValidateScript resolves.
            $ValidatorTypes = @('Get-SPOScope', 'Get-SPOAdminUrl') | ForEach-Object {
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
                Get-SPOScope -M365Environment 'testcloud' @script:DomainParams | Should -Be 'https://contoso-admin.sharepoint.com/.default'
                Get-SPOAdminUrl -M365Environment 'testcloud' @script:DomainParams | Should -Be 'https://contoso-admin.sharepoint.com'
            }
            finally {
                for ($i = 0; $i -lt $Schemas.Count; $i++) {
                    $Schemas[$i].properties.M365Environment.enum = $OriginalEnvironments[$i]
                }
            }

            $ValidatorTypes | ForEach-Object { $_::GetSupportedEnvironments() | Should -Not -Contain 'testcloud' }
            { Get-SPOScope -M365Environment 'testcloud' @script:DomainParams } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
            { Get-SPOAdminUrl -M365Environment 'testcloud' @script:DomainParams } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }
    }
}

AfterAll {
    Remove-Module SPORestHelper -Force -ErrorAction SilentlyContinue
    Remove-Module Utility -Force -ErrorAction SilentlyContinue
}
