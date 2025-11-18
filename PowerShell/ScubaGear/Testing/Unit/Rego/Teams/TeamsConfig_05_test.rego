package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.TestResultContains
import data.utils.key.PASS


#
# Policy MS.TEAMS.5.1v2
#--
test_DefaultCatalogAppsType_Correct_V1 if {
    Output := teams.tests with input.app_policies as [AppPolicies]

    TestResult("MS.TEAMS.5.1v2", Output, PASS, true) == true
}

test_DefaultCatalogAppsType_Correct_V2 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"}])

    Output := teams.tests with input.app_policies as [App]

    TestResult("MS.TEAMS.5.1v2", Output, PASS, true) == true
}

test_DefaultCatalogAppsType_Incorrect_V1 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of Microsoft Apps by default: Global. Org-wide tenant setting (Microsoft apps): Not Checked - If MS.TEAMS.5.1V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.1v2", Output, ReportDetailStr, false) == true
}

test_DefaultCatalogAppsType_Incorrect_V2 if {
    App := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                {"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of Microsoft Apps by default: Tag:TestPolicy. Org-wide tenant setting (Microsoft apps): Not Checked - If MS.TEAMS.5.1V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.1v2", Output, ReportDetailStr, false) == true
}

test_DefaultCatalogAppsType_Multiple if {
    App1 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy1"},
                {"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])
    App2 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy2"},
                {"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [AppPolicies, App1, App2]

    ReportDetailArrayStrs := [
        "Legacy app permission policy check: 2 app permission policy(ies) found that does not restrict installation of Microsoft Apps by default: ",
        "Tag:TestPolicy1",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.1v2", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.5.2v2
#--
test_GlobalCatalogAppsType_Correct_V1 if {
    Output := teams.tests with input.app_policies as [AppPolicies]

    TestResult("MS.TEAMS.5.2v2", Output, PASS, true) == true
}

test_GlobalCatalogAppsType_Correct_V2 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"}])

    Output := teams.tests with input.app_policies as [App]

    TestResult("MS.TEAMS.5.2v2", Output, PASS, true) == true
}

test_GlobalCatalogAppsType_Incorrect_V1 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of third-party apps by default: Global. Org-wide tenant setting (third-party apps): Not Checked - If MS.TEAMS.5.2V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.2v2", Output, ReportDetailStr, false) == true
}

test_GlobalCatalogAppsType_Incorrect_V2 if {
    App := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                {"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of third-party apps by default: Tag:TestPolicy. Org-wide tenant setting (third-party apps): Not Checked - If MS.TEAMS.5.2V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.2v2", Output, ReportDetailStr, false) == true
}

test_GlobalCatalogAppsType_Multiple if {
    App1 := json.patch(AppPolicies, [{"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])
    App2 := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy1"}])
    App3 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy2"},
                {"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App1, App2, App3]

    ReportDetailArrayStrs := [
        "Legacy app permission policy check: 2 app permission policy(ies) found that does not restrict installation of third-party apps by default: ",
        "Global",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.2v2", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.5.3v2
#--
test_PrivateCatalogAppsType_Correct_V1 if {
    Output := teams.tests with input.app_policies as [AppPolicies]

    TestResult("MS.TEAMS.5.3v2", Output, PASS, true) == true
}

test_PrivateCatalogAppsType_Correct_V2 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"}])

    Output := teams.tests with input.app_policies as [App]

    TestResult("MS.TEAMS.5.3v2", Output, PASS, true) == true
}

test_PrivateCatalogAppsType_Incorrect_V1 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of custom apps by default: Global. Org-wide tenant setting (custom apps): Not Checked - If MS.TEAMS.5.3V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.3v2", Output, ReportDetailStr, false) == true
}

test_PrivateCatalogAppsType_Incorrect_V2 if {
    App := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                {"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of custom apps by default: Tag:TestPolicy. Org-wide tenant setting (custom apps): Not Checked - If MS.TEAMS.5.3V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.3v2", Output, ReportDetailStr, false) == true
}

test_PrivateCatalogAppsType_Multiple if {
    App1 := json.patch(AppPolicies, [{"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])
    App2 := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy1"}])
    App3 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy2"},
                {"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App1, App2, App3]

    ReportDetailArrayStrs := [
        "Legacy app permission policy check: 2 app permission policy(ies) found that does not restrict installation of custom apps by default: ",
        "Global",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.3v2", Output, ReportDetailArrayStrs, false) == true
}
#--
package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.TestResultContains
import data.utils.key.PASS


#
# Policy MS.TEAMS.5.1v2
#--
test_DefaultCatalogAppsType_Correct_V1 if {
    Output := teams.tests with input.app_policies as [AppPolicies]

    TestResult("MS.TEAMS.5.1v2", Output, PASS, true) == true
}

test_DefaultCatalogAppsType_Correct_V2 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"}])

    Output := teams.tests with input.app_policies as [App]

    TestResult("MS.TEAMS.5.1v2", Output, PASS, true) == true
}

test_DefaultCatalogAppsType_Incorrect_V1 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of Microsoft Apps by default: Global. Org-wide tenant setting (Microsoft apps): Not Checked - If MS.TEAMS.5.1V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.1v2", Output, ReportDetailStr, false) == true
}

test_DefaultCatalogAppsType_Incorrect_V2 if {
    App := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                {"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of Microsoft Apps by default: Tag:TestPolicy. Org-wide tenant setting (Microsoft apps): Not Checked - If MS.TEAMS.5.1V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.1v2", Output, ReportDetailStr, false) == true
}

test_DefaultCatalogAppsType_Multiple if {
    App1 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy1"},
                {"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])
    App2 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy2"},
                {"op": "add", "path": "DefaultCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [AppPolicies, App1, App2]

    ReportDetailArrayStrs := [
        "Legacy app permission policy check: 2 app permission policy(ies) found that does not restrict installation of Microsoft Apps by default: ",
        "Tag:TestPolicy1",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.1v2", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.5.2v2
#--
test_GlobalCatalogAppsType_Correct_V1 if {
    Output := teams.tests with input.app_policies as [AppPolicies]

    TestResult("MS.TEAMS.5.2v2", Output, PASS, true) == true
}

test_GlobalCatalogAppsType_Correct_V2 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"}])

    Output := teams.tests with input.app_policies as [App]

    TestResult("MS.TEAMS.5.2v2", Output, PASS, true) == true
}

test_GlobalCatalogAppsType_Incorrect_V1 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of third-party apps by default: Global. Org-wide tenant setting (third-party apps): Not Checked - If MS.TEAMS.5.2V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.2v2", Output, ReportDetailStr, false) == true
}

test_GlobalCatalogAppsType_Incorrect_V2 if {
    App := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                {"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of third-party apps by default: Tag:TestPolicy. Org-wide tenant setting (third-party apps): Not Checked - If MS.TEAMS.5.2V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.2v2", Output, ReportDetailStr, false) == true
}

test_GlobalCatalogAppsType_Multiple if {
    App1 := json.patch(AppPolicies, [{"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])
    App2 := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy1"}])
    App3 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy2"},
                {"op": "add", "path": "GlobalCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App1, App2, App3]

    ReportDetailArrayStrs := [
        "Legacy app permission policy check: 2 app permission policy(ies) found that does not restrict installation of third-party apps by default: ",
        "Global",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.2v2", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.5.3v2
#--
test_PrivateCatalogAppsType_Correct_V1 if {
    Output := teams.tests with input.app_policies as [AppPolicies]

    TestResult("MS.TEAMS.5.3v2", Output, PASS, true) == true
}

test_PrivateCatalogAppsType_Correct_V2 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"}])

    Output := teams.tests with input.app_policies as [App]

    TestResult("MS.TEAMS.5.3v2", Output, PASS, true) == true
}

test_PrivateCatalogAppsType_Incorrect_V1 if {
    App := json.patch(AppPolicies, [{"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of custom apps by default: Global. Org-wide tenant setting (custom apps): Not Checked - If MS.TEAMS.5.3V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.3v2", Output, ReportDetailStr, false) == true
}

test_PrivateCatalogAppsType_Incorrect_V2 if {
    App := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                {"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App]

    ReportDetailStr :=
    "Legacy app permission policy check: 1 app permission policy(ies) found that does not restrict installation of custom apps by default: Tag:TestPolicy. Org-wide tenant setting (custom apps): Not Checked - If MS.TEAMS.5.3V2 implemented in the portal, then it requires interactive authentication; legacy policies were validated"

    TestResult("MS.TEAMS.5.3v2", Output, ReportDetailStr, false) == true
}

test_PrivateCatalogAppsType_Multiple if {
    App1 := json.patch(AppPolicies, [{"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])
    App2 := json.patch(AppPolicies, [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy1"}])
    App3 := json.patch(AppPolicies,
                [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy2"},
                {"op": "add", "path": "PrivateCatalogAppsType", "value": "BlockedAppList"}])

    Output := teams.tests with input.app_policies as [App1, App2, App3]

    ReportDetailArrayStrs := [
        "Legacy app permission policy check: 2 app permission policy(ies) found that does not restrict installation of custom apps by default: ",
        "Global",
        "Tag:TestPolicy2"
    ]
    TestResultContains("MS.TEAMS.5.3v2", Output, ReportDetailArrayStrs, false) == true
}
#--
