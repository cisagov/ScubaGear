package sharepoint
import future.keywords

ReportDetailsBoolean(Status) = "Requirement met" if {Status == true}

ReportDetailsBoolean(Status) = "Requirement not met" if {Status == false}


################
# Baseline 2.1 #
################

#
# Baseline 2.1: Policy 1
#--
tests[{
    "Requirement" : "File and folder links default sharing setting SHALL be set to \"Specific People (Only the People the User Specifies)\"",
    "Control" : "Sharepoint 2.1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenant"],
    "ActualValue" : Policy.DefaultSharingLinkType,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Status := Policy.DefaultSharingLinkType == 1
}
#--


################
# Baseline 2.2 #
################

#
# Baseline 2.2: Policy 1
#--
ReportDetails2_2(Policy) = Description if {
    Policy.SharingCapability == 1
    Policy.SharingDomainRestrictionMode == 1
	Description := "Requirement met"
}

ReportDetails2_2(Policy) = Description if {
    Policy.SharingCapability != 1
    Policy.SharingDomainRestrictionMode == 1
	Description := "Requirement not met: Sharepoint sharing slider must be set to 'New and Existing Guests'"
}

ReportDetails2_2(Policy) = Description if {
    Policy.SharingCapability == 1
    Policy.SharingDomainRestrictionMode != 1
	Description := "Requirement not met: 'Limit external sharing by domain' must be enabled"
}

ReportDetails2_2(Policy) = Description if {
    Policy.SharingCapability != 1
    Policy.SharingDomainRestrictionMode != 1
	Description := "Requirement not met"
}

tests[{
    "Requirement" : "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs",
    "Control" : "Sharepoint 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant"],
    "ActualValue" : [Policy.SharingCapability, Policy.SharingDomainRestrictionMode],
    "ReportDetails" : ReportDetails2_2(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    # TODO: Missing Allow only users in specific security groups to share externally
    Conditions := [Policy.SharingCapability == 1, Policy.SharingDomainRestrictionMode == 1]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--


################
# Baseline 2.3 #
################

#
# Baseline 2.3: Policy 1
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "Sharing settings for specific SharePoint sites SHOULD align to their sensitivity level",
    "Control" : "Sharepoint 2.3",
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Sharepoint Secure Configuration Baseline policy 2.3 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--


################
# Baseline 2.4 #
################

#
# Baseline 2.4: Policy 1
#--
ReportDetails2_4_1(Policy) = Description if {
    Policy.ExternalUserExpirationRequired == true
    Policy.EmailAttestationRequired == true
	Description := "Requirement met"
}

ReportDetails2_4_1(Policy) = Description if {
    Policy.ExternalUserExpirationRequired == false
    Policy.EmailAttestationRequired == true
	Description := "Requirement not met: 'Guest access to a site or OneDrive will expire automatically after this many days' must be enabled"
}

ReportDetails2_4_1(Policy) = Description if {
    Policy.ExternalUserExpirationRequired == true
    Policy.EmailAttestationRequired == false
	Description := "Requirement not met: 'People who use a verification code must reauthenticate after this many days' must be enabled"
}

ReportDetails2_4_1(Policy) = Description if {
    Policy.ExternalUserExpirationRequired == false
    Policy.EmailAttestationRequired == false
	Description := "Requirement not met"
}

tests[{
    "Requirement" : "Expiration timers for 'guest access to a site or OneDrive' and 'people who use a verification code' SHOULD be set",
    "Control" : "Sharepoint 2.4",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant"],
    "ActualValue" : [Policy.ExternalUserExpirationRequired, Policy.EmailAttestationRequired],
    "ReportDetails" : ReportDetails2_4_1(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Conditions := [Policy.ExternalUserExpirationRequired == true, Policy.EmailAttestationRequired == true]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--

#
# Baseline 2.4: Policy 2
#--
ReportDetails2_4_2(Policy) = Description if {
    Policy.ExternalUserExpireInDays == 30
    Policy.EmailAttestationReAuthDays == 30
	Description := "Requirement met"
}

ReportDetails2_4_2(Policy) = Description if {
    Policy.ExternalUserExpireInDays != 30
    Policy.EmailAttestationReAuthDays == 30
	Description := "Requirement not met: 'Guest access to a site or OneDrive will expire automatically after this many days' must be 30 days"
}

ReportDetails2_4_2(Policy) = Description if {
    Policy.ExternalUserExpireInDays == 30
    Policy.EmailAttestationReAuthDays != 30
	Description := "Requirement not met: 'People who use a verification code must reauthenticate after this many days' must be 30 days"
}

ReportDetails2_4_2(Policy) = Description if {
    Policy.ExternalUserExpireInDays != 30
    Policy.EmailAttestationReAuthDays != 30
	Description := "Requirement not met"
}

tests[{
    "Requirement" : "Expiration timers SHOULD be set to 30 days",
    "Control" : "Sharepoint 2.4",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant"],
    "ActualValue" : [Policy.ExternalUserExpireInDays, Policy.EmailAttestationReAuthDays],
    "ReportDetails" : ReportDetails2_4_2(Policy),
    "RequirementMet" : Status
}] {
    Policy := input.SPO_tenant[_]
    Conditions := [Policy.ExternalUserExpireInDays == 30, Policy.EmailAttestationReAuthDays == 30]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--


################
# Baseline 2.5 #
################

#
# Baseline 2.5: Policy 1
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "Users SHALL be prevented from running custom scripts on personal sites (OneDrive)",
    "Control" : "Sharepoint 2.5",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Sharepoint Secure Configuration Baseline policy 2.5 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.5: Policy 2
#--
tests[{
    "Requirement" : "Users SHALL be prevented from running custom scripts on self-service created sites",
    "Control" : "Sharepoint 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOSite"],
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