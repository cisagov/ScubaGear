package exo_test
import future.keywords
import data.exo
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
test_SmtpClientAuthenticationDisabled_Correct if {
    Output := exo.tests with input as {
        "transport_config": [
            {
                "SmtpClientAuthenticationDisabled": true,
                "Name": "A"
            }
        ]
    }

    CorrectTestResult("MS.EXO.5.1v1", Output, PASS) == true
}

test_SmtpClientAuthenticationDisabled_Incorrect if {
    Output := exo.tests with input as {
        "transport_config": [
            {
                "SmtpClientAuthenticationDisabled": false,
                "Name": "A"
            }
        ]
    }

    IncorrectTestResult("MS.EXO.5.1v1", Output, FAIL) == true
}
#--