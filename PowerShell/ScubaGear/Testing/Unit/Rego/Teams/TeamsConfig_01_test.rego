package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.TestResultContains
import data.utils.key.FAIL
import data.utils.key.PASS


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

    TestResult("MS.TEAMS.1.1v1", Output, PASS, true) == true
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

    TestResult("MS.TEAMS.1.1v1", Output, PASS, true) == true
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

    ReportDetailStr := "1 meeting policy(ies) found that allows external control: Global"
    TestResult("MS.TEAMS.1.1v1", Output, ReportDetailStr, false) == true
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

    ReportDetailStr := "1 meeting policy(ies) found that allows external control: Tag:FirstCustomPolicy"
    TestResult("MS.TEAMS.1.1v1", Output, ReportDetailStr, false) == true
}

test_ExternalParticipantControl_MultiplePolicies if {
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

    ReportDetailArrayStrs := [
        "2 meeting policy(ies) found that allows external control: ",
        "Global",
        "Tag:SecondCustomPolicy"
    ]
    TestResultContains("MS.TEAMS.1.1v1", Output, ReportDetailArrayStrs, false) == true
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

    TestResult("MS.TEAMS.1.2v1", Output, PASS, true) == true
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

    TestResult("MS.TEAMS.1.2v1", Output, PASS, true) == true
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

    ReportDetailStr := "1 meeting policy(ies) found that allows anonymous users to start meetings: Global"
    TestResult("MS.TEAMS.1.2v1", Output, ReportDetailStr, false) == true
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

    ReportDetailStr :=
        "1 meeting policy(ies) found that allows anonymous users to start meetings: Tag:FirstCustomPolicy"
    TestResult("MS.TEAMS.1.2v1", Output, ReportDetailStr, false) == true
}

test_AnonymousMeetingStart_MultiplePolicies if {
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

    ReportDetailArrayStrs := [
        "2 meeting policy(ies) found that allows anonymous users to start meetings: ",
        "Global",
        "Tag:SecondCustomPolicy"
    ]
    TestResultContains("MS.TEAMS.1.2v1", Output, ReportDetailArrayStrs, false) == true
}
#--

#
# Policy MS.TEAMS.1.3v1
#--
test_meeting_policies_Correct_V1 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowPSTNUsersToBypassLobby": false,
                "AutoAdmittedUsers": "EveryoneInCompany"
            }
        ]
    }

    TestResult("MS.TEAMS.1.3v1", Output, PASS, true) == true
}

test_AllowPSTNUsersToBypassLobby_Incorrect_V1 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Global",
                "AllowPSTNUsersToBypassLobby": true,
                "AutoAdmittedUsers": "EveryoneInCompany"
            }
        ]
    }

    ReportDetailStr := "Requirement not met: Dial-in users are enabled to bypass the lobby"
    TestResult("MS.TEAMS.1.3v1", Output, ReportDetailStr, false) == true
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

    ReportDetailStr := "Requirement not met: All users are admitted automatically"
    TestResult("MS.TEAMS.1.3v1", Output, ReportDetailStr, false) == true
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

    TestResult("MS.TEAMS.1.3v1", Output, PASS, true) == true
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

    TestResult("MS.TEAMS.1.4v1", Output, PASS, true) == true
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

    TestResult("MS.TEAMS.1.4v1", Output, PASS, true) == true
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

    TestResult("MS.TEAMS.1.4v1", Output, FAIL, false) == true
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

    TestResult("MS.TEAMS.1.4v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.TEAMS.1.5v1
#--
test_meeting_policies_Correct_V2 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:CustomPolicy",
                "AutoAdmittedUsers": "EveryoneInCompany",
                "AllowPSTNUsersToBypassLobby": false
            }
        ]
    }

    TestResult("MS.TEAMS.1.5v1", Output, PASS, true) == true
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

    ReportDetailStr :=
        "1 meeting policy(ies) found that allow everyone or dial-in users to bypass lobby: Tag:CustomPolicy"
    TestResult("MS.TEAMS.1.5v1", Output, ReportDetailStr, false) == true
}

test_AllowPSTNUsersToBypassLobby_Incorrect_V2 if {
    Output := teams.tests with input as {
        "meeting_policies": [
            {
                "Identity": "Tag:CustomPolicy",
                "AutoAdmittedUsers": "EveryoneInCompany",
                "AllowPSTNUsersToBypassLobby": true
            }
        ]
    }

    ReportDetailStr :=
        "1 meeting policy(ies) found that allow everyone or dial-in users to bypass lobby: Tag:CustomPolicy"
    TestResult("MS.TEAMS.1.5v1", Output, ReportDetailStr, false) == true
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

    TestResult("MS.TEAMS.1.6v1", Output, PASS, true) == true
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

    TestResult("MS.TEAMS.1.6v1", Output, FAIL, false) == true
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

    TestResult("MS.TEAMS.1.6v1", Output, PASS, true) == true
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

    TestResult("MS.TEAMS.1.7v1", Output, PASS, true) == true
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

    TestResult("MS.TEAMS.1.7v1", Output, FAIL, false) == true
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

    TestResult("MS.TEAMS.1.7v1", Output, PASS, true) == true
}
#--