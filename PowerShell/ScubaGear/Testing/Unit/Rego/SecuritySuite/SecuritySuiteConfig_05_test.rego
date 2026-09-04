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

# A lower-priority compliant policy (12 months) must NOT override a higher-priority
# non-compliant policy (7 days). Per Microsoft, lower numeric Priority means higher
# precedence, so the 7 day policy wins and the tenant fails. See issue #2374.
test_AuditLogRetention_Incorrect_HigherPriorityNonCompliant if {
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [LowerPriorityCompliantRetentionPolicy, HighPriorityNonCompliantRetentionPolicy]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}

# Symmetric case: the non-compliant policy has the lower priority (Priority=2)
# while the compliant 12 month policy has the higher priority (Priority=1).
# Here the compliant policy wins and the tenant should pass.
test_AuditLogRetention_Correct_HigherPriorityCompliant if {
    HighPriorityCompliant := json.patch(LowerPriorityCompliantRetentionPolicy, [
        {"op": "replace", "path": "Priority", "value": 1},
    ])
    LowPriorityNonCompliant := json.patch(HighPriorityNonCompliantRetentionPolicy, [
        {"op": "replace", "path": "Priority", "value": 2},
    ])
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [LowPriorityNonCompliant, HighPriorityCompliant]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

# Tie on the smallest Priority value (two enabled policies, both Priority=1):
# Purview does not define tie semantics, so the evaluation fails closed — all
# highest-priority policies must comply for the tenant to pass.
test_AuditLogRetention_TieBothCompliant if {
    PolicyA := json.patch(LowerPriorityCompliantRetentionPolicy, [
        {"op": "replace", "path": "Priority", "value": 1},
    ])
    PolicyB := json.patch(LowerPriorityCompliantRetentionPolicy, [
        {"op": "replace", "path": "Name", "value": "Second compliant policy"},
        {"op": "replace", "path": "Priority", "value": 1},
    ])
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [PolicyA, PolicyB]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [PASS, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, true) == true
}

# A tie where one of the smallest-priority policies is non-compliant must fail:
# a compliant policy at the same priority cannot mask the non-compliant one.
test_AuditLogRetention_TieOneNonCompliant if {
    TieNonCompliant := json.patch(HighPriorityNonCompliantRetentionPolicy, [
        {"op": "replace", "path": "Priority", "value": 1},
    ])
    TieCompliant := json.patch(LowerPriorityCompliantRetentionPolicy, [
        {"op": "replace", "path": "Priority", "value": 1},
    ])
    Output := securitysuite.tests with input.unified_audit_log_retention_policies as [TieNonCompliant, TieCompliant]
        with input.service_plans as ServicePlansWithAdvancedAuditing

    ReportDetailString := concat(": ", [FAIL, RetentionLicenseNote])
    TestResult("MS.SECURITYSUITE.5.2v1", Output, ReportDetailString, false) == true
}
#--
