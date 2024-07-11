package teams_test
import rego.v1

MeetingPolicies := {
    "Identity": "Global",
    "AllowExternalParticipantGiveRequestControl": false,
    "AllowAnonymousUsersToStartMeeting": false,
    "AllowPSTNUsersToBypassLobby": false,
    "AutoAdmittedUsers": "EveryoneInCompany",
    "AllowCloudRecording": false
}

BroadcastPolicies := {
    "Identity": "Global",
    "BroadcastRecordingMode": "UserOverride"
}

FederationConfiguration := {
    "Identity": "Global",
    "AllowFederatedUsers": false,
    "AllowedDomains": [
        {
            "AllowedDomain": [
                "Domain=test365.cisa.dhs.gov"
            ]
        }
    ],
    "AllowTeamsConsumer": false,
    "AllowTeamsConsumerInbound": false,
    "AllowPublicUsers": false
}

ClientConfiguration := {
    "Identity": "Global",
    "AllowEmailIntoChannel": false
}

TeamsTenantInfo := {
    "AssignedPlan": [
        "MCOEV",
        "Teams",
        "MCOProfessional"
    ]
}