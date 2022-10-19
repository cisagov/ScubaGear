package defender
import future.keywords


#
# Policy 1
#--
test_AdminAuditLogEnabled_Correct if {
    ControlNumber := "Defender 2.10"
    Requirement := "Unified audit logging SHALL be enabled"

    Output := tests with input as {
        "admin_audit_log_config": {
            "UnifiedAuditLogIngestionEnabled" : true
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AdminAuditLogEnabled_Incorrect if {
    ControlNumber := "Defender 2.10"
    Requirement := "Unified audit logging SHALL be enabled"

    Output := tests with input as {
        "admin_audit_log_config": {
            "UnifiedAuditLogIngestionEnabled" : false
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 2
#--
test_NotImplemented_Correct_V1 if {
    ControlNumber := "Defender 2.10"
    Requirement := "Advanced audit SHALL be enabled"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.10 for instructions on manual check"
}

#
# Policy 3
#--
test_NotImplemented_Correct_V2 if {
    ControlNumber := "Defender 2.10"
    Requirement := "Audit logs SHALL be maintained for at least the minimum duration dictated by OMB M-21-31"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.10 for instructions on manual check"
}
