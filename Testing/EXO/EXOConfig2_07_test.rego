package exo
import future.keywords


#
# Policy 1
#--
test_FromScope_Correct if {
    ControlNumber := "EXO 2.7"
    Requirement := "External sender warnings SHALL be implemented"
    
    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : "NotInOrganization"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_FromScope_Incorrect if {
    ControlNumber := "EXO 2.7"
    Requirement := "External sender warnings SHALL be implemented"

    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : ""
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No transport rule found with that applies to emails received from outside the organization"
}

test_FromScope_Multiple_Correct if {
    ControlNumber := "EXO 2.7"
    Requirement := "External sender warnings SHALL be implemented"

    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : ""
            },
            {
                "FromScope" : "NotInOrganization"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_FromScope_Multiple_Incorrect if {
    ControlNumber := "EXO 2.7"
    Requirement := "External sender warnings SHALL be implemented"

    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : ""
            },
            {
                "FromScope" : "Hello there"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No transport rule found with that applies to emails received from outside the organization"
}