package exo
import future.keywords
import data.report.utils.DefenderMirrorDetails

#
# Policy 1
#--
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.EXO.15.1v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == DefenderMirrorDetails(PolicyId)
}

#
# Policy 2
#--
test_3rdParty_Correct_V2 if {
    PolicyId := "MS.EXO.15.2v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == DefenderMirrorDetails(PolicyId)
}

#
# Policy 3
#--
test_3rdParty_Correct_V3 if {
    PolicyId := "MS.EXO.15.3v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == DefenderMirrorDetails(PolicyId)
}