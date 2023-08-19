package defender
import future.keywords
import data.report.utils.NotCheckedDetails

#
# Policy 1
#--
test_AdminAuditLogEnabled_Correct if {
    PolicyId := "MS.DEFENDER.6.1v1"

    Output := tests with input as {
        "admin_audit_log_config": [{
            "Identity": "Admin Audit Log Settings",
            "UnifiedAuditLogIngestionEnabled" : true
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AdminAuditLogEnabled_Incorrect if {
    PolicyId := "MS.DEFENDER.6.1v1"

    Output := tests with input as {
        "admin_audit_log_config": [{
            "Identity": "Admin Audit Log Settings",
            "UnifiedAuditLogIngestionEnabled" : false
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 2
#--
test_NotImplemented_Correct_V1 if {
    PolicyId := "MS.DEFENDER.6.2v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}

#
# Policy 3
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.DEFENDER.6.3v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
