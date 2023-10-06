package teams
import future.keywords

Format(Array) := format_int(count(Array), 10)

Description(String1, String2, String3) := trim(concat(" ", [String1, concat(" ", [String2, String3])]), " ")

ReportDetailsBoolean(Status) := "Requirement met" if {Status == true}

ReportDetailsBoolean(Status) := "Requirement not met" if {Status == false}

ReportDetailsArray(Status, Array, String1) :=  Detail if {
    Status == true
    Detail := "Requirement met"
}

ReportDetailsArray(Status, Array, String1) := Detail if {
	Status == false
	String2 := concat(", ", Array)
    Detail := Description(Format(Array), String1, String2)
}

ReportDetailsString(Status, String) :=  Detail if {
    Status == true
    Detail := "Requirement met"
}

ReportDetailsString(Status, String) :=  Detail if {
    Status == false
    Detail := String
}


################
# Baseline 2.1 #
################

#
# Baseline 2.1: Policy 1
#--
# The english translation of the following is:
# Iterate through all meeting policies. For each, check if AllowExternalParticipantGiveRequestControl
# is true. If so, save the policy Identity to the "meetings_allowing_control" list.
MeetingsAllowingExternalControl[Policy.Identity] {
	Policy := input.meeting_policies[_]
	Policy.AllowExternalParticipantGiveRequestControl == true
}

tests[{
	"Requirement" : "External participants SHOULD NOT be enabled to request control of shared desktops or windows in the Global (Org-wide default) meeting policy or in custom meeting policies if any exist",
    "Control" : "Teams 2.1",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : Policies,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := MeetingsAllowingExternalControl
	String := "meeting policy(ies) found that allows external control:"
	Status := count(Policies) == 0
}
#--


################
# Baseline 2.2 #
################

#
# Baseline 2.2: Policy 1
#--
MeetingsAllowingAnonStart[Policy.Identity] {
	Policy := input.meeting_policies[_]
	Policy.AllowAnonymousUsersToStartMeeting == true
}

tests[{
	"Requirement" : "Anonymous users SHALL NOT be enabled to start meetings in the Global (Org-wide default) meeting policy or in custom meeting policies if any exist",
	"Control" : "Teams 2.2",
	"Criticality" : "Shall",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : Policies,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := MeetingsAllowingAnonStart
	String := "meeting policy(ies) found that allows anonymous users to start meetings:"
	Status := count(Policies) == 0
}
#--


################
# Baseline 2.3 #
################

#
# Baseline 2.3: Policy 1
#--
ReportDetails2_3(Policy) := Description if {
	Policy.AutoAdmittedUsers != "Everyone"
	Policy.AllowPSTNUsersToBypassLobby == false
	Description := "Requirement met"
}

ReportDetails2_3(Policy) := Description if {
	Policy.AutoAdmittedUsers != "Everyone"
	Policy.AllowPSTNUsersToBypassLobby == true
	Description := "Requirement not met: Dial-in users are enabled to bypass the lobby"
}

ReportDetails2_3(Policy) := Description if {
	Policy.AutoAdmittedUsers == "Everyone"
	Description := "Requirement not met: All users are admitted automatically"
}

tests[{
	"Requirement" : "Anonymous users, including dial-in users, SHOULD NOT be admitted automatically",
	"Control" : "Teams 2.3",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : [Policy.AutoAdmittedUsers, Policy.AllowPSTNUsersToBypassLobby],
	"ReportDetails" : ReportDetails2_3(Policy),
	"RequirementMet" : Status
}] {
	Policy := input.meeting_policies[_]
	# This control specifically states that non-global policies MAY be different, so filter for the global policy
	Policy.Identity = "Global"
	Conditions := [Policy.AutoAdmittedUsers != "Everyone", Policy.AllowPSTNUsersToBypassLobby == false]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}

tests[{
	"Requirement" : "Anonymous users, including dial-in users, SHOULD NOT be admitted automatically",
	"Control" : "Teams 2.3",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : "PowerShell Error",
	"ReportDetails" : "PowerShell Error",
	"RequirementMet" : false
}] {
	count(input.meeting_policies) == 0
}
#--

#
# Baseline 2.3: Policy 2
#--
tests[{
	"Requirement" : "Internal users SHOULD be admitted automatically",
	"Control" : "Teams 2.3",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : Policy.AutoAdmittedUsers,
	"ReportDetails" : ReportDetailsBoolean(Status),
	"RequirementMet" : Status
}] {
	Policy := input.meeting_policies[_]
    # This control specifically states that non-global policies MAY be different, so filter for the global policy
	Policy.Identity = "Global"
	Status :=  Policy.AutoAdmittedUsers in ["EveryoneInCompany", "EveryoneInSameAndFederatedCompany", "EveryoneInCompanyExcludingGuests"]
}

#
# Baseline 2.3: Policy 2
#--
tests[{
	"Requirement" : "Internal users SHOULD be admitted automatically",
	"Control" : "Teams 2.3",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : "PowerShell Error",
	"ReportDetails" : "PowerShell Error",
	"RequirementMet" : false
}] {
	count(input.meeting_policies) == 0
}
#--


################
# Baseline 2.4 #
################

#
# Baseline 2.4: Policy 1
#--
ExternalAccessConfig[Policy.Identity] {
    	Policy := input.federation_configuration[_]
        # Filter: only include policies that meet all the requirements
    	Policy.AllowFederatedUsers == true
        count(Policy.AllowedDomains) == 0
}

tests[{
	"Requirement" : "External access SHALL only be enabled on a per-domain basis",
	"Control" : "Teams 2.4",
	"Criticality" : "Shall",
	"Commandlet" : ["Get-CsTenantFederationConfiguration"],
	"ActualValue" : Policies,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
    Policies := ExternalAccessConfig
	String := "meeting policy(ies) that allow external access across all domains:"
	Status := count(Policies) == 0
}
#--

#
# Baseline 2.4: Policy 2
#--
MeetingsNotAllowingAnonJoin[Policy.Identity] {
	Policy := input.meeting_policies[_]
	Policy.AllowAnonymousUsersToJoinMeeting == false
}

tests[{
	"Requirement" : "Anonymous users SHOULD be enabled to join meetings",
	"Control" : "Teams 2.4",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : MeetingsNotAllowingAnonJoin,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := MeetingsNotAllowingAnonJoin
	String := "meeting policy(ies) found that don't allow anonymous users to join meetings:"
	Status := count(Policies) == 0
}
#--


################
# Baseline 2.5 #
################

#
# Baseline 2.5: Policy 1
#--
# There are two relevant settings:
#	- AllowTeamsConsumer: Is contact to or from unmanaged users allowed at all?
#	- AllowTeamsConsumerInbound: Are unamanged users able to initiate contact?
# If AllowTeamsConsumer is false, unmanaged users will be unable to initiate
# contact regardless of what AllowTeamsConsumerInbound is set to as contact
# is completely disabled. However, unfortunately setting AllowTeamsConsumer
# to false doesn't automatically set AllowTeamsConsumerInbound to false as
# well, and in the GUI the checkbox for AllowTeamsConsumerInbound completely
# disappears when AllowTeamsConsumer is set to false, basically preserving
# on the backend whatever value was there to begin with.
#
# TLDR: This requirement can be met if:
#	- AllowTeamsConsumer is false regardless of the value for AllowTeamsConsumerInbound OR
#	- AllowTeamsConsumerInbound is false
# Basically, both cannot be true.

FederationConfiguration[Policy.Identity] {
    Policy := input.federation_configuration[_]
    # Filter: only include policies that meet all the requirements
	Policy.AllowTeamsConsumerInbound == true
    Policy.AllowTeamsConsumer == true
}

tests[{
	"Requirement" : "Unmanaged users SHALL NOT be enabled to initiate contact with internal users",
	"Control" : "Teams 2.5",
	"Criticality" : "Shall",
	"Commandlet" : ["Get-CsTenantFederationConfiguration"],
	"ActualValue" : Policies,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := FederationConfiguration
    String := "Configuration allowed unmanaged users to initiate contact with internal user across domains:"
	Status := count(Policies) == 0
}
#--

#
# Baseline 2.5: Policy 2
#--
InternalCannotenable[Policy.Identity] {
    Policy := input.federation_configuration[_]
    Policy.AllowTeamsConsumer == true
}

tests[{
	"Requirement" : "Internal users SHOULD NOT be enabled to initiate contact with unmanaged users",
	"Control" : "Teams 2.5",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTenantFederationConfiguration"],
	"ActualValue" : Policies,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := InternalCannotenable
	String := "Internal users are enabled to initiate contact with unmanaged users across domains:"
	Status := count(Policies) == 0
}
#--


################
# Baseline 2.6 #
################

#
# Baseline 2.6: Policy 1
#--
SkpyeBlocConfig[Policy.Identity] {
    Policy := input.federation_configuration[_]
    Policy.AllowPublicUsers == true
}

tests[{
	"Requirement" : "Contact with Skype users SHALL be blocked",
	"Control" : "Teams 2.6",
	"Criticality" : "Shall",
	"Commandlet" : ["Get-CsTenantFederationConfiguration"],
	"ActualValue" : Policies,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := SkpyeBlocConfig
	String := "domains that allows contact with Skype users:"
	Status := count(Policies) == 0
}
#--


################
# Baseline 2.7 #
################

#
# Baseline 2.7: Policy 1
#--
ConfigsAllowingEmail[Policy.Identity] {
    Policy := input.client_configuration[_]
    Policy.AllowEmailIntoChannel == true
}

ReportDetails2_7(IsGCC, IsEnabled) := Description if {
	IsGCC == true
	Description := "N/A: Feature is unavailable in GCC environments"
}

ReportDetails2_7(IsGCC, IsEnabled) := Description if {
	IsGCC == false
	IsEnabled == true
	Description := "Requirement met"
}

ReportDetails2_7(IsGCC, IsEnabled) := Description if {
	IsGCC == false
	IsEnabled == false
	Description := "Requirement not met"
}

tests[{
	"Requirement" : "Teams email integration SHALL be disabled",
	"Control" : "Teams 2.7",
	"Criticality" : "Shall",
	"Commandlet" : ["Get-CsTeamsClientConfiguration", "Get-CsTenant"],
	"ActualValue" : {"ClientConfig": input.client_configuration, "AssignedPlans": AssignedPlans},
	"ReportDetails" : ReportDetails2_7(IsGCC, IsEnabled),
	"RequirementMet" : Status
}] {
	# According to Get-CsTeamsClientConfiguration, is team email integration enabled?
    IsEnabled := count(ConfigsAllowingEmail) == 0
	# What is the tenant type according to Get-CsTenant?
    TenantConfig := input.teams_tenant_info[_]
	AssignedPlans := concat(", ", TenantConfig.AssignedPlan)
    GCCConditions := [contains(AssignedPlans, "GCC"), contains(AssignedPlans, "DOD")]
	IsGCC := count([Condition | Condition = GCCConditions[_]; Condition == true]) > 0
	# As long as either:
	# 	1) Get-CsTeamsClientConfiguration reports email integration is disabled or
	# 	2) Get-CsTenant reports this as a gov tenant
	# this test should pass.
	Conditions := [IsEnabled, IsGCC]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}
#--


################
# Baseline 2.8 #
################

#
# Baseline 2.8: Policy 1
#--
PoliciesBlockingDefaultApps[Policy.Identity] {
	Policy := input.app_policies[_]
	Policy.DefaultCatalogAppsType != "BlockedAppList"
}

tests[{
	"Requirement" : "Agencies SHOULD allow all apps published by Microsoft, but MAY block specific Microsoft apps as needed",
	"Control" : "Teams 2.8",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsAppPermissionPolicy"],
	"ActualValue" : Policies,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := PoliciesBlockingDefaultApps
	String := "meeting policy(ies) found that block Microsoft Apps by default:"
	Status = count(Policies) == 0
}
#--

#
# Baseline 2.8: Policy 2
#--
PoliciesAllowingGlobalApps[Policy.Identity] {
	Policy := input.app_policies[_]
	Policy.GlobalCatalogAppsType != "AllowedAppList"
}

PoliciesAllowingCustomApps[Policy.Identity] {
	Policy := input.app_policies[_]
	Policy.PrivateCatalogAppsType != "AllowedAppList"
}

tests[{
	"Requirement" : "Agencies SHOULD NOT allow installation of all third-party apps, but MAY allow specific apps as needed",
	"Control" : "Teams 2.8",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsAppPermissionPolicy"],
	"ActualValue" : Policies,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := PoliciesAllowingGlobalApps
	String := "meeting policy(ies) found that allow third-party apps by default:"
	Status = count(Policies) == 0
}

tests[{
	"Requirement" : "Agencies SHOULD NOT allow installation of all custom apps, but MAY allow specific apps as needed",
	"Control" : "Teams 2.8",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsAppPermissionPolicy"],
	"ActualValue" : Policies,
	"ReportDetails" :  ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := PoliciesAllowingCustomApps
	String := "meeting policy(ies) found that allow custom apps by default:"
	Status = count(Policies) == 0
}
#--

#
# Baseline 2.8: Policy 3
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "Agencies SHALL establish policy dictating the app review and approval process to be used by the agency",
    "Control" : "Teams 2.8",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Cannot be checked automatically. See Microsoft Teams Secure Configuration Baseline policy 2.8 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--


################
# Baseline 2.9 #
################

#
# Baseline 2.9: Policy 1
#--
tests[{
	"Requirement" : "Cloud video recording SHOULD be disabled in the global (org-wide default) meeting policy",
	"Control" : "Teams 2.9",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : Policy.AllowCloudRecording,
	"ReportDetails" : ReportDetailsBoolean(Status),
	"RequirementMet" : Status
}] {
	Policy := input.meeting_policies[_]
	Policy.Identity == "Global" # Filter: this control only applies to the Global policy
	Status := Policy.AllowCloudRecording == false
}

#
# Baseline 2.9: Policy 1
#--
tests[{
	"Requirement" : "Cloud video recording SHOULD be disabled in the global (org-wide default) meeting policy",
	"Control" : "Teams 2.9",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : "PowerShell Error",
	"ReportDetails" : "PowerShell Error",
	"RequirementMet" : false
}] {
	count(input.meeting_policies) == 0
}
#--

#
# Baseline 2.9: Policy 2
#--
PoliciesAllowingOutsideRegionStorage[Policy.Identity] {
	Policy := input.meeting_policies[_]
	Policy.AllowCloudRecording == true
	Policy.AllowRecordingStorageOutsideRegion == true
}

tests[{
	"Requirement" : "For all meeting polices that allow cloud recording, recordings SHOULD be stored inside the country of that agency's tenant",
	"Control" : "Teams 2.9",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingPolicy"],
	"ActualValue" : Policies,
	"ReportDetails" : ReportDetailsArray(Status, Policies, String),
	"RequirementMet" : Status
}] {
	Policies := PoliciesAllowingOutsideRegionStorage
	String := "meeting policy(ies) found that allow cloud recording and storage outside of the tenant's region:"
	Status := count(Policies) == 0
}
#--


#################
# Baseline 2.10 #
#################

#
# Baseline 2.10: Policy 1
#--
tests[{
	"Requirement" : "Record an event SHOULD be set to Organizer can record",
	"Control" : "Teams 2.10",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingBroadcastPolicy"],
	"ActualValue" : Policy.BroadcastRecordingMode,
	"ReportDetails" : ReportDetailsBoolean(Status),
	"RequirementMet" : Status
}] {
	Policy := input.broadcast_policies[_]
	Policy.Identity == "Global" # Filter: this control only applies to the Global policy
	Status := Policy.BroadcastRecordingMode == "UserOverride"
}

#
# Baseline 2.10: Policy 1
#--
tests[{
	"Requirement" : "Record an event SHOULD be set to Organizer can record",
	"Control" : "Teams 2.10",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingBroadcastPolicy"],
	"ActualValue" : "PowerShell Error",
	"ReportDetails" : "PowerShell Error",
	"RequirementMet" : false
}] {
	count(input.broadcast_policies) == 0
}
#--


#################
# Baseline 2.11 #
#################

#
# Baseline 2.11: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "Requirement" : "A DLP solution SHALL be enabled",
    "Control" : "Teams 2.11",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.11: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"Requirement" : "Agencies SHOULD use either the native DLP solution offered by Microsoft or a DLP solution that offers comparable services",
    "Control" : "Teams 2.11",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.11: Policy 3
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"Requirement" : "The DLP solution SHALL protect Personally Identifiable Information (PII) and sensitive information, as defined by the agency. At a minimum, the sharing of credit card numbers, taxpayer Identification Numbers (TIN), and Social Security Numbers (SSN) via email SHALL be restricted",
    "Control" : "Teams 2.11",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--


#################
# Baseline 2.12 #
#################

#
# Baseline 2.12: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"Requirement" : "Attachments included with Teams messages SHOULD be scanned for malware",
    "Control" : "Teams 2.12",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.12: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"Requirement" : "Users SHOULD be prevented from opening or downloading files detected as malware",
    "Control" : "Teams 2.12",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--


#################
# Baseline 2.13 #
#################

#
# Baseline 2.13: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"Requirement" : "URL comparison with a block-list SHOULD be enabled",
    "Control" : "Teams 2.13",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.13: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"Requirement" : "Direct download links SHOULD be scanned for malware",
    "Control" : "Teams 2.13",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.13: Policy 3
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"Requirement" : "User click tracking SHOULD be enabled",
    "Control" : "Teams 2.13",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--
