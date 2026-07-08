$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-PermissionLookup" {
        BeforeEach {
            $script:CachedRiskyAppPermissionsJson = $null
            $script:CachedPermissionLookup = $null
        }

        It "returns existing cache without rebuilding" {
            $ExistingLookup = @{
                "Microsoft Graph" = @{ Application = @{} }
            }
            $script:CachedPermissionLookup = $ExistingLookup

            $Result = Get-PermissionLookup

            [object]::ReferenceEquals($ExistingLookup, $Result) | Should -BeTrue
        }

        It "builds and caches lookup from provided JSON" {
            $Json = [PSCustomObject]@{
                permissions = [PSCustomObject]@{
                    "Microsoft Graph" = [PSCustomObject]@{
                        Application = [PSCustomObject]@{
                            "55555555-5555-5555-5555-555555555555" = [PSCustomObject]@{
                                Name = "Mail.ReadWrite"
                                RiskLevel = "Critical"
                            }
                        }
                    }
                }
            }

            $Result = Get-PermissionLookup -RiskyAppPermissionsJson $Json

            $Result["Microsoft Graph"]["Application"]["55555555-5555-5555-5555-555555555555"].Name | Should -Be "Mail.ReadWrite"
            $script:CachedPermissionLookup | Should -Not -BeNullOrEmpty
        }

        It "loads JSON via Get-RiskyAppPermissionsJson when input is null" {
            $Json = [PSCustomObject]@{
                permissions = [PSCustomObject]@{
                    "Microsoft Graph" = [PSCustomObject]@{
                        Delegated = [PSCustomObject]@{
                            "66666666-6666-6666-6666-666666666666" = [PSCustomObject]@{
                                Name = "User.Read"
                                RiskLevel = "Low"
                            }
                        }
                    }
                }
            }

            Mock Get-RiskyAppPermissionsJson {
                return $Json
            } -ModuleName AADRiskyPermissionsHelper

            $Result = Get-PermissionLookup

            Assert-MockCalled Get-RiskyAppPermissionsJson -Times 1 -ModuleName AADRiskyPermissionsHelper
            $Result["Microsoft Graph"]["Delegated"]["66666666-6666-6666-6666-666666666666"].RiskLevel | Should -Be "Low"
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}
