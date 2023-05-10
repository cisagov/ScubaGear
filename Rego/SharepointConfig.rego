package sharepoint
import future.keywords
import data.report.utils.notCheckedDetails

ReportDetailsBoolean(Status) = "Requirement met" if {Status == true}

ReportDetailsBoolean(Status) = "Requirement not met" if {Status == false}

#
# MS.SHAREPOINT.1.1v1
#--
tests[{
    "PolicyId" : "MS.SHAREPOINT.1.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : Policy.DefaultSharingLinkType,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Status := Policy.DefaultSharingLinkType == 1
}
#--

#
# MS.SHAREPOINT.1.3v1
#--
tests[{
    "PolicyId" : "MS.SHAREPOINT.1.3v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : Policy.SharingCapability,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Status := Policy.SharingCapability != 2
}
#--

#
# Baseline 2.2: Policy 2
#--
#tests[{
#    "Requirement" : "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs",
#    "Control" : "Sharepoint 2.2",
#    "Criticality" : "Should",
#    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
#    "ActualValue" : Policy.SharingDomainRestrictionMode,
#    "ReportDetails" : ReportDetailsBoolean(Status),
#    "RequirementMet" : Status
#}] {
#    Policy := input.SPO_tenant[_]
#    Status := Policy.SharingDomainRestrictionMode == 1
#}
#--

#
# Baseline 2.2: Policy 3
#--
#tests[{
#    "Requirement" : "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs",
#    "Control" : "Sharepoint 2.2",
#    "Criticality" : "Should",
#    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
#    "ActualValue" : [Policy.SharingCapability, Policy.SharingDomainRestrictionMode],
#    "ReportDetails" : ReportDetails2_2(Policy),
#    "RequirementMet" : Status
#}] {
#    Policy := input.SPO_tenant[_]
    # TODO: Missing Allow only users in specific security groups to share externally
#}
#--

################
# Baseline 2.3 #
################

#
# MS.SHAREPOINT.2.1v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.SHAREPOINT.2.1v1"
    true
}
#--

#
# MS.SHAREPOINT.3.1v1
#--
ReportDetails2_4_1(Policy) = Description if {
    Policy.SharingCapability == 0
	Description := "Requirement met"
}

ReportDetails2_4_1(Policy) = Description if {
    Policy.SharingCapability != 0
    Policy.ExternalUserExpirationRequired == true
    Policy.ExternalUserExpireInDays == 30
	Description := "Requirement met"
}

ReportDetails2_4_1(Policy) = Description if {
    Policy.SharingCapability != 0
    Policy.ExternalUserExpirationRequired == false
    Policy.ExternalUserExpireInDays == 30
	Description := "Requirement not met: Expiration timer for 'Guest access to a site or OneDrive' NOT enabled"
}

ReportDetails2_4_1(Policy) = Description if {
    Policy.SharingCapability != 0
    Policy.ExternalUserExpirationRequired == true
    Policy.ExternalUserExpireInDays != 30
	Description := "Requirement not met: Expiration timer for 'Guest access to a site or OneDrive' NOT set to 30 days"
}

ReportDetails2_4_1(Policy) = Description if {
    Policy.SharingCapability != 0
    Policy.ExternalUserExpirationRequired == false
    Policy.ExternalUserExpireInDays != 30
	Description := "Requirement not met"
}

tests[{
    "PolicyId" : "MS.SHAREPOINT.3.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.SharingCapability, Policy.ExternalUserExpirationRequired, Policy.ExternalUserExpireInDays],
    "ReportDetails" : ReportDetails2_4_1(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]

    # Role policy requires assignment expiration, but maximum duration is 30 days
    Conditions1 := [Policy.ExternalUserExpirationRequired == true, Policy.ExternalUserExpireInDays == 30]
    Case := count([Condition | Condition = Conditions1[_]; Condition == false]) == 0

    # Filter: only include rules that meet one of the two cases
    Conditions2 := [Policy.SharingCapability == 0, Case]
    Status := count([Condition | Condition = Conditions2[_]; Condition == true]) > 0
}
#--

# TODO: Resolve policy id
# Baseline 2.4: Policy 2
#--
ReportDetails2_4_2(Policy) = Description if {
    Policy.SharingCapability == 0
	Description := "Requirement met"
}

ReportDetails2_4_2(Policy) = Description if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == true
    Policy.EmailAttestationReAuthDays == 30
	Description := "Requirement met"
}

ReportDetails2_4_2(Policy) = Description if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == false
    Policy.EmailAttestationReAuthDays == 30
	Description := "Requirement not met: Expiration timer for 'People who use a verification code' NOT enabled"
}

ReportDetails2_4_2(Policy) = Description if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == true
    Policy.EmailAttestationReAuthDays != 30
	Description := "Requirement not met: Expiration timer for 'People who use a verification code' NOT set to 30 days"
}

ReportDetails2_4_2(Policy) = Description if {
    Policy.SharingCapability != 0
    Policy.EmailAttestationRequired == false
    Policy.EmailAttestationReAuthDays != 30
	Description := "Requirement not met"
}

tests[{
    "Requirement" : "Expiration timer for 'People who use a verification code' should be set to 30 days",
    "Control" : "Sharepoint 2.4",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : [Policy.SharingCapability, Policy.EmailAttestationRequired, Policy.EmailAttestationReAuthDays],
    "ReportDetails" : ReportDetails2_4_2(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]

    # Role policy requires assignment expiration, but maximum duration is 30 days
    Conditions1 := [Policy.EmailAttestationRequired == true, Policy.EmailAttestationReAuthDays == 30]
    Case := count([Condition | Condition = Conditions1[_]; Condition == false]) == 0

    # Filter: only include rules that meet one of the two cases
    Conditions2 := [Policy.SharingCapability == 0, Case]
    Status := count([Condition | Condition = Conditions2[_]; Condition == true]) > 0
}
#--

# TODO: Resolve Policy Id
# Baseline 2.5: Policy 1
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "Users SHALL be prevented from running custom scripts on personal sites (OneDrive)",
    "Control" : "Sharepoint 2.5",
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.SHAREPOINT.TBD"
    true
}
#--

# TODO: Resolve Policy Id
# Baseline 2.5: Policy 2
#--
tests[{
    "Requirement" : "Users SHALL be prevented from running custom scripts on self-service created sites",
    "Control" : "Sharepoint 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOSite", "Get-PnPTenantSite"],
    "ActualValue" : Policy.DenyAddAndCustomizePages,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_site[_]
    # 1 == Allow users to run custom script on self-service created sites
    # 2 == Prevent users from running custom script on self-service created sites
    Status := Policy.DenyAddAndCustomizePages == 2
}
#--