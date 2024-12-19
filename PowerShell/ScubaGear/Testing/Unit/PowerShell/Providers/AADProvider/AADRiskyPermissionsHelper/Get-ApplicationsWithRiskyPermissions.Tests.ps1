$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-ApplicationsWithRiskyPermissions" {
        BeforeAll {
            # Import mock data
            $MockApplications = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockApplications.json") | ConvertFrom-Json
            $MockFederatedCredentials = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockFederatedCredentials.json") | ConvertFrom-Json

            function Get-MgBetaApplication { $MockApplications }
            function Get-MgBetaApplicationFederatedIdentityCredential { $MockFederatedCredentials }
        }

        It "returns a list of applications with valid properties" {
            Mock Get-MgBetaApplication { $MockApplications }
            Mock Get-MgBetaApplicationFederatedIdentityCredential { $MockFederatedCredentials }

            # Refer to $MockApplications in ./RiskyPermissionsSnippets,
            # we are comparing data stored there with the function's return value
            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            $RiskyApps | Should -HaveCount 3

            $RiskyApps[0].DisplayName | Should -Match "Test App 1"
            $RiskyApps[0].ObjectId | Should -Match "00000000-0000-0000-0000-000000000001"
            $RiskyApps[0].AppId | Should -Match "10000000-0000-0000-0000-000000000000"
            $RiskyApps[0].IsMultiTenantEnabled | Should -Be $true
            $RiskyApps[0].KeyCredentials | Should -HaveCount 2
            $RiskyApps[0].PasswordCredentials | Should -HaveCount 1
            $RiskyApps[0].FederatedCredentials | Should -HaveCount 2
            $RiskyApps[0].RiskyPermissions | Should -HaveCount 2

            $RiskyApps[1].DisplayName | Should -Match "Test App 2"
            $RiskyApps[1].ObjectId | Should -Match "00000000-0000-0000-0000-000000000002"
            $RiskyApps[1].AppId | Should -Match "20000000-0000-0000-0000-000000000000"
            $RiskyApps[1].IsMultiTenantEnabled | Should -Be $false
            $RiskyApps[1].KeyCredentials | Should -HaveCount 1
            $RiskyApps[1].PasswordCredentials | Should -BeNullOrEmpty
            $RiskyApps[1].FederatedCredentials | Should -HaveCount 2
            $RiskyApps[1].RiskyPermissions | Should -HaveCount 3

            $RiskyApps[2].DisplayName | Should -Match "Test App 3"
            $RiskyApps[2].ObjectId | Should -Match "00000000-0000-0000-0000-000000000003"
            $RiskyApps[2].AppId | Should -Match "30000000-0000-0000-0000-000000000000"
            $RiskyApps[2].IsMultiTenantEnabled | Should -Be $false
            $RiskyApps[2].KeyCredentials | Should -BeNullOrEmpty
            $RiskyApps[2].PasswordCredentials | Should -HaveCount 1
            $RiskyApps[2].FederatedCredentials | Should -HaveCount 2
            $RiskyApps[2].RiskyPermissions | Should -HaveCount 4
        }

        It "excludes ResourceAccess objects with property Type='Scope'" {
            # We only care about objects with type="role".
            # Adding a couple objects with type="scope" to verify they're excluded
            $ResourceAccess = $MockApplications[0].RequiredResourceAccess[0].ResourceAccess
            $ResourcesOfTypeScope = @(
                [PSCustomObject]@{
                    Id = "b633e1c5-b582-4048-a93e-9f11b44c7e96" # Mail.Send
                    Type = "Scope"
                }
                [PSCustomObject]@{
                    Id = "19dbc75e-c2e2-444c-a770-ec69d8559fc7" # Directory.ReadWrite.All
                    Type = "Scope"
                }
            )
            $ResourceAccess += $ResourcesOfTypeScope
            $ResourceAccess | Should -HaveCount 4

            Mock Get-MgBetaApplication { $MockApplications[0] }
            Mock Get-MgBetaApplicationFederatedIdentityCredential {}

            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            $RiskyApps[0].RiskyPermissions | Should -HaveCount 2
        }

        It "correctly formats federated credentials if they exist" {
            Mock Get-MgBetaApplication { $MockApplications[0] }
            Mock Get-MgBetaApplicationFederatedIdentityCredential {}

            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            $ExpectedKeys = @("Id", "Name", "Description", "Issuer", "Subject", "Audiences")
            foreach ($Credential in $RiskyApps[0].FederatedCredentials) {
                # Check for correct properties
                $Credential.PSObject.Properties.Name | Should -Be $ExpectedKeys
            }
        }

        It "sets the list of federated credentials to null if no credentials exist" {
            Mock Get-MgBetaApplication { $MockApplications[0] }
            Mock Get-MgBetaApplicationFederatedIdentityCredential {}

            $RiskyApps = Get-ApplicationsWithRiskyPermissions
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

            Mock Get-MgBetaApplication { $MockApplications }
            Mock Get-MgBetaApplicationFederatedIdentityCredential {}

            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            $RiskyApps | Should -HaveCount 2
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}