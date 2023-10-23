package exo
import future.keywords


#
# Policy 1
#--
test_AutoForwardEnabled_Correct if {
    PolicyId := "MS.EXO.1.1v1"

    Output := tests with input as {
        "remote_domains": [
            {
                "AutoForwardEnabled" : false,
                "DomainName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AutoForwardEnabled_Incorrect_V1 if {
    PolicyId := "MS.EXO.1.1v1"

    Output := tests with input as {
        "remote_domains": [
            {
                "AutoForwardEnabled" : true,
                "DomainName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 remote domain(s) that allows automatic forwarding: Test name"
}

test_AutoForwardEnabled_Incorrect_V2 if {
    PolicyId := "MS.EXO.1.1v1"

    Output := tests with input as {
        "remote_domains": [
            {
                "AutoForwardEnabled" : true,
                "DomainName" : "Test name"
            },
            {
                "AutoForwardEnabled" : true,
                "DomainName" : "Test name 2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "2 remote domain(s) that allows automatic forwarding: Test name, Test name 2"
}

test_AutoForwardEnabled_Incorrect_V3 if {
    PolicyId := "MS.EXO.1.1v1"

    Output := tests with input as {
        "remote_domains": [
            {
                "AutoForwardEnabled" : true,
                "DomainName" : "Test name"
            },
            {
                "AutoForwardEnabled" : true,
                "DomainName" : "Test name 2"
            },
            {
                "AutoForwardEnabled" : false,
                "DomainName" : "Test name 3"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "2 remote domain(s) that allows automatic forwarding: Test name, Test name 2"
}
