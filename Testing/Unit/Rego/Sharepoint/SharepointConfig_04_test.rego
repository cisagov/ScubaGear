package sharepoint_test
import future.keywords
import data.sharepoint
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
# MS.SHAREPOINT.4.1v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.SHAREPOINT.4.1v1"

    Output := sharepoint.tests with input as { }

    IncorrectTestResult(PolicyId, Output, NotCheckedDetails(PolicyId)) == true
}
#--

#
# MS.SHAREPOINT.4.2v1
#--
test_DenyAddAndCustomizePages_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages": 2
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.4.2v1", Output, PASS) == true
}

test_DenyAddAndCustomizePages_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_site": [
            {
                "DenyAddAndCustomizePages": 1
            }
        ]
    }

    IncorrectTestResult("MS.SHAREPOINT.4.2v1", Output, FAIL) == true
}
#--