package teams
import future.keywords


#
# Policy 1
#--
test_ExternalParticipantControl_Correct_V1 if {
    PolicyId := "MS.TEAMS.1.1v1"
    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowExternalParticipantGiveRequestControl" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalParticipantControl_Correct_V2 if {
    PolicyId := "MS.TEAMS.1.1v1"
    Output := tests with input as {
    "meeting_policies": [
        {
            "Identity": "Tag:FirstCustomPolicy", 
            "AllowExternalParticipantGiveRequestControl" : false
        }
    ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExternalParticipantControl_Incorrect_V1 if {
    PolicyId := "MS.TEAMS.1.1v1"
    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowExternalParticipantGiveRequestControl" : true
            }
        ]
    }
    
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that allows external control: Global"
}

test_ExternalParticipantControl_Incorrect_V2 if {
    PolicyId := "MS.TEAMS.1.1v1"
    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowExternalParticipantGiveRequestControl" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that allows external control: Tag:FirstCustomPolicy"
}

test_ExternalParticipantControl_MultiplePolicies if {
    PolicyId := "MS.TEAMS.1.1v1"
    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowExternalParticipantGiveRequestControl" : true
            },
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowExternalParticipantGiveRequestControl" : false
            },
            {
                "Identity": "Tag:SecondCustomPolicy", 
                "AllowExternalParticipantGiveRequestControl" : true
            }
        ] 
    }
    
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that allows external control: ")
    contains(RuleOutput[0].ReportDetails, "Global") # Not sure if we can assume the order these will appear in,
    # hence the "contains" instead of a simple "=="
    contains(RuleOutput[0].ReportDetails, "Tag:SecondCustomPolicy")
}
