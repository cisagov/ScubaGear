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
    Output := teams.tests with input.meeting_policies as [MeetingPolicies]

    TestResult("MS.TEAMS.1.1v1", Output, PASS, true) == true
}

test_ExternalParticipantControl_Correct_V2 if {
    Policies := json.patch(MeetingPolicies, [{"op": "add", "path": "Identity", "value": "Tag:FirstCustomPolicy"}])

    Output := teams.tests with input.meeting_policies as [Policies]

    TestResult("MS.TEAMS.1.1v1", Output, PASS, true) == true
}

test_ExternalParticipantControl_Incorrect_V1 if {
    Policies := json.patch(MeetingPolicies, [{"op": "add", "path": "AllowExternalParticipantGiveRequestControl", "value": true}])

    Output := teams.tests with input.meeting_policies as [Policies]

    ReportDetailStr := "1 meeting policy(ies) found that allows external control: Global"
    TestResult("MS.TEAMS.1.1v1", Output, ReportDetailStr, false) == true
}

test_ExternalParticipantControl_Incorrect_V2 if {
    Policies := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:FirstCustomPolicy"},
                    {"op": "add", "path": "AllowExternalParticipantGiveRequestControl", "value": true}])

    Output := teams.tests with input.meeting_policies as [Policies]

    ReportDetailStr := "1 meeting policy(ies) found that allows external control: Tag:FirstCustomPolicy"
    TestResult("MS.TEAMS.1.1v1", Output, ReportDetailStr, false) == true
}

test_ExternalParticipantControl_MultiplePolicies if {
    Policy1 := json.patch(MeetingPolicies, [{"op": "add", "path": "AllowExternalParticipantGiveRequestControl", "value": true}])
    Policy2 := json.patch(MeetingPolicies, [{"op": "add", "path": "Identity", "value": "Tag:FirstCustomPolicy"}])
    Policy3 := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:SecondCustomPolicy"},
                    {"op": "add", "path": "AllowExternalParticipantGiveRequestControl", "value": true}])

    Output := teams.tests with input.meeting_policies as [Policy1, Policy2, Policy3]

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
    Output := teams.tests with input.meeting_policies as [MeetingPolicies]

    TestResult("MS.TEAMS.1.2v1", Output, PASS, true) == true
}

test_AnonymousMeetingStart_Correct_V2 if {
    Policies := json.patch(MeetingPolicies, [{"op": "add", "path": "Identity", "value": "Tag:FirstCustomPolicy"}])

    Output := teams.tests with input.meeting_policies as [Policies]

    TestResult("MS.TEAMS.1.2v1", Output, PASS, true) == true
}

test_AnonymousMeetingStart_Incorrect_V1 if {
    Policies := json.patch(MeetingPolicies, [{"op": "add", "path": "AllowAnonymousUsersToStartMeeting", "value": true}])

    Output := teams.tests with input.meeting_policies as [Policies]

    ReportDetailStr := "1 meeting policy(ies) found that allows anonymous users to start meetings: Global"
    TestResult("MS.TEAMS.1.2v1", Output, ReportDetailStr, false) == true
}

test_AnonymousMeetingStart_Incorrect_V2 if {
    Policies := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:FirstCustomPolicy"},
                    {"op": "add", "path": "AllowAnonymousUsersToStartMeeting", "value": true}])

    Output := teams.tests with input.meeting_policies as [Policies]

    ReportDetailStr :=
        "1 meeting policy(ies) found that allows anonymous users to start meetings: Tag:FirstCustomPolicy"
    TestResult("MS.TEAMS.1.2v1", Output, ReportDetailStr, false) == true
}

test_AnonymousMeetingStart_MultiplePolicies if {
    Policy1 := json.patch(MeetingPolicies, [{"op": "add", "path": "AllowAnonymousUsersToStartMeeting", "value": true}])
    Policy2 := json.patch(MeetingPolicies, [{"op": "add", "path": "Identity", "value": "Tag:FirstCustomPolicy"}])
    Policy3 := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:SecondCustomPolicy"},
                    {"op": "add", "path": "AllowAnonymousUsersToStartMeeting", "value": true}])

    Output := teams.tests with input.meeting_policies as [Policy1, Policy2, Policy3]

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
    Output := teams.tests with input.meeting_policies as [MeetingPolicies]

    TestResult("MS.TEAMS.1.3v1", Output, PASS, true) == true
}

test_AllowPSTNUsersToBypassLobby_Incorrect_V1 if {
    Policies := json.patch(MeetingPolicies, [{"op": "add", "path": "AllowPSTNUsersToBypassLobby", "value": true}])

    Output := teams.tests with input.meeting_policies as [Policies]

    ReportDetailStr := "Requirement not met: Dial-in users are enabled to bypass the lobby"
    TestResult("MS.TEAMS.1.3v1", Output, ReportDetailStr, false) == true
}

test_AutoAdmittedUsers_Incorrect if {
    Policies := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "AllowPSTNUsersToBypassLobby", "value": true},
                    {"op": "add", "path": "AutoAdmittedUsers", "value": "Everyone"}])

    Output := teams.tests with input.meeting_policies as [Policies]

    ReportDetailStr := "Requirement not met: All users are admitted automatically"
    TestResult("MS.TEAMS.1.3v1", Output, ReportDetailStr, false) == true
}

# It shouldn't matter that the custom policy is incorrect as this policy only applies to the Global policy
test_Multiple_Correct if {
    Policies := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:CustomPolicy"},
                    {"op": "add", "path": "AllowPSTNUsersToBypassLobby", "value": true},
                    {"op": "add", "path": "AutoAdmittedUsers", "value": "Everyone"}])

    Output := teams.tests with input.meeting_policies as [MeetingPolicies, Policies]

    TestResult("MS.TEAMS.1.3v1", Output, PASS, true) == true
}
#--

#
# Policy MS.TEAMS.1.4v1
#--
test_AutoAdmittedUsers_Correct_V1 if {
    Policies := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "AutoAdmittedUsers", "value": "EveryoneInSameAndFederatedCompany"}])
    Output := teams.tests with input.meeting_policies as [Policies]

    TestResult("MS.TEAMS.1.4v1", Output, PASS, true) == true
}

test_AutoAdmittedUsers_Correct_V2 if {
    Policies := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "AutoAdmittedUsers", "value": "EveryoneInCompanyExcludingGuests"}])
    Output := teams.tests with input.meeting_policies as [Policies]

    TestResult("MS.TEAMS.1.4v1", Output, PASS, true) == true
}

test_AutoAdmittedUsers_Incorrect_V2 if {
    Policies := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "AutoAdmittedUsers", "value": "OrganizerOnly"}])

    Output := teams.tests with input.meeting_policies as [Policies]

    TestResult("MS.TEAMS.1.4v1", Output, FAIL, false) == true
}

test_AutoAdmittedUsers_Incorrect_V3 if {
    Policies := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "AutoAdmittedUsers", "value": "InvitedUsers"}])

    Output := teams.tests with input.meeting_policies as [Policies]

    TestResult("MS.TEAMS.1.4v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.TEAMS.1.5v1
#--
test_meeting_policies_Correct_V2 if {
    Policies := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:CustomPolicy"}])

    Output := teams.tests with input.meeting_policies as [Policies]

    TestResult("MS.TEAMS.1.5v1", Output, PASS, true) == true
}

test_OneGoodOneBadPolicy_Incorrect if {
    Policy1 := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:CustomPolicy"},
                    {"op": "add", "path": "AllowPSTNUsersToBypassLobby", "value": true}])
    Policy2 := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:CustomPolicy2"}])

    Output := teams.tests with input.meeting_policies as [Policy1, Policy2]

    ReportDetailStr :=
        "1 meeting policy(ies) found that allow everyone or dial-in users to bypass lobby: Tag:CustomPolicy"
    TestResult("MS.TEAMS.1.5v1", Output, ReportDetailStr, false) == true
}

test_AllowPSTNUsersToBypassLobby_Incorrect_V2 if {
    Policy := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:CustomPolicy"},
                    {"op": "add", "path": "AllowPSTNUsersToBypassLobby", "value": true}])

    Output := teams.tests with input.meeting_policies as [Policy]

    ReportDetailStr :=
        "1 meeting policy(ies) found that allow everyone or dial-in users to bypass lobby: Tag:CustomPolicy"
    TestResult("MS.TEAMS.1.5v1", Output, ReportDetailStr, false) == true
}
#--

#
# Policy MS.TEAMS.1.6v1
#--
test_AllowCloudRecording_Correct if {
    Output := teams.tests with input.meeting_policies as [MeetingPolicies]

    TestResult("MS.TEAMS.1.6v1", Output, PASS, true) == true
}

test_AllowCloudRecording_Incorrect if {
    Policy := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "AllowCloudRecording", "value": true}])

    Output := teams.tests with input.meeting_policies as [Policy]

    TestResult("MS.TEAMS.1.6v1", Output, FAIL, false) == true
}

# This baseline only applies to the Global policy,
# so no failure will be produced for the non-global policies
test_AllowCloudRecording_Multiple if {
    Policy := json.patch(MeetingPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                    {"op": "add", "path": "AllowCloudRecording", "value": true}])

    Output := teams.tests with input.meeting_policies as [MeetingPolicies, Policy]

    TestResult("MS.TEAMS.1.6v1", Output, PASS, true) == true
}
#--

#
# Policy MS.TEAMS.1.7v1
#--
test_BroadcastRecordingMode_Correct if {
    Output := teams.tests with input.broadcast_policies as [BroadcastPolicies]

    TestResult("MS.TEAMS.1.7v1", Output, PASS, true) == true
}

test_BroadcastRecordingMode_Incorrect if {
    Policy := json.patch(BroadcastPolicies,
                    [{"op": "add", "path": "BroadcastRecordingMode", "value": "AlwaysRecord"}])

    Output := teams.tests with input.broadcast_policies as [Policy]

    TestResult("MS.TEAMS.1.7v1", Output, FAIL, false) == true
}

# Ignores non global identities
test_BroadcastRecordingMode_Multiple if {
    Policy := json.patch(BroadcastPolicies,
                    [{"op": "add", "path": "Identity", "value": "Tag:TestPolicy"},
                    {"op": "add", "path": "BroadcastRecordingMode", "value": "AlwaysRecord"}])

    Output := teams.tests with input.broadcast_policies as [BroadcastPolicies, Policy]

    TestResult("MS.TEAMS.1.7v1", Output, PASS, true) == true
}
#--