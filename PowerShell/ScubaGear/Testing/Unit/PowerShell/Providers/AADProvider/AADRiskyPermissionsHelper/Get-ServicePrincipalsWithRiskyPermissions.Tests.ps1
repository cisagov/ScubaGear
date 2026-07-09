$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "Get-ServicePrincipalsWithRiskyPermissions" {
        $PermissionsModule = "../../../../../../Modules/Permissions/PermissionsHelper.psm1"
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $PermissionsModule) -Function Get-ScubaGearPermissions
        BeforeAll {
            # Import mock data
            $MockServicePrincipals = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipals.json") | ConvertFrom-Json
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockServicePrincipalAppRoleAssignments')]
            $MockServicePrincipalAppRoleAssignments = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipalAppRoleAssignments.json") | ConvertFrom-Json
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockSafePermissions')]
            $MockSafePermissions = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockSafePermissions.json") | ConvertFrom-Json
            $MockResourcePermissionCacheJson = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockResourcePermissionCache.json") | ConvertFrom-Json
            $MockResourcePermissionCache = @{}
            foreach ($prop in $MockResourcePermissionCacheJson.PSObject.Properties) {
                $MockResourcePermissionCache[$prop.Name] = $prop.Value
            }

            # Create mock RiskyAppPermissions.json structure with test data
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockRiskyAppPermissionsJson')]
            $MockRiskyAppPermissionsJson = @{
                permissions = @{
                    "Microsoft Graph" = @{
                        "Application" = @{
                            "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9" = @{ Name = "Application.ReadWrite.All"; RiskLevel = "High" }
                            "e2a3a72e-5f79-4c64-b1b1-878b674786c9" = @{ Name = "Mail.ReadWrite"; RiskLevel = "High" }
                            "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8" = @{ Name = "RoleManagement.ReadWrite.Directory"; RiskLevel = "Critical" }
                            "df021288-bdef-4463-88db-98f22de89214" = @{ Name = "User.Read.All"; RiskLevel = "Medium" }
                            "dbaae8cf-10b5-4b86-a4a1-f871c94c6695" = @{ Name = "GroupMember.ReadWrite.All"; RiskLevel = "High" }
                            "75359482-378d-4052-8f01-80520e7db3cd" = @{ Name = "Files.ReadWrite.All"; RiskLevel = "High" }
                        }
                    }
                    "Office 365 Exchange Online" = @{
                        "Application" = @{
                            "dc890d15-9560-4a4c-9b7f-a736ec74ec40" = @{ Name = "full_access_as_app"; RiskLevel = "Critical" }
                            "e2a3a72e-5f79-4c64-b1b1-878b674786c9" = @{ Name = "Mail.ReadWrite"; RiskLevel = "Critical" }
                        }
                    }
                }
                resources = @{
                    "00000003-0000-0000-c000-000000000000" = "Microsoft Graph"
                    "00000002-0000-0ff1-ce00-000000000000" = "Office 365 Exchange Online"
                }
            }
            # Convert nested hashtables to PSCustomObject so PSObject.Properties enumerates JSON keys as expected.
            $MockRiskyAppPermissionsJson = $MockRiskyAppPermissionsJson | ConvertTo-Json -Depth 20 | ConvertFrom-Json

            function New-MockMgGraphResponseAppRoleAssignments {
                param (
                    [int] $Size,
                    [array] $MockBody
                )

                $data = @()
                for ($i = 1; $i -le $Size; $i++) {
                    $id = "00000000-0000-0000-0000-0000000000{0:D2}" -f ($i * 10)
                    $mockResponse = @{
                        id     = $id
                        status = 200
                        body   = @{
                            value = $MockBody
                        }
                    }
                    $data += $mockResponse
                }

                return $data
            }

            function Invoke-MgGraphRequest { }

            Mock Invoke-GraphDirectly {
                return @{
                    "value" = $MockServicePrincipals
                    "@odata.context" = "https://graph.microsoft.com/beta/$metadata#ServicePrincipal"
                }
            } -ParameterFilter { $commandlet -eq "Get-MgBetaServicePrincipal" -or $Uri -match "/serviceprincipals" } -ModuleName AADRiskyPermissionsHelper
            function Get-MockMgGraphResponse {
                param (
                    [int] $Size,
                    [array] $MockBody
                )

                $data = @()
                for ($i = 1; $i -le $Size; $i++) {
                    $id = "00000000-0000-0000-0000-0000000000{0:D2}" -f ($i * 10)
                    $mockResponse = @{
                        id     = $id
                        status = 200
                        body   = @{
                            value = $MockBody
                        }
                    }
                    $data += $mockResponse
                }

                return $data
            }

            Mock Invoke-GraphDirectly {
                return $MockResourcePermissionCache
            } -ParameterFilter { $commandlet -eq "Get-MgServicePrincipal" } -ModuleName AADRiskyPermissionsHelper

            Mock Get-ScubaGearPermissions {
                return "https://graph.microsoft.com"
            } -ParameterFilter { $CmdletName -eq "Connect-MgGraph" -and $OutAs -eq "endpoint" } -ModuleName AADRiskyPermissionsHelper

            Mock Get-RiskyAppPermissionsJson {
                return $MockRiskyAppPermissionsJson
            } -ModuleName AADRiskyPermissionsHelper

            # Mock Get-PermissionLookup to return the proper nested hashtable structure
            Mock Get-PermissionLookup {
                param([PSCustomObject] $RiskyAppPermissionsJson)
                $Lookup = @{}
                foreach ($Resource in $RiskyAppPermissionsJson.permissions.PSObject.Properties) {
                    $ResourceName = $Resource.Name
                    $Lookup[$ResourceName] = @{}
                    foreach ($RoleType in $Resource.Value.PSObject.Properties) {
                        if ($RoleType.Name.StartsWith("_")) { continue }
                        $RoleTypeName = $RoleType.Name
                        $Lookup[$ResourceName][$RoleTypeName] = @{}
                        foreach ($Perm in $RoleType.Value.PSObject.Properties) {
                            $Lookup[$ResourceName][$RoleTypeName][$Perm.Name] = @{
                                Name = $Perm.Value.Name
                                RiskLevel = $Perm.Value.RiskLevel
                            }
                        }
                    }
                }
                return $Lookup
            } -ModuleName AADRiskyPermissionsHelper

            # Mock New-RiskyAppResourceLookup to return AppId/Name mappings
            Mock New-RiskyAppResourceLookup {
                param([PSCustomObject] $RiskyAppPermissionsJson)
                $Lookup = @{
                    AppIdToName = @{}
                    NameToAppId = @{}
                }
                foreach ($Property in $RiskyAppPermissionsJson.resources.PSObject.Properties) {
                    $Lookup.AppIdToName[$Property.Name] = $Property.Value
                    $Lookup.NameToAppId[$Property.Value] = $Property.Name
                }
                return $Lookup
            } -ModuleName AADRiskyPermissionsHelper
        }

        It "returns a list of service principals with valid properties" {
            $MockAppRoleAssignmentResponses = New-MockMgGraphResponseAppRoleAssignments -Size 5 -MockBody $MockServicePrincipalAppRoleAssignments

            Mock Invoke-GraphBatchRequestsWithRetry {
                $responses = @{}
                foreach ($response in $MockAppRoleAssignmentResponses) {
                    $responses[[string]$response.id] = $response
                }
                return $responses
            } -ModuleName AADRiskyPermissionsHelper

            # Pass explicit JSON instead of relying on Get-RiskyAppPermissionsJson to avoid cache issues
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache -RiskyAppPermissionsJson $MockRiskyAppPermissionsJson
            $RiskySPs | Should -HaveCount 5

            $RiskySPs[0].DisplayName | Should -Match "Test SP 1"
            $RiskySPs[0].ObjectId | Should -Match "00000000-0000-0000-0000-000000000010"
            $RiskySPs[0].AppId | Should -Match "10000000-0000-0000-0000-000000000000"
            $RiskySPs[0].KeyCredentials | Should -HaveCount 1
            $RiskySPs[0].PasswordCredentials | Should -HaveCount 1
            $RiskySPs[0].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[0].Permissions | Should -HaveCount 8

            $RiskySPs[1].DisplayName | Should -Match "Test SP 2"
            $RiskySPs[1].ObjectId | Should -Match "00000000-0000-0000-0000-000000000020"
            $RiskySPs[1].AppId | Should -Match "20000000-0000-0000-0000-000000000000"
            $RiskySPs[1].KeyCredentials | Should -HaveCount 1
            $RiskySPs[1].PasswordCredentials | Should -BeNullOrEmpty
            $RiskySPs[1].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[1].Permissions | Should -HaveCount 8

            $RiskySPs[2].DisplayName | Should -Match "Test SP 3"
            $RiskySPs[2].ObjectId | Should -Match "00000000-0000-0000-0000-000000000030"
            $RiskySPs[2].AppId | Should -Match "40000000-0000-0000-0000-000000000000"
            $RiskySPs[2].KeyCredentials | Should -BeNullOrEmpty
            $RiskySPs[2].PasswordCredentials | Should -BeNullOrEmpty
            $RiskySPs[2].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[2].Permissions | Should -HaveCount 8

            $RiskySPs[3].DisplayName | Should -Match "Test SP 4"
            $RiskySPs[3].ObjectId | Should -Match "00000000-0000-0000-0000-000000000040"
            $RiskySPs[3].AppId | Should -Match "50000000-0000-0000-0000-000000000000"
            $RiskySPs[3].KeyCredentials | Should -BeNullOrEmpty
            $RiskySPs[3].PasswordCredentials | Should -HaveCount 2
            $RiskySPs[3].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[3].Permissions | Should -HaveCount 8

            $RiskySPs[4].DisplayName | Should -Match "Test SP 5"
            $RiskySPs[4].ObjectId | Should -Match "00000000-0000-0000-0000-000000000050"
            $RiskySPs[4].AppId | Should -Match "60000000-0000-0000-0000-000000000000"
            $RiskySPs[4].KeyCredentials | Should -HaveCount 1
            $RiskySPs[4].PasswordCredentials | Should -BeNullOrEmpty
            $RiskySPs[4].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[4].Permissions | Should -HaveCount 8
        }

        It "excludes service principals with no risky permissions" {
            # Set to $SafePermissions instead of $MockServicePrincipalAppRoleAssignments
            # to simulate service principals assigned to safe permissions
            $MockAppRoleAssignmentResponses = New-MockMgGraphResponseAppRoleAssignments -Size 5 -MockBody $MockSafePermissions
            Mock Invoke-GraphBatchRequestsWithRetry {
                $responses = @{}
                foreach ($response in $MockAppRoleAssignmentResponses) {
                    $responses[[string]$response.id] = $response
                }
                return $responses
            } -ModuleName AADRiskyPermissionsHelper

            $RiskySPs = @()
            foreach ($SP in Get-ServicePrincipalsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache -RiskyAppPermissionsJson $MockRiskyAppPermissionsJson) {
                $RiskyPerms = $SP.Permissions | Where-Object { $_.IsRisky }
                if ($RiskyPerms.Count -gt 0) {
                    $RiskySPs += $SP
                }
            }
            $RiskySPs | Should -BeNullOrEmpty
        }

        It "excludes permissions not included in the RiskyAppPermissions.json mapping" {
            $MockServicePrincipalAppRoleAssignments += $MockSafePermissions
            $MockServicePrincipalAppRoleAssignments | Should -HaveCount 11

            $MockAppRoleAssignmentResponses = New-MockMgGraphResponseAppRoleAssignments -Size 5 -MockBody $MockServicePrincipalAppRoleAssignments
            Mock Invoke-GraphBatchRequestsWithRetry {
                $responses = @{}
                foreach ($response in $MockAppRoleAssignmentResponses) {
                    $responses[[string]$response.id] = $response
                }
                return $responses
            } -ModuleName AADRiskyPermissionsHelper

            $RiskySPs = @()
            foreach ($SP in Get-ServicePrincipalsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache -RiskyAppPermissionsJson $MockRiskyAppPermissionsJson) {
                $RiskyPerms = $SP.Permissions | Where-Object { $_.IsRisky }
                if ($RiskyPerms.Count -gt 0) {
                    $RiskySPs += $SP
                }
            }
            $RiskySPs[0].DisplayName | Should -Match "Test SP 1"
            $RiskySPs[0].ObjectId | Should -Match "00000000-0000-0000-0000-000000000010"
            $RiskySPs[0].AppId | Should -Match "10000000-0000-0000-0000-000000000000"
            $RiskySPs[0].KeyCredentials | Should -HaveCount 1
            $RiskySPs[0].PasswordCredentials | Should -HaveCount 1
            $RiskySPs[0].FederatedCredentials | Should -BeNullOrEmpty
            $RiskySPs[0].Permissions | Where-Object { $_.IsRisky } | Should -HaveCount 8
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}