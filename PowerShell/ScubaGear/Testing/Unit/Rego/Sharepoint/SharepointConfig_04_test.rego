package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS



#
# Policy MS.SHAREPOINT.4.2v1
#--
test_DenyAddAndCustomizePages_Correct if {
    Output := sharepoint.tests with input.SPO_site as [SPOSite]

    TestResult("MS.SHAREPOINT.4.2v1", Output, PASS, true) == true
}

test_DenyAddAndCustomizePages_Incorrect if {
    Site := json.patch(SPOSite, [{"op": "add", "path": "DenyAddAndCustomizePages", "value": 1}])

    Output := sharepoint.tests with input.SPO_site as [Site]

    TestResult("MS.SHAREPOINT.4.2v1", Output, FAIL, false) == true
}
#--
