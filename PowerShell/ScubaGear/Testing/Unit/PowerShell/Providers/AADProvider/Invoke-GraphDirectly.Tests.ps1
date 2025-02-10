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

        It "should return the expected value from Invoke-GraphDirectly" {
            $expected = "https://graph.microsoft.com/beta/roleManagement/directory/roleEligibilityScheduleInstances"
            $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" -M365Environment "commercial"
            $result | Should -Be $expected
        }

        It "should return the expected value from Invoke-GraphDirectly" {
            $expected = "https://graph.microsoft.com/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances"
            $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment "commercial"
            $result | Should -Be $expected
        }

        It "should return the expected value from Invoke-GraphDirectly" {
            $expected = "https://graph.microsoft.com/beta/privilegedAccess/aadGroups/resources"
            $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaPrivilegedAccessResource" -M365Environment "commercial"
            $result | Should -Be $expected
        }

        It "should return the expected value from Invoke-GraphDirectly" {
            $expected = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentScheduleInstances"
            $result = Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment "commercial"
            $result | Should -Be $expected
        }

        AfterAll {
            Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
            Remove-Module PermissionsHelper -Force -ErrorAction SilentlyContinue
        }
    }
}