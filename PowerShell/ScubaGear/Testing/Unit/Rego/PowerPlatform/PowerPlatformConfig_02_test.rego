package powerplatform_test
import rego.v1
import data.powerplatform
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.POWERPLATFORM.2.1v1
#--
test_name_Correct if {
    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                  with input.dlp_policies as [DlpPolicies]

    TestResult("MS.POWERPLATFORM.2.1v1", Output, PASS, true) == true
}

test_name_Incorrect if {
    Policies := json.patch(DlpPolicies, [
        {"op": "add", "path": "value/0/environments/0/name", "value": "NotDefault-Test Id"}
    ])

    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                  with input.dlp_policies as [Policies]

    ReportDetailString := "No policy found that applies to default environment"
    TestResult("MS.POWERPLATFORM.2.1v1", Output, ReportDetailString, false) == true
}

test_environmentType_AllEnvironments_Correct_V1 if {
    Policies := json.patch(DlpPolicies, [
        {"op": "add", "path": "value/0/environmentType", "value": "AllEnvironments"},
        {"op": "add", "path": "value/0/environments", "value": []}
    ])

    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                  with input.dlp_policies as [Policies]
                                  with input.environment_list as [EnvironmentList]

    TestResult("MS.POWERPLATFORM.2.1v1", Output, PASS, true) == true
}

test_environmentType_OnlyEnvironments_environmentList_Correct if {
    Policies := json.patch(DlpPolicies, [
        {"op": "add", "path": "value/0/environmentType", "value": "OnlyEnvironments"},
    ])

    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                  with input.dlp_policies as [Policies]
                                  with input.environment_list as [EnvironmentList]

    TestResult("MS.POWERPLATFORM.2.1v1", Output, PASS, true) == true
}

test_environmentType_ExceptEnvironments_Incorrect if {
    Policies := json.patch(DlpPolicies, [
        {"op": "add", "path": "value/0/environmentType", "value": "ExceptEnvironments"},
    ])

    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                  with input.dlp_policies as [Policies]
                                  with input.environment_list as [EnvironmentList]

    ReportDetailString := "No policy found that applies to default environment"
    TestResult("MS.POWERPLATFORM.2.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.POWERPLATFORM.2.2v1
#--
test_environmentList_Correct if {
    Output := powerplatform.tests with input.dlp_policies as [DlpPolicies]
                                  with input.environment_list as [EnvironmentList]

    TestResult("MS.POWERPLATFORM.2.2v1", Output, PASS, true) == true
}

test_environmentType_AllEnvironments_Correct_V2 if {
    Policies := json.patch(DlpPolicies, [
        {"op": "add", "path": "value/0/environmentType", "value": "AllEnvironments"},
        {"op": "add", "path": "value/0/environments", "value": []},
    ])
    
    Output := powerplatform.tests with input.dlp_policies as [Policies]
                                  with input.environment_list as [EnvironmentList]

    TestResult("MS.POWERPLATFORM.2.2v1", Output, PASS, true) == true
}

test_environmentType_ExceptEnvironments_Correct if {
    Policies := json.patch(DlpPolicies, [
        {"op": "add", "path": "value/0/environmentType", "value": "ExceptEnvironments"}
    ])
    
    Output := powerplatform.tests with input.dlp_policies as [Policies]
                                  with input.environment_list as [EnvironmentList]

    TestResult("MS.POWERPLATFORM.2.2v1", Output, PASS, true) == true
}

test_environmentList_Incorrect if {
    Env := json.patch(EnvironmentList, [
        {"op": "add", "path": "0/EnvironmentName", "value": "NotDefault-Test Id"},
        {"op": "add", "path": "0/IsDefault", "value": false}
    ])

    Output := powerplatform.tests with input.dlp_policies as [DlpPolicies]
                                  with input.environment_list as Env

    ReportDetailString := "2 subsequent environments without DLP policies: NotDefault-Test Id, Test2"
    TestResult("MS.POWERPLATFORM.2.2v1", Output, ReportDetailString, false) == true
}

test_environmentType_ExceptEnvironments_environmentList_Incorrect if {
    Env := json.patch(EnvironmentList, [
        {"op": "add", "path": "0/EnvironmentName", "value": "NotIncludedEnvironment1"},
        {"op": "add", "path": "0/IsDefault", "value": false}
    ])

    Policies := json.patch(DlpPolicies, [
        {"op": "add", "path": "value/0/environmentType", "value": "ExceptEnvironments"},
        {"op": "add", "path": "value/0/environments/0/name", "value": "Test1"},
        {"op": "add", "path": "value/0/environments/1/name", "value": "Test2"}
    ])

    Output := powerplatform.tests with input.dlp_policies as [Policies]
                                  with input.environment_list as Env

    ReportDetailString := "1 subsequent environments without DLP policies: NotIncludedEnvironment1"
    TestResult("MS.POWERPLATFORM.2.2v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.POWERPLATFORM.2.3v1
#--
test_classification_Correct_V1 if {
    Policies := json.patch(DlpPolicies, [{"op": "remove", "path": "value/0/connectorGroups/1"}])

    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                    with input.dlp_policies as [Policies]

    TestResult("MS.POWERPLATFORM.2.3v1", Output, PASS, true) == true
}

test_classification_Correct_V2 if {
    Policies := json.patch(DlpPolicies, [{"op": "remove", "path": "value/0/connectorGroups/0"}])

    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                    with input.dlp_policies as [Policies]

    TestResult("MS.POWERPLATFORM.2.3v1", Output, PASS, true) == true
}

test_connectorGroups_Correct if {
    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                    with input.dlp_policies as [DlpPolicies]

    TestResult("MS.POWERPLATFORM.2.3v1", Output, PASS, true) == true
}

test_classification_Incorrect_V1 if {
    Policies := json.patch(DlpPolicies,
                    [{"op": "remove", "path": "value/0/connectorGroups/1"},
                    {"op": "add", "path": "value/0/connectorGroups/0/connectors/0/id", "value": "HttpWebhook"}])

    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                    with input.dlp_policies as [Policies]

    ReportDetailString := "1 Connectors are allowed that should be blocked: HttpWebhook"
    TestResult("MS.POWERPLATFORM.2.3v1", Output, ReportDetailString, false) == true
}

test_classification_Incorrect_V2 if {
    Policies := json.patch(DlpPolicies,
                    [{"op": "remove", "path": "value/0/connectorGroups/0"},
                    {"op": "add", "path": "value/0/connectorGroups/0/connectors/0/id", "value": "HttpWebhook"}])

    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                    with input.dlp_policies as [Policies]

    ReportDetailString := "1 Connectors are allowed that should be blocked: HttpWebhook"
    TestResult("MS.POWERPLATFORM.2.3v1", Output, ReportDetailString, false) == true
}

test_connectorGroups_Incorrect if {
    Policies := json.patch(DlpPolicies,
                    [{"op": "add", "path": "value/0/connectorGroups/0/connectors/0/id", "value": "HttpWebhook"},
                    {"op": "add", "path": "value/0/connectorGroups/1/connectors/0/id", "value": "HttpWebhook"}])

    Output := powerplatform.tests with input.tenant_id as "Test Id"
                                    with input.dlp_policies as [Policies]

    ReportDetailString := "1 Connectors are allowed that should be blocked: HttpWebhook"
    TestResult("MS.POWERPLATFORM.2.3v1", Output, ReportDetailString, false) == true
}
#--