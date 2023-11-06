package sharepoint
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.ReportDetailsBoolean
import data.report.utils.ReportDetailsString

#############
# Constants #
#############

TENANTPOLICY := input.SPO_tenant[_]
FAIL := ReportDetailsBoolean(false)
PASS := ReportDetailsBoolean(true)

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

tests contains {
    "PolicyId": "MS.SHAREPOINT.1.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [SharingCapability],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status,
} if {
    SharingCapability := TENANTPOLICY.SharingCapability
    Conditions := [SharingCapability == 0, SharingCapability == 3]
    Status := count([Condition | some Condition in Conditions; Condition == true]) == 1
}

#--

#
# MS.SHAREPOINT.1.2v1
#--

tests contains {
    "PolicyId": "MS.SHAREPOINT.1.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [OneDriveSharingCapability],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status,
} if {
    input.OneDrive_PnP_Flag == false
    OneDriveSharingCapability := TENANTPOLICY.OneDriveSharingCapability
    Conditions := [OneDriveSharingCapability == 0, OneDriveSharingCapability == 3]
    Status := count([Condition | some Condition in Conditions; Condition == true]) == 1
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails(PolicyId),
    "RequirementMet": false,
} if {
    PolicyId := "MS.SHAREPOINT.1.2v1"
    input.OneDrive_PnP_Flag == true
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
NoteArray := [
    "Note that we currently only check for approved external domains.",
    "Approved security groups are currently not being checked,",
    "see the baseline policy for instructions on a manual check."
]
NoteString := concat(" ", NoteArray)

Domainlist(TenantPolicy) := Description if {
    TenantPolicy.SharingCapability == 0
    Description := "Requirement met: external sharing is set to Only People In Organization"
}

Domainlist(TenantPolicy) := concat(": ", [PASS, NoteString]) if {
    TenantPolicy.SharingCapability != 0
    TenantPolicy.SharingDomainRestrictionMode == 1
}

Domainlist(TenantPolicy) := concat(": ", [FAIL, NoteString]) if {
    TenantPolicy.SharingCapability != 0
    TenantPolicy.SharingDomainRestrictionMode != 1
}

tests contains {
    "PolicyId": "MS.SHAREPOINT.1.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TENANTPOLICY.SharingDomainRestrictionMode, TENANTPOLICY.SharingCapability],
    "ReportDetails": Domainlist(TENANTPOLICY),
    "RequirementMet": Status,
} if {
    Conditions := [TENANTPOLICY.SharingCapability == 0, TENANTPOLICY.SharingDomainRestrictionMode == 1]
    Status := count([Condition | some Condition in Conditions; Condition == true]) == 1
}

#--

#
# MS.SHAREPOINT.1.4v1
#--

tests contains {
    "PolicyId": "MS.SHAREPOINT.1.4v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TENANTPOLICY.RequireAcceptingAccountMatchInvitedAccount, TENANTPOLICY.SharingCapability],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status,
} if {
    Conditions := [TENANTPOLICY.SharingCapability == 0, TENANTPOLICY.RequireAcceptingAccountMatchInvitedAccount == true]
    Status := count([Condition | some Condition in Conditions; Condition == true]) >= 1
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

tests contains {
    "PolicyId": "MS.SHAREPOINT.2.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TENANTPOLICY.DefaultSharingLinkType],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status,
} if {
    Status := TENANTPOLICY.DefaultSharingLinkType == 1
}

#--

#
# MS.SHAREPOINT.2.2v1
#--

# SPO_tenant - DefaultLinkPermission
# 1 view 2 edit

tests contains {
    "PolicyId": "MS.SHAREPOINT.2.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TENANTPOLICY.DefaultLinkPermission],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status,
} if {
    Status := TENANTPOLICY.DefaultLinkPermission == 1
}

###################
# MS.SHAREPOINT.3 #
###################

#
# MS.SHAREPOINT.3.1v1
#--

ExternalUserExpireInDays(TenantPolicy) := ["", true] if {
    Conditions := [TenantPolicy.SharingCapability == 0, TenantPolicy.SharingCapability == 3]
    count([Condition | some Condition in Conditions; Condition == true]) > 0
}

ExternalUserExpireInDays(TenantPolicy) := ["", true] if {
    Conditions := [TenantPolicy.SharingCapability == 1, TenantPolicy.SharingCapability == 2]
    count([Condition | some Condition in Conditions; Condition == true]) > 0
    TenantPolicy.RequireAnonymousLinksExpireInDays <= 30
}

ExternalUserExpireInDays(TenantPolicy) := [ErrMsg, false] if {
    TenantPolicy.SharingCapability == 1
    TenantPolicy.RequireAnonymousLinksExpireInDays > 30
    ErrString := "External Sharing is set to New and Existing Guests and expiration date is not 30 days or less"
    ErrMsg := concat(": ", [FAIL, ErrString])
}

ExternalUserExpireInDays(TenantPolicy) := [ErrMsg, false] if {
    TenantPolicy.SharingCapability == 2
    TenantPolicy.RequireAnonymousLinksExpireInDays > 30
    ErrString := "External Sharing is set to Anyone and expiration date is not 30 days or less"
    ErrMsg := concat(": ", [FAIL, ErrString])
}

tests contains {
    "PolicyId": "MS.SHAREPOINT.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TENANTPOLICY.SharingCapability, TENANTPOLICY.RequireAnonymousLinksExpireInDays],
    "ReportDetails": ReportDetailsString(Status, ErrMsg),
    "RequirementMet": Status,
} if {
    [ErrMsg, Status] := ExternalUserExpireInDays(TENANTPOLICY)
}

#--

#
# MS.SHAREPOINT.3.2v1

FileAndFolderPermission(1, 1) := PASS if {}

FileAndFolderPermission(2, 2) := concat(": ", [FAIL, "both files and folders are not limited to view for Anyone"]) if {}

FileAndFolderPermission(1, 2) := concat(": ", [FAIL, "folders are not limited to view for Anyone"]) if {}

FileAndFolderPermission(2, 1) := concat(": ", [FAIL, "files are not limited to view for Anyone"]) if {}

tests contains {
    "PolicyId": "MS.SHAREPOINT.3.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [FileLinkType, FolderLinkType],
    "ReportDetails": FileAndFolderPermission(FileLinkType, FolderLinkType),
    "RequirementMet": Status,
} if {
    input.OneDrive_PnP_Flag == false
    FileLinkType := TENANTPOLICY.FileAnonymousLinkType
    FolderLinkType := TENANTPOLICY.FolderAnonymousLinkType
    Conditions := [FileLinkType == 2, FolderLinkType == 2]
    Status := count([Condition | some Condition in Conditions; Condition == true]) == 0
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails(PolicyId),
    "RequirementMet": false,
} if {
    PolicyId := "MS.SHAREPOINT.3.2v1"
    input.OneDrive_PnP_Flag == true
}

#--

#
# MS.SHAREPOINT.3.3v1
#--

ExpirationTimersVerificationCode(TenantPolicy) := ["", true] if {
    TenantPolicy.SharingCapability == 0
}

ExpirationTimersVerificationCode(TenantPolicy) := ["", true] if {
    TenantPolicy.SharingCapability != 0
    TenantPolicy.EmailAttestationRequired == true
    TenantPolicy.EmailAttestationReAuthDays <= 30
}

ExpirationTimersVerificationCode(TenantPolicy) := [ErrMsg, false] if {
    TenantPolicy.SharingCapability != 0
    TenantPolicy.EmailAttestationRequired == false
    TenantPolicy.EmailAttestationReAuthDays <= 30
    ErrMsg := concat(": ", [FAIL, "Expiration timer for 'People who use a verification code' NOT enabled"])
}

ExpirationTimersVerificationCode(TenantPolicy) := [ErrMsg, false] if {
    TenantPolicy.SharingCapability != 0
    TenantPolicy.EmailAttestationRequired == true
    TenantPolicy.EmailAttestationReAuthDays > 30
    ErrMsg := concat(": ", [FAIL, "Expiration timer for 'People who use a verification code' NOT set to 30 days"])
}

ExpirationTimersVerificationCode(TenantPolicy) := [ErrMsg, false] if {
    TenantPolicy.SharingCapability != 0
    TenantPolicy.EmailAttestationRequired == false
    TenantPolicy.EmailAttestationReAuthDays > 30
    ErrMsg := concat(": ", [FAIL, "Expiration timer for 'People who use a verification code' NOT enabled and set to greater 30 days"])
}

tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TENANTPOLICY.SharingCapability, TENANTPOLICY.EmailAttestationRequired, TENANTPOLICY.EmailAttestationReAuthDays],
    "ReportDetails": ReportDetailsString(Status, ErrMsg),
    "RequirementMet": Status,
} if {
    [ErrMsg, Status] := ExpirationTimersVerificationCode(TENANTPOLICY)
}

###################
# MS.SHAREPOINT.4 #
###################

#
# MS.SHAREPOINT.4.1v1
#--

# At this time we are unable to test for running custom scripts on personal sites
# because we have yet to find the setting to check
tests contains {
    "PolicyId": "MS.SHAREPOINT.4.1v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SHAREPOINT.4.1v1"),
    "RequirementMet": false,
}

#--

#
# MS.SHAREPOINT.4.2v1
#--

# 1 == Allow users to run custom script on self-service created sites
# 2 == Prevent users from running custom script on self-service created sites

tests contains {
    "PolicyId": "MS.SHAREPOINT.4.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOSite", "Get-PnPTenantSite"],
    "ActualValue": [SitePolicy.DenyAddAndCustomizePages],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status,
} if {
    some SitePolicy in input.SPO_site
    Status := SitePolicy.DenyAddAndCustomizePages == 2
}

#--