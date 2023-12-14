package defender_test
import future.keywords
import data.defender
import data.utils.policy.TestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# Policy 1
#--
test_Spot_Correct if {
    Output := defender.tests with input as {
        "atp_policy_for_o365": [
            {
                "EnableATPForSPOTeamsODB": true,
                "Identity": "Default"
            }
        ],
        "defender_license": true
    }

    TestResult("MS.DEFENDER.3.1v1", Output, PASS, true) == true
}

test_Spot_Incorrect if {
    Output := defender.tests with input as {
        "atp_policy_for_o365": [
            {
                "EnableATPForSPOTeamsODB": false,
                "Identity": "Default"
            }
        ],
        "defender_license": true
    }

    TestResult("MS.DEFENDER.3.1v1", Output, FAIL, false) == true
}
#--