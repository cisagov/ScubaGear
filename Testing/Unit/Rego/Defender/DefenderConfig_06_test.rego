package defender_test
import future.keywords
import data.defender
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
test_AdminAuditLogEnabled_Correct if {
    Output := defender.tests with input as {
        "admin_audit_log_config": [
            {
                "Identity": "Admin Audit Log Settings",
                "UnifiedAuditLogIngestionEnabled": true
            }
        ]
    }

    CorrectTestResult("MS.DEFENDER.6.1v1", Output, PASS) == true
}

test_AdminAuditLogEnabled_Incorrect if {
    Output := defender.tests with input as {
        "admin_audit_log_config": [
            {
                "Identity": "Admin Audit Log Settings",
                "UnifiedAuditLogIngestionEnabled": false
            }
        ]
    }

    IncorrectTestResult("MS.DEFENDER.6.1v1", Output, FAIL) == true
}

#
# Policy 2
#--
test_NotImplemented_Correct_V1 if {
    PolicyId := "MS.DEFENDER.6.2v1"

    Output := defender.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    IncorrectTestResult(PolicyId, Output, ReportDetailString) == true
}

#
# Policy 3
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.DEFENDER.6.3v1"

    Output := defender.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    IncorrectTestResult(PolicyId, Output, ReportDetailString) == true
}
#--