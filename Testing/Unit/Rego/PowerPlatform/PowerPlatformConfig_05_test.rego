package powerplatform_test
import future.keywords
import data.powerplatform


#
# Policy 1
#--
test_disablePortalCreationByNonAdminUsers_Correct if {
    PolicyId := "MS.POWERPLATFORM.5.1v1"

    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disablePortalsCreationByNonAdminUsers": true
            }
        ]
    }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == true
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_disablePortalCreationByNonAdminUsers_Incorrect if {
    PolicyId := "MS.POWERPLATFORM.5.1v1"

    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disablePortalsCreationByNonAdminUsers": false
            }
        ]
    }

    RuleOutput := [Result | some Result in Output; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet == false
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--