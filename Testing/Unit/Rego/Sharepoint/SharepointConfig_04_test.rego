package sharepoint_test
import future.keywords
import data.sharepoint
import data.utils.report.NotCheckedDetails
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# MS.SHAREPOINT.4.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.SHAREPOINT.4.1v1"

    Output := sharepoint.tests with input as { }

    IncorrectTestResult(PolicyId, Output, NotCheckedDetails(PolicyId)) == true
}
#--

#
# MS.SHAREPOINT.4.2v1
#--
test_DenyAddAndCustomizePages_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages": 2
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.4.2v1", Output, PASS) == true
}

test_DenyAddAndCustomizePages_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages": 1
            }
        ]
    }

    IncorrectTestResult("MS.SHAREPOINT.4.2v1", Output, FAIL) == true
}
#--