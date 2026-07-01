$ModulesPath = "../../../../../../Modules"
$AADHybridExchangeHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADHybridExchangeHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADHybridExchangeHelper)

InModuleScope AADHybridExchangeHelper {
    Describe "Get-ExchangeHybridIds" {
        Context "When RiskyPermissions.json is present and contaisn the expected entries" {
            It "returns a hashtable" {
                $Result = Get-ExchangeHybridIds
                $Result | Should -BeOfType [hashtable]
            }

            It "returns a hashtable containing ExchangeOnlineAppId and FullAccessAsAppRoleId keys" {
                $Result = Get-ExchangeHybridIds
                $Result.Keys | Should -Contain "ExchangeOnlineAppId"
                $Result.Keys | Should -Contain "FullAccessAsAppRoleId"
            }

            It "returns the correct Office 365 Exchange Online AppId" {
                $Result = Get-ExchangeHybridIds
                $Result.ExchangeOnlineAppId | Should -Be "00000002-0000-0ff1-ce00-000000000000"
            }

            It "returns the correct full_access_as_app role ID" {
                $Result = Get-ExchangeHybridIds
                $Result.FullAccessAsAppRoleId | Should -Be "dc890d15-9560-4a4c-9b7f-a736ec74ec40"
            }
        }

        Context "When Office 365 Exchange Online is missing from RiskyPermissions.json" {
            BeforeEach {
                Mock Get-RiskyPermissionsJson {
                    return [PSCustomObject]@{
                        resources = [PSCustomObject]@{}
                        permissions = [PSCustomObject]@{}
                    }
                }
            }

            It "throws an error referencing 'Office 365 Exchange Online'" {
                { Get-ExchangeHybridIds } | Should -Throw "Could not find 'Office 365 Exchange Online' in RiskyPermissions.json."
            }
        }

        Context "When full_access_as_app is missing from RiskyPermissions.json" {
            BeforeEach {
                Mock Get-RiskyPermissionsJson {
                    return [PSCustomObject]@{
                        resources = [PSCustomObject]@{
                            "00000002-0000-0ff1-ce00-000000000000" = "Office 365 Exchange Online"
                        }
                        permissions = [PSCustomObject]@{
                            "Office 365 Exchange Online" = [PSCustomObject]@{
                                Application = [PSCustomObject]@{}
                            }
                        }
                    }
                }
            }

            It "Should throw an error referencing 'full_access_as_app'" {
                { Get-ExchangeHybridIds } | Should -Throw "Could not find 'full_access_as_app' in RiskyPermissions.json under permissions.'Office 365 Exchange Online'.Application"
            }
        }
    }
}

AfterAll {
    Remove-Module AADHybridExchangeHelper -Force -ErrorAction 'SilentlyContinue'
}