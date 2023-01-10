package powerplatform
import future.keywords


#
# Policy 1
#--
test_isDisabled_Correct if {
    ControlNumber := "Power Platform 2.3"
    Requirement := "Power Platform tenant isolation SHALL be enabled"

    Output := tests with input as {
        "tenant_isolation": [{
            "properties" : {
                "isDisabled" : false
            } 
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_isDisabled_Incorrect if {
    ControlNumber := "Power Platform 2.3"
    Requirement := "Power Platform tenant isolation SHALL be enabled"

    Output := tests with input as {
        "tenant_isolation": [{
            "properties" : {
                "isDisabled" : true
            } 
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 2
#--
test_NotImplemented_Correct if {
    ControlNumber := "Power Platform 2.3"
    Requirement := "An inbound/outbound connection allowlist SHOULD be configured"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Power Platform Secure Configuration Baseline policy 2.3 for instructions on manual check"
}