package teams_test
import future.keywords
import data.teams
import data.report.utils.ReportDetailsBoolean


CorrectTestResult(PolicyId, Output, ReportDetailString) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == true
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false

IncorrectTestResult(PolicyId, Output, ReportDetailString) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false

PASS := ReportDetailsBoolean(true)

#
# Policy MS.TEAMS.2.1v1
#--
test_AllowFederatedUsers_Correct_V1 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers" : false,
                "AllowedDomains": []
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.1v1", Output, PASS) == true
}

test_AllowFederatedUsers_Correct_V2 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers" : false,
                "AllowedDomains": [
                    {
                        "AllowedDomain": ["Domain=test365.cisa.dhs.gov"]
                    }
                ]
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.1v1", Output, PASS) == true
}

test_AllowedDomains_Correct if {
    Output := teams.tests with input as {
        "federation_configuration":[
            {
                "Identity": "Global",
                "AllowFederatedUsers" : true,
                "AllowedDomains": [
                    {
                        "AllowedDomain": ["Domain=test365.cisa.dhs.gov"]
                    }
                ]
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.1v1", Output, PASS) == true
}

test_AllowedDomains_Incorrect if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers" : true,
                "AllowedDomains": []
            }
        ]
    }

    ReportDetailString := "1 meeting policy(ies) that allow external access across all domains: Global"
    IncorrectTestResult("MS.TEAMS.2.1v1", Output, ReportDetailString) == true
}

test_AllowFederatedUsers_Correct_V1_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers" : false,
                "AllowedDomains": []
            },
            {
                "Identity": "Tag:AllOn",
                "AllowFederatedUsers" : false,
                "AllowedDomains": []
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.1v1", Output, PASS) == true
}

test_AllowFederatedUsers_Correct_V2_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers" : false,
                "AllowedDomains": [
                    {
                        "AllowedDomain": ["Domain=test365.cisa.dhs.gov"]
                    }
                ]
            },
            {
                "Identity": "Tag:AllOn",
                "AllowFederatedUsers" : false,
                "AllowedDomains": [
                    {
                        "AllowedDomain": ["Domain=test365.cisa.dhs.gov"]
                    }
                ]
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.1v1", Output, PASS) == true
}


test_AllowedDomains_Correct_multi if {
    Output := teams.tests with input as {
        "federation_configuration":[
            {
                "Identity": "Global",
                "AllowFederatedUsers" : true,
                "AllowedDomains": [
                    {
                        "AllowedDomain": ["Domain=test365.cisa.dhs.gov"]
                    }
                ]
            },
            {
                "Identity": "Tag:AllOn",
                "AllowFederatedUsers" : true,
                "AllowedDomains": [
                    {
                        "AllowedDomain": ["Domain=test365.cisa.dhs.gov"]
                    }
                ]
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.1v1", Output, PASS) == true
}

test_AllowedDomains_Incorrect_multi if {
    Output := teams.tests with input as {
        "federation_configuration":[
            {
                "Identity": "Global",
                "AllowFederatedUsers" : true,
                "AllowedDomains": []
            },
            {
                "Identity": "Tag:AllOn",
                "AllowFederatedUsers" : true,
                "AllowedDomains": []
            }
        ]
    }

    ReportDetailString := "2 meeting policy(ies) that allow external access across all domains: Global, Tag:AllOn"
    IncorrectTestResult("MS.TEAMS.2.1v1", Output, ReportDetailString) == true
}
#--

#
# Policy MS.TEAMS.2.2v1
#--
test_AllowTeamsConsumerInbound_Correct_V1 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.2v1", Output, PASS) == true
}

test_AllowTeamsConsumerInbound_Correct_V1_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.2v1", Output, PASS) == true
}

test_AllowTeamsConsumerInbound_Correct_V2 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.2v1", Output, PASS) == true
}

test_AllowTeamsConsumerInbound_Correct_V2_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": true
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.2v1", Output, PASS) == true
}

test_AllowTeamsConsumer_Incorrect if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    ReportDetailString := "1 Configuration allowed unmanaged users to initiate contact with internal user across domains: Global"
    IncorrectTestResult("MS.TEAMS.2.2v1", Output, ReportDetailString) == true
}

test_AllowTeamsConsumer_Incorrect_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": true
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    ReportDetailString := "2 Configuration allowed unmanaged users to initiate contact with internal user across domains: Global, Tag:AllOn"
    IncorrectTestResult("MS.TEAMS.2.2v1", Output, ReportDetailString) == true
}

test_AllowTeamsConsumer_Correct if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.2v1", Output, PASS) == true
}

test_AllowTeamsConsumer_Correct_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.2v1", Output, PASS) == true
}
#--

#
# Policy MS.TEAMS.2.3v1
#--
test_AllowTeamsConsumer_Correct if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.3v1", Output, PASS) == true
}

test_AllowTeamsConsumer_Correct_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.2.3v1", Output, PASS) == true
}

test_AllowTeamsConsumer_Incorrect if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    ReportDetailString := "1 Internal users are enabled to initiate contact with unmanaged users across domains: Global"
    IncorrectTestResult("MS.TEAMS.2.3v1", Output, ReportDetailString) == true
}

test_AllowTeamsConsumer_Incorrect_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    ReportDetailString := "2 Internal users are enabled to initiate contact with unmanaged users across domains: Global, Tag:AllOn"
    IncorrectTestResult("MS.TEAMS.2.3v1", Output, ReportDetailString) == true
}
#--