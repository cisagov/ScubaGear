BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Permissions' -resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'PermissionsHelper.psm1') -Force
}

InModuleScope PermissionsHelper {
    Describe -Tag 'PermissionsHelper' -Name "Get-ScubaGearPermissions" {

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

InModuleScope PermissionsHelper {
    Describe -Tag 'PermissionsHelper' -Name "Get-ScubaGearPermissions - securitysuite" {

        Context "Check service principal API permissions for securitysuite (commercial)" {
            It "should return Exchange.ManageAsApp for securitysuite commercial" {
                $expected = @(
                    "Exchange.ManageAsApp"
                )
                $result = Get-ScubaGearPermissions -Product securitysuite -ServicePrincipal
                $result | Should -Be $expected
            }
        }

        Context "Check service principal API permissions for securitysuite (gcchigh)" {
            It "should return Exchange.ManageAsApp for securitysuite gcchigh" {
                $result = Get-ScubaGearPermissions -Product securitysuite -ServicePrincipal -Environment gcchigh
                $result | Should -Contain "Exchange.ManageAsApp"
            }

            It "should include both Exchange Online and EOP resource API IDs for securitysuite gcchigh" {
                # gcchigh requires Exchange.ManageAsApp on BOTH
                #   00000002-0000-0ff1-ce00-000000000000 (Exchange Online)
                #   00000007-0000-0ff1-ce00-000000000000 (Exchange Online Protection)
                $result = Get-ScubaGearPermissions -Product securitysuite -ServicePrincipal -OutAs appId -Environment gcchigh
                $result | Should -HaveCount 2
                $result | Should -Contain "00000002-0000-0ff1-ce00-000000000000"
                $result | Should -Contain "00000007-0000-0ff1-ce00-000000000000"
            }
        }

        Context "Check role permissions for securitysuite" {
            It "should return Global Reader for securitysuite" {
                $expected = @(
                    "Global Reader"
                )
                $result = Get-ScubaGearPermissions -Product securitysuite -OutAs role
                $result | Should -Be $expected
            }
        }

        Context "Wildcard expansion includes securitysuite" {
            It "should include securitysuite permissions when -Product * is used with -ServicePrincipal" {
                $result = Get-ScubaGearPermissions -Product * -ServicePrincipal
                $result | Should -Contain "Exchange.ManageAsApp"
            }
        }
    }
}

InModuleScope PermissionsHelper {
    Describe -Tag 'PermissionsHelper' -Name "Get-ServicePrincipalPermissions - securitysuite" {

        Context "securitysuite entries are included in service principal permission table" {
            It "should return at least one row with scubaGearProduct containing securitysuite" {
                $result = Get-ServicePrincipalPermissions
                $ssRows = $result | Where-Object { $_.scubaGearProduct -contains "securitysuite" }
                $ssRows | Should -Not -BeNullOrEmpty
            }

            It "should return Exchange.ManageAsApp as leastPermissions for securitysuite" {
                $result = Get-ServicePrincipalPermissions
                $ssRows = $result | Where-Object { $_.scubaGearProduct -contains "securitysuite" }
                $ssRows.leastPermissions | Should -Contain "Exchange.ManageAsApp"
            }

            It "should reference the Office 365 Exchange Online resource API for securitysuite" {
                $result = Get-ServicePrincipalPermissions
                $ssRows = $result | Where-Object { $_.scubaGearProduct -contains "securitysuite" }
                $ssRows.resourceAPIAppId | Should -Contain "00000002-0000-0ff1-ce00-000000000000"
            }
        }

        Context "EXO service principal permissions are still present" {
            It "should still include Exchange.ManageAsApp for exo product" {
                $result = Get-ServicePrincipalPermissions
                $exoRows = $result | Where-Object { $_.scubaGearProduct -contains "exo" }
                $exoRows | Should -Not -BeNullOrEmpty
                $exoRows.leastPermissions | Should -Contain "Exchange.ManageAsApp"
            }
        }

        Context "SharePoint service principal permissions are still present" {
            It "should still include Sites.FullControl.All for sharepoint product" {
                $result = Get-ServicePrincipalPermissions
                $spRows = $result | Where-Object { $_.scubaGearProduct -contains "sharepoint" }
                $spRows | Should -Not -BeNullOrEmpty
                $spRows.leastPermissions | Should -Contain "Sites.FullControl.All"
            }
        }
    }
}