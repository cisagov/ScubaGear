package powerplatform_test
import future.keywords
import data.powerplatform
import data.report.utils.ReportDetailsBoolean
import data.report.utils.NotCheckedDetails


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
test_isDisabled_Correct if {
    Output := powerplatform.tests with input as {
        "tenant_isolation": [
            {
                "properties": {
                    "isDisabled": false
                }
            }
        ]
    }

    CorrectTestResult("MS.POWERPLATFORM.3.1v1", Output, PASS) == true
}

test_isDisabled_Incorrect if {
    Output := powerplatform.tests with input as {
        "tenant_isolation": [
            {
                "properties": {
                    "isDisabled": true
                }
            }
        ]
    }

    IncorrectTestResult("MS.POWERPLATFORM.3.1v1", Output, FAIL) == true
}
#--

#
# Policy 2
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.POWERPLATFORM.3.2v1"

    Output := powerplatform.tests with input as { }

    IncorrectTestResult(PolicyId, Output, NotCheckedDetails(PolicyId)) == true
}
#--