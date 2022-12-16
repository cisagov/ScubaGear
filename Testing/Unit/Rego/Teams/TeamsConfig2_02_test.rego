package teams
import future.keywords


#
# Policy 1
#--
test_AnonymousMeetingStart_Correct_V1 if {
    ControlNumber := "Teams 2.2"
    Requirement := "Anonymous users SHALL NOT be enabled to start meetings in the Global (Org-wide default) meeting policy or in custom meeting policies if any exist"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowAnonymousUsersToStartMeeting" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AnonymousMeetingStart_Correct_V2 if {
    ControlNumber := "Teams 2.2"
    Requirement := "Anonymous users SHALL NOT be enabled to start meetings in the Global (Org-wide default) meeting policy or in custom meeting policies if any exist"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowAnonymousUsersToStartMeeting" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AnonymousMeetingStart_Incorrect_V1 if {
    ControlNumber := "Teams 2.2"
    Requirement := "Anonymous users SHALL NOT be enabled to start meetings in the Global (Org-wide default) meeting policy or in custom meeting policies if any exist"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowAnonymousUsersToStartMeeting" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that allows anonymous users to start meetings: Global"
}

test_AnonymousMeetingStart_Incorrect_V2 if {
    ControlNumber := "Teams 2.2"
    Requirement := "Anonymous users SHALL NOT be enabled to start meetings in the Global (Org-wide default) meeting policy or in custom meeting policies if any exist"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowAnonymousUsersToStartMeeting" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that allows anonymous users to start meetings: Tag:FirstCustomPolicy"
}

test_AnonymousMeetingStart_MultiplePolicies if {
    ControlNumber := "Teams 2.2"
    Requirement := "Anonymous users SHALL NOT be enabled to start meetings in the Global (Org-wide default) meeting policy or in custom meeting policies if any exist"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowAnonymousUsersToStartMeeting" : true
            },
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowAnonymousUsersToStartMeeting" : false
            },
            {
                "Identity": "Tag:SecondCustomPolicy", 
                "AllowAnonymousUsersToStartMeeting" : true
            }
        ] 
    }
    
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that allows anonymous users to start meetings: ")
    contains(RuleOutput[0].ReportDetails, "Global") # Not sure if we can assume the order these will appear in,
    # hence the "contains" instead of a simple "=="
    contains(RuleOutput[0].ReportDetails, "Tag:SecondCustomPolicy")
}