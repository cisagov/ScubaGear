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

# Iterate through all app permission policies. For each, check if DefaultCatalogAppsType
# is BlockedAppList. If so, save the policy Identity to the PoliciesBlockingDefaultApps list.
PoliciesBlockingDefaultApps contains Policy.Identity if {
    some Policy in input.app_policies
    Policy.DefaultCatalogAppsType == "BlockedAppList"
}

# Check if the DefaultApp tenant setting exists and is set to "None"
DefaultAppTenantSetting := Setting if {
    some Setting in input.tenant_app_settings
    Setting.SettingName == "DefaultApp"
}

# Determine if the tenant setting requirement is met (set to None)
# Default to false if the setting doesn't exist
DefaultAppTenantSettingCompliant := true if {
    DefaultAppTenantSetting
    DefaultAppTenantSetting.SettingValue == "None"
}

DefaultAppTenantSettingCompliant := false if {
    not DefaultAppTenantSetting
}

DefaultAppTenantSettingCompliant := false if {
    DefaultAppTenantSetting
    DefaultAppTenantSetting.SettingValue != "None"
}

# Get tenant setting value - returns value if exists, otherwise "Not Checked"
DefaultAppSettingValue := DefaultAppTenantSetting.SettingValue if {
    input.tenant_app_settings
    count([S | some S in input.tenant_app_settings; S.SettingName == "DefaultApp"]) > 0
}

DefaultAppSettingValue := "Not Checked" if {
    not input.tenant_app_settings
}

DefaultAppSettingValue := "Not Checked" if {
    input.tenant_app_settings
    count([S | some S in input.tenant_app_settings; S.SettingName == "DefaultApp"]) == 0
}

# Check passes if either:
# 1. No legacy policies are blocking AND tenant setting is compliant, OR
# 2. No legacy policies are blocking AND tenant setting doesn't exist (legacy mode)
tests contains {
    "PolicyId": "MS.TEAMS.5.1v2",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsAppPermissionPolicy"],
    "ActualValue": {"Policies": Policies, "TenantSetting": DefaultAppSettingValue},
    "ReportDetails": Details,
    "RequirementMet": Status
} if {
    Policies := PoliciesBlockingDefaultApps
    LegacyCompliant := count(Policies) == 0
    TenantCompliant := DefaultAppTenantSettingCompliant
    
    # Overall status: pass if legacy is compliant OR tenant setting is compliant
    # Count how many are compliant - if any are compliant (count > 0), we pass
    CompliantCount := count([x | x := LegacyCompliant; x == true]) + count([x | x := TenantCompliant; x == true])
    Status := CompliantCount > 0
    
    # Build detailed report
    LegacyDetails := ReportDetailsArray(LegacyCompliant, Policies, concat("", [
        "app permission policy(ies) found that does not restrict installation of ",
        "Microsoft Apps by default:"
    ]))
    
    # Determine tenant details based on setting state - using separate rules for each case
    TenantDetails := GetDefaultAppTenantDetails
    
    # Use helper function to build details with proper prioritization
    Details := BuildDefaultAppDetails(DefaultAppSettingValue, TenantDetails, LegacyDetails, LegacyCompliant)
}

# Helper function to build details message - prioritizes org-wide settings when available
# When org-wide setting is available (not "Not Checked"), show it first
BuildDefaultAppDetails(SettingValue, TenantDetails, _, _) := concat("", [
    "Org-wide tenant setting (Microsoft apps): ",
    SettingValue,
    TenantDetails
]) if {
    SettingValue != "Not Checked"
}

# When legacy is compliant and tenant setting is not checked, just show "Requirement met"
BuildDefaultAppDetails(SettingValue, _, LegacyDetails, LegacyCompliant) := LegacyDetails if {
    SettingValue == "Not Checked"
    LegacyCompliant == true
}

# When legacy is NOT compliant and tenant setting is not checked, show full message
BuildDefaultAppDetails(SettingValue, TenantDetails, LegacyDetails, LegacyCompliant) := concat("", [
    "Legacy app permission policy check: ",
    LegacyDetails,
    ". Org-wide tenant setting (Microsoft apps): ",
    SettingValue,
    TenantDetails
]) if {
    SettingValue == "Not Checked"
    LegacyCompliant == false
}

# Helper rule to determine DefaultApp tenant setting details
GetDefaultAppTenantDetails := " - Compliant (set to None); legacy app permission policies not required" if {
    DefaultAppTenantSettingCompliant
}

GetDefaultAppTenantDetails := " - Non-compliant (should be set to None)" if {
    not DefaultAppTenantSettingCompliant
    DefaultAppSettingValue != "Not Checked"
}

GetDefaultAppTenantDetails := concat("", [
    " - Org-wide app settings not available in this tenant; ",
    "legacy app permission policies were validated instead"
]) if {
    DefaultAppSettingValue == "Not Checked"
}
#--

#
# MS.TEAMS.5.2v2
#--

# Iterate through all app permission policies. For each, check if GlobalCatalogAppsType
# is BlockedAppList. If so, save the policy Identity to the PoliciesAllowingGlobalApps list.
PoliciesAllowingGlobalApps contains Policy.Identity if {
    some Policy in input.app_policies
    Policy.GlobalCatalogAppsType == "BlockedAppList"
}

# Check if the GlobalApp tenant setting exists and is set to "None"
GlobalAppTenantSetting := Setting if {
    some Setting in input.tenant_app_settings
    Setting.SettingName == "GlobalApp"
}

# Determine if the tenant setting requirement is met (set to None)
# Default to false if the setting doesn't exist
GlobalAppTenantSettingCompliant := true if {
    GlobalAppTenantSetting
    GlobalAppTenantSetting.SettingValue == "None"
}

GlobalAppTenantSettingCompliant := false if {
    not GlobalAppTenantSetting
}

GlobalAppTenantSettingCompliant := false if {
    GlobalAppTenantSetting
    GlobalAppTenantSetting.SettingValue != "None"
}

# Get tenant setting value - returns value if exists, otherwise "Not Checked"
GlobalAppSettingValue := GlobalAppTenantSetting.SettingValue if {
    input.tenant_app_settings
    count([S | some S in input.tenant_app_settings; S.SettingName == "GlobalApp"]) > 0
}

GlobalAppSettingValue := "Not Checked" if {
    not input.tenant_app_settings
}

GlobalAppSettingValue := "Not Checked" if {
    input.tenant_app_settings
    count([S | some S in input.tenant_app_settings; S.SettingName == "GlobalApp"]) == 0
}

# Check passes if either:
# 1. No legacy policies are blocking AND tenant setting is compliant, OR
# 2. No legacy policies are blocking AND tenant setting doesn't exist (legacy mode)
tests contains {
    "PolicyId": "MS.TEAMS.5.2v2",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsAppPermissionPolicy"],
    "ActualValue": {"Policies": Policies, "TenantSetting": GlobalAppSettingValue},
    "ReportDetails": Details,
    "RequirementMet": Status
} if {
    Policies := PoliciesAllowingGlobalApps
    LegacyCompliant := count(Policies) == 0
    TenantCompliant := GlobalAppTenantSettingCompliant
    
    # Overall status: pass if legacy is compliant OR tenant setting is compliant
    CompliantCount := count([x | x := LegacyCompliant; x == true]) + count([x | x := TenantCompliant; x == true])
    Status := CompliantCount > 0
    
    # Build detailed report
    LegacyDetails := ReportDetailsArray(LegacyCompliant, Policies, concat("", [
        "app permission policy(ies) found that does not restrict installation of ",
        "third-party apps by default:"
    ]))
    
    # Determine tenant details based on setting state - using separate rules for each case
    TenantDetails := GetGlobalAppTenantDetails
    
    # Use helper function to build details with proper prioritization
    Details := BuildGlobalAppDetails(GlobalAppSettingValue, TenantDetails, LegacyDetails, LegacyCompliant)
}

# Helper function to build details message - prioritizes org-wide settings when available
# When org-wide setting is available (not "Not Checked"), show it first
BuildGlobalAppDetails(SettingValue, TenantDetails, _, _) := concat("", [
    "Org-wide tenant setting (third-party apps): ",
    SettingValue,
    TenantDetails
]) if {
    SettingValue != "Not Checked"
}

# When legacy is compliant and tenant setting is not checked, just show "Requirement met"
BuildGlobalAppDetails(SettingValue, _, LegacyDetails, LegacyCompliant) := LegacyDetails if {
    SettingValue == "Not Checked"
    LegacyCompliant == true
}

# When legacy is NOT compliant and tenant setting is not checked, show full message
BuildGlobalAppDetails(SettingValue, TenantDetails, LegacyDetails, LegacyCompliant) := concat("", [
    "Legacy app permission policy check: ",
    LegacyDetails,
    ". Org-wide tenant setting (third-party apps): ",
    SettingValue,
    TenantDetails
]) if {
    SettingValue == "Not Checked"
    LegacyCompliant == false
}

# Helper rule to determine GlobalApp tenant setting details
GetGlobalAppTenantDetails := " - Compliant (set to None); legacy app permission policies not required" if {
    GlobalAppTenantSettingCompliant
}

GetGlobalAppTenantDetails := " - Non-compliant (should be set to None)" if {
    not GlobalAppTenantSettingCompliant
    GlobalAppSettingValue != "Not Checked"
}

GetGlobalAppTenantDetails := concat("", [
    " - Org-wide app settings not available in this tenant; ",
    "legacy app permission policies were validated instead"
]) if {
    GlobalAppSettingValue == "Not Checked"
}
#--

#
# MS.TEAMS.5.3v2
#--

# Iterate through all app permission policies. For each, check if PrivateCatalogAppsType
# is BlockedAppList. If so, save the policy Identity to the PoliciesAllowingCustomApps list.
PoliciesAllowingCustomApps contains Policy.Identity if {
    some Policy in input.app_policies
    Policy.PrivateCatalogAppsType == "BlockedAppList"
}

# Check if the PrivateApp tenant setting exists and is set to "None"
PrivateAppTenantSetting := Setting if {
    some Setting in input.tenant_app_settings
    Setting.SettingName == "PrivateApp"
}

# Determine if the tenant setting requirement is met (set to None)
# Default to false if the setting doesn't exist
PrivateAppTenantSettingCompliant := true if {
    PrivateAppTenantSetting
    PrivateAppTenantSetting.SettingValue == "None"
}

PrivateAppTenantSettingCompliant := false if {
    not PrivateAppTenantSetting
}

PrivateAppTenantSettingCompliant := false if {
    PrivateAppTenantSetting
    PrivateAppTenantSetting.SettingValue != "None"
}

# Get tenant setting value - returns value if exists, otherwise "Not Checked"
PrivateAppSettingValue := PrivateAppTenantSetting.SettingValue if {
    input.tenant_app_settings
    count([S | some S in input.tenant_app_settings; S.SettingName == "PrivateApp"]) > 0
}

PrivateAppSettingValue := "Not Checked" if {
    not input.tenant_app_settings
}

PrivateAppSettingValue := "Not Checked" if {
    input.tenant_app_settings
    count([S | some S in input.tenant_app_settings; S.SettingName == "PrivateApp"]) == 0
}

# Check passes if either:
# 1. No legacy policies are blocking AND tenant setting is compliant, OR
# 2. No legacy policies are blocking AND tenant setting doesn't exist (legacy mode)
tests contains {
    "PolicyId": "MS.TEAMS.5.3v2",
    "Criticality": "Should",
    "Commandlet": ["Get-CsTeamsAppPermissionPolicy"],
    "ActualValue": {"Policies": Policies, "TenantSetting": PrivateAppSettingValue},
    "ReportDetails": Details,
    "RequirementMet": Status
} if {
    Policies := PoliciesAllowingCustomApps
    LegacyCompliant := count(Policies) == 0
    TenantCompliant := PrivateAppTenantSettingCompliant
    
    # Overall status: pass if legacy is compliant OR tenant setting is compliant
    CompliantCount := count([x | x := LegacyCompliant; x == true]) + count([x | x := TenantCompliant; x == true])
    Status := CompliantCount > 0
    
    # Build detailed report
    LegacyDetails := ReportDetailsArray(LegacyCompliant, Policies, concat("", [
        "app permission policy(ies) found that does not restrict installation of ",
        "custom apps by default:"
    ]))
    
    # Determine tenant details based on setting state - using separate rules for each case
    TenantDetails := GetPrivateAppTenantDetails
    
    # Use helper function to build details with proper prioritization
    Details := BuildPrivateAppDetails(PrivateAppSettingValue, TenantDetails, LegacyDetails, LegacyCompliant)
}

# Helper function to build details message - prioritizes org-wide settings when available
# When org-wide setting is available (not "Not Checked"), show it first
BuildPrivateAppDetails(SettingValue, TenantDetails, _, _) := concat("", [
    "Org-wide tenant setting (custom apps): ",
    SettingValue,
    TenantDetails
]) if {
    SettingValue != "Not Checked"
}

# When legacy is compliant and tenant setting is not checked, just show "Requirement met"
BuildPrivateAppDetails(SettingValue, _, LegacyDetails, LegacyCompliant) := LegacyDetails if {
    SettingValue == "Not Checked"
    LegacyCompliant == true
}

# When legacy is NOT compliant and tenant setting is not checked, show full message
BuildPrivateAppDetails(SettingValue, TenantDetails, LegacyDetails, LegacyCompliant) := concat("", [
    "Legacy app permission policy check: ",
    LegacyDetails,
    ". Org-wide tenant setting (custom apps): ",
    SettingValue,
    TenantDetails
]) if {
    SettingValue == "Not Checked"
    LegacyCompliant == false
}

# Helper rule to determine PrivateApp tenant setting details
GetPrivateAppTenantDetails := " - Compliant (set to None); legacy app permission policies not required" if {
    PrivateAppTenantSettingCompliant
}

GetPrivateAppTenantDetails := " - Non-compliant (should be set to None)" if {
    not PrivateAppTenantSettingCompliant
    PrivateAppSettingValue != "Not Checked"
}

GetPrivateAppTenantDetails := concat("", [
    " - Org-wide app settings not available in this tenant; ",
    "legacy app permission policies were validated instead"
]) if {
    PrivateAppSettingValue == "Not Checked"
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
