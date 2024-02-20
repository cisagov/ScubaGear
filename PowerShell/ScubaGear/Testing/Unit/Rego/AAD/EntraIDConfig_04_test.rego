package entraid_test
import future.keywords
import data.entraid
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# Policy MS.ENTRAID.4.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.ENTRAID.4.1v1"

    Output := entraid.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--