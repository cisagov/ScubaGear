package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.CheckedSkippedDetails
import data.utils.key.TestResult
import data.utils.key.PASS
import data.utils.key.FAIL


#
# Policy MS.SHAREPOINT.3.1v1
#--
test_SharingCapability_Anyone_LinkExpirationValid_Correct_V1 if {
    Tenant := json.patch(SPOTenant, 
                [{"op": "add", "path": "SharingCapability", "value": 2},
                {"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 30}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.3.1v1", Output, PASS, true) == true
}

test_SharingCapability_Anyone_LinkExpirationValid_Correct_V2 if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 2},
                {"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 29}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.3.1v1", Output, PASS, true) == true
}

test_SharingCapability_Anyone_LinkExpirationInvalid_Incorrect_V1 if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 2},
                {"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 31}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "Requirement not met:",
        "total expiration days are not set to 30 days or less"
    ])
    TestResult("MS.SHAREPOINT.3.1v1", Output, ReportDetailsString, false) == true
}

test_SharingCapability_Anyone_LinkExpirationInvalid_Incorrect_V2 if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 2},
                {"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": -1}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "Requirement not met:",
        "total expiration days are not set to 30 days or less"
    ])
    TestResult("MS.SHAREPOINT.3.1v1", Output, ReportDetailsString, false) == true
}

test_SharingCapability_Anyone_LinkExpirationInvalid_Incorrect_V3 if {
    # If "RequireAnonymousLinksExpireInDays" == 0, Anyone links is unchecked,
    # the policy must indicate a fail for this case.
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 2},
                {"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 0}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "Requirement not met:",
        "total expiration days are not set to 30 days or less"
    ])
    TestResult("MS.SHAREPOINT.3.1v1", Output, ReportDetailsString, false) == true
}

# Test if the Sharepoint external sharing slider is set to "Only people in your organization".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_OnlyPeopleInOrg_NotApplicable_V1 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 31}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "on the admin page is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

# Test if the Sharepoint external sharing slider is set to "Existing guests".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_ExistingGuests_NotApplicable_V1 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 3},
                {"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 31}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "on the admin page is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

# Test if the Sharepoint external sharing slider is set to "New and existing guests".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_NewExistingGuests_NotApplicable_V1 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 1},
                {"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 31}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "on the admin page is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

# Test if the Sharepoint external sharing slider is set to "Only people in your organization".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_OnlyPeopleInOrg_NotApplicable_V2 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 29}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "on the admin page is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

# Test if the Sharepoint external sharing slider is set to "Existing guests".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_ExistingGuests_NotApplicable_V2 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 3},
                {"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 29}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "on the admin page is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

# Test if the Sharepoint external sharing slider is set to "New and existing guests".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_NewExistingGuests_NotApplicable_V2 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 1},
                {"op": "add", "path": "RequireAnonymousLinksExpireInDays", "value": 29}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "on the admin page is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}
#--

#
# Policy MS.SHAREPOINT.3.2v1
#--
test_File_Folder_AnonymousLinkType_Correct if {
    Tenant := json.patch(SPOTenant, [
        {"op": "add", "path": "SharingCapability", "value": 2},
        {"op": "add", "path": "FileAnonymousLinkType", "value": 1},
        {"op": "add", "path": "FolderAnonymousLinkType", "value": 1}
    ])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.3.2v1", Output, PASS, true) == true
}

test_File_Folder_AnonymousLinkType_Incorrect if {
    Tenant := json.patch(SPOTenant, [
        {"op": "add", "path": "SharingCapability", "value": 2},
        {"op": "add", "path": "FileAnonymousLinkType", "value": 2},
        {"op": "add", "path": "FolderAnonymousLinkType", "value": 2}
    ])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := "Requirement not met: both files and folders are not limited to view for Anyone"
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailsString, false) == true
}

test_Folder_AnonymousLinkType_Incorrect if {
    Tenant := json.patch(SPOTenant, [
        {"op": "add", "path": "SharingCapability", "value": 2},
        {"op": "add", "path": "FileAnonymousLinkType", "value": 1},
        {"op": "add", "path": "FolderAnonymousLinkType", "value": 2}
    ])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := "Requirement not met: folders are not limited to view for Anyone"
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailsString, false) == true
}

test_File_AnonymousLinkType_Incorrect if {
    Tenant := json.patch(SPOTenant, [
        {"op": "add", "path": "SharingCapability", "value": 2},
        {"op": "add", "path": "FileAnonymousLinkType", "value": 2},
        {"op": "add", "path": "FolderAnonymousLinkType", "value": 1}
    ])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := "Requirement not met: files are not limited to view for Anyone"
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailsString, false) == true
}

test_File_Folder_AnonymousLinkType_UsingServicePrincipal_Correct if {
    # SharingCapability value of 2 equals "Anyone"
    # FileAnonymousLinkType value of 1 equals "View"
    # FolderAnonymousLinkType value of 1 equals "View"
    Tenant := json.patch(SPOTenant, [
        {"op": "add", "path": "SharingCapability", "value": 2},
        {"op": "add", "path": "FileAnonymousLinkType", "value": 1},
        {"op": "add", "path": "FolderAnonymousLinkType", "value": 1}
    ])

    # Set PnP flag to true denoting use of service principal
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]
        with input.OneDrive_PnP_Flag as true
    TestResult("MS.SHAREPOINT.3.2v1", Output, PASS, true) == true
}

test_File_Folder_AnonymousLinkType_UsingServicePrincipal_Incorrect if {
    # SharingCapability value of 2 equals "Anyone"
    # FileAnonymousLinkType value of 2 equals "Edit"
    # FolderAnonymousLinkType value of 2 equals "Edit"
    Tenant := json.patch(SPOTenant, [
        {"op": "add", "path": "SharingCapability", "value": 2},
        {"op": "add", "path": "FileAnonymousLinkType", "value": 2},
        {"op": "add", "path": "FolderAnonymousLinkType", "value": 2}
    ])
    
    # Set PnP flag to true denoting use of service principal 
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]
        with input.OneDrive_PnP_Flag as true

    ReportDetailsString := concat(": ", [
        FAIL,
        "both files and folders are not limited to view for Anyone"
    ])
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailsString, false) == true
}

test_File_AnonymousLinkType_UsingServicePrincipal_Incorrect if {
    # SharingCapability value of 2 equals "Anyone"
    # FileAnonymousLinkType value of 2 equals "Edit"
    # FolderAnonymousLinkType value of 1 equals "View"
    Tenant := json.patch(SPOTenant, [
        {"op": "add", "path": "SharingCapability", "value": 2},
        {"op": "add", "path": "FileAnonymousLinkType", "value": 2},
        {"op": "add", "path": "FolderAnonymousLinkType", "value": 1}
    ])
    
    # Set PnP flag to true denoting use of service principal
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]
        with input.OneDrive_PnP_Flag as true

    # FAIL = Requirement not met
    # ReportDetailsString = "Requirement not met: both files and folders are not limited to view for Anyone"
    ReportDetailsString := concat(": ", [
        FAIL,
        "files are not limited to view for Anyone"
    ])
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailsString, false) == true
}

test_Folder_AnonymousLinkType_UsingServicePrincipal_Incorrect if {
    # SharingCapability value of 2 equals "Anyone"
    # FileAnonymousLinkType value of 1 equals "View"
    # FolderAnonymousLinkType value of 2 equals "Edit"
    Tenant := json.patch(SPOTenant, [
        {"op": "add", "path": "SharingCapability", "value": 2},
        {"op": "add", "path": "FileAnonymousLinkType", "value": 1},
        {"op": "add", "path": "FolderAnonymousLinkType", "value": 2}
    ])
    
    # Set PnP flag to true denoting use of service principal
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]
        with input.OneDrive_PnP_Flag as true

    ReportDetailsString := concat(": ", [
        FAIL,
        "folders are not limited to view for Anyone"
    ])
    TestResult("MS.SHAREPOINT.3.2v1", Output, ReportDetailsString, false) == true
}

test_File_Folder_AnonymousLinkType_SharingCapability_OnlyPeopleInOrg_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Tenant := json.patch(SPOTenant, [
        {"op": "add", "path": "FileAnonymousLinkType", "value": 2},
        {"op": "add", "path": "FolderAnonymousLinkType", "value": 2}
    ])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "on the admin page is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_File_Folder_AnonymousLinkType_SharingCapability_ExistingGuests_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 3},
                {"op": "add", "path": "FileAnonymousLinkType", "value": 2},
                {"op": "add", "path": "FolderAnonymousLinkType", "value": 2}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "on the admin page is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_File_Folder_AnonymousLinkType_SharingCapability_NewExistingGuests_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 1},
                {"op": "add", "path": "FileAnonymousLinkType", "value": 2},
                {"op": "add", "path": "FolderAnonymousLinkType", "value": 2}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "on the admin page is set to Anyone. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

#
# Policy MS.SHAREPOINT.3.3v1
#--
test_EmailAttestationReAuthDays_SharingCapability_NewExistingGuests_Correct if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "SharingCapability", "value": 1}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.3.3v1", Output, PASS, true) == true
}

test_EmailAttestationReAuthDays_SharingCapability_Anyone_Correct if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "SharingCapability", "value": 2}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.3.3v1", Output, PASS, true) == true
}

test_EmailAttestationReAuthDays_Correct if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 1},
                {"op": "add", "path": "EmailAttestationReAuthDays", "value": 29}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.3.3v1", Output, PASS, true) == true
}

test_EmailAttestationReAuthDays_Incorrect_V1 if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 1},
                {"op": "add", "path": "EmailAttestationRequired", "value": false},
                {"op": "add", "path": "EmailAttestationReAuthDays", "value": 31}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString :=
        "Requirement not met: Expiration time for 'People who use a verification code' NOT enabled and set to 30 days or more"
    TestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailsString, false) == true
}

test_EmailAttestationReAuthDays_Incorrect_V2 if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 1},
                {"op": "add", "path": "EmailAttestationReAuthDays", "value": 31}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString :=
        "Requirement not met: Expiration time for 'People who use a verification code' NOT set to 30 days or less"
    TestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailsString, false) == true
}

test_EmailAttestationRequired_Incorrect if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 1},
                {"op": "add", "path": "EmailAttestationRequired", "value": false},
                {"op": "add", "path": "EmailAttestationReAuthDays", "value": 29}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := "Requirement not met: Expiration time for 'People who use a verification code' NOT enabled"
    TestResult("MS.SHAREPOINT.3.3v1", Output, ReportDetailsString, false) == true
}

test_EmailAttestationReAuthDays_SharingCapability_OnlyPeopleInOrg_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 0},
                {"op": "add", "path": "EmailAttestationReAuthDays", "value": 29}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider on the admin page",
        "is set to Anyone or New and Existing Guests. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}

test_EmailAttestationReAuthDays_SharingCapability_ExistingGuests_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 3},
                {"op": "add", "path": "EmailAttestationReAuthDays", "value": 29}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider on the admin page",
        "is set to Anyone or New and Existing Guests. See %v for more info"
    ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
}
#--