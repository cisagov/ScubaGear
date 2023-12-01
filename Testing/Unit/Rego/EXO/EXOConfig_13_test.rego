package exo_test
import future.keywords
import data.exo


#
# Policy 1
#--
test_AuditDisabled_Correct if {
    PolicyId := "MS.EXO.13.1v1"

    Output := exo.tests with input as {
        "org_config": [
            {
                "AuditDisabled": false,
                "Identity": "Test name",
                "Name": "A"
            }
        ]
    }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == true
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AuditDisabled_Incorrect if {
    PolicyId := "MS.EXO.13.1v1"

    Output := exo.tests with input as {
        "org_config": [
            {
                "AuditDisabled": true,
                "Identity": "Test name",
                "Name": "A"
            }
        ]
    }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--