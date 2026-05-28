package securitysuite_test
import rego.v1
import data.securitysuite
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.SECURITYSUITE.5.1v1
#--
test_AdminAuditLogEnabled_Correct if {
    Output := securitysuite.tests with input.admin_audit_log_config as [AdminAuditLogConfig]

    TestResult("MS.SECURITYSUITE.5.1v1", Output, PASS, true) == true
}

test_AdminAuditLogEnabled_Incorrect if {
    AdminAudit := json.patch(AdminAuditLogConfig, [{"op": "add", "path": "UnifiedAuditLogIngestionEnabled", "value": false}])
    Output := securitysuite.tests with input.admin_audit_log_config as [AdminAudit]

    TestResult("MS.SECURITYSUITE.5.1v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.SECURITYSUITE.5.2v1
#--
test_AuditLogRetention_NotImplemented if {
    PolicyId := "MS.SECURITYSUITE.5.2v1"

    Output := securitysuite.tests with input as {}

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--
