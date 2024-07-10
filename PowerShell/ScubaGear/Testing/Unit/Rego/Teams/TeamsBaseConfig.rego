package teams_test
import rego.v1

MeetingPolicies := {
    "Identity": "Global",
    "AllowExternalParticipantGiveRequestControl": false,
    "AllowAnonymousUsersToStartMeeting": false,
    "AllowPSTNUsersToBypassLobby": false,
    "AutoAdmittedUsers": "EveryoneInCompany"
}