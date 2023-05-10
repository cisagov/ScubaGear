package exo
import future.keywords


#
# Policy 1
#--
test_FromScope_Correct if {
    PolicyId := "MS.EXO.7.1v1"
    
    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : "NotInOrganization",
                "State" : "Enabled",
                "Mode" : "Enforce"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_FromScope_IncorrectV1 if {
    PolicyId := "MS.EXO.7.1v1"

    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : "",
                "State" : "Enabled",
                "Mode" : "Audit"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No transport rule found that applies warnings to emails received from outside the organization"
}

test_FromScope_IncorrectV2 if {
    PolicyId := "MS.EXO.7.1v1"

    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : "NotInOrganization",
                "State" : "Disabled",
                "Mode" : "Audit"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No transport rule found that applies warnings to emails received from outside the organization"
}

test_FromScope_IncorrectV3 if {
    PolicyId := "MS.EXO.7.1v1"

    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : "",
                "State" : "Enabled",
                "Mode" : "AuditAndNotify"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No transport rule found that applies warnings to emails received from outside the organization"
}

test_FromScope_IncorrectV4 if {
    PolicyId := "MS.EXO.7.1v1"

    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : "NotInOrganization",
                "State" : "Disabled",
                "Mode" : "AuditAndNotify"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No transport rule found that applies warnings to emails received from outside the organization"
}

test_FromScope_Multiple_Correct if {
    PolicyId := "MS.EXO.7.1v1"

    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : "",
                "State" : "Disabled",
                "Mode" : "Enforce"
            },
            {
                "FromScope" : "",
                "State" : "Enabled",
                "Mode" : "Audit"
            },
            {
                "FromScope" : "",
                "State" : "Enabled",
                "Mode" : "AuditAndNotify"
            },
            {
                "FromScope" : "NotInOrganization",
                "State" : "Enabled",
                "Mode" : "Enforce"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_FromScope_Multiple_Incorrect if {
    PolicyId := "MS.EXO.7.1v1"

    Output := tests with input as {
        "transport_rule": [
            {
                "FromScope" : "",
                "State" : "Enabled",
                "Mode":"Enforce"
            },
            {
                "FromScope" : "Hello there",
                "State" : "Enabled",
                "Mode":"Audit"
            },
            {
                "FromScope" : "Hello there",
                "State" : "Enabled",
                "Mode":"AuditAndNotify"
            },
            {
                "FromScope" : "NotInOrganization",
                "State" : "Enabled",
                "Mode":"Audit"
            },
            {
                "FromScope" : "NotInOrganization",
                "State" : "Enabled",
                "Mode":"AuditAndNotify"
            },
            {
                "FromScope" : "NotInOrganization",
                "State" : "Disabled",
                "Mode":"Enforce"
            }
        ]    
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No transport rule found that applies warnings to emails received from outside the organization"
}