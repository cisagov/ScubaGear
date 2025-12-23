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
                        leastPermissions    = @('PrivilegedAccess.Read.AzureADGroup')
                        resourceAPIAppId    = '00000003-0000-0000-c000-000000000000'
                        scubaGearProduct    = 'aad'
                    },
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
                        APIName = 'PrivilegedAccess.Read.AzureADGroup'
                        AppRoleID = '01e37dc9-c035-40bd-b438-b2879c4870a6'
                        Product = 'aad'
                    },
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
    }
}
