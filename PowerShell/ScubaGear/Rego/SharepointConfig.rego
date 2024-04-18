package sharepoint
import rego.v1
import data.utils.report.NotCheckedDetails
import data.utils.report.CheckedSkippedDetails
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

# Suggest renaming constants for readability
ONLY_PEOPLE_IN_ORG := 0      # "Disabled" in functional tests
EXISTING_GUESTS := 3         # "ExistingExternalUserSharingOnly" in functional tests 
NEW_AND_EXISTING_GUESTS := 1 # "ExternalUserSharingOnly" in functional tests 
ANYONE := 2                  # "ExternalUserandGuestSharing" in functional tests 

######################################
# External sharing support functions #
######################################

SliderSettings(Value) := "Only people in your organization" if {
    Value == 0
} else := "New and existing guests" if {
    Value == 1
} else := "Anyone" if {
    Value == 2
} else := "Existing guests" if {
    Value == 3
} else := Value

SharingCapability := Setting if {
    some tenant in input.SPO_tenant
    Setting := tenant.SharingCapability
}

CheckSharingCapability(InvalidConditions) := true if {
    SharingCapability in InvalidConditions
} else := false


PolicyNotApplicable_Group3(Conditions) := true if {
    SharingCapability in Conditions
} else := false

# "This policy is only applicable if External Sharing is set to Anyone. See %v for more info"

CheckPolicyNotApplicable(InvalidConditions, DetailStr) := [Reason, true] if {
    Reason := concat(" ", [
        concat("", [
            "External Sharing is set to ",
            SliderSettings(SharingCapability),
            "."
        ]),
        DetailStr
    ])

    CheckSharingCapability(InvalidConditions) == true
} else := false


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

ErrStr := concat(" ", [
    "External Sharing is set to",
    SliderSettings(SharingCapability),
    "and expiration date is not set to 30 days or less."
])

# Non-compliant case
ExternalUserLinksExpireInDays(tenant) := [concat(": ", [FAIL, ErrStr]), false] if {
    tenant.RequireAnonymousLinksExpireInDays > 30
}

# Policy is compliant if expiration days for Anyone links is set to 30 days or less
ExternalUserLinksExpireInDays(tenant) := [PASS, true] if {
    tenant.RequireAnonymousLinksExpireInDays <= 30
}

# Test for N/A case
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.1v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-SPOTenant"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails(PolicyId, Reason),
    "RequirementMet": false
} if {
    PolicyId := "MS.SHAREPOINT.3.1v1"
    [Reason, Result] := CheckPolicyNotApplicable(
        [ONLY_PEOPLE_IN_ORG, EXISTING_GUESTS, NEW_AND_EXISTING_GUESTS],
        "This policy is only applicable if External Sharing is set to Anyone. See %v for more info"
    )
    Result == true
}

# Standard test to compare against baseline
# This policy is only applicable if external sharing is set to "Anyone"
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant"],
    "ActualValue": [
        SharingCapability, 
        tenant.RequireAnonymousLinksExpireInDays
    ],
    "ReportDetails": ReportDetailsString(Status, ErrMsg),
    "RequirementMet": Status
} if {
    CheckPolicyNotApplicable([ONLY_PEOPLE_IN_ORG, EXISTING_GUESTS, NEW_AND_EXISTING_GUESTS], "") == false
    SharingCapability == ANYONE

    some tenant in input.SPO_tenant
    [ErrMsg, Status] = ExternalUserLinksExpireInDays(tenant)
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

# Test for N/A case
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.2v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails(PolicyId, Reason),
    "RequirementMet": false
} if {
    PolicyId := "MS.SHAREPOINT.3.2v1"
    [Reason, Result] := CheckPolicyNotApplicable(
        [ONLY_PEOPLE_IN_ORG, EXISTING_GUESTS, NEW_AND_EXISTING_GUESTS],
        "This policy is only applicable if External Sharing is set to Anyone. See %v for more info"
    )
    Result == true
}

# This policy is only applicable if external sharing is set to "Anyone"
# Both link types must be 2 & OneDrive_PnP_Flag must be false for policy to pass
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [FileLinkType, FolderLinkType],
    "ReportDetails": FileAndFolderLinkPermission(FileLinkType, FolderLinkType),
    "RequirementMet": Status
} if {
    CheckPolicyNotApplicable([ONLY_PEOPLE_IN_ORG, EXISTING_GUESTS, NEW_AND_EXISTING_GUESTS], "") == false
    SharingCapability == ANYONE

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
    [Reason, Result] := CheckPolicyNotApplicable(
        [ONLY_PEOPLE_IN_ORG],
        "This policy is only applicable if External Sharing is set to Anyone, New and existing guests, or Existing guests. See %v for more info"
    )
    Result == true
}

# This policy is only applicable if external sharing is set to "Anyone", 
# "New and existing guests", or "Existing guests"
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenant", "Get-PnPTenant"],
    "ActualValue": [
        SharingCapability,
        tenant.EmailAttestationRequired,
        tenant.EmailAttestationReAuthDays
    ],
    "ReportDetails": ReportDetailsString(Status, ErrMsg),
    "RequirementMet": Status
} if {
    CheckPolicyNotApplicable([ONLY_PEOPLE_IN_ORG], "") == false
    SharingCapability in [ANYONE, NEW_AND_EXISTING_GUESTS, EXISTING_GUESTS]

    some tenant in input.SPO_tenant
    [ErrMsg, Status] := VerificationCodeReAuthExpiration(tenant)
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