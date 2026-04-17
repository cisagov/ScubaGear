$ModulesPath = "../../../../../../Modules"
$AADHybridExchangeHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADHybridExchangeHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADHybridExchangeHelper)

InModuleScope AADHybridExchangeHelper {
    BeforeAll {
        # Import mock data
        $SnippetsPath = Join-Path -Path $PSScriptRoot -ChildPath "../HybridExchangeSnippets"
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockExchangeOnlineSP')]
        $MockExchangeOnlineSP = Get-Content "$SnippetsPath/MockExchangeOnlineServicePrincipal.json" | ConvertFrom-Json
    }
    Describe "Get-LegacyExchangeServicePrincipal" {
        Context "When the Exchange Online service principal exists with key credentials" {
            BeforeEach {
                Mock Invoke-GraphDirectly {
                    return @{ Value = $MockExchangeOnlineSP }
                }
            }

            It "returns the correct ObjectId" {
                $Result = Get-LegacyExchangeServicePrincipal -M365Environment "gcc"
                $Result.ObjectId | Should -Be $MockExchangeOnlineSP.Id
            }

            It "returns the correct AppId" {
                $Result = Get-LegacyExchangeServicePrincipal -M365Environment "gcc"
                $Result.AppId | Should -Be $MockExchangeOnlineSP.AppId
            }

            It "returns the correct DisplayName" {
                $Result = Get-LegacyExchangeServicePrincipal -M365Environment "gcc"
                $Result.DisplayName | Should -Be $MockExchangeOnlineSP.DisplayName
            }

            It "returns the correct SignInAudience" {
                $Result = Get-LegacyExchangeServicePrincipal -M365Environment "gcc"
                $Result.SignInAudience | Should -Be $MockExchangeOnlineSP.SignInAudience
            }

            It "returns the correct AppOwnerOrganizationId" {
                $Result = Get-LegacyExchangeServicePrincipal -M365Environment "gcc"
                $Result.AppOwnerOrganizationId | Should -Be $MockExchangeOnlineSP.AppOwnerOrganizationId
            }

            It "indicates HasKeyCredentials is true when key credentials are present" {
                $Result = Get-LegacyExchangeServicePrincipal -M365Environment "gcc"
                $Result.HasKeyCredentials | Should -BeTrue
            }

            It "populates KeyCredentials from the service principal" {
                $Result = Get-LegacyExchangeServicePrincipal -M365Environment "gcc"
                $Result.KeyCredentials | Should -Not -BeNullOrEmpty
                $Result.KeyCredentials | Should -HaveCount $MockExchangeOnlineSP.KeyCredentials.Count
            }
        }

        Context "When the Exchange Online service principal exists with no key credentials" {
            BeforeEach {
                $MockSPWithNoKeys = $MockExchangeOnlineSP | Select-Object *
                $MockSPWithNoKeys.KeyCredentials = $null

                Mock Invoke-GraphDirectly {
                    return @{ Value = $MockSPWithNoKeys }
                }
            }

            It "indicates HasKeyCredentials is false" {
                $Result = Get-LegacyExchangeServicePrincipal -M365Environment "gcc"
                $Result.HasKeyCredentials | Should -BeFalse
            }

            It "returns null for KeyCredentials" {
                $Result = Get-LegacyExchangeServicePrincipal -M365Environment "gcc"
                $Result.KeyCredentials | Should -BeNullOrEmpty
            }
        }

        Context "When Invoke-GraphDirectly throws an exception" {
            BeforeEach {
                Mock Invoke-GraphDirectly {
                    throw "Graph API error"
                }
            }

            It "throws an exception" {
                { Get-LegacyExchangeServicePrincipal -M365Environment "gcc" } | Should -Throw "Graph API error"
            }
        }
    }
}

AfterAll {
    Remove-Module AADHybridExchangeHelper -Force -ErrorAction 'SilentlyContinue'
}