package sharepoint
import rego.v1
import data.utils.report.CheckedSkippedDetails
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsBooleanWarning
import data.utils.report.ReportDetailsString
import data.utils.key.FilterArray
import data.utils.key.FAIL
import data.utils.key.PASS


#############
# Constants and helper rulesets
#############

# Values in json for slider sharepoint/onedrive sharing settings
ONLYPEOPLEINORG := 0        # "Disabled" in functional tests
EXISTINGGUESTS := 3         # "ExistingExternalUserSharingOnly" in functional tests
NEWANDEXISTINGGUESTS := 1   # "ExternalUserSharingOnly" in functional tests
ANYONE := 2                 # "ExternalUserAndGuestSharing" in functional tests

SliderSettings(0) := "Only People In Your Organization"

SliderSettings(1) := "New and Existing Guests"

SliderSettings(2) := "Anyone"

SliderSettings(3) := "Existing Guests"

SliderSettings(Value) := "Unknown" if not Value in [0, 1, 2, 3]

NAString(SharingSetting, Negation) := concat("", [
    "This policy is only applicable if the external sharing slider in the SharePoint admin center is set to ",
    SharingSetting,
    ". ",
    "See %v for more info"
]) if Negation == false
else := concat("", [
    "This policy is only applicable if the external sharing slider in the SharePoint admin center is not set to ",
    SharingSetting,
    ". ",
    "See %v for more info"
]) if Negation == true

# All of the SharePoint settings
default SPOTenant := {}
SPOTenant := object.get(input, "SPO_tenant", [{}])[0] if {
    count(object.get(input, "SPO_tenant", [])) > 0
} 

# SharingCapability is referenced by many of the policies
SharingCapabilitySetting := object.get(SPOTenant, "SharingCapability", null)

### End Constants and helper rulesets


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
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [SharingCapabilitySetting],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    SharingCapabilitySetting != null

    Conditions := [
        SharingCapabilitySetting == ONLYPEOPLEINORG,
        SharingCapabilitySetting == EXISTINGGUESTS
    ]

    Status := count(FilterArray(Conditions, true)) == 1
}

# Test for settings not found in JSON
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "SPO_tenant or SharingCapability are missing from input JSON",
    "RequirementMet": false
} if {
    MissingConditions := [
        # count(SharepointSettings) == 0,
        count(SPOTenant) == 0,
        SharingCapabilitySetting == null
    ]

    some condition in MissingConditions
    condition
}
#--

#
# MS.SHAREPOINT.1.2v1
#--

ODBSharingCapabilitySetting := object.get(SPOTenant, "ODBSharingCapability", null)


# If ODBSharingCapability is set to Only People In Organization
# OR Existing Guests, the policy should pass.
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [ODBSharingCapabilitySetting],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    ODBSharingCapabilitySetting != null

    Conditions := [
        ODBSharingCapabilitySetting == ONLYPEOPLEINORG,
        ODBSharingCapabilitySetting == EXISTINGGUESTS
    ]

    Status := count(FilterArray(Conditions, true)) == 1
}

# Test for settings not found in JSON
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "SPO_tenant or ODBSharingCapability are missing from input JSON",
    "RequirementMet": false
} if {
    MissingConditions := [
        # count(SharepointSettings) == 0,
        count(SPOTenant) == 0,
        ODBSharingCapabilitySetting == null
    ]

    some condition in MissingConditions
    condition
}
#--

#
# MS.SHAREPOINT.1.3v1
#--

# SharingDomainRestrictionMode == 0 Unchecked
# SharingDomainRestrictionMode == 1 Checked
# SharingAllowedDomainList == "domains" Domain list

SharingDomainRestrictionModeSetting := object.get(SPOTenant, "SharingDomainRestrictionMode", null)

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
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [
        SharingDomainRestrictionModeSetting,
        SharingCapabilitySetting
    ],
    "ReportDetails": ReportDetailsBooleanWarning(Status, NOTESTRING),
    "RequirementMet": Status
} if {
    SharingDomainRestrictionModeSetting != null
    SharingCapabilitySetting != null

    SharingCapabilitySetting != ONLYPEOPLEINORG
    Status := SharingDomainRestrictionModeSetting == 1
}

# Test for N/A case where sharing is set to Only people in your organization
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails("MS.SHAREPOINT.1.3v1", Reason),
    "RequirementMet": true
} if {
    SharingDomainRestrictionModeSetting != null
    SharingCapabilitySetting != null
    SharingCapabilitySetting == ONLYPEOPLEINORG
    Reason := NAString(SliderSettings(0), true)
}

# Test for settings not found in JSON
tests contains {
    "PolicyId": "MS.SHAREPOINT.1.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "SPO_tenant or SharingDomainRestrictionMode or SharingCapability are missing from input JSON",
    "RequirementMet": false
} if {
    MissingConditions := [
        # count(SharepointSettings) == 0,
        count(SPOTenant) == 0,
        SharingCapabilitySetting == null,
        SharingDomainRestrictionModeSetting == null
    ]

    some condition in MissingConditions
    condition
}
#--

###################
# MS.SHAREPOINT.2 #
###################

#
# MS.SHAREPOINT.2.1v1
#--

DefaultSharingLinkTypeSetting := object.get(SPOTenant, "DefaultSharingLinkType", null)

# DefaultSharingLinkType == 1 for Specific People
# DefaultSharingLinkType == 2 for Only people in your organization
# Default Sharing Link should be set to specific people
tests contains {
    "PolicyId": "MS.SHAREPOINT.2.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [DefaultSharingLinkTypeSetting],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    DefaultSharingLinkTypeSetting != null

    Status := DefaultSharingLinkTypeSetting == 1
}

# Test for settings not found in JSON
tests contains {
    "PolicyId": "MS.SHAREPOINT.2.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "SPO_tenant or DefaultSharingLinkType are missing from input JSON",
    "RequirementMet": false
} if {
    MissingConditions := [
        count(SPOTenant) == 0,
        DefaultSharingLinkTypeSetting == null
    ]

    some condition in MissingConditions
    condition
}
#--

#
# MS.SHAREPOINT.2.2v1
#--

DefaultLinkPermissionSetting := object.get(SPOTenant, "DefaultLinkPermission", null)

# DefaultLinkPermission == 1 view
# DefaultLinkPermission == 2 edit

# Default link permission should be set to view
tests contains {
    "PolicyId": "MS.SHAREPOINT.2.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [DefaultLinkPermissionSetting],
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    DefaultLinkPermissionSetting != null

    Status := DefaultLinkPermissionSetting == 1
}

# Test for settings not found in JSON
tests contains {
    "PolicyId": "MS.SHAREPOINT.2.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "SPO_tenant or DefaultLinkPermission are missing from input JSON",
    "RequirementMet": false
} if {
    MissingConditions := [
        count(SPOTenant) == 0,
        DefaultLinkPermissionSetting == null
    ]

    some condition in MissingConditions
    condition
}
#--

###################
# MS.SHAREPOINT.3 #
###################

#
# MS.SHAREPOINT.3.1v1
#--

RequireAnonymousLinksExpireInDaysSetting := object.get(SPOTenant, "RequireAnonymousLinksExpireInDays", null)

ErrStr := concat(" ", [
    "Requirement not met:",
    "total expiration days are not set to 30 days or less"
])

# Standard test to compare against baseline
# This policy is only applicable if external sharing is set to "Anyone"
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [
        SharingCapabilitySetting,
        RequireAnonymousLinksExpireInDaysSetting
    ],
    "ReportDetails": ReportDetailsString(Status, ErrStr),
    "RequirementMet": Status
} if {
    SharingCapabilitySetting != null
    SharingCapabilitySetting == ANYONE

    RequireAnonymousLinksExpireInDaysSetting != null
    Conditions := [
        RequireAnonymousLinksExpireInDaysSetting >= 1,
        RequireAnonymousLinksExpireInDaysSetting <= 30
    ]
    Status := count(FilterArray(Conditions, true)) == 2
}

# Test for N/A case where sharing is set to New and existing guests, Existing guests, or Only people in your organization.
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails("MS.SHAREPOINT.3.1v1", Reason),
    "RequirementMet": true
} if {
    SharingCapabilitySetting != null
    SharingCapabilitySetting != ANYONE
    RequireAnonymousLinksExpireInDaysSetting != null
    Reason := NAString(SliderSettings(2), false)
}

# Test for settings not found in JSON
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "SPO_tenant or RequireAnonymousLinksExpireInDays or SharingCapability are missing from input JSON",
    "RequirementMet": false
} if {
    MissingConditions := [
        count(SPOTenant) == 0,
        SharingCapabilitySetting == null,
        RequireAnonymousLinksExpireInDaysSetting == null
    ]

    some condition in MissingConditions
    condition
}
#--


#
# MS.SHAREPOINT.3.2v1
#--

FileAnonymousLinkTypeSetting := object.get(SPOTenant, "FileAnonymousLinkType", null)
FolderAnonymousLinkTypeSetting := object.get(SPOTenant, "FolderAnonymousLinkType", null)

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
# Both link types must be 1 for policy to pass
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [FileAnonymousLinkTypeSetting, FolderAnonymousLinkTypeSetting],
    "ReportDetails": FileAndFolderLinkPermission(FileAnonymousLinkTypeSetting, FolderAnonymousLinkTypeSetting),
    "RequirementMet": Status
} if {
    SharingCapabilitySetting != null
    SharingCapabilitySetting == ANYONE

    FileAnonymousLinkTypeSetting != null
    FolderAnonymousLinkTypeSetting != null
    Conditions := [
        FileAnonymousLinkTypeSetting == 1,
        FolderAnonymousLinkTypeSetting == 1
    ]
    Status := count(FilterArray(Conditions, true)) == 2
}

# Test for N/A case where sharing is set to New and existing guests, Existing guests, or Only people in your organization.
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails("MS.SHAREPOINT.3.2v1", Reason),
    "RequirementMet": true
} if {
    SharingCapabilitySetting != null
    SharingCapabilitySetting != ANYONE
    FileAnonymousLinkTypeSetting != null
    FolderAnonymousLinkTypeSetting != null
    Reason := NAString(SliderSettings(2), false)
}

# Test for settings not found in JSON
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "SPO_tenant or FileAnonymousLinkType or FolderAnonymousLinkType or SharingCapability are missing from input JSON",
    "RequirementMet": false
} if {
    MissingConditions := [
        count(SPOTenant) == 0,
        SharingCapabilitySetting == null,
        FileAnonymousLinkTypeSetting == null,
        FolderAnonymousLinkTypeSetting == null
    ]

    some condition in MissingConditions
    condition
}
#--


#
# MS.SHAREPOINT.3.3v2
#--

EmailAttestationRequiredSetting := object.get(SPOTenant, "EmailAttestationRequired", null)
EmailAttestationReAuthDaysSetting := object.get(SPOTenant, "EmailAttestationReAuthDays", null)

VERIFICATION_STRING := "Expiration time for 'People who use a verification code' NOT"

# This ruleset only checks if verification code reauthentication is enabled,
# and if the verification time is valid (less than or equal to 30 days)
VerificationCodeReAuthExpiration := [PASS, true] if {
    EmailAttestationRequiredSetting == true
    EmailAttestationReAuthDaysSetting <= 30
} else := [ErrStr, false] if {
    EmailAttestationRequiredSetting == false
    EmailAttestationReAuthDaysSetting <= 30
    ErrStr := concat(": ", [FAIL, concat(" ", [VERIFICATION_STRING, "enabled"])])
} else := [ErrStr, false] if {
    EmailAttestationRequiredSetting == true
    EmailAttestationReAuthDaysSetting > 30
    ErrStr := concat(": ", [FAIL, concat(" ", [VERIFICATION_STRING, "set to 30 days or less"])])
} else := [ErrStr, false] if {
    EmailAttestationRequiredSetting == false
    EmailAttestationReAuthDaysSetting > 30
    ErrStr := concat(": ", [FAIL, concat(" ", [VERIFICATION_STRING, "enabled and set to 30 days or more"])])
} else := [FAIL, false]

# This policy is only applicable if external sharing is set to "Anyone",
# "New and existing guests", or "Exisiting Guests"
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v2",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [
        SharingCapabilitySetting,
        EmailAttestationRequiredSetting,
        EmailAttestationReAuthDaysSetting
    ],
    "ReportDetails": ReportDetailsString(Status, ErrMsg),
    "RequirementMet": Status
} if {
    SharingCapabilitySetting != null
    SharingCapabilitySetting in [ANYONE, NEWANDEXISTINGGUESTS, EXISTINGGUESTS]

    EmailAttestationRequiredSetting != null
    EmailAttestationReAuthDaysSetting != null
    [ErrMsg, Status] := VerificationCodeReAuthExpiration
}

# Test for N/A case where sharing is set to Only people in your organization.
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v2",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": [],
    "ReportDetails": CheckedSkippedDetails("MS.SHAREPOINT.3.3v2", Reason),
    "RequirementMet": true
} if {
    SharingCapabilitySetting != null
    not SharingCapabilitySetting in [ANYONE, NEWANDEXISTINGGUESTS, EXISTINGGUESTS]

    EmailAttestationRequiredSetting != null
    EmailAttestationReAuthDaysSetting != null
    Reason := NAString(
        concat(" ", [
            SliderSettings(2), 
            "or", 
            SliderSettings(1),
            "or",
            SliderSettings(3)
        ]),
        false
    )
}

# Test for settings not found in JSON
tests contains {
    "PolicyId": "MS.SHAREPOINT.3.3v2",
    "Criticality": "Shall",
    "Commandlet": ["Get-SPOTenantRest"],
    "ActualValue": "Setting Not Found in JSON",
    "ReportDetails": "SPO_tenant or EmailAttestationRequired or EmailAttestationReAuthDays or SharingCapability are missing from input JSON",
    "RequirementMet": false
} if {
    MissingConditions := [
        count(SPOTenant) == 0,
        SharingCapabilitySetting == null,
        EmailAttestationRequiredSetting == null,
        EmailAttestationReAuthDaysSetting == null
    ]

    some condition in MissingConditions
    condition
}
#--
