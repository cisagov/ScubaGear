$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-ApplicationsWithRiskyPermissions" {
        BeforeAll {
            # Import mock data
            $MockApplications = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockApplications.json") | ConvertFrom-Json
            $MockFederatedCredentials = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockFederatedCredentials.json") | ConvertFrom-Json
            $MockResourcePermissionCacheJson = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockResourcePermissionCache.json") | ConvertFrom-Json
            $MockResourcePermissionCache = @{}
            foreach ($prop in $MockResourcePermissionCacheJson.PSObject.Properties) {
                $MockResourcePermissionCache[$prop.Name] = $prop.Value
            }

            Mock Invoke-MgGraphRequest { $MockApplications }
            Mock Invoke-GraphDirectly {
                return $MockResourcePermissionCache
            }

            Mock Invoke-GraphDirectly {
                return @{
                    "value" = $MockApplications
                    "@odata.context" = "https://graph.microsoft.com/beta/$metadata#applications"
                }
            } -ParameterFilter { $commandlet -eq "Get-MgBetaApplication" -or $Uri -match "/applications" } -ModuleName AADRiskyPermissionsHelper
              Mock Invoke-GraphDirectly {
                param($commandlet, $ID, $Uri)
                # Suppress PSReviewUnusedParameter warnings
                $null = $commandlet
                $null = $Uri
                return @{
                    "value" = $MockFederatedCredentials
                    "@odata.context" = "https://graph.microsoft.com/beta/$metadata#applications/$ID/federatedIdentityCredentials"
                }
            } -ParameterFilter { $commandlet -eq "Get-MgBetaApplicationFederatedIdentityCredential" -or $Uri -match "/federatedIdentityCredentials" } -ModuleName AADRiskyPermissionsHelper
        }

        It "returns a list of applications with valid properties" {
            # Refer to $MockApplications in ./RiskyPermissionsSnippets,
            # we are comparing data stored there with the function's return value
            $RiskyApps = Get-ApplicationsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache
            $RiskyApps | Should -HaveCount 3

            $RiskyApps[0].DisplayName | Should -Match "Test App 1"
            $RiskyApps[0].ObjectId | Should -Match "00000000-0000-0000-0000-000000000001"
            $RiskyApps[0].AppId | Should -Match "10000000-0000-0000-0000-000000000000"
            $RiskyApps[0].IsMultiTenantEnabled | Should -Be $true
            $RiskyApps[0].KeyCredentials | Should -HaveCount 2
            $RiskyApps[0].PasswordCredentials | Should -HaveCount 1
            $RiskyApps[0].FederatedCredentials | Should -HaveCount 2
            $RiskyApps[0].Permissions | Should -HaveCount 2

            $RiskyApps[1].DisplayName | Should -Match "Test App 2"
            $RiskyApps[1].ObjectId | Should -Match "00000000-0000-0000-0000-000000000002"
            $RiskyApps[1].AppId | Should -Match "20000000-0000-0000-0000-000000000000"
            $RiskyApps[1].IsMultiTenantEnabled | Should -Be $false
            $RiskyApps[1].KeyCredentials | Should -HaveCount 1
            $RiskyApps[1].PasswordCredentials | Should -BeNullOrEmpty
            $RiskyApps[1].FederatedCredentials | Should -HaveCount 2
            $RiskyApps[1].Permissions | Should -HaveCount 3

            $RiskyApps[2].DisplayName | Should -Match "Test App 3"
            $RiskyApps[2].ObjectId | Should -Match "00000000-0000-0000-0000-000000000003"
            $RiskyApps[2].AppId | Should -Match "30000000-0000-0000-0000-000000000000"
            $RiskyApps[2].IsMultiTenantEnabled | Should -Be $false
            $RiskyApps[2].KeyCredentials | Should -BeNullOrEmpty
            $RiskyApps[2].PasswordCredentials | Should -HaveCount 1
            $RiskyApps[2].FederatedCredentials | Should -HaveCount 2
            $RiskyApps[2].Permissions | Should -HaveCount 4
        }

        It "correctly formats federated credentials if they exist" {
            $RiskyApps = Get-ApplicationsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache
            $ExpectedKeys = @("Id", "Name", "Description", "Issuer", "Subject", "Audiences")
            foreach ($Credential in $RiskyApps[0].FederatedCredentials) {
                # Check for correct properties
                $Credential.PSObject.Properties.Name | Should -Be $ExpectedKeys
            }
        }

        It "sets the list of federated credentials to null if no credentials exist" {
            # Override to return empty federated credentials
            Mock Invoke-GraphDirectly {
                return @{
                    "value" = @()
                    "@odata.context" = "https://graph.microsoft.com/beta/$metadata#federatedIdentityCredentials"
                }
            } -ParameterFilter { $commandlet -eq "Get-MgBetaApplicationFederatedIdentityCredential" -or $Uri -match "/federatedIdentityCredentials" } -ModuleName AADRiskyPermissionsHelper

            $RiskyApps = Get-ApplicationsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache
            $RiskyApps[0].FederatedCredentials | Should -BeNullOrEmpty
        }

        It "excludes applications without risky permissions" {
            # Reset to some arbitrary Id not included in RiskyPermissions.json mapping
            $MockApplications[1].RequiredResourceAccess[0].ResourceAccess = @(
                [PSCustomObject]@{
                    Id = "00000000-0000-0000-0000-000000000000"
                    Type = "Role"
                }
            )
            # Reset to empty list
            $MockApplications[1].RequiredResourceAccess[1].ResourceAccess = @()

            $RiskyApps = @()
            foreach ($App in Get-ApplicationsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache) {
                $RiskyPerms = $App.Permissions | Where-Object { $_.IsRisky }
                if ($RiskyPerms.Count -gt 0) {
                    $RiskyApps += $App
                }
            }
            $RiskyApps | Should -HaveCount 2
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}