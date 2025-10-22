package teams
import rego.v1
import data.utils.report.ReportDetailsBoolean
import data.utils.report.DefenderMirrorDetails
import data.utils.report.ReportDetailsArray
import data.utils.report.CheckedSkippedDetails
import data.utils.key.FilterArray
import data.utils.key.FAIL
import data.utils.key.PASS


##############
# MS.TEAMS.1 #
##############

#
# MS.TEAMS.1.1v1
#--

# Iterate through all meeting policies. For each, check if AllowExternalParticipantGiveRequestControl
# is true. If so, save the policy Identity to the MeetingsAllowingExternalControl list.
MeetingsAllowingExternalControl contains Policy.Identity if {
    some Policy in input.meeting_policies
    Policy.AllowExternalParticipantGiveRequestControl == true
}

# Pass if MeetingsAllowingExternalControl does not have any policies saved.
tests contains {
    "PolicyId": "MS.TEAMS.1.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := MeetingsAllowingExternalControl
    String := "meeting policy(ies) found that allows external control:"
    Status := count(Policies) == 0
}
#--

#
# MS.TEAMS.1.2v2
#--

# Iterate through all meeting policies. For each, check if AllowAnonymousUsersToStartMeeting
# is true. If so, save the policy Identity to the MeetingsAllowingAnonStart list.
MeetingsAllowingAnonStart contains Policy.Identity if {
    some Policy in input.meeting_policies
    Policy.AllowAnonymousUsersToStartMeeting == true
}

# Pass if MeetingsAllowingAnonStart does not have any policies saved.
tests contains {
    "PolicyId": "MS.TEAMS.1.2v2",
    "Criticality": "Shall",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := MeetingsAllowingAnonStart
    String := "meeting policy(ies) found that allows anonymous users to start meetings:"
    Status := count(Policies) == 0
}
#--

#
# MS.TEAMS.1.3v1
#--

# Create the descriptive error message if policy should fail
ReportDetails1_3(Policy) := PASS if {
    Policy.AutoAdmittedUsers != "Everyone"
    Policy.AllowPSTNUsersToBypassLobby == false
}

ReportDetails1_3(Policy) := Description if {
    Policy.AutoAdmittedUsers != "Everyone"
    Policy.AllowPSTNUsersToBypassLobby == true
    Description := concat(": ", [FAIL, "Dial-in users are enabled to bypass the lobby"])
}

ReportDetails1_3(Policy) := Description if {
    Policy.AutoAdmittedUsers == "Everyone"
    Description := concat(": ", [FAIL, "All users are admitted automatically"])
}

# If AutoAdmittedUsers != Everyone &
# AllowPSTNUsersToBypassLobby == false, then policy should pass
tests contains {
    "PolicyId": "MS.TEAMS.1.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": [
        Policy.AutoAdmittedUsers,
        Policy.AllowPSTNUsersToBypassLobby
    ],
    "ReportDetails": ReportDetails1_3(Policy),
    "RequirementMet": Status
} if {
    some Policy in input.meeting_policies

    # This control specifically states that non-global policies MAY be different,
    # so filter for the global policy only
    Policy.Identity == "Global"
    Conditions := [
        Policy.AutoAdmittedUsers != "Everyone",
        Policy.AllowPSTNUsersToBypassLobby == false
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.TEAMS.1.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.meeting_policies) == 0
}
#--

#
# MS.TEAMS.1.4v1
#--

# Pass if AutoAdmittedUsers is one of the allowed settings
tests contains {
    "PolicyId": "MS.TEAMS.1.4v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": Policy.AutoAdmittedUsers,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some Policy in input.meeting_policies

    # This control specifically states that non-global policies MAY be different,
    # so filter for the global policy
    Policy.Identity == "Global"
    AllowedUsers := [
        "EveryoneInCompany",
        "EveryoneInSameAndFederatedCompany",
        "EveryoneInCompanyExcludingGuests"
    ]
    Status := Policy.AutoAdmittedUsers in AllowedUsers
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.TEAMS.1.4v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.meeting_policies) == 0
}
#--

#
# MS.TEAMS.1.5v1
#--

# Iterate through all meeting policies. For each, check if AllowPSTNUsersToBypassLobby
# is true. If so, save the policy Identity to the MeetingsAllowingPSTNBypass list.
MeetingsAllowingPSTNBypass contains Policy.Identity if {
    some Policy in input.meeting_policies
    Policy.AllowPSTNUsersToBypassLobby == true
}

# Pass if MeetingsAllowingPSTNBypass does not have any policies saved.
tests contains {
    "PolicyId": "MS.TEAMS.1.5v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := MeetingsAllowingPSTNBypass
    String := "meeting policy(ies) found that allow everyone or dial-in users to bypass lobby:"
    Status := count(Policies) == 0
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.TEAMS.1.5v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.meeting_policies) == 0
}
#--

#
# MS.TEAMS.1.6v1
#--

# Pass if AllowCloudRecording == false for global policy
tests contains {
    "PolicyId": "MS.TEAMS.1.6v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": Policy.AllowCloudRecording,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some Policy in input.meeting_policies

    # Filter: this control only applies to the Global policy
    Policy.Identity == "Global"
    Status := Policy.AllowCloudRecording == false
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.TEAMS.1.6v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.meeting_policies) == 0
}
#--

#
# MS.TEAMS.1.7v2
#--

# Pass if BroadcastRecordingMode is set to UserOverride (Organizer can record) or AlwaysDisabled (Never record) for global policy
tests contains {
    "PolicyId": "MS.TEAMS.1.7v2",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingBroadcastPolicy"],
    "ActualValue": Policy.BroadcastRecordingMode,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some Policy in input.broadcast_policies

    # Filter: this control only applies to the Global policy
    Policy.Identity == "Global"
    # Check that recording is not set to "Always record" (AlwaysEnabled)
    # The policy should pass when BroadcastRecordingMode is NOT "AlwaysEnabled"
    # This includes "UserOverride" (Organizer can record), "AlwaysDisabled" (Never record), or any other value except "AlwaysEnabled"
    # Handle potential null or undefined values by treating them as valid (not "AlwaysEnabled")
    Status := Policy.BroadcastRecordingMode != "AlwaysEnabled"
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.TEAMS.1.7v2",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingBroadcastPolicy"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.broadcast_policies) == 0
}
#--




##############
# MS.TEAMS.2 #
##############

#
# MS.TEAMS.2.1v2
#--

# Iterate through all meeting policies. For each, check if AllowFederatedUsers
# is true & no AllowedDomains. If so, save the policy Identity to the ExternalAccessConfig list.
ExternalAccessConfig contains Policy.Identity if {
    some Policy in input.federation_configuration

    # Filter: only include policies that meet all the requirements
    Policy.AllowFederatedUsers == true
    count(Policy.AllowedDomains) == 0
}

# Pass if ExternalAccessConfig does not have any policies saved.
tests contains {
    "PolicyId": "MS.TEAMS.2.1v2",
    "Criticality": "Shall",
    "Commandlet": ["Get-CsTenantFederationConfiguration"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := ExternalAccessConfig
    String := "meeting policy(ies) that allow external access across all domains:"
    Status := count(Policies) == 0
}
#--

#
# MS.TEAMS.2.2v2
#--

# GCC/GCC High/DoD environments: Not applicable
tests contains {
    "PolicyId": "MS.TEAMS.2.2v2",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-CsTenantFederationConfiguration"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails("MS.TEAMS.2.2v2", Reason),
    "RequirementMet": false
} if {
    Reason := "This policy is not applicable to GCC, GCC High, or DOD environments. See %v for more info"
    IsUSGovTenantRegion
}

# There are two relevant settings:
#    - AllowTeamsConsumer: Is contact to or from unmanaged users allowed at all?
#    - AllowTeamsConsumerInbound: Are unamanged users able to initiate contact?
# If AllowTeamsConsumer is false, unmanaged users will be unable to initiate
# contact regardless of what AllowTeamsConsumerInbound is set to as contact
# is completely disabled. However, unfortunately setting AllowTeamsConsumer
# to false doesn't automatically set AllowTeamsConsumerInbound to false as
# well, and in the GUI the checkbox for AllowTeamsConsumerInbound completely
# disappears when AllowTeamsConsumer is set to false, basically preserving
# on the backend whatever value was there to begin with.
#
# TLDR: This requirement can be met if:
#    - AllowTeamsConsumer is false regardless of the value for AllowTeamsConsumerInbound OR
#    - AllowTeamsConsumerInbound is false
# Basically, both cannot be true.

FederationConfiguration contains Policy.Identity if {
    some Policy in input.federation_configuration

    # Filter: only include policies that meet all the requirements
    Policy.AllowTeamsConsumerInbound == true
    Policy.AllowTeamsConsumer == true
}

# Pass if FederationConfiguration does not have any policies saved.
tests contains {
    "PolicyId": "MS.TEAMS.2.2v2",
    "Criticality": "Shall",
    "Commandlet": ["Get-CsTenantFederationConfiguration"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    not IsUSGovTenantRegion
    Policies := FederationConfiguration
    String := "Configuration allowed unmanaged users to initiate contact with internal user across domains:"
    Status := count(Policies) == 0
}
#--

#
# MS.TEAMS.2.3v2
#--

# GCC/GCC High/DoD environments: Not applicable
tests contains {
    "PolicyId": "MS.TEAMS.2.3v2",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": ["Get-CsTenantFederationConfiguration"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails("MS.TEAMS.2.3v2", Reason),
    "RequirementMet": false
} if {
    Reason := "This policy is not applicable to GCC, GCC High, or DOD environments. See %v for more info"
    IsUSGovTenantRegion
}

# Iterate through all meeting policies. For each, check if AllowTeamsConsumer
# is true. If so, save the policy Identity to the InternalCannotEnable list.
InternalCannotEnable contains Policy.Identity if {
    some Policy in input.federation_configuration
    Policy.AllowTeamsConsumer == true
}

# Pass if InternalCannotEnable does not have any policies saved.
tests contains {
    "PolicyId": "MS.TEAMS.2.3v2",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTenantFederationConfiguration"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    not IsUSGovTenantRegion
    Policies := InternalCannotEnable
    String := "Internal users are enabled to initiate contact with unmanaged users across domains:"
    Status := count(Policies) == 0
}
#--

##############
# MS.TEAMS.4 #
##############

#
# MS.TEAMS.4.1v1
#--

# Iterate through all meeting policies. For each, check if AllowEmailIntoChannel
# is true. If so, save the policy Identity to the ConfigsAllowingEmail list.
ConfigsAllowingEmail contains Policy.Identity if {
    some Policy in input.client_configuration
    Policy.AllowEmailIntoChannel == true
}

# Concat the AssignedPlan for each tenant in one comma separated string
AssignedPlans := concat(", ", TenantConfig.AssignedPlan) if {
    some TenantConfig in input.teams_tenant_info
}

# If AssignedPlan (one of the tenant configs) contain the string
# "GCC" and/or "DOD", return true, else return false
default IsUSGovTenantRegion := false
IsUSGovTenantRegion := true if {
    GCCConditions := [
        contains(AssignedPlans, "GCC"),
        contains(AssignedPlans, "GCCHIGH"),
        contains(AssignedPlans, "DOD")
    ]
    count(FilterArray(GCCConditions, true)) > 0
}

# GCC/GCC High/DoD environments: Not applicable
tests contains {
    "PolicyId": "MS.TEAMS.4.1v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-CsTeamsClientConfiguration", "Get-CsTenant"],
    "ActualValue": {
        "ClientConfig": input.client_configuration,
        "AssignedPlans": AssignedPlans
    },
    "ReportDetails": CheckedSkippedDetails("MS.TEAMS.4.1v1", Reason),
    "RequirementMet": false
} if {
    Reason := "This policy is not applicable to GCC, GCC High, or DOD environments. See %v for more info"
    IsUSGovTenantRegion
}

# Create descriptive report string based on what passed variables equal
ReportDetails4_1(true) := PASS

ReportDetails4_1(false) := FAIL

# As long as email integration is disabled, this test should pass.
tests contains {
    "PolicyId": "MS.TEAMS.4.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-CsTeamsClientConfiguration", "Get-CsTenant"],
    "ActualValue": {
        "ClientConfig": input.client_configuration,
        "AssignedPlans": AssignedPlans
    },
    "ReportDetails": ReportDetails4_1(IsEnabled),
    "RequirementMet": Status
} if {
    not IsUSGovTenantRegion
    IsEnabled := count(ConfigsAllowingEmail) == 0
    Status := IsEnabled
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.TEAMS.4.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-CsTeamsClientConfiguration"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.teams_tenant_info) == 0
}
#--


##############
# MS.TEAMS.5 #
##############

#
# MS.TEAMS.5.1v2
#--

# Iterate through all meeting policies. For each, check if DefaultCatalogAppsType
# is BlockedAppList. If so, save the policy Identity to the PoliciesBlockingDefaultApps list.
PoliciesBlockingDefaultApps contains Policy.Identity if {
    some Policy in input.app_policies
    Policy.DefaultCatalogAppsType == "BlockedAppList"
}

# Pass if PoliciesBlockingDefaultApps does not have any policies saved.
tests contains {
    "PolicyId": "MS.TEAMS.5.1v2",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsAppPermissionPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := PoliciesBlockingDefaultApps
    String := "app permission policy(ies) found that does not restrict installation of Microsoft Apps by default:"
    Status := count(Policies) == 0
}
#--

#
# MS.TEAMS.5.2v2
#--

# Iterate through all meeting policies. For each, check if GlobalCatalogAppsType
# is BlockedAppList. If so, save the policy Identity to the PoliciesAllowingGlobalApps list.
PoliciesAllowingGlobalApps contains Policy.Identity if {
    some Policy in input.app_policies
    Policy.GlobalCatalogAppsType == "BlockedAppList"
}

# Pass if PoliciesAllowingGlobalApps does not have any policies saved.
tests contains {
    "PolicyId": "MS.TEAMS.5.2v2",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsAppPermissionPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := PoliciesAllowingGlobalApps
    String := "app permission policy(ies) found that does not restrict installation of third-party apps by default:"
    Status := count(Policies) == 0
}
#--

#
# MS.TEAMS.5.3v2
#--
#

# Iterate through all meeting policies. For each, check if PrivateCatalogAppsType
# is BlockedAppList. If so, save the policy Identity to the PoliciesAllowingCustomApps list.
PoliciesAllowingCustomApps contains Policy.Identity if {
    some Policy in input.app_policies
    Policy.PrivateCatalogAppsType == "BlockedAppList"
}

# Pass if PoliciesAllowingCustomApps does not have any policies saved.
tests contains {
    "PolicyId": "MS.TEAMS.5.3v2",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsAppPermissionPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := PoliciesAllowingCustomApps
    String := "app permission policy(ies) found that does not restrict installation of custom apps by default:"
    Status := count(Policies) == 0
}
#--


##############
# MS.TEAMS.6 #
##############

#
# MS.TEAMS.6.1v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.6.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.TEAMS.6.1v1"),
    "RequirementMet": false
}
#--

#
# MS.TEAMS.6.2v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.6.2v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.TEAMS.6.2v1"),
    "RequirementMet": false
}
#--


##############
# MS.TEAMS.7 #
##############

#
# MS.TEAMS.7.1v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.7.1v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.TEAMS.7.1v1"),
    "RequirementMet": false
}
#--

#
# MS.TEAMS.7.2v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.7.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.TEAMS.7.2v1"),
    "RequirementMet": false
}
#--


##############
# MS.TEAMS.8 #
##############

#
# MS.TEAMS.8.1v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.8.1v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.TEAMS.8.1v1"),
    "RequirementMet": false
}
#--

#
# MS.TEAMS.8.2v1
#--

# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.8.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.TEAMS.8.2v1"),
    "RequirementMet": false
}
#--
