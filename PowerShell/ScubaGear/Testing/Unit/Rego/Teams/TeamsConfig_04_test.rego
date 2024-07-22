package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.TEAMS.4.1v1
#--
test_AllowEmailIntoChannel_Correct_V1 if {
    Output := teams.tests with input.client_configuration as [ClientConfiguration]
                            with input.teams_tenant_info as [TeamsTenantInfo]

    TestResult("MS.TEAMS.4.1v1", Output, PASS, true) == true
}

test_AllowEmailIntoChannel_Correct_V1_multi if {
    Config := json.patch(ClientConfiguration, [{"op": "add", "path": "Identity", "value": "Tag:AllOn"}])

    Output := teams.tests with input.client_configuration as [ClientConfiguration, Config]
                            with input.teams_tenant_info as [TeamsTenantInfo]

    TestResult("MS.TEAMS.4.1v1", Output, PASS, true) == true
}

test_AllowEmailIntoChannel_Incorrect if {
    Config := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])

    Output := teams.tests with input.client_configuration as [Config]
                            with input.teams_tenant_info as [TeamsTenantInfo]

    TestResult("MS.TEAMS.4.1v1", Output, FAIL, false) == true
}

test_AllowEmailIntoChannel_Incorrect_multi if {
    Config1 := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Config2 := json.patch(ClientConfiguration,
                    [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                    {"op": "add", "path": "AllowEmailIntoChannel", "value": true}])

    Output := teams.tests with input.client_configuration as [Config1, Config2]
                            with input.teams_tenant_info as [TeamsTenantInfo]

    TestResult("MS.TEAMS.4.1v1", Output, FAIL, false) == true
}

test_AllowEmailIntoChannel_Correct_V2 if {
    Tenant := json.patch(TeamsTenantInfo, [{"op": "add", "path": "AssignedPlan/1", "value": "Teams_GCC"}])

    Output := teams.tests with input.client_configuration as [ClientConfiguration]
                            with input.teams_tenant_info as [Tenant]

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V2_multi if {
    Config := json.patch(ClientConfiguration, [{"op": "add", "path": "Identity", "value": "Tag:AllOn"}])
    Tenant := json.patch(TeamsTenantInfo, [{"op": "add", "path": "AssignedPlan/1", "value": "TEAMS_GCCHIGH"}])

    Output := teams.tests with input.client_configuration as [ClientConfiguration, Config]
                            with input.teams_tenant_info as [Tenant]

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V3 if {
    Config := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Tenant := json.patch(TeamsTenantInfo, [{"op": "add", "path": "AssignedPlan/1", "value": "TEAMS_GCC"}])

    Output := teams.tests with input.client_configuration as [Config]
                            with input.teams_tenant_info as [Tenant]

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V3_multi if {
    Config1 := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Config2 := json.patch(ClientConfiguration,
                    [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                    {"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Tenant := json.patch(TeamsTenantInfo, [{"op": "add", "path": "AssignedPlan/1", "value": "TEAMS_GCC"}])

    Output := teams.tests with input.client_configuration as [Config1, Config2]
                            with input.teams_tenant_info as [Tenant]

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V4 if {
    Config1 := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Config2 := json.patch(ClientConfiguration,
                    [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                    {"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Tenant := json.patch(TeamsTenantInfo, [{"op": "add", "path": "AssignedPlan/1", "value": "TEAMS_GCCHIGH"}])

    Output := teams.tests with input.client_configuration as [Config1, Config2]
                            with input.teams_tenant_info as [Tenant]

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}

test_AllowEmailIntoChannel_Correct_V4_multi if {
    Config1 := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Config2 := json.patch(ClientConfiguration,
                    [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                    {"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Tenant := json.patch(TeamsTenantInfo, [{"op": "add", "path": "AssignedPlan/1", "value": "TEAMS_GCCHIGH"}])

    Output := teams.tests with input.client_configuration as [Config1, Config2]
                            with input.teams_tenant_info as [Tenant]

    ReportDetailString := "N/A: Feature is unavailable in GCC environments"
    TestResult("MS.TEAMS.4.1v1", Output, ReportDetailString, true) == true
}
#--