package sharepoint
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.ReportDetailsBoolean
import data.report.utils.ReportDetailsString

###################
# MS.SHAREPOINT.1 #
###################

#
# MS.SHAREPOINT.1.1v1
#--

# SharingCapability == 0 Only People In Organization
# SharingCapability == 3 Existing Guests
# SharingCapability == 1 New and Existing Guests
# SharingCapability == 2 Anyone

tests[{
    "PolicyId" : "MS.SHAREPOINT.1.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.SharingCapability],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Conditions := [Policy.SharingCapability == 0, Policy.SharingCapability == 3]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) == 1
}
#--

#
# MS.SHAREPOINT.1.2v1
#--

tests[{
    "PolicyId" : "MS.SHAREPOINT.1.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.OneDriveSharingCapability],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    input.OneDrive_PnP_Flag == false
    Conditions := [Policy.OneDriveSharingCapability == 0, Policy.OneDriveSharingCapability == 3]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) == 1
}

tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.SHAREPOINT.1.2v1"
    input.OneDrive_PnP_Flag
}
#--

#
# MS.SHAREPOINT.1.3v1
#--

# SharingDomainRestrictionMode == 0 Unchecked
# SharingDomainRestrictionMode == 1 Checked
# SharingAllowedDomainList == "domains" Domain list

# At this time we are unable to test for approved security groups
# because we have yet to find the setting to check
Domainlist(Policy) := Description if {
    Policy.SharingCapability == 0
    Description := "Requirement met: external sharing is set to Only People In Organization"
}

Domainlist(Policy) := Description if {
    Policy.SharingCapability != 0
    Policy.SharingDomainRestrictionMode == 1
    Description := "Requirement met: Note that we currently only check for approved external domains. Approved security groups are currently not being checked, see the baseline policy for instructions on a manual check"
}

Domainlist(Policy) := Description if {
    Policy.SharingCapability != 0
    Policy.SharingDomainRestrictionMode != 1
    Description := "Requirement not met: Note that we currently only check for approved external domains. Approved security groups are currently not being checked, see the baseline policy for instructions on a manual check"
}

tests[{
    "PolicyId" : "MS.SHAREPOINT.1.3v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.SharingDomainRestrictionMode, Policy.SharingCapability],
    "ReportDetails" : Domainlist(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Conditions := [Policy.SharingCapability == 0, Policy.SharingDomainRestrictionMode == 1]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) == 1
}
#--

#
# MS.SHAREPOINT.1.4v1
#--


tests[{
    "PolicyId" : "MS.SHAREPOINT.1.4v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.RequireAcceptingAccountMatchInvitedAccount, Policy.SharingCapability],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Conditions := [Policy.SharingCapability == 0, Policy.RequireAcceptingAccountMatchInvitedAccount == true]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) >= 1
}
#--

###################
# MS.SHAREPOINT.2 #
###################

#
# MS.SHAREPOINT.2.1v1
#--

# DefaultSharingLinkType == 1 for Specific People
# DefaultSharingLinkType == 2 for Only people in your organization

tests[{
    "PolicyId" : "MS.SHAREPOINT.2.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.DefaultSharingLinkType],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Status := Policy.DefaultSharingLinkType == 1
}
#--

#
# MS.SHAREPOINT.2.2v1
#--

# SPO_tenant - DefaultLinkPermission
# 1 view 2 edit

tests[{
    "PolicyId" : "MS.SHAREPOINT.2.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.DefaultLinkPermission],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Status := Policy.DefaultLinkPermission == 1
}

###################
# MS.SHAREPOINT.3 #
###################

#
# MS.SHAREPOINT.3.1v1
#--

ExternalUserExpireInDays(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability = 0
    ErrMsg := ""
    Status := true
}

ExternalUserExpireInDays(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability = 3
    ErrMsg := ""
    Status := true
}

ExternalUserExpireInDays(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability == 1
    Policy.RequireAnonymousLinksExpireInDays <= 30
    ErrMsg := ""
    Status := true
}

ExternalUserExpireInDays(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability == 2
    Policy.RequireAnonymousLinksExpireInDays <= 30
    ErrMsg := ""
    Status := true
}

ExternalUserExpireInDays(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability == 1
    Policy.RequireAnonymousLinksExpireInDays > 30
    ErrMsg := "Requirement not met: External Sharing is set to New and Existing Guests and expiration date is not 30 days or less"
    Status := false
}

ExternalUserExpireInDays(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability == 2
    Policy.RequireAnonymousLinksExpireInDays > 30
    ErrMsg := "Requirement not met: External Sharing is set to Anyone and expiration date is not 30 days or less"
    Status := false
}

tests[{
    "PolicyId" : "MS.SHAREPOINT.3.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.SharingCapability, Policy.RequireAnonymousLinksExpireInDays],
    "ReportDetails" : ReportDetailsString(Status, ErrMsg),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    [ErrMsg, Status] := ExternalUserExpireInDays(Policy)
}
#--

#
# MS.SHAREPOINT.3.2v1

FileAndFolderPermission(Policy) := Description if {
    Policy.FileAnonymousLinkType == 1
    Policy.FolderAnonymousLinkType == 1
	Description := "Requirement met"
}

FileAndFolderPermission(Policy) := Description if {
    Policy.FileAnonymousLinkType == 2
    Policy.FolderAnonymousLinkType == 2
	Description := "Requirement not met: both files and folders are not limited to view for Anyone"
}

FileAndFolderPermission(Policy) := Description if {
    Policy.FileAnonymousLinkType == 1
    Policy.FolderAnonymousLinkType == 2
	Description := "Requirement not met: folders are not limited to view for Anyone"
}

FileAndFolderPermission(Policy) := Description if {
    Policy.FileAnonymousLinkType == 2
    Policy.FolderAnonymousLinkType == 1
	Description := "Requirement not met: files are not limited to view for Anyone"
}

tests[{
    "PolicyId" : "MS.SHAREPOINT.3.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.FileAnonymousLinkType, Policy.FolderAnonymousLinkType],
    "ReportDetails" : FileAndFolderPermission(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    input.OneDrive_PnP_Flag == false
    Conditions := [Policy.FileAnonymousLinkType == 2, Policy.FolderAnonymousLinkType == 2]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) == 0
}

tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.SHAREPOINT.3.2v1"
    input.OneDrive_PnP_Flag
}
#--

#
# MS.SHAREPOINT.3.3v1
#--

ExpirationTimersVerificationCode(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability == 0
    ErrMsg := ""
    Status := true
}

ExpirationTimersVerificationCode(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == true
    Policy.EmailAttestationReAuthDays <= 30
    ErrMsg := ""
    Status := true
}

ExpirationTimersVerificationCode(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == false
    Policy.EmailAttestationReAuthDays <= 30
    ErrMsg := "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled"
    Status := false
}

ExpirationTimersVerificationCode(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == true
    Policy.EmailAttestationReAuthDays > 30
    ErrMsg := "Requirement not met: Expiration timer for 'People who use a verification code' NOT set to 30 days"
    Status := false
}

ExpirationTimersVerificationCode(Policy) := [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == false
    Policy.EmailAttestationReAuthDays > 30
    ErrMsg := "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled and set to greater 30 days"
    Status := false
}
tests[{
    "PolicyId" : "MS.SHAREPOINT.3.3v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.SharingCapability, Policy.EmailAttestationRequired, Policy.EmailAttestationReAuthDays],
    "ReportDetails" : ReportDetailsString(Status, ErrMsg),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    [ErrMsg, Status] := ExpirationTimersVerificationCode(Policy)
}

###################
# MS.SHAREPOINT.4 #
###################

#
# MS.SHAREPOINT.4.1v1
#--

# At this time we are unable to test for running custom scripts on personal sites
# because we have yet to find the setting to check
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.SHAREPOINT.4.1v1"
    true
}
#--

#
# MS.SHAREPOINT.4.2v1
#--

# 1 == Allow users to run custom script on self-service created sites
# 2 == Prevent users from running custom script on self-service created sites

tests[{
    "PolicyId" : "MS.SHAREPOINT.4.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOSite", "Get-PnPTenantSite"],
    "ActualValue" : [Policy.DenyAddAndCustomizePages],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_site[_]
    Status := Policy.DenyAddAndCustomizePages == 2
}
#--
