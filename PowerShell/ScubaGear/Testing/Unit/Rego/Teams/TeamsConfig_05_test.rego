package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.TestResultContains
import data.utils.key.PASS


#
# Policy MS.TEAMS.5.1v2 - Always uses v2 policy ID, checks tenant settings if available, otherwise legacy
#--
test_DefaultCatalogAppsType_Correct_V1 if {
    # No tenant_app_settings, should check legacy policies
    Output := teams.tests with input.app_policies as [AppPolicies]

    TestResult("MS.TEAMS.5.1v2", Output, PASS, true) == true
}

test_DefaultCatalogAppsType_Correct_V1_V2 if {
    # No tenant_app_settings, should check legacy policies
    App := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"}])

    Output := teams.tests with input.app_policies as [App]

    TestResult("MS.TEAMS.5.1v2", Output, PASS, true) == true
}

test_DefaultCatalogAppsType_Incorrect_V1 if {
    # No tenant_app_settings, legacy policy non-compliant
    App := json.patch(AppPolicies, [{"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    # Should report legacy policy failure with context
    ReportDetailArrayStrs := [
        "1 app permission policy(ies) found that does not restrict installation of Microsoft Apps by default:",
        "Global"
    ]

    TestResultContains("MS.TEAMS.5.1v2", Output, ReportDetailArrayStrs, false) == true
}

test_DefaultCatalogAppsType_Incorrect_V1_V2 if {
    # No tenant_app_settings, legacy policy non-compliant
    App := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                {"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailArrayStrs := [
        "1 app permission policy(ies) found that does not restrict installation of Microsoft Apps by default:",
        "Tag:TestPolicy"
    ]

    TestResultContains("MS.TEAMS.5.1v2", Output, ReportDetailArrayStrs, false) == true
}

test_DefaultCatalogAppsType_Multiple_V1 if {
    # No tenant_app_settings, multiple legacy policies non-compliant
    App1 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy1"},
                {"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])
    App2 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy2"},
                {"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [AppPolicies, App1, App2]

    ReportDetailArrayStrs := [
        "2 app permission policy(ies) found that does not restrict installation of Microsoft Apps by default: ",
        "Tag:TestPolicy1",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.1v2", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.5.1v2 - With tenant_app_settings available
#--
test_DefaultCatalogAppsType_Correct_V2 if {
    TenantSettings := [{"SettingName": "DefaultApp", "SettingValue": "None"}]
    Output := teams.tests with input.app_policies as [AppPolicies]
                        with input.tenant_app_settings as TenantSettings

    TestResult("MS.TEAMS.5.1v2", Output, PASS, true) == true
}

test_DefaultCatalogAppsType_Incorrect_V2 if {
    TenantSettings := [{"SettingName": "DefaultApp", "SettingValue": "AllowedApps"}]
    Output := teams.tests with input.app_policies as [AppPolicies]
                        with input.tenant_app_settings as TenantSettings

    ReportDetailStr := "Org-wide tenant setting (Microsoft apps): AllowedApps - Non-compliant (should be set to None)"

    TestResult("MS.TEAMS.5.1v2", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.TEAMS.5.2v2 - Always uses v2 policy ID, checks tenant settings if available, otherwise legacy
#--
test_GlobalCatalogAppsType_Correct_V1 if {
    # No tenant_app_settings, should check legacy policies
    Output := teams.tests with input.app_policies as [AppPolicies]

    TestResult("MS.TEAMS.5.2v2", Output, PASS, true) == true
}

test_GlobalCatalogAppsType_Correct_V1_V2 if {
    # No tenant_app_settings, should check legacy policies
    App := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"}])

    Output := teams.tests with input.app_policies as [App]

    TestResult("MS.TEAMS.5.2v2", Output, PASS, true) == true
}

test_GlobalCatalogAppsType_Incorrect_V1 if {
    # No tenant_app_settings, legacy policy non-compliant
    App := json.patch(AppPolicies, [{"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailArrayStrs := [
        "1 app permission policy(ies) found that does not restrict installation of third-party apps by default:",
        "Global"
    ]

    TestResultContains("MS.TEAMS.5.2v2", Output, ReportDetailArrayStrs, false) == true
}

test_GlobalCatalogAppsType_Incorrect_V1_V2 if {
    # No tenant_app_settings, legacy policy non-compliant
    App := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                {"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailArrayStrs := [
        "1 app permission policy(ies) found that does not restrict installation of third-party apps by default:",
        "Tag:TestPolicy"
    ]

    TestResultContains("MS.TEAMS.5.2v2", Output, ReportDetailArrayStrs, false) == true
}

test_GlobalCatalogAppsType_Multiple_V1 if {
    # No tenant_app_settings, multiple legacy policies non-compliant
    App1 := json.patch(AppPolicies, [{"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])
    App2 := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy1"}])
    App3 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy2"},
                {"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App1, App2, App3]

    ReportDetailArrayStrs := [
        "2 app permission policy(ies) found that does not restrict installation of third-party apps by default: ",
        "Global",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.2v2", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.5.2v2 - With tenant_app_settings available
#--
test_GlobalCatalogAppsType_Correct_V2 if {
    TenantSettings := [{"SettingName": "GlobalApp", "SettingValue": "None"}]
    Output := teams.tests with input.app_policies as [AppPolicies]
                        with input.tenant_app_settings as TenantSettings

    TestResult("MS.TEAMS.5.2v2", Output, PASS, true) == true
}

test_GlobalCatalogAppsType_Incorrect_V2 if {
    TenantSettings := [{"SettingName": "GlobalApp", "SettingValue": "AllowedApps"}]
    Output := teams.tests with input.app_policies as [AppPolicies]
                        with input.tenant_app_settings as TenantSettings

    ReportDetailStr := "Org-wide tenant setting (third-party apps): AllowedApps - Non-compliant (should be set to None)"

    TestResult("MS.TEAMS.5.2v2", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.TEAMS.5.3v2 - Always uses v2 policy ID, checks tenant settings if available, otherwise legacy
#--
test_PrivateCatalogAppsType_Correct_V1 if {
    # No tenant_app_settings, should check legacy policies
    Output := teams.tests with input.app_policies as [AppPolicies]

    TestResult("MS.TEAMS.5.3v2", Output, PASS, true) == true
}

test_PrivateCatalogAppsType_Correct_V1_V2 if {
    # No tenant_app_settings, should check legacy policies
    App := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"}])

    Output := teams.tests with input.app_policies as [App]

    TestResult("MS.TEAMS.5.3v2", Output, PASS, true) == true
}

test_PrivateCatalogAppsType_Incorrect_V1 if {
    # No tenant_app_settings, legacy policy non-compliant
    App := json.patch(AppPolicies, [{"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailArrayStrs := [
        "1 app permission policy(ies) found that does not restrict installation of custom apps by default:",
        "Global"
    ]

    TestResultContains("MS.TEAMS.5.3v2", Output, ReportDetailArrayStrs, false) == true
}

test_PrivateCatalogAppsType_Incorrect_V1_V2 if {
    # No tenant_app_settings, legacy policy non-compliant
    App := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                {"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailArrayStrs := [
        "1 app permission policy(ies) found that does not restrict installation of custom apps by default:",
        "Tag:TestPolicy"
    ]

    TestResultContains("MS.TEAMS.5.3v2", Output, ReportDetailArrayStrs, false) == true
}

test_PrivateCatalogAppsType_Multiple_V1 if {
    # No tenant_app_settings, multiple legacy policies non-compliant
    App1 := json.patch(AppPolicies, [{"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])
    App2 := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy1"}])
    App3 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy2"},
                {"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App1, App2, App3]

    ReportDetailArrayStrs := [
        "2 app permission policy(ies) found that does not restrict installation of custom apps by default: ",
        "Global",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.3v2", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.5.3v2 - With tenant_app_settings available
#--
test_PrivateCatalogAppsType_Correct_V2 if {
    TenantSettings := [{"SettingName": "PrivateApp", "SettingValue": "None"}]
    Output := teams.tests with input.app_policies as [AppPolicies]
                        with input.tenant_app_settings as TenantSettings

    TestResult("MS.TEAMS.5.3v2", Output, PASS, true) == true
}

test_PrivateCatalogAppsType_Incorrect_V2 if {
    TenantSettings := [{"SettingName": "PrivateApp", "SettingValue": "AllowedApps"}]
    Output := teams.tests with input.app_policies as [AppPolicies]
                        with input.tenant_app_settings as TenantSettings

    ReportDetailStr := "Org-wide tenant setting (custom apps): AllowedApps - Non-compliant (should be set to None)"

    TestResult("MS.TEAMS.5.3v2", Output, ReportDetailStr, false) == true
}
#--
