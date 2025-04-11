$ModulesPath = "../../../../../../Modules"
$AADRiskyPermissionsHelper = "$($ModulesPath)/Providers/ProviderHelpers/AADRiskyPermissionsHelper.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $AADRiskyPermissionsHelper)

InModuleScope AADRiskyPermissionsHelper {
    Describe "Format-RiskyThirdPartyServicePrincipals" {
        BeforeAll {
            # Import mock data
            $MockApplications = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockApplications.json") | ConvertFrom-Json
            $MockFederatedCredentials = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockFederatedCredentials.json") | ConvertFrom-Json
            $MockServicePrincipals = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipals.json") | ConvertFrom-Json
            $MockServicePrincipalAppRoleAssignments = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "../RiskyPermissionsSnippets/MockServicePrincipalAppRoleAssignments.json") | ConvertFrom-Json

            function Get-MgBetaApplication { $MockApplications }
            function Get-MgBetaApplicationFederatedIdentityCredential { $MockFederatedCredentials }
            function Get-MgBetaServicePrincipal { $MockServicePrincipals }

            Mock Get-MgBetaApplication { $MockApplications }
            Mock Get-MgBetaApplicationFederatedIdentityCredential { $MockFederatedCredentials }
            Mock Get-MgBetaServicePrincipal { $MockServicePrincipals }
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
                        }
                    )
                }
            }
            Mock Get-MgBetaOrganization {
                return @{
                    "Id" = "00000000-0000-0000-0000-000000000000"
                }
            }
        }

        It "returns a list of third-party risky service principals with valid properties" {
            $RiskySPs = Get-ServicePrincipalsWithRiskyPermissions
            $ThirdPartySPs = Format-RiskyThirdPartyServicePrincipals -RiskySPs $RiskySPs

            $ThirdPartySPs | Should -HaveCount 3

            $ThirdPartySPs[0].DisplayName | Should -Match "Test SP 3"
            $ThirdPartySPs[0].ObjectId | Should -Match "00000000-0000-0000-0000-000000000030"
            $ThirdPartySPs[0].AppId | Should -Match "40000000-0000-0000-0000-000000000000"
            $ThirdPartySPs[0].KeyCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[0].PasswordCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[0].FederatedCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[0].RiskyPermissions | Should -HaveCount 8

            $ThirdPartySPs[1].DisplayName | Should -Match "Test SP 4"
            $ThirdPartySPs[1].ObjectId | Should -Match "00000000-0000-0000-0000-000000000040"
            $ThirdPartySPs[1].AppId | Should -Match "50000000-0000-0000-0000-000000000000"
            $ThirdPartySPs[1].KeyCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[1].PasswordCredentials | Should -HaveCount 2
            $ThirdPartySPs[1].FederatedCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[1].RiskyPermissions | Should -HaveCount 8

            $ThirdPartySPs[2].DisplayName | Should -Match "Test SP 5"
            $ThirdPartySPs[2].ObjectId | Should -Match "00000000-0000-0000-0000-000000000050"
            $ThirdPartySPs[2].AppId | Should -Match "60000000-0000-0000-0000-000000000000"
            $ThirdPartySPs[2].KeyCredentials | Should -HaveCount 1
            $ThirdPartySPs[2].PasswordCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[2].FederatedCredentials | Should -BeNullOrEmpty
            $ThirdPartySPs[2].RiskyPermissions | Should -HaveCount 8
        }

        #It "throws a ParameterBindingValidationException if the $RiskySPs value is null" {
        #    { Format-RiskyThirdPartyServicePrincipals -RiskySPs $null } | Should -Throw -ErrorType System.Management.Automation.ParameterBindingValidationException
        #}
    }
}

AfterAll {
    Remove-Module AADRiskyPermissionsHelper -Force -ErrorAction 'SilentlyContinue'
}