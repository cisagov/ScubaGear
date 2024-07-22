package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.report.CheckedSkippedDetails
import data.utils.key.TestResult
import data.utils.key.TODO


#
# Policy MS.SHAREPOINT.3.1v1
#--

# Sharepoint Rego Unit Test Challenge
#
# Policy logic: If external sharing is set to "Anyone" and Anonymous Links Expire in 30 or less days, the policy should pass.
#
# Level 1: Easy
#
# Code Note: Complete MS.SHAREPOINT.1.3v1 unit tests first
#
test_SharingCapability_Anyone_LinkExpirationValid_Correct_V1 if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.3.1v1", TODO, TODO, TODO) == true
}

test_SharingCapability_Anyone_LinkExpirationValid_Correct_V2 if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.3.1v1", TODO, TODO, TODO) == true
}

test_SharingCapability_Anyone_LinkExpirationInvalid_Incorrect if {
    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult("MS.SHAREPOINT.3.1v1", TODO, ReportDetailsString, TODO) == true
}

# Test if the Sharepoint external sharing slider is set to "Only People In Org".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_OnlyPeopleInOrg_NotApplicable_V1 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}

# Test if the Sharepoint external sharing slider is set to "Existing guests".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_ExistingGuests_NotApplicable_V1 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}

# Test if the Sharepoint external sharing slider is set to "New and existing guests".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_NewExistingGuests_NotApplicable_V1 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}

# Test if the Sharepoint external sharing slider is set to "Only people in your organization".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_OnlyPeopleInOrg_NotApplicable_V2 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}

# Test if the Sharepoint external sharing slider is set to "Existing guests".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_ExistingGuests_NotApplicable_V2 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}

# Test if the Sharepoint external sharing slider is set to "New and existing guests".
# The result must be N/A because the policy is not applicable unless external sharing is set to "Anyone".
test_SharingCapability_NewExistingGuests_NotApplicable_V2 if {
    PolicyId := "MS.SHAREPOINT.3.1v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}
#--

#
# Policy MS.SHAREPOINT.3.2v1
#--

# Sharepoint Rego Unit Test Challenge
#
# Policy logic: If external sharing is set to "Anyone", OneDrive_PnP_Flag is not set, and File And Folder Link Permission is set to view,
# the policy should pass.
# FileLinkType == 1 view
# FolderLinkType == 1 view
#
# Level 1: Easy
#
# Code Note: Complete MS.SHAREPOINT.1.3v1 unit tests first
#
test_File_Folder_AnonymousLinkType_Correct if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.3.2v1", TODO, TODO, TODO) == true
}

test_File_Folder_AnonymousLinkType_Incorrect if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := ""
    TestResult("MS.SHAREPOINT.3.2v1", TODO, ReportDetailString, TODO) == true
}

test_Folder_AnonymousLinkType_Incorrect if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := ""
    TestResult("MS.SHAREPOINT.3.2v1", TODO, ReportDetailString, TODO) == true
}

test_File_AnonymousLinkType_Incorrect if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := ""
    TestResult("MS.SHAREPOINT.3.2v1", TODO, ReportDetailString, TODO) == true
}

test_AnonymousLinkType_UsingServicePrincipal if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := sharepoint.tests with input as {}

    TestResult(PolicyId, TODO, NotCheckedDetails(PolicyId), TODO) == true
}

test_File_Folder_AnonymousLinkType_SharingCapability_OnlyPeopleInOrg_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}

test_File_Folder_AnonymousLinkType_SharingCapability_ExistingGuests_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}

test_File_Folder_AnonymousLinkType_SharingCapability_NewExistingGuests_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.2v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}

#
# Policy MS.SHAREPOINT.3.3v1
#--

# Sharepoint Rego Unit Test Challenge
#
# Policy logic: This policy is only applicable if external sharing is set to "Anyone", or "New and existing guests". If verification code
# reauthentication is enabled, and if the verification time is valid (less than or equal to 30 days), the policy should pass.
#
# Level 1: Easy
#
# Code Note: Complete MS.SHAREPOINT.1.3v1 unit tests first
#
test_EmailAttestationReAuthDays_SharingCapability_NewExistingGuests_Correct if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.3.3v1", TODO, TODO, TODO) == true
}

test_EmailAttestationReAuthDays_SharingCapability_Anyone_Correct if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.3.3v1", TODO, TODO, TODO) == true
}

test_EmailAttestationReAuthDays_Correct if {
    Output := sharepoint.tests with input as {}

    TestResult("MS.SHAREPOINT.3.3v1", TODO, TODO, TODO) == true
}

test_EmailAttestationReAuthDays_Incorrect_V1 if {
    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult("MS.SHAREPOINT.3.3v1", TODO, ReportDetailsString, TODO) == true
}

test_EmailAttestationReAuthDays_Incorrect_V2 if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := ""
    TestResult("MS.SHAREPOINT.3.3v1", TODO, ReportDetailString, TODO) == true
}

test_EmailAttestationRequired_Incorrect if {
    Output := sharepoint.tests with input as {}

    ReportDetailString := ""
    TestResult("MS.SHAREPOINT.3.3v1", TODO, ReportDetailString, TODO) == true
}

test_EmailAttestationReAuthDays_SharingCapability_OnlyPeopleInOrg_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}

test_EmailAttestationReAuthDays_SharingCapability_ExistingGuests_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.3.3v1"

    Output := sharepoint.tests with input as {}

    ReportDetailsString := ""
    TestResult(PolicyId, TODO, CheckedSkippedDetails(PolicyId, ReportDetailsString), TODO) == true
}
#--