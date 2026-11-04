$ModulesPath = "../../../../Modules"
$ServicePrincipalModule = "$($ModulesPath)/Support/ServicePrincipal.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ServicePrincipalModule)

InModuleScope ServicePrincipal {
    Describe "Get-ServicePrincipalMemberGroupIds" {
        It "batches membership checks into requests of at most 20 group IDs" {
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Uri, $Method, $Body)
                $RequestBody = $Body | ConvertFrom-Json
                if ($Method -ne 'POST' -or
                    $Uri -ne 'https://graph.microsoft.us/v1.0/servicePrincipals/service-principal-id/checkMemberGroups' -or
                    @($RequestBody.groupIds).Count -gt 20) {
                    throw "Unexpected checkMemberGroups request."
                }
                return @{ value = @($RequestBody.groupIds) }
            }

            $GroupIds = @(1..21 | ForEach-Object { "group-$_" })
            $MatchedGroupIds = @(Get-ServicePrincipalMemberGroupIds -ServicePrincipalID 'service-principal-id' `
                -GroupIds $GroupIds -M365Environment gcchigh)

            $MatchedGroupIds.Count | Should -Be 21
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 2 -Exactly
        }

        It "throws when the Graph response does not contain membership results" {
            Mock -CommandName Invoke-GraphDirectly -MockWith { return @{ unexpected = @() } }

            {
                Get-ServicePrincipalMemberGroupIds -ServicePrincipalID 'service-principal-id' `
                    -GroupIds @('group-id') -M365Environment commercial
            } | Should -Throw '*checkMemberGroups response did not contain a valid value*'
        }

        It "accepts an empty membership result" {
            Mock -CommandName Invoke-GraphDirectly -MockWith { return [PSCustomObject]@{ value = @() } }

            $MatchedGroupIds = @(Get-ServicePrincipalMemberGroupIds -ServicePrincipalID 'service-principal-id' `
                -GroupIds @('group-id') -M365Environment commercial)

            $MatchedGroupIds.Count | Should -Be 0
        }

        It "propagates a Graph request failure" {
            Mock -CommandName Invoke-GraphDirectly -MockWith { throw 'Network unreachable' }

            {
                Get-ServicePrincipalMemberGroupIds -ServicePrincipalID 'service-principal-id' `
                    -GroupIds @('group-id') -M365Environment commercial
            } | Should -Throw '*Network unreachable*'
        }
    }

    Describe "Set-PowerBIAppRegistration catalog endpoints" {
        BeforeAll {
            $script:PowerBITestAppId = '11111111-1111-1111-1111-111111111111'
            $script:PowerBITestSpId = '22222222-2222-2222-2222-222222222222'
            $script:PowerBITestGroupId = '33333333-3333-3333-3333-333333333333'
        }

        BeforeEach {
            Mock -CommandName Get-PowerBIAdminToken -MockWith {
                return [PSCustomObject]@{ BaseUrl = 'https://example.test'; AccessToken = 'token' }
            }
            Mock -CommandName Get-PowerBITenantSettingsRest -MockWith {
                return [PSCustomObject]@{
                    tenantSettings = @([PSCustomObject]@{
                        settingName = 'AllowServicePrincipalsUseReadAdminAPIs'
                        enabled = $true
                        enabledSecurityGroups = @([PSCustomObject]@{
                            graphId = $script:PowerBITestGroupId
                            name = 'Test group'
                        })
                    })
                }
            }
        }

        It "uses the catalog path with both IDs and the reference suffix when removing membership" {
            $script:PowerBITestCheckCount = 0
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith {
                $script:PowerBITestCheckCount++
                if ($script:PowerBITestCheckCount -eq 1) { return $script:PowerBITestGroupId }
            }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet, $Method)
                if ($Commandlet -eq 'Get-MgBetaGroupMember') {
                    return [PSCustomObject]@{
                        Value = @([PSCustomObject]@{ Id = $script:PowerBITestSpId })
                    }
                }
                if ($Method -ne 'DELETE') { throw 'Unexpected Graph request.' }
            }

            Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId -ServicePrincipalID $script:PowerBITestSpId `
                -TenantId 'tenant-id' -M365Environment commercial -Remove -Confirm:$false

            Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'DELETE' -and
                $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestGroupId)/members/$($script:PowerBITestSpId)/`$ref"
            }
        }

        It "does not make changes when allowed-group membership cannot be checked" {
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { throw 'Network unreachable' }
            Mock -CommandName Invoke-GraphDirectly -MockWith {}

            {
                Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId -ServicePrincipalID $script:PowerBITestSpId `
                    -TenantId 'tenant-id' -M365Environment commercial -Force -Confirm:$false
            } | Should -Throw '*Unable to verify Power BI allowed-group membership*'

            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
        }

        It "displays interactive group choices on the information stream, not the success stream" {
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                [PSCustomObject]@{ Value = @() }
            } -ParameterFilter { $Commandlet -eq 'Get-MgBetaGroupMember' }
            Mock -CommandName Read-Host -MockWith { '1' }

            $Output = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -WhatIf -InformationVariable MenuInformation

            $MenuText = @($MenuInformation | ForEach-Object { $_.MessageData }) -join "`n"
            $MenuText | Should -Match "Power BI tenant setting 'Service principals can access read-only admin APIs'"
            $MenuText | Should -Match 'Test group \(ID: 33333333-3333-3333-3333-333333333333\)'
            $MenuText | Should -Match 'Create a new dedicated security group'
            ($Output -join "`n") | Should -Not -Match "currently enabled for the following security group|  \[1\] Test group \(ID:"
            ($Output -join "`n") | Should -Not -Match "Create a new dedicated security group and append it"
            Should -Invoke -CommandName Read-Host -Times 1 -Exactly
        }
    }

    Describe "Power Platform registration catalog endpoints" {
        BeforeEach {
            Mock -CommandName Get-PowerPlatformAdminToken -MockWith {
                return [PSCustomObject]@{ BaseUrl = 'https://example.test'; AccessToken = 'token' }
            }
        }

        It "uses the catalog path for registration and removal" {
            Mock -CommandName Invoke-ScubaRestMethod -MockWith {}
            $AppId = '11111111-1111-1111-1111-111111111111'

            Set-PowerPlatformAppRegistration -AppID $AppId -TenantId 'tenant-id' -M365Environment commercial
            Set-PowerPlatformAppRegistration -AppID $AppId -TenantId 'tenant-id' -M365Environment commercial -Remove

            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'PUT' -and $Endpoint -eq '/providers/Microsoft.BusinessAppPlatform/adminApplications/11111111-1111-1111-1111-111111111111?api-version=2020-10-01'
            }
            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'DELETE' -and $Endpoint -eq '/providers/Microsoft.BusinessAppPlatform/adminApplications/11111111-1111-1111-1111-111111111111?api-version=2020-10-01'
            }
        }

        It "uses the catalog path when checking registrations" {
            Mock -CommandName Invoke-ScubaRestMethod -MockWith {
                return [PSCustomObject]@{ value = @([PSCustomObject]@{
                    applicationId = '11111111-1111-1111-1111-111111111111'
                }) }
            }

            Test-PowerPlatformAppRegistration -AppID '11111111-1111-1111-1111-111111111111' `
                -TenantId 'tenant-id' -M365Environment commercial | Should -BeTrue

            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq '/providers/Microsoft.BusinessAppPlatform/adminApplications?api-version=2020-10-01'
            }
        }
    }

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
                $Result[1] | Should -Be "WhatIf: Would add missing permissions: Policy.Read.All, PrivilegedEligibilitySchedule.Read.AzureADGroup, RoleManagementPolicy.Read.AzureADGroup, Directory.Read.All, RoleManagement.Read.Directory, User.Read.All, Exchange.ManageAsApp, Sites.FullControl.All"

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

        Context "Unneeded directory role assignment tests" {
            BeforeEach {
                $script:UnneededRoleInput = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformUnneeded.json") | ConvertFrom-Json
                $script:UnneededRoleInput.ProductNames = @('aad')
                $script:UnneededRoleInput.MissingRoles = $false
                $script:UnneededRoleInput.PowerPlatformRegistered = $false
                $script:UnneededRoleInput | Add-Member -MemberType NoteProperty -Name PowerBIRegistered -Value $false -Force
                $script:UnneededRoleInput | Add-Member -MemberType NoteProperty -Name PowerBIGroupMembership -Value $false -Force
                $script:UnneededRoleInput | Add-Member -MemberType NoteProperty -Name ExtraRoles -Value @([PSCustomObject]@{
                    RoleName = 'Global Reader'
                    RoleDefinitionId = 'global-reader-role-id'
                    AssignmentId = 'global-reader-assignment-id'
                }) -Force
            }

            It "previews <RoleName> removal without issuing a Graph delete under WhatIf" -ForEach @(
                @{ RoleName = 'Global Reader' }
                @{ RoleName = 'Global Administrator' }
                @{ RoleName = 'Custom Audit Role' }
            ) {
                param($RoleName)
                $script:UnneededRoleInput.ExtraRoles[0].RoleName = $RoleName
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw "WhatIf must not issue a Graph request."
                }

                $result = $script:UnneededRoleInput | Set-ScubaGearAppPermission -WhatIf

                $result | Should -Contain "WhatIf: Would remove unneeded directory role '$RoleName' from 00000000-0000-0000-0000-000000000001"
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
            }

            It "deletes the <RoleName> assignment through the catalog-backed Graph command" -ForEach @(
                @{ RoleName = 'Global Reader' }
                @{ RoleName = 'Global Administrator' }
                @{ RoleName = 'Custom Audit Role' }
            ) {
                param($RoleName)
                $script:UnneededRoleInput.ExtraRoles[0].RoleName = $RoleName
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $id, $M365Environment)
                    if ($Commandlet -ne 'Remove-MgRoleManagementDirectoryRoleAssignment' -or
                        $id -ne 'global-reader-assignment-id' -or
                        $M365Environment -ne 'commercial') {
                        throw "Unexpected Graph request."
                    }
                }

                $result = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and
                    $id -eq 'global-reader-assignment-id' -and
                    $M365Environment -eq 'commercial'
                }
                $result | Should -Contain "Removed unneeded directory role assignment: $RoleName"
            }

            It "preserves Global Reader when a selected product still requires it" {
                $script:UnneededRoleInput.ProductNames = @('aad', 'exo')
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw "Global Reader is still required and must not be deleted."
                }

                $result = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
                $result | Should -Not -Contain 'Removed unneeded directory role assignment: Global Reader'
            }

            It "deletes each unneeded Global Reader assignment by its own assignment ID" {
                $script:UnneededRoleInput.ExtraRoles = @(
                    [PSCustomObject]@{
                        RoleName = 'Global Reader'
                        RoleDefinitionId = 'global-reader-role-id'
                        AssignmentId = 'first-assignment-id'
                    }
                    [PSCustomObject]@{
                        RoleName = 'Global Reader'
                        RoleDefinitionId = 'global-reader-role-id'
                        AssignmentId = 'second-assignment-id'
                    }
                )
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $id)
                    if ($Commandlet -ne 'Remove-MgRoleManagementDirectoryRoleAssignment' -or
                        $id -notin @('first-assignment-id', 'second-assignment-id')) {
                        throw 'Unexpected Graph request.'
                    }
                }

                $null = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and $id -eq 'first-assignment-id'
                }
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and $id -eq 'second-assignment-id'
                }
            }

            It "removes unneeded roles while preserving a required role in the same input" {
                $script:UnneededRoleInput.ProductNames = @('aad', 'exo')
                $script:UnneededRoleInput.ExtraRoles = @(
                    [PSCustomObject]@{
                        RoleName = 'Global Reader'
                        AssignmentId = 'reader-assignment-id'
                    }
                    [PSCustomObject]@{
                        RoleName = 'Global Administrator'
                        AssignmentId = 'admin-assignment-id'
                    }
                    [PSCustomObject]@{
                        RoleName = 'Custom Audit Role'
                        AssignmentId = 'custom-assignment-id'
                    }
                )
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $id)
                    if ($Commandlet -ne 'Remove-MgRoleManagementDirectoryRoleAssignment' -or
                        $id -notin @('admin-assignment-id', 'custom-assignment-id')) {
                        throw 'Unexpected Graph request.'
                    }
                }

                $result = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 2 -Exactly
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and $id -eq 'admin-assignment-id'
                }
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and $id -eq 'custom-assignment-id'
                }
                $result | Should -Not -Contain 'Removed unneeded directory role assignment: Global Reader'
            }

            It "preserves a required role other than Global Reader in stale pipeline data" {
                $script:UnneededRoleInput.ExtraRoles[0].RoleName = 'Custom Audit Role'
                Mock -CommandName Get-ScubaGearServicePrincipalRole -MockWith { 'Custom Audit Role' }
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw 'A required role must not be deleted.'
                }

                $null = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
            }

            It "warns and skips role removal when <PropertyName> is missing" -ForEach @(
                @{ PropertyName = 'RoleName' }
                @{ PropertyName = 'AssignmentId' }
            ) {
                param($PropertyName)
                $script:UnneededRoleInput.ExtraRoles[0].$PropertyName = $null
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw 'An incomplete role assignment must not be deleted.'
                }

                $null = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false `
                    -WarningVariable RemovalWarnings -WarningAction SilentlyContinue

                $RemovalWarnings | Should -Match 'role name or role-assignment ID is missing'
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
            }

            It "warns and skips role removal when product selection is missing" {
                $script:UnneededRoleInput.ProductNames = $null
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw 'A role must not be deleted without determining product requirements.'
                }

                $null = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false `
                    -WarningVariable RemovalWarnings -WarningAction SilentlyContinue

                $RemovalWarnings | Should -Match 'Cannot determine required directory roles without ProductNames'
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
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

            # Get-MgContext no longer exists, and this session cannot read the organization, so the tenant has to come
            # from the service principal. The -WhatIf tests above never reach this code.
            It "Removes the Power Platform registration using the service principal's tenant" {
                $PowerPlatformUnneededObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformUnneeded.json") | ConvertFrom-Json
                Mock Invoke-GraphDirectly {
                    [pscustomobject]@{ Value = [pscustomobject]@{ AppOwnerOrganizationId = '11111111-1111-1111-1111-111111111111' } }
                } -ParameterFilter { $Commandlet -eq 'Get-MgServicePrincipal' }
                Mock Set-PowerPlatformAppRegistration {}

                $Result = $PowerPlatformUnneededObject | Set-ScubaGearAppPermission -Confirm:$false -WarningVariable RemovalWarnings -WarningAction SilentlyContinue

                Should -Invoke Set-PowerPlatformAppRegistration -Times 1 -Exactly -ParameterFilter {
                    $AppID -eq '00000000-0000-0000-0000-000000000001' -and
                    $TenantId -eq '11111111-1111-1111-1111-111111111111' -and
                    $M365Environment -eq 'commercial' -and
                    $Remove
                }
                Should -Invoke Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Get-MgServicePrincipal' -and $queryParams['$filter'] -eq "id eq '00000000-0000-0000-0000-000000000002'"
                }
                $Result | Should -Contain 'Successfully removed Power Platform registration'
                $RemovalWarnings | Should -BeNullOrEmpty
            }

            It "Warns and does not remove the registration when the tenant cannot be found" {
                $PowerPlatformUnneededObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformUnneeded.json") | ConvertFrom-Json
                Mock Invoke-GraphDirectly { [pscustomobject]@{ Value = $null } } -ParameterFilter { $Commandlet -eq 'Get-MgServicePrincipal' }
                Mock Set-PowerPlatformAppRegistration {}

                $Result = $PowerPlatformUnneededObject | Set-ScubaGearAppPermission -Confirm:$false -WarningVariable RemovalWarnings -WarningAction SilentlyContinue

                Should -Invoke Set-PowerPlatformAppRegistration -Times 0
                $Result | Should -Not -Contain 'Successfully removed Power Platform registration'
                @($RemovalWarnings) -join ' ' | Should -BeLike '*Could not retrieve tenant ID*'
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