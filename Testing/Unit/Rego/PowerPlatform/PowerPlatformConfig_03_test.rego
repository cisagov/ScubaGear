package powerplatform
import future.keywords
import data.report.utils.NotCheckedDetails

#
# Policy 1
#--
test_isDisabled_Correct if {
    PolicyId := "MS.POWERPLATFORM.3.1v1"

    Output := tests with input as {
        "tenant_isolation": [{
            "properties" : {
                "isDisabled" : false
            } 
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_isDisabled_Incorrect if {
    PolicyId := "MS.POWERPLATFORM.3.1v1"

    Output := tests with input as {
        "tenant_isolation": [{
            "properties" : {
                "isDisabled" : true
            } 
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 2
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.POWERPLATFORM.3.2v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}