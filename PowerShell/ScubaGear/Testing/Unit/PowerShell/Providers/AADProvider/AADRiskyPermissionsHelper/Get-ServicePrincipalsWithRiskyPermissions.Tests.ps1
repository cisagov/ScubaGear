$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-ServicePrincipalsWithRiskyPermissions" {
        BeforeAll {
            # Import mock data
            $MockServicePrincipals = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipals.json") | ConvertFrom-Json
            $MockServicePrincipalAppRoleAssignments = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipalAppRoleAssignments.json") | ConvertFrom-Json

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockSafePermissions')]
            $MockSafePermissions = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockSafePermissions.json") | ConvertFrom-Json

            function Get-MgBetaServicePrincipal { $MockServicePrincipals }
            function Get-MgBetaServicePrincipalAppRoleAssignment { $MockServicePrincipalAppRoleAssignments }
        }

        It "returns a list of service principals with valid properties" {
            Mock Get-MgBetaServicePrincipal { $MockServicePrincipals }
            Mock Get-MgBetaServicePrincipalAppRoleAssignment { $MockServicePrincipalAppRoleAssignments }

            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
            $RiskySPs | Should -HaveCount 5

            $RiskySPs[0].DisplayName | Should -Match "Test SP 1"
            $RiskySPs[0].KeyCredentials | Should -HaveCount 1
            $RiskySPs[0].PasswordCredentials | Should -HaveCount 1
            $RiskySPs[0].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[0].RiskyPermissions | Should -HaveCount 8

            $RiskySPs[1].DisplayName | Should -Match "Test SP 2"
            $RiskySPs[1].KeyCredentials | Should -HaveCount 1
            $RiskySPs[1].PasswordCredentials | Should -BeNullOrEmpty
            $RiskySPs[1].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[1].RiskyPermissions | Should -HaveCount 8

            $RiskySPs[2].DisplayName | Should -Match "Test SP 3"
            $RiskySPs[2].KeyCredentials | Should -BeNullOrEmpty
            $RiskySPs[2].PasswordCredentials | Should -BeNullOrEmpty
            $RiskySPs[2].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[2].RiskyPermissions | Should -HaveCount 8

            $RiskySPs[3].DisplayName | Should -Match "Test SP 4"
            $RiskySPs[3].KeyCredentials | Should -BeNullOrEmpty
            $RiskySPs[3].PasswordCredentials | Should -HaveCount 2
            $RiskySPs[3].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[3].RiskyPermissions | Should -HaveCount 8

            $RiskySPs[4].DisplayName | Should -Match "Test SP 5"
            $RiskySPs[4].KeyCredentials | Should -HaveCount 1
            $RiskySPs[4].PasswordCredentials | Should -BeNullOrEmpty
            $RiskySPs[4].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[4].RiskyPermissions | Should -HaveCount 8
        }

        It "excludes service principals with no risky permissions" {
            Mock Get-MgBetaServicePrincipal { $MockServicePrincipals }
            # Set to $SafePermissions instead of $MockServicePrincipalAppRoleAssignments
            # to simulate service principals assigned to safe permissions
            Mock Get-MgBetaServicePrincipalAppRoleAssignment { $MockSafePermissions }

            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
            $RiskySPs | Should -BeNullOrEmpty
        }

        It "excludes permissions not included in the RiskyPermissions.json mapping" {
            $MockServicePrincipalAppRoleAssignments += $MockSafePermissions
            $MockServicePrincipalAppRoleAssignments | Should -HaveCount 11

            Mock Get-MgBetaServicePrincipal { $MockServicePrincipals }
            Mock Get-MgBetaServicePrincipalAppRoleAssignment { $MockServicePrincipalAppRoleAssignments }

            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
            $RiskySPs[0].RiskyPermissions | Should -HaveCount 8
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}