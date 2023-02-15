package onedrive
import future.keywords

ReportDetailsBoolean(Status) = "Requirement met" if {Status == true}

ReportDetailsBoolean(Status) = "Requirement not met" if {Status == false}


################
# Baseline 2.1 #
################

#
# Baseline 2.1: Policy 1
#--
AnyoneLinksPolicy[Policy]{
    Policy := input.SPO_tenant_info[_]
    Policy.OneDriveSharingCapability != 2
}

tests[{
    "Requirement" : "Anyone links SHOULD be disabled",
    "Control" : "OneDrive 2.1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := AnyoneLinksPolicy
    Status := count(Policies) == 1
}
#--


################
# Baseline 2.2 #
################

#
# Baseline 2.2: Policy 1
#--
ReportDetails2_2(Policy) = Description if {
    Policy.OneDriveSharingCapability != 2
    Description := "Requirement met: Anyone links are disabled"
}

ReportDetails2_2(Policy) = Description if {
    Policy.OneDriveSharingCapability == 2
    Policy.RequireAnonymousLinksExpireInDays != -1
    Policy.OneDriveRequestFilesLinkExpirationInDays == 30
    Description := "Requirement met"
}

ReportDetails2_2(Policy) = Description if {
    Policy.OneDriveSharingCapability == 2
    Policy.RequireAnonymousLinksExpireInDays == -1
    Description := "Requirement not met: Expiration date is not set"
}

ReportDetails2_2(Policy) = Description if {
    Policy.OneDriveSharingCapability == 2
    Policy.RequireAnonymousLinksExpireInDays != -1
    Policy.OneDriveRequestFilesLinkExpirationInDays != 30
    Description := "Requirement not met: Expiration date is not 30"
}

tests[{
    "Requirement" : "An expiration date SHOULD be set for Anyone links",
    "Control" : "OneDrive 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant"],
    "ActualValue" : [Policy.OneDriveSharingCapability, Policy.RequireAnonymousLinksExpireInDays, Policy.OneDriveRequestFilesLinkExpirationInDays],
    "ReportDetails" : ReportDetails2_2(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant_info[_]
    Conditions1 := [Policy.OneDriveSharingCapability !=2]
    Case1 := count([Condition | Condition = Conditions1[_]; Condition == false]) == 0
    Conditions2 := [Policy.OneDriveSharingCapability == 2, Policy.RequireAnonymousLinksExpireInDays != -1, Policy.OneDriveRequestFilesLinkExpirationInDays == 30]
    Case2 := count([Condition | Condition = Conditions2[_]; Condition == false]) == 0
    Conditions := [Case1, Case2]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}
#--


################
# Baseline 2.3 #
################

#
# Baseline 2.3: Policy 1
#--
ReportDetails2_3(Policy) = Description if {
    Policy.OneDriveSharingCapability != 2
    Description := "Requirement met: Anyone links are disabled"
}

ReportDetails2_3(Policy) = Description if {
    Policy.OneDriveSharingCapability == 2
    Policy.FileAnonymousLinkType == 1
    Policy.FolderAnonymousLinkType == 1
	Description := "Requirement met"
}

ReportDetails2_3(Policy) = Description if {
    Policy.OneDriveSharingCapability == 2
    Policy.FileAnonymousLinkType == 2
    Policy.FolderAnonymousLinkType == 2
	Description := "Requirement not met: both files and folders are not limited to view for Anyone"
}

ReportDetails2_3(Policy) = Description if {
    Policy.OneDriveSharingCapability == 2
    Policy.FileAnonymousLinkType == 1
    Policy.FolderAnonymousLinkType == 2
	Description := "Requirement not met: folders are not limited to view for Anyone"
}

ReportDetails2_3(Policy) = Description if {
    Policy.OneDriveSharingCapability == 2
    Policy.FileAnonymousLinkType == 2
    Policy.FolderAnonymousLinkType == 1
	Description := "Requirement not met: files are not limited to view for Anyone"
}

tests[{
    "Requirement" : "Anyone link permissions SHOULD be limited to View",
    "Control" : "OneDrive 2.3",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant"],
    "ActualValue" : [Policy.OneDriveSharingCapability, Policy.FileAnonymousLinkType, Policy.FolderAnonymousLinkType],
    "ReportDetails" : ReportDetails2_3(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant_info[_]
    Conditions1 := [Policy.OneDriveSharingCapability !=2]
    Case1 := count([Condition | Condition = Conditions1[_]; Condition == false]) == 0
    Conditions2 := [Policy.OneDriveSharingCapability == 2, Policy.FileAnonymousLinkType == 1, Policy.FolderAnonymousLinkType == 1]
    Case2 := count([Condition | Condition = Conditions2[_]; Condition == false]) == 0
    Conditions := [Case1, Case2]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}
#--


################
# Baseline 2.4 #
################

#
# Baseline 2.4: Policy 1
#--
DefinedDomainsPolicy[Policy]{
    Policy := input.Tenant_sync_info[_]
    count(Policy.AllowedDomainList) > 0
}

tests[{
    "Requirement" : "OneDrive Client for Windows SHALL be restricted to agency-Defined Domain(s)",
    "Control" : "OneDrive 2.4",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenant"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := DefinedDomainsPolicy
    Status := count(Policies) == 1
}
#--


################
# Baseline 2.5 #
################

#
# Baseline 2.5: Policy 1
#--
ClientSyncPolicy[Policy]{
    Policy := input.Tenant_sync_info[_]
    Policy.BlockMacSync == false
}

tests[{
    "Requirement" : "OneDrive Client Sync SHALL only be allowed only within the local domain",
    "Control" : "OneDrive 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenantSyncClientRestriction"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := ClientSyncPolicy
    Status := count(Policies) == 1
}
#--


################
# Baseline 2.6 #
################

#
# Baseline 2.6: Policy 1
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "OneDrive Client Sync SHALL be restricted to the local domain",
    "Control" : "OneDrive 2.6",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Onedrive Secure Configuration Baseline policy 2.6 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--


################
# Baseline 2.7 #
################

#
# Baseline 2.7: Policy 1
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "Legacy Authentication SHALL be blocked",
    "Control" : "OneDrive 2.7",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Onedrive Secure Configuration Baseline policy 2.7 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--
