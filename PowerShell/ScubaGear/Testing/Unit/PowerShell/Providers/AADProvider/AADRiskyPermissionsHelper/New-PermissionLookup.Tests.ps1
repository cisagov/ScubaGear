$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "New-PermissionLookup" {
        It "builds a nested lookup with Name and RiskLevel" {
            $Json = [PSCustomObject]@{
                permissions = [PSCustomObject]@{
                    "Microsoft Graph" = [PSCustomObject]@{
                        Application = [PSCustomObject]@{
                            "11111111-1111-1111-1111-111111111111" = [PSCustomObject]@{
                                Name = "Application.ReadWrite.All"
                                RiskLevel = "Critical"
                            }
                        }
                        Delegated = [PSCustomObject]@{
                            "22222222-2222-2222-2222-222222222222" = [PSCustomObject]@{
                                Name = "User.Read.All"
                                RiskLevel = "High"
                            }
                        }
                    }
                }
            }

            $Lookup = New-PermissionLookup -Json $Json

            $Lookup.ContainsKey("Microsoft Graph") | Should -BeTrue
            $Lookup["Microsoft Graph"].ContainsKey("Application") | Should -BeTrue
            $Lookup["Microsoft Graph"].ContainsKey("Delegated") | Should -BeTrue
            $Lookup["Microsoft Graph"]["Application"]["11111111-1111-1111-1111-111111111111"].Name | Should -Be "Application.ReadWrite.All"
            $Lookup["Microsoft Graph"]["Application"]["11111111-1111-1111-1111-111111111111"].RiskLevel | Should -Be "Critical"
        }

        It "skips underscore-prefixed internal keys" {
            $Json = [PSCustomObject]@{
                permissions = [PSCustomObject]@{
                    "Microsoft Graph" = [PSCustomObject]@{
                        _excludedDelegated = [PSCustomObject]@{
                            "33333333-3333-3333-3333-333333333333" = [PSCustomObject]@{
                                Name = "Ignored"
                                RiskLevel = "Low"
                            }
                        }
                        Application = [PSCustomObject]@{
                            "44444444-4444-4444-4444-444444444444" = [PSCustomObject]@{
                                Name = "Directory.Read.All"
                                RiskLevel = "High"
                            }
                        }
                    }
                }
            }

            $Lookup = New-PermissionLookup -Json $Json

            $Lookup["Microsoft Graph"].ContainsKey("_excludedDelegated") | Should -BeFalse
            $Lookup["Microsoft Graph"]["Application"].ContainsKey("44444444-4444-4444-4444-444444444444") | Should -BeTrue
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}
