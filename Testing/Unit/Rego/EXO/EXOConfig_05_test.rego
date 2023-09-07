package exo
import future.keywords


#
# Policy 1
#--
test_SmtpClientAuthenticationDisabled_Correct if {
    PolicyId := "MS.EXO.5.1v1"

    Output := tests with input as {
        "transport_config":
        [
            {
                "SmtpClientAuthenticationDisabled" : true,
                "Name":"A"
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SmtpClientAuthenticationDisabled_Incorrect if {
    PolicyId := "MS.EXO.5.1v1"

    Output := tests with input as {
        "transport_config": [
            {
                "SmtpClientAuthenticationDisabled" : false,
                "Name" : "A"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}