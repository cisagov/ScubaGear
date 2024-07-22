package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.TEAMS.2.1v1
#--
test_AllowFederatedUsers_Correct_V1 if {
    Config := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowedDomains", "value": []}])

    Output := teams.tests with input.federation_configuration as [Config]

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowFederatedUsers_Correct_V2 if {
    Output := teams.tests with input.federation_configuration as [FederationConfiguration]

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowedDomains_Correct if {
    Config := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowFederatedUsers", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config]

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowedDomains_Incorrect if {
    Config := json.patch(FederationConfiguration,
                [{"op": "add", "path": "AllowFederatedUsers", "value": true},
                {"op": "add", "path": "AllowedDomains", "value": []}])

    Output := teams.tests with input.federation_configuration as [Config]

    ReportDetailStr := "1 meeting policy(ies) that allow external access across all domains: Global"
    TestResult("MS.TEAMS.2.1v1", Output, ReportDetailStr, false) == true
}

test_AllowFederatedUsers_Correct_V1_multi if {
    Config1 := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                {"op": "add", "path": "AllowedDomains", "value": []}])
    Config2 := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowedDomains", "value": []}])

    Output := teams.tests with input.federation_configuration as [Config1, Config2]

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowFederatedUsers_Correct_V2_multi if {
    Config := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"}])

    Output := teams.tests with input.federation_configuration as [FederationConfiguration, Config]

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}


test_AllowedDomains_Correct_multi if {
    Config1 := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                {"op": "add", "path": "AllowFederatedUsers", "value": true}])
    Config2 := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowFederatedUsers", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config1, Config2]

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowedDomains_Incorrect_multi if {
    Config1 := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                {"op": "add", "path": "AllowedDomains", "value": []},
                {"op": "add", "path": "AllowFederatedUsers", "value": true}])
    Config2 := json.patch(FederationConfiguration,
                [{"op": "add", "path": "AllowedDomains", "value": []},
                {"op": "add", "path": "AllowFederatedUsers", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config1, Config2]

    ReportDetailStr := "2 meeting policy(ies) that allow external access across all domains: Global, Tag:AllOn"
    TestResult("MS.TEAMS.2.1v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.TEAMS.2.2v1
#--
test_AllowTeamsConsumerInbound_Correct_V1 if {
    Output := teams.tests with input.federation_configuration as [FederationConfiguration]

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumerInbound_Correct_V1_multi if {
    Config := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"}])

    Output := teams.tests with input.federation_configuration as [FederationConfiguration, Config]

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumerInbound_Correct_V2 if {
    Config := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowTeamsConsumerInbound", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config]

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumerInbound_Correct_V2_multi if {
    Config1 := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                {"op": "add", "path": "AllowTeamsConsumerInbound", "value": true}])
    Config2 := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowTeamsConsumerInbound", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config1, Config2]

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumer_Incorrect_V1 if {
    Config := json.patch(FederationConfiguration,
                [{"op": "add", "path": "AllowTeamsConsumer", "value": true},
                {"op": "add", "path": "AllowTeamsConsumerInbound", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config]

    ReportDetailStr :=
        "1 Configuration allowed unmanaged users to initiate contact with internal user across domains: Global"
    TestResult("MS.TEAMS.2.2v1", Output, ReportDetailStr, false) == true
}

test_AllowTeamsConsumer_Incorrect_multi_V1 if {
    Config1 := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                {"op": "add", "path": "AllowTeamsConsumer", "value": true},
                {"op": "add", "path": "AllowTeamsConsumerInbound", "value": true}])
    Config2 := json.patch(FederationConfiguration,
                [{"op": "add", "path": "AllowTeamsConsumer", "value": true},
                {"op": "add", "path": "AllowTeamsConsumerInbound", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config1, Config2]

    ReportDetailStr :=concat(" ", [
        "2 Configuration allowed unmanaged users to initiate contact with internal user across domains:",
        "Global, Tag:AllOn"
    ])

    TestResult("MS.TEAMS.2.2v1", Output, ReportDetailStr, false) == true
}

test_AllowTeamsConsumer_Correct_V1 if {
    Config := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowTeamsConsumer", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config]

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumer_Correct_multi_V1 if {
    Config1 := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                {"op": "add", "path": "AllowTeamsConsumer", "value": true}])
    Config2 := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowTeamsConsumer", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config1, Config2]

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}
#--

#
# Policy MS.TEAMS.2.3v1
#--
test_AllowTeamsConsumer_Correct_V2 if {
    Output := teams.tests with input.federation_configuration as [FederationConfiguration]

    TestResult("MS.TEAMS.2.3v1", Output, PASS, true) == true
}

test_AllowTeamsConsumer_Correct_multi_V2 if {
    Config := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"}])

    Output := teams.tests with input.federation_configuration as [FederationConfiguration, Config]

    TestResult("MS.TEAMS.2.3v1", Output, PASS, true) == true
}

test_AllowTeamsConsumer_Incorrect_V2 if {
    Config := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowTeamsConsumer", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config]

    ReportDetailStr := "1 Internal users are enabled to initiate contact with unmanaged users across domains: Global"
    TestResult("MS.TEAMS.2.3v1", Output, ReportDetailStr, false) == true
}

test_AllowTeamsConsumer_Incorrect_multi_V2 if {
    Config1 := json.patch(FederationConfiguration,
                [{"op": "add", "path": "Identity", "value": "Tag:AllOn"},
                {"op": "add", "path": "AllowTeamsConsumer", "value": true}])
    Config2 := json.patch(FederationConfiguration, [{"op": "add", "path": "AllowTeamsConsumer", "value": true}])

    Output := teams.tests with input.federation_configuration as [Config1, Config2]

    ReportDetailStr := concat(" ", [
        "2 Internal users are enabled to initiate contact with unmanaged users across domains:",
        "Global, Tag:AllOn"
    ])

    TestResult("MS.TEAMS.2.3v1", Output, ReportDetailStr, false) == true
}
#--