package onedrive
import future.keywords
import data.report.utils.notCheckedDetails

ReportDetailsBoolean(Status) = "Requirement met" if {Status == true}

ReportDetailsBoolean(Status) = "Requirement not met" if {Status == false}

#
# MS.ONEDRIVE.1.1v1
#--
AnyoneLinksPolicy[Policy]{
    Policy := input.SPO_tenant_info[_]
    Policy.OneDriveSharingCapability != 2
}

tests[{
    "Requirement" : "Anyone links SHOULD be disabled",
    "PolicyId" : "MS.ONEDRIVE.1.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    input.OneDrive_PnP_Flag == false
    Policies := AnyoneLinksPolicy
    Status := count(Policies) == 1
}
#--

tests[{
    "Requirement" : "Anyone links SHOULD be disabled",
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.1.1v1"
    input.OneDrive_PnP_Flag
}
#--

#
# MS.ONEDRIVE.1.2v1
#--
ReportDetails2_2(Policy) = Description if {
    Policy.OneDriveSharingCapability != 2
    Description := "Requirement met: Anyone links are disabled"
}

ReportDetails2_2(Policy) = Description if {
    Policy.OneDriveSharingCapability == 2
    Policy.RequireAnonymousLinksExpireInDays == 30
    Description := "Requirement met"
}

ReportDetails2_2(Policy) = Description if {
    Policy.OneDriveSharingCapability == 2
    Policy.RequireAnonymousLinksExpireInDays != 30
    Description := "Requirement not met: Expiration date is not 30"
}

tests[{
    "Requirement" : "An expiration date SHOULD be set for Anyone links",
    "PolicyId" : "MS.ONEDRIVE.1.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.OneDriveSharingCapability, Policy.RequireAnonymousLinksExpireInDays],
    "ReportDetails" : ReportDetails2_2(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant_info[_]
    Conditions1 := [Policy.OneDriveSharingCapability !=2]
    Case1 := count([Condition | Condition = Conditions1[_]; Condition == false]) == 0
    Conditions2 := [Policy.OneDriveSharingCapability == 2, Policy.RequireAnonymousLinksExpireInDays == 30]
    Case2 := count([Condition | Condition = Conditions2[_]; Condition == false]) == 0
    Conditions := [Case1, Case2]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}

tests[{
    "Requirement" : "An expiration date SHOULD be set for Anyone links",
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.1.2v1"
    input.OneDrive_PnP_Flag
}
#--

#
# MS.ONEDRIVE.1.3v1
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
    "PolicyId" : "MS.ONEDRIVE.1.3v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
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

tests[{
    "Requirement" : "Anyone link permissions SHOULD be limited to View",
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.1.3v1"
    input.OneDrive_PnP_Flag
}
#--

#
# MS.ONEDRIVE.2.1v1
#--
DefinedDomainsPolicy[Policy]{
    Policy := input.Tenant_sync_info[_]
    count(Policy.AllowedDomainList) > 0
}

tests[{
    "PolicyId" : "MS.ONEDRIVE.2.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := DefinedDomainsPolicy
    Status := count(Policies) == 1
}
#--

#
# MS.ONEDRIVE.2.3v1
#--
ClientSyncPolicy[Policy]{
    Policy := input.Tenant_sync_info[_]
    Policy.BlockMacSync == false
}

tests[{
    "PolicyId" : "MS.ONEDRIVE.2.3v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenantSyncClientRestriction", "Get-PnPTenantSyncClientRestriction"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := ClientSyncPolicy
    Status := count(Policies) == 1
}
#--

#
# MS.ONEDRIVE.2.2v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.2.2v1"
    true
}
#--

#
# MS.ONEDRIVE.3.1v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.3.1v1"
    true
}
#--
