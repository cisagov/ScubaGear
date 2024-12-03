$ModulesPath = "../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module $AADRiskyPermissionsHelper

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-ServicePrincipalsWithRiskyPermissions" {
        BeforeAll {
            $PermissionsPath = (Join-Path -Path $PSScriptRoot -ChildPath "../../../../../Modules/Permissions")
            $PermissionsJson = (
                Get-Content -Path ( `
                    Join-Path -Path $PermissionsPath -ChildPath "RiskyPermissions.json" `
                ) | ConvertFrom-Json
            )
    
            # Import mock data
            . .\RiskyPermissionsSnippets/MockData.ps1
        
            function Get-MgBetaServicePrincipal { $MockServicePrincipals }
            function Get-MgBetaServicePrincipalAppRoleAssignment { $MockServicePrincipalAppRoleAssignments }
        }
        
        It "returns a list of service principals with valid properties" {
            Mock Get-MgBetaServicePrincipal { $MockServicePrincipals }
            Mock Get-MgBetaServicePrincipalAppRoleAssignment { $MockServicePrincipalAppRoleAssignments }
        
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
            Write-Output $RiskySPs > riskysptestoutput.json

            $RiskySPs | Should -HaveCount 2
            $RiskySPs[0].DisplayName | Should -Match "Test SP 1"
            $RiskySPs[0].KeyCredentials | Should -HaveCount 1
            $RiskySPs[0].PasswordCredentials | Should -HaveCount 1
            $RiskySPs[0].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[0].RiskyPermissions | Should -HaveCount 5
        }

        It "excludes service principals without any risky permissions" {

        }

        It "excludes roles not included in the RiskyPermissions.json mapping" {

        }
    }
}