package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.TEAMS.3.1v1
#--
test_AllowPublicUsers_Correct if {
    Output := teams.tests with input.federation_configuration as [FederationConfiguration]

    TestResult("MS.TEAMS.3.1v1", Output, PASS, true) == true
}

test_AllowPublicUsers_Incorrect if {
    Config := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowPublicUsers", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config]

    ReportDetailString := "1 domains that allows contact with Skype users: Global"
    TestResult("MS.TEAMS.3.1v1", Output, ReportDetailString, false) == true
}

test_AllowPublicUsers_Correct_multi if {
    Config := json.patch(FederationConfiguration, [{"op": "add", "path": "Identity", "value": "Tag:AllOn"}])

    Output := teams.tests with input.federation_configuration as [FederationConfiguration, Config]

    TestResult("MS.TEAMS.3.1v1", Output, PASS, true) == true
}

test_AllowPublicUsers_Incorrect_multi if {
    Config1 := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowPublicUsers", "value": true}])
    Config2 := json.patch(FederationConfiguration,
                    [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                    {"op": "add", "path": "AllowPublicUsers", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config1, Config2]

    ReportDetailString := "2 domains that allows contact with Skype users: Global, Tag:AllOn"
    TestResult("MS.TEAMS.3.1v1", Output, ReportDetailString, false) == true
}
#--