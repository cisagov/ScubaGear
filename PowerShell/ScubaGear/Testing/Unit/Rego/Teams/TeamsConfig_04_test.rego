package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.report.CheckedSkippedDetails
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.TEAMS.4.1v1
#--
test_AllowEmailIntoChannel_Correct_V1 if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "commercial"}])
    Output := teams.tests with input.client_configuration as [ClientConfiguration]
                            with input.scuba_config as ScubaConf

    TestResult("MS.TEAMS.4.1v1", Output, PASS, true) == true
}

test_AllowEmailIntoChannel_Correct_V1_multi if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "commercial"}])
    Config := json.patch(ClientConfiguration, [{"op": "add", "path": "Identity", "value": "Tag:AllOn"}])

    Output := teams.tests with input.client_configuration as [ClientConfiguration, Config]
                            with input.scuba_config as ScubaConf

    TestResult("MS.TEAMS.4.1v1", Output, PASS, true) == true
}

test_AllowEmailIntoChannel_Incorrect if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "commercial"}])
    Config := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])

    Output := teams.tests with input.client_configuration as [Config]
                            with input.scuba_config as ScubaConf

    TestResult("MS.TEAMS.4.1v1", Output, FAIL, false) == true
}

test_AllowEmailIntoChannel_Incorrect_multi if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "commercial"}])
    Config1 := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Config2 := json.patch(ClientConfiguration,
                    [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                    {"op": "add", "path": "AllowEmailIntoChannel", "value": true}])

    Output := teams.tests with input.client_configuration as [Config1, Config2]
                            with input.scuba_config as ScubaConf

    TestResult("MS.TEAMS.4.1v1", Output, FAIL, false) == true
}

test_AllowEmailIntoChannel_Correct_V2 if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "gcc"}])

    Output := teams.tests with input.client_configuration as [ClientConfiguration]
                            with input.scuba_config as ScubaConf

    ReportDetailString := "This policy is not applicable to GCC, GCC High, or DOD environments. See %v for more info"
    TestResult("MS.TEAMS.4.1v1", Output, CheckedSkippedDetails("MS.TEAMS.4.1v1", ReportDetailString), true) == true
}

test_AllowEmailIntoChannel_Correct_V2_multi if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "gcchigh"}])
    Config := json.patch(ClientConfiguration, [{"op": "add", "path": "Identity", "value": "Tag:AllOn"}])

    Output := teams.tests with input.client_configuration as [ClientConfiguration, Config]
                            with input.scuba_config as ScubaConf

    ReportDetailString := "This policy is not applicable to GCC, GCC High, or DOD environments. See %v for more info"
    TestResult("MS.TEAMS.4.1v1", Output, CheckedSkippedDetails("MS.TEAMS.4.1v1", ReportDetailString), true) == true
}

test_AllowEmailIntoChannel_Correct_V3 if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "gcc"}])
    Config := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])

    Output := teams.tests with input.client_configuration as [Config]
                            with input.scuba_config as ScubaConf

    ReportDetailString := "This policy is not applicable to GCC, GCC High, or DOD environments. See %v for more info"
    TestResult("MS.TEAMS.4.1v1", Output, CheckedSkippedDetails("MS.TEAMS.4.1v1", ReportDetailString), true) == true
}

test_AllowEmailIntoChannel_Correct_V3_multi if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "gcc"}])
    Config1 := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Config2 := json.patch(ClientConfiguration,
                    [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                    {"op": "add", "path": "AllowEmailIntoChannel", "value": true}])

    Output := teams.tests with input.client_configuration as [Config1, Config2]
                            with input.scuba_config as ScubaConf

    ReportDetailString := "This policy is not applicable to GCC, GCC High, or DOD environments. See %v for more info"
    TestResult("MS.TEAMS.4.1v1", Output, CheckedSkippedDetails("MS.TEAMS.4.1v1", ReportDetailString), true) == true
}

test_AllowEmailIntoChannel_Correct_V4 if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "gcchigh"}])
    Config1 := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Config2 := json.patch(ClientConfiguration,
                    [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                    {"op": "add", "path": "AllowEmailIntoChannel", "value": true}])

    Output := teams.tests with input.client_configuration as [Config1, Config2]
                            with input.scuba_config as ScubaConf

    ReportDetailString := "This policy is not applicable to GCC, GCC High, or DOD environments. See %v for more info"
    TestResult("MS.TEAMS.4.1v1", Output, CheckedSkippedDetails("MS.TEAMS.4.1v1", ReportDetailString), true) == true
}

test_AllowEmailIntoChannel_Correct_V4_multi if {
    ScubaConf := json.patch(ScubaConfig, [{"op": "add", "path": "M365Environment", "value": "gcchigh"}])
    Config1 := json.patch(ClientConfiguration, [{"op": "add", "path": "AllowEmailIntoChannel", "value": true}])
    Config2 := json.patch(ClientConfiguration,
                    [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                    {"op": "add", "path": "AllowEmailIntoChannel", "value": true}])

    Output := teams.tests with input.client_configuration as [Config1, Config2]
                            with input.scuba_config as ScubaConf

    ReportDetailString := "This policy is not applicable to GCC, GCC High, or DOD environments. See %v for more info"
    TestResult("MS.TEAMS.4.1v1", Output, CheckedSkippedDetails("MS.TEAMS.4.1v1", ReportDetailString), true) == true
}
#--