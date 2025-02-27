BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Permissions' -resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'PermissionsHelper.psm1') -Force
}

InModuleScope PermissionsHelper {
    Describe -Tag 'PermissionsHelper' -Name "Get-ScubaGearPermissions" {
        BeforeAll {

            Mock -ModuleName PermissionsHelper Get-ScubaGearPermissions -MockWith {
                param ($Product)
                    [string]$ResourceRoot = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]
                    $permissionSet = Get-Content -Path "$($ResourceRoot)/../../../../Modules/Permissions/ScubaGearPermissions.json" | ConvertFrom-Json
                    $collection = $permissionSet | Where-Object { $_.scubaGearProduct -contains $product -and $_.supportedEnv -contains "commercial" }
                    $results = $collection | Where-Object {$_.moduleCmdlet -notlike 'Connect-Mg*'} | Select-Object -ExpandProperty leastPermissions -Unique | sort-object
                    return $results
            }
        }

        Context "Check Graph permissions for aad" {
            It "should return the expected value from Get-ScubaGearPermissions for aad" {
                $expected = @(
                    "Application.Read.All"
                    "Directory.Read.All"
                    "Domain.Read.All"
                    "GroupMember.Read.All"
                    "Organization.Read.All"
                    "Policy.Read.All"
                    "PrivilegedAccess.Read.AzureADGroup"
                    "PrivilegedEligibilitySchedule.Read.AzureADGroup"
                    "RoleAssignmentSchedule.Read.Directory"
                    "RoleEligibilitySchedule.Read.Directory"
                    "RoleManagement.Read.Directory"
                    "RoleManagementPolicy.Read.AzureADGroup"
                    "RoleManagementPolicy.Read.Directory"
                    "User.Read.All"
                )
                $result = Get-ScubaGearPermissions -Product aad
                $result | Should -Be $expected
            }
        }

        Context "Check Graph permissions for sharepoint" {
            It "should return the expected value from Get-ScubaGearPermissions for sharepoint" {
                $expected = @(
                    "Sites.FullControl.All"
                )
                $result = Get-ScubaGearPermissions -Product sharepoint -servicePrincipal
                $result | Should -Be $expected
            }
        }

        Context "Check Graph permissions for exo" {
            It "should return the expected value from Get-ScubaGearPermissions for exo" {
                $expected = @(
                    "Exchange.ManageAsApp"
                )
                $result = Get-ScubaGearPermissions -Product exo -servicePrincipal
                $result | Should -Be $expected
            }
        }
    }
}

InModuleScope PermissionsHelper {
    Describe -Tag 'PermissionsHelper' -Name "Get-ScubaGearEntraMinimumPermissions" {
        BeforeAll {

            Mock -ModuleName PermissionsHelper Get-ScubaGearEntraMinimumPermissions -MockWith {
                # Create a list to hold the filtered permissions
                $filteredPermissions = @()

                # get all modules with least and higher permissions
                $allPermissions = Get-ScubaGearPermissions -Product aad -OutAs all

                # Compare the permissions to find the redundant ones
                $comparedPermissions = Compare-Object $allPermissions.leastPermissions $allPermissions.higherPermissions -IncludeEqual

                # filter to get the higher overwriting permissions
                $OverwriteHigherPermissions = $comparedPermissions | Where-Object {$_.SideIndicator -eq "=="} | Select-Object -ExpandProperty InputObject -Unique

                # loop thru each module and grab the least permissions unless the higher permissions is one from the $overriteHigherPermissions
                # Don't include the least permissions that are overwriten by the higher permissions
                foreach($permission in $allPermissions){
                    if( (Compare-Object $permission.higherPermissions -DifferenceObject $OverwriteHigherPermissions -IncludeEqual).SideIndicator -notcontains "=="){
                        $filteredPermissions += $permission
                    }
                }

                # Build a new list of permissions that includes the least permissions and the higher permissions that overwrite them
                $NewPermissions = @()
                $NewPermissions += $filteredPermissions | Select-Object -ExpandProperty leastPermissions -Unique
                # include overwrite higher permissions
                $NewPermissions += $OverwriteHigherPermissions
                $NewPermissions = $NewPermissions | Sort-Object -Unique

                # Display the filtered permissions
                return $NewPermissions
            }
        }

        Context "Check redundant permissions for aad" {
            It "should return the expected value from Get-ScubaGearEntraMinimumPermissions for aad" {
                $expected = @(
                    "Directory.Read.All"
                    "Policy.Read.All"
                    "PrivilegedAccess.Read.AzureADGroup"
                    "PrivilegedEligibilitySchedule.Read.AzureADGroup"
                    "RoleManagement.Read.Directory"
                    "RoleManagementPolicy.Read.AzureADGroup"
                    "User.Read.All"
                )
                $result = Get-ScubaGearEntraMinimumPermissions
                $result | Should -Be $expected
            }
        }

        AfterAll {
            Remove-Module PermissionsHelper -Force -ErrorAction SilentlyContinue
        }
    }
}