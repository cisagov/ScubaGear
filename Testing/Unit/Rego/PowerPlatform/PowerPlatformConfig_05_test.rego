package powerplatform_test
import future.keywords
import data.powerplatform
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
test_disablePortalCreationByNonAdminUsers_Correct if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disablePortalsCreationByNonAdminUsers": true
            }
        ]
    }

    CorrectTestResult("MS.POWERPLATFORM.5.1v1", Output, PASS) == true
}

test_disablePortalCreationByNonAdminUsers_Incorrect if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disablePortalsCreationByNonAdminUsers": false
            }
        ]
    }

    IncorrectTestResult("MS.POWERPLATFORM.5.1v1", Output, FAIL) == true
}
#--