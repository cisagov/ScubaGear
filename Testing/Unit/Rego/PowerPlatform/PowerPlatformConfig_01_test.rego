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
test_disableProductionEnvironmentCreationByNonAdminUsers_Correct if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disableEnvironmentCreationByNonAdminUsers": true
            }
        ]
    }

    CorrectTestResult("MS.POWERPLATFORM.1.1v1", Output, PASS) == true
}

test_disableProductionEnvironmentCreationByNonAdminUsers_Incorrect if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disableEnvironmentCreationByNonAdminUsers": false
            }
        ]
    }

    IncorrectTestResult("MS.POWERPLATFORM.1.1v1", Output, FAIL) == true
}
#--

#
# Policy 2
#--
test_disableTrialEnvironmentCreationByNonAdminUsers_Correct if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disableTrialEnvironmentCreationByNonAdminUsers": true
            }
        ]
    }

    CorrectTestResult("MS.POWERPLATFORM.1.2v1", Output, PASS) == true
}

test_disableTrialEnvironmentCreationByNonAdminUsers_Incorrect if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disableTrialEnvironmentCreationByNonAdminUsers": false
            }
        ]
    }

    IncorrectTestResult("MS.POWERPLATFORM.1.2v1", Output, FAIL) == true
}
#--