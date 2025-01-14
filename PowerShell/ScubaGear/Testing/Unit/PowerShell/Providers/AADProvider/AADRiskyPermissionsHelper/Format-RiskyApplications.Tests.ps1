$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "Format-RiskyApplications" {
        BeforeAll {
            # Import mock data
            $MockApplications = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockApplications.json") | ConvertFrom-Json
            $MockFederatedCredentials = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockFederatedCredentials.json") | ConvertFrom-Json
            $MockServicePrincipals = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipals.json") | ConvertFrom-Json
            $MockServicePrincipalAppRoleAssignments = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipalAppRoleAssignments.json") | ConvertFrom-Json

            function Get-MgBetaApplication { $MockApplications }
            function Get-MgBetaApplicationFederatedIdentityCredential { $MockFederatedCredentials }
            function Get-MgBetaServicePrincipal { $MockServicePrincipals }
            function Get-MgBetaServicePrincipalAppRoleAssignment { $MockServicePrincipalAppRoleAssignments }

            Mock Get-MgBetaApplication { $MockApplications }
            Mock Get-MgBetaApplicationFederatedIdentityCredential { $MockFederatedCredentials }
            Mock Get-MgBetaServicePrincipal { $MockServicePrincipals }
            Mock Get-MgBetaServicePrincipalAppRoleAssignment { $MockServicePrincipalAppRoleAssignments }

            $RiskyApps = Get-ApplicationsWithRiskyPermissions
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'AggregateRiskyApps')]
            $AggregateRiskyApps = Format-RiskyApplications -RiskyApps $RiskyApps -RiskySPs $RiskySPs
        }

        It "returns a list of first-party risky applications with valid properties" {
            $AggregateRiskyApps | Should -HaveCount 3

            $AggregateRiskyApps[0].DisplayName | Should -Match "Test App 1"
            $AggregateRiskyApps[0].ObjectId.Application | Should -Match "00000000-0000-0000-0000-000000000001"
            $AggregateRiskyApps[0].ObjectId.ServicePrincipal | Should -Match "00000000-0000-0000-0000-000000000010"
            $AggregateRiskyApps[0].AppId | Should -Match "10000000-0000-0000-0000-000000000000"
            $AggregateRiskyApps[0].IsMultiTenantEnabled | Should -Be $true
            $AggregateRiskyApps[0].KeyCredentials | Should -HaveCount 3
            $AggregateRiskyApps[0].PasswordCredentials | Should -HaveCount 2
            $AggregateRiskyApps[0].FederatedCredentials | Should -HaveCount 2
            $AggregateRiskyApps[0].RiskyPermissions | Should -HaveCount 2

            $AggregateRiskyApps[1].DisplayName | Should -Match "Test App 2"
            $AggregateRiskyApps[1].ObjectId.Application | Should -Match "00000000-0000-0000-0000-000000000002"
            $AggregateRiskyApps[1].ObjectId.ServicePrincipal | Should -Match "00000000-0000-0000-0000-000000000020"
            $AggregateRiskyApps[1].AppId | Should -Match "20000000-0000-0000-0000-000000000000"
            $AggregateRiskyApps[1].IsMultiTenantEnabled | Should -Be $false
            $AggregateRiskyApps[1].KeyCredentials | Should -HaveCount 2
            $AggregateRiskyApps[1].PasswordCredentials | Should -BeNullOrEmpty
            $AggregateRiskyApps[1].FederatedCredentials | Should -HaveCount 2
            $AggregateRiskyApps[1].RiskyPermissions | Should -HaveCount 3

            # Application with no matching service principal results in slightly different format
            $AggregateRiskyApps[2].DisplayName | Should -Match "Test App 3"
            $AggregateRiskyApps[2].ObjectId | Should -Match "00000000-0000-0000-0000-000000000003"
            $AggregateRiskyApps[2].AppId | Should -Match "30000000-0000-0000-0000-000000000000"
            $AggregateRiskyApps[2].IsMultiTenantEnabled | Should -Be $false
            $AggregateRiskyApps[2].KeyCredentials | Should -BeNullOrEmpty
            $AggregateRiskyApps[2].PasswordCredentials | Should -HaveCount 1
            $AggregateRiskyApps[2].FederatedCredentials | Should -HaveCount 2
            $AggregateRiskyApps[2].RiskyPermissions | Should -HaveCount 4
        }

        It "matches service principals with applications that have the same AppId" {
            $AggregateRiskyApps[0].ObjectId | Should -BeOfType [Object]
            $AggregateRiskyApps[1].ObjectId | Should -BeOfType [Object]
            $AggregateRiskyApps[2].ObjectId | Should -BeOfType [string]
        }

        It "sets an application permission's admin consent property to true" {
            foreach ($App in $AggregateRiskyApps) {
                $MatchedSP = $RiskySPs | Where-Object { $_.AppId -eq $App.AppId }
                # Check if corresponding service principal object exists
                if($MatchedSP) {
                    foreach ($AppPermission in $App.RiskyPermissions) {
                        # If the application permission is included as a service principal permission,
                        # then the permission has admin consent.
                        # If not included, then the permission has no admin consent.
                        $SPPermission = $MatchedSP.RiskyPermissions | Where-Object { $_.RoleId -eq $AppPermission.RoleId }
                        if ($SPPermission) {
                            $AppPermission.IsAdminConsented | Should -Be $true
                        }
                        else {
                            $AppPermission.IsAdminConsented | Should -Be $false
                        }
                    }
                }
            }
        }

        It "correctly formats the object with merged properties from both applications and service principals" {
            # Object IDs are merged into a single object, but as separate properties
            # KeyCredentials/PasswordCredentials/FederatedCredentials are merged into one list
            $ExpectedKeys = @(
                "ObjectId", "AppId", "DisplayName", "IsMultiTenantEnabled", `
                "KeyCredentials", "PasswordCredentials", "FederatedCredentials", "RiskyPermissions"
            )
            foreach ($App in $AggregateRiskyApps) {
                # Check for correct properties
                $App.PSObject.Properties.Name | Should -Be $ExpectedKeys
            }
        }

        It "keeps applications in the merged dataset that don't have a matching service principal object" {
            $AppsWithNoMatch = 0
            foreach ($App in $AggregateRiskyApps) {
                $MatchedSP = $RiskySPs | Where-Object { $_.AppId -eq $App.AppId }

                if(!$MatchedSP) {
                    $AppsWithNoMatch += 1
                }
            }
            $AppsWithNoMatch | Should -Be 1
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}