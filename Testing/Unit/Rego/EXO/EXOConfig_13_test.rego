package exo
import future.keywords


#
# Policy 1
#--
test_AuditDisabled_Correct if {
    PolicyId := "MS.EXO.13.1v1"

    Output := tests with input as {
        "org_config":
        [
            {
                "AuditDisabled" : false,
                "Identity" : "Test name",
                "Name":"A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AuditDisabled_Incorrect if {
    PolicyId := "MS.EXO.13.1v1"

    Output := tests with input as {
        "org_config": [
            {
                "AuditDisabled" : true,
                "Identity" : "Test name",
                "Name" : "A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}