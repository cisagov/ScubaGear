package teams
import future.keywords


#
# Policy 1.3, 1.4, and 1.5
#--
test_meeting_policies_Correct if {
    PolicyId := "MS.TEAMS.1.3v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowPSTNUsersToBypassLobby": false,
                "AutoAdmittedUsers": "EveryoneInCompany"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowPSTNUsersToBypassLobby_Incorrect if {
    PolicyId := "MS.TEAMS.1.3v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowPSTNUsersToBypassLobby": true,
                "AutoAdmittedUsers": "EveryoneInCompany"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: Dial-in users are enabled to bypass the lobby"
}

test_AutoAdmittedUsers_Incorrect if {
    PolicyId := "MS.TEAMS.1.3v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowPSTNUsersToBypassLobby": true,
                "AutoAdmittedUsers": "Everyone"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met: All users are admitted automatically"
}

# It shouldn't matter that the custom policy is incorrect as this policy only applies to the Global policy
test_Multiple_Correct if {
    PolicyId := "MS.TEAMS.1.3v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowPSTNUsersToBypassLobby": false,
                "AutoAdmittedUsers": "EveryoneInCompany"
            },
            {
                "Identity": "Tag:CustomPolicy",
                "AllowPSTNUsersToBypassLobby": true,
                "AutoAdmittedUsers": "Everyone"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

#
# Policy 1.4
#--
test_AutoAdmittedUsers_Correct_V1 if {
    PolicyId := "MS.TEAMS.1.4v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AutoAdmittedUsers" : "EveryoneInSameAndFederatedCompany"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AutoAdmittedUsers_Correct_V2 if {
    PolicyId := "MS.TEAMS.1.4v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AutoAdmittedUsers" : "EveryoneInCompanyExcludingGuests"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AutoAdmittedUsers_Incorrect_V2 if {
    PolicyId := "MS.TEAMS.1.4v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AutoAdmittedUsers" : "OrganizerOnly"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AutoAdmittedUsers_Incorrect_V3 if {
    PolicyId := "MS.TEAMS.1.4v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AutoAdmittedUsers" : "InvitedUsers"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}