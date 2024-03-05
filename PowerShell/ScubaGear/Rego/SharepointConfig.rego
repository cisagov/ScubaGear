package sharepoint
import rego.v1
import data.utils.report.NotCheckedDetails
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsString
import data.utils.key.FilterArray
import data.utils.key.FAIL
import data.utils.key.PASS


#############
# Constants #
#############

# Values in json for slider sharepoint/onedrive sharing settings
ONLYPEOPLEINORG := 0

EXISTINGGUESTS := 3

NEWANDEXISTINGGUESTS := 1

ANYONE := 2


###################
# MS.SHAREPOINT.1 #
###################

#
# MS.SHAREPOINT.1.1v1
#--

# If SharingCapability is set to Only People In Organization
# OR Existing Guests, the policy should pass.
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [SharingCapability],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some TenantPolicy in input.SPO_tenant
    SharingCapability := TenantPolicy.SharingCapability
    Conditions := [
        SharingCapability == ONLYPEOPLEINORG,
        SharingCapability == EXISTINGGUESTS
    ]
    Status := count(FilterArray(Conditions, true)) == 1
}
#--

#
# MS.SHAREPOINT.1.2v1
#--

# If OneDriveSharingCapability is set to Only People In Organization
# OR Existing Guests, the policy should pass.
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [OneDriveSharingCapability],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some TenantPolicy in input.SPO_tenant
    OneDriveSharingCapability := TenantPolicy.OneDriveSharingCapability
    input.OneDrive_PnP_Flag == false
    Conditions := [
        OneDriveSharingCapability == ONLYPEOPLEINORG,
        OneDriveSharingCapability == EXISTINGGUESTS
    ]
    Status := count(FilterArray(Conditions, true)) == 1
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails(PolicyId),
    "RequirementMet": false
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
NOTESTRING := concat(" ", NoteArray)

Domainlist(TenantPolicy) := Description if {
    TenantPolicy.SharingCapability == ONLYPEOPLEINORG
    Description := "Requirement met: external sharing is set to Only People In Organization"
}

Domainlist(TenantPolicy) := concat(": ", [PASS, NOTESTRING]) if {
    TenantPolicy.SharingCapability != ONLYPEOPLEINORG
    TenantPolicy.SharingDomainRestrictionMode == 1
}

Domainlist(TenantPolicy) := concat(": ", [FAIL, NOTESTRING]) if {
    TenantPolicy.SharingCapability != ONLYPEOPLEINORG
    TenantPolicy.SharingDomainRestrictionMode != 1
}

# If SharingCapability is set to Only People In Organization
# OR Sharing Domain Restriction Mode is enabled,
# the policy should pass.
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [
        TenantPolicy.SharingDomainRestrictionMode,
        TenantPolicy.SharingCapability
    ],
    "ReportDetails": Domainlist(TenantPolicy),
    "RequirementMet": Status
} if {
    some TenantPolicy in input.SPO_tenant
    Conditions := [
        TenantPolicy.SharingCapability == ONLYPEOPLEINORG,
        TenantPolicy.SharingDomainRestrictionMode == 1
    ]
    Status := count(FilterArray(Conditions, true)) == 1
}
#--

#
# MS.SHAREPOINT.1.4v1
#--

# If SharingCapability is set to Only People In Organization
# OR require account login to be the one on the invite enabled,
# the policy should pass.
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.4v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [
        TenantPolicy.RequireAcceptingAccountMatchInvitedAccount,
        TenantPolicy.SharingCapability
    ],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some TenantPolicy in input.SPO_tenant
    Conditions := [
        TenantPolicy.SharingCapability == ONLYPEOPLEINORG,
        TenantPolicy.RequireAcceptingAccountMatchInvitedAccount == true
    ]
    Status := count(FilterArray(Conditions, true)) >= 1
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
# Default Sharing Link should be set to specific people
tests contains {
    "PolicyId": "MS.SHAREPOINT.2.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TenantPolicy.DefaultSharingLinkType],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some TenantPolicy in input.SPO_tenant
    Status := TenantPolicy.DefaultSharingLinkType == 1
}
#--

#
# MS.SHAREPOINT.2.2v1
#--

# DefaultLinkPermission == 1 view
# DefaultLinkPermission == 2 edit

# Default link permission should be set to view
tests contains {
    "PolicyId": "MS.SHAREPOINT.2.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [TenantPolicy.DefaultLinkPermission],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some TenantPolicy in input.SPO_tenant
    Status := TenantPolicy.DefaultLinkPermission == 1
}
#--

###################
# MS.SHAREPOINT.3 #
###################

#
# MS.SHAREPOINT.3.1v1
#--

# If SharingCapability is set to Only People In Organization
# OR Existing Guests, the policy should pass.
ExternalUserExpireInDays(TenantPolicy) := ["", true] if {
    Conditions := [
        TenantPolicy.SharingCapability == ONLYPEOPLEINORG,
        TenantPolicy.SharingCapability == EXISTINGGUESTS
    ]
    count(FilterArray(Conditions, true)) == 1
}

# If SharingCapability is set to New and Existing Guests
# OR Anyone, AND anonymous links are set to expire
# in 30 days or less, the policy should pass, else fail.
# The error message is concatanated by 2 steps to insert the
# result of ReportBoolean in front, & the setting in the middle.
SHARINGCAPABILITY := "New and Existing Guests" if
    # regal ignore:prefer-some-in-iteration
    input.SPO_tenant[_].SharingCapability == NEWANDEXISTINGGUESTS

SHARINGCAPABILITY := "Anyone" if
    # regal ignore:prefer-some-in-iteration
    input.SPO_tenant[_].SharingCapability == ANYONE

ERRSTRING := concat(" ", [
    "External Sharing is set to",
    SHARINGCAPABILITY,
    "and expiration date is not 30 days or less"
    ])

ExternalUserExpireInDays(TenantPolicy) := [concat(": ", [FAIL, ERRSTRING]), Status] if {
    Conditions := [
        TenantPolicy.SharingCapability == NEWANDEXISTINGGUESTS,
        TenantPolicy.SharingCapability == ANYONE
    ]
    count(FilterArray(Conditions, true)) > 0
    Status := TenantPolicy.RequireAnonymousLinksExpireInDays <= 30
}

tests contains {
    "PolicyId": "MS.SHAREPOINT.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [
        TenantPolicy.SharingCapability,
        TenantPolicy.RequireAnonymousLinksExpireInDays
    ],
    "ReportDetails": ReportDetailsString(Status, ErrMsg),
    "RequirementMet": Status
} if {
    some TenantPolicy in input.SPO_tenant
    [ErrMsg, Status] := ExternalUserExpireInDays(TenantPolicy)
}
#--

#
# MS.SHAREPOINT.3.2v1
#--

# Create Repot Detatils string based on File link type & Folder link type
PERMISSIONSTRING := "are not limited to view for Anyone"

FileAndFolderPermission(1, 1) := PASS

FileAndFolderPermission(2, 2) := concat(": ", [
        FAIL,
        concat(" ", ["both files and folders", PERMISSIONSTRING])
    ])

FileAndFolderPermission(1, 2) := concat(": ", [
        FAIL,
        concat(" ", ["folders", PERMISSIONSTRING])
    ])

FileAndFolderPermission(2, 1) := concat(": ", [
        FAIL,
        concat(" ", ["files", PERMISSIONSTRING])
    ])

# Both link types must be 2 & OneDrive_PnP_Flag must be false for policy to pass
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [FileLinkType, FolderLinkType],
    "ReportDetails": FileAndFolderPermission(FileLinkType, FolderLinkType),
    "RequirementMet": Status
} if {
    some TenantPolicy in input.SPO_tenant
    FileLinkType := TenantPolicy.FileAnonymousLinkType
    FolderLinkType := TenantPolicy.FolderAnonymousLinkType
    input.OneDrive_PnP_Flag == false
    Conditions := [
        FileLinkType == 2,
        FolderLinkType == 2
    ]
    Status := count(FilterArray(Conditions, true)) == 0
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails(PolicyId),
    "RequirementMet": false
} if {
    PolicyId := "MS.SHAREPOINT.3.2v1"
    input.OneDrive_PnP_Flag == true
}
#--

#
# MS.SHAREPOINT.3.3v1
#--

VERIFICATIONSTRING := "Expiration timer for 'People who use a verification code' NOT"

# If Sharing set to Only People In Org, pass
ExpirationTimersVerificationCode(TenantPolicy) := ["", true] if {
    TenantPolicy.SharingCapability == ONLYPEOPLEINORG
}

# If Sharing NOT set to Only People In Org, reathentication enabled,
# & reauth sent to <= 30 days, pass
ExpirationTimersVerificationCode(TenantPolicy) := ["", true] if {
    TenantPolicy.SharingCapability != ONLYPEOPLEINORG
    TenantPolicy.EmailAttestationRequired == true
    TenantPolicy.EmailAttestationReAuthDays <= 30
}

# If Sharing NOT set to Only People In Org & reathentication disbled,
# fail
ExpirationTimersVerificationCode(TenantPolicy) := [ErrMsg, false] if {
    TenantPolicy.SharingCapability != ONLYPEOPLEINORG
    TenantPolicy.EmailAttestationRequired == false
    TenantPolicy.EmailAttestationReAuthDays <= 30
    ErrMsg := concat(": ", [FAIL, concat(" ", [VERIFICATIONSTRING, "enabled"])])
}

# If Sharing NOT set to Only People In Org & reauth sent to > 30 days, fail
ExpirationTimersVerificationCode(TenantPolicy) := [ErrMsg, false] if {
    TenantPolicy.SharingCapability != ONLYPEOPLEINORG
    TenantPolicy.EmailAttestationRequired == true
    TenantPolicy.EmailAttestationReAuthDays > 30
    ErrMsg := concat(": ", [FAIL, concat(" ", [VERIFICATIONSTRING, "set to 30 days"])])
}

# If Sharing NOT set to Only People In Org, reathentication disabled,
# & reauth sent to > 30 days, fail
ExpirationTimersVerificationCode(TenantPolicy) := [ErrMsg, false] if {
    TenantPolicy.SharingCapability != ONLYPEOPLEINORG
    TenantPolicy.EmailAttestationRequired == false
    TenantPolicy.EmailAttestationReAuthDays > 30
    ErrMsg := concat(": ", [FAIL, concat(" ", [VERIFICATIONSTRING, "enabled and set to >30 days"])])
}

tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [
        TenantPolicy.SharingCapability,
        TenantPolicy.EmailAttestationRequired,
        TenantPolicy.EmailAttestationReAuthDays
    ],
    "ReportDetails": ReportDetailsString(Status, ErrMsg),
    "RequirementMet": Status
} if {
    some TenantPolicy in input.SPO_tenant
    [ErrMsg, Status] := ExpirationTimersVerificationCode(TenantPolicy)
}
#--

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
    "RequirementMet": false
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
    "RequirementMet": Status
} if {
    some SitePolicy in input.SPO_site
    Status := SitePolicy.DenyAddAndCustomizePages == 2
}
#--