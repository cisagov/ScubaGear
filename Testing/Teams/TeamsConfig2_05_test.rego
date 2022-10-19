package teams
import future.keywords


#
# Policy 1
#--
test_AllowTeamsConsumerInbound_Correct_V1 if {
    ControlNumber := "Teams 2.5"
    Requirement := "Unmanaged users SHALL NOT be enabled to initiate contact with internal users"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumerInbound_Correct_V1_multi if {
    ControlNumber := "Teams 2.5"
    Requirement := "Unmanaged users SHALL NOT be enabled to initiate contact with internal users"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumerInbound_Correct_V2 if {
    ControlNumber := "Teams 2.5"
    Requirement := "Unmanaged users SHALL NOT be enabled to initiate contact with internal users"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumerInbound_Correct_V2_multi if {
    ControlNumber := "Teams 2.5"
    Requirement := "Unmanaged users SHALL NOT be enabled to initiate contact with internal users"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumer_Incorrect if {
    ControlNumber := "Teams 2.5"
    Requirement := "Unmanaged users SHALL NOT be enabled to initiate contact with internal users"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Configuration allowed unmanaged users to initiate contact with internal user across domains: Global"
}

test_AllowTeamsConsumer_Incorrect_multi if {
    ControlNumber := "Teams 2.5"
    Requirement := "Unmanaged users SHALL NOT be enabled to initiate contact with internal users"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "2 Configuration allowed unmanaged users to initiate contact with internal user across domains: Global, Tag:AllOn"
}

test_AllowTeamsConsumer_Incorrect if {
    ControlNumber := "Teams 2.5"
    Requirement := "Unmanaged users SHALL NOT be enabled to initiate contact with internal users"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumer_Incorrect_multi if {
    ControlNumber := "Teams 2.5"
    Requirement := "Unmanaged users SHALL NOT be enabled to initiate contact with internal users"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}
#
# Policy 2
#--
test_AllowTeamsConsumer_Correct if {
    ControlNumber := "Teams 2.5"
    Requirement := "Internal users SHOULD NOT be enabled to initiate contact with unmanaged users"

    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : false,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumer_Correct_multi if {
    ControlNumber := "Teams 2.5"
    Requirement := "Internal users SHOULD NOT be enabled to initiate contact with unmanaged users"

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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowTeamsConsumer_Incorrect if {
    ControlNumber := "Teams 2.5"
    Requirement := "Internal users SHOULD NOT be enabled to initiate contact with unmanaged users"
    
    Output := tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowTeamsConsumer" : true,
                "AllowTeamsConsumerInbound": false # the value here doesn't matter for this control
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 Internal users are enabled to initiate contact with unmanaged users across domains: Global"
}

test_AllowTeamsConsumer_Incorrect_multi if {
    ControlNumber := "Teams 2.5"
    Requirement := "Internal users SHOULD NOT be enabled to initiate contact with unmanaged users"
    
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

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "2 Internal users are enabled to initiate contact with unmanaged users across domains: Global, Tag:AllOn"
}
