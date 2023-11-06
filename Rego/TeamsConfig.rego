################
# Teams Baseline
################

#--
# Reference: Secure Baseline file, teams.md
#--
# This file implements controls/policies documented in the secure baseline.  The tests.PolicyId
# (e.g., MS.TEAMS.1.1v1) aligns this files to the secure baseline control.
package teams
import future.keywords
import data.report.utils.Format
import data.report.utils.ReportDetailsBoolean
import data.report.utils.Description

ReportDetailsArray(true, _, _) := ReportDetailsBoolean(true) if {}

ReportDetailsArray(false, Array, String) := Description(Format(Array), String, concat(", ", Array)) if {}

ThirdPartyCheck := "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of ScubaGear. Otherwise, use a 3rd party tool OR manually check"

#--
# MS.TEAMS.1.1v1
#--
# The english translation of the following is:
# Iterate through all meeting policies. For each, check if AllowExternalParticipantGiveRequestControl
# is true. If so, save the policy Identity to the "meetings_allowing_control" list.
MeetingsAllowingExternalControl contains Policy.Identity if {
    some Policy in input.meeting_policies
    Policy.AllowExternalParticipantGiveRequestControl == true
}

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

#--
# MS.TEAMS.1.2v1
#--
MeetingsAllowingAnonStart contains Policy.Identity if {
    some Policy in input.meeting_policies
    Policy.AllowAnonymousUsersToStartMeeting == true
}

tests contains {
    "PolicyId": "MS.TEAMS.1.2v1",
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

#--
# MS.TEAMS.1.3v1
#--
ReportDetails1_3(Policy) := ReportDetailsBoolean(true) if {
    Policy.AutoAdmittedUsers != "Everyone"
    Policy.AllowPSTNUsersToBypassLobby == false
}

ReportDetails1_3(Policy) := Description if {
    Policy.AutoAdmittedUsers != "Everyone"
    Policy.AllowPSTNUsersToBypassLobby == true
    Description := concat(": ", [ReportDetailsBoolean(false), "Dial-in users are enabled to bypass the lobby"])
}

ReportDetails1_3(Policy) := Description if {
    Policy.AutoAdmittedUsers == "Everyone"
    Description := concat(": ", [ReportDetailsBoolean(false), "All users are admitted automatically"])
}

tests contains {
    "PolicyId": "MS.TEAMS.1.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": [Policy.AutoAdmittedUsers, Policy.AllowPSTNUsersToBypassLobby],
    "ReportDetails": ReportDetails1_3(Policy),
    "RequirementMet": Status
} if {
    some Policy in input.meeting_policies

    # This control specifically states that non-global policies MAY be different, so filter for the global policy
    Policy.Identity == "Global"
    Conditions := [Policy.AutoAdmittedUsers != "Everyone", Policy.AllowPSTNUsersToBypassLobby == false]
    Status := count([Condition | some Condition in Conditions; Condition == false]) == 0
}

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

#--
# MS.TEAMS.1.4v1
#--
tests contains {
    "PolicyId": "MS.TEAMS.1.4v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": Policy.AutoAdmittedUsers,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some Policy in input.meeting_policies

    # This control specifically states that non-global policies MAY be different, so filter for the global policy
    Policy.Identity == "Global"
    AllowedUsers := ["EveryoneInCompany", "EveryoneInSameAndFederatedCompany", "EveryoneInCompanyExcludingGuests"]
    Status := Policy.AutoAdmittedUsers in AllowedUsers
}

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

#--
# MS.TEAMS.1.5v1
#--
MeetingsAllowingPSTNBypass contains Policy.Identity if {
    some Policy in input.meeting_policies
    Policy.AllowPSTNUsersToBypassLobby == true
}

tests contains {
    "PolicyId": "MS.TEAMS.1.5v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := MeetingsAllowingPSTNBypass
    String := "meeting policy(ies) found that either allow everyone or dial-in users to bypass lobby:"
    Status := count(Policies) == 0
}

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

#--
# MS.TEAMS.1.6v1
#--
tests contains {
    "PolicyId": "MS.TEAMS.1.6v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingPolicy"],
    "ActualValue": Policy.AllowCloudRecording,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some Policy in input.meeting_policies
    Policy.Identity == "Global" # Filter: this control only applies to the Global policy
    Status := Policy.AllowCloudRecording == false
}

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

#--
# MS.TEAMS.1.7v1
#--
tests contains {
    "PolicyId": "MS.TEAMS.1.7v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingBroadcastPolicy"],
    "ActualValue": Policy.BroadcastRecordingMode,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some Policy in input.broadcast_policies
    Policy.Identity == "Global" # Filter: this control only applies to the Global policy
    Status := Policy.BroadcastRecordingMode == "UserOverride"
}

#
tests contains {
    "PolicyId": "MS.TEAMS.1.7v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsMeetingBroadcastPolicy"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.broadcast_policies) == 0
}

#--

#--
# MS.TEAMS.2.1v1
#--
ExternalAccessConfig contains Policy.Identity if {
    some Policy in input.federation_configuration

    # Filter: only include policies that meet all the requirements
    Policy.AllowFederatedUsers == true
    count(Policy.AllowedDomains) == 0
}

tests contains {
    "PolicyId": "MS.TEAMS.2.1v1",
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
# MS.TEAMS.2.2v1
#--
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

tests contains {
    "PolicyId": "MS.TEAMS.2.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-CsTenantFederationConfiguration"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := FederationConfiguration
    String := "Configuration allowed unmanaged users to initiate contact with internal user across domains:"
    Status := count(Policies) == 0
}

#--

#--
# MS.TEAMS.2.3v1
#--
InternalCannotEnable contains Policy.Identity if {
    some Policy in input.federation_configuration
    Policy.AllowTeamsConsumer == true
}

tests contains {
    "PolicyId": "MS.TEAMS.2.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTenantFederationConfiguration"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := InternalCannotEnable
    String := "Internal users are enabled to initiate contact with unmanaged users across domains:"
    Status := count(Policies) == 0
}

#--

#--
# MS.TEAMS.3.1v1
#--
SkypeBlocConfig contains Policy.Identity if {
    some Policy in input.federation_configuration
    Policy.AllowPublicUsers == true
}

tests contains {
    "PolicyId": "MS.TEAMS.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-CsTenantFederationConfiguration"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := SkypeBlocConfig
    String := "domains that allows contact with Skype users:"
    Status := count(Policies) == 0
}

#--

#--
# MS.TEAMS.4.1v1
#--
ConfigsAllowingEmail contains Policy.Identity if {
    some Policy in input.client_configuration
    Policy.AllowEmailIntoChannel == true
}

ReportDetails4_1(true, _) := "N/A: Feature is unavailable in GCC environments" if {}

ReportDetails4_1(false, true) := ReportDetailsBoolean(true) if {}

ReportDetails4_1(false, false) := ReportDetailsBoolean(false) if {}

tests contains {
    "PolicyId": "MS.TEAMS.4.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-CsTeamsClientConfiguration", "Get-CsTenant"],
    "ActualValue": {"ClientConfig": input.client_configuration, "AssignedPlans": AssignedPlans},
    "ReportDetails": ReportDetails4_1(IsGCC, IsEnabled),
    "RequirementMet": Status
} if {
    # According to Get-CsTeamsClientConfiguration, is team email integration enabled?
    IsEnabled := count(ConfigsAllowingEmail) == 0

    # What is the tenant type according to Get-CsTenant?
    some TenantConfig in input.teams_tenant_info
    AssignedPlans := concat(", ", TenantConfig.AssignedPlan)
    GCCConditions := [contains(AssignedPlans, "GCC"), contains(AssignedPlans, "DOD")]
    IsGCC := count([Condition | some Condition in GCCConditions; Condition == true]) > 0

    # As long as either:
    #     1) Get-CsTeamsClientConfiguration reports email integration is disabled or
    #     2) Get-CsTenant reports this as a gov tenant
    # this test should pass.
    Conditions := [IsEnabled, IsGCC]
    Status := count([Condition | some Condition in Conditions; Condition == true]) > 0
}

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

#--
# MS.TEAMS.5.1v1
#--
PoliciesBlockingDefaultApps contains Policy.Identity if {
    some Policy in input.app_policies
    Policy.DefaultCatalogAppsType == "BlockedAppList"
}

tests contains {
    "PolicyId": "MS.TEAMS.5.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsAppPermissionPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := PoliciesBlockingDefaultApps
    String := "meeting policy(ies) found that does not restrict installation of Microsoft Apps by default:"
    Status := count(Policies) == 0
}

#--

#--
# MS.TEAMS.5.2v1
#--
PoliciesAllowingGlobalApps contains Policy.Identity if {
    some Policy in input.app_policies
    Policy.GlobalCatalogAppsType == "BlockedAppList"
}

tests contains {
    "PolicyId": "MS.TEAMS.5.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsAppPermissionPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := PoliciesAllowingGlobalApps
    String := "meeting policy(ies) found that does not restrict installation of third-party apps by default:"
    Status := count(Policies) == 0
}

#--

#--
# MS.TEAMS.5.3v1
#--
#
PoliciesAllowingCustomApps contains Policy.Identity if {
    some Policy in input.app_policies
    Policy.PrivateCatalogAppsType == "BlockedAppList"
}

tests contains {
    "PolicyId": "MS.TEAMS.5.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsAppPermissionPolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsArray(Status, Policies, String),
    "RequirementMet": Status
} if {
    Policies := PoliciesAllowingCustomApps
    String := "meeting policy(ies) found that does not restrict installation of custom apps by default:"
    Status := count(Policies) == 0
}

#--

#--
# MS.TEAMS.6.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.6.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": ThirdPartyCheck,
    "RequirementMet": false
}

#--

#--
# MS.TEAMS.6.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.6.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": ThirdPartyCheck,
    "RequirementMet": false
}

#--

#--
# MS.TEAMS.7.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.7.1v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": ThirdPartyCheck,
    "RequirementMet": false
}

#--

#--
# MS.TEAMS.7.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.7.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": ThirdPartyCheck,
    "RequirementMet": false
}

#--

#--
# MS.TEAMS.8.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.8.1v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": ThirdPartyCheck,
    "RequirementMet": false
}

#--

#--
# MS.TEAMS.8.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.TEAMS.8.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": ThirdPartyCheck,
    "RequirementMet": false
}

#--
