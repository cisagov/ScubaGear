$ProviderPath = '../../../../../Modules/Utility'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/Utility.psm1") -Function 'Invoke-GraphDirectly' -Force

InModuleScope Utility {
    $ProviderPath = '../../../../../Modules/Permissions'
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/PermissionsHelper.psm1") -Function 'Get-ScubaGearPermissions' -Force

    Describe -Tag 'Utility' -Name "Invoke-GraphDirectly" {
        BeforeAll {

            Mock -ModuleName Utility Invoke-GraphDirectly -MockWith {
                param ($Commandlet, $M365Environment, $ID)
                    if(-not $ID){
                        return (Get-ScubaGearPermissions -CmdletName $Commandlet -OutAs api -Environment $M365Environment)
                    }else{
                        return (Get-ScubaGearPermissions -CmdletName $Commandlet -OutAs api -Environment $M365Environment -ID $ID)
                    }
            }
            $ID = New-Guid
        }

        Context "when M365Environment is commercial" {
            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/roleManagement/directory/roleEligibilityScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances/?`$filter=groupId eq '$ID'"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment "commercial" -id $ID
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPrivilegedAccessResource" {
                $expected = "https://graph.microsoft.com/beta/privilegedAccess/aadGroups/resources"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPrivilegedAccessResource" -M365Environment "commercial" -Id "aadGroups"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaIdentityConditionalAccessPolicy" {
                $expected = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityConditionalAccessPolicy" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaUserCount" {
                $expected = "https://graph.microsoft.com/beta/users/`$count"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaUserCount" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyAuthorizationPolicy" {
                $expected = "https://graph.microsoft.com/beta/policies/authorizationPolicy"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyAuthorizationPolicy" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyAuthenticationMethodPolicy" {
                $expected = "https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyAuthenticationMethodPolicy" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaUser" {
                $expected = "https://graph.microsoft.com/beta/users/"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaUser" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaGroupMember" {
                $expected = "https://graph.microsoft.com/beta/groups/$ID/members"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaGroupMember" -M365Environment "commercial" -id $ID
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyRoleManagementPolicyAssignment" {
                $expected = "https://graph.microsoft.com/beta/policies/roleManagementPolicyAssignments"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyAssignment" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyRoleManagementPolicyRule" {
                $expected = "https://graph.microsoft.com/beta/policies/roleManagementPolicies/$ID/rules"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyRule" -M365Environment "commercial" -id $ID
                $result | Should -Be $expected
            }
        }

        Context "when M365Environment is gcc" {
            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/roleManagement/directory/roleEligibilityScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances/?`$filter=groupId eq '$ID'"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment "gcc" -id $ID
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPrivilegedAccessResource" {
                $expected = "https://graph.microsoft.com/beta/privilegedAccess/aadGroups/resources"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPrivilegedAccessResource" -M365Environment "gcc" -id "aadGroups"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaIdentityConditionalAccessPolicy" {
                $expected = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityConditionalAccessPolicy" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaUserCount" {
                $expected = "https://graph.microsoft.com/beta/users/`$count"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaUserCount" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyAuthorizationPolicy" {
                $expected = "https://graph.microsoft.com/beta/policies/authorizationPolicy"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyAuthorizationPolicy" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyAuthenticationMethodPolicy" {
                $expected = "https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyAuthenticationMethodPolicy" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaUser" {
                $expected = "https://graph.microsoft.com/beta/users/"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaUser" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaGroupMember" {
                $expected = "https://graph.microsoft.com/beta/groups/$ID/members"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaGroupMember" -M365Environment "gcc" -id $ID
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyRoleManagementPolicyAssignment" {
                $expected = "https://graph.microsoft.com/beta/policies/roleManagementPolicyAssignments"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyAssignment" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyRoleManagementPolicyRule" {
                $expected = "https://graph.microsoft.com/beta/policies/roleManagementPolicies/$ID/rules"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyRule" -M365Environment "gcc" -id $ID
                $result | Should -Be $expected
            }
        }

        Context "when M365Environment is gcchigh" {
            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" {
                $expected = "https://graph.microsoft.us/beta/roleManagement/directory/roleEligibilityScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" {
                $expected = "https://graph.microsoft.us/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances/?`$filter=groupId eq '$ID'"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment "gcchigh" -id $ID
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPrivilegedAccessResource" {
                $expected = "https://graph.microsoft.us/beta/privilegedAccess/aadGroups/resources"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPrivilegedAccessResource" -M365Environment "gcchigh" -id "aadGroups"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" {
                $expected = "https://graph.microsoft.us/beta/roleManagement/directory/roleAssignmentScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaIdentityConditionalAccessPolicy" {
                $expected = "https://graph.microsoft.us/beta/identity/conditionalAccess/policies"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityConditionalAccessPolicy" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaUserCount" {
                $expected = "https://graph.microsoft.us/beta/users/`$count"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaUserCount" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyAuthorizationPolicy" {
                $expected = "https://graph.microsoft.us/beta/policies/authorizationPolicy"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyAuthorizationPolicy" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyAuthenticationMethodPolicy" {
                $expected = "https://graph.microsoft.us/beta/policies/authenticationMethodsPolicy"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyAuthenticationMethodPolicy" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaUser" {
                $expected = "https://graph.microsoft.us/beta/users/"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaUser" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaGroupMember" {
                $expected = "https://graph.microsoft.us/beta/groups/$ID/members"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaGroupMember" -M365Environment "gcchigh" -id $ID
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyRoleManagementPolicyAssignment" {
                $expected = "https://graph.microsoft.us/beta/policies/roleManagementPolicyAssignments"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyAssignment" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyRoleManagementPolicyRule" {
                $expected = "https://graph.microsoft.us/beta/policies/roleManagementPolicies/$ID/rules"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyRule" -M365Environment "gcchigh" -id $ID
                $result | Should -Be $expected
            }
        }

        Context "when M365Environment is dod" {
            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" {
                $expected = "https://dod-graph.microsoft.us/beta/roleManagement/directory/roleEligibilityScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" {
                $expected = "https://dod-graph.microsoft.us/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances/?`$filter=groupId eq '$ID'"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment "dod" -id $ID
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPrivilegedAccessResource" {
                $expected = "https://dod-graph.microsoft.us/beta/privilegedAccess/aadGroups/resources"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPrivilegedAccessResource" -M365Environment "dod" -id "aadGroups"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" {
                $expected = "https://dod-graph.microsoft.us/beta/roleManagement/directory/roleAssignmentScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaIdentityConditionalAccessPolicy" {
                $expected = "https://dod-graph.microsoft.us/beta/identity/conditionalAccess/policies"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityConditionalAccessPolicy" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaUserCount" {
                $expected = "https://dod-graph.microsoft.us/beta/users/`$count"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaUserCount" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyAuthorizationPolicy" {
                $expected = "https://dod-graph.microsoft.us/beta/policies/authorizationPolicy"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyAuthorizationPolicy" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyAuthenticationMethodPolicy" {
                $expected = "https://dod-graph.microsoft.us/beta/policies/authenticationMethodsPolicy"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyAuthenticationMethodPolicy" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaUser" {
                $expected = "https://dod-graph.microsoft.us/beta/users/"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaUser" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaGroupMember" {
                $expected = "https://dod-graph.microsoft.us/beta/groups/$ID/members"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaGroupMember" -M365Environment "dod" -id $ID
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyRoleManagementPolicyAssignment" {
                $expected = "https://dod-graph.microsoft.us/beta/policies/roleManagementPolicyAssignments"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyAssignment" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPolicyRoleManagementPolicyRule" {
                $expected = "https://dod-graph.microsoft.us/beta/policies/roleManagementPolicies/$ID/rules"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyRule" -M365Environment "dod" -id $ID
                $result | Should -Be $expected
            }
        }

        AfterAll {
            Remove-Module Utility -Force -ErrorAction SilentlyContinue
            Remove-Module PermissionsHelper -Force -ErrorAction SilentlyContinue
        }
    }
}