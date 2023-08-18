package powerplatform
import future.keywords

#
# Policy 1
#--
test_disablePortalCreationByNonAdminUsers_Correct if {
    PolicyId := "MS.POWERPLATFORM.5.1v1"

    Output := tests with input as {
        "environment_creation": [{
            "disablePortalsCreationByNonAdminUsers" : true
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_disablePortalCreationByNonAdminUsers_Incorrect if {
    PolicyId := "MS.POWERPLATFORM.5.1v1"

    Output := tests with input as {
        "environment_creation": [{
            "disablePortalsCreationByNonAdminUsers" : false
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}