package aad_test
import future.keywords
import data.aad
import data.utils.report.NotCheckedDetails


IncorrectTestResult(PolicyId, Output, ReportDetailString) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false


#
# MS.AAD.6.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.6.1v1"

    Output := aad.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    IncorrectTestResult(PolicyId, Output, ReportDetailString) == true
}
#--