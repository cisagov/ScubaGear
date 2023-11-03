package defender_test
import future.keywords
import data.defender
import data.utils.report.ReportDetailsBoolean


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

FAIL := ReportDetailsBoolean(false)

PASS := ReportDetailsBoolean(true)


#
# Policy 1
#--
test_Spot_Correct if {
    Output := defender.tests with input as {
        "atp_policy_for_o365": [
            {
                "EnableATPForSPOTeamsODB": true,
                "Identity": "Default"
            }
        ],
        "defender_license": true
    }

    CorrectTestResult("MS.DEFENDER.3.1v1", Output, PASS) == true
}

test_Spot_Incorrect if {
    Output := defender.tests with input as {
        "atp_policy_for_o365": [
            {
                "EnableATPForSPOTeamsODB": false,
                "Identity": "Default"
            }
        ],
        "defender_license": true
    }

    IncorrectTestResult("MS.DEFENDER.3.1v1", Output, FAIL) == true
}
#--