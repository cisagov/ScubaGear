################
# Teams Baseline 
################

#
# Reference: Secure Baseline file, teams.md
#--
# This file implements controls/policies documented in the secure baseline.  The tests.PolicyId 
# (e.g., MS.TEAMS.1.1v1) aligns this files to the secure baseline control.
package teams
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.Format
import data.report.utils.ReportDetailsBoolean
import data.report.utils.Description

ReportDetailsArray(Status, Array, String1) =  Detail if {
    Status == true
    Detail := "Requirement met"
}

ReportDetailsArray(Status, Array, String1) = Detail if {
	Status == false
	String2 := concat(", ", Array)
    Detail := Description(Format(Array), String1, String2)
}

#
# MS.TEAMS.1.1v1
#--
# The english translation of the following is:
# Iterate through all meeting policies. For each, check if AllowExternalParticipantGiveRequestControl
# is true. If so, save the policy Identity to the "meetings_allowing_control" list.
MeetingsAllowingExternalControl[Policy.Identity] {
	Policy := input.meeting_policies[_]
	Policy.AllowExternalParticipantGiveRequestControl == true
}

tests[{
	"PolicyId" : "MS.TEAMS.1.1v1",
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

#
# MS.TEAMS.2.1v1
#--
MeetingsAllowingAnonStart[Policy.Identity] {
	Policy := input.meeting_policies[_]
	Policy.AllowAnonymousUsersToStartMeeting == true
}

tests[{
	"PolicyId" : "MS.TEAMS.2.1v1",
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

#
# MS.TEAMS.3.1v1
#--
ReportDetails2_3(Policy) = Description if {
	Policy.AutoAdmittedUsers != "Everyone"
	Policy.AllowPSTNUsersToBypassLobby == false
	Description := "Requirement met"
}

ReportDetails2_3(Policy) = Description if {
	Policy.AutoAdmittedUsers != "Everyone"
	Policy.AllowPSTNUsersToBypassLobby == true
	Description := "Requirement not met: Dial-in users are enabled to bypass the lobby"
}

ReportDetails2_3(Policy) = Description if {
	Policy.AutoAdmittedUsers == "Everyone"
	Description := "Requirement not met: All users are admitted automatically"
}

tests[{
	"PolicyId" : "MS.TEAMS.3.1v1",
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
	"PolicyId" : "MS.TEAMS.3.1v1",
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
# MS.TEAMS.3.2v1
#--
tests[{
	"PolicyId" : "MS.TEAMS.3.2v1",
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
# MS.TEAMS.3.2v1
#--
tests[{
	"PolicyId" : "MS.TEAMS.3.2v1",
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
# MS.TEAMS.4.1v1
#--
ExternalAccessConfig[Policy.Identity] {
    	Policy := input.federation_configuration[_]
        # Filter: only include policies that meet all the requirements
    	Policy.AllowFederatedUsers == true
        count(Policy.AllowedDomains) == 0
}

tests[{
	"PolicyId" : "MS.TEAMS.4.1v1",
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

#
# MS.TEAMS.5.1v1
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
	"PolicyId" : "MS.TEAMS.5.1v1",
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
# MS.TEAMS.5.2v1
#--
InternalCannotenable[Policy.Identity] {
    Policy := input.federation_configuration[_]
    Policy.AllowTeamsConsumer == true
}

tests[{
	"PolicyId" : "MS.TEAMS.5.2v1",
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

#
# MS.TEAMS.6.1v1
#--
SkpyeBlocConfig[Policy.Identity] {
    Policy := input.federation_configuration[_]
    Policy.AllowPublicUsers == true
}

tests[{
	"PolicyId" : "MS.TEAMS.6.1v1",
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

#
# MS.TEAMS.7.1v1
#--
ConfigsAllowingEmail[Policy.Identity] {
    Policy := input.client_configuration[_]
    Policy.AllowEmailIntoChannel == true
}

ReportDetails2_7(IsGCC, ComfirmCorrectConfig, Policies) = Description if {
	IsGCC == true
	Description := "N/A: Feature is unavailable in GCC environments"
}

ReportDetails2_7(IsGCC, ComfirmCorrectConfig, Policies) = Description if {
	IsGCC == false
	ComfirmCorrectConfig == true
	Description := "Requirement met"
}

ReportDetails2_7(IsGCC, ComfirmCorrectConfig, Policies) = Description if {
	IsGCC == false
	ComfirmCorrectConfig == false
	Detail := "Requirement not met: Email integration is enabled across domain:"
	Description := ReportDetailsArray(false, Policies, Detail)
}

tests[{
	"PolicyId" : "MS.TEAMS.7.1v1",
	"Criticality" : "Shall",
	"Commandlet" : ["Get-CsTeamsClientConfiguration"],
	"ActualValue" : [Policies, ServiceInstance],
	"ReportDetails" : ReportDetails2_7(IsGCC, ComfirmCorrectConfig, Policies),
	"RequirementMet" : Status
}] {
    TenantConfig := input.teams_tenant_info[_]
	ServiceInstance := TenantConfig.ServiceInstance
	Policies := ConfigsAllowingEmail
    ComfirmCorrectConfig := count(Policies) ==0
    IsGCC := indexof(ServiceInstance, "GOV") != -1
	Conditions := [ComfirmCorrectConfig, IsGCC]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}

tests[{
	"PolicyId" : "MS.TEAMS.7.1v1",
	"Criticality" : "Shall",
	"Commandlet" : ["Get-CsTeamsClientConfiguration"],
	"ActualValue" : "PowerShell Error",
	"ReportDetails" : "PowerShell Error",
	"RequirementMet" : false
}] {
    count(input.teams_tenant_info) == 0
}
#--

#
# MS.TEAMS.8.1v1
#--
PoliciesBlockingDefaultApps[Policy.Identity] {
	Policy := input.app_policies[_]
	Policy.DefaultCatalogAppsType != "BlockedAppList"
}

tests[{
	"PolicyId" : "MS.TEAMS.8.1v1",
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
# MS.TEAMS.8.2v1
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
	"PolicyId" : "MS.TEAMS.8.2v1",
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
	"PolicyId" : "MS.TEAMS.8.2av1",
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
# MS.TEAMS.8.3v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
	PolicyId := "MS.TEAMS.8.3v1"
    true
}
#--

#
# MS.TEAMS.9.1v1
#--
tests[{
	"PolicyId" : "MS.TEAMS.9.1v1",
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
# MS.TEAMS.9.1v1
#--
tests[{
	"PolicyId" : "MS.TEAMS.9.1v1",
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
# MS.TEAMS.9.3v1
#--
PoliciesAllowingOutsideRegionStorage[Policy.Identity] {
	Policy := input.meeting_policies[_]
	Policy.AllowCloudRecording == true
	Policy.AllowRecordingStorageOutsideRegion == true
}

tests[{
	"PolicyId" : "MS.TEAMS.9.3v1",
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

#
# MS.TEAMS.10.1v1
#--
tests[{
	"PolicyId" : "MS.TEAMS.10.1v1",
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
# MS.TEAMS.10.1v1
#--
tests[{
	"PolicyId" : "MS.TEAMS.10.1v1",
	"Criticality" : "Should",
	"Commandlet" : ["Get-CsTeamsMeetingBroadcastPolicy"],
	"ActualValue" : "PowerShell Error",
	"ReportDetails" : "PowerShell Error",
	"RequirementMet" : false
}] {
	count(input.broadcast_policies) == 0
}
#--

#
# MS.TEAMS.11.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.TEAMS.11.1v1",
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
# MS.TEAMS.11.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"PolicyId" : "MS.TEAMS.11.2v1",
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
# MS.TEAMS.11.4v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"PolicyId" : "MS.TEAMS.11.4v1",
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
# MS.TEAMS.12.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.TEAMS.12.1v1",
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
# MS.TEAMS.12.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"PolicyId" : "MS.TEAMS.12.2v1",
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
# MS.TEAMS.13.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.TEAMS.13.1v1",
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
# MS.TEAMS.13.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"PolicyId" : "MS.TEAMS.13.2v1",
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
# MS.TEAMS.13.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
	"PolicyId" : "MS.TEAMS.13.3v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--
