$ModulesPath = "../../../../Modules"
$ServicePrincipalModule = "$($ModulesPath)/Support/ServicePrincipal.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ServicePrincipalModule)

InModuleScope ServicePrincipal {
    Describe "Set-ScubaGearAppPermission" {
        BeforeAll {
            Mock -CommandName Connect-GraphHelper -MockWith {
                return $null
            }
        }

        It "Verify no changes are needed for optimal permissions" {
            $OptimalInputObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockOptimalPermissions.json") | ConvertFrom-Json
            $Optimal = $OptimalInputObject | Set-ScubaGearAppPermission -WhatIf
            $Optimal | Should -Be "No changes needed - service principal is already configured correctly."
        }

        It "Verify changes would be made if missing permissions are detected" {
            $MissingPermissionObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockMissingPermission.json") | ConvertFrom-Json
            $MissingPermissionObject.MissingPermissions.Permission = 'Policy.Read.All'
            $Result = $MissingPermissionObject | Set-ScubaGearAppPermission -WhatIf
            $Result[0] | Should -Be 'WhatIf: Would add missing permissions: Policy.Read.All'
        }

        Context "No Current Permissions Tests" {
            BeforeAll {
                # Mock Get-ScubaGearPermissions for delegated permissions removal
                Mock -CommandName Get-ScubaGearPermissions -MockWith {
                    param($outAs, $id)
                    if ($outAs -eq 'api') {
                        return "https://graph.microsoft.com/v1.0/servicePrincipals/$id/oauth2PermissionGrants"
                    }
                    return $null
                }

                # Mock Invoke-GraphDirectly for role definition lookup (if MissingRoles exists)
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $queryParams)

                    if ($Commandlet -eq 'Get-MgRoleManagementDirectoryRoleDefinition' -and $queryParams) {
                        return [PSCustomObject]@{
                            Value = @(
                                [PSCustomObject]@{
                                    IsBuiltIn = $true
                                    DisplayName = "Global Reader"
                                    TemplateId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                    Id = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                }
                            )
                        }
                    }
                    return $null
                }
            }

            It "Verify needed permissions would be added, unneeded delegated permissions removed, Global Reader role added, and power platform registered" {
                $NoCurrentPermissionsObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockNoCurrentPermissions.json") | ConvertFrom-Json
                $Result = $NoCurrentPermissionsObject | Set-ScubaGearAppPermission -WhatIf

                # Verify the message contains expected delegated permissions removal
                $Result[0] | Should -Be "WhatIf: Would remove delegated permissions: User.Read"

                # Verify the message contains expected missing permissions
                $Result[1] | Should -Be "WhatIf: Would add missing permissions: PrivilegedAccess.Read.AzureADGroup, Policy.Read.All, PrivilegedEligibilitySchedule.Read.AzureADGroup, RoleManagementPolicy.Read.AzureADGroup, Directory.Read.All, RoleManagement.Read.Directory, User.Read.All, Exchange.ManageAsApp, Sites.FullControl.All"

                # Verify the correct role is assigned
                $Result[2] | Should -Be "WhatIf: Would assign directory role 'Global Reader' to 00000000-0000-0000-0000-000000000001"

                # Verify that Power Platform registration is handled
                $Result[3] | Should -Be "WhatIf: Would register application with Power Platform"
            }
        }

        Context "Missing Roles Tests" {
            BeforeAll {
                # Mock only the functions needed for role assignment tests
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $queryParams)

                    if ($Commandlet -eq 'Get-MgRoleManagementDirectoryRoleDefinition' -and $queryParams) {
                        # Mock role definition lookup - return structure that matches Graph API
                        # The real API returns an object with a Value property containing an array
                        return [PSCustomObject]@{
                            Value = @(
                                [PSCustomObject]@{
                                    IsBuiltIn = $true
                                    DisplayName = "Global Reader"
                                    TemplateId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                    RolePermissions = @(@{
                                        Condition = $null
                                        AllowedResourceActions = @()
                                    })
                                    Version = "1"
                                    Id = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                    Description = ""
                                    IsEnabled = $true
                                    InheritsPermissionsFrom = @(@{Id = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b"})
                                    ResourceScopes = @("/")
                                }
                            )
                        }
                    }
                    return $null
                }
            }

            It "Verify changes would be made if missing roles are detected" {
                $MissingRoleObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockMissingRole.json") | ConvertFrom-Json
                $MissingRoleObject.MissingRoles = 'Global Reader'
                $Result = $MissingRoleObject | Set-ScubaGearAppPermission -WhatIf
                $Result[0] | Should -Match "WhatIf: Would assign directory role 'Global Reader' to 00000000-0000-0000-0000-000000000001"
            }
        }

        Context "Extra Permissions Tests" {

            It "Verify changes would be made if extra permissions are detected" {
                $ExtraPermissionObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockExtraPermissions.json") | ConvertFrom-Json
                $ExtraPermissionInputObject = $ExtraPermissionObject
                $Result = $ExtraPermissionInputObject | Set-ScubaGearAppPermission -WhatIf
                $Result[0] | Should -Be "WhatIf: Would remove extra permissions: Acronym.Read.All"
            }
        }

        Context "Power Platform Registration Tests" {

            It "Verify Power Platform would be removed when registered but not needed" {
                $PowerPlatformUnneededObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformUnneeded.json") | ConvertFrom-Json
                $Result = $PowerPlatformUnneededObject | Set-ScubaGearAppPermission -WhatIf
                $Result[0] | Should -Be "WhatIf: Would remove Power Platform registration"
            }

            It "Verify Power Platform would be registered when needed but missing" {
                $PowerPlatformNeededObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformNeeded.json") | ConvertFrom-Json
                $Result = $PowerPlatformNeededObject | Set-ScubaGearAppPermission -WhatIf
                $Result[0] | Should -Be "WhatIf: Would register application with Power Platform"
            }
        }

        Context "Multiple Issues Tests" {
            BeforeAll {
                $MultipleIssuesObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockMultipleIssues.json") | ConvertFrom-Json

                # Mock all functions needed for multiple issues scenario
                Mock -CommandName Get-ScubaGearPermissions -MockWith {
                    param($outAs, $id)
                    if ($outAs -eq 'api') {
                        return "https://graph.microsoft.com/v1.0/servicePrincipals/$id/appRoleAssignments"
                    }
                    return $null
                }

                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $queryParams)

                    if ($Commandlet -eq 'Get-MgBetaApplication') {
                        return $MultipleIssuesObject.ExtraPermissions
                    }
                    elseif ($Commandlet -eq 'Update-MgBetaApplication') {
                        return $null
                    }
                    elseif ($Commandlet -eq 'Get-MgRoleManagementDirectoryRoleDefinition' -and $queryParams) {
                        return [PSCustomObject]@{
                            Value = @(
                                [PSCustomObject]@{
                                    Id = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                    DisplayName = "Global Reader"
                                }
                            )
                        }
                    }
                    return $null
                }
            }

            It "Verify multiple issues are detected and reported" {
                $MultipleIssuesInputObject = $MultipleIssuesObject
                $Result = $MultipleIssuesInputObject | Set-ScubaGearAppPermission -WhatIf

                # Verify all expected messages are present
                $Result[0] | Should -Be "WhatIf: Would remove extra permissions: Acronym.Read.All"
                $Result[1] | Should -Be "WhatIf: Would add missing permissions: Policy.Read.All"
                $Result[2] | Should -Be "WhatIf: Would assign directory role 'Global Reader' to 00000000-0000-0000-0000-000000000001"
            }
        }

        Context "Handle permissions in App Registration Manifest that are not granted admin consent" {

            It "Verify permissions in manifest that only need to be granted admin consent" {
                $MissingAdminConsentPermissionsObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockManifestMissingAdminConsent.json") | ConvertFrom-Json
                $Result = $MissingAdminConsentPermissionsObject | Set-ScubaGearAppPermission -WhatIf

                # Verify expected message is present
                $Result[0] | Should -Be "WhatIf: Would add missing permissions: User.Read.All, Exchange.ManageAsApp"
            }
        }

        Context "Verify both exchange permissions are present in GCC High environments" {

            It "Verify Microsoft Exchange Online Protection Exchange.ManageAsApp permission is handled correctly in GCC High" {
                $MissingAdminConsentPermissionsObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockMissingGCCHighExoPermission.json") | ConvertFrom-Json
                $Result = $MissingAdminConsentPermissionsObject | Set-ScubaGearAppPermission -WhatIf

                # Verify expected message is present
                $Result[0] | Should -Be "WhatIf: Would add missing permissions: Exchange.ManageAsApp"
            }
        }
    }
}

AfterAll {
    Remove-Module ServicePrincipal -Force -ErrorAction 'SilentlyContinue'
}