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
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

test_AuditLogRetention_Correct_ThreeYears if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [ThreeYearRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

test_AuditLogRetention_Correct_FiveYears if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [FiveYearRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

test_AuditLogRetention_Correct_SevenYears if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [SevenYearRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

test_AuditLogRetention_Correct_TenYears if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [TenYearRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

test_AuditLogRetention_Correct_MultiplePolicies if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [SixMonthRetentionPolicy, UnifiedAuditLogRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

test_AuditLogRetention_Incorrect_NoPolicies if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as []
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_SevenDays if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [SevenDayRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_OneMonth if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [OneMonthRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_ThreeMonths if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [ThreeMonthRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_SixMonths if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [SixMonthRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_NineMonths if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [NineMonthRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

test_AuditLogRetention_Incorrect_Disabled if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [DisabledRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

# E3/G3 license level: a compliant 12 month retention policy is configured but
# the tenant lacks the advanced auditing service plan, so the policy fails.
test_AuditLogRetention_Incorrect_NoAdvancedAuditingLicense if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [UnifiedAuditLogRetentionPolicy]
        with input.service_plans as ServicePlansWithoutAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

# No service plans at all (e.g. license data unavailable) also fails even with a
# compliant retention policy.
test_AuditLogRetention_Incorrect_NoServicePlans if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [UnifiedAuditLogRetentionPolicy]
        with input.service_plans as []

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}
#--
