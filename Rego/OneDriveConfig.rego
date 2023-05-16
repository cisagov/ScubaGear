package onedrive
import future.keywords
import data.report.utils.notCheckedDetails
import data.report.utils.ReportDetailsBoolean

#--
#
# MS.ONEDRIVE.1.1v1
#--
AnyoneLinksPolicy[Policy]{
    Policy := input.SPO_tenant_info[_]
    Policy.OneDriveSharingCapability != 2
}

tests[{
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
# MS.ONEDRIVE.2.1v1
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
    "PolicyId" : "MS.ONEDRIVE.2.1v1",
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
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.2.1v1"
    input.OneDrive_PnP_Flag
}
#--

#
# MS.ONEDRIVE.2.2v1
#--
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.2.2v1"
    input.OneDrive_PnP_Flag
}
#--

#
# MS.ONEDRIVE.3.1v1
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
    "PolicyId" : "MS.ONEDRIVE.3.1v1",
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
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.3.1v1"
    input.OneDrive_PnP_Flag
}
#--

#
# MS.ONEDRIVE.4.1v1
#--
DefinedDomainsPolicy[Policy]{
    Policy := input.Tenant_sync_info[_]
    count(Policy.AllowedDomainList) > 0
}

tests[{
    "PolicyId" : "MS.ONEDRIVE.4.1v1",
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
# MS.ONEDRIVE.5.1v1
#--
ClientSyncPolicy[Policy]{
    Policy := input.Tenant_sync_info[_]
    Policy.BlockMacSync == false
}

tests[{
    "Requirement" : "OneDrive Client Sync SHALL only be allowed only within the local domain",
    "PolicyId" : "MS.ONEDRIVE.5.1v1",
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
# MS.ONEDRIVE.6.1v1
#--
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.6.1v1"
    true
}
#--

#
# MS.ONEDRIVE.7.1v1
#--
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.ONEDRIVE.7.1v1"
    true
}
#--