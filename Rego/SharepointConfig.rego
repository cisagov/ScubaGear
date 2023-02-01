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
DefaultSharingLinkTypePolicy[Policy]{
    Policy := input.SPO_tenant[_]
    Policy.DefaultSharingLinkType == 1
}

tests[{
    "Requirement" : "File and folder links default sharing setting SHALL be set to \"Specific People (Only the People the User Specifies)\"",
    "Control" : "Sharepoint 2.1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := DefaultSharingLinkTypePolicy
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
    "ActualValue" : Policy,
    "ReportDetails" : ReportDetails2_2(Status),
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
ExpirationTimerPolicyRequired[Policy]{
    Policy := input.SPO_tenant[_]
    Policy.ExternalUserExpirationRequired == true
}

tests[{
    "Requirement" : "Expiration timers for 'guest access to a site or OneDrive' and 'people who use a verification code' SHOULD be set",
    "Control" : "Sharepoint 2.4",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := ExpirationTimerPolicyRequired
    Status := count(Policies) == 1
}
#--

#
# Baseline 2.4: Policy 2
#--
ExpirationTimerPolicy[Policy]{
    Policy := input.SPO_tenant[_]
    Policy.ExternalUserExpireInDays == 30
}

tests[{
    "Requirement" : "Expiration timers SHOULD be set to 30 days",
    "Control" : "Sharepoint 2.4",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := ExpirationTimerPolicy
    Status := count(Policies) == 1
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
CustomScriptPolicy[Policy]{
    Policy := input.SPO_site[_]
    # DenyAddAndCustomizePages corresponds to the Custom Script config in the Sharepoint Admin classic settings page (2nd set of bullets in GUI)
    # 1 = Allow users to run custom script on self-service created sites
    # 2 = Prevent users from running custom script on self-service created sites
    Policy.DenyAddAndCustomizePages == 2
}

tests[{
    "Requirement" : "Users SHALL be prevented from running custom scripts on self-service created sites",
    "Control" : "Sharepoint 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SPOSite", "Get-PnPTenantSite"],
    "ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := CustomScriptPolicy
    Status := count(Policies) == 1
}
#--