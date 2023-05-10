package teams
import future.keywords


#
# Policy 1
#--
test_AllowFederatedUsers_Correct_V1 if {
    PolicyId := "MS.TEAMS.4.1v1"

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
    PolicyId := "MS.TEAMS.4.1v1"

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
    PolicyId := "MS.TEAMS.4.1v1"

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
    PolicyId := "MS.TEAMS.4.1v1"

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
    PolicyId := "MS.TEAMS.4.1v1"

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
    PolicyId := "MS.TEAMS.4.1v1"

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
    PolicyId := "MS.TEAMS.4.1v1"

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
    PolicyId := "MS.TEAMS.4.1v1"

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

#
# Policy 2
#--
test_AllowAnonymousUsersToJoinMeeting_Correct_V1 if {
    ControlNumber := "Teams 2.4"
    Requirement := "Anonymous users SHOULD be enabled to join meetings"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowAnonymousUsersToJoinMeeting" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowAnonymousUsersToJoinMeeting_Correct_V2 if {
    ControlNumber := "Teams 2.4"
    Requirement := "Anonymous users SHOULD be enabled to join meetings"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowAnonymousUsersToJoinMeeting" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowAnonymousUsersToJoinMeeting_Incorrect_V1 if {
    ControlNumber := "Teams 2.4"
    Requirement := "Anonymous users SHOULD be enabled to join meetings"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowAnonymousUsersToJoinMeeting" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that don't allow anonymous users to join meetings: Global"
}

test_AllowAnonymousUsersToJoinMeeting_Incorrect_V2 if {
    ControlNumber := "Teams 2.4"
    Requirement := "Anonymous users SHOULD be enabled to join meetings"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowAnonymousUsersToJoinMeeting" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that don't allow anonymous users to join meetings: Tag:FirstCustomPolicy"
}

test_AllowAnonymousUsersToJoinMeeting_MultiplePolicies if {
    ControlNumber := "Teams 2.4"
    Requirement := "Anonymous users SHOULD be enabled to join meetings"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowAnonymousUsersToJoinMeeting" : true
            },
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowAnonymousUsersToJoinMeeting" : false
            },
            {
                "Identity": "Tag:SecondCustomPolicy", 
                "AllowAnonymousUsersToJoinMeeting" : true
            }
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that don't allow anonymous users to join meetings: Tag:FirstCustomPolicy"
}


