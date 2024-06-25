package aad_test
import rego.v1
import data.aad
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.AAD.5.1v1
#--
test_AllowedToCreateApps_Correct if {
    Output := aad.tests with input.authorization_policies as [AuthorizationPolicies]

    ReportDetailStr := "0 authorization policies found that allow non-admin users to register third-party applications"
    TestResult("MS.AAD.5.1v1", Output, ReportDetailStr, true) == true
}

test_AllowedToCreateApps_Incorrect_V1 if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "DefaultUserRolePermissions/AllowedToCreateApps", "value": true}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow non-admin users to register third-party applications:",
        "<br/>authorizationPolicy"
    ])

    TestResult("MS.AAD.5.1v1", Output, ReportDetailStr, false) == true
}

test_AllowedToCreateApps_Incorrect_V2 if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "DefaultUserRolePermissions/AllowedToCreateApps","value": true},
                {"op": "add", "path": "Id", "value": "Bad Policy"}])

    Output := aad.tests with input.authorization_policies as [Policies, AuthorizationPolicies]

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow non-admin users to register third-party applications:",
        "<br/>Bad Policy"
    ])

    TestResult("MS.AAD.5.1v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.5.2v1
#--
test_UserConsentNotAllowed_Correct if {
    Output := aad.tests with input.authorization_policies as [AuthorizationPolicies]

    ReportDetailStr :=
        "0 authorization policies found that allow non-admin users to consent to third-party applications"
    TestResult("MS.AAD.5.2v1", Output, ReportDetailStr, true) == true
}

test_UserConsentNotAllowedEmptyDefaultUserArray_Correct if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "PermissionGrantPolicyIdsAssignedToDefaultUserRole", "value": []}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailStr :=
        "0 authorization policies found that allow non-admin users to consent to third-party applications"
    TestResult("MS.AAD.5.2v1", Output, ReportDetailStr, true) == true
}

test_UserConsentFromVerifiedPublishersAllowed_Incorrect if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "PermissionGrantPolicyIdsAssignedToDefaultUserRole",
                "value": [
                    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
                    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-team",
                    "ManagePermissionGrantsForSelf.microsoft-user-default-legacy"
                ]}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow non-admin users to consent to third-party applications:",
        "<br/>authorizationPolicy"
    ])

    TestResult("MS.AAD.5.2v1", Output, ReportDetailStr, false) == true
}

test_UserConsentAllowed_Incorrect if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "PermissionGrantPolicyIdsAssignedToDefaultUserRole",
                "value": [
                    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
                    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-team",
                    "ManagePermissionGrantsForSelf.microsoft-user-default-low"
                ]}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow non-admin users to consent to third-party applications:",
        "<br/>authorizationPolicy"
    ])

    TestResult("MS.AAD.5.2v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.AAD.5.3v1
#--
test_IsEnabled_Correct if {
    Output := aad.tests with input.directory_settings as [DirectorySettings]

    TestResult("MS.AAD.5.3v1", Output, PASS, true) == true
}

test_IsEnabled_Incorrect_Missing if {
    Settings := json.patch(DirectorySettings, [{"op": "add", "path": "Values/0/Value", "value": "false"}])

    Output := aad.tests with input.directory_settings as [Settings]

    TestResult("MS.AAD.5.3v1", Output, FAIL, false) == true
}

test_IsEnabled_Incorrect if {
    Settings := json.patch(DirectorySettings, [{"op": "add", "path": "Values/0/Value", "value": "false"}])

    Output := aad.tests with input.directory_settings as [Settings]

    TestResult("MS.AAD.5.3v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.AAD.5.4v1
#--
test_Value_Correct_Lowercase if {
    Output := aad.tests with input.directory_settings as [DirectorySettings]

    TestResult("MS.AAD.5.4v1", Output, PASS, true) == true
}

test_Value_Correct_Uppercase if {
    Settings := json.patch(DirectorySettings, [{"op": "add", "path": "Values/1/Value", "value": "False"}])

    Output := aad.tests with input.directory_settings as [Settings]

    TestResult("MS.AAD.5.4v1", Output, PASS, true) == true
}

test_Value_Incorrect_Lowercase if {
    Settings := json.patch(DirectorySettings, [{"op": "add", "path": "Values/1/Value", "value": "true"}])

    Output := aad.tests with input.directory_settings as [Settings]

    TestResult("MS.AAD.5.4v1", Output, FAIL, false) == true
}

test_Value_Incorrect_Uppercase if {
    Settings := json.patch(DirectorySettings, [{"op": "add", "path": "Values/1/Value", "value": "True"}])

    Output := aad.tests with input.directory_settings as [Settings]

    TestResult("MS.AAD.5.4v1", Output, FAIL, false) == true
}
#--