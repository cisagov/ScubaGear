package securitysuite_test
import rego.v1
import data.securitysuite
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
RetentionLicenseNote := concat(" ", [
    "Note that the data retention policy only applies to users with an Office 365 E5",
    "or Microsoft 365 E5 license or a Microsoft Purview Suite",
    "(formerly known as Microsoft 365 E5 Compliance) or E5 eDiscovery and Audit add-on license."
])

test_AuditLogRetention_Correct_TwelveMonths if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [UnifiedAuditLogRetentionPolicy]

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

test_AuditLogRetention_Correct_TenYears if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [TenYearRetentionPolicy]

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

test_AuditLogRetention_Correct_MultiplePolicies if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [SixMonthRetentionPolicy, UnifiedAuditLogRetentionPolicy]

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

test_AuditLogRetention_Incorrect_NoPolicies if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as []

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_ThreeMonths if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [ThreeMonthRetentionPolicy]

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_SixMonths if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [SixMonthRetentionPolicy]

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_NineMonths if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [NineMonthRetentionPolicy]

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_Disabled if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [DisabledRetentionPolicy]

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}
#--
