package exo_test
import future.keywords
import data.exo
import data.report.utils.DefenderMirrorDetails


#
# Policy 1
#--
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.EXO.17.1v1"

    Output := exo.tests with input as { }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == DefenderMirrorDetails(PolicyId)
}
#--

#
# Policy 2
#--
test_3rdParty_Correct_V2 if {
    PolicyId := "MS.EXO.17.2v1"

    Output := exo.tests with input as { }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == DefenderMirrorDetails(PolicyId)
}
#--

#
# Policy 3
#--
test_3rdParty_Correct_V3 if {
    PolicyId := "MS.EXO.17.3v1"

    Output := exo.tests with input as { }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == DefenderMirrorDetails(PolicyId)
}
#--