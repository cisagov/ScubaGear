package teams_test
import future.keywords
import data.teams
import data.utils.report.DefenderMirrorDetails


CorrectTestResult(PolicyId, Output, ReportDetailString) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == true
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false

IncorrectTestResult(PolicyId, Output, ReportDetailString) := true if {
    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == ReportDetailString
} else := false

#
# Policy MS.TEAMS.8.1v1
#--
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.TEAMS.8.1v1"

    Output := teams.tests with input as { }

    IncorrectTestResult(PolicyId, Output, DefenderMirrorDetails(PolicyId)) == true
}
#--

#
# Policy MS.TEAMS.8.2v1
#--
test_3rdParty_Correct_V2 if {
    PolicyId := "MS.TEAMS.8.2v1"

    Output := teams.tests with input as { }

    IncorrectTestResult(PolicyId, Output, DefenderMirrorDetails(PolicyId)) == true
}
#--