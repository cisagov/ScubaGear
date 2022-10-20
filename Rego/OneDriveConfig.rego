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
tests[{
    "Requirement" : "Anyone links SHOULD be disabled",
    "Control" : "OneDrive 2.1",
    "Criticality" : "Should",
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : TenantInfo.OneDriveLoopSharingCapability,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    TenantInfo := input.SPO_tenant_info
    Status := TenantInfo.OneDriveLoopSharingCapability == 1
}
#--


################
# Baseline 2.2 #
################

#
# Baseline 2.2: Policy 1
#--
tests[{
    "Requirement" : "An expiration date SHOULD be set for Anyone links",
    "Control" : "OneDrive 2.2",
    "Criticality" : "Should",
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : TenantInfo.ExternalUserExpirationRequired,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    TenantInfo := input.SPO_tenant_info
    Status := TenantInfo.ExternalUserExpirationRequired== true
}
#--

#
# Baseline 2.2: Policy 2
#--
tests[{
    "Requirement" : "Expiration date SHOULD be set to thirty days",
    "Control" : "OneDrive 2.2",
    "Criticality" : "Should",
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : TenantInfo.ExternalUserExpireInDays,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    TenantInfo := input.SPO_tenant_info
    Status := TenantInfo.ExternalUserExpireInDays == 30
}
#--


################
# Baseline 2.3 #
################

#
# Baseline 2.3: Policy 1
#--
tests[{
    "Requirement" : "Anyone link permissions SHOULD be limited to View",
    "Control" : "OneDrive 2.3",
    "Criticality" : "Should",
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : TenantInfo.DefaultLinkPermission,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    TenantInfo := input.SPO_tenant_info
    Status := TenantInfo.DefaultLinkPermission == 1
}
#--


################
# Baseline 2.4 #
################

#
# Baseline 2.4: Policy 1
#--
tests[{
    "Requirement" : "OneDrive Client for Windows SHALL be restricted to agency-Defined Domain(s)",
    "Control" : "OneDrive 2.4",
    "Criticality" : "Shall",
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : ["Domain GUID: ", Domain],
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    TenantSyncInfo := input.Tenant_sync_info
    Domain := input.Expected_results.Owner
    Status := Domain in TenantSyncInfo.AllowedDomainList
}
#--


################
# Baseline 2.5 #
################

#
# Baseline 2.5: Policy 1
#--
tests[{
    "Requirement" : "OneDrive Client Sync SHALL only be allowed only within the local domain",
    "Control" : "OneDrive 2.5",
    "Criticality" : "Shall",
    "Commandlet" : "Get-SPOTenant",
    "ActualValue" : TenantSyncInfo.BlockMacSync,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    TenantSyncInfo := input.Tenant_sync_info
    Status := TenantSyncInfo.BlockMacSync == false
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
    "Commandlet" : "",
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
    "Commandlet" : "",
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Onedrive Secure Configuration Baseline policy 2.7 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--