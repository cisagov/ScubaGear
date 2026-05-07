$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper) -force

InModuleScope AADRiskyPermissionsHelper {
    $PermissionsModule = "../../../../../../Modules/Permissions/PermissionsHelper.psm1"
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $PermissionsModule) -Function Get-ScubaGearPermissions
    Describe "Format-RiskyThirdPartyServicePrincipals" {
        BeforeAll {
            # Import mock data
            $MockServicePrincipals = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipals.json") | ConvertFrom-Json
            $MockServicePrincipalAppRoleAssignments = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipalAppRoleAssignments.json") | ConvertFrom-Json
            $MockResourcePermissionCacheJson = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockResourcePermissionCache.json") | ConvertFrom-Json
            $MockResourcePermissionCache = @{}
            foreach ($prop in $MockResourcePermissionCacheJson.PSObject.Properties) {
                $MockResourcePermissionCache[$prop.Name] = $prop.Value
            }

            Mock Invoke-GraphDirectly {
                return @{
                    "value" = $MockServicePrincipals
                }
            } -ParameterFilter { $commandlet -eq "Get-MgBetaServicePrincipal" } -ModuleName AADRiskyPermissionsHelper

            function Invoke-MgGraphRequest { }
            # Simulate that "Test SP 6" from MockServicePrincipals.json has the Exchange Administrator role
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MockPrivilegedServicePrincipals')]
            $MockPrivilegedServicePrincipals = @{
                "00000000-0000-0000-0000-000000000060" = @{
                    "AppId"              = "70000000-0000-0000-0000-000000000000"
                    "ServicePrincipalId" = "00000000-0000-0000-0000-000000000060"
                    "DisplayName"        = "Test SP 6"
                    "roles"              = @("Exchange Administrator")
                }
            }

            function Get-ServicePrincipalAll { $MockServicePrincipals }

            Mock Invoke-MgGraphRequest {
                return @{
                    responses = @(
                        @{
                            id = "00000000-0000-0000-0000-000000000030"
                            status = 200
                            body = @{
                                value = $MockServicePrincipalAppRoleAssignments
                            }
                        },
                        @{
                            id = "00000000-0000-0000-0000-000000000040"
                            status = 200
                            body = @{
                                value = $MockServicePrincipalAppRoleAssignments
                            }
                        },
                        @{
                            id = "00000000-0000-0000-0000-000000000050"
                            status = 200
                            body = @{
                                value = $MockServicePrincipalAppRoleAssignments
                            }
                        },
                        @{
                            id     = "00000000-0000-0000-0000-000000000060"
                            status = 200
                            body   = @{ value = $MockServicePrincipalAppRoleAssignments }
                        }
                    )
                }
            }
            Mock Invoke-GraphDirectly {
                return @{
                    "Value" = @{
                        "Id" = "00000000-0000-0000-0000-000000000000"
                    }
                }
            } -ParameterFilter { $Commandlet -eq "Get-MgBetaOrganization" -and $M365Environment -eq "gcc" } -ModuleName AADRiskyPermissionsHelper
            Mock Invoke-GraphDirectly {
                return $MockResourcePermissionCache
            }
        }

        It "returns a list of third-party risky service principals with valid properties" {
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache
            $ThirdPartySPs = Format-RiskyThirdPartyServicePrincipals -RiskySPs $RiskySPs -M365Environment "gcc" -PrivilegedServicePrincipals $MockPrivilegedServicePrincipals

            $ThirdPartySPs | Should -HaveCount 4

            $ThirdPartySPs[0].DisplayName | Should -Match "Test SP 3"
            $ThirdPartySPs[0].ObjectId | Should -Match "00000000-0000-0000-0000-000000000030"
            $ThirdPartySPs[0].AppId | Should -Match "40000000-0000-0000-0000-000000000000"
            $ThirdPartySPs[0].KeyCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[0].PasswordCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[0].FederatedCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[0].Permissions | Should -HaveCount 8
            $ThirdPartySPs[0].PrivilegedRoles | Should -BeNullOrEmpty

            $ThirdPartySPs[1].DisplayName | Should -Match "Test SP 4"
            $ThirdPartySPs[1].ObjectId | Should -Match "00000000-0000-0000-0000-000000000040"
            $ThirdPartySPs[1].AppId | Should -Match "50000000-0000-0000-0000-000000000000"
            $ThirdPartySPs[1].KeyCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[1].PasswordCredentials | Should -HaveCount 2
            $ThirdPartySPs[1].FederatedCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[1].Permissions | Should -HaveCount 8
            $ThirdPartySPs[1].PrivilegedRoles | Should -BeNullOrEmpty

            $ThirdPartySPs[2].DisplayName | Should -Match "Test SP 5"
            $ThirdPartySPs[2].ObjectId | Should -Match "00000000-0000-0000-0000-000000000050"
            $ThirdPartySPs[2].AppId | Should -Match "60000000-0000-0000-0000-000000000000"
            $ThirdPartySPs[2].KeyCredentials | Should -HaveCount 1
            $ThirdPartySPs[2].PasswordCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[2].FederatedCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[2].Permissions | Should -HaveCount 8
            $ThirdPartySPs[2].PrivilegedRoles | Should -BeNullOrEmpty

            $ThirdPartySPs[3].DisplayName | Should -Match "Test SP 6"
            $ThirdPartySPs[3].ObjectId | Should -Match "00000000-0000-0000-0000-000000000060"
            $ThirdPartySPs[3].AppId | Should -Match "70000000-0000-0000-0000-000000000000"
            $ThirdPartySPs[3].KeyCredentials | Should -HaveCount 1
            $ThirdPartySPs[3].PasswordCredentials | Should -HaveCount 1
            $ThirdPartySPs[3].FederatedCredentials | Should -HaveCount 1
            $ThirdPartySPs[3].Permissions | Should -HaveCount 8
            $ThirdPartySPs[3].PrivilegedRoles | Should -HaveCount 1
            $ThirdPartySPs[3].PrivilegedRoles[0] | Should -Be "Exchange Administrator"
        }

        It "throws a ParameterBindingValidationException if the -RiskySPs value is null" {
            { Format-RiskyThirdPartyServicePrincipals -RiskySPs $null | Should -Throw -ErrorType System.Management.Automation.ParameterBindingValidationException }
        }

        It "throws a ParameterBindingValidationException if the -RiskySPs value is empty" {
            { Format-RiskyThirdPartyServicePrincipals -RiskySPs @() | Should -Throw -ErrorType System.Management.Automation.ParameterBindingValidationException }
        }

        It "returns severity info for valid properties for each third-party service principal" {
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache
            $ThirdPartySPs = Format-RiskyThirdPartyServicePrincipals -RiskySPs $RiskySPs -M365Environment "gcc" -PrivilegedServicePrincipals $MockPrivilegedServicePrincipals

            foreach ($SP in $ThirdPartySPs) {
                $SP.SeverityScore | Should -BeGreaterOrEqual 0
                $SP.ScoreBreakdown | Should -Not -BeNullOrEmpty
                $SP.PSObject.Properties.Name | Should -Contain "PrivilegedRoles"
            }
        }

        It "calculates the correct severity score for Test SP 4" {
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache
            $ThirdPartySPs = Format-RiskyThirdPartyServicePrincipals -RiskySPs $RiskySPs -M365Environment "gcc" -PrivilegedServicePrincipals $MockPrivilegedServicePrincipals
            $Weights = Get-SeverityScoreWeights
            
            $SP = $ThirdPartySPs | Where-Object { $_.DisplayName -eq "Test SP 4" }

            $AdminConsentedRiskyPermissions = $SP.Permissions | Where-Object { $_.IsAdminConsented -eq $true -and $_.IsRisky -eq $true }
            $CriticalCount = ($AdminConsentedRiskyPermissions | Where-Object { $_.RiskLevel -eq "Critical" } | Measure-Object).Count
            $HighCount = ($AdminConsentedRiskyPermissions | Where-Object { $_.RiskLevel -eq "High" }     | Measure-Object).Count
            $MediumCount = ($AdminConsentedRiskyPermissions | Where-Object { $_.RiskLevel -eq "Medium" }   | Measure-Object).Count
            $LowCount = ($AdminConsentedRiskyPermissions | Where-Object { $_.RiskLevel -eq "Low" }      | Measure-Object).Count


            # Contains 8 admin consented risky permissions:
            #   - Application.ReadWrite.All (Graph; Critical)
            #   - RoleManagement.ReadWrite.Directory (Graph; Critical)
            #   - Files.ReadWrite.All (Graph; Critical)
            #   - full_access_as_app (Exchange Online; Critical)
            #   - Mail.ReadWrite (Exchange Online; Critical)
            #   - Mail.ReadWrite (Graph; Critical)
            #   - GroupMember.ReadWrite.All (Graph; High)
            #   - User.Read.All (Graph; Medium)
            $ExpectedAdminConsentedPoints = (
                ($Weights.PermissionRiskLevelWeights.Critical * $CriticalCount) +
                ($Weights.PermissionRiskLevelWeights.High     * $HighCount) +
                ($Weights.PermissionRiskLevelWeights.Medium   * $MediumCount) +
                ($Weights.PermissionRiskLevelWeights.Low      * $LowCount)
            )

            # No non-admin consented permissions
            $ExpectedNonAdminConsentedPoints = 0

            # IsThirdPartyServicePrincipal = $true -> 20pts
            $ExpectedThirdPartyPoints = $Weights.ThirdPartyServicePrincipal.Points

            # Test SP 4 has no privileged roles
            $ExpectedPrivilegedRolePoints = 0

            $ExpectedKeyCredentialPoints       = $SP.ScoreBreakdown.KeyCredentials.TotalPoints
            $ExpectedPasswordCredentialPoints  = $SP.ScoreBreakdown.PasswordCredentials.TotalPoints
            $ExpectedFederatedCredentialPoints = $SP.ScoreBreakdown.FederatedCredentials.TotalPoints
            $ExpectedCredentialVolumePoints    = $SP.ScoreBreakdown.CredentialVolume.TotalPoints
            $ExpectedPermissionVolumePoints    = $SP.ScoreBreakdown.PermissionVolume.TotalPoints

            $ExpectedScore = $ExpectedAdminConsentedPoints `
                           + $ExpectedNonAdminConsentedPoints `
                           + $ExpectedThirdPartyPoints `
                           + $ExpectedPrivilegedRolePoints `
                           + $ExpectedKeyCredentialPoints `
                           + $ExpectedPasswordCredentialPoints `
                           + $ExpectedFederatedCredentialPoints `
                           + $ExpectedCredentialVolumePoints `
                           + $ExpectedPermissionVolumePoints

            $SP.SeverityScore | Should -Be $ExpectedScore
            $SP.ScoreBreakdown.AdminConsentedRiskyPermissions.PermissionCount | Should -Be 8
            $SP.ScoreBreakdown.AdminConsentedRiskyPermissions.TotalPoints | Should -Be $ExpectedAdminConsentedPoints
            $SP.ScoreBreakdown.NonAdminConsentedRiskyPermissions.PermissionCount | Should -Be 0
            $SP.ScoreBreakdown.NonAdminConsentedRiskyPermissions.TotalPoints | Should -Be $ExpectedNonAdminConsentedPoints
            $SP.ScoreBreakdown.ThirdPartyServicePrincipal.IsThirdPartyServicePrincipal | Should -Be $true
            $SP.ScoreBreakdown.ThirdPartyServicePrincipal.TotalPoints | Should -Be $ExpectedThirdPartyPoints
            $SP.ScoreBreakdown.KeyCredentials.CredentialCount | Should -Be 0
            $SP.ScoreBreakdown.KeyCredentials.TotalPoints | Should -Be $ExpectedKeyCredentialPoints
            $SP.ScoreBreakdown.PasswordCredentials.CredentialCount | Should -Be 2
            $SP.ScoreBreakdown.PasswordCredentials.TotalPoints | Should -Be $ExpectedPasswordCredentialPoints
            $SP.ScoreBreakdown.FederatedCredentials.CredentialCount | Should -Be 0
            $SP.ScoreBreakdown.FederatedCredentials.TotalPoints | Should -Be 0
            $SP.PSObject.Properties.Name | Should -Contain "PrivilegedRoles"
            $SP.PrivilegedRoles | Should -BeNullOrEmpty
        }

        It "calculates the correct severity score for Test SP 6" {
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache
            $ThirdPartySPs = Format-RiskyThirdPartyServicePrincipals -RiskySPs $RiskySPs -M365Environment "gcc" -PrivilegedServicePrincipals $MockPrivilegedServicePrincipals
            $Weights = Get-SeverityScoreWeights

            $SP = $ThirdPartySPs | Where-Object { $_.DisplayName -eq "Test SP 6" }

            $AdminConsentedRiskyPermissions = $SP.Permissions | Where-Object { $_.IsAdminConsented -eq $true -and $_.IsRisky -eq $true }
            $CriticalCount = ($AdminConsentedRiskyPermissions | Where-Object { $_.RiskLevel -eq "Critical" } | Measure-Object).Count
            $HighCount = ($AdminConsentedRiskyPermissions | Where-Object { $_.RiskLevel -eq "High" }     | Measure-Object).Count
            $MediumCount = ($AdminConsentedRiskyPermissions | Where-Object { $_.RiskLevel -eq "Medium" }   | Measure-Object).Count
            $LowCount = ($AdminConsentedRiskyPermissions | Where-Object { $_.RiskLevel -eq "Low" }      | Measure-Object).Count

            # Contains 8 admin consented risky permissions
            $ExpectedAdminConsentedPoints = (
                ($Weights.PermissionRiskLevelWeights.Critical * $CriticalCount) +
                ($Weights.PermissionRiskLevelWeights.High * $HighCount) +
                ($Weights.PermissionRiskLevelWeights.Medium * $MediumCount) +
                ($Weights.PermissionRiskLevelWeights.Low * $LowCount)
            )

            # No non-admin consented permissions
            $ExpectedNonAdminConsentedPoints = 0

            # IsThirdPartyServicePrincipal = $true
            $ExpectedThirdPartyPoints = $Weights.ThirdPartyServicePrincipal.Points

            # 1 privileged role (Exchange Administrator)
            $ExpectedPrivilegedRolePoints = $Weights.PrivilegedRoles.PointsPerRole

            $ExpectedKeyCredentialPoints       = $SP.ScoreBreakdown.KeyCredentials.TotalPoints
            $ExpectedPasswordCredentialPoints  = $SP.ScoreBreakdown.PasswordCredentials.TotalPoints
            $ExpectedFederatedCredentialPoints = $SP.ScoreBreakdown.FederatedCredentials.TotalPoints
            $ExpectedCredentialVolumePoints    = $SP.ScoreBreakdown.CredentialVolume.TotalPoints
            $ExpectedPermissionVolumePoints    = $SP.ScoreBreakdown.PermissionVolume.TotalPoints

            $ExpectedScore = $ExpectedAdminConsentedPoints `
                           + $ExpectedNonAdminConsentedPoints `
                           + $ExpectedThirdPartyPoints `
                           + $ExpectedPrivilegedRolePoints `
                           + $ExpectedKeyCredentialPoints `
                           + $ExpectedPasswordCredentialPoints `
                           + $ExpectedFederatedCredentialPoints `
                           + $ExpectedCredentialVolumePoints `
                           + $ExpectedPermissionVolumePoints

            $SP.SeverityScore | Should -Be $ExpectedScore
            $SP.ScoreBreakdown.AdminConsentedRiskyPermissions.PermissionCount | Should -Be 8
            $SP.ScoreBreakdown.AdminConsentedRiskyPermissions.TotalPoints | Should -Be $ExpectedAdminConsentedPoints
            $SP.ScoreBreakdown.NonAdminConsentedRiskyPermissions.PermissionCount | Should -Be 0
            $SP.ScoreBreakdown.NonAdminConsentedRiskyPermissions.TotalPoints | Should -Be $ExpectedNonAdminConsentedPoints
            $SP.ScoreBreakdown.ThirdPartyServicePrincipal.IsThirdPartyServicePrincipal | Should -Be $true
            $SP.ScoreBreakdown.ThirdPartyServicePrincipal.TotalPoints | Should -Be $ExpectedThirdPartyPoints
            $SP.ScoreBreakdown.PrivilegedRoles.RoleCount | Should -Be 1
            $SP.ScoreBreakdown.PrivilegedRoles.TotalPoints | Should -Be $ExpectedPrivilegedRolePoints
            $SP.ScoreBreakdown.KeyCredentials.CredentialCount | Should -Be 1
            $SP.ScoreBreakdown.KeyCredentials.TotalPoints | Should -Be $ExpectedKeyCredentialPoints
            $SP.ScoreBreakdown.PasswordCredentials.CredentialCount | Should -Be 1
            $SP.ScoreBreakdown.PasswordCredentials.TotalPoints | Should -Be $ExpectedPasswordCredentialPoints
            $SP.ScoreBreakdown.FederatedCredentials.CredentialCount | Should -Be 1
            $SP.ScoreBreakdown.FederatedCredentials.TotalPoints | Should -Be $ExpectedFederatedCredentialPoints
            $SP.PSObject.Properties.Name | Should -Contain "PrivilegedRoles"
            $SP.PrivilegedRoles | Should -HaveCount 1
            $SP.PrivilegedRoles[0] | Should -Be "Exchange Administrator"
        }

        It "excludes service principals with a null AppOwnerOrganizationId (agent service principals)" {
            $AgentSP = [PSCustomObject]@{
                Id                     = "00000000-0000-0000-0000-000000000099"
                AppId                  = "99000000-0000-0000-0000-000000000000"
                DisplayName            = "Test Agent SP"
                KeyCredentials         = $null
                PasswordCredentials    = $null
                FederatedIdentityCredentials = $null
                AppOwnerOrganizationId = $null
            }
            $MockSPsWithAgent = @($MockServicePrincipals) + $AgentSP
            Mock Get-ServicePrincipalAll { $MockSPsWithAgent }

            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions -M365Environment "gcc" -ResourcePermissionCache $MockResourcePermissionCache
            $ThirdPartySPs = Format-RiskyThirdPartyServicePrincipals -RiskySPs $RiskySPs -M365Environment "gcc"

            $AgentSP = $ThirdPartySPs | Where-Object { $_.DisplayName -eq "Test Agent SP" }
            $AgentSP | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}