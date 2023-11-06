package teams_test
import future.keywords
import data.teams
import data.utils.report.ReportDetailsBoolean


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

FAIL := ReportDetailsBoolean(false)

PASS := ReportDetailsBoolean(true)

#
# Policy MS.TEAMS.1.1v1
#--
test_ExternalParticipantControl_Correct_V1 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowExternalParticipantGiveRequestControl": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.1v1", Output, PASS) == true
}

test_ExternalParticipantControl_Correct_V2 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy",
                "AllowExternalParticipantGiveRequestControl": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.1v1", Output, PASS) == true
}

test_ExternalParticipantControl_Incorrect_V1 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowExternalParticipantGiveRequestControl": true
            }
        ]
    }

    ReportDetailString := "1 meeting policy(ies) found that allows external control: Global"
    IncorrectTestResult("MS.TEAMS.1.1v1", Output, ReportDetailString) == true
}

test_ExternalParticipantControl_Incorrect_V2 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy",
                "AllowExternalParticipantGiveRequestControl": true
            }
        ]
    }

    ReportDetailString := "1 meeting policy(ies) found that allows external control: Tag:FirstCustomPolicy"
    IncorrectTestResult("MS.TEAMS.1.1v1", Output, ReportDetailString) == true
}

test_ExternalParticipantControl_MultiplePolicies if {
    PolicyId := "MS.TEAMS.1.1v1"
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowExternalParticipantGiveRequestControl": true
            },
            {
                "Identity": "Tag:FirstCustomPolicy",
                "AllowExternalParticipantGiveRequestControl": false
            },
            {
                "Identity": "Tag:SecondCustomPolicy",
                "AllowExternalParticipantGiveRequestControl": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that allows external control: ")
    # Not sure if we can assume the order these will appear in,
    # hence the "contains" instead of a simple "=="
    contains(RuleOutput[0].ReportDetails, "Global")
    contains(RuleOutput[0].ReportDetails, "Tag:SecondCustomPolicy")
}
#--

#
# Policy MS.TEAMS.1.2v1
#--
test_AnonymousMeetingStart_Correct_V1 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowAnonymousUsersToStartMeeting": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.2v1", Output, PASS) == true
}

test_AnonymousMeetingStart_Correct_V2 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy",
                "AllowAnonymousUsersToStartMeeting": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.2v1", Output, PASS) == true
}

test_AnonymousMeetingStart_Incorrect_V1 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowAnonymousUsersToStartMeeting": true
            }
        ]
    }

    ReportDetailString := "1 meeting policy(ies) found that allows anonymous users to start meetings: Global"
    IncorrectTestResult("MS.TEAMS.1.2v1", Output, ReportDetailString) == true
}

test_AnonymousMeetingStart_Incorrect_V2 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:FirstCustomPolicy",
                "AllowAnonymousUsersToStartMeeting": true
            }
        ]
    }

    ReportDetailString := "1 meeting policy(ies) found that allows anonymous users to start meetings: Tag:FirstCustomPolicy"
    IncorrectTestResult("MS.TEAMS.1.2v1", Output, ReportDetailString) == true
}

test_AnonymousMeetingStart_MultiplePolicies if {
    PolicyId := "MS.TEAMS.1.2v1"

    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowAnonymousUsersToStartMeeting": true
            },
            {
                "Identity": "Tag:FirstCustomPolicy",
                "AllowAnonymousUsersToStartMeeting": false
            },
            {
                "Identity": "Tag:SecondCustomPolicy",
                "AllowAnonymousUsersToStartMeeting": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    startswith(RuleOutput[0].ReportDetails, "2 meeting policy(ies) found that allows anonymous users to start meetings: ")
    # Not sure if we can assume the order these will appear in,
    # hence the "contains" instead of a simple "=="
    contains(RuleOutput[0].ReportDetails, "Global")
    contains(RuleOutput[0].ReportDetails, "Tag:SecondCustomPolicy")
}
#--

#
# Policy MS.TEAMS.1.3v1
#--
test_meeting_policies_Correct if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowPSTNUsersToBypassLobby": false,
                "AutoAdmittedUsers": "EveryoneInCompany"
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.3v1", Output, PASS) == true
}

test_AllowPSTNUsersToBypassLobby_Incorrect if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowPSTNUsersToBypassLobby": true,
                "AutoAdmittedUsers": "EveryoneInCompany"
            }
        ]
    }

    ReportDetailString := "Requirement not met: Dial-in users are enabled to bypass the lobby"
    IncorrectTestResult("MS.TEAMS.1.3v1", Output, ReportDetailString) == true
}

test_AutoAdmittedUsers_Incorrect if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowPSTNUsersToBypassLobby": true,
                "AutoAdmittedUsers": "Everyone"
            }
        ]
    }

    ReportDetailString := "Requirement not met: All users are admitted automatically"
    IncorrectTestResult("MS.TEAMS.1.3v1", Output, ReportDetailString) == true
}

# It shouldn't matter that the custom policy is incorrect as this policy only applies to the Global policy
test_Multiple_Correct if {
    Output := teams.tests with input as {
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

    CorrectTestResult("MS.TEAMS.1.3v1", Output, PASS) == true
}
#--

#
# Policy MS.TEAMS.1.4v1
#--
test_AutoAdmittedUsers_Correct_V1 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AutoAdmittedUsers": "EveryoneInSameAndFederatedCompany"
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.4v1", Output, PASS) == true
}

test_AutoAdmittedUsers_Correct_V2 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AutoAdmittedUsers": "EveryoneInCompanyExcludingGuests"
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.4v1", Output, PASS) == true
}

test_AutoAdmittedUsers_Incorrect_V2 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AutoAdmittedUsers": "OrganizerOnly"
            }
        ]
    }

    IncorrectTestResult("MS.TEAMS.1.4v1", Output, FAIL) == true
}

test_AutoAdmittedUsers_Incorrect_V3 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AutoAdmittedUsers": "InvitedUsers"
            }
        ]
    }

    IncorrectTestResult("MS.TEAMS.1.4v1", Output, FAIL) == true
}
#--

#
# Policy MS.TEAMS.1.5v1
#--
test_meeting_policies_Correct if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:CustomPolicy",
                "AutoAdmittedUsers": "EveryoneInCompany",
                "AllowPSTNUsersToBypassLobby": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.5v1", Output, PASS) == true
}

test_OneGoodOneBadPolicy_Incorrect if {
    Output := teams.tests with input as {
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

    ReportDetailString := "1 meeting policy(ies) found that allow everyone or dial-in users to bypass lobby: Tag:CustomPolicy"
    IncorrectTestResult("MS.TEAMS.1.5v1", Output, ReportDetailString) == true
}

test_AllowPSTNUsersToBypassLobby_Incorrect if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:CustomPolicy",
                "AutoAdmittedUsers": "EveryoneInCompany",
                "AllowPSTNUsersToBypassLobby": true
            }
        ]
    }

    ReportDetailString := "1 meeting policy(ies) found that allow everyone or dial-in users to bypass lobby: Tag:CustomPolicy"
    IncorrectTestResult("MS.TEAMS.1.5v1", Output, ReportDetailString) == true
}
#--

#
# Policy MS.TEAMS.1.6v1
#--
test_AllowCloudRecording_Correct if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": false
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.6v1", Output, PASS) == true
}

test_AllowCloudRecording_Incorrect if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": true
            }
        ]
    }

    IncorrectTestResult("MS.TEAMS.1.6v1", Output, FAIL) == true
}

# This baseline only applies to the Global policy,
# so no failure will be produced for the non-global policies
test_AllowCloudRecording_Multiple if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowCloudRecording": false
            },
            {
                "Identity": "Tag:TestPolicy",
                "AllowCloudRecording": true
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.6v1", Output, PASS) == true
}
#--

#
# Policy MS.TEAMS.1.7v1
#--
test_BroadcastRecordingMode_Correct if {
    Output := teams.tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "UserOverride"
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.7v1", Output, PASS) == true
}

test_BroadcastRecordingMode_Incorrect if {
    Output := teams.tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "AlwaysRecord"
            }
        ]
    }

    IncorrectTestResult("MS.TEAMS.1.7v1", Output, FAIL) == true
}

# Ignores non global identities
test_BroadcastRecordingMode_Multiple if {
    Output := teams.tests with input as {
        "broadcast_policies": [
            {
                "Identity": "Global",
                "BroadcastRecordingMode": "UserOverride"
            },
            {
                "Identity": "Tag:TestPolicy",
                "BroadcastRecordingMode": "AlwaysRecord"
            }
        ]
    }

    CorrectTestResult("MS.TEAMS.1.7v1", Output, PASS) == true
}
#--