package aad_test
import rego.v1
import data.aad
import data.utils.report.CheckedSkippedDetails
import data.utils.key.TestResult


#
# Policy MS.AAD.8.1v1
#--
test_GuestUserRoleId_Correct_V1 if {
    Output := aad.tests with input.authorization_policies as [AuthorizationPolicies]

    ReportDetailString := "Permission level set to \"Restricted access\" (authorizationPolicy)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, true) == true
}

test_GuestUserRoleId_Correct_V2 if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "GuestUserRoleId", "value": "10dae51f-b6af-4016-8d66-8c2a99b929b3"}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailString := "Permission level set to \"Limited access\" (authorizationPolicy)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, true) == true
}

test_GuestUserRoleId_Incorrect_V1 if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "GuestUserRoleId", "value": "a0b1b346-4d3e-4e8b-98f8-753987be4970"}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailString := "Permission level set to \"Same as member users\" (authorizationPolicy)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, false) == true
}

test_GuestUserRoleId_Incorrect_V2 if {
    Policies := json.patch(AuthorizationPolicies, [{"op": "add", "path": "GuestUserRoleId", "value": "Hello World"}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailString := "Permission level set to \"Unknown\" (authorizationPolicy)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, false) == true
}

test_GuestUserRoleId_Incorrect_V3 if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "GuestUserRoleId", "value": "Hello World"},
                {"op": "add", "path": "Id", "value": "policy 1"}])

    Output := aad.tests with input.authorization_policies as [Policies, AuthorizationPolicies]

    ReportDetailString := "Permission level set to \"Restricted access\" (authorizationPolicy), \"Unknown\" (policy 1)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.8.2v1
#--
test_AllowInvitesFrom_Correct if {
    Output := aad.tests with input.authorization_policies as [AuthorizationPolicies]

    ReportDetailString := "Permission level set to \"adminsAndGuestInviters\" (authorizationPolicy)"
    TestResult("MS.AAD.8.2v1", Output, ReportDetailString, true) == true
}

test_AllowInvitesFrom_Incorrect if {
    Policies := json.patch(AuthorizationPolicies, [{"op": "add", "path": "AllowInvitesFrom", "value": "Bad value"}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailString := "Permission level set to \"Bad value\" (authorizationPolicy)"
    TestResult("MS.AAD.8.2v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.8.3v1
#--
test_AllowedDomains_Correct if {
    Output := aad.tests with input.b2b_management_policy as {
        "AllowedDomains": ["contoso.com", "fabrikam.com"],
        "BlockedDomains": []
    }

    ReportDetailString := "Guest invitations are limited to the specified domains: contoso.com, fabrikam.com"
    TestResult("MS.AAD.8.3v1", Output, ReportDetailString, true) == true
}

test_BlockedDomainsOnly_Incorrect if {
    Output := aad.tests with input.b2b_management_policy as {
        "AllowedDomains": [],
        "BlockedDomains": ["evil.example"]
    }

    ReportDetailString := "Guest invitations are blocked only for: evil.example. Invitations to other domains are still allowed"
    TestResult("MS.AAD.8.3v1", Output, ReportDetailString, false) == true
}

test_AnyDomain_Incorrect if {
    Output := aad.tests with input.b2b_management_policy as {
        "AllowedDomains": [],
        "BlockedDomains": []
    }

    ReportDetailString := "Guest invitations are allowed to any external domain"
    TestResult("MS.AAD.8.3v1", Output, ReportDetailString, false) == true
}

test_PolicyReadFailed_Incorrect if {
    Output := aad.tests with input.b2b_management_policy as null
        with input.aad_unsuccessful_commands as ["Get-MgBetaPolicyB2BManagementPolicy"]

    ReportDetailString := "Could not read the B2B management policy. The call requires Policy.Read.B2BManagementPolicy, and a delegated sign-in must be a Global Administrator"
    TestResult("MS.AAD.8.3v1", Output, ReportDetailString, false) == true
}

test_GovernmentEnvironment_NotApplicable if {
    PolicyId := "MS.AAD.8.3v1"
    ReportDetailString := concat(" ", [
        "This policy is not applicable to GCC High or DOD environments because the B2B management",
        "policy API is not available. See %v for more info"
    ])
    every Environment in ["gcchigh", "dod"] {
        Output := aad.tests with input.scuba_config as {"M365Environment": Environment}
        TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailString), false) == true
    }
}
#--