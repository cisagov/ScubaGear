package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.SHAREPOINT.2.1v1
#--
test_DefaultSharingLinkType_Correct if {
    Output := sharepoint.tests with input.SPO_tenant as [SPOTenant]

    TestResult("MS.SHAREPOINT.2.1v1", Output, PASS, true) == true
}

test_DefaultSharingLinkType_Incorrect if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "DefaultSharingLinkType", "value": 2}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.2.1v1", Output, FAIL, false) == true
}

### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_DefaultSharingLinkType_SharepointSettings_Missing if {
    Output := sharepoint.tests with input as []

    MissingError := "SPO_tenant or DefaultSharingLinkType are missing from input JSON"
    TestResult("MS.SHAREPOINT.2.1v1", Output, MissingError, false) == true
}

test_DefaultSharingLinkType_SharepointSettings_EmptyArray if {
    Output := sharepoint.tests with input.SPO_tenant as []

    MissingError := "SPO_tenant or DefaultSharingLinkType are missing from input JSON"
    TestResult("MS.SHAREPOINT.2.1v1", Output, MissingError, false) == true
}

test_DefaultSharingLinkType_Missing if {
    Tenant := json.patch(SPOTenant, [{"op": "remove", "path": "DefaultSharingLinkType"}])
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    MissingError := "SPO_tenant or DefaultSharingLinkType are missing from input JSON"
    TestResult("MS.SHAREPOINT.2.1v1", Output, MissingError, false) == true
}
#--

#
# Policy MS.SHAREPOINT.2.2v1
#--
test_DefaultLinkPermission_Correct if {
    Output := sharepoint.tests with input.SPO_tenant as [SPOTenant]

    TestResult("MS.SHAREPOINT.2.2v1", Output, PASS, true) == true
}

test_DefaultLinkPermission_Incorrect if {
    Tenant := json.patch(SPOTenant, [{"op": "add", "path": "DefaultLinkPermission", "value": 2}])

    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    TestResult("MS.SHAREPOINT.2.2v1", Output, FAIL, false) == true
}

### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_DefaultLinkPermission_SharepointSettings_Missing if {
    Output := sharepoint.tests with input as []

    MissingError := "SPO_tenant or DefaultLinkPermission are missing from input JSON"
    TestResult("MS.SHAREPOINT.2.2v1", Output, MissingError, false) == true
}

test_DefaultLinkPermission_SharepointSettings_EmptyArray if {
    Output := sharepoint.tests with input.SPO_tenant as []

    MissingError := "SPO_tenant or DefaultLinkPermission are missing from input JSON"
    TestResult("MS.SHAREPOINT.2.2v1", Output, MissingError, false) == true
}

test_DefaultLinkPermission_Missing if {
    Tenant := json.patch(SPOTenant, [{"op": "remove", "path": "DefaultLinkPermission"}])
    Output := sharepoint.tests with input.SPO_tenant as [Tenant]

    MissingError := "SPO_tenant or DefaultLinkPermission are missing from input JSON"
    TestResult("MS.SHAREPOINT.2.2v1", Output, MissingError, false) == true
}
#--