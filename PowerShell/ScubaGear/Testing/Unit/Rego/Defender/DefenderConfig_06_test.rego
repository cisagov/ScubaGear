package defender_test
import rego.v1
import data.defender
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS
import data.utils.report.PolicyLink

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
# Policy MS.DEFENDER.6.2v1
#--
test_AdvAudit_Correct if {
    Output := defender.tests with input.total_users_without_advanced_audit as 0

    TestResult("MS.DEFENDER.6.2v1", Output, PASS, true) == true
}

test_AdvAudit_Incorrect_V1 if {
    Output := defender.tests with input.total_users_without_advanced_audit as 10

    ErrorDetails := concat(" ", [ "Requirement not met.", "10",
    "tenant users without M365 Advanced Auditing feature assigned.",
    "To review and assign users the Microsoft 365 Advanced Auditing feature, see %v.",
    "To get a list of all users without the license feature run the following:",
    concat("", ["Get-MgBetaUser -Filter \"not assignedPlans/any(a:a/servicePlanId eq ",
                "2f442157-a11c-46b9-ae5b-6e39ff4e5849 and a/capabilityStatus eq 'Enabled')\""]),
    "-ConsistencyLevel eventual -Count UserCount -All | Select-Object DisplayName,UserPrincipalName"
    ])

    ErrorMessage := sprintf(ErrorDetails, [PolicyLink("MS.DEFENDER.6.2v1")])
    TestResult("MS.DEFENDER.6.2v1", Output, ErrorMessage, false) == true
}

test_AdvAudit_Incorrect_V2 if {
    Output := defender.tests with input as { }

    ReportDetailString := concat(" ", [
        "Requirement not met. Error retrieving license information from tenant. ",
        "**NOTE: M365 Advanced Auditing feature requires E5/G5 or add-on licensing.**"
    ])
    TestResult("MS.DEFENDER.6.2v1", Output,  ReportDetailString, false) == true
}

test_AdvAudit_Incorrect_V3 if {
    Output := defender.tests with input.total_users_without_advanced_audit as -1

    ReportDetailString := concat(" ", [
        "Requirement not met. Error retrieving license information from tenant. ",
        "**NOTE: M365 Advanced Auditing feature requires E5/G5 or add-on licensing.**"
    ])

    TestResult("MS.DEFENDER.6.2v1", Output,  ReportDetailString, false) == true
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
