package teams
import future.keywords


#--
# Policy MS.TEAMS.1.1v1
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

#--
# Policy MS.TEAMS.1.2v1
#--
test_AnonymousMeetingStart_Correct_V1 if {
    PolicyId := "MS.TEAMS.1.2v1"
    
    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowAnonymousUsersToStartMeeting" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AnonymousMeetingStart_Correct_V2 if {
    PolicyId := "MS.TEAMS.1.2v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowAnonymousUsersToStartMeeting" : false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AnonymousMeetingStart_Incorrect_V1 if {
    PolicyId := "MS.TEAMS.1.2v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global", 
                "AllowAnonymousUsersToStartMeeting" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that allows anonymous users to start meetings: Global"
}

test_AnonymousMeetingStart_Incorrect_V2 if {
    PolicyId := "MS.TEAMS.1.2v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy", 
                "AllowAnonymousUsersToStartMeeting" : true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that allows anonymous users to start meetings: Tag:FirstCustomPolicy"
}

test_AnonymousMeetingStart_MultiplePolicies if {
    PolicyId := "MS.TEAMS.1.2v1"

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
    
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that allows anonymous users to start meetings: ")
    contains(RuleOutput[0].ReportDetails, "Global") # Not sure if we can assume the order these will appear in,
    # hence the "contains" instead of a simple "=="
    contains(RuleOutput[0].ReportDetails, "Tag:SecondCustomPolicy")
}

#--
# Policy MS.TEAMS.1.3v1
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

#--
# Policy MS.TEAMS.1.4v1
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

#--
# Policy MS.TEAMS.1.5v1
#--
test_meeting_policies_Correct if {
    PolicyId := "MS.TEAMS.1.5v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:CustomPolicy",
                "AutoAdmittedUsers": "EveryoneInCompany",
                "AllowPSTNUsersToBypassLobby": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_OneGoodOneBadPolicy_Incorrect if {
    PolicyId := "MS.TEAMS.1.5v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:CustomPolicy",
                "AutoAdmittedUsers": "EveryoneInCompany",
                "AllowPSTNUsersToBypassLobby": true
            },
            {
                "Identity": "Tag:CustomPolicy",
                "AutoAdmittedUsers": "EveryoneInCompany",
                "AllowPSTNUsersToBypassLobby": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that either allow everyone or dial-in users to bypass lobby: Tag:CustomPolicy"
}

test_AllowPSTNUsersToBypassLobby_Incorrect if {
    PolicyId := "MS.TEAMS.1.5v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:CustomPolicy",
                "AutoAdmittedUsers": "EveryoneInCompany",
                "AllowPSTNUsersToBypassLobby": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 meeting policy(ies) found that either allow everyone or dial-in users to bypass lobby: Tag:CustomPolicy"
}

#--
# Policy MS.TEAMS.1.6v1
#--
test_AllowCloudRecording_Correct if {
    PolicyId := "MS.TEAMS.1.6v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowCloudRecording_Incorrect if {
    PolicyId := "MS.TEAMS.1.6v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllowCloudRecording_Multiple if {
    PolicyId := "MS.TEAMS.1.6v1"

    Output := tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": false
            },
            {
                "Identity": "Tag:TestPolicy",
                "AllowCloudRecording": true # This baseline only applies to the Global policy,
                # so no failure will be produced for the non-global policies
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

#--
# Policy MS.TEAMS.1.7v1
#--
test_BroadcastRecordingMode_Correct if {
    PolicyId := "MS.TEAMS.1.7v1"
   
    Output := tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "UserOverride"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BroadcastRecordingMode_Incorrect if {
    PolicyId := "MS.TEAMS.1.7v1"
   
    Output := tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "AlwaysRecord"
            }
        ]
    }
   
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}


test_BroadcastRecordingMode_Multiple if {
    PolicyId := "MS.TEAMS.1.7v1"

    Output := tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "UserOverride"
            },
            {
                "Identity": "Tag:TestPolicy", # Should be ignored
                "BroadcastRecordingMode": "AlwaysRecord"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}