$ModulesPath = "../../../../../../Modules"
$AADHybridExchangeHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADHybridExchangeHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADHybridExchangeHelper)

InModuleScope AADHybridExchangeHelper {
    BeforeAll {
        # Import mock data
        $SnippetsPath = Join-Path -Path $PSScriptRoot -ChildPath "../HybridExchangeSnippets"
        $MockAppRoleAssignment = Get-Content "$SnippetsPath/MockAppRoleAssignment.json" | ConvertFrom-Json
        $MockDedicatedHybridAppRegistration = Get-Content "$SnippetsPath/MockDedicatedHybridAppRegistration.json" | ConvertFrom-Json
        $MockDedicatedHybridSP = Get-Content "$SnippetsPath/MockDedicatedHybridServicePrincipal.json" | ConvertFrom-Json
        $MockExchangeOnlineSP = Get-Content "$SnippetsPath/MockExchangeOnlineServicePrincipal.json" | ConvertFrom-Json

        $ExchangeOnlineAppId = "00000002-0000-0ff1-ce00-000000000000"
        $FullAccessAsAppRoleId = "dc890d15-9560-4a4c-9b7f-a736ec74ec40"
    }

    Describe "Get-DedicatedExchangeHybridApplications" {
        Context "When a dedicated hybrid app is fully configured with an app registration and service principal" {
            BeforeEach {
                Mock Invoke-GraphDirectly {
                    param($Commandlet, $M365Environment, $QueryParams, $Id)
                    switch ($Commandlet) {
                        "Get-MgBetaServicePrincipal" {
                            if ($QueryParams.'$filter' -like "$($ExchangeOnlineAppId)") {
                                return @{ Value = $MockExchangeOnlineSP }
                            }
                            return @{ Value = $MockDedicatedHybridSP }
                        }
                        "Get-MgBetaServicePrincipalAppRoleAssignedTo" {
                            return @{ Value = @($MockAppRoleAssignment) }
                        }
                        "Get-MgBetaApplication" {
                            return @{ Value = $MockDedicatedHybridAppRegistration }
                        }
                        "Get-MgBetaApplicationFederatedIdentityCredential" {
                            return @{ Value = $null }
                        }
                    }
                }
            }

            It "returns DedicatedHybridAppConfigured as true" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.DedicatedHybridAppConfigured | Should -BeTrue
            }

            It "returns exactly one application in the 'Apps' array" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                @($Result.Apps).Count | Should -Be 1
            }

            It "returns the correct DisplayName from the service principal" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].DisplayName | Should -Be $MockDedicatedHybridSP.DisplayName
            }

            It "returns the correct AppId from the service principal" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].AppId | Should -Be $MockDedicatedHybridSP.AppId
            }

            It "returns the correct AppOwnerOrganizationId from the service principal" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].AppOwnerOrganizationId | Should -Be $MockDedicatedHybridSP.AppOwnerOrganizationId
            }

            It "indicates AppRegistrationExists is true" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].AppRegistrationExists | Should -BeTrue
            }

            It "sets 'ObjectId.ServicePrincipal' from the service principal" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].ObjectId.ServicePrincipal | Should -Be $MockDedicatedHybridSP.Id
            }

            It "sets 'ObjectId.AppRegistration' from the app registration" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].ObjectId.Application | Should -Be $MockDedicatedHybridAppRegistration.Id
            }

            It "populates FullAccessAsAppRole with the correct AppRoleId" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].FullAccessAsAppRole | Should -Not -BeNullOrEmpty
                $Result.Apps[0].FullAccessAsAppRole.AppRoleId | Should -Be $FullAccessAsAppRoleId
            }

            It "indicates HasKeyCredentials is true when the app registration has key credentials" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].HasKeyCredentials | Should -BeTrue
            }

            It "populates KeyCredentials from the app registration" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].KeyCredentials | Should -Not -BeNullOrEmpty
                $Result.Apps[0].KeyCredentials | Should -HaveCount $MockDedicatedHybridAppRegistration.KeyCredentials.Count
            }

            It "returns null for 'FederatedCredentials' when none exist" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].FederatedCredentials | Should -BeNullOrEmpty
            }
        }

        Context "When a dedicated hybrid app has federated credentials assigned" {
            BeforeEach {
                $MockFederatedCredential = [PSCustomObject]@{
                    Id          = "00000000-0000-0000-0000-000000000099"
                    Name        = "TestFederatedCredential"
                    Description = "Test federated identity"
                    Issuer      = "https://token.actions.githubusercontent.com"
                    Subject     = "repo:org/repo:ref:refs/heads/main"
                    Audiences   = @("api://AzureADTokenExchange")
                }

                Mock Invoke-GraphDirectly {
                    param($Commandlet, $M365Environment, $QueryParams, $Id)
                    switch ($Commandlet) {
                        "Get-MgBetaServicePrincipal" {
                            if ($QueryParams.'$filter' -like "$($ExchangeOnlineAppId)") {
                                return @{ Value = $MockExchangeOnlineSP }
                            }
                            return @{ Value = $MockDedicatedHybridSP }
                        }
                        "Get-MgBetaServicePrincipalAppRoleAssignedTo" {
                            return @{ Value = @($MockAppRoleAssignment) }
                        }
                        "Get-MgBetaApplication" {
                            return @{ Value = $MockDedicatedHybridAppRegistration }
                        }
                        "Get-MgBetaApplicationFederatedIdentityCredential" {
                            return @{ Value = @($MockFederatedCredential) }
                        }
                    }
                }
            }

            It "populates 'FederatedCredentials' with one entry" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].FederatedCredentials | Should -Not -BeNullOrEmpty
                $Result.Apps[0].FederatedCredentials.Count | Should -Be 1
            }

            It "maps the correct federated credential 'Issuer'" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].FederatedCredentials[0].Issuer | Should -Be "https://token.actions.githubusercontent.com"
            }

            It "maps the correct federated credential 'Subject'" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].FederatedCredentials[0].Subject | Should -Be "repo:org/repo:ref:refs/heads/main"
            }

            It "maps the correct federated credential 'Name'" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].FederatedCredentials[0].Name | Should -Be "TestFederatedCredential"
            }
        }

        Context "When the service principal exists but has no app registration" {
            BeforeEach {
                Mock Invoke-GraphDirectly {
                    param($Commandlet, $M365Environment, $QueryParams, $Id)
                    switch ($Commandlet) {
                        "Get-MgBetaServicePrincipal" {
                            if ($QueryParams.'$filter' -like "$($ExchangeOnlineAppId)") {
                                return @{ Value = $MockExchangeOnlineSP }
                            }
                            return @{ Value = $MockDedicatedHybridSP }
                        }
                        "Get-MgBetaServicePrincipalAppRoleAssignedTo" {
                            return @{ Value = @($MockAppRoleAssignment) }
                        }
                        "Get-MgBetaApplication" {
                            return @{ Value = $null }
                        }
                    }
                }
            }

            It "returns DedicatedHybridAppConfigured as true" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.DedicatedHybridAppConfigured | Should -BeTrue
            }

            It "indicates AppRegistrationExists is false" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].AppRegistrationExists | Should -BeFalse
            }

            It "sets 'ObjectId.Application' to null when no app registration exists" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].ObjectId.Application | Should -BeNullOrEmpty
            }

            It "sets 'HasKeyCredentials' to false when no app registration exists" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].HasKeyCredentials | Should -BeFalse
            }

            It "returns null for 'KeyCredentials' when no app registration exists" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].KeyCredentials | Should -BeNullOrEmpty
            }

            It "returns null for 'PasswordCredentials' when no app registration exists" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps[0].PasswordCredentials | Should -BeNullOrEmpty
            }
        }

        Context "When the Exchange Online service principal is not found in the tenant" {
            BeforeEach {
                Mock Invoke-GraphDirectly {
                    return @{ Value = $null }
                }
            }

            It "returns DedicatedHybridAppConfigured as false" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.DedicatedHybridAppConfigured | Should -BeFalse
            }

            It "returns 'Apps' as null" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps | Should -BeNullOrEmpty
            }
        }

        Context "When no app role assignments match full_access_as_app" {
            BeforeEach {
                Mock Invoke-GraphDirectly {
                    param($Commandlet, $M365Environment, $QueryParams, $Id)
                    switch ($Commandlet) {
                        "Get-MgBetaServicePrincipal" {
                            return @{ Value = $MockExchangeOnlineSP }
                        }
                        "Get-MgBetaServicePrincipalAppRoleAssignedTo" {
                            return @{ Value = @([PSCustomObject]@{
                                AppRoleId   = "00000000-0000-0000-0000-000000000000"
                                PrincipalId = "00000000-0000-0000-0000-000000000020"
                            })}
                        }
                    }
                }
            }

            It "returns DedicatedHybridAppConfigured as false" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.DedicatedHybridAppConfigured | Should -BeFalse
            }

            It "returns Apps as null" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps | Should -BeNullOrEmpty
            }
        }

        Context "When no app role assignments exist at all" {
            BeforeEach {
                Mock Invoke-GraphDirectly {
                    param($Commandlet, $M365Environment, $QueryParams, $Id)
                    switch ($Commandlet) {
                        "Get-MgBetaServicePrincipal" {
                            return @{ Value = $MockExchangeOnlineSP }
                        }
                        "Get-MgBetaServicePrincipalAppRoleAssignedTo" {
                            return @{ Value = $null }
                        }
                    }
                }
            }

            It "returns DedicatedHybridAppConfigured as false" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.DedicatedHybridAppConfigured | Should -BeFalse
            }

            It "returns Apps as null" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps | Should -BeNullOrEmpty
            }
        }

        Context "When multiple dedicated hybrid apps are assigned full_access_as_app" {
            BeforeEach {
                $SecondAssignment = $MockAppRoleAssignment | Select-Object *
                $SecondAssignment.PrincipalId = "00000000-0000-0000-0000-000000000021"

                $SecondSP = $MockDedicatedHybridSP | Select-Object *
                $SecondSP.Id = "00000000-0000-0000-0000-000000000021"
                $SecondSP.DisplayName = "ExchangeServerApp-SecondOrg"

                Mock Invoke-GraphDirectly {
                    param($Commandlet, $M365Environment, $QueryParams, $Id)
                    switch ($Commandlet) {
                        "Get-MgBetaServicePrincipal" {
                            if ($QueryParams.'$filter' -like "*$($ExchangeOnlineAppId)*") {
                                return @{ Value = $MockExchangeOnlineSP }
                            }
                            if ($QueryParams.'$filter' -like "*00000000-0000-0000-0000-000000000021*") {
                                return @{ Value = $SecondSP }
                            }
                            return @{ Value = $MockDedicatedHybridSP }
                        }
                        "Get-MgBetaServicePrincipalAppRoleAssignedTo" {
                            return @{ Value = @($MockAppRoleAssignment, $SecondAssignment) }
                        }
                        "Get-MgBetaApplication" {
                            return @{ Value = $MockDedicatedHybridApp }
                        }
                        "Get-MgBetaApplicationFederatedIdentityCredential" {
                            return @{ Value = $null }
                        }
                    }
                }
            }

            It "returns DedicatedHybridAppConfigured as true" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.DedicatedHybridAppConfigured | Should -BeTrue
            }

            It "returns two apps in the Apps array" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                @($Result.Apps).Count | Should -Be 2
            }

            It "includes both DisplayNames in the Apps array" {
                $Result = Get-DedicatedExchangeHybridApplications -M365Environment "gcc"
                $Result.Apps.DisplayName | Should -Contain $MockDedicatedHybridSP.DisplayName
                $Result.Apps.DisplayName | Should -Contain $SecondSP.DisplayName
            }
        }

        Context "When Invoke-GraphDirectly throws an exception" {
            BeforeEach {
                Mock Invoke-GraphDirectly {
                    throw "Graph API error"
                }
            }

            It "rethrows the exception" {
                { Get-DedicatedExchangeHybridApplications -M365Environment "gcc" } | Should -Throw "Graph API error"
            }
        }
    }
}