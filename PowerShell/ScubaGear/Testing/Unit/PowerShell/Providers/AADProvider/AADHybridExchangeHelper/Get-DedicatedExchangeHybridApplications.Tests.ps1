$ModulesPath = "../../../../../../Modules"
$AADHybridExchangeHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADHybridExchangeHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADHybridExchangeHelper)

InModuleScope AADHybridExchangeHelper {
    BeforeAll {
        $HybridIds = Get-ExchangeHybridIds
        $FullAccessAsAppRoleId = $HybridIds.FullAccessAsAppRoleId

        # Mock dedicated hybrid app with full_access_as_app permission
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "MockDedicatedHybridApp")]
        $MockDedicatedHybridApp = [PSCustomObject]@{
            ObjectId              = "00000000-0000-0000-0000-000000000010"
            AppId                 = "10000000-0000-0000-0000-000000000000"
            DisplayName           = "ExchangeServerApp-TestOrg"
            IsMultiTenantEnabled  = $false
            KeyCredentials        = @( [PSCustomObject]@{ KeyId = "key-1" } )
            PasswordCredentials   = $null
            FederatedCredentials  = $null
            Permissions           = @(
                [PSCustomObject]@{
                    RoleId    = $FullAccessAsAppRoleId
                    IsRisky   = $true
                    RoleName  = "full_access_as_app"
                }
            )
        }

        # Mock non-hybrid app that does NOT have full_access_as_app
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "MockNonHybridApp")]
        $MockNonHybridApp = [PSCustomObject]@{
            ObjectId              = "00000000-0000-0000-0000-000000000020"
            AppId                 = "20000000-0000-0000-0000-000000000000"
            DisplayName           = "Some Other Risky App"
            IsMultiTenantEnabled  = $false
            KeyCredentials        = $null
            PasswordCredentials   = $null
            FederatedCredentials  = $null
            Permissions           = @(
                [PSCustomObject]@{
                    RoleId    = "0c4b2d20-7919-468d-8668-c54b09d4dee8"
                    IsRisky   = $true
                    RoleName  = "Bookings.ReadWrite.All"
                }
            )
        }

        # Second dedicated hybrid app for multi-app tests
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "MockSecondDedicatedHybridApp")]
        $MockSecondDedicatedHybridApp = [PSCustomObject]@{
            ObjectId              = "00000000-0000-0000-0000-000000000030"
            AppId                 = "30000000-0000-0000-0000-000000000000"
            DisplayName           = "ExchangeServerApp-SecondOrg"
            IsMultiTenantEnabled  = $false
            KeyCredentials        = $null
            PasswordCredentials   = $null
            FederatedCredentials  = $null
            Permissions           = @(
                [PSCustomObject]@{
                    RoleId    = $FullAccessAsAppRoleId
                    IsRisky   = $true
                    RoleName  = "full_access_as_app"
                }
            )
        }
    }

    Describe "Get-DedicatedExchangeHybridApplications" {
        Context "When a dedicated hybrid app is present in the risky apps list" {
            It "returns DedicatedHybridAppConfigured as true" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($MockDedicatedHybridApp, $MockNonHybridApp)
                $Result.DedicatedHybridAppConfigured | Should -BeTrue
            }

            It "returns exactly one application in the 'Apps' array" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($MockDedicatedHybridApp, $MockNonHybridApp)
                @($Result.Apps).Count | Should -Be 1
            }

            It "returns the correct app in the 'Apps' array" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($MockDedicatedHybridApp, $MockNonHybridApp)
                $Result.Apps[0].DisplayName | Should -Be "ExchangeServerApp-TestOrg"
            }

            It "excludes apps that do not have the full_access_as_app permission" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($MockDedicatedHybridApp, $MockNonHybridApp)
                $Result.Apps.DisplayName | Should -Not -Contain "Some Other Risky App"
            }
        }

        Context "When multiple dedicated hybrid apps are present" {
            It "returns DedicatedHybridAppConfigured as true" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($MockDedicatedHybridApp, $MockSecondDedicatedHybridApp, $MockNonHybridApp)
                $Result.DedicatedHybridAppConfigured | Should -BeTrue
            }

            It "returns two apps in the Apps array" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($MockDedicatedHybridApp, $MockSecondDedicatedHybridApp, $MockNonHybridApp)
                @($Result.Apps).Count | Should -Be 2
            }

            It "includes both DisplayNames in the Apps array" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($MockDedicatedHybridApp, $MockSecondDedicatedHybridApp, $MockNonHybridApp)
                $Result.Apps.DisplayName | Should -Contain "ExchangeServerApp-TestOrg"
                $Result.Apps.DisplayName | Should -Contain "ExchangeServerApp-SecondOrg"
            }
        }

        Context "When no dedicated hybrid apps are present in the risky apps list" {
            It "returns DedicatedHybridAppConfigured as false" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($MockNonHybridApp)
                $Result.DedicatedHybridAppConfigured | Should -BeFalse
            }

            It "returns 'Apps' as null" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($MockNonHybridApp)
                $Result.Apps | Should -BeNullOrEmpty
            }
        }

        Context "When an app has the full_access_as_app role but IsRisky is false" {
            It "does not include the app as a dedicated hybrid app" {
                $NotRiskyApp = [PSCustomObject]@{
                    ObjectId    = "00000000-0000-0000-0000-000000000040"
                    AppId       = "40000000-0000-0000-0000-000000000000"
                    DisplayName = "Non-Risky Exchange App"
                    Permissions = @(
                        [PSCustomObject]@{
                            RoleId   = $FullAccessAsAppRoleId
                            IsRisky  = $false
                            RoleName = "full_access_as_app"
                        }
                    )
                }
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @($NotRiskyApp)
                $Result.DedicatedHybridAppConfigured | Should -BeFalse
                $Result.Apps | Should -BeNullOrEmpty
            }
        }

        Context "When AggregateRiskyAppsRaw is an empty array" {
            It "returns DedicatedHybridAppConfigured as false" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @()
                $Result.DedicatedHybridAppConfigured | Should -BeFalse
            }

            It "returns Apps as null" {
                $Result = Get-DedicatedExchangeHybridApplications -AggregateRiskyAppsRaw @()
                $Result.Apps | Should -BeNullOrEmpty
            }
        }
    }
}

AfterAll {
    Remove-Module AADHybridExchangeHelper -Force -ErrorAction 'SilentlyContinue'
}