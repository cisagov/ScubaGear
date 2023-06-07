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

# SharingDomainRestrictionMode == 0 Unchecked
# SharingDomainRestrictionMode == 1 Checked
# SharingAllowedDomainList == "domains" Domain list

tests[{
    "PolicyId" : "MS.SHAREPOINT.1.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.SharingDomainRestrictionMode],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Status := Policy.SharingDomainRestrictionMode == 1
}
#--

#
# MS.SHAREPOINT.1.3v1
#--
# At this time we are unable to test for approved security groups
# because we have yet to find the setting to check
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.SHAREPOINT.1.3v1"
    true
}
#--

#
# MS.SHAREPOINT.1.4v1
#--
tests[{
    "PolicyId" : "MS.SHAREPOINT.1.4v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.RequireAcceptingAccountMatchInvitedAccount],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Status := Policy.RequireAcceptingAccountMatchInvitedAccount == true
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

###################
# MS.SHAREPOINT.3 #
###################

#
# MS.SHAREPOINT.3.1v1
#--
# At this time we are unable to test for sharing settings of specific SharePoint sites
# because we have yet to find the setting to check
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.SHAREPOINT.3.1v1"
    true
}
#--

###################
# MS.SHAREPOINT.4 #
###################

#
# MS.SHAREPOINT.4.1v1
#--
ExpirationTimersGuestAccess(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability == 0
    ErrMsg := ""
    Status := true
}

ExpirationTimersGuestAccess(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.ExternalUserExpirationRequired == true
    Policy.ExternalUserExpireInDays <= 30
    ErrMsg := ""
    Status := true
}

ExpirationTimersGuestAccess(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.ExternalUserExpirationRequired == false
    Policy.ExternalUserExpireInDays <= 30
    ErrMsg := "Requirement not met: Expiration timer for 'Guest access to a site or OneDrive' NOT enabled"
    Status := false
}

ExpirationTimersGuestAccess(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.ExternalUserExpirationRequired == true
    Policy.ExternalUserExpireInDays > 30
    ErrMsg := "Requirement not met: Expiration timer for 'Guest access to a site or OneDrive' NOT set to 30 days or less"
    Status := false
}

ExpirationTimersGuestAccess(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.ExternalUserExpirationRequired == false
    Policy.ExternalUserExpireInDays > 30
    ErrMsg := "Requirement not met: Expiration timer for 'Guest access to a site or OneDrive' NOT enabled and set to greater 30 days"
    Status := false
}
tests[{
    "PolicyId" : "MS.SHAREPOINT.4.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.SharingCapability, Policy.ExternalUserExpirationRequired, Policy.ExternalUserExpireInDays],
    "ReportDetails" : ReportDetailsString(Status, ErrMsg),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    [ErrMsg, Status] := ExpirationTimersGuestAccess(Policy)
}
#--

#
# MS.SHAREPOINT.4.2v1
#--
ExpirationTimersVerificationCode(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability == 0
    ErrMsg := ""
    Status := true
}

ExpirationTimersVerificationCode(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == true
    Policy.EmailAttestationReAuthDays <= 30
    ErrMsg := ""
    Status := true
}

ExpirationTimersVerificationCode(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == false
    Policy.EmailAttestationReAuthDays <= 30
    ErrMsg := "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled"
    Status := false
}

ExpirationTimersVerificationCode(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == true
    Policy.EmailAttestationReAuthDays > 30
    ErrMsg := "Requirement not met: Expiration timer for 'People who use a verification code' NOT set to 30 days"
    Status := false
}

ExpirationTimersVerificationCode(Policy) = [ErrMsg, Status] if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == false
    Policy.EmailAttestationReAuthDays > 30
    ErrMsg := "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled and set to greater 30 days"
    Status := false
}
tests[{
    "PolicyId" : "MS.SHAREPOINT.4.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.SharingCapability, Policy.EmailAttestationRequired, Policy.EmailAttestationReAuthDays],
    "ReportDetails" : ReportDetailsString(Status, ErrMsg),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    [ErrMsg, Status] := ExpirationTimersVerificationCode(Policy)
}
#--

###################
# MS.SHAREPOINT.5 #
###################

#
# MS.SHAREPOINT.5.1v1
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
    PolicyId := "MS.SHAREPOINT.5.1v1"
    true
}
#--

#
# MS.SHAREPOINT.5.2v1
#--

# 1 == Allow users to run custom script on self-service created sites
# 2 == Prevent users from running custom script on self-service created sites

tests[{
    "PolicyId" : "MS.SHAREPOINT.5.2v1",
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