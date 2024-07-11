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
#--