$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $AADRiskyPermissionsHelper

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-ServicePrincipalsWithRiskyPermissions" {
        BeforeAll {
            # Import mock data
            . ../RiskyPermissionsSnippets/MockData.ps1
        
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
        }

        It "excludes service principals with no risky permissions" {
            Mock Get-MgBetaServicePrincipal { $MockServicePrincipals }
            # Set to $SafePermissions instead of $MockServicePrincipalAppRoleAssignments
            # to simulate service principals assigned to safe permissions
            Mock Get-MgBetaServicePrincipalAppRoleAssignment { $SafePermissions }
            
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
            $RiskySPs | Should -BeNullOrEmpty
        }

        It "excludes permissions not included in the RiskyPermissions.json mapping" {
            $MockServicePrincipalAppRoleAssignments += $SafePermissions
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