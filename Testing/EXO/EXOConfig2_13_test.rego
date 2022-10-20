package exo
import future.keywords


#
# Policy 1
#--
test_AuditDisabled_Correct if {
    ControlNumber := "EXO 2.13"
    Requirement := "Mailbox auditing SHALL be enabled"

    Output := tests with input as {
        "org_config": {
            "AuditDisabled" : false, 
            "Identity" : "Test name"
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AuditDisabled_Incorrect if {
    ControlNumber := "EXO 2.13"
    Requirement := "Mailbox auditing SHALL be enabled"

    Output := tests with input as {
        "org_config": {
            "AuditDisabled" : true, 
            "Identity" : "Test name"
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}