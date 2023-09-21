package teams
import future.keywords


#--
# Policy MS.TEAMS.2.1v1
#--
test_AllowFederatedUsers_Correct_V1 if {
    PolicyId := "MS.TEAMS.2.1v1"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers" : false,
                "AllowedDomains": []
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowFederatedUsers_Correct_V2 if {
    PolicyId := "MS.TEAMS.2.1v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowedDomains_Correct if {
    PolicyId := "MS.TEAMS.2.1v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowedDomains_Incorrect if {
    PolicyId := "MS.TEAMS.2.1v1"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowFederatedUsers" : true,
                "AllowedDomains": []
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) that allow external access across all domains: Global"
}

test_AllowFederatedUsers_Correct_V1_multi if {
    PolicyId := "MS.TEAMS.2.1v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowFederatedUsers_Correct_V2_multi if {
    PolicyId := "MS.TEAMS.2.1v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}


test_AllowedDomains_Correct_multi if {
    PolicyId := "MS.TEAMS.2.1v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowedDomains_Incorrect_multi if {
    PolicyId := "MS.TEAMS.2.1v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "2 meeting policy(ies) that allow external access across all domains: Global, Tag:AllOn"
}

#--
# Policy MS.TEAMS.2.2v1 
#--
test_AllowTeamsConsumerInbound_Correct_V1 if {
    PolicyId := "MS.TEAMS.2.2v1"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumerInbound_Correct_V1_multi if {
    PolicyId := "MS.TEAMS.2.2v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumerInbound_Correct_V2 if {
    PolicyId := "MS.TEAMS.2.2v1"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumerInbound_Correct_V2_multi if {
    PolicyId := "MS.TEAMS.2.2v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumer_Incorrect if {
    PolicyId := "MS.TEAMS.2.2v1"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Configuration allowed unmanaged users to initiate contact with internal user across domains: Global"
}

test_AllowTeamsConsumer_Incorrect_multi if {
    PolicyId := "MS.TEAMS.2.2v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "2 Configuration allowed unmanaged users to initiate contact with internal user across domains: Global, Tag:AllOn"
}

test_AllowTeamsConsumer_Incorrect if {
    PolicyId := "MS.TEAMS.2.2v1"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumer_Incorrect_multi if {
    PolicyId := "MS.TEAMS.2.2v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}
#--
# Policy MS.TEAMS.2.3v1 
#--
test_AllowTeamsConsumer_Correct if {
    PolicyId := "MS.TEAMS.2.3v1"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumer_Correct_multi if {
    PolicyId := "MS.TEAMS.2.3v1"

    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumer_Incorrect if {
    PolicyId := "MS.TEAMS.2.3v1"
    
    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Internal users are enabled to initiate contact with unmanaged users across domains: Global"
}

test_AllowTeamsConsumer_Incorrect_multi if {
    PolicyId := "MS.TEAMS.2.3v1"
    
    Output := tests with input as {
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "2 Internal users are enabled to initiate contact with unmanaged users across domains: Global, Tag:AllOn"
}

