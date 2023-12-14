package powerplatform_test
import future.keywords
import data.powerplatform
import data.utils.report.NotCheckedDetails
import data.utils.policy.TestResult


#
# Policy 1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.POWERPLATFORM.4.1v1"

    Output := powerplatform.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--