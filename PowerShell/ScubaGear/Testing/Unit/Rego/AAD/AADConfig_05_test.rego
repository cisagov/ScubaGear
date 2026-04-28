package aad_test
import rego.v1
import data.aad
import data.utils.key.TestResult
import data.utils.key.TestResultContains
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
                    "ManagePermissionGrantsForSelf.microsoft-user-default-recommended"
                ]}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow Microsoft to manage consent settings:",
        "<br/>authorizationPolicy"
    ])

    TestResult("MS.AAD.5.2v1", Output, ReportDetailStr, false) == true
}

test_UserConsentAllowedNoRiskyDelegatedPermissionClassifications_Correct if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "PermissionGrantPolicyIdsAssignedToDefaultUserRole",
                "value": [
                    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
                    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-team",
                    "ManagePermissionGrantsForSelf.microsoft-user-default-low"
                ]}])

    Output := aad.tests with input.authorization_policies as [Policies]

    ReportDetailStr := concat("", [
        "0 authorization policies found that allow non-admin users to consent to third-party applications"
    ])

    TestResult("MS.AAD.5.2v1", Output, ReportDetailStr, true) == true
}

test_UserConsentAllowedWithRiskyDelegatedPermissionClassifications_Incorrect if {
    Policies := json.patch(AuthorizationPolicies,
                [{"op": "add", "path": "PermissionGrantPolicyIdsAssignedToDefaultUserRole",
                "value": [
                    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
                    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-team",
                    "ManagePermissionGrantsForSelf.microsoft-user-default-low"
                ]}])

    RiskyClassifications := json.patch(Classifications,
                [{"op": "add", "path": "RiskyPermClassifications",
                "value": [
                    "Mail.Read",
                    "Mail.Send"
                ]}])

    Output := aad.tests with input.authorization_policies as [Policies]
        with input.risky_delegated_permission_classifications as [RiskyClassifications]

    ReportDetailStr := concat("", [
        "1 authorization policies found that allow non-admin users to consent to ",
        "third-party applications with risky delegated permission classifications:",
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
# Policy MS.AAD.5.5v1
#--
test_PasswordAdditionBlocked_Correct if {
    Output := aad.tests with input.app_management_policy as [AppManagementPolicy]

    TestResult("MS.AAD.5.5v1", Output, "0 password/symmetric key addition restriction(s) not meeting requirements"assword/symmetric key addition restriction(s) not meeting requirements", true) == true
}

test_PasswordAdditionBlocked_Incorrect_V1 if {
    Policy := json.patch(AppManagementPolicy,
                [{"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/0/State", "value": "disabled"}])

    Output := aad.tests with input.app_management_policy as [Policy]

    TestResultContains("MS.AAD.5.5v1", Output, ["passwordAddition (Applications): restriction is not enabled"]ut, ["passwordAddition (Applications): restriction is not enabled"], false) == true
}

test_PasswordAdditionBlocked_Incorrect_V2 if {
    Policy := json.patch(AppManagementPolicy,
                [{"op": "add", "path": "ServicePrincipalRestrictions/PasswordCredentials/1/State", "value": "disabled"}])

    Output := aad.tests with input.app_management_policy as [Policy]

    TestResultContains("MS.AAD.5.5v1", Output, ["symmetricKeyAddition (ServicePrincipals): restriction is not enabled"]ut, ["symmetricKeyAddition (ServicePrincipals): restriction is not enabled"], false) == true
}

test_PasswordAdditionBlocked_Incorrect_V3 if {
    # Setting a specific date means old apps are exempt from the restriction
    Policy := json.patch(AppManagementPolicy,
                [{"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/0/RestrictForAppsCreatedAfterDateTime", "value": "/Date(1700000000000)/"}])

    Output := aad.tests with input.app_management_policy as [Policy]

    TestResultContains("MS.AAD.5.5v1", Output, ["passwordAddition (Applications): date restriction set, old apps are exempt"]ut, ["passwordAddition (Applications): date restriction set, old apps are exempt"], false) == true
}
#--

#
# Policy MS.AAD.5.6v1
#--
test_PasswordLifetimeRestricted_Correct if {
    Output := aad.tests with input.app_management_policy as [AppManagementPolicy]

    TestResult("MS.AAD.5.6v1", Output, "N/A: All password addition is blocked per MS.AAD.5.5v1.", true) == true
}

test_PasswordLifetimeRestricted_PasswordAdditionAllowed_Correct if {
    Policy := json.patch(AppManagementPolicy,
                [{"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/0/State", "value": "disabled"},
                 {"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/1/State", "value": "disabled"},
                 {"op": "add", "path": "ServicePrincipalRestrictions/PasswordCredentials/0/State", "value": "disabled"},
                 {"op": "add", "path": "ServicePrincipalRestrictions/PasswordCredentials/1/State", "value": "disabled"}])

    Output := aad.tests with input.app_management_policy as [Policy]

    TestResult("MS.AAD.5.6v1", Output, "0 password/symmetric key lifetime restriction(s) not meeting requirements"assword/symmetric key lifetime restriction(s) not meeting requirements", true) == true
}

test_PasswordLifetimeRestricted_Incorrect_TooLong if {
    Policy := json.patch(AppManagementPolicy,
                [{"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/0/State", "value": "disabled"},
                 {"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/1/State", "value": "disabled"},
                 {"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/3/MaxLifetime", "value": "P182D"},
                 {"op": "add", "path": "ServicePrincipalRestrictions/PasswordCredentials/0/State", "value": "disabled"},
                 {"op": "add", "path": "ServicePrincipalRestrictions/PasswordCredentials/1/State", "value": "disabled"}])

    Output := aad.tests with input.app_management_policy as [Policy]

    TestResult("MS.AAD.5.6v1", Output, FAIL, false) == true
}

test_PasswordLifetimeRestricted_Incorrect_DateRestriction if {
    # Setting a specific date means old apps are exempt from the lifetime restriction
    Policy := json.patch(AppManagementPolicy,
                [{"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/0/State", "value": "disabled"},
                 {"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/1/State", "value": "disabled"},
                 {"op": "add", "path": "ServicePrincipalRestrictions/PasswordCredentials/0/State", "value": "disabled"},
                 {"op": "add", "path": "ServicePrincipalRestrictions/PasswordCredentials/1/State", "value": "disabled"},
                 {"op": "add", "path": "ApplicationRestrictions/PasswordCredentials/3/RestrictForAppsCreatedAfterDateTime", "value": "/Date(1700000000000)/"}])

    Output := aad.tests with input.app_management_policy as [Policy]

    TestResultContains("MS.AAD.5.6v1", Output, ["passwordLifetime (Applications): date restriction set, old apps are exempt"]ut, ["passwordLifetime (Applications): date restriction set, old apps are exempt"], false) == true
}
#--

#
# Policy MS.AAD.5.7v1
#--
test_CertificateLifetimeRestricted_Correct if {
    Output := aad.tests with input.app_management_policy as [AppManagementPolicy]

    TestResult("MS.AAD.5.7v1", Output, "0 certificate lifetime restriction(s) not meeting requirements"ertificate lifetime restriction(s) not meeting requirements", true) == true
}

test_CertificateLifetimeRestricted_Incorrect_TooLong if {
    Policy := json.patch(AppManagementPolicy,
                [{"op": "add", "path": "ApplicationRestrictions/KeyCredentials/0/MaxLifetime", "value": "P367D"}])

    Output := aad.tests with input.app_management_policy as [Policy]

    TestResultContains("MS.AAD.5.7v1", Output, ["asymmetricKeyLifetime (Applications): MaxLifetime is 367 days, must be 366 days or less"]ut, ["asymmetricKeyLifetime (Applications): MaxLifetime is 367 days, must be 366 days or less"], false) == true
}

test_CertificateLifetimeRestricted_Incorrect_Disabled if {
    Policy := json.patch(AppManagementPolicy,
                [{"op": "add", "path": "ServicePrincipalRestrictions/KeyCredentials/0/State", "value": "disabled"}])

    Output := aad.tests with input.app_management_policy as [Policy]

    TestResultContains("MS.AAD.5.7v1", Output, ["asymmetricKeyLifetime (ServicePrincipals): restriction is not enabled"]ut, ["asymmetricKeyLifetime (ServicePrincipals): restriction is not enabled"], false) == true
}

test_CertificateLifetimeRestricted_Incorrect_DateRestriction if {
    # Setting a specific date means old apps are exempt from the certificate lifetime restriction
    Policy := json.patch(AppManagementPolicy,
                [{"op": "add", "path": "ApplicationRestrictions/KeyCredentials/0/RestrictForAppsCreatedAfterDateTime", "value": "/Date(1700000000000)/"}])

    Output := aad.tests with input.app_management_policy as [Policy]

    TestResultContains("MS.AAD.5.7v1", Output, ["asymmetricKeyLifetime (Applications): date restriction set, old apps are exempt"]ut, ["asymmetricKeyLifetime (Applications): date restriction set, old apps are exempt"], false) == true
}
#--
