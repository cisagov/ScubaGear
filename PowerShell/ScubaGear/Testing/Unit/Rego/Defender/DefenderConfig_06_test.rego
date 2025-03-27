package defender_test
import rego.v1
import data.defender
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.DEFENDER.6.1v1
#--
test_AdminAuditLogEnabled_Correct if {
    Output := defender.tests with input.admin_audit_log_config as [AdminAuditLogConfig]

    TestResult("MS.DEFENDER.6.1v1", Output, PASS, true) == true
}

test_AdminAuditLogEnabled_Incorrect if {
    AdminAudit := json.patch(AdminAuditLogConfig, [{"op": "add", "path": "UnifiedAuditLogIngestionEnabled", "value": false}])
    Output := defender.tests with input.admin_audit_log_config as [AdminAudit]

    TestResult("MS.DEFENDER.6.1v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.DEFENDER.6.3v1
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.DEFENDER.6.3v1"

    Output := defender.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--
