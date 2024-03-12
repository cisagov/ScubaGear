package aad_test
import rego.v1
import data.aad
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# Policy MS.AAD.4.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.4.1v1"

    Output := aad.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--