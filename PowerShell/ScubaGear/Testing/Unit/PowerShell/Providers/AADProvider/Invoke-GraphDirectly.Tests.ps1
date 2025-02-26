$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Invoke-GraphDirectly' -Force

$ProviderPath = '../../../../../Modules/Permissions'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/PermissionsHelper.psm1") -Function 'Get-ScubaGearPermissions' -Force

InModuleScope ExportAADProvider {
    Describe -Tag 'AADProvider' -Name "Invoke-GraphDirectly" {
        BeforeAll {

            Mock -ModuleName ExportAADProvider Invoke-GraphDirectly -MockWith {
                param ($Commandlet, $M365Environment)
                    return (Get-ScubaGearPermissions -CmdletName $Commandlet -OutAs api -Environment $M365Environment)
            }
        }

        Context "when M365Environment is commercial" {
            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/roleManagement/directory/roleEligibilityScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPrivilegedAccessResource" {
                $expected = "https://graph.microsoft.com/beta/privilegedAccess/aadGroups/resources"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPrivilegedAccessResource" -M365Environment "commercial"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment "commercial"
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
                $expected = "https://graph.microsoft.com/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPrivilegedAccessResource" {
                $expected = "https://graph.microsoft.com/beta/privilegedAccess/aadGroups/resources"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPrivilegedAccessResource" -M365Environment "gcc"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" {
                $expected = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment "gcc"
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
                $expected = "https://graph.microsoft.us/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPrivilegedAccessResource" {
                $expected = "https://graph.microsoft.us/beta/privilegedAccess/aadGroups/resources"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPrivilegedAccessResource" -M365Environment "gcchigh"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" {
                $expected = "https://graph.microsoft.us/beta/roleManagement/directory/roleAssignmentScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment "gcchigh"
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
                $expected = "https://dod-graph.microsoft.us/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaPrivilegedAccessResource" {
                $expected = "https://dod-graph.microsoft.us/beta/privilegedAccess/aadGroups/resources"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPrivilegedAccessResource" -M365Environment "dod"
                $result | Should -Be $expected
            }

            It "should return the expected value from Invoke-GraphDirectly for Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" {
                $expected = "https://dod-graph.microsoft.us/beta/roleManagement/directory/roleAssignmentScheduleInstances"
                $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment "dod"
                $result | Should -Be $expected
            }
        }

        AfterAll {
            Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
            Remove-Module PermissionsHelper -Force -ErrorAction SilentlyContinue
        }
    }
}