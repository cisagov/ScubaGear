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
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : SPOTenant.DefaultSharingLinkType,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    SPOTenant := input.SPO_tenant
    Status := SPOTenant.DefaultSharingLinkType == 1
}
#--


################
# Baseline 2.2 #
################

#
# Baseline 2.2: Policy 1
#--
tests[{
    "Requirement" : "External sharing SHOULD be limited to approved domains and security groups per interagency collaboration needs",
    "Control" : "Sharepoint 2.2",
    "Criticality" : "Should",
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : SPOTenant.SharingCapability,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    SPOTenant := input.SPO_tenant
    Status := SPOTenant.SharingCapability == 1
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
    "Commandlet" : "",
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
tests[{
    "Requirement" : "Expiration timers for 'guest access to a site or OneDrive' and 'people who use a verification code' SHOULD be set",
    "Control" : "Sharepoint 2.4",
    "Criticality" : "Should",
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : SPOTenant.ExternalUserExpirationRequired,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    SPOTenant := input.SPO_tenant
	Status := SPOTenant.ExternalUserExpirationRequired == true
}
#--

#
# Baseline 2.4: Policy 2
#--
tests[{
    "Requirement" : "Expiration timers SHOULD be set to 30 days",
    "Control" : "Sharepoint 2.4",
    "Criticality" : "Should",
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : SPOTenant.ExternalUserExpireInDays,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    SPOTenant := input.SPO_tenant
	Status := SPOTenant.ExternalUserExpireInDays == 30
}
#--


################
# Baseline 2.5 #
################

#
# Baseline 2.5: Policy 1
#--
tests[{
    "Requirement" : "Users SHALL be prevented from running custom scripts",
    "Control" : "Sharepoint 2.5",
    "Criticality" : "Shall",
    "Commandlet" : "Get-SPOSite -Identity",
    "ActualValue" : SPOSite.DenyAddAndCustomizePages,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    SPOSite := input.SPO_site
    Status := SPOSite.DenyAddAndCustomizePages == 1
}
#--