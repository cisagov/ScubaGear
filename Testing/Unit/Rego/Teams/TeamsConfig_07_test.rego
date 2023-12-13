package teams_test
import future.keywords
import data.teams
import data.utils.report.DefenderMirrorDetails
import data.utils.policy.IncorrectTestResult


#
# Policy MS.TEAMS.7.1v1
#--
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.TEAMS.7.1v1"

    Output := teams.tests with input as { }

    IncorrectTestResult(PolicyId, Output, DefenderMirrorDetails(PolicyId)) == true
}
#--

#
# Policy MS.TEAMS.7.2v1
#--
test_3rdParty_Correct_V2 if {
    PolicyId := "MS.TEAMS.7.2v1"

    Output := teams.tests with input as { }

    IncorrectTestResult(PolicyId, Output, DefenderMirrorDetails(PolicyId)) == true
}
#--