package aad_test
import future.keywords
import data.aad
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# MS.AAD.6.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.6.1v1"

    Output := aad.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--