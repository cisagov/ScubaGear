package sharepoint_test
import rego.v1
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.SHAREPOINT.4.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.SHAREPOINT.4.1v1"

    Output := sharepoint.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--

#
# Policy MS.SHAREPOINT.4.2v1
#--
test_DenyAddAndCustomizePages_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages": 2
            }
        ]
    }

    TestResult("MS.SHAREPOINT.4.2v1", Output, PASS, true) == true
}

test_DenyAddAndCustomizePages_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages": 1
            }
        ]
    }

    TestResult("MS.SHAREPOINT.4.2v1", Output, FAIL, false) == true
}
#--