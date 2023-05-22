package aad
import future.keywords
import data.report.utils.NotCheckedDetails

#--
test_NotImplemented_Correct_V1 if {
    PolicyId := "MS.AAD.5.1v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}

#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.AAD.5.4v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}