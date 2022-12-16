package exo
import future.keywords


#
# Policy 1
#--
test_SmtpClientAuthenticationDisabled_Correct if {
    ControlNumber := "EXO 2.5"
    Requirement := "SMTP AUTH SHALL be disabled in Exchange Online"

    Output := tests with input as {
        "transport_config": 
        [
            {
                "SmtpClientAuthenticationDisabled" : true,
                "Name":"A"
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SmtpClientAuthenticationDisabled_Incorrect if {
    ControlNumber := "EXO 2.5"
    Requirement := "SMTP AUTH SHALL be disabled in Exchange Online"

    Output := tests with input as {
        "transport_config": [
            {
                "SmtpClientAuthenticationDisabled" : false,
                "Name" : "A"
            }
        ]  
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
 
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}