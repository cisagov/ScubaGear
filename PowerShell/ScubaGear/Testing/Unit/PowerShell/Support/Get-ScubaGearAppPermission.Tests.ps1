Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../../../Modules/Support/ServicePrincipal.psm1") -Force

InModuleScope ServicePrincipal {
    Describe "Get-ScubaGearAppPermission" {
        BeforeAll {
            # Load mock resource service principals - one for each API
            $MockResourceSP_Graph = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockResourceSP_Graph.json") | ConvertFrom-Json
            $MockResourceSP_Exchange = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockResourceSP_Exchange.json") | ConvertFrom-Json
            $MockResourceSP_SharePoint = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockResourceSP_SharePoint.json") | ConvertFrom-Json

            # Mock all external dependencies
            Mock -CommandName Connect-GraphHelper -MockWith { return $null }

            Mock -CommandName Get-ServicePrincipalPermissions -MockWith {
                return @(
                    [PSCustomObject]@{
                        leastPermissions    = @('Policy.Read.All')
                        resourceAPIAppId    = '00000003-0000-0000-c000-000000000000'
                        scubaGearProduct    = 'aad'
                    },
                    [PSCustomObject]@{
                        leastPermissions    = @('Exchange.ManageAsApp')
                        resourceAPIAppId    = '00000002-0000-0ff1-ce00-000000000000'
                        scubaGearProduct    = 'exo'
                    },
                    [PSCustomObject]@{
                        leastPermissions    = @('Sites.FullControl.All')
                        resourceAPIAppId    = '00000003-0000-0ff1-ce00-000000000000'
                        scubaGearProduct    = 'sharepoint'
                    },
                    [PSCustomObject]@{
                        leastPermissions    = @('PrivilegedEligibilitySchedule.Read.AzureADGroup')
                        resourceAPIAppId    = '00000003-0000-0000-c000-000000000000'
                        scubaGearProduct    = 'aad'
                    },
                    [PSCustomObject]@{
                        leastPermissions    = @('RoleManagementPolicy.Read.AzureADGroup')
                        resourceAPIAppId    = '00000003-0000-0000-c000-000000000000'
                        scubaGearProduct    = 'aad'
                    },
                    [PSCustomObject]@{
                        leastPermissions    = @('Directory.Read.All')
                        resourceAPIAppId    = '00000003-0000-0000-c000-000000000000'
                        scubaGearProduct    = 'aad'
                    },
                    [PSCustomObject]@{
                        leastPermissions    = @('RoleManagement.Read.Directory')
                        resourceAPIAppId    = '00000003-0000-0000-c000-000000000000'
                        scubaGearProduct    = 'aad'
                    },
                    [PSCustomObject]@{
                        leastPermissions    = @('User.Read.All')
                        resourceAPIAppId    = '00000003-0000-0000-c000-000000000000'
                        scubaGearProduct    = 'aad'
                    }
                )
            }

            Mock -CommandName Get-ScubaGearPermissions -MockWith {
                param($OutAs)
                if ($OutAs -eq 'role') {
                    return @('Global Reader')
                }
                return @()
            }

            Mock -CommandName Get-ScubaGearAppRoleID -MockWith {
                return @(
                    [PSCustomObject]@{
                        resourceAPIAppId = '00000003-0000-0000-c000-000000000000'
                        APIName = 'Policy.Read.All'
                        AppRoleID = '246dd0d5-5bd0-4def-940b-0421030a5b68'
                        Product = 'aad'
                    },
                    [PSCustomObject]@{
                        resourceAPIAppId = '00000003-0000-0000-c000-000000000000'
                        APIName = 'PrivilegedEligibilitySchedule.Read.AzureADGroup'
                        AppRoleID = 'edb419d6-7edc-42a3-9345-509bfdf5d87c'
                        Product = 'aad'
                    },
                    [PSCustomObject]@{
                        resourceAPIAppId = '00000003-0000-0000-c000-000000000000'
                        APIName = 'RoleManagementPolicy.Read.AzureADGroup'
                        AppRoleID = '69e67828-780e-47fd-b28c-7b27d14864e6'
                        Product = 'aad'
                    },
                    [PSCustomObject]@{
                        resourceAPIAppId = '00000003-0000-0000-c000-000000000000'
                        APIName = 'Directory.Read.All'
                        AppRoleID = '7ab1d382-f21e-4acd-a863-ba3e13f7da61'
                        Product = 'aad'
                    },
                    [PSCustomObject]@{
                        resourceAPIAppId = '00000003-0000-0000-c000-000000000000'
                        APIName = 'RoleManagement.Read.Directory'
                        AppRoleID = '483bed4a-2ad3-4361-a73b-c83ccdbdc53c'
                        Product = 'aad'
                    },
                    [PSCustomObject]@{
                        resourceAPIAppId = '00000003-0000-0000-c000-000000000000'
                        APIName = 'User.Read.All'
                        AppRoleID = 'df021288-bdef-4463-88db-98f22de89214'
                        Product = 'aad'
                    },
                    [PSCustomObject]@{
                        resourceAPIAppId = '00000002-0000-0ff1-ce00-000000000000'
                        APIName = 'Exchange.ManageAsApp'
                        AppRoleID = 'dc50a0fb-09a3-484d-be87-e023b12c6440'
                        Product = 'exo'
                    },
                    [PSCustomObject]@{
                        resourceAPIAppId = '00000003-0000-0ff1-ce00-000000000000'
                        APIName = 'Sites.FullControl.All'
                        AppRoleID = '678536fe-1083-478a-9c59-b99265e6b0d3'
                        Product = 'sharepoint'
                    }
                )
            }

            # Mock service principal and application lookups
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet)

                if ($Commandlet -eq 'Get-MgServicePrincipal') {
                    return @{
                        Value = $script:MockScenario.servicePrincipal
                    }
                }
                elseif ($Commandlet -eq 'Get-MgBetaApplication') {
                    return @{
                        Value = $script:MockScenario.application
                    }
                }
                elseif ($Commandlet -eq 'Get-MgServicePrincipalAppRoleAssignment') {
                    return @{
                        Value = $script:MockScenario.appRoleAssignments
                    }
                }
                elseif ($Commandlet -eq 'Get-MgServicePrincipalOauth2PermissionGrant') {
                    return @{
                        Value = $script:MockScenario.oauth2Grants
                    }
                }
                return @{ Value = @() }
            }

            # Mock batch request for resource service principals - accurately simulate the real behavior
            Mock -CommandName Invoke-GraphBatchRequest -MockWith {
                param($Requests)
                $results = @{}

                foreach ($req in $Requests) {
                    $requestId = $req.id

                    # Determine which resource SP to return based on the request type
                    if ($requestId -like "spById_*") {
                        # Direct lookup by ID (returns object directly in body)
                        $resourceId = $requestId -replace '^spById_', ''

                        $body = switch ($resourceId) {
                            "resource-sp-graph" { $MockResourceSP_Graph }
                            "resource-sp-exo" { $MockResourceSP_Exchange }
                            "resource-sp-sharepoint" { $MockResourceSP_SharePoint }
                            default { $null }
                        }

                        if ($body) {
                            $results[$requestId] = @{
                                id = $requestId
                                status = 200
                                body = $body
                            }
                        } else {
                            $results[$requestId] = @{
                                id = $requestId
                                status = 404
                                body = @{ error = @{ message = "Service principal not found" } }
                            }
                        }
                    }
                    elseif ($requestId -like "spByAppId_*") {
                        # Lookup by AppId (returns array in 'value' property for filter queries)
                        $appId = $requestId -replace '^spByAppId_', ''

                        $body = switch ($appId) {
                            "00000003-0000-0000-c000-000000000000" { $MockResourceSP_Graph }
                            "00000002-0000-0ff1-ce00-000000000000" { $MockResourceSP_Exchange }
                            "00000003-0000-0ff1-ce00-000000000000" { $MockResourceSP_SharePoint }
                            default { $null }
                        }

                        if ($body) {
                            # spByAppId returns results in a 'value' array (Graph filter queries)
                            $results[$requestId] = @{
                                id = $requestId
                                status = 200
                                body = @{
                                    value = @($body)
                                }
                            }
                        } else {
                            $results[$requestId] = @{
                                id = $requestId
                                status = 200
                                body = @{
                                    value = @()
                                }
                            }
                        }
                    }
                }

                return $results
            }

            # Mock permission comparison
            Mock -CommandName Compare-ScubaGearPermission -MockWith {
                return $script:MockScenario.permissionComparison
            }

            # Mock role comparison
            Mock -CommandName Compare-ScubaGearRole -MockWith {
                return $script:MockScenario.roleComparison
            }

            # Mock Power Platform check
            Mock -CommandName Test-PowerPlatformAppRegistration -MockWith {
                return $script:MockScenario.powerPlatformRegistered
            }

            # Mock Power BI check
            Mock -CommandName Get-PowerBIAppRegistrationState -MockWith {
                return [PSCustomObject]@{
                    PowerBIRegistered = $false
                    GroupMembership = $false
                }
            }

            Mock -CommandName Get-PowerBIAdminToken -MockWith {
                throw "Unit tests must not acquire a Power BI token."
            }
            Mock -CommandName Get-PowerPlatformAdminToken -MockWith {
                throw "Unit tests must not acquire a Power Platform token."
            }
        }

        AfterEach {
            Should -Invoke -CommandName Get-PowerBIAdminToken -Times 0
            Should -Invoke -CommandName Get-PowerPlatformAdminToken -Times 0
        }

        Context "When testing with scenario: OptimalPermissions" {
            BeforeEach {
                $script:MockScenario = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockOptimalPermissions.json") | ConvertFrom-Json
            }

            It "Should not have FixPermissionIssues property when permissions are optimal" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PSObject.Properties.Name | Should -Not -Contain 'FixPermissionIssues'
            }

            It "Should report 'No action needed' status" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.Status | Should -Match $script:MockScenario.expectedResult.statusPattern
            }

            It "Should have MissingPermissions as false" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.MissingPermissions | Should -Be $false
            }

            It "Should have ExtraPermissions as false" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.ExtraPermissions | Should -Be $false
            }

            It "Should have MissingRoles as false" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.MissingRoles | Should -Be $false
            }

            It "Should have Power Platform as registered equal true" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PowerPlatformRegistered | Should -Be $true
            }

            It "Should report mocked Power BI state without acquiring tokens" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PowerBIRegistered | Should -Be $false
                $result.PowerBIGroupMembership | Should -Be $false
                Should -Invoke -CommandName Get-PowerBIAppRegistrationState -Times 1 -Exactly -ParameterFilter {
                    $AppID -eq $script:MockScenario.servicePrincipal.appId -and
                    $ServicePrincipalID -eq $script:MockScenario.servicePrincipal.id -and
                    $TenantId -eq $script:MockScenario.servicePrincipal.appOwnerOrganizationId -and
                    $M365Environment -eq 'commercial'
                }
            }
        }

        Context "When testing with scenario: MissingPermissions" {
            BeforeEach {
                $script:MockScenario = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockMissingPermissions.json") | ConvertFrom-Json
            }

            It "Should have FixPermissionIssues property when permissions are missing" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PSObject.Properties.Name | Should -Contain 'FixPermissionIssues'
                $result.FixPermissionIssues | Should -Not -BeNullOrEmpty
            }

            It "Should report 'Action needed' with missing permissions in status" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.Status | Should -Match $script:MockScenario.expectedResult.statusPattern
            }

            It "Should detect missing permissions" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.MissingPermissions | Should -Not -Be $false
                @($result.MissingPermissions).Count | Should -BeGreaterThan 0
            }
        }

        Context "When testing with scenario: ExtraPermissions" {
            BeforeEach {
                $script:MockScenario = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockExtraPermissions.json") | ConvertFrom-Json
            }

            It "Should have FixPermissionIssues property when extra permissions exist" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PSObject.Properties.Name | Should -Contain 'FixPermissionIssues'
                $result.FixPermissionIssues | Should -Not -BeNullOrEmpty
            }

            It "Should report 'Action needed' with extra permissions in status" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.Status | Should -Match $script:MockScenario.expectedResult.statusPattern
            }

            It "Should detect extra permissions" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.ExtraPermissions | Should -Not -Be $false
                @($result.ExtraPermissions).Count | Should -BeGreaterThan 0
            }
        }

        Context "When testing with scenario: MissingRole" {
            BeforeEach {
                $script:MockScenario = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockMissingRole.json") | ConvertFrom-Json
            }

            It "Should have FixPermissionIssues property when role is missing" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PSObject.Properties.Name | Should -Contain 'FixPermissionIssues'
                $result.FixPermissionIssues | Should -Not -BeNullOrEmpty
            }

            It "Should report 'Action needed' with missing role in status" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.Status | Should -Match $script:MockScenario.expectedResult.statusPattern
            }

            It "Should detect missing role" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.MissingRoles | Should -Not -Be $false
            }
        }

        Context "When testing with scenario: PowerPlatformUnneeded" {
            BeforeEach {
                $script:MockScenario = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockPowerPlatformUnneeded.json") | ConvertFrom-Json
            }

            It "Should have FixPermissionIssues property when Power Platform is registered but not needed" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PSObject.Properties.Name | Should -Contain 'FixPermissionIssues'
                $result.FixPermissionIssues | Should -Not -BeNullOrEmpty
            }

            It "Should report 'Action needed' with Power Platform status in message" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.Status | Should -Match $script:MockScenario.expectedResult.statusPattern
            }

            It "Should report Power Platform as registered" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PowerPlatformRegistered | Should -Be $true
            }
        }

        Context "When testing with scenario: PowerPlatformNeeded" {
            BeforeEach {
                $script:MockScenario = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockPowerPlatformNeeded.json") | ConvertFrom-Json
            }

            It "Should have FixPermissionIssues property when Power Platform is needed but not registered" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PSObject.Properties.Name | Should -Contain 'FixPermissionIssues'
                $result.FixPermissionIssues | Should -Not -BeNullOrEmpty
            }

            It "Should report 'Action needed' with Power Platform not registered status" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.Status | Should -Match $script:MockScenario.expectedResult.statusPattern
            }

            It "Should report Power Platform as not registered" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.PowerPlatformRegistered | Should -Be $false
            }
        }

        Context "When directory roles are assigned but not required" {
            BeforeEach {
                $script:MockScenario = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "ServicePrincipalSnippets/MockOptimalPermissions.json") | ConvertFrom-Json
                $script:MockScenario.productNames = @('aad')
                $script:MockScenario.powerPlatformRegistered = $false
                $script:MockScenario.roleComparison = [PSCustomObject]@{
                    RoleName = $null
                    Missing = $false
                    MissingRoles = $false
                    ExtraRoles = @([PSCustomObject]@{
                        RoleName = 'Global Reader'
                        RoleDefinitionId = 'global-reader-role-id'
                        AssignmentId = 'global-reader-assignment-id'
                    })
                }
            }

            It "reports the unneeded Global Reader assignment and includes the fix command" {
                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId `
                    -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.ExtraRoles | Should -HaveCount 1
                $result.ExtraRoles[0].RoleName | Should -Be 'Global Reader'
                $result.ExtraRoles[0].AssignmentId | Should -Be 'global-reader-assignment-id'
                $result.Status | Should -Match 'remove unneeded directory role assignment'
                $result.FixPermissionIssues | Should -Not -BeNullOrEmpty
            }

            It "reports unneeded <RoleName> in the status and includes the fix command" -ForEach @(
                @{ RoleName = 'Global Administrator' }
                @{ RoleName = 'Custom Audit Role' }
            ) {
                param($RoleName)
                $script:MockScenario.roleComparison.ExtraRoles[0].RoleName = $RoleName

                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId `
                    -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.ExtraRoles | Should -HaveCount 1
                $result.ExtraRoles[0].RoleName | Should -Be $RoleName
                $result.Status | Should -Match ([regex]::Escape($RoleName))
                $result.FixPermissionIssues | Should -Not -BeNullOrEmpty
            }

            It "reports no action needed after the last unneeded role assignment is removed" {
                $script:MockScenario.roleComparison.ExtraRoles = $false

                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId `
                    -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.Status | Should -Be 'No action needed, service principal is setup correctly.'
                $result.ExtraRoles | Should -BeFalse
                $result.PSObject.Properties.Name | Should -Not -Contain 'FixPermissionIssues'
            }

            It "reports multiple unneeded Global Reader assignments with their IDs" {
                $script:MockScenario.roleComparison.ExtraRoles = @(
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

                $result = Get-ScubaGearAppPermission -AppID $script:MockScenario.servicePrincipal.appId `
                    -M365Environment 'commercial' -ProductNames $script:MockScenario.productNames

                $result.ExtraRoles | Should -HaveCount 2
                $result.ExtraRoles.AssignmentId | Should -Contain 'first-assignment-id'
                $result.ExtraRoles.AssignmentId | Should -Contain 'second-assignment-id'
                $result.Status | Should -Match 'remove unneeded directory role assignment'
                $result.FixPermissionIssues | Should -Not -BeNullOrEmpty
            }
        }
    }

    Describe "Compare-ScubaGearRole" {
        BeforeEach {
            $script:RoleAssignmentFixture = @()
            $script:RoleDefinitionFixture = @(
                [PSCustomObject]@{ Id = 'global-reader-role-id'; DisplayName = 'Global Reader' }
                [PSCustomObject]@{ Id = 'global-admin-role-id'; DisplayName = 'Global Administrator' }
                [PSCustomObject]@{ Id = 'custom-role-id'; DisplayName = 'Custom Audit Role' }
            )
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet, $id, $queryParams)
                if ($Commandlet -eq 'Get-MgRoleManagementDirectoryRoleAssignment') {
                    return [PSCustomObject]@{ Value = @($script:RoleAssignmentFixture) }
                }
                if ($Commandlet -eq 'Get-MgRoleManagementDirectoryRoleDefinition') {
                    $definition = $script:RoleDefinitionFixture | Where-Object {
                        $_.Id -eq $id -or ($queryParams -and $queryParams['$filter'] -eq "displayName eq '$($_.DisplayName)'")
                    }
                    if ($definition) {
                        return [PSCustomObject]@{
                            Value = $definition
                        }
                    }
                }
                throw "Unexpected Graph command: $Commandlet"
            }
        }

        It "detects an unneeded Global Reader assignment even when no roles are required" {
            $script:RoleAssignmentFixture = @([PSCustomObject]@{
                Id = 'global-reader-assignment-id'
                RoleDefinitionId = 'global-reader-role-id'
            })

            $result = Compare-ScubaGearRole -ServicePrincipalID 'service-principal-id' -Roles @() `
                -M365Environment commercial -SkipConnect

            $result.Missing | Should -BeFalse
            $result.ExtraRoles | Should -HaveCount 1
            $result.ExtraRoles[0].AssignmentId | Should -Be 'global-reader-assignment-id'
        }

        It "keeps Global Reader when a selected product requires it" {
            $script:RoleAssignmentFixture = @([PSCustomObject]@{
                Id = 'global-reader-assignment-id'
                RoleDefinitionId = 'global-reader-role-id'
            })

            $result = Compare-ScubaGearRole -ServicePrincipalID 'service-principal-id' `
                -Roles @('Global Reader') -M365Environment commercial -SkipConnect

            $result.Missing | Should -BeFalse
            $result.ExtraRoles | Should -BeFalse
        }

        It "detects unneeded <RoleName> when no directory roles are required" -ForEach @(
            @{ RoleName = 'Global Administrator'; RoleDefinitionId = 'global-admin-role-id' }
            @{ RoleName = 'Custom Audit Role'; RoleDefinitionId = 'custom-role-id' }
        ) {
            param($RoleName, $RoleDefinitionId)
            $script:RoleAssignmentFixture = @([PSCustomObject]@{
                Id = 'unneeded-assignment-id'
                RoleDefinitionId = $RoleDefinitionId
            })

            $result = Compare-ScubaGearRole -ServicePrincipalID 'service-principal-id' -Roles @() `
                -M365Environment commercial -SkipConnect

            $result.Missing | Should -BeFalse
            $result.ExtraRoles | Should -HaveCount 1
            $result.ExtraRoles[0].RoleName | Should -Be $RoleName
            $result.ExtraRoles[0].AssignmentId | Should -Be 'unneeded-assignment-id'
        }

        It "reports all unneeded roles while preserving every required role" {
            $script:RoleAssignmentFixture = @(
                [PSCustomObject]@{ Id = 'reader-assignment-id'; RoleDefinitionId = 'global-reader-role-id' }
                [PSCustomObject]@{ Id = 'admin-assignment-id'; RoleDefinitionId = 'global-admin-role-id' }
                [PSCustomObject]@{ Id = 'custom-assignment-id'; RoleDefinitionId = 'custom-role-id' }
            )

            $result = Compare-ScubaGearRole -ServicePrincipalID 'service-principal-id' `
                -Roles @('Global Reader') -M365Environment commercial -SkipConnect

            $result.Missing | Should -BeFalse
            $result.ExtraRoles | Should -HaveCount 2
            $result.ExtraRoles.RoleName | Should -Not -Contain 'Global Reader'
            $result.ExtraRoles.AssignmentId | Should -Contain 'admin-assignment-id'
            $result.ExtraRoles.AssignmentId | Should -Contain 'custom-assignment-id'

            $result = Compare-ScubaGearRole -ServicePrincipalID 'service-principal-id' `
                -Roles @('Global Reader', 'Custom Audit Role') -M365Environment commercial -SkipConnect

            $result.Missing | Should -BeFalse
            $result.ExtraRoles | Should -HaveCount 1
            $result.ExtraRoles[0].RoleName | Should -Be 'Global Administrator'
        }

        It "reports all missing required roles when no assignment exists" {
            $result = Compare-ScubaGearRole -ServicePrincipalID 'service-principal-id' `
                -Roles @('Global Reader') -M365Environment commercial -SkipConnect

            $result.Missing | Should -BeTrue
            $result.MissingRoles | Should -Be @('Global Reader')
        }
    }
}
