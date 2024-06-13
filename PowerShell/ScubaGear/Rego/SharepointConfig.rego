package sharepoint
import rego.v1
import data.utils.report.NotCheckedDetails
import data.utils.report.CheckedSkippedDetails
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsBooleanWarning
import data.utils.report.ReportDetailsString
import data.utils.key.FilterArray
import data.utils.key.FAIL
import data.utils.key.PASS


#############
# Constants #
#############

# Values in json for slider sharepoint/onedrive sharing settings
ONLYPEOPLEINORG := 0        # "Disabled" in functional tests
EXISTINGGUESTS := 3         # "ExistingExternalUserSharingOnly" in functional tests
NEWANDEXISTINGGUESTS := 1   # "ExternalUserSharingOnly" in functional tests
ANYONE := 2                 # "ExternalUserAndGuestSharing" in functional tests

######################################
# External sharing support functions #
######################################

SliderSettings(0) := "Only People In Your Organization"

SliderSettings(1) := "New and Existing Guests"

SliderSettings(2) := "Anyone"

SliderSettings(3) := "Existing Guests"

SliderSettings(Value) := "Unknown" if not Value in [0, 1, 2, 3]

Tenant := input.SPO_tenant[0] if {
    count(input.SPO_tenant) == 1
}

SharingCapability := Tenant.SharingCapability

SharingString := concat("", [
    "External Sharing is set to ",
    SliderSettings(SharingCapability),
    "."
])

NAString(SharingSetting) := concat("", [
        "This policy is only applicable if External Sharing is set to any value other than ",
        SharingSetting,
        ". ",
        "See %v for more info"
    ])


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
    input.OneDrive_PnP_Flag == false
    OneDriveSharingCapability := Tenant.OneDriveSharingCapability
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

# If Sharing Domain Restriction Mode is enabled, the policy should pass.
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [
        Tenant.SharingDomainRestrictionMode,
        SharingCapability
    ],
    "ReportDetails": ReportDetailsBooleanWarning(Status, NOTESTRING),
    "RequirementMet": Status
} if {
    SharingCapability != ONLYPEOPLEINORG
    Status := Tenant.SharingDomainRestrictionMode == 1
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails(PolicyId, Reason),
    "RequirementMet": false
} if {
    SharingCapability == ONLYPEOPLEINORG
    PolicyId := "MS.SHAREPOINT.1.3v1"
    Reason := NAString(SliderSettings(0))
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
        Tenant.RequireAcceptingAccountMatchInvitedAccount,
        SharingCapability
    ],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    SharingCapability != ONLYPEOPLEINORG
    Status := Tenant.RequireAcceptingAccountMatchInvitedAccount == true
}

tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails(PolicyId, Reason),
    "RequirementMet": false
} if {
    SharingCapability == ONLYPEOPLEINORG
    PolicyId := "MS.SHAREPOINT.1.4v1"
    Reason := NAString(SliderSettings(0))
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
    "ActualValue": [Tenant.DefaultSharingLinkType],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Status := Tenant.DefaultSharingLinkType == 1
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
    "ActualValue": [Tenant.DefaultLinkPermission],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Status := Tenant.DefaultLinkPermission == 1
}
#--

###################
# MS.SHAREPOINT.3 #
###################

#
# MS.SHAREPOINT.3.1v1
#--

ErrStr := concat(" ", [
    "Requirement not met:",
    "External Sharing is set to",
    SliderSettings(SharingCapability),
    "and expiration date is not set to 30 days or less."
])

# Standard test to compare against baseline
# This policy is only applicable if external sharing is set to "Anyone"
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant"],
    "ActualValue": [
        SharingCapability,
        Tenant.RequireAnonymousLinksExpireInDays
    ],
    "ReportDetails": ReportDetailsString(Status, ErrStr),
    "RequirementMet": Status
} if {
    SharingCapability == ANYONE
    Status := Tenant.RequireAnonymousLinksExpireInDays <= 30
}

# Test for N/A case
tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-SPOTenant"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails(PolicyId, Reason),
    "RequirementMet": false
} if {
    PolicyId := "MS.SHAREPOINT.3.1v1"
    SharingCapability != ANYONE
    Reason := NAString(SliderSettings(2))
}
#--


#
# MS.SHAREPOINT.3.2v1
#--

# Create Report Details string based on File link type & Folder link type
PERMISSION_STRING := "are not limited to view for Anyone"

FileAndFolderLinkPermission(1, 1) := PASS

FileAndFolderLinkPermission(2, 2) := concat(": ", [
    FAIL,
    concat(" ", ["both files and folders", PERMISSION_STRING])
])

FileAndFolderLinkPermission(1, 2) := concat(": ", [
    FAIL,
    concat(" ", ["folders", PERMISSION_STRING])
])

FileAndFolderLinkPermission(2, 1) := concat(": ", [
    FAIL,
    concat(" ", ["files", PERMISSION_STRING])
])

# This policy is only applicable if external sharing is set to "Anyone"
# Both link types must be 1 & OneDrive_PnP_Flag must be false for policy to pass
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [FileLinkType, FolderLinkType],
    "ReportDetails": FileAndFolderLinkPermission(FileLinkType, FolderLinkType),
    "RequirementMet": Status
} if {
    input.OneDrive_PnP_Flag == false
    SharingCapability == ANYONE

    FileLinkType := Tenant.FileAnonymousLinkType
    FolderLinkType := Tenant.FolderAnonymousLinkType
    Conditions := [
        FileLinkType == 1,
        FolderLinkType == 1
    ]
    Status := count(FilterArray(Conditions, true)) == 2
}

# Test for N/A case
tests contains {
    "PolicyId": PolicyId,
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails(PolicyId, Reason),
    "RequirementMet": false
} if {
    PolicyId := "MS.SHAREPOINT.3.2v1"
    input.OneDrive_PnP_Flag == false
    SharingCapability != ANYONE
    Reason := NAString(SliderSettings(2))
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

VERIFICATION_STRING := "Expiration time for 'People who use a verification code' NOT"

# PolicyNotApplicable_Group3 handles the correct SharingCapability setting.
# This ruleset only checks if verification code reauthentication is enabled,
# and if the verification time is valid (less than or equal to 30 days)
VerificationCodeReAuthExpiration(tenant) := [PASS, true] if {
    tenant.EmailAttestationRequired == true
    tenant.EmailAttestationReAuthDays <= 30
} else := [ErrStr, false] if {
    tenant.EmailAttestationRequired == false
    tenant.EmailAttestationReAuthDays <= 30
    ErrStr := concat(": ", [FAIL, concat(" ", [VERIFICATION_STRING, "enabled"])])
} else := [ErrStr, false] if {
    tenant.EmailAttestationRequired == true
    tenant.EmailAttestationReAuthDays > 30
    ErrStr := concat(": ", [FAIL, concat(" ", [VERIFICATION_STRING, "set to 30 days or less"])])
} else := [ErrStr, false] if {
    tenant.EmailAttestationRequired == false
    tenant.EmailAttestationReAuthDays > 30
    ErrStr := concat(": ", [FAIL, concat(" ", [VERIFICATION_STRING, "enabled and set to 30 days or more"])])
} else := [FAIL, false]

# This policy is only applicable if external sharing is set to "Anyone",
# or "New and existing guests"
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [
        SharingCapability,
        Tenant.EmailAttestationRequired,
        Tenant.EmailAttestationReAuthDays
    ],
    "ReportDetails": ReportDetailsString(Status, ErrMsg),
    "RequirementMet": Status
} if {
    SharingCapability in [ANYONE, NEWANDEXISTINGGUESTS]

    [ErrMsg, Status] := VerificationCodeReAuthExpiration(Tenant)
}

# Test for N/A case
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails(PolicyId, Reason),
    "RequirementMet": false
} if {
    PolicyId := "MS.SHAREPOINT.3.3v1"
    not SharingCapability in [ANYONE, NEWANDEXISTINGGUESTS]
    Reason := concat(" ", [
        SharingString,
        NAString(concat(" ", [SliderSettings(0), "or", SliderSettings(3)]))
        ])
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