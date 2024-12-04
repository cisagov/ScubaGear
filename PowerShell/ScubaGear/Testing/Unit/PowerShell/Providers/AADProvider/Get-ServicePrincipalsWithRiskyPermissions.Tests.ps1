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
            $RiskySPs[1].DisplayName | Should -Match "Test SP 2"
            $RiskySPs[1].KeyCredentials | Should -HaveCount 1
            $RiskySPs[1].PasswordCredentials | Should -BeNullOrEmpty
            $RiskySPs[1].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[1].RiskyPermissions | Should -HaveCount 5
        }

        It "excludes service principals without any risky permissions" {
            Mock Get-MgBetaServicePrincipal { $MockServicePrincipals }
            # Set to empty list
            Mock Get-MgBetaServicePrincipalAppRoleAssignment { @() }
            
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
            $RiskySPs | Should -BeNullOrEmpty
        }

        It "excludes roles not included in the RiskyPermissions.json mapping" {
            $SafePermissions = @(
                [PSCustomObject]@{
                    AppRoleId = "2f3e6f8c-093b-4c57-a58b-ba5ce494a169" # Agreement.Read.All
                    ResourceDisplayName = "Microsoft Graph"
                }
                [PSCustomObject]@{
                    AppRoleId = "e12dae10-5a57-4817-b79d-dfbec5348930" # AppCatalog.Read.All
                    ResourceDisplayName = "Microsoft Graph"
                }
                [PSCustomObject]@{
                    AppRoleId = "be95e614-8ef3-49eb-8464-1c9503433b86" # Bookmark.Read.All
                    ResourceDisplayName = "Microsoft Graph"
                }
            )
            $MockServicePrincipalAppRoleAssignments += $SafePermissions
            $MockServicePrincipalAppRoleAssignments | Should -HaveCount 8

            Mock Get-MgBetaServicePrincipal { $MockServicePrincipals }
            Mock Get-MgBetaServicePrincipalAppRoleAssignment { $MockServicePrincipalAppRoleAssignments }
            
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
            $RiskySPs[0].RiskyPermissions | Should -HaveCount 5
        }
    }
}