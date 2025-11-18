$ProviderPath = '../../../../../Modules/Utility'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/Utility.psm1") -Function 'Invoke-GraphDirectly' -Force

InModuleScope Utility {
    $ProviderPath = '../../../../../Modules/Permissions'
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/PermissionsHelper.psm1") -Function 'Get-ScubaGearPermissions' -Force

    $ID = [guid]::NewGuid().Guid

    $testCases = @(
        @{ Cmdlet = "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance"; Path = "roleManagement/directory/roleEligibilityScheduleInstances"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance"; Path = "identityGovernance/privilegedAccess/group/eligibilityScheduleInstances/?`$filter=groupId eq '$ID'"; NeedsID = $true; IdValue = $ID },
        @{ Cmdlet = "Get-MgBetaPrivilegedAccessResource"; Path = "privilegedAccess/aadGroups/resources"; NeedsID = $true; IdValue = "aadGroups" },
        @{ Cmdlet = "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance"; Path = "roleManagement/directory/roleAssignmentScheduleInstances"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaIdentityConditionalAccessPolicy"; Path = "identity/conditionalAccess/policies"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaUserCount"; Path = "users/`$count"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaPolicyAuthorizationPolicy"; Path = "policies/authorizationPolicy"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaPolicyAuthenticationMethodPolicy"; Path = "policies/authenticationMethodsPolicy"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaUser"; Path = "users/"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaGroupMember"; Path = "groups/$ID/members"; NeedsID = $true; IdValue = $ID },
        @{ Cmdlet = "Get-MgBetaPolicyRoleManagementPolicyAssignment"; Path = "policies/roleManagementPolicyAssignments"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaPolicyRoleManagementPolicyRule"; Path = "policies/roleManagementPolicies/$ID/rules"; NeedsID = $true; IdValue = $ID },
        @{ Cmdlet = "Get-MgBetaSubscribedSku"; Path = "subscribedSkus"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaDirectorySetting"; Path = "settings"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaOrganization"; Path = "organization"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaDirectoryRole"; Path = "directoryRoles"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaDirectoryRoleMember"; Path = "directoryRoles/$ID/members"; NeedsID = $true; IdValue = $ID },
        @{ Cmdlet = "Get-MgBetaDirectoryObject"; Path = "directoryObjects/$ID"; NeedsID = $true; IdValue = $ID },
        @{ Cmdlet = "Get-MgBetaServicePrincipal"; Path = "servicePrincipals/$ID"; NeedsID = $true; IdValue = $ID },
        @{ Cmdlet = "Get-MgBetaDirectoryRoleTemplate"; Path = "directoryRoleTemplates"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaApplication"; Path = "applications"; NeedsID = $false; IdValue = $null },
        @{ Cmdlet = "Get-MgBetaApplicationFederatedIdentityCredential"; Path = "applications/$ID/federatedIdentityCredentials"; NeedsID = $true; IdValue = $ID }
    )

    $environments = @(
        @{ Name = "commercial"; Url = "https://graph.microsoft.com/beta" }
        @{ Name = "gcc";        Url = "https://graph.microsoft.com/beta" }
        @{ Name = "gcchigh";    Url = "https://graph.microsoft.us/beta" }
        @{ Name = "dod";        Url = "https://dod-graph.microsoft.us/beta" }
    )

    # Build the test cases dynamically for each environment
    # This will create a combination of each environment with each test case
    $combinedCases = [System.Collections.ArrayList]::new()
    foreach ($env in $environments) {
        foreach ($testCase in $testCases) {
            $null = $combinedCases.Add(@{
                EnvName = $env.Name
                EnvUrl  = $env.Url
                Cmdlet  = $testCase.Cmdlet
                Path    = $testCase.Path
                NeedsID = $testCase.NeedsID
                IdValue = $testCase.IdValue
            })
        }
    }

    Describe -Tag 'Utility' -Name "Invoke-GraphDirectly" {
        BeforeAll {
            Mock -ModuleName Utility Invoke-GraphDirectly -MockWith {
                param($Commandlet, $M365Environment, $ID)
                if(-not $ID){
                    # Mock Invoke-GraphDirectly to retrieve the Graph API URL to verify the configuration file hasn't been modified
                    return (Get-ScubaGearPermissions -CmdletName $Cmdlet -OutAs api -Environment $M365Environment)
                }else{
                    # Mock Invoke-GraphDirectly to retrieve the Graph API URL and insert the ID to verify the configuration file hasn't been modified
                    return (Get-ScubaGearPermissions -CmdletName $Cmdlet -OutAs api -Environment $M365Environment -ID $ID)
                }
            }
        }

        # Tests to ensure that corrent Microsoft Graph API URL is returned. The URL is stored in the permissions configuration file (ScubaGearPermissions.json).
        It "should return the expected value from Invoke-GraphDirectly for <Cmdlet> in <EnvName>" -TestCases $combinedCases {
            param($EnvName, $EnvUrl, $Cmdlet, $Path, $NeedsID, $IdValue)

            $expected = "$EnvUrl/$Path"

            if ($NeedsID -and $IdValue) {
                $result = Invoke-GraphDirectly -Commandlet $Cmdlet -M365Environment $EnvName -Id $IdValue
            } else {
                $result = Invoke-GraphDirectly -Commandlet $Cmdlet -M365Environment $EnvName
            }

            $result | Should -Be $expected
        }

        # Tests to ensure that the correct API header is returned for each cmdlet that requires it. The API header is stored in the permissions configuration file (ScubaGearPermissions.json).
        $ApiHeaderCases = @(
            @{ Cmdlet = "Get-MgBetaUserCount"; Path = "users/`$count"; NeedsID = $false; IdValue = $null; apiHeader = @{ConsistencyLevel = "eventual"} }
        )

        $combinedApiHeaderCases = @()
        foreach ($testCase in $apiHeaderCases) {
            $combinedApiHeaderCases += @{
                Cmdlet         = $testCase.Cmdlet
                apiHeaderKey   = $testCase.apiHeader.Keys
                apiHeaderValue = $testCase.apiHeader.Values
            }
        }

        It "should return the expected API header for <Cmdlet>" -TestCases $combinedApiHeaderCases {
            param($Cmdlet, $apiHeaderKey, $apiHeaderValue)

            $expected = Get-ScubaGearPermissions -CmdletName $Cmdlet -OutAs apiheader

            $expectedKey = $expected.psobject.Properties.name
            $expectedValue = $expected.psobject.Properties.value

            $expectedKey | Should -Be $apiHeaderKey
            $expectedValue | Should -Be $apiHeaderValue
        }
    }
}

AfterAll {
    Remove-Module Utility -Force -ErrorAction SilentlyContinue
    Remove-Module PermissionsHelper -Force -ErrorAction SilentlyContinue
}