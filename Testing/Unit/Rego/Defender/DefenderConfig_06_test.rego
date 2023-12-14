package defender_test
import future.keywords
import data.defender
import data.utils.report.NotCheckedDetails
import data.utils.policy.TestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


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

    TestResult("MS.DEFENDER.6.1v1", Output, PASS, true) == true
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

    TestResult("MS.DEFENDER.6.1v1", Output, FAIL, false) == true
}
#--

#
# Policy 2
#--
test_NotImplemented_Correct_V1 if {
    PolicyId := "MS.DEFENDER.6.2v1"

    Output := defender.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--

#
# Policy 3
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.DEFENDER.6.3v1"

    Output := defender.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--