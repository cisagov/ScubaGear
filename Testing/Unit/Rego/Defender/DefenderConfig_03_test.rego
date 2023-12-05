package defender_test
import future.keywords
import data.defender


#
# Policy 1
#--
test_Spot_Correct if {
    PolicyId := "MS.DEFENDER.3.1v1"

    Output := defender.tests with input as {
        "atp_policy_for_o365": [
            {
                "EnableATPForSPOTeamsODB": true,
                "Identity": "Default"
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Spot_Incorrect if {
    PolicyId := "MS.DEFENDER.3.1v1"

    Output := defender.tests with input as {
        "atp_policy_for_o365": [
            {
                "EnableATPForSPOTeamsODB": false,
                "Identity": "Default"
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--