package powerplatform_test
import rego.v1
import data.powerplatform
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# Policy MS.POWERPLATFORM.4.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.POWERPLATFORM.4.1v1"

    Output := powerplatform.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--