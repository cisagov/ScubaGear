package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.report.NotCheckedDeprecation
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
#--

#
# Policy MS.SHAREPOINT.1.2v1
#--
test_OneDriveSharingCapability_Correct_V1 if {
    Output := sharepoint.tests with input.SPO_tenant as [SPOTenant]
                                with input.OneDrive_PnP_Flag as false

    TestResult("MS.SHAREPOINT.1.2v1", Output, PASS, true) == true
}

test_OneDriveSharingCapability_Correct_V2 if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "OneDriveSharingCapability", "value": 3}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]
                                with input.OneDrive_PnP_Flag as false

    TestResult("MS.SHAREPOINT.1.2v1", Output, PASS, true) == true
}

test_UsingServicePrincipal if {
    PolicyId := "MS.SHAREPOINT.1.2v1"

    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "OneDriveSharingCapability", "value": 3}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]
                                with input.OneDrive_PnP_Flag as true

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}

test_OneDriveSharingCapability_Incorrect_V1 if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "OneDriveSharingCapability", "value": 1}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]
                                with input.OneDrive_PnP_Flag as false

    TestResult("MS.SHAREPOINT.1.2v1", Output, FAIL, false) == true
}

test_OneDriveSharingCapability_Incorrect_V2 if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "OneDriveSharingCapability", "value": 2}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]
                                with input.OneDrive_PnP_Flag as false

    TestResult("MS.SHAREPOINT.1.2v1", Output, FAIL, false) == true
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
        "on the admin page is not set to Only People In Your Organization.",
        "See %v for more info"
        ])
    TestResult(PolicyId, Output, CheckedSkippedDetails(PolicyId, ReportDetailsString), false) == true
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
#--

#
# Policy MS.SHAREPOINT.1.4v1
#--
test_RequireAcceptingAccountMatchInvitedAccount_NotImplemented_V1 if {
    PolicyId := "MS.SHAREPOINT.1.4v1"

    Output := sharepoint.tests with input.SPO_tenant as [SPOTenant]

    TestResult(PolicyId, Output, NotCheckedDeprecation, false) == true
}
#--