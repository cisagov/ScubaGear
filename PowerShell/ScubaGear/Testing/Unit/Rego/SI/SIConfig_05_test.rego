package si_test
import rego.v1
import data.si
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# Policy MS.SI.5.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.SI.5.1v1"

    Output := si.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--
