package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.TEAMS.2.1v1
#--
test_AllowFederatedUsers_Correct_V1 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers": false,
                "AllowedDomains": []
            }
        ]
    }

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowFederatedUsers_Correct_V2 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers": false,
                "AllowedDomains": [
                    {
                        "AllowedDomain": [
                            "Domain=test365.cisa.dhs.gov"
                        ]
                    }
                ]
            }
        ]
    }

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowedDomains_Correct if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers": true,
                "AllowedDomains": [
                    {
                        "AllowedDomain": [
                            "Domain=test365.cisa.dhs.gov"
                        ]
                    }
                ]
            }
        ]
    }

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowedDomains_Incorrect if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers": true,
                "AllowedDomains": []
            }
        ]
    }

    ReportDetailStr := "1 meeting policy(ies) that allow external access across all domains: Global"
    TestResult("MS.TEAMS.2.1v1", Output, ReportDetailStr, false) == true
}

test_AllowFederatedUsers_Correct_V1_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers": false,
                "AllowedDomains": []
            },
            {
                "Identity": "Tag:AllOn",
                "AllowFederatedUsers": false,
                "AllowedDomains": []
            }
        ]
    }

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowFederatedUsers_Correct_V2_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers": false,
                "AllowedDomains": [
                    {
                        "AllowedDomain": [
                            "Domain=test365.cisa.dhs.gov"
                        ]
                    }
                ]
            },
            {
                "Identity": "Tag:AllOn",
                "AllowFederatedUsers": false,
                "AllowedDomains": [
                    {
                        "AllowedDomain": [
                            "Domain=test365.cisa.dhs.gov"
                        ]
                    }
                ]
            }
        ]
    }

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}


test_AllowedDomains_Correct_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers": true,
                "AllowedDomains": [
                    {
                        "AllowedDomain": [
                            "Domain=test365.cisa.dhs.gov"
                        ]
                    }
                ]
            },
            {
                "Identity": "Tag:AllOn",
                "AllowFederatedUsers": true,
                "AllowedDomains": [
                    {
                        "AllowedDomain": [
                            "Domain=test365.cisa.dhs.gov"
                        ]
                    }
                ]
            }
        ]
    }

    TestResult("MS.TEAMS.2.1v1", Output, PASS, true) == true
}

test_AllowedDomains_Incorrect_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers": true,
                "AllowedDomains": []
            },
            {
                "Identity": "Tag:AllOn",
                "AllowFederatedUsers": true,
                "AllowedDomains": []
            }
        ]
    }

    ReportDetailStr := "2 meeting policy(ies) that allow external access across all domains: Global, Tag:AllOn"
    TestResult("MS.TEAMS.2.1v1", Output, ReportDetailStr, false) == true
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
                "AllowTeamsConsumer": false,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumerInbound_Correct_V1_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": false,
                "AllowTeamsConsumerInbound": false
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer": false,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumerInbound_Correct_V2 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": false,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumerInbound_Correct_V2_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": false,
                "AllowTeamsConsumerInbound": true
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer": false,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumer_Incorrect_V1 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": true,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    ReportDetailStr :=
        "1 Configuration allowed unmanaged users to initiate contact with internal user across domains: Global"
    TestResult("MS.TEAMS.2.2v1", Output, ReportDetailStr, false) == true
}

test_AllowTeamsConsumer_Incorrect_multi_V1 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": true,
                "AllowTeamsConsumerInbound": true
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer": true,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    ReportDetailStr :=concat(" ", [
        "2 Configuration allowed unmanaged users to initiate contact with internal user across domains:",
        "Global, Tag:AllOn"
    ])

    TestResult("MS.TEAMS.2.2v1", Output, ReportDetailStr, false) == true
}

test_AllowTeamsConsumer_Correct_V1 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": true,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}

test_AllowTeamsConsumer_Correct_multi_V1 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": true,
                "AllowTeamsConsumerInbound": false
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer": true,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    TestResult("MS.TEAMS.2.2v1", Output, PASS, true) == true
}
#--

#
# Policy MS.TEAMS.2.3v1
#--
test_AllowTeamsConsumer_Correct_V2 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": false,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    TestResult("MS.TEAMS.2.3v1", Output, PASS, true) == true
}

test_AllowTeamsConsumer_Correct_multi_V2 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": false,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer": false,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    TestResult("MS.TEAMS.2.3v1", Output, PASS, true) == true
}

test_AllowTeamsConsumer_Incorrect_V2 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": true,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    ReportDetailStr := "1 Internal users are enabled to initiate contact with unmanaged users across domains: Global"
    TestResult("MS.TEAMS.2.3v1", Output, ReportDetailStr, false) == true
}

test_AllowTeamsConsumer_Incorrect_multi_V2 if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer": true,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            },
            {
                "Identity": "Tag:AllOn",
                "AllowTeamsConsumer": true,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    ReportDetailStr := concat(" ", [
        "2 Internal users are enabled to initiate contact with unmanaged users across domains:",
        "Global, Tag:AllOn"
    ])

    TestResult("MS.TEAMS.2.3v1", Output, ReportDetailStr, false) == true
}
#--