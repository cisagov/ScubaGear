package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.report.CheckedSkippedDetails
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.SHAREPOINT.1.1v1
#--
test_SharingCapability_Correct_V1 if {
    Output := sharepoint.tests with input.SPO_tenant as [SPOTenant]

    TestResult("MS.SHAREPOINT.1.1v1", Output, PASS, true) == true
}

test_SharingCapability_Correct_V2 if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "SharingCapability", "value": 3}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.1.1v1", Output, PASS, true) == true
}

test_SharingCapability_Incorrect_V1 if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "SharingCapability", "value": 1}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.1.1v1", Output, FAIL, false) == true
}

test_SharingCapability_Incorrect_V2 if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "SharingCapability", "value": 2}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.1.1v1", Output, FAIL, false) == true
}

### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_SharingCapability_SharepointSettings_Missing if {
    Output := sharepoint.tests with input as []

    MissingError := "SPO_tenant or SharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.1v1", Output, MissingError, false) == true
}

test_SharingCapability_SharepointSettings_EmptyArray if {
    Output := sharepoint.tests with input.SPO_tenant as []

    MissingError := "SPO_tenant or SharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.1v1", Output, MissingError, false) == true
}

test_SharingCapability_Missing if {
    Tenant := json.patch(SPOTenant, [{"op": "remove", "path": "SharingCapability"}])
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    MissingError := "SPO_tenant or SharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.1v1", Output, MissingError, false) == true
}

### Delete below this
# test_SharingCapability_Empty if {
#     # Tenant := json.patch(SPOTenant, [{"op": "add", "path": "SharingCapability", "value": 2}])
# SPOTenant := {
#     "SharingCapability": 0,
#     "ODBSharingCapability": 0,
#     "SharingDomainRestrictionMode": 0,
#     "DefaultSharingLinkType": 1,
#     "DefaultLinkPermission": 1,
#     "RequireAnonymousLinksExpireInDays": 30,
#     "FileAnonymousLinkType": 1,
#     "FolderAnonymousLinkType": 1,
#     "EmailAttestationRequired": true,
#     "EmailAttestationReAuthDays": 30
# }

#     Output := sharepoint.tests with input.SPO_tenant as [SPOTenant]
#     # Output := sharepoint.tests with input.SPO_tenant as []

#     # count(Output) == 1
# # sprintf("DEBUG test_SharingCapability_Empty Output: %v", [Output])
# print("DEBUG test_SharingCapability_Empty Output: ", [Output])

#     TestResult("MS.SHAREPOINT.1.1v1", Output, FAIL, false) == true
# }
#--

#
# Policy MS.SHAREPOINT.1.2v1
#--
test_ODBSharingCapability_Correct_V1 if {
    Output := sharepoint.tests with input.SPO_tenant as [SPOTenant]

    TestResult("MS.SHAREPOINT.1.2v1", Output, PASS, true) == true
}

test_ODBSharingCapability_Correct_V2 if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "ODBSharingCapability", "value": 3}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.1.2v1", Output, PASS, true) == true
}

test_ODBSharingCapability_Incorrect_V1 if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "ODBSharingCapability", "value": 1}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.1.2v1", Output, FAIL, false) == true
}

test_ODBSharingCapability_Incorrect_V2 if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "ODBSharingCapability", "value": 2}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.1.2v1", Output, FAIL, false) == true
}

### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_ODBSharingCapability_SharepointSettings_Missing if {
    Output := sharepoint.tests with input as []

    MissingError := "SPO_tenant or ODBSharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.2v1", Output, MissingError, false) == true
}

test_ODBSharingCapability_SharepointSettings_EmptyArray if {
    Output := sharepoint.tests with input.SPO_tenant as []

    MissingError := "SPO_tenant or ODBSharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.2v1", Output, MissingError, false) == true
}

test_ODBSharingCapability_Missing if {
    Tenant := json.patch(SPOTenant, [{"op": "remove", "path": "ODBSharingCapability"}])
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    MissingError := "SPO_tenant or ODBSharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.2v1", Output, MissingError, false) == true
}
#--

#
# Policy MS.SHAREPOINT.1.3v1
#--
test_SharingDomainRestrictionMode_SharingCapability_OnlyPeopleInOrg_NotApplicable if {
    PolicyId := "MS.SHAREPOINT.1.3v1"

    Output := sharepoint.tests with input.SPO_tenant as [SPOTenant]

    ReportDetailsString := concat(" ", [
        "This policy is only applicable if the external sharing slider",
        "in the SharePoint admin center is not set to Only People In Your Organization.",
        "See %v for more info"
        ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), true) == true
}

test_SharingDomainRestrictionMode_SharingCapability_Anyone_Correct if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 2},
                {"op": "add", "path": "SharingDomainRestrictionMode", "value": 1}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailString := concat(" ", [
        "Requirement met: Note that we currently only check for approved external domains.",
        "Approved security groups are currently not being checked,",
        "see the baseline policy for instructions on a manual check."
    ])
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, true) == true
}

test_SharingDomainRestrictionMode_SharingCapability_NewExistingGuests_Correct if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 1},
                {"op": "add", "path": "SharingDomainRestrictionMode", "value": 1}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailString := concat(" ", [
        "Requirement met: Note that we currently only check for approved external domains.",
        "Approved security groups are currently not being checked,",
        "see the baseline policy for instructions on a manual check."
    ])
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, true) == true
}

test_SharingDomainRestrictionMode_SharingCapability_ExistingGuests_Correct if {
    Tenant := json.patch(SPOTenant,
                [{"op": "add", "path": "SharingCapability", "value": 3},
                {"op": "add", "path": "SharingDomainRestrictionMode", "value": 1}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailString := concat(" ", [
        "Requirement met: Note that we currently only check for approved external domains.",
        "Approved security groups are currently not being checked,",
        "see the baseline policy for instructions on a manual check."
    ])
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, true) == true
}

test_SharingDomainRestrictionMode_SharingCapability_NewExistingGuests_Incorrect if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "SharingCapability", "value": 1}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailString := concat(" ", [
        "Requirement not met: Note that we currently only check for approved external domains.",
        "Approved security groups are currently not being checked,",
        "see the baseline policy for instructions on a manual check."
    ])
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, false) == true
}

test_SharingDomainRestrictionMode_SharingCapability_ExistingGuests_Incorrect if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "SharingCapability", "value": 3}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailString := concat(" ", [
        "Requirement not met: Note that we currently only check for approved external domains.",
        "Approved security groups are currently not being checked,",
        "see the baseline policy for instructions on a manual check."
    ])
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, false) == true
}

test_SharingDomainRestrictionMode_SharingCapability_Anyone_Incorrect if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "SharingCapability", "value": 2}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    ReportDetailString := concat(" ", [
        "Requirement not met: Note that we currently only check for approved external domains.",
        "Approved security groups are currently not being checked,",
        "see the baseline policy for instructions on a manual check."
    ])
    TestResult("MS.SHAREPOINT.1.3v1", Output, ReportDetailString, false) == true
}

### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_SharingDomainRestrictionMode_SharepointSettings_Missing if {
    Output := sharepoint.tests with input as []

    MissingError := "SPO_tenant or SharingDomainRestrictionMode or SharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.3v1", Output, MissingError, false) == true
}

test_SharingDomainRestrictionMode_SharepointSettings_EmptyArray if {
    Output := sharepoint.tests with input.SPO_tenant as []

    MissingError := "SPO_tenant or SharingDomainRestrictionMode or SharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.3v1", Output, MissingError, false) == true
}

test_SharingDomainRestrictionMode_Missing if {
    Tenant := json.patch(SPOTenant, [{"op": "remove", "path": "SharingDomainRestrictionMode"}])
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    MissingError := "SPO_tenant or SharingDomainRestrictionMode or SharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.3v1", Output, MissingError, false) == true
}

test_SharingDomainRestrictionMode_SharingCapability_Missing if {
    Tenant := json.patch(SPOTenant, [{"op": "remove", "path": "SharingCapability"}])
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    MissingError := "SPO_tenant or SharingDomainRestrictionMode or SharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.3v1", Output, MissingError, false) == true
}

test_SharingDomainRestrictionMode_Both_Missing if {
    Tenant := json.patch(SPOTenant, [{"op": "remove", "path": "SharingDomainRestrictionMode"},
                                    {"op": "remove", "path": "SharingCapability"}])
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    MissingError := "SPO_tenant or SharingDomainRestrictionMode or SharingCapability are missing from input JSON"
    TestResult("MS.SHAREPOINT.1.3v1", Output, MissingError, false) == true
}
#--
