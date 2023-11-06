package sharepoint_test
import future.keywords
import data.sharepoint
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
# MS.SHAREPOINT.2.1v1
#--
test_DefaultSharingLinkType_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultSharingLinkType": 1
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.2.1v1", Output, PASS) == true
}

test_DefaultSharingLinkType_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultSharingLinkType": 2
            }
        ]
    }

    IncorrectTestResult("MS.SHAREPOINT.2.1v1", Output, FAIL) == true
}
#--

#
# MS.SHAREPOINT.2.2v1
#--
test_DefaultLinkPermission_Correct if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultLinkPermission": 1
            }
        ]
    }

    CorrectTestResult("MS.SHAREPOINT.2.2v1", Output, PASS) == true
}

test_DefaultLinkPermission_Incorrect if {
    Output := sharepoint.tests with input as {
        "SPO_tenant": [
            {
                "DefaultLinkPermission": 2
            }
        ]
    }

    IncorrectTestResult("MS.SHAREPOINT.2.2v1", Output, FAIL) == true
}
#--