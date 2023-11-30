package powerplatform_test
import future.keywords
import data.powerplatform
import data.report.utils.NotCheckedDetails


#
# Policy 1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.POWERPLATFORM.4.1v1"

    Output := powerplatform.tests with input as { }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--